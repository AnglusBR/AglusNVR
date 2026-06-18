# Estatísticas e eventos da câmera

## Estatísticas de gravação da câmera

**Ponto final:** `GET /api/cameras/{id}/stats`

Obtenha estatísticas de gravação para uma câmera específica.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/stats"
```

**Resposta:**
```json
{
  "recording_count": 150,
  "total_size": 1073741824
}
```

## Fluxo de eventos de câmera (SSE)

**Ponto final:** `GET /api/cameras/{id}/events`

Endpoint de eventos enviados pelo servidor que transmite eventos específicos da câmera do barramento de eventos. Filtra eventos por ID da câmera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/events"
```

**Resposta:** Fluxo SSE (`text/event-stream`). Keepalive de batimento cardíaco de 15 segundos.

```
event: camera.status
data: {"topic":"camera.status","data":{"camera_id":"front-door","status":"recording"}}

: ping
```
