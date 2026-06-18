# Guia de Relay — RTMP Transmissão ao vivo em plataformas

> Encaminhe transmissões de câmera para plataformas de streaming ao vivo (Bilibili, YouTube, Douyin, Kuaishou) com otimização automática de codificação. Implementação pura Go, sem FFmpeg para H.264 passthrough.

## Início Rápido

### Configuração em 3 Etapas: Câmera → Bilibili Live

1. **Configure sua câmera em `aglus-nvr.yaml`:**
```yaml
cameras:
  - id: "front-door"
    name: "Front Door Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
```

2. **Adicionar alvo de retransmissão Bilibili:**
```yaml
cameras:
  - id: "front-door"
    name: "Front Door Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    push_targets:
      - id: "bilibili-live"
        name: "Bilibili Live"
        protocol: "rtmp"
        url: "rtmp://live-push.bilivideo.com/live-bvc/?streamkey=YOUR_STREAM_KEY"
        enabled: true
        platform: "bilibili"
        transcode_policy: "auto"
```

3. **Comece e verifique:**
```bash
# Start AglusNVR
./aglus-nvr -config aglus-nvr.yaml

# Check relay status
curl -u admin:PASSWORD http://localhost:9090/api/cameras/front-door/push-status

# Verify Bilibili stream on your Bilibili dashboard
```

## Plataformas Suportadas

| Plataforma | Padrão de URL | Codec de Áudio | Video Codec | Notas |
|----------|-------------|-------------|-------------|-------|
| **Bilibili** | `rtmp://live-push.bilivideo.com/live-bvc/` | AAC exigido | H.264 só | 4000kbps, 1920x1080, perfil principal, 2 quadros B |
| **Douyin** | `rtmp://live-push.douyin.com/` | AAC exigido | H.264 só | 3500kbps, **1080x1920 (vertical)**, perfil principal, 0 B-frames |
| **YouTube** | `rtmp://a.youtube.com/live2/` | AAC exigido | H.264 só | 4500kbps, 1920x1080, perfil alto, 2 quadros B |
| **Kuaishou** | `rtmp://txyun-push.voip.yximgs.com/gifshow/` | AAC exigido | H.264 só | 4000kbps, 1920x1080, perfil principal, 2 quadros B |
| **Genérico** | URL personalizada | AAC ou G.711 | H.264 só | 3000kbps, 1920x1080, perfil principal, 0 B-frames |

> **Importante:** 
> - RTMP alvos exigem H.264 vídeo fonte
> - Áudio: AAC preferencial, G.711 μ-law/a-law aceito como plano B
> - H.265 fontes transcodificam automaticamente para H.264

## Presets de Plataforma

### 5 Presets Embutidos

O sistema inclui 5 presets otimizados para as principais plataformas:

```go
// Bilibili: Balanced quality for live streaming
{
    Name: "bilibili",
    Description: "Bilibili live streaming", 
    URLHint: "rtmp://live-push.bilivideo.com/live-bvc/",
    GopSeconds: 2,
    VideoBitrateKbps: 4000,
    AudioBitrateKbps: 128,
    Resolution: "1920x1080",
    Framerate: 30,
    Profile: "main",
    Bframes: 2,
    AudioCodecRequired: "aac"
}

// Douyin: Vertical video format
{
    Name: "douyin",
    Description: "Douyin/TikTok live",
    URLHint: "rtmp://live-push.douyin.com/", 
    GopSeconds: 2,
    VideoBitrateKbps: 3500,
    AudioBitrateKbps: 128,
    Resolution: "1080x1920", // Vertical format
    Framerate: 30,
    Profile: "main", 
    Bframes: 0, // No B-frames for lowest latency
    AudioCodecRequired: "aac"
}

// YouTube: High quality with high profile
{
    Name: "youtube",
    Description: "YouTube Live",
    URLHint: "rtmp://a.youtube.com/live2/",
    GopSeconds: 2,
    VideoBitrateKbps: 4500,
    AudioBitrateKbps: 128,
    Resolution: "1920x1080",
    Framerate: 30,
    Profile: "high", // YouTube high profile
    Bframes: 2,
    AudioCodecRequired: "aac"
}

// Kuaishou: Standard quality
{
    Name: "kuaishou", 
    Description: "Kuaishou live",
    URLHint: "rtmp://txyun-push.voip.yximgs.com/gifshow/",
    GopSeconds: 2,
    VideoBitrateKbps: 4000,
    AudioBitrateKbps: 128,
    Resolution: "1920x1080",
    Framerate: 30,
    Profile: "main",
    Bframes: 2, 
    AudioCodecRequired: "aac"
}

// Generic: Fallback for unknown platforms
{
    Name: "generic",
    Description: "Generic RTMP target",
    URLHint: "", // Must be provided in config
    GopSeconds: 2,
    VideoBitrateKbps: 3000,
    AudioBitrateKbps: 128,
    Resolution: "1920x1080",
    Framerate: 30,
    Profile: "main",
    Bframes: 0, // Conservative setting
    AudioCodecRequired: "any" // Accepts both AAC and G.711
}
```

