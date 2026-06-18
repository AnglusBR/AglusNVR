# WASM + WebCodecs Detecção Unificada de Jogadores e IA

## O que é o WASM + WebCodecs Sistema Unificado de Detecção de Jogadores e IA

O sistema WASM + WebCodecs Unified Player & AI Detection é uma arquitetura moderna de streaming de vídeo em camadas que substitui os tradicionais players de navegador por um pipeline baseado em WebCodecs. Ele oferece renderização de três níveis (WebGPU → WebGL2 → Legacy), suporta detecção de objetos com IA no lado do navegador, usando um modelo nano YOLOv11 (ONNX Runtime Web), e mantém compatibilidade entre navegadores modernos, além de oferecer desempenho superior para conteúdo H.264/H.265.

**Principais Características:**
- Renderização de três níveis com degradação automática
- WebSocket protocolo binário de streaming para transporte de vídeo de baixa latência
- Detecção de IA frontend com provedores de execução ONNX Runtime WebGPU/WASM
- O backend serve apenas a configuração da IA + o arquivo do modelo ONNX (sem inferência do lado do servidor — preserva o binário estático `CGO_ENABLED=0`)
- Aceleração de hardware tanto para decodificação quanto para renderização
- Suporte para codecs de vídeo modernos, incluindo H.265 (HEVC)

## Visão Geral da Arquitetura

O sistema implementa uma sofisticada arquitetura de três níveis de reserva que se adapta automaticamente às capacidades do navegador:

```
┌─ Tier 1: WebGPU (Zero-Copy Hardware) ──────────────────────────────────┐
│  WebCodecs decode → WebGPU texture (importExternalTexture) → Render    │
│  ONNX Runtime WebGPU execution provider (AI, 5-10ms/frame)               │
│  Browser Support: Chrome 113+, Edge 113+, Safari 18+                     │
│  Performance: Decode 200+ FPS, AI 30+ FPS, Render 60 FPS                │
├───────────────────────────────────────────────────────────────────────────┤
└── ↓ WebGPU device loss or unavailable → Automatic fallback to WebGL2

┌─ Tier 2: WebGL2 + WASM SIMD (Hybrid Mode) ─────────────────────────────┐
│  WebCodecs decode → WebGL2 Canvas (copyExternalImageToTexture) → Render  │
│  ONNX Runtime WASM SIMD execution provider (AI, 30-50ms/frame)          │
│  Browser Support: Firefox 130+, Safari 16.4+, Chrome 94+ (WebCodecs)    │
│  Performance: Decode 200+ FPS, AI 10-20 FPS, Render 60 FPS            │
├───────────────────────────────────────────────────────────────────────────┤
└── ↓ WebCodecs unavailable → Automatic fallback to Legacy players

┌─ Tier 3: Legacy Compatibility Mode ──────────────────────────────────┐
│  HTTP-FLV/HLS/WebRTC → hls.js/mpegts.js/WHEP → <video> element        │
│  Browser Support: Legacy browsers, mobile browsers, specific scenarios   │
│  Performance: Same as current experience                              │
└───────────────────────────────────────────────────────────────────────────┘
```

### Arquitetura de Fluxo de Dados

```
Camera → RTSP Recorder → StreamHub → WebSocket → Browser Worker → 
VideoDecoder → Renderer → Canvas
                                                    ↓
Frontend AI (ONNX Runtime Web) → Detections → UI Overlay (in-browser, no server round-trip)
```

### Algoritmo de Detecção de Níveis

O sistema determina dinamicamente o melhor nível de reprodução usando `getPlaybackTier()`:

```typescript
export function getPlaybackTier(): PlaybackTier {
  if (detectWebCodecs() && detectWebGPU()) {
    return 'tier1'; // WebCodecs + WebGPU
  }
  if (detectWebCodecs() && (detectWebGL2() || detectOffscreenCanvas())) {
    return 'tier2'; // WebCodecs + WebGL2
  }
  return 'tier3'; // Legacy fallback
}
```

