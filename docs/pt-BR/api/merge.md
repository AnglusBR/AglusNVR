# API de configuração de mesclagem e lapso de tempo

## Merge API

### Get Merge Status

**Ponto final:** `GET /api/merge/status`

Obtenha o status e as estatísticas atuais do gerenciador de mesclagem.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/merge/status"
```

**Resposta:**
```json
{
  "enabled": true,
  "error_count": 0,
  "files_created": 9,
  "last_run_time": "2026-05-11T06:37:41Z",
  "segments_merged": 235
}
```

### Obtenha contagens de mesclagem pendentes

**Ponto final:** `GET /api/merge/pending`

Obtenha a contagem de segmentos pendentes de mesclagem para cada câmera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/merge/pending"
```

**Resposta:**
```json
{
  "pending": {
    "front-door": 99,
    "backyard": 145
  }
}
```

## Configuração de mesclagem de câmeras

### Update Camera Merge Configuration

**Ponto final:** `PUT /api/cameras/{id}/merge-config`

Defina substituições de configuração de mesclagem para uma câmera específica.

**Corpo da solicitação:**
```json
{
  "enabled": true,
  "check_interval": "30m",
  "window_size": "1h", 
  "batch_limit": 150,
  "min_segment_age": "5m",
  "min_segments_to_merge": 2
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": false,
    "batch_limit": 50
  }' \
  "http://localhost:9090/api/cameras/front-door/merge-config"
```

**Resposta:**
```json
{
  "status": "updated"
}
```

### Delete Camera Merge Configuration

**Ponto final:** `DELETE /api/cameras/{id}/merge-config`

Remove per-camera merge overrides.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/cameras/front-door/merge-config"
```

**Resposta:**
```json
{
  "status": "reset"
}
```

## Camera Timelapse Configuration

### Obtenha a configuração do lapso de tempo da câmera

**Ponto final:** `GET /api/cameras/{id}/timelapse`

Obtenha a configuração de lapso de tempo para uma câmera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/timelapse"
```

**Resposta:**
```json
{
  "enabled": false,
  "interval": "30s",
  "output_fps": 30,
  "video_codec": "h264",
  "delete_original": false
}
```

### Update Camera Timelapse Config

**Ponto final:** `PUT /api/cameras/{id}/timelapse`

Update the timelapse configuration for a camera.

**Corpo da solicitação:**
```json
{
  "enabled": true,
  "interval": "10s",
  "output_fps": 15,
  "video_codec": "h264",
  "delete_original": false,
  "merge_mode": "auto",
  "merge_output_fps": 30
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "enabled": true,
    "interval": "10s",
    "output_fps": 15
  }' \
  "http://localhost:9090/api/cameras/front-door/timelapse"
```

**Resposta:** Retorna a matriz completa de configuração da câmera após a atualização.
