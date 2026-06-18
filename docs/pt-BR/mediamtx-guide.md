# MediaMTX Guia de Integração

MediaMTX (anteriormente rtsp-simple-server) é um servidor de mídia poderoso que pode servir como um servidor proxy RTSP para AglusNVR. Ele oferece RTSP para WebRTC, HLS e outras capacidades de conversão de protocolos, tornando-se particularmente adequado para integração com AglusNVR.

MediaMTX principais vantagens:
- Suporta múltiplos protocolos de câmera (RTSP, RTMP, HTTP-FLV, WebRTC)
- Fornece conversão de fluxo em tempo real
- Suporta balanceamento de carga e failover
- Fácil de configurar e implantar
- Integração perfeita com AglusNVR

## MediaMTX Visão Geral

### O que é MediaMTX

MediaMTX (anteriormente RTSP-simple-server) é um servidor de mídia de código aberto focado em:
- RTSP/RTMP/WebRTC funcionalidade cliente/servidor
- Processamento de mídia em fluxo em tempo real
- Conversão e encaminhamento de protocolo
- Publicação em mídia e assinatura

### Principais Recursos

- **Suporte ao Protocolo**: RTSP, RTMP, WebRTC, HLS, HTTP-FLV
- **Gerenciamento de Streams**: Gravação, encaminhamento e conversão em tempo real
- **Balanceamento de carga**: Distribuição de fluxos multi-câmera
- **Autenticação**: Autenticação básica, autenticação personalizada
- **Monitoramento**: Estatísticas e registros

## Instalação

### Binário (Recomendado)

```bash
# Download for ARM64
wget https://github.com/bluenviron/mediamtx/releases/download/v1.18.0/mediamtx_v1.18.0_linux_arm64.tar.gz
tar -xzf mediamtx_v1.18.0_linux_arm64.tar.gz

# Install
sudo cp mediamtx /usr/local/bin/
sudo chmod +x /usr/local/bin/mediamtx
sudo mkdir -p /etc/mediamtx
```

### Verificar

```bash
mediamtx --version
```

### Da Fonte

```bash
# Install dependencies
sudo apt-get install -y golang git

# Clone repository
git clone https://github.com/bluenviron/mediamtx.git
cd mediamtx

# Build
go build -mod=readonly -o mediamtx ./cmd/mediamtx
```

### Usando Docker

```bash
# Pull image
docker pull bluenviron/mediamtx:latest

# Run container
docker run -d --name mediamtx \
  -p 8554:8554 -p 8000:8000 -p 1935:1935 \
  -v /path/to/config.yml:/etc/mediamtx.yml \
  bluenviron/mediamtx:latest
```

## Configuração Básica

Crie `/etc/mediamtx/mediamtx.yml`:

```yaml
# MediaMTX Basic Configuration

# RTSP Configuration
paths:
  all:
    # Enable recording (optional)
    record: true
    # Recording path
    recordPath: /path/to/recordings
    # Recording format
    recordFormat: fmp4
    # Max recording duration
    recordMaxDuration: 1h

# Server Configuration
protocols:
  # RTSP Protocol
  - protocol: rtsp
    listen: :8554
    # RTSP-over-TCP
    rtspOverTcp: true
    # Authentication
    authMethod: static
    authUsers:
      user: password

  # RTMP Protocol (optional)
  - protocol: rtmp
    listen: :1935

  # WebRTC Protocol (optional)
  - protocol: webrtc
    listen: :8889
    # WebRTC Server Key
    webrtcServerKey: mediamtx

# Logging Configuration
logging:
  level: info
  format: json
```

Comece:

```bash
mediamtx /etc/mediamtx/mediamtx.yml
```

A transmissão já está disponível no `rtsp://localhost:8554/cam_front`.
```


## Integrating with AglusNVR

Configure AglusNVR to pull from MediaMTX:

```yaml
# aglus-nvr.yaml
Câmeras:
  - ID: "Porta da frente"
    name: "Front Door"
    protocol: "rtsp_h264"
    url: "rtsp://localhost:8554/cam_front"
    enabled: true
```

AglusNVR will connect to MediaMTX's RTSP port and record the stream.

## CSI Camera Pipeline

For devices with a CSI camera (e.g., Raspberry Pi Camera Module), you need a pipeline to convert the raw H.264 output into an RTSP stream via MediaMTX.

### Option 1: UDP Pipeline (rpicam-vid + ffmpeg)

```bash
# Capturar H.264 da câmera CSI → ffmpeg → UDP
rpicam-vid -n ---codec h264 --largura 1280 --altura 720 --taxa de quadros 15 -t 0 -o - \
| ffmpeg -fflags + genpts -i pipe:0 -c:v cópia -f mpegts -flush_packets 0 \
    'udp://127.0.0.1:8555?pkt_size=188'
```

MediaMTX config to receive the UDP stream:

```yaml
Caminhos:
rpi_cam:
    source: udp://127.0.0.1:8555
```

> **Note**: On Debian Bookworm and later, `libcamera-*` commands have been renamed to `rpicam-*`.

### Option 2: Built-in rpiCamera Source (MediaMTX v1.14+)

MediaMTX can directly access the Raspberry Pi camera without ffmpeg:

```yaml
Caminhos:
rpi_cam:
    source: rpiCamera
    rpiCameraCamID: 0
    rpiCameraWidth: 1280
    rpiCameraHeight: 720
    rpiCameraFPS: 15
```

This is simpler but only works on devices with a compatible CSI camera.

### Systemd Service

Create `/etc/systemd/system/rpicam-stream.service`:

```ini
[Unidade]
Descrição=Pipeline de Streaming de Câmeras CSI
Wants=mediamtx.service
After=mediamtx.service

[Serviço]
Tipo=simples
User=nvr
ExecStart=/bin/bash -c 'rpicam-vid -n --codec h264 --largura 1280 --altura 720 --taxa de quadros 15 -t 0 -o - | ffmpeg -fflags +genpts -i pipe:0 -c:v copy -f mpegts -flush_packets 0 "udp://127.0.0.1:8555?pkt_size=188"'
Reiniciar = falhar
RestartSec=5

[Instalar]
WantedBy=multi-usuário.target
```

## Multi-Camera Configuration

```yaml
Caminhos:
front_door:
    source: rtsp://admin:pass@192.168.1.10:554/stream1
    rtspTransport: tcp
    sourceOnDemand: yes

Quintal:
    source: rtsp://admin:pass@192.168.1.11:554/stream1
    rtspTransport: tcp
    sourceOnDemand: yes

Garagem:
    source: rtsp://admin:pass@192.168.1.12:554/stream1
    rtspTransport: tcp
    sourceOnDemand: yes

rpi_csi:
    source: udp://127.0.0.1:8555
```

Then in AglusNVR config:

```yaml
Câmeras:
  - ID: "Frente"
    name: "Front Door"
    protocol: "rtsp_h264"
    url: "rtsp://localhost:8554/front_door"
    enabled: true
  - ID: "Quintal"
    name: "Backyard"
    protocol: "rtsp_h264"
    url: "rtsp://localhost:8554/backyard"
    enabled: true
  - ID: "garagem"
    name: "Garage"
    protocol: "rtsp_h264"
    url: "rtsp://localhost:8554/garage"
    enabled: true
  - ID: "CSI-Cam"
    name: "CSI Camera"
    protocol: "rtsp_h264"
    url: "rtsp://localhost:8554/rpi_csi"
    enabled: true
```

## Authentication

### Internal Users

```yaml
authMethod: internal
authInternalUsers:
  # Administrador (acesso total)
  - usuário: admin
    pass: secret123
    permissions:
      - action: publish
      - action: read
      - action: api

  # Somente leitura (para NVR)
  - Usuário: NVR
    pass: nvrcode
    ips: ["127.0.0.1"]  # Restrict to localhost
    permissions:
      - action: read
```

### Hashed Passwords

```bash
# Gerar hash SHA256
echo -n "minhapassword" | openssl dgst -binário -sha256 | OpenSSL base64
```

```yaml
authInternalUsers:
  - Usuário: sha256:<hash_value>
    pass: sha256:<hash_value>
    permissions:
      - action: read
```

## Logging and Debugging

### Log Levels

```yaml
logLevel: info # error, warn, info, debug
```

### Log to File

```yaml
logDestinations: [arquivo]
logFile: /var/log/mediamtx/mediamtx.log
```

### Structured Logging (JSONL)

```yaml
logStructured: true
```

### Debugging Packet Issues

```yaml
logLevel: debug
dumpPackets: true # Despeje pacotes para o disco para análise
```

## Common Issues

### "invalid FU-A packet (non-starting)"

This error appears when using the UDP pipeline (rpicam-vid → ffmpeg → UDP). It is **non-critical** and does not affect recording. You can safely ignore it.

### Stream Not Available

1. Check MediaMTX is running: `systemctl status mediamtx`
2. Check logs: `journalctl -u mediamtx -f`
3. Verify camera is accessible: `ffplay rtsp://camera-ip:554/stream`
4. Test MediaMTX path: `ffplay rtsp://localhost:8554/cam_name`

### High Memory Usage

- Use `sourceOnDemand: yes` to only pull streams when readers connect
- Reduce `writeQueueSize: 256` for memory-constrained devices
- Use TCP transport instead of UDP for reliability

### TCP vs UDP Transport

```yaml
# Mais confiável (funciona via NAT)
rtspTransport: tcp

# Latência menor (padrão)
rtspTransport: udp
```

For home networks, TCP is recommended for reliability.

## Troubleshooting

### Connection Issues

#### Camera Cannot Connect to MediaMTX