## WebSocket Protocolo

O sistema utiliza um protocolo binário personalizado WebSocket com enquadramento eficiente para dados de configuração de vídeo e codec. Todos os inteiros de múltiplos bytes usam big-endian (ordem dos bytes da rede).

### Visão Geral do Protocolo

**Tipos de Mensagem:**
- `0x01` = CodecInfo (servidor → cliente)
- `0x02` = VideoFrame (servidor → cliente)
- `0x03` = AudioFrame (servidor → cliente, reservado)
- `0x04` = KeyframeReq (cliente → servidor)

### Informações do Codec (tipo 0x01)

Formato binário de fio para dados de configuração de codec enviados uma vez no início do fluxo:

```
[type:1byte][codec:1byte][profile:1byte][level:1byte][sps_len:2bytes_BE][sps:N][pps_len:2bytes_BE][pps:N][vps_len:2bytes_BE][vps:N]
```

**Identificadores de Codec:**
- `4` = H.264 (AVC)
- `5` = H.265 (HEVC)

**Detalhes do campo:**
- `codec`: Byte indicando o tipo de codec (4 para H.264, 5 para H.265)
- `profile`: H.264 byte de perfil ou H.265 profile_idc
- `level`: H.264 nível ou combinação de H.265 nível/nível
- `sps_len`, `pps_len`, `vps_len`: Comprimentos dos respectivos conjuntos NAL (big-endian)
- `sps`, `pps`, `vps`: Dados brutos da unidade NAL (sem códigos de início)
- `vps` campo está presente apenas para H.265

### Quadro de Vídeo (tipo 0x02)

Formato binário de fio para quadros de vídeo individuais com unidades NAL:

```
[type:1byte][pts:8bytes_BE][is_keyframe:1byte][nalu_count:2bytes_BE][nalu1_len:4bytes_BE][nalu1]...
```

**Detalhes do campo:**
- `type`: Sempre `0x02`
- `pts`: Hora da apresentação em 90kHz (do StreamHub)
- `is_keyframe`: Flag booleano (1=quadro-chave, 0=interquadro)
- `nalu_count`: Número de unidades NAL neste quadro (máximo 65535)
- `naluX_len`: Comprimento de cada unidade NAL (big-endian)
- `naluX`: Dados brutos da unidade NAL sem códigos de início do Anexo B

**Detalhes Chave da Implementação:**
- Todas as unidades da NAL são enviadas sem códigos de início do Anexo B (`00 00 00 01`)
- Os códigos de início são colocados no lado do cliente antes da decodificação
- Os carimbos de tempo do PTS são sincronizados com o clock de 90kHz do StreamHub
- Pulo de quadros e recuperação de erros são gerenciados no nível do decodificador

## WebCodecs Pipeline de Decodificação

O pipeline de decodificação roda em um Web Worker para evitar bloquear a thread principal, usando a API WebCodecs VideoDecoder para decodificação de vídeo acelerada por hardware.

### Protocolo de Mensagem de Trabalhador

**Mensagens do Trabalhador:**
- `codec-info`: Configurar o decodificador com dados SPS/PPS/VPS
- `video-frame`: Decodificar unidades NAL brutas com informações de data/hora e quadros-chave
- `reset`: Reinicializar o estado do decodificador (lidar com mudanças de formato)
- `close`: Limpar recursos e demitir trabalhador

### Configuração do Codec

**H.264 Corda de Codec:**
```typescript
const codecString = `avc1.${profile}${constraint}${level}`;
// Example: "avc1.42C01E" for High Profile @ Level 3.1
```

**H.265 Corda de Codec:**
```typescript
const codecString = `hvc1.${profile_idc}.6.${tier}${level}.B0`;
// Example: "hvc1.1.6.L93.B0" for Main Profile @ Level 3.1
```