### Predefinições personalizadas via `relay-presets.yaml`

Crie `relay-presets.yaml` no seu diretório de deploy para sobrescrever presets embutidos ou adicionar novos:

```yaml
# deploy/relay-presets.yaml
presets:
  custom_platform:
    name: custom_platform
    description: "My custom streaming platform"
    url_hint: "rtmp://live.mycustomplatform.com/"
    gop_seconds: 2
    video_bitrate_kbps: 5000
    audio_bitrate_kbps: 128
    resolution: "1920x1080"
    framerate: 30
    profile: "main"
    bframes: 2
    audio_codec_required: "aac"

  low_latency:
    name: low_latency
    description: "Low latency gaming stream"
    url_hint: "rtmp://gaming-platform.com/live/"
    gop_seconds: 1  # Shorter GOP for lower latency
    video_bitrate_kbps: 3000
    audio_bitrate_kbps: 128
    resolution: "1280x720"
    framerate: 60
    profile: "baseline"  # Baseline for lower latency
    bframes: 0
    audio_codec_required: "aac"
```

> **Carregamento de Configuração:** O sistema carrega presets personalizados a partir de `relay-presets.yaml` se estiverem presentes. Se o arquivo estiver faltando, inválido ou vazio, ele automaticamente volta aos 5 presets embutidos.

## Manuseio de Áudio

### Passagem AAC

- **Melhor Qualidade:** O áudio AAC da sua câmera é transmitido sem alterações
- **Compatibilidade:** Suportado por todas as principais plataformas (Bilibili, YouTube, Douyin, Kuaishou)
- **Configuração:** Automático quando a câmera fornece áudio AAC

### G.711 Passthrough (Suporte Limitado)

- **Mu-law/A-law:** Áudio G.711 de algumas câmeras (principalmente câmeras ONVIF e Xiaomi)
- **Melhor esforço:** Algumas plataformas podem aceitar o G.711, outras podem rejeitá-lo
- **Reserva:** Se rejeitado, a CAA silenciosa é gerada (veja abaixo)

### Alternativa silenciosa do CAA

**Propósito:** Quando as câmeras não têm áudio ou o G.711 é rejeitado pela plataforma

**Como funciona:**
1. **Detecção:** Sistema detecta áudio ausente ou fonte somente G.711
2. **Geração:** Cria quadros AAC-LC silenciosos em 48kHz estéreo
3. **Taxa Adaptativa:** Limites a 5 quadros por segundo (10% da capacidade do buffer de áudio)
4. **Proteção contra Quedas:** Reduz automaticamente a saída caso ocorra congestionamento de rede

**Configuração:** Automático - não é necessário ajuste manual

**Detalhes técnicos:**
- AudioSpecificConfig: AAC-LC estéreo padrão 48kHz
- Tamanho do quadro: 6 bytes por quadro silencioso
- Taxa de amostragem: 48kHz, canais: 2 (estéreo)
- Gerenciamento de buffer: Não bloqueio, evita o excesso de buffer de áudio

## H.265 Transcodificação

### Quando a Transcodificação é Ativada

O sistema transcodifica automaticamente H.265 fontes para H.264 quando:

1. **Câmera Fonte:** Sua câmera fornece H.265 vídeo
2. **Política de Transcodificação:** `transcode_policy: "auto"` ou `"force_sw"`
3. **Registro Disponível:** Presets de plataforma são configurados

```yaml
cameras:
  - id: "h265-camera"
    name: "H.265 Camera"
    protocol: "rtsp" 
    encoding: "h265"  # H.265 source
    url: "rtsp://camera/h265-stream"
    push_targets:
      - id: "youtube-transcode"
        protocol: "rtmp"
        url: "rtmp://a.youtube.com/live2/"
        enabled: true
        platform: "youtube"
        transcode_policy: "auto"  # Will transcode H.265 to H.264
```

### Requisitos de Hardware

**Servidor de Produção Banana Pi M5:**
- **Aceleração por Hardware:** Usa codec v4l2m2m (kernel do fornecedor)
- **Reserva do CPU:** Retorna ao libx264 no kernel principal
- **Desempenho:** Transcodificação de hardware em 1080p@30fps com < 10% de uso da CPU
- **Memória:** ~50MB de RAM de sobrecarga para transcodificação

**Raspberry Pi 3B:**
- **Apenas software:** Usa libx264 (sem aceleração de hardware disponível)
- **Uso da CPU:** ~30-40% da CPU em 1080p@30fps
- **Memória:** ~100MB de overhead de RAM
- **Recomendação:** Use resolução 720p ou inferior para desempenho confiável

### Gestão Térmica

**Proteção Térmica Banana Pi M5:**
- **Limiar de Aceleração:** 85°C → Faz downgrade automaticamente para resolução 480p
- **Limiar de Desligamento:** 95°C → Para a transcodificação, aciona a reconexão
- **Monitoramento:** Estatísticas térmicas em tempo real disponíveis via métricas Prometheus
- **Resfriamento:** Garantir resfriamento adequado para transcodificação sustentada

**Configuração:**
```yaml
# System-wide thermal limit (optional override)
relay:
  thermal_limit: 85  # Celsius throttle threshold (default: 85)
```

### Políticas de Transcodificação

| Política | Descrição | Caso de Uso |
|--------|-------------|----------|
| `"auto"` | Use hardware se disponível, recorrer ao software | Melhor equilíbrio entre desempenho e qualidade |
| `"force_sw"` | Sempre use transcodificação por software | Testando, ou quando o hardware apresenta bugs |
| `"off"` | Rejeitar fontes H.265 com erro permanente | Apenas para fluxos de trabalho exclusivos de H.264 |

## Testes de Plataforma Manual

### Teste Bilibili Passo a Passo

1. **Criar Conta Bilibili Live:**
   - Go para o [Bilibili Live Creator Center](https://link.bilibili.com/p/center/index)
   - Crie uma sala de transmissão ao vivo
   - Copie sua chave de stream (começando com "live-bvc-")

2. **Configurar NVR:**
```yaml
cameras:
  - id: "test-camera"
    name: "Test Camera for Bilibili"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://your-camera-ip:554/stream"
    enabled: true
    push_targets:
      - id: "bilibili-test"
        name: "Bilibili Test Stream"
        protocol: "rtmp"
        url: "rtmp://live-push.bilivideo.com/live-bvc/?streamkey=YOUR_STREAM_KEY"
        enabled: true
        platform: "bilibili"
        transcode_policy: "auto"
```

3. **Iniciar Stream:**
```bash
# Start the NVR
./aglus-nvr -config aglus-nvr.yaml

# Wait 30 seconds for camera connection
```

4. **Verificar Stream:**
   - Confira o painel do Bilibili para prévia ao vivo
   - Verifique a transmissão que aparece na sua sala ao vivo
   - Verifique se tanto o vídeo quanto o áudio estão funcionando

5. **Verifique as Análises:**
   - Monitore a contagem de visualizações e o engajamento
   - Verifique as métricas de qualidade dos fluxos no Bilibili
   - Monitore NVR logs para o status do relé

6. **Parar o Teste:**
```bash
# Disable target to stop streaming
# Edit aglus-nvr.yaml to set enabled: false for bilibili-test
# Restart NVR or reload config
```

### Comandos de Verificação

```bash
# Check camera status
curl -s http://localhost:9090/api/cameras/test-camera | jq '.status.recording_status'

# Check relay status  
curl -s http://localhost:9090/api/cameras/test-camera | jq '.push_targets[]'

# View NVR logs
tail -f /var/log/aglus-nvr.log | grep relay

# Check stream key authentication (if applicable)
curl -H "Authorization: Bearer YOUR_KEY" -X GET https://api.bilibili.com/x/web-interface/nav
```

## Solução de problemas

### Erros de "Conexão Recusada"

**Problema:** RTMP/RTSP conexão falha

**Soluções:**
```bash
# 1. Check target URL accessibility
curl -I "rtmp://live-push.bilivideo.com/live-bvc/"

# 2. Verify camera stream locally
ffplay "rtsp://your-camera-ip:554/stream"

# 3. Check NVR logs for connection errors
journalctl -u aglus-nvr -f --since="5 minutes ago"

# 4. Verify network connectivity
ping live-push.bilivideo.com
netstat -tlnp | grep 1935  # RTMP port
```

**Correções de Configuração:**
- Garanta que o esquema de URL esteja correto (`rtmp://` ou `rtsp://`)
- Verifique os números das portas e o formato da chave de fluxo
- Verifique se o nome do pré-definido da plataforma corresponde exatamente

### Erros "Codec Rejeitado"

**Problema:** Codec de áudio/vídeo não suportado pela Target

**Soluções:**
```bash
# Check codec information from camera
curl -s http://localhost:9090/api/cameras/test-camera | jq '.recording_codec_info'

# If H.265 source and transcode not enabled:
# Add transcode_policy: "auto" to your target config
```

**Problemas comuns:**
- **H.265 fonte sem transcodificação:** Adicionar `transcode_policy: "auto"`
- **Áudio G.711 rejeitado:** O sistema voltará para o AAC silencioso
- **Formato de áudio errado:** Certifique-se de que a câmera forneça áudio AAC

### Erros de "Desligamento Térmico"

**Problema:** Transcodificação superaquece no Banana Pi M5

**Soluções:**
```bash
# Check current temperature
curl -u admin:PASSWORD -s http://localhost:9090/api/cameras/front-door/push-status | jq '.targets[0].temperature_c'

# Monitor thermal metrics
curl -s http://localhost:9090/api/metrics | grep 'nvr_relay_transcoder_temperature_c'

# Reduce transcode resolution or bitrate
# Or add cooling to the system
```

**Prevenção:**
- Garanta ventilação adequada
- Monitorar a temperatura ambiente
- Use `transcode_policy: "force_sw"` para reduzir a carga da GPU

### Problemas de "A/V Drift"

**Problema:** Áudio e vídeo ficam fora de sincronia

**Sintomas:**
- Áudio atrasa/retarda o vídeo em vários segundos
- Deriva contínua que piora com o tempo

**Soluções:**
```bash
# Check drift monitoring logs
tail -f /var/log/aglus-nvr.log | grep 'AV drift'

# System will automatically reconnect if drift exceeds 1 second sustained
# No manual intervention usually required
```

**Comportamento do Sistema:**
- Monitora a sincronização A/V em tempo real
- Reconecta automaticamente se o desvio > 1 segundo por > 5 segundos
- Não é necessária configuração do usuário

### Mensagens de erro comuns

| Mensagem de erro | Solução |
|---------------|----------|
| `"source stream not ready"` | Câmera desconectada ou ainda não transmite |
| `"H.265 source with transcode_policy=off"` | Adicionar `transcode_policy: "auto"` ou mudar para H.264 câmera |
| `"preset registry not configured"` | Garanta que o PresetRegistry esteja conectado ao gerenciador de relés em main.go |
| `"failed to parse AudioSpecificConfig"` | A câmera fornece áudio AAC inválido, o sistema voltará para o AAC silencioso |
| `"thermal limit exceeded"` | Reduzir resolução/bitrate ou melhorar o resfriamento |

### "expirado após 15s esperando pelo transcodificador SPS/PPS"

**Causa:** O transcodificador (FFmpeg) inicia, mas não recebe nenhum quadro de entrada H.265 antes do tempo de espera SPS/PPS de 15 segundos. Esse foi um bug em que a assinatura do hub de câmeras foi configurada depois do parâmetro espera, em vez de antes.

**Corrigido em:** Versão atual. A assinatura do hub agora começa a alimentar H.265 quadros para FFmpeg imediatamente após o transcodificador começar, antes de esperar pelos parâmetros de saída.

**Se ainda perceber isso:** Verifique se a câmera está transmitindo ativamente (verifique `GET /api/cameras/{id}` → `status` deve ser `"recording"`). O transcodificador só pode produzir saída se receber quadros de entrada.

### `temperature_c` sempre mostra 0

**Causa:** O monitor térmico não estava conectado ao motor do relé. O campo `latestTemperatureC` foi declarado, mas nunca atualizado.

**Corrigido em:** Versão atual. Um `ThermalMonitor` agora é iniciado junto com cada instância do transcodificador, lendo `/sys/class/thermal/thermal_zone*/temp` a cada 30 segundos.

**Nota:** Quando o alvo RTMP está inalcançável, o transcodificador reinicia a cada ~5-10 segundos (ciclo de retentativa de conexão). Como o intervalo de verificação térmica é de 30 segundos, a temperatura pode não ser atualizada durante ciclos rápidos de reconexão. Quando a conexão RTMP está estável, o relatório de temperatura funciona normalmente.
## Referência de Configuração

### Campos PushTargetConfig

```go
type PushTargetConfig struct {
    ID                  string                `yaml:"id" json:"id"`                             // Unique target ID within camera
    Name                string                `yaml:"name,omitempty" json:"name,omitempty"`    // Display name
    Protocol            string                `yaml:"protocol" json:"protocol"`                 // "rtmp" or "rtsp"
    URL                 string                `yaml:"url" json:"url"`                           // Target URL
    Enabled             bool                  `yaml:"enabled" json:"enabled"`                   // Whether target is active
    Platform            string                `yaml:"platform,omitempty" json:"platform,omitempty"`                         // Preset name (bilibili/dougin/youtube/kuaishou/generic)
    TranscodePolicy     string                `yaml:"transcode_policy,omitempty" json:"transcode_policy,omitempty"`         // "auto", "force_sw", "off"
    VideoPresetOverride *VideoPresetOverrides `yaml:"video_preset_override,omitempty" json:"video_preset_override,omitempty"`
}
```

### VideoPresetOverrides Fields

```go
type VideoPresetOverrides struct {
    Resolution       string `yaml:"resolution,omitempty" json:"resolution,omitempty"`       // "1920x1080", "1280x720", etc.
    Framerate        int    `yaml:"framerate,omitempty" json:"framerate,omitempty"`        // 1-120 FPS
    VideoBitrateKbps int    `yaml:"video_bitrate_kbps,omitempty" json:"video_bitrate_kbps,omitempty"` // 100-50000 kbps
    GopSeconds       int    `yaml:"gop_seconds,omitempty" json:"gop_seconds,omitempty"`       // 1-10 seconds
    Profile          string `yaml:"profile,omitempty" json:"profile,omitempty"`          // "baseline", "main", "high"
    Bframes          int    `yaml:"bframes,omitempty" json:"bframes,omitempty"`          // 0-2 (0=none, 1=1 B-frame, 2=2 B-frames)
}
```

### Configuração Global

```yaml
# aglus-nvr.yaml

relay:
  # Path to custom presets file (optional)
  presets_path: "/etc/aglus-nvr/relay-presets.yaml"
  
  # Thermal throttle threshold in Celsius (optional)
  thermal_limit: 85
```

### Regras de validação

- **Plataforma:** Deve corresponder `^[a-zA-Z0-9_]+$` (alfanumérico + sublinhado) ou estar vazia
- **TranscodePolicy:** Deve ser "auto", "force_sw", "desligado" ou vazio
- **Resolução:** Deve estar no formato WxH (ex., "1920x1080")
- **Taxa de quadros:** Se especificado, deve ser de 1 a 120
- **VideoBitrateKbps:** Se especificado, deve ser 100-50000
- **GopSeconds:** Se especificado, deve ser de 1 a 10
- **Perfil:** Se especificado, deve ser "baseline", "main" ou "high"
- **Bframes:** Devem estar 0-2

### Exemplo completo de configuração

```yaml
# aglus-nvr.yaml - Full Relay Configuration

cameras:
  - id: "front-door"
    name: "Front Door Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    push_targets:
      # Bilibili Live Stream
      - id: "bilibili-stream"
        name: "Bilibili Live"
        protocol: "rtmp"
        url: "rtmp://live-push.bilivideo.com/live-bvc/?streamkey=bvc_live_your_key"
        enabled: true
        platform: "bilibili"
        transcode_policy: "auto"
        video_preset_override:
          resolution: "1920x1080"
          framerate: 30
          video_bitrate_kbps: 4000
          gop_seconds: 2
          profile: "main"
          bframes: 2
      
      # YouTube Backup Stream
      - id: "youtube-backup"
        name: "YouTube Backup"
        protocol: "rtmp"
        url: "rtmp://a.youtube.com/live2/your_youtube_key"
        enabled: false  # Disabled by default
        platform: "youtube"
        transcode_policy: "auto"

  - id: "backyard-camera"
    name: "Backyard Camera"
    protocol: "rtsp"
    encoding: "h265"  # Will be transcoded automatically
    url: "rtsp://192.168.1.101:554/stream"
    enabled: true
    push_targets:
      - id: "douyin-stream"
        name: "Douyin Live"
        protocol: "rtmp"
        url: "rtmp://live-push.douyin.com/stream_key"
        enabled: true
        platform: "douyin"
        transcode_policy: "auto"
        # No override needed - uses douyin preset (1080x1920 vertical)

# Optional global relay configuration
relay:
  presets_path: "/etc/aglus-nvr/relay-presets.yaml"
  thermal_limit: 85
```

### Exemplos de Linha de Comando

```bash
# Check relay status for all cameras
curl http://localhost:9090/api/cameras | jq '.[].push_targets[]'

# Check specific camera relay status
curl http://localhost:9090/api/cameras/front-door | jq '.push_targets[]'

# Monitor relay metrics
curl http://localhost:9090/api/metrics | grep 'nvr_relay_'

# Force restart camera relay (by toggling enabled flag)
# Edit config, set enabled: false → true, reload config

# Test connection to target platform
ffmpeg -re -i test-video.mp4 -c:v copy -c:a aac -f flv "rtmp://live-push.bilivideo.com/live-bvc/?test_key"
```

### Integração de Sistemas

**Prometheus Métricas:**
- `nvr_relay_target_status` - Status de streaming alvo
- `nvr_relay_bitrate_kbps` - Taxa de bits atual
- `nvr_relay_reconnects_total` - Contagem de reconexão
- `nvr_relay_transcoder_temperature_c` - Temperatura do transcodificador (Banana Pi M5)
- `nvr_relay_transcoder_restarts_total` - Transcodificador reinicia
- `nvr_relay_transcoder_thermal_throttles_total` - Eventos de aceleração térmica

**Serviço Systemd:**
- Serviço: `aglus-nvr.service`
- Registros: `journalctl -u aglus-nvr`
- Status: `systemctl status aglus-nvr`

**Exames de Saúde:**
```bash
# Overall system health
curl http://localhost:9090/api/health

# Camera health including relay status
curl http://localhost:9090/api/cameras/front-door/health
```

## Capturas de tela

*Interface de configuração de relé na interface web*
![Configuração do relé](../images/relay-config.png)

*Painel de status do relé em tempo real*
![Status do relé](../images/relay-dashboard.png)

*Gerenciamento de preset de plataforma*
![Gerenciamento de predefinições](../images/relay-presets.png)

---

**Próximos passos:**
- [Referência de configuração](configuration.md) - Guia completo de configuração
- [Referência da API](api/README.md) - Documentação da API REST
- [Solução de problemas](troubleshooting.md) - Questões e soluções comuns
