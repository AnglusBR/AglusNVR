# API de câmeras

## Gerenciamento de Câmera

### Câmeras List

**Ponto final:** `GET /api/cameras`

Obtenha uma lista de todas as câmeras configuradas.

**Pedido:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras"
```

**Resposta:**
```json
[
  {
    "id": "front-door",
    "name": "Front Door",
    "protocol": "rtsp",
    "encoding": "h264",
    "url": "rtsp://192.168.1.100:554/stream",
    "enabled": true,
    "status": "recording",
    "last_seen": "2024-01-01T10:15:00Z",
    "retention_days": 30,
    "username": "admin",
    "has_password": true,
    "sub_stream_url": "",
    "snapshot_url": "",
    "sample_interval": 1,
    "hls_max_fps": 30,
    "did": "",
    "vendor": ""
  }
]
```

### Criar Câmera

**Ponto final:** `POST /api/cameras`

Adicione uma nova configuração de câmera.

**Solicito Corpo:**
```json
{
  "name": "Front Door",
  "protocol": "rtsp",
  "encoding": "h264",
  "url": "rtsp://192.168.1.100:554/stream",
  "username": "admin",
  "password": "secret",
  "enabled": true,
  "retention_days": 30,
  "sub_stream_url": "rtsp://192.168.1.100:554/sub_stream",
  "snapshot_url": "http://192.168.1.100:8080/snapshot",
  "sample_interval": 1,
  "hls_max_fps": 30,
  "push_targets": [
    {
      "id": "backup-nvr",
      "name": "Backup NVR",
      "protocol": "rtmp",
      "url": "rtmp://backup.example.com:1935/live/front-door",
      "enabled": true
    }
  ]
}
```

**Pedido:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Front Door",
    "protocol": "rtsp",
    "encoding": "h264",
    "url": "rtsp://192.168.1.100:554/stream",
    "username": "admin",
    "password": "secret",
    "enabled": true
  }' \
  "http://localhost:9090/api/cameras"
```

**Resposta (201 Criados):**
```json
{
  "id": "front-door",
  "name": "Front Door",
  "protocol": "rtsp",
  "encoding": "h264",
  "url": "rtsp://192.168.1.100:554/stream",
  "enabled": true
}
```

### Pegue a câmera

**Ponto final:** `GET /api/cameras/{id}`

Adquira uma configuração específica da câmera.

**Pedido:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door"
```

**Resposta:**
```json
{
  "id": "front-door",
  "name": "Front Door", 
  "protocol": "rtsp",
  "encoding": "h264",
  "url": "rtsp://192.168.1.100:554/stream",
  "enabled": true,
  "status": "recording",
  "last_seen": "2024-01-01T10:15:00Z"
}
```

### Atualização da câmera

**Ponto final:** `PUT /api/cameras/{id}`

Atualize a configuração da câmera. Todos os campos são opcionais para atualizações parciais.

**Solicito Corpo:**
```json
{
  "name": "Updated Front Door",
  "url": "rtsp://192.168.1.100:554/new_stream",
  "enabled": false,
  "retention_days": 7
}
```

**Pedido:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Front Door",
    "url": "rtsp://192.168.1.100:554/new_stream",
    "enabled": false
  }' \
  "http://localhost:9090/api/cameras/front-door"
```

**Resposta:**
```json
{
  "id": "front-door",
  "name": "Updated Front Door",
  "protocol": "rtsp",
  "encoding": "h264",
  "url": "rtsp://192.168.1.100:554/new_stream",
  "enabled": false
}
```

### Delete Camera

**Ponto final:** `DELETE /api/cameras/{id}`

Exclua uma configuração de câmera.

**Pedido:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/cameras/backyard"
```

**Resposta:**
```json
{
  "status": "deleted"
}
```

### Conexão de Teste

**Ponto final:** `POST /api/cameras/test-connection`

Conexão da câmera de teste com configuração fornecida.

**Solicito Corpo:**
```json
{
  "protocol": "rtsp",
  "encoding": "h264",
  "url": "rtsp://192.168.1.100:554/stream",
  "username": "admin", 
  "password": "secret"
}
```

**Pedido:**
```bash
curl -u username:password \
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

**Resposta:**
```json
{
  "success": true,
  "message": "Connection successful",
  "details": {
    "protocol": "rtsp",
    "encoding": "h264",
    "latency_ms": 45,
    "frames_received": 10
  }
}
```

### Iniciar a câmera

**Ponto final:** `POST /api/cameras/{id}/start`

Comece a gravar para uma câmera.

**Pedido:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/cameras/front-door/start"
```

**Resposta:**
```json
{
  "status": "started"
}
```

### Câmera de Pare

**Ponto final:** `POST /api/cameras/{id}/stop`

Pare de gravar para uma câmera.

**Pedido:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/cameras/front-door/stop"
```

**Resposta:**
```json
{
  "status": "stopped"
}
```

## Fotografia de Câmera

**Ponto final:** `GET /api/cameras/{id}/snapshot`

Tire uma imagem JPEG instantânea com uma câmera.

**Pedido:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/snapshot" \
  -o snapshot.jpg
```

**Resposta:** JPEG imagem com `Content-Type: image/jpeg` e `Cache-Control: max-age=5`

## Status de Empurramento da Câmera

**Ponto final:** `GET /api/cameras/{id}/push-status`

Veja o status em tempo real dos alvos push-out da câmera (RTMP/RTSP). Retorna estado de conexão por alvo, bitrate de saída, tempo de atividade e erros.

**Pedido:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/push-status"
```

**Resposta:**
```json
{
  "camera_id": "front-door",
  "targets": [
    {
      "id": "backup-nvr",
      "name": "Backup NVR",
      "protocol": "rtmp",
      "url": "rtmp://backup.example.com:1935/live/front-door",
      "status": "streaming",
      "kbps": 270.8,
      "enabled": true,
      "uptime": "1m16s",
      "error": "",
      "updated_at": "2026-06-17T06:15:37+08:00"
    }
  ]
}
```

**Valores `status` alvo:** `idle` (desativado), `connecting`, `streaming`, `reconnecting`, `error`.
