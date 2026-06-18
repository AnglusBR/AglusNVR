# API de estatísticas e configurações

## Estatísticas do sistema

**Ponto final:** `GET /api/stats`

Obtenha estatísticas do sistema, incluindo uso de armazenamento e contagens de gravação.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/stats"
```

**Resposta:**
```json
{
  "total_bytes": 1073741824,
  "used_bytes": 536870912,
  "recording_count": 1000,
  "camera_count": 4
}
```

## Tendências de estatísticas

**Ponto final:** `GET /api/stats/trends`

Obtenha tendências de uso de armazenamento ao longo do tempo.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/stats/trends"
```

**Resposta:**
```json
{
  "trends": [
    {
      "date": "2024-01-01",
      "total_bytes": 1000000000,
      "used_bytes": 500000000,
      "recording_count": 950
    }
  ]
}
```

## Obter configurações

**Ponto final:** `GET /api/settings`

Obtenha as configurações atuais.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/settings"
```

**Resposta:**
```json
{
  "server": {
    "listen": ":9090"
  },
  "storage": {
    "root_dir": "/var/lib/aglus-nvr",
    "segment_duration": "30s"
  },
  "cleanup": {
    "retention_days": 30,
    "check_interval": "1h",
    "disk_threshold_percent": 95
  },
  "auth": {
    "username": "admin"
  }
}
```

## Atualizar configurações

**Ponto final:** `PUT /api/settings`

Atualize as definições de configuração.

**Corpo da solicitação:**
```json
{
  "cleanup": {
    "retention_days": 60,
    "disk_threshold_percent": 90,
    "check_interval": "30m"
  }
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "cleanup": {
      "retention_days": 60,
      "disk_threshold_percent": 90,
      "check_interval": "30m"
    }
  }' \
  "http://localhost:9090/api/settings"
```

**Resposta:**
```json
{
  "status": "updated"
}
```

## Obter configurações de mesclagem

**Ponto final:** `GET /api/settings/merge`

Obtenha a configuração das configurações de mesclagem global.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/settings/merge"
```

**Resposta:**
```json
{
  "enabled": true,
  "check_interval": "1h",
  "window_size": "1h",
  "batch_limit": 200,
  "min_segment_age": "10m",
  "min_segments_to_merge": 3
}
```

## Update Merge Settings

**Ponto final:** `PUT /api/settings/merge`

Atualize as configurações de mesclagem global.

**Corpo da solicitação:**
```json
{
  "enabled": true,
  "check_interval": "30m",
  "window_size": "2h",
  "batch_limit": 100,
  "min_segment_age": "15m",
  "min_segments_to_merge": 5
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "check_interval": "30m",
    "batch_limit": 100
  }' \
  "http://localhost:9090/api/settings/merge"
```

**Resposta:**
```json
{
  "status": "updated"
}
```

## API de configurações de streaming e transcodificação

## Obtenha configurações de streaming

**Ponto final:** `GET /api/settings/streaming`

Obtenha a configuração de streaming atual, incluindo protocolo padrão, configurações de baixa latência WebRTC, FLV e HLS.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/settings/streaming"
```

**Resposta:**
```json
{
  "default_protocol": "webrtc",
  "webrtc": {
    "enabled": true,
    "max_viewers": 10,
    "idle_timeout": "5m"
  },
  "flv": {
    "enabled": true,
    "max_viewers": 10,
    "idle_timeout": "5m",
    "gop_cache_size": 25
  },
  "hls": {
    "low_latency": true
  }
}
```

## Atualizar configurações de streaming

**Ponto final:** `PUT /api/settings/streaming`

Atualize a configuração de streaming. Todos os campos são opcionais para atualizações parciais.

**Corpo da solicitação:**
```json
{
  "default_protocol": "flv",
  "webrtc": {
    "enabled": true,
    "max_viewers": 5,
    "idle_timeout": "10m"
  },
  "flv": {
    "enabled": true,
    "max_viewers": 5,
    "idle_timeout": "10m",
    "gop_cache_size": 50
  },
  "hls": {
    "low_latency": false
  }
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "default_protocol": "flv",
    "webrtc": {
      "max_viewers": 5
    }
  }' \
  "http://localhost:9090/api/settings/streaming"
```

**Resposta:**
```json
{
  "status": "updated"
}
```

## Obtenha configurações de transcodificação

**Ponto final:** `GET /api/settings/transcoding`

Obtenha a configuração de transcodificação global.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/settings/transcoding"
```

**Resposta:**
```json
{
  "enabled": true,
  "max_workers": 2
}
```

## Atualizar configurações de transcodificação

**Ponto final:** `PUT /api/settings/transcoding`

Atualize a configuração de transcodificação global.

**Corpo da solicitação:**
```json
{
  "enabled": true,
  "max_workers": 2
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "max_workers": 2
  }' \
  "http://localhost:9090/api/settings/transcoding"
```

**Resposta:**
```json
{
  "status": "updated"
}
```