### Processamento Unitário NAL

1. **Adição de Código de Início:** Códigos de início do Anexo B (`00 00 00 01`) inseridos em cada NAL
2. **Configuração do Decodificador:** SPS/PPS enviado primeiro para inicializar o decodificador
3. **Decodificação de quadros:** Unidades NAL agrupadas por quadro com metadados PTS
4. **Recuperação de Erros:** Reset automático ao decodificar erros com os parâmetros mais recentes do codec

### Gerenciamento de Memória

- `VideoFrame.close()` chamado após cada quadro para garantir a segurança da memória da GPU
- Pool de quadros gerenciado por trabalhadores para minimizar alocações
- Limpeza automática na demissão do trabalhador ou reinício do decodificador

```typescript
// Example worker message handling
self.onmessage = (event) => {
  const { type, data } = event.data;
  
  if (type === 'codec-info') {
    decoder.configure(data.config);
  } else if (type === 'video-frame') {
    const frame = new VideoFrame(data.canvas, {
      timestamp: data.pts / 90000, // Convert 90kHz to seconds
      duration: 1000 / 30 // Assume 30 FPS
    });
    decoder.decode(frame);
  }
};
```

## WebGPU Renderizador

O renderizador WebGPU oferece dois caminhos de renderização: zero-copy usando GPUExternalTexture e fallback usando copyExternalImageToTexture. Isso maximiza o desempenho mantendo a compatibilidade.

### Renderização de Dois Caminhos

**Caminho de Cópia Zero (Preferido):**
```wgsl
@group(0) @binding(1) var ourTexture: texture_external;

@fragment
fn fs(input: VertexOutput) -> @location(0) vec4f {
  return textureSampleBaseClampToEdge(ourTexture, ourSampler, input.texcoord);
}
```

**Caminho de Reserva (Textura de Estágio):**
```wgsl
@group(0) @binding(1) var ourTexture: texture_2d<f32>;

@fragment
fn fs(input: VertexOutput) -> @location(0) vec4f {
  return textureSample(ourTexture, ourSampler, input.texcoord);
}
```

### Pipeline de Renderização

1. **Inicialização do Dispositivo:** Solicitação WebGPU adaptador e dispositivo
2. **Criação de Recursos:** Criar pipelines de renderização, samplers, vincular grupos
3. **Processamento de Quadros:** Importar textura externa ou cópia do VideoFrame
4. **Render Pass:** Desenhar quad texturizado para a tela
5. **Limpeza:** Destrua a textura externa após cada renderização

### Gerenciamento de Perdas de Dispositivos

```typescript
device.lost.then((info: GPUDeviceLostInfo) => {
  this.deviceLost = true;
  this.onDeviceLostCallback?.();
  // Automatic fallback to WebGL2 occurs at player level
});
```

**Requisitos Principais:**
- Texturas externas devem ser destruídas após cada renderização (especificação WebGPU)
- O formato Canvas utiliza `navigator.gpu.getPreferredCanvasFormat()`
- Modo alfa definido para 'opaco' para renderização de vídeo
- RequestAnimationFrame garante renderização alinhada ao vsync

### Loop de renderização

```typescript
render(videoFrame: VideoFrame): void {
  if (this.pendingFrame) {
    this.pendingFrame.close(); // Cleanup old frame
  }
  this.pendingFrame = videoFrame;
  
  if (this.animationFrameId === null) {
    this.animationFrameId = requestAnimationFrame(() => this.renderLoop());
  }
}
```

## Reserva de Três Níveis

O sistema detecta e adapta automaticamente às capacidades do navegador usando uma abordagem em camadas que garante o máximo desempenho mantendo ampla compatibilidade.

### Detecção por Níveis

```typescript
export function getPlaybackTier(): PlaybackTier {
  if (detectWebCodecs() && detectWebGPU()) {
    return 'tier1';
  }
  if (detectWebCodecs() && (detectWebGL2() || detectOffscreenCanvas())) {
    return 'tier2';
  }
  return 'tier3';
}
```

