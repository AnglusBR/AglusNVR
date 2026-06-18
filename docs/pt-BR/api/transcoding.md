# Transcoding API

## Transcoding Self-Check

**Ponto final:** `GET /api/transcoding/check`

Executa uma autoverificação dos recursos de transcodificação do sistema, incluindo validação de hardware, disponibilidade do FFmpeg e estimativa de desempenho.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/check"
```

**Resposta:**
```json
{
  "supported": true,
  "ffmpeg_status": "available",
  "encoders": {
    "h264": "libx264",
    "h265": "libx265"
  },
  "decoders": {
    "h264": "h264",
    "h265": "hevc"
  },
  "warnings": [],
  "max_concurrent": 2,
  "estimated_fps": 3.5,
  "total_cores": 4,
  "total_memory_mb": 1024,
  "h264_encoder_type": "software",
  "h265_encoder_type": "software",
  "h264_decoder_type": "software",
  "h265_decoder_type": "software",
  "max_encode_width": 1920,
  "max_encode_height": 1080,
  "devices": [
    {
      "type": "cpu",
      "name": "ARMv7 Processor rev 5 (v7l)"
    }
  ]
}
```

**Campos de resposta:**

| Campo | Tipo | Descrição |
|-------|------|-------------|
| `supported` | booleano | Se a transcodificação é suportada |
| `ffmpeg_status` | corda | Status FFmpeg: "disponível", "baixando", "não_instalado", "com falha" |
| `encoders` | objeto | Bibliotecas de codificadores disponíveis (h264, h265) |
| `decoders` | objeto | Bibliotecas de decodificadores disponíveis (h264, h265) |
| `warnings` | array[] | Avisos legíveis sobre limitações |
| `max_concurrent` | inteiro | Fluxos de transcodificação simultâneos máximos estimados |
| `estimated_fps` | flutuar | FPS de transcodificação estimado neste hardware |
| `total_cores` | inteiro | Total de núcleos de CPU disponíveis |
| `total_memory_mb` | inteiro | Memória total do sistema em MB |
| `h264_encoder_type` | corda | "software", "hardware" ou "desconhecido" |
| `h265_encoder_type` | corda | "software", "hardware" ou "desconhecido" |
| `devices` | array[] | Informações do dispositivo de hardware |

## Status FFmpeg

**Ponto final:** `GET /api/transcoding/ffmpeg/status`

Retorna o status atual de download/disponibilidade do FFmpeg. Não expõe o caminho binário para segurança.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/ffmpeg/status"
```

**Resposta (instalada):**
```json
{
  "status": "available",
  "version": "6.0",
  "download_progress": 100
}
```

**Resposta (não instalada):**
```json
{
  "status": "not_installed",
  "version": "",
  "download_progress": 0
}
```

## Baixar FFmpeg

**Ponto final:** `POST /api/transcoding/ffmpeg/download`

Inicie um download binário FFmpeg em segundo plano. Idempotente: retorna o status atual se já estiver baixando ou disponível.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/transcoding/ffmpeg/download"
```

**Resposta (aceita - download iniciado):**
```json
{
  "status": "downloading",
  "download_progress": 0
}
```

**Resposta (já disponível):**
```json
{
  "status": "available",
  "version": "6.0"
}
```

**Resposta (já baixando):**
```json
{
  "status": "downloading",
  "download_progress": 45
}
```

## Tente novamente baixar FFmpeg

**Ponto final:** `POST /api/transcoding/ffmpeg/download/retry`

Tente novamente um download de FFmpeg com falha. Funciona apenas quando o status é "falhou". Retorna 409 Conflict se um download já estiver em andamento.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/transcoding/ffmpeg/download/retry"
```

**Resposta (nova tentativa iniciada):**
```json
{
  "status": "downloading",
  "download_progress": 0
}
```

**Resposta (conflito - já em andamento):**
```json
{
  "error": "download already in progress",
  "status": "downloading"
}
```

## Status do gerenciador de transcodificação

**Ponto final:** `GET /api/transcoding/status`

