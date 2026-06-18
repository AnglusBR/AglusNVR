# Streaming API

## Transmissão HLS

**Ponto final:** `GET /api/cameras/{id}/stream/*path`

Fornece transmissão ao vivo HLS sob demanda.

**Solicitar (lista de reprodução HLS):**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/stream/stream.m3u8"
```

**Solicitação (segmento HLS):**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/stream/segment_001.ts"
```

**Resposta:** lista de reprodução HLS ou conteúdo do arquivo de segmento

### Interromper fluxo HLS

**Ponto final:** `DELETE /api/cameras/{id}/stream`

Pare todos os streams HLS de uma câmera.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/cameras/front-door/stream"
```

**Resposta:**
```json
{
  "status": "stopped"
}
```

## Transmissão WebRTC

### Criar sessão WebRTC (WHEP)

**Ponto final:** `POST /api/cameras/{id}/stream/webrtc`

Crie uma nova sessão WebRTC WHEP (protocolo de saída WebRTC-HTTP). Aceita uma oferta SDP e retorna uma resposta SDP com uma URL de sessão no cabeçalho Location.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/sdp" \
  -d "$SDP_OFFER" \
  "http://localhost:9090/api/cameras/front-door/stream/webrtc"
```

**Resposta (criada em 201):** Resposta SDP com `Content-Type: application/sdp` e `Location: /api/cameras/{id}/stream/webrtc/{session}`

### Close WebRTC Session

**Ponto final:** `DELETE /api/cameras/{id}/stream/webrtc/{session}`

Desative uma sessão WHEP ativa.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/cameras/front-door/stream/webrtc/session_123"
```

**Resposta:**
```json
{
  "status": "deleted"
}
```

## Transmissão HTTP-FLV

**Ponto final:** `GET /api/cameras/{id}/stream.flv`

HTTP-FLV live stream. Fornece streaming FLV compatível com navegador em HTTP.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/stream.flv"
```

**Resposta:** Fluxo binário FLV com `Content-Type: video/x-flv`

## Transmissão WebSocket

**Ponto final:** `GET /api/cameras/{id}/stream/ws`

WebSocket live stream. Atualizações para uma conexão WebSocket para streaming de quadros binários em tempo real.

**Solicitação:**
```bash
# Use a WebSocket client
wscat -c "ws://localhost:9090/api/cameras/front-door/stream/ws" \
  -H "Authorization: Basic $(echo -n 'username:password' | base64)"
```

**Resposta:** Atualização WebSocket. Quadros binários contendo dados de vídeo.

## Camera Protocols

**Ponto final:** `GET /api/cameras/{id}/protocols`

Obtenha os protocolos de streaming disponíveis para uma câmera específica, com base em sua codificação e nos manipuladores de stream registrados. Retorna protocolos, codificação e o protocolo padrão.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/front-door/protocols"
```

**Resposta:**
```json
{
  "protocols": [
    {
      "protocol": "webrtc",
      "label": "WebRTC (WHEP)",
      "available": true
    },
    {
      "protocol": "flv",
      "label": "HTTP-FLV",
      "available": true
    },
    {
      "protocol": "hls",
      "label": "HLS",
      "available": true
    },
    {
      "protocol": "ws",
      "label": "WebSocket",
      "available": true
    }
  ],
  "encoding": "h264",
  "default": "webrtc"
}
```
