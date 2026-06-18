# Referência da API AglusNVR

This is the REST API reference for AglusNVR. Todos os endpoints da API são documentados com seus formatos de solicitação, esquemas de resposta e exemplos de comandos `curl`.

A maioria dos endpoints requer autenticação via HTTP Basic Auth. See [Authentication](authentication.md) for details.

## Seções de API

| Section | Arquivo | Descrição |
|---------|------|-------------|
| Autenticação | [authentication.md](authentication.md) | Login, setup, capabilities, basic auth usage |
| Saúde e Sistema | [system.md](system.md) | Health check, readiness check, system stats |
| Monitoramento de Saúde | [health-monitoring.md](health-monitoring.md) | Status de integridade da câmera, pontuações de estabilidade, eventos de integridade |
| Câmeras | [cameras.md](cameras.md) | Câmera CRUD, conexão de teste, início/parada, instantâneos |
| Transmissão | [streaming.md](streaming.md) | HLS, WebRTC, HTTP-FLV, WebSocket streaming, protocolos de câmera |
| Camera Stats & Events | [camera-details.md](camera-details.md) | Estatísticas de gravação, fluxo de eventos da câmera (SSE) |
| ONVIF | [onvif.md](onvif.md) | Controle PTZ, predefinições, imagens, rede, usuários, descoberta |
| Gravações | [recordings.md](recordings.md) | Listar, obter, excluir, baixar gravações, quadros de lapso de tempo |
| Arquivos | [arquivos.md](archives.md) | Archive groups, retention management |
| Configurações | [configurações.md](settings.md) | System stats, settings CRUD, merge/streaming/transcoding settings |
| Xiaomi | [xiaomi.md](xiaomi.md) | Autenticação em nuvem, captcha, gerenciamento de dispositivos |
| Merge & Timelapse Config | [merge.md](merge.md) | Status de mesclagem, contagens pendentes, configuração de mesclagem/timelapse de câmera |
| Transcodificação | [transcodificação.md](transcoding.md) | Gerenciamento FFmpeg, tarefas de transcodificação, preenchimento, configurações de câmera |
| Detecção de IA | [ai-detection.md](ai-detection.md) | AI config, ROI zones, model serving (browser-side inference) |
| Eventos | [events.md](events.md) | Event stream (SSE), camera events, telemetry |
| Timelapse e protocolos | [protocolos de timelapse.md](timelapse-protocols.md) | Timelapse status, supported protocols, feature flags |
| Backup | [backup.md](backup.md) | Criar/listar backups de banco de dados |
| Respostas de erro | [erros.md](errors.md) | Códigos de erro, códigos de status HTTP, exemplos comuns |
| Prometheus Metrics | [../metrics.md](../metrics.md) | Todas as definições, tipos, rótulos e uso de métricas Prometheus |

## Início rápido

### Teste Básico de Autenticação

```bash
# Test health endpoint (no auth required)
curl http://localhost:9090/api/health

# Test authentication
curl -u admin:password http://localhost:9090/api/cameras
```

### Operações Comuns

```bash
# List all recordings
curl -u admin:password "http://localhost:9090/api/recordings"

# Add a new camera
curl -u admin:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Living Room Cam",
    "protocol": "rtsp",
    "encoding": "h264",
    "url": "rtsp://192.168.1.50:554/stream",
    "enabled": true
  }' \
  "http://localhost:9090/api/cameras"

# Download a recording
curl -u admin:password \
  -o recording.mp4 \
  "http://localhost:9090/api/recordings/1704123456789012345/download"

# Update settings to clean up recordings older than 7 days
curl -u admin:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "cleanup": {
      "retention_days": 7
    }
  }' \
  "http://localhost:9090/api/settings"

# Test camera connection
curl -u admin:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "protocol": "rtsp",
    "encoding": "h264",
    "url": "rtsp://192.168.1.100:554/stream",
    "username": "admin",
    "password": "secret"
  }' \
  "http://localhost:9090/api/cameras/test-connection"
```

### Exemplo de streaming HLS

```bash
# Get HLS playlist
curl -u admin:password \
  "http://localhost:9090/api/cameras/living-room/stream/stream.m3u8"

# Get HLS segment  
curl -u admin:password \
  "http://localhost:9090/api/cameras/living-room/stream/segment_001.ts"
```

### Xiaomi Camera Setup

```bash
# Authenticate with Xiaomi cloud
curl -u admin:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "xiaomi@example.com",
    "password": "password123"
  }' \
  "http://localhost:9090/api/xiaomi/auth"

# List Xiaomi devices
curl -u admin:password \
  "http://localhost:9090/api/xiaomi/devices"
```

## Respostas de erro

Todas as respostas de erro seguem este formato:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

Consulte [Respostas de erro](errors.md) para obter a referência completa do código de erro e os códigos de status HTTP.