**Funções de Detecção de Capacidade:**
- `detectWebCodecs()`: Verifique a disponibilidade do VideoDecoder
- `detectWebGPU()`: Verifique a disponibilidade do navegador.gpu
- `detectWebGL2()`: Tente criar um contexto WebGL2
- `detectOffscreenCanvas()`: Verifique a API do OffscreenCanvas

### Degradação em tempo de execução

Quando WebGPU dispositivo é perdido, o sistema automaticamente volta ao WebGL2:

```typescript
device.lost.then((info: GPUDeviceLostInfo) => {
  this.deviceLost = true;
  this.onDeviceLostCallback?.(); // Tr tier switch
});
```

**ConnectionManager gerencia** reconexão com retrocesso exponencial:
- Inicial: 2 segundos
- Seguinte: [2, 4, 8, 16, 32] segundos
- Atraso máximo: 32 segundos para evitar tempos de espera excessivos

### Matriz de Suporte ao Navegador

| Navegador | Nível 1 | Nível 2 | Nível 3 | Notas |
|---------|--------|--------|--------|-------|
| Chrome 113+ | ✅ | ✅ | ✅ | Suporte total de Tier 1 |
| Firefox 130+ | ❌ | ✅ | ✅ | Alternativa do WebGL2 |
| Safari 16.4+ | ❌ | ✅ | ✅ | Alternativa do WebGL2 |
| Safari 18+ | ✅ | ✅ | ✅ | Suporte de nível 1 |
| Navegadores legados | ❌ | ❌ | ✅ | Jogadores atuais |

## Detecção de IA (Frontend)

O sistema de detecção de IA frontend utiliza ONNX Runtime Web com YOLOv11-nano para detecção de objetos em tempo real, rodando inteiramente no navegador com aceleração por hardware.

### Seleção de Backend

O sistema seleciona automaticamente o provedor de execução ideal:

```typescript
// Runtime detection from onnxruntime-web
if (navigator.gpu) {
  // WebGPU execution provider (5-10ms/frame)
  sessionOptions.executionProviders = ['webgpu'];
} else if (detectWasmSimd()) {
  // WASM SIMD execution provider (30-50ms/frame)
  sessionOptions.executionProviders = ['wasm-simd'];
} else {
  // Fallback to plain WASM
  sessionOptions.executionProviders = ['wasm'];
}
```

### YOLOv11-nano Pipeline

**Especificações do Modelo:**
- Entrada: `[1, 3, 640, 640]` float32 NCHW
- Saída: `[1, 84, 8400]` caixas delimitadoras com pontuações de confiança
- Classes: 80 categorias COCO (pessoa, carro, etc.)
- Tamanho do modelo: ~4MB (quantizado)

**Pipeline de Pré-Processamento:**

```typescript
async function preprocessFrame(
  videoFrame: VideoFrame,
  inputSize: number
): Promise<Float32Array> {
  // 1. Create ImageBitmap for safe drawing
  const bitmap = await createImageBitmap(videoFrame);
  
  // 2. Letterbox to 640x640 with gray padding
  const { scale, padX, padY } = letterboxParams(
    bitmap.width, bitmap.height, inputSize
  );
  
  // 3. Draw to OffscreenCanvas
  const canvas = new OffscreenCanvas(inputSize, inputSize);
  const ctx = canvas.getContext('2d');
  ctx.fillStyle = `rgb(114, 114, 114)`; // Gray padding
  ctx.fillRect(0, 0, inputSize, inputSize);
  ctx.drawImage(bitmap, padX, padY, 
    Math.round(bitmap.width * scale), 
    Math.round(bitmap.height * scale)
  );
  
  // 4. Extract and convert pixels to Float32 CHW
  return convertToCHW(canvas);
}
```