Retorna o status geral do subsistema de transcodificação, incluindo estado habilitado, informações de hardware, comprimento da fila e trabalhos ativos.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/status"
```

**Resposta:**
```json
{
  "enabled": true,
  "hardware": {
    "h264_encoder": "libx264",
    "h265_encoder": "libx265"
  },
  "queue_length": 5,
  "active_jobs": 2,
  "recent_results": []
}
```

## Listar tarefas de transcodificação

**Ponto final:** `GET /api/transcoding/tasks`

Retorna tarefas de transcodificação paginadas com filtros opcionais.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `status` | corda | Não | Filtrar por status da tarefa | `pending` |
| `camera_id` | corda | Não | Filtrar por ID da câmera | `front-door` |
| `limit` | inteiro | Não | Resultados máximos (padrão: 50) | `20` |
| `offset` | inteiro | Não | Deslocamento de resultado para paginação | `0` |
| `page` | inteiro | Não | Número de página (indexado 1, alternativa ao deslocamento) | `1` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/tasks?status=pending&limit=10"
```

**Resposta:**
```json
{
  "tasks": [
    {
      "id": 1,
      "camera_id": "front-door",
      "recording_id": "1704123456789012345",
      "status": "pending",
      "input_format": "h265",
      "output_format": "h264",
      "created_at": "2024-01-01T12:34:56.789Z"
    }
  ],
  "total": 1,
  "limit": 10,
  "offset": 0,
  "page": 1
}
```

## Criar tarefa de transcodificação

**Ponto final:** `POST /api/transcoding/tasks`

Enfileirar manualmente uma tarefa de transcodificação. Validates the recording exists and the camera has transcoding enabled.

**Corpo da solicitação:**
```json
{
  "camera_id": "front-door",
  "recording_id": "1704123456789012345",
  "target_codec": "h264"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "front-door",
    "recording_id": "1704123456789012345",
    "target_codec": "h264"
  }' \
  "http://localhost:9090/api/transcoding/tasks"
```

**Resposta (criada em 201):**
```json
{
  "id": 1,
  "camera_id": "front-door",
  "recording_id": "1704123456789012345",
  "input_path": "/data/recordings/h265/front-door_1704123456789012345.mp4",
  "input_format": "h265",
  "output_path": "/data/recordings/h265/front-door_1704123456789012345.mp4.transcoded.mp4",
  "output_format": "h264",
  "created_at": "2024-01-01T12:34:56.789999999"
}
```

## Excluir tarefa de transcodificação

**Ponto final:** `DELETE /api/transcoding/tasks/{id}`

Cancele uma tarefa pendente ou em execução. Retorna 409 para tarefas concluídas, com falha ou já canceladas.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/transcoding/tasks/1"
```

**Resposta:**
```json
{
  "id": 1,
  "status": "cancelled"
}
```

## Tentar novamente a tarefa de transcodificação

**Ponto final:** `POST /api/transcoding/tasks/{id}/retry`

Create a new pending transcoding task from a failed task.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/transcoding/tasks/1/retry"
```

**Resposta (criada em 201):**
```json
{
  "id": 2,
  "camera_id": "front-door",
  "recording_id": "1704123456789012345",
  "input_path": "/data/recordings/h265/front-door_1704123456789012345.mp4",
  "input_format": "h265",
  "output_format": "h264",
  "created_at": "2024-01-01T12:35:00.000000000"
}
```

## Create Backfill Tasks

**Ponto final:** `POST /api/transcoding/backfill`

Enqueue all untranscoded recordings for a camera into the transcode queue.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `camera_id` | corda | Sim | Camera ID to backfill | `front-door` |

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/transcoding/backfill?camera_id=front-door"
```

**Resposta:**
```json
{
  "enqueued": 45,
  "skipped": 5,
  "total": 50
}
```

## Configurações de transcodificação de câmera

**Ponto final:** `GET /api/transcoding/cameras`

Retorna a configuração de transcodificação resolvida para cada câmera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/cameras"
```

**Resposta:**
```json
{
  "global_enabled": true,
  "cameras": [
    {
      "camera_id": "front-door",
      "camera_name": "Front Door",
      "enabled": true,
      "target_codec": "h264",
      "preset": "fast",
      "bitrate": 1000000
    },
    {
      "camera_id": "backyard",
      "camera_name": "Backyard",
      "enabled": false,
      "target_codec": "h264",
      "preset": "",
      "bitrate": 0
    }
  ]
}
```

## Gravações sem transcodificação

**Ponto final:** `GET /api/transcoding/recordings-without-transcode`

Returns the count of recordings that have not been transcoded for a camera.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `camera_id` | corda | Sim | ID da câmera para verificar | `front-door` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/transcoding/recordings-without-transcode?camera_id=front-door"
```

**Resposta:**
```json
{
  "count": 45
}
```
