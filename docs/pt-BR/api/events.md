# API de eventos

## Fluxo de eventos (SSE)

**Ponto final:** `GET /api/events`

Server-Sent Events endpoint that streams events from the global EventBus. Suporta filtragem de tópicos opcional.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `filter` | corda | Não | Filtrar eventos por prefixo de tópico | `onvif.` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/events?filter=onvif."
```

**Response:** SSE stream (`text/event-stream`) with 15-second heartbeat keepalive.

```
event: onvif.discovery
data: {"topic":"onvif.discovery","data":{"device":"192.168.1.104"}}

: ping
```

## Fluxo de eventos de câmera (SSE)

**Ponto final:** `GET /api/cameras/{id}/events`

Endpoint de eventos enviados pelo servidor que transmite eventos específicos da câmera do barramento de eventos. Filters events by camera ID extracted from the event data.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/events"
```

**Response:** SSE stream (`text/event-stream`) with 15-second heartbeat keepalive.

```
event: camera.status
data: {"topic":"camera.status","data":{"camera_id":"front-door","status":"recording"}}

: ping
```

## Telemetria

**Ponto final:** `POST /api/telemetry`

Envie eventos de telemetria de reprodução. Taxa limitada a 10 solicitações/segundo por IP. Requer autenticação.

**Corpo da solicitação:**
```json
{
  "event": "playback_start",
  "camera_id": "front-door",
  "duration_ms": 15000,
  "details": {
    "protocol": "hls",
    "quality": "high"
  }
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "event": "playback_start",
    "camera_id": "front-door",
    "duration_ms": 15000
  }' \
  "http://localhost:9090/api/telemetry"
```

**Resposta:** `204 No Content` em caso de sucesso.