**Pipeline de Pós-Processamento:**

1. **Análise Sintática de Saída YOLO:** Extrair caixas delimitadoras e pontuações de confiança
2. **Supressão Não Máxima:** Remover detecções sobrepostas (limiar IoU 0,45)
3. **Suavização EMA:** Aplique média móvel exponencial para acompanhamento (alfa 0,3)
4. **Mapeamento de coordenadas:** Mapeamento do espaço de entrada (640x640) para o quadro original

### Otimização de Desempenho

**Pulando quadro de cena:**
- Salto de quadro configurável (padrão: a cada 3º quadro)
- Resulta em detecção de ~10 FPS em vídeo de 30 FPS
- Equilibra a precisão da detecção com o desempenho

**Cache de modelos:**
- Downloads e caches de modelos via API de cache
- Progresso de download das faixas com porcentagem
- Download de Idempotentes com verificação SHA-256

**Gerenciamento de Memória:**
- Offscreen Canvas reutilizada para evitar vazamentos
- Objetos ImageBitmap fechados após o uso
- Tensores de saída descartados após inferência

### Saída de Detecção

```typescript
interface Detection {
  bbox: [number, number, number, number]; // [x1, y1, x2, y2] in original coordinates
  confidence: number; // [0, 1] confidence score
  classId: number; // COCO class ID (0-79)
  label: string; // Human-readable label
}
```

## Papel do Backend na Detecção de IA

> **O backend NÃO realiza inferência de IA.** Não há subprocesso, nem runtime ONNX, nem sonda de hardware, nem download de modelos no lado do servidor. Esta seção documenta essa decisão de evitar regressões.