```bash
# Conexão RTSP teste
ffmpeg -rtsp_transport tcp -i "rtsp://admin:password123@localhost:8554/cam1" -t 5 -f null -

# Verifique MediaMTX registros
mediamtx --config mediamtx.yml --log-level debug

# Verifique o uso das portas
Netstat -TLNP | grep :8554
```

#### MediaMTX Cannot Connect to Camera

```bash
# Teste de câmera direta
ffmpeg -rtsp_transport tcp -i "rtsp://192.168.1.100:554/stream" -t 5 -f null -

# Verifique a conectividade da rede de câmeras
ping 192.168.1.100
NPMAP -P 554 192.168.1.100
```

### Performance Issues

#### High CPU Usage

```yaml
# Configuração de otimização
Caminhos:
todos:
    videoBitrate: 1000        # Reduce bitrate
    fps: 15                   # Reduce frame rate
    gopSize: 30              # Increase GOP size
```

#### High Memory Usage

```yaml
# Otimização de memória
Caminhos:
todos:
    recordMaxDuration: 10m   # Reduce recording duration
    bufferType: ring         # Use ring buffer
    bufferTimeMs: 1000       # Reduce buffer time
```

### Authentication Issues

#### Authentication Failure

```yaml
# Verifique a configuração da autenticação
Caminhos:
todos:
    authMethod: static
    authUsers:
      admin: password123      # Ensure correct password

# Teste o acesso autenticado
ffmpeg -rtsp_transport tcp -i "rtsp://admin:password123@localhost:8554/cam1" -t 5 -f null -
```

### Recording Issues

#### Recording Failure

```bash
# Verifique permissões de armazenamento
ls -la /mnt/dados/nvr/gravações/
sudo chown -R aglus:aglus /mnt/data/nvr/recordings/

# Verifique o espaço do disco
df -h /mnt/data/nvr

# Verifique MediaMTX registros de gravação
mediamtx --config mediamtx.yml --log-level debug
```

## Monitoring and Logging

### Log Configuration

```yaml
# mediamtx.yml - Configuração do Log

Registro:
nível: info
Formato: JSON
Arquivos:
    - path: /var/log/mediamtx.log
      maxSize: 100MB
      maxBackups: 5
      compress: true
```

### Statistics

```bash
# Confira as estatísticas MediaMTX
curl http://localhost:8889/stats

# Confira as estatísticas AglusNVR
curl http://localhost:9090/api/stats
```

### Prometheus Monitoring

```yaml
# mediamtx.yml - Prometheus Configuração

Métricas:
ativado: true
Endereço: :9998
Caminho: /métricas
```

## Performance Optimization

### Network Optimization

```yaml
# Configuração de otimização de rede
Protocolos:
  - Protocolo: RTSP
    listen: :8554
    rtspOverTcp: true        # Use TCP for stability
    rtspReadTimeout: 10s     # Read timeout
    rtspWriteTimeout: 10s    # Write timeout
```

### Encoding Optimization

```yaml
# Configuração de otimização da codificação
Caminhos:
todos:
    videoCodec: h264         # Use H.264
    videoBitrate: 2000       # 2 Mbps
    audioCodec: aac          # Use AAC
    audioBitrate: 128        # 128 kbps
    fps: 25                  # 25 FPS
    gopSize: 50              # 2 second GOP
```

### Buffer Optimization

```yaml
# Configuração de otimização de buffer
Caminhos:
todos:
    bufferType: ring         # Ring buffer
    bufferTimeMs: 2000       # 2 second buffer
    ringSize: 1000           # Buffer size
```

## Best Practices

### Deployment Architecture

```
→ MediaMTX da câmera (balanceamento de carga) → AglusNVR
         ↓
      monitoring node
         ↓
      storage cluster
```

### Configuration Management

```bash
# Use ferramentas de gerenciamento de configuração
ansible-playbook -i inventário mediamtx.yml
```

### Backup Strategy

```bash
# Backup de configuração regular
*/5 * * * * cp /etc/mediamtx.yml /backup/mediamtx-$(data +\%Y\%m\%d).yml
```

### Update Strategy

```bash
# Script de atualização contínua
gato > update-mediamtx.sh << 'EOF'
#!/lixo/batida
# Serviço de parada
Sudo SystemCTL Stop mediamtx

# Configuração de backup
sudo cp /etc/mediamtx.yml /etc/mediamtx.yml.bak

# Atualização binária
sudo wget -O /usr/local/bin/mediamtx https://github.com/bluenviron/mediamtx/releases/latest/download/mediamtx-linux-amd64
sudo chmod +x /usr/local/bin/mediamtx

# Início do serviço
Sudo SystemCTL Start mediamtx
EOF

chmod +x update-mediamtx.sh
```

## Summary

MediaMTX provides powerful media processing capabilities for AglusNVR, enabling:

- More stable camera connections
- More protocol support
- Better performance
- More flexible deployment options

It's recommended to choose appropriate configuration based on actual needs and regularly monitor system status.
