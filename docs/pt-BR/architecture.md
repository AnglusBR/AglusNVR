# Arquitetura: Ingesta Push-In e Relé Push-Out

> Como AglusNVR conecta câmeras entre redes — nativamente em Go, sem FFmpeg.

Este documento aborda dois subsistemas de streaming adicionados na v0.8.0 que permitiram que o NVR operasse através das fronteiras da rede:

1. **Push-In (Ingest)** — uma publicadora remota empurra um stream PARA o NVR (SRT/RTMP). A NVR grava e serve ao vivo como qualquer câmera.
2. **Push-Out (Relé)** — o NVR encaminha a transmissão ao vivo da câmera para destinos remotos (RTMP/RTSP). Pura Go, sem processos externos.

Ambos reutilizam o barramento de quadros `StreamHub` existente para encaixarem no pipeline de gravação + live (HLS/WebRTC/FLV/WS) sem alterações para os consumidores.

---

## 1. Fundação Compartilhada: o StreamHub

Cada câmera possui um `*model.StreamHub` — um ônibus de enquadramento espalhado. Os produtores `hub.Broadcast(pts, au, isIDR)`; Consumidores ligam para `hub.Subscribe(id, callback)`. O hub executa o callback de cada consumidor em uma goroutine dedicada (não bloqueadora; queda no buffer completo).

```
                     ┌─────────────────────────────────────────┐
                     │              StreamHub                   │
   RTSP recorder ──▶ │  Broadcast(pts, au, isIDR)              │ ──▶ HLS muxer
   ONVIF recorder ──▶ │                                         │ ──▶ WebRTC
   IngestRecorder ──▶ │  Subscribe("hls", cb)                   │ ──▶ FLV
                     │  Subscribe("webrtc-<id>", cb)            │ ──▶ WebSocket
                     │  Subscribe("relay-rtmp-<id>", cb)  ◀── NEW (push-out)
                     └─────────────────────────────────────────┘
```

O **registro central do hub** (`CameraManager.hubRegistry`, `GetHub(id)` / `GetOrCreateHub(id)`) é a única fonte de verdade: gravadores de pull, servidores de ingesta e alvos de retransmissão referenciam o MESMO objeto hub para uma determinada câmera.

---

## 2. Ingestimento por Empurrar — `internal/recorder/ingest.go`

Um publisher remoto (ffmpeg, OBS, um telefone, outro NVR) envia um stream para o ouvinte SRT do NVR ou para o servidor RTMP. A transmissão vira uma câmera completa.

### Componentes

| Componente | Arquivo | Função |
|-----------|------|------|
| SRT Ouvinte | `internal/srt/listener.go` | Aceita SRT insiste; mapas `streamid` → ID da câmera |
| RTMP Server | `internal/rtmp/server.go` | Aceita RTMP pressiona; chave de fluxo de mapas → ID da câmera |
| IngestRecorder | `internal/recorder/ingest.go` | O gravador para câmeras push: grava MP4 rodando + alimenta o hub |

### Fluxo de dados (exemplo RTMP)

```
Publisher ──RTMP──▶ RTMP Server (handlePublisher)
                       │  OnDataH264(au, pts)
                       ├─▶ NALUProvider ──▶ IngestRecorder.WriteNALU(au, pts, isIDR)
                       │                       ├─▶ hub.Broadcast (live consumers)
                       │                       ├─▶ SPS/PPS capture + IDR-gated MP4 segment
                       │                       └─▶ SegmentStore → RecordingDB → SegmentCompleted event
                       └─▶ hub.Broadcast (legacy path)
```

### Pontos-chave de projeto

- **IngestRecorder implementa `model.Recorder`** (Start/Stop/Status) + **`HLSProvider`** (CodecParams) para que ele seja encaixado no CameraManager existente e nos handlers HLS/FLV/WS sem nenhuma alteração.
- **Ciclo de vida**: `Idle (awaiting publisher)` → `Recording (publisher connected)` → `Idle (publisher disconnected)`. Modelado como `StatusReconnecting` para Idle para evitar uma nova constante de status.
- **Injeção SPS/PPS**: RTMP transporta SPS/PPS fora de banda (AVCDecoderConfigurationRecord). O servidor os envia para o IngestRecorder antes dos quadros VCL, e o IngestRecorder os antepõe às transmissões IDR para que os muxers a jusante (extrator DTS gohlslib) os vejam em banda — correspondendo ao caminho RTSP.
- **Rolagem de segmento**: espelhos H264Recorder — detecção de mudança SPS, início de segmento com IDR limitado, rolamento baseado em duração, renomeação → temperatura atômica.

### Política de salvamento por empurrar

Por câmera `push_retention_days`: `nil` = seguir global, `0` = apenas ao vivo (sem gravação), `N` = manter N dias.

---

## 3. Push-Out (Revezamento) — `internal/relay/`

O NVR encaminha a transmissão ao vivo da câmera para alvos remotos RTMP/RTSP. **No FFmpeg** — usa as APIs existentes `gortsplib`/`gortmplib` cliente+publish já existentes no go.mod.

### Componentes