Toda a detecção de objetos roda no navegador (veja [Detecção de IA (Frontend)](#ai-detection-frontend) acima e `web/src/lib/ai-detection/`). As únicas funções relacionadas à IA do servidor Go são:

1. **Persistência de configuração** — Configurações de IA + zonas de ROI via `/api/ai/*` (veja [API de IA do backend](#backend-ai-api) abaixo).
2. **Servidor de arquivos modelo** — a rota pública de `GET /models/{filename}` serve `{storage_root}/models/<file>` para que o navegador possa buscar a `.onnx`.

### Por que não há inferência de backend

- O NVR é lançado como um binário estático `CGO_ENABLED=0` compilado cruzadamente para ARM64/ARMv7. Uma Go binding ONNX (`libonnxruntime`) introduziria uma dependência de C, incharia o binário e quebraria a compilação cruzada do ARM. FFmpeg já é a dependência mais pesada.
- O alvo mais baixo suportado (RPi 3B, 1 GB de RAM, Cortex-A53, sem GPU ML) não pode dispensar ciclos para inferência junto com gravação/streaming.
- A detecção ocorre por visualizador em uma transmissão ao vivo já decodificada, então executá-la no navegador evita a re-decodificação no servidor e escala com os espectadores, não com as câmeras.

Se a inferência backend for reconsiderada, ela deve rodar como um sidecar **fora de processo** (subprocesso + IPC), nunca vinculado ao binário principal — preservando a garantia `CGO_ENABLED=0` de compilação estática.

## API de IA de backend

> **O backend NÃO realiza inferência de IA e não expõe nenhuma API de inferência/evento.** A detecção roda inteiramente no navegador (veja `web/src/lib/ai-detection/`). As únicas funções relacionadas à IA do backend Go são (a) persistir a configuração + zonas de ROI e (b) servir o arquivo do modelo.

A API backend para IA é **apenas configuração**:

| Endpoint | Propósito |
|----------|---------|
| `GET /api/ai/status` | Leia configuração global de IA |
| `PUT /api/ai/config` | Atualizar configuração (ativada, limiares, URL do modelo) |
| `GET`/`POST`/`PUT`/`DELETE /api/ai/zones[/{id}]` | CRUD da zona ROI |
| `GET /models/{filename}` | Servir o modelo `.onnx` para o navegador (**público**, sem autenticação) |

Não existe **nenhum** `POST /api/ai/enable`, `POST /api/ai/disable` ou `GET /api/ai/events` SSE ponto final. Para o contrato completo de solicitação/resposta, veja [AI Detection API](api/ai-detection.md).

## Configuração

O sistema de detecção de IA é configurável tanto no frontend quanto no backend para se adaptar a diferentes capacidades e requisitos de hardware.

### Configuração da Frontend

**Configurações de Armazenamento Local:**
```typescript
interface AIConfig {
  enabled: boolean;
  confidenceThreshold: number; // 0.1-0.9
  frameSkip: number; // 1-10 frames
  emaAlpha: number; // 0.1-1.0
}

// Default values
const defaultConfig: AIConfig = {
  enabled: true,
  confidenceThreshold: 0.5,
  frameSkip: 3,
  emaAlpha: 0.3
};
```

**Atualizações de Runtime:**
- Mudanças de configuração aplicadas imediatamente
- Não é necessário reiniciar a página
- As mudanças persistiam automaticamente

### Configuração do Backend

O backend armazena a configuração da IA no bloco de YAML `ai:` (`config.AIConfig`) e persiste as mudanças de runtime de `PUT /api/ai/config` atômicas. **Não há **requisito de hardware backend para IA** — nenhuma inferência roda do lado do servidor.

- `enabled`, `confidence_threshold`, `frame_skip_rate` `model_url` — configurações globais de IA
- `enabled_cameras` — câmeras autorizadas a mostrar IA na interface
- `zones` — `map[cameraID][]ROI`, `[0,1]` vértices de polígonos normalizados

**Arquivo modelo:** coloque `.onnx` modelos em `{storage_root}/models/` (a CLI do `aglus-nvr download-model` faz isso para o `yolo11n.onnx` padrão). O navegador os recupera via `GET /models/{filename}`.

### Ajuste de Performance

**Configurações de Frontend (inferência do navegador):**
- `frameSkip`: valores mais altos reduzem a CPU do cliente, mas reduzem a frequência de detecção
- `confidenceThreshold`: valores mais altos reduzem falsos positivos, mas podem deixar passar objetos
- `emaAlpha`: valores mais baixos dão um acompanhamento mais suave, mas uma resposta mais lenta

## Testes

O pipeline de inferência do lado do navegador é testado diretamente por unidades; A lógica da zona de backend/configuração é testada em Go. Não existem **nenhum** testes de inferência backend / ONNX / sonda / download — nenhum código assim existe.

### Inventário de Teste

**Go testes (backend — apenas configuração + zonas):**
- `internal/ai/zones_test.go` — 43 testes: CRUD de zona, `PointInPolygon`, `FilterDetectionsByZone`, `GetEnabledZones`, validação
- `internal/config/config_ai_test.go` — 15 testes: padrões de configuração da IA + validação (faixa de limiar, salto de quadro, pontos/coordenadas de zona)

**Testes frontend (inferência do lado do navegador — vitest):**
- `web/src/lib/ai-detection/inference.test.ts` — Análise sintática de saída YOLO, NMS, IoU, sigmoide, suavização EMA, mapeamento de coordenadas
- `web/src/lib/ai-detection/runtime.test.ts` — detecção de WebGPU, WASM fallback, cache de modelos, lista branca de URLs/validação SSRF, ciclo de vida de iniciação/execução/descarte (runtime simulado em ONNX)

### Lacunas

- Nenhum E2E faz testes em todo o pipeline (carregar modelo → decodificar o quadro → detectar → overlay de renderização). Maior lacuna aberta nos testes.
- Sem benchmark de precisão/recall contra quadros rotulados.
- A inferência é testada com um tempo de execução simulado do ONNX; Nenhum teste roda um modelo `.onnx` real.