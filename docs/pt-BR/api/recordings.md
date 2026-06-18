# API de gravações

## Listar gravações

**Ponto final:** `GET /api/recordings`

Recuperar uma lista paginada de gravações com filtragem opcional.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `camera_id` | corda | Não | Filtrar por ID da câmera | `front-door` |
| `format` | corda | Não | Filtrar por formato (h264, h265, mjpeg) | `h264` |
| `merged` | booleano | Não | Filter by merge status | `true` |
| `start` | corda | Não | Hora de início (formato RFC3339) | `2024-01-01T00:00:00Z` |
| `end` | corda | Não | Hora de término (formato RFC3339) | `2024-01-02T00:00:00Z` |
| `limit` | inteiro | Não | Resultados máximos (padrão: 50) | `20` |
| `offset` | inteiro | Não | Deslocamento de resultado para paginação | `0` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings?format=h264&limit=10&offset=0"
```

**Resposta:**
```json
{
  "recordings": [
    {
      "id": "1704123456789012345",
      "camera_id": "front-door",
      "file_path": "/data/recordings/h264/front-door_1704123456789012345.mp4",
      "format": "h264",
      "started_at": "2024-01-01T12:34:56.789Z",
      "ended_at": "2024-01-01T12:35:06.789Z",
      "duration": 10.0,
      "file_size": 1048576,
      "frame_count": 300,
      "merged": false
    }
  ],
  "total": 1
}
```

## Obter gravação

**Ponto final:** `GET /api/recordings/{id}`

Recuperar uma gravação específica por ID.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings/1704123456789012345"
```

**Resposta:**
```json
{
  "id": "1704123456789012345",
  "camera_id": "front-door",
  "file_path": "/data/recordings/h264/front-door_1704123456789012345.mp4",
  "format": "h264",
  "started_at": "2024-01-01T12:34:56.789Z",
  "ended_at": "2024-01-01T12:35:06.789Z",
  "duration": 10.0,
  "file_size": 1048576,
  "frame_count": 300,
  "merged": false
}
```

## Delete Recording

**Ponto final:** `DELETE /api/recordings/{id}`

Exclua uma gravação por ID.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/recordings/1704123456789012345"
```

**Resposta:**
```json
{
  "status": "deleted"
}
```

## Download Recording

**Ponto final:** `GET /api/recordings/{id}/download`

Baixe um arquivo de gravação.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `frame` | inteiro | Não | Para o formato MJPEG, baixe o quadro específico | `150` |

**Request (H264):**
```bash
curl -u username:password \
  -o recording.mp4 \
  "http://localhost:9090/api/recordings/1704123456789012345/download"
```

**Solicitação (MJPEG com moldura específica):**
```bash
curl -u username:password \
  -o frame_150.jpg \
  "http://localhost:9090/api/recordings/1704123456789012345/download?frame=150"
```

**Resposta:** Conteúdo do arquivo binário (MP4 ou JPEG)

## Listar quadros de gravação (somente MJPEG)

**Ponto final:** `GET /api/recordings/{id}/frames`

Liste todos os quadros para uma gravação MJPEG.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings/1704123456789012345/frames"
```

**Resposta:**
```json
{
  "frames": [
    {
      "index": 0,
      "filename": "front-door_1704123456789012345_0000.jpg",
      "size": 54321
    },
    {
      "index": 1,
      "filename": "front-door_1704123456789012345_0001.jpg",
      "size": 52345
    }
  ]
}
```

## Gravações de exclusão em lote

**Ponto final:** `POST /api/recordings/batch-delete`

Exclua várias gravações por ID.

**Corpo da solicitação:**
```json
{
  "recording_ids": ["id1", "id2", "id3"]
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "recording_ids": ["1704123456789012345", "1704123456789012346"]
  }' \
  "http://localhost:9090/api/recordings/batch-delete"
```

**Resposta:**
```json
{
  "deleted": 2,
  "failed": 0
}
```

## Baixar gravação mesclada

**Ponto final:** `GET /api/recordings/{id}/merged`

Baixe o arquivo MP4 mesclado para uma gravação de lapso de tempo. Fornece o arquivo via `http.ServeFile()` com suporte de intervalo.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings/1704123456789012345/merged"
```

**Resposta:** Conteúdo do arquivo binário MP4. Retorna 404 se nenhuma gravação mesclada estiver disponível.

## Listar quadros de lapso de tempo

**Ponto final:** `GET /api/recordings/{id}/timelapse-frames`

Liste os quadros JPEG para uma gravação de lapso de tempo.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings/1704123456789012345/timelapse-frames"
```

**Resposta:**
```json
[
  {
    "filename": "frame_0001.jpg",
    "url": "/api/recordings/1704123456789012345/timelapse-frames/frame_0001.jpg",
    "size": 54321,
    "timestamp": "2024-01-01T12:34:56Z"
  },
  {
    "filename": "frame_0002.jpg",
    "url": "/api/recordings/1704123456789012345/timelapse-frames/frame_0002.jpg",
    "size": 52345,
    "timestamp": "2024-01-01T12:35:06Z"
  }
]
```

## Get Timelapse Frame

**Ponto final:** `GET /api/recordings/{id}/timelapse-frames/{filename}`

Obtenha um quadro JPEG específico de uma gravação de lapso de tempo.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/recordings/1704123456789012345/timelapse-frames/frame_0001.jpg" \
  -o frame_0001.jpg
```

**Resposta:** imagem binária JPEG. Retorna 400 para nomes de arquivos inválidos (proteção contra passagem de caminho).