| Componente | Arquivo | Função |
|-----------|------|------|
| PushTarget | `internal/relay/engine.go` | Um por destino; assina no hub da câmera, grava quadros para o alvo, reconecta o loop |
| Gerente | `internal/relay/manager.go` | Possui todos os alvos; reconciliação config-diff, agregação de status, ciclo de vida |
| Estado | `internal/relay/status.go` | `RelayStatus` (diferente de `RecorderStatus`) + `TargetStatus` (JSON) |

### Fluxo de dados

```
Camera StreamHub ──▶ Subscribe("relay-rtmp-<id>", cb)
                      │  cb(pts, au)
                      ▼
                   PushTarget.connectRTMP/connectRTSP
                      │
           ┌──────────┴──────────┐
           ▼                     ▼
     gortmplib.Writer       gortsplib.Client
     .WriteH264(track,      .WritePacketRTP(media, pkt)
       pts, dts, au)          (rtpEnc.Encode(au))
           │                     │
           ▼                     ▼
     RTMP target            RTSP target
     (remote NVR /          (remote NVR /
      live platform)         backup)
```

### Principais pontos de design

- **Fonte = cópia zero**: PushTarget assina o hub existente da câmera. Sem re-puxar, sem decodificação. Mesmo barramento de quadro que HLS/WebRTC/gravação — adicionar um alvo de retransmissão adiciona uma goroutine + um soquete de saída, ~5-10MB em RPi 3B.
- **H.264 apenas remux**: sem transcodificação (nenhum codificador Go H.265 puro viável). Os destinos RTMP rejeitam as fontes H.265 (`errPermanent`). Isso ocorre por design - a transcodificação continua sendo a única exceção FFmpeg.
- **Independência por destino**: cada destino é uma goroutine separada + conexão + loop de reconexão (`TieredBackoffWithJitter`). A falha de um alvo nunca afeta outro, gravado ou ao vivo.
- **`RelayStatus` dedicado**: NÃO `RecorderStatus`. "Streaming para um destino" ≠ "gravação em disco" — a IU de integridade da câmera não deve combiná-los.
- **A reconciliação é assíncrona**: `SetCameraTargets` é executado em uma goroutine (não em `cm.mu`) porque chama `GetHub`, que bloqueia novamente o mutex do gerenciador de câmera.
- **SPS/PPS da origem**: `camMgr.GetSPS(cameraID)` retorna o SPS/PPS da origem para inicialização da trilha de destino.

### Why not FFmpeg?

| | FFmpeg | Relé Go nativo |
|---|---|---|
| Binário | Processo externo (~50MB) | Binário estático único e incorporado |
| RPi 3B de RAM | ~30-50MB por processo | ~5-10MB (um goroutine + soquete) |
| Cross-compile | Compilação separada do ARM ffmpeg | `CGO_ENABLED=0`, sem alteração |
| Confiabilidade | Falhas precisam de scripts de reinicialização | NVR reconexão/retirada integrada |
| Transcodificar | ✅ (H.265→H.264) | ❌ (remux only) |

O relé cobre o caso comum (câmeras H.264 em redes) a um custo 10x menor. A transcodificação permanece atrás de seu sinalizador de recurso FFmpeg para o raro caso H.265→RTMP.

---

## 4. Configuração

### Push-in (protocolo de câmera `srt` ou `rtmp`)

```yaml
cameras:
  - id: "remote-shop"
    name: "Remote Shop"
    protocol: "rtmp"
    encoding: "h264"
    stream_key: "remote-shop"       # maps rtmp://NVR:1935/live/remote-shop
    push_retention_days: 7          # nil=global, 0=live-only, N=days
    enabled: true
```

### Push-out (any camera)

```yaml
cameras:
  - id: "front-door"
    protocol: "rtsp"
    url: "rtsp://192.168.1.50/stream"
    push_targets:
      - id: "backup-nvr"
        name: "Backup NVR"
        protocol: "rtmp"
        url: "rtmp://backup.example.com:1935/live/front-door"
        enabled: true
      - id: "live-platform"
        name: "Live Platform"
        protocol: "rtsp"
        url: "rtsp://live.example.com:8554/front-door"
        enabled: false
```

### Habilitando os servidores de ingestão

```yaml
srt:
  enabled: true
  port: 9000
rtmp:
  enabled: true
  port: 1935
```

---

## 5. API

- `POST /api/cameras` / `PUT /api/cameras/{id}` — aceita `push_targets[]` e `push_retention_days`.
- `GET /api/cameras/{id}/push-status` — retorna o status ativo por destino:
  ```json
  {
    "camera_id": "front-door",
    "targets": [{
      "id": "backup-nvr",
      "name": "Backup NVR",
      "protocol": "rtmp",
      "status": "streaming",
      "kbps": 270.8,
      "enabled": true,
      "uptime": "1m16s"
    }]
  }
  ```

---

## 6. Exemplos de topologia de rede

```
A) Push-in: remote camera → NVR
   [Remote Cam/ffmpeg] ──push RTMP/SRT──▶ [NVR (public IP / port-forwarded)]

B) Push-out: NVR → remote destination
   [NVR + camera] ──relay RTMP/RTSP──▶ [Remote NVR ingest / live platform]

C) Chained (NVR-to-NVR, the cross-network scenario):
   [Camera] ──RTSP──▶ [NVR-A] ──push-out relay──▶ [NVR-B (push-in ingest)] ──▶ records + live
```
