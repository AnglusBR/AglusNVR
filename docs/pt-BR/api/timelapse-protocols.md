# API de lapso de tempo e protocolos

## API de lapso de tempo

### Status do gerenciador de lapso de tempo

**Ponto final:** `GET /api/timelapse/status`

Obtenha o status global do gerenciador de timelapse e as configurações de mesclagem padrão.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/timelapse/status"
```

**Resposta:**
```json
{
  "merge_enabled": false,
  "merge_mode": "auto",
  "daily_merge": true,
  "merge_output_fps": 30
}
```

## API de protocolos

### Obtenha protocolos suportados

**Ponto final:** `GET /api/protocols`

Obtenha a lista de todos os protocolos de câmera suportados com suas codificações e capacidades.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/protocols"
```

**Resposta:**
```json
{
  "protocols": [
    {
      "id": "rtsp",
      "label": "RTSP",
      "encodings": ["h264", "h265", "mjpeg"],
      "built_in": true,
      "capabilities": {
        "hls": true,
        "ptz": false,
        "snapshot": false,
        "discovery": false,
        "auth": true
      }
    },
    {
      "id": "http",
      "label": "HTTP JPEG",
      "encodings": ["jpeg"],
      "built_in": true,
      "capabilities": {
        "hls": false,
        "ptz": false,
        "snapshot": true,
        "discovery": false,
        "auth": true
      }
    },
    {
      "id": "onvif",
      "label": "ONVIF",
      "encodings": ["h264", "h265", "mjpeg"],
      "built_in": true,
      "capabilities": {
        "hls": true,
        "ptz": true,
        "snapshot": false,
        "discovery": true,
        "auth": true
      }
    },
    {
      "id": "xiaomi",
      "label": "Xiaomi",
      "encodings": ["h264", "h265"],
      "built_in": true,
      "capabilities": {
        "hls": true,
        "ptz": false,
        "snapshot": false,
        "discovery": true,
        "auth": true
      }
    }
  ]
}
```

## API de recursos

### Get Features

**Ponto final:** `GET /api/features`

Get enabled/disabled protocol feature flags.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/features"
```

**Resposta:**
```json
{
  "protocols": {
    "rtsp": true,
    "onvif": true,
    "xiaomi": false
  }
}
```

### Recursos de atualização

**Ponto final:** `PUT /api/features`

Atualizar sinalizadores de recursos de protocolo.

**Corpo da solicitação:**
```json
{
  "protocols": {
    "rtsp": true,
    "xiaomi": false
  }
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "protocols": {
      "rtsp": true,
      "xiaomi": false
    }
  }' \
  "http://localhost:9090/api/features"
```

**Resposta:**
```json
{
  "protocols": {
    "rtsp": true,
    "onvif": true,
    "xiaomi": false
  }
}
```
