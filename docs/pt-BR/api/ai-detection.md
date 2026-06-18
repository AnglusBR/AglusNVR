# AI Detection API

## Arquitetura

> **A inferência de IA é executada inteiramente no navegador** por meio de [ONNX Runtime Web](https://onnxruntime.ai/docs/tutorials/web/) (preferencialmente WebGPU, substituto WASM SIMD). O back-end Go **não realiza inferência de IA**.

Isso é intencional: o NVR é fornecido como um binário `CGO_ENABLED=0` estático que faz compilação cruzada para ARM64/ARMv7. Agrupar um tempo de execução Go ONNX (`libonnxruntime`) arrastaria uma dependência C, aumentaria o binário e complicaria a compilação cruzada do ARM - FFmpeg já é a dependência mais pesada. A detecção também é feita por visualizador em uma transmissão ao vivo já decodificada, portanto, executá-la no navegador evita a recodificação no servidor e é dimensionada com visualizadores em vez de câmeras.

A função do back-end é limitada a:

- **(a) Configuração de IA persistente + zonas ROI** — os endpoints abaixo (todos em `/api/ai/*`).
- **(b) Servindo o arquivo de modelo `.onnx`** para o navegador — a rota pública [`GET /models/{filename}`](#serve-model-file).

O pipeline de inferência do lado do navegador reside em `web/src/lib/ai-detection/` (`runtime.ts` = sessão ONNX Runtime Web, `inference.ts` = pré-processamento YOLOv11-nano/suavização NMS/EMA). **Não** endpoint `POST /api/ai/enable`, `POST /api/ai/disable` ou `GET /api/ai/events` SSE — a detecção nunca flui pelo back-end.

> Todos os endpoints `/api/ai/*` requerem autenticação básica HTTP. Somente [`GET /models/{filename}`](#serve-model-file) é público.

---

## Obtenha status de IA

**Ponto final:** `GET /api/ai/status`

Retorna a configuração global da IA. Este é apenas o estado de configuração — não há status de inferência por câmera, porque a inferência é executada no navegador.

**Solicitação:**
```bash
curl -u admin:password \
  "http://localhost:9090/api/ai/status"
```

**Resposta:** `200 OK`
```json
{
  "enabled": true,
  "model_url": "/models/yolo11n.onnx",
  "confidence_threshold": 0.5,
  "frame_skip_rate": 10
}
```

| Campo | Tipo | Descrição |
|-------|------|-------------|
| `enabled` | bool | Se a IA está habilitada (consumida pela IU do navegador) |
| `model_url` | corda | Caminho do modelo que o navegador carrega (HTTPS relativo ou na lista de permissões) |
| `confidence_threshold` | float | Limite de confiança de detecção `[0, 1]` |
| `frame_skip_rate` | interno | Execute a inferência a cada N quadros |

---

## Atualizar configuração de IA

**Ponto final:** `PUT /api/ai/config`

Atualiza a configuração global da IA ​​em tempo de execução. Todos os campos são opcionais — apenas os campos fornecidos são alterados (atualização parcial). As alterações são persistidas na configuração YAML atomicamente.

**Request Body:**
```json
{
  "enabled": true,
  "confidence_threshold": 0.6,
  "frame_skip_rate": 5,
  "model_url": "/models/yolo11n.onnx"
}
```

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|----------|-------------|
| `enabled` | bool | não | Ativar/desativar IA |
| `confidence_threshold` | float | não | Deve estar em `[0, 1]` |
| `frame_skip_rate` | interno | não | Deve ser `> 0` |
| `model_url` | corda | não | Caminho do modelo (HTTPS relativo ou na lista de permissões) |

**Solicitação:**
```bash
curl -u admin:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "confidence_threshold": 0.6,
    "frame_skip_rate": 5
  }' \
  "http://localhost:9090/api/ai/config"
```

**Resposta:** `200 OK`
```json
{ "status": "updated" }
```

**Erros:** `400 Bad Request` — `{"error":"invalid request body"}` se o corpo JSON não puder ser decodificado.

---

## Listar zonas de ROI

**Ponto final:** `GET /api/ai/zones`

Lista todas as zonas ROI (região de interesse) em todas as câmeras. Sempre retorna um array (vazio se não houver).

**Request:**
```bash
curl -u admin:password \
  "http://localhost:9090/api/ai/zones"
```

**Resposta:** `200 OK`
```json
{
  "zones": [
    {
      "camera_id": "front-door",
      "zone": {
        "name": "driveway",
        "points": [[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]
      },
      "enabled": true
    }
  ]
}
```

---

## Criar zona ROI

**Ponto final:** `POST /api/ai/zones`

Cria uma nova zona ROI. **Os nomes das zonas são globalmente exclusivos** em todas as câmeras.

**Corpo da solicitação:**
```json
{
  "camera_id": "front-door",
  "zone": {
    "name": "driveway",
    "points": [[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]
  },
  "enabled": true
}
```

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|----------|-------------|
| `camera_id` | corda | sim | ID da câmera alvo |
| `zone.name` | corda | sim | Nome de zona globalmente exclusivo (usado como `{id}` em atualização/exclusão) |
| `zone.points` | `[[x,y],...]` | sim | Vértices do polígono, ≥ 3 pontos, normalizados `[0, 1]` |
| `enabled` | bool | não | Se o filtro de zona está ativo |

**Solicitação:**
```bash
curl -u admin:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "front-door",
    "zone": {
      "name": "driveway",
      "points": [[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]
    },
    "enabled": true
  }' \
  "http://localhost:9090/api/ai/zones"
```

**Resposta:** `201 Created`
```json
{
  "camera_id": "front-door",
  "zone": {
    "name": "driveway",
    "points": [[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]
  },
  "enabled": true
}
```

**Errors:**
- `400 Bad Request` — `{"error":"camera_id and zone.name are required"}`
- `409 Conflict` — `{"error":"zone with this name already exists"}`

---

## Atualizar zona ROI

**Ponto final:** `PUT /api/ai/zones/{id}`

Atualiza uma zona existente. O parâmetro de caminho `{id}` é o **nome** da zona (os nomes das zonas são globalmente exclusivos). Suporta renomear e/ou substituir os pontos do polígono.

**Path Parameter:**

| Parâmetro | Descrição |
|-------|-------------|
| `id` | A zona **nome** a ser atualizada |

**Corpo da solicitação:**
```json
{
  "camera_id": "front-door",
  "zone": {
    "name": "front-lawn",
    "points": [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0], [0.0, 1.0]]
  },
  "enabled": true
}
```

**Solicitação:**
```bash
curl -u admin:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "front-door",
    "zone": { "points": [[0.0, 0.0], [1.0, 0.0], [1.0, 1.0]] }
  }' \
  "http://localhost:9090/api/ai/zones/driveway"
```

**Resposta:** `200 OK`
```json
{ "status": "updated" }
```

**Erros:**
- `400 Bad Request` — ID de zona ausente ou corpo inválido
- `404 Not Found` — `{"error":"zone not found"}`
- `409 Conflict` — `{"error":"zone with new name already exists"}` (ao renomear para um nome existente)

---

## Delete ROI Zone

**Ponto final:** `DELETE /api/ai/zones/{id}`

Exclui uma zona por nome. O `{id}` é o **nome** da zona.

**Solicitação:**
```bash
curl -u admin:password \
  -X DELETE \
  "http://localhost:9090/api/ai/zones/driveway"
```

**Resposta:** `200 OK`
```json
{ "status": "deleted" }
```

**Errors:**
- `400 Bad Request` — ID de zona ausente
- `404 Not Found` — `{"error":"zone not found"}`

---

## Servir arquivo de modelo

**Ponto final:** `GET /models/{filename}`

Fornece um arquivo de modelo AI do diretório `{storage_root}/models/` usando `http.ServeFile` (com suporte a solicitação de intervalo HTTP para downloads parciais).

> **Público — não é necessária autenticação.** Esta rota é intencionalmente não autenticada para que o navegador possa buscar o modelo ONNX antes/sem depender do streaming autenticado por sessão. É a **única** rota pública relacionada à IA; todos os endpoints `/api/ai/*` ainda exigem autenticação básica.

**Parâmetro do caminho:**

| Parâmetro | Descrição |
|-------|-------------|
| `filename` | Nome do arquivo do modelo, por ex. `yolo11n.onnx` |

**Solicitação:**
```bash
curl "http://localhost:9090/models/yolo11n.onnx" -o yolo11n.onnx
```

**Resposta:** `200 OK` com os bytes do arquivo (`Content-Type` detectado automaticamente, `Accept-Ranges: bytes`).

**Erros:** `400 Bad Request` se `filename` estiver vazio; padrão `404` se o arquivo não existir.

### Putting a model on disk

Os arquivos de modelo são colocados em `{storage_root}/models/` pelo operador — **não** endpoint de upload/download HTTP para modelos. O subcomando CLI incluído baixa o modelo YOLOv11-nano padrão:

```bash
aglus-nvr download-model -config aglus-nvr.yaml
# or: make download-model RPi_HOST=user@host  (deploys + downloads on a remote host)
```

---

## Modelo de dados

### Zona ROI

```json
{
  "camera_id": "front-door",
  "zone": {
    "name": "driveway",
    "points": [[0.1, 0.1], [0.9, 0.1], [0.9, 0.9], [0.1, 0.9]]
  },
  "enabled": true
}
```

- **`points`** — vértices do polígono como pares `[x, y]` em **coordenadas `[0, 1]`** normalizadas em relação ao quadro (independente da resolução). Minimum 3 points. O polígono é implicitamente fechado (o último vértice se conecta ao primeiro).
- **`zone.name`** — globalmente exclusivo em todas as câmeras; também usado como parâmetro de URL `{id}` para atualização/exclusão.

### Error Responses

Todos os erros usam a forma auxiliar padrão:

```json
{ "error": "human-readable message" }
```

| Estado | Significado |
|--------|---------|
| `200`/`201` | Sucesso |
| `400` | Solicitação incorreta (corpo inválido, campo obrigatório ausente) |
| `404` | Zona não encontrada |
| `409` | Conflito (nome de zona duplicado) |
