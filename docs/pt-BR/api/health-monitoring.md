# API de monitoramento de integridade

## Camera Health Status Overview

**Ponto final:** `GET /api/health/cameras`

Get aggregated camera health status overview. Public endpoint (rate-limited).

**Solicitação:**
```bash
curl http://localhost:9090/api/health/cameras
```

**Resposta:**
```json
{
  "total": 4,
  "recording": 3,
  "reconnecting": 0,
  "error": 0,
  "offline": 1,
  "details": [
    {
      "id": "front-door",
      "name": "Front Door",
      "status": "recording",
      "score": 95
    },
    {
      "id": "backyard",
      "name": "Backyard",
      "status": "offline",
      "score": 0
    }
  ]
}
```

## Detailed Health Monitoring Status

**Ponto final:** `GET /api/health/status`

Obtenha status detalhado de monitoramento de integridade de todas as câmeras.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/health/status"
```

**Resposta:**
```json
{
  "front-door": {
    "status": "recording",
    "last_seen": "2024-01-01T12:34:56Z",
    "error_count": 0,
    "uptime": "2h34m15s"
  }
}
```

## Recent Health Events

**Ponto final:** `GET /api/health/events`

Get paginated health events from the database.

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `camera_id` | corda | Não | Filtrar por ID da câmera | `front-door` |
| `event_type` | corda | Não | Filter by event type | `disconnected` |
| `since` | corda | Não | Return events after this timestamp | `2024-01-01T00:00:00Z` |
| `limit` | inteiro | Não | Maximum results (default: 50) | `20` |
| `offset` | integer | Não | Result offset for pagination | `0` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/health/events?camera_id=front-door&limit=10"
```

**Resposta:**
```json
{
  "events": [
    {
      "id": 1,
      "camera_id": "front-door",
      "event_type": "disconnected",
      "message": "Camera disconnected",
      "timestamp": "2024-01-01T12:34:56Z"
    }
  ],
  "total": 1
}
```

## Camera Stability Scores

**Ponto final:** `GET /api/health/stability`

Get stability quality scores for all cameras.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/health/stability"
```

**Resposta:**
```json
{
  "cameras": {
    "front-door": {
      "score": 95,
      "uptime_percentage": 99.5,
      "total_events": 2
    },
    "backyard": {
      "score": 70,
      "uptime_percentage": 85.0,
      "total_events": 15
    }
  }
}
```

## Estabilidade por câmera

**Ponto final:** `GET /api/health/stability/{camera_id}`

Get stability quality data for a single camera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/health/stability/front-door"
```

**Resposta:**
```json
{
  "score": 95,
  "uptime_percentage": 99.5,
  "total_events": 2
}
```

## Camera-Specific Health Info

**Ponto final:** `GET /api/cameras/{id}/health`

Get health status for a specific camera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/health"
```

**Resposta:**
```json
{
  "status": "recording",
  "last_seen": "2024-01-01T12:34:56Z",
  "error_count": 0,
  "uptime": "2h34m15s"
}
```
