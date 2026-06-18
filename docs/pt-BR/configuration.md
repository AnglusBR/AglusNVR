# Referência de configuração

AglusNVR usa um arquivo de configuração YAML para controlar todos os aspectos de sua operação. Abaixo está uma referência abrangente de todas as opções disponíveis, seus padrões e exemplos de uso.

## Estrutura do arquivo de configuração

```yaml
server:
  listen: ":9090"
storage:
  root_dir: "/var/lib/aglus-nvr"
  segment_duration: "30s"
auth:
  username: "admin"
  password_hash: ""
  password: ""
cameras:
  - id: "cam1"
    name: "Camera Name"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://..."
    enabled: true
    audio_enabled: false
    onvif_endpoint: ""           # ONVIF specific
    profile_token: ""            # ONVIF specific  
    stream_encoding: ""          # ONVIF auto-detect (H264/H265)
    sub_stream_url: "rtsp://..."  # Sub-stream for live preview
    snapshot_url: "http://..."    # JPEG snapshot for thumbnails
    sample_interval: 1            # MJPEG frame sampling
    hls_max_fps: 0               # HLS frame rate limit
    vendor: ""                   # Xiaomi transport vendor
    did: ""                      # Xiaomi device ID
    frame_watchdog_timeout: "30s" # Per-camera frame watchdog
    merge:                       # Per-camera merge overrides
      enabled: false
      check_interval: "1h"
      window_size: "1h"
      batch_limit: 150
      min_segment_age: "5m"
      min_segments_to_merge: 2
    transcoding:                 # Per-camera transcoding overrides
      enabled: false
      target_codec: "h264"
      preset: "ultrafast"
      bitrate: "2M"
    timelapse:                   # Per-camera timelapse recording
      enabled: false
      interval: "30s"
      delete_original: false
    health_overrides:            # Per-camera health threshold overrides
      min_fps: 10
      offline_threshold: "15s"
cleanup:
  retention_days: 30
  check_interval: "1h"
  disk_threshold_percent: 95
merge:
  enabled: false
  check_interval: "1h"
  window_size: "1h"
  batch_limit: 200
  min_segment_age: "10m"
  min_segments_to_merge: 3
ftp:
  enabled: true
  port: 2121
  passive_port_range: "2122-2140"
mqtt:
  enabled: false
  broker: "tcp://localhost:1883"
  topic: "aglusnvr/trigger"
  client_id: "aglus-nvr"
  username: ""
  password: ""
webdav:
  enabled: true
  path_prefix: "/dav"
  read_write: false
hls:
  write_buffer_size: 100         # Async frame buffer per stream
  segment_max_size_mb: 10        # HLS segment max size in MB
  segment_count: 7               # Segments per stream (range: 3-10)
  max_streams: 4                 # Max concurrent streams (range: 1-20, RPi constraint: 4)
  low_latency: false             # Enable Low-Latency HLS
  part_min_duration: "200ms"     # LL-HLS partial segment duration
xiaomi:
  user_id: ""                    # Xiaomi account user ID (from auth response)
  token: ""                      # Xiaomi passToken for API access
  region: "cn"                   # Region code: cn, sg, de, etc.
observability:
  log_level: "info"              # Log level: debug, info, warn, error
  log_format: "text"             # Log format: json or text
  enable_pprof: false            # Enable pprof debug endpoints
streaming:
  default_protocol: "hls"        # Default live view protocol (hls/ll-hls/webrtc/flv)
  webrtc:
    enabled: true
    max_viewers: 2               # Range: 1-10
    idle_timeout: "60s"
  flv:
    enabled: true
    max_viewers: 10              # Range: 1-50
    idle_timeout: "60s"
    gop_cache_size: 1
websocket:
  max_viewers: 10
  write_buf_size: 100
  idle_timeout: 60s
health:
  enabled: false
  events_retention: "720h"       # 30 days
  alerts:
    cooldown: "5m"
    mqtt: false
  layer1:
    offline_threshold: "30s"
  layer2:
    bitrate_change_threshold: 0.5
    min_fps: 5
    max_idr_interval: "60s"
  layer2_5:
    freeze_timeout: "10s"
  auto_remediation:
    enabled: false
    max_restarts_per_hour: 3
    cooldown_minutes: 5
    blacklist_hours: 1
    global_max_per_min: 10
remote_log:
  enabled: false
  endpoint: ""                   # VictoriaLogs URL when enabled
  format: "jsonline"             # jsonline or loki
transcoding:
  enabled: false
  max_workers: 1                 # Range: 1-4
  job_timeout: "30m"
  history_retention: "168h"      # 7 days
ai:
  inference_timeout_ms: 0
  frame_skip_rate: 0
  confidence_threshold: 0.0
  model_path: ""
rtmp:
  enabled: false
  port: 1935
  # stream_keys:                  # Map camera_id to stream key
  #   cam1: "my-stream-key"
srt:
  enabled: false
  port: 9000
  # streams:                      # SRT stream mappings
  #   - camera_id: "cam1"
  #     mode: "listener"
metrics_auth:
  username: ""
  password: ""
version: "1.0"
```

## Configuração do servidor

### `server.listen`
- **Tipo**: string
- **Padrão**: `":9090"`
- **Descrição**: O endereço e a porta para o servidor web escutar
- **Exemplo**: `":8080"` ou `"192.168.1.100:9090"`

## Configuração de armazenamento

### `storage.root_dir`
- **Tipo**: string
- **Padrão**: `/var/lib/aglus-nvr` (binário) ou `/data` (Docker)
- **Descrição**: Diretório raiz para armazenamento de gravações, banco de dados e arquivos temporários. Todas as gravações da câmera são armazenadas em `{root_dir}/{camera_id}/`.
- **Docker**: Ao executar em Docker, isso é definido por meio da variável de ambiente `NVR_DATA_DIR`. A montagem do volume e `NVR_DATA_DIR` devem corresponder.
- **Binário**: pode ser definido por meio do sinalizador `--data-dir` com `aglus-nvr init` ou diretamente na configuração YAML.
- **Exemplo**: `/var/lib/aglus-nvr`, `/mnt/external/nvr`, `/data`

### `storage.segment_duration`
- **Tipo**: string
- **Padrão**: `"30s"`
- **Descrição**: Duração dos segmentos de vídeo (uso intenso de memória)
- **Importante**: cada segmento mantém todos os dados de vídeo na RAM até a conclusão
- **Uso de memória**:
  - Segmentos dos anos 30: aproximadamente 15-20 MB por segmento
  - Segmentos dos anos 60: ~30-40MB por segmento
  - Segmentos dos anos 120: ~60-80MB por segmento
- **Restrição RPi**: máximo de 30 segundos em Raspberry Pi 3B
- **Exemplo**: `"30s"`, `"1m"`, `"5m"`

## Configuração de autenticação

### `auth.username`
- **Tipo**: string
- **Obrigatório**: Sim (para interface web e FTP)
- **Descrição**: Nome de usuário para autenticação
- **Exemplo**: `"admin"`

### `auth.password_hash`
- **Tipo**: string
- **Obrigatório**: Sim (para interface web e FTP)
- **Descrição**: senha com hash bcrypt. Use `aglus-nvr hash-password <password>` para gerar.
- **Prioridade**: `password_hash` terá precedência se `password` e `password_hash` estiverem definidos
- **Observação**: Se apenas `auth.password` (texto simples) for fornecido, o servidor gera automaticamente o hash na inicialização e o persiste de volta ao arquivo de configuração
- **Exemplo**: `$2a$10$N9qo8uLOickgx2ZMRZoMy...`

### `auth.password`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Senha em texto simples para configuração inicial conveniente. Na primeira execução, o servidor faz hash automático desse valor e grava-o em `password_hash` e, em seguida, limpa o campo `password`.
- **Prioridade**: Usado somente quando `password_hash` está vazio
- **Exemplo**: `"admin123"`

## Configuração da câmera

### Estrutura da câmera
Cada configuração de câmera requer estes campos básicos:

```yaml
cameras:
  - id: "cam1"
    name: "Camera Name"
    protocol: "rtsp"
    encoding: "h264"
    url: "camera_url"
    enabled: true
```

### `cameras[].id`
- **Tipo**: string
- **Obrigatório**: Sim
- **Descrição**: identificador exclusivo da câmera (gerado automaticamente se não for fornecido)
- **Formato**: Alfanumérico, caixa de kebab recomendada (por exemplo, "porta da frente")
- **Exemplo**: `"front-door"`, `"cam-01"`

### `cameras[].name`
- **Tipo**: string
- **Obrigatório**: Sim
- **Descrição**: Nome da câmera legível por humanos
- **Exemplo**: `"Front Door Camera"`, `"Back Yard"`

### `cameras[].protocol`
- **Tipo**: string
- **Obrigatório**: Sim
- **Descrição**: Protocolo de transporte de câmeras
- **Opções**: `"rtsp"`, `"http"`, `"onvif"`, `"xiaomi"`, `"timelapse"`, `"srt"`, `"rtmp"`
- **Protocolos push**: `"srt"` e `"rtmp"` são protocolos push/ingest — um publisher remoto empurra um fluxo PARA o NVR. O campo `url` não é utilizado; Em vez disso, configure `stream_key` (RTMP) ou `srt_stream_id` / `srt_passphrase` (SRT). Veja [Push Cameras](./camera-guide.md#push-cameras-srt--rtmp--cross-network-ingest).
- **Formato Legado**: Também suporta `"rtsp_h264"`, `"rtsp_h265"`, `"rtsp_mjpeg"` `"http_jpeg"` (automaticamente analisado para um novo formato)
- **Nota**: O formato legado é automaticamente analisado para o novo protocolo + codificação para compatibilidade retroativa
- **Compatibilidade**: Ambos os formatos são suportados

### `cameras[].encoding`
- **Tipo**: string
- **Opcional**: Sim (detectado automaticamente pelo protocolo legado ou padrões baseados no protocolo)
- **Descrição**: Formato de codificação de vídeo
- **Opções**: `"h264"`, `"h265"`, `"mjpeg"`, `"jpeg"`
- **Combinações válidas**:
  - `protocol: "rtsp"` → `encoding: "h264"`, `"h265"` ou `"mjpeg"`
  - `protocol: "http"` → `encoding: "jpeg"`
  - `protocol: "onvif"` → `encoding: "h264"` ou `"h265"` (detectar automaticamente se não especificado)
  - `protocol: "xiaomi"` → `encoding: "h264"` ou `"h265"` (auto-detectação)
  - `protocol: "srt"` → `encoding: "h264"` ou `"h265"` (H.264 apenas no SRT atual demux)
  - `protocol: "rtmp"` → `encoding: "h264"` (RTMP só carrega H.264)

### `cameras[].url`
- **Tipo**: string
- **Obrigatório**: Sim (exceto para câmeras ONVIF e Xiaomi)
- **Descrição**: URL da câmera ou ponto final do stream
- **Exemplos**:
  - RTSP: `"rtsp://192.168.1.100:554/stream"`
  - HTTP: `"http://192.168.1.101/capture"`
  - ONVIF: `"http://192.168.1.102:80/onvif/device_service"` (ou use `onvif_endpoint`)
- **Validação**: Deve ter um esquema válido (http/rtsp) e host

### `cameras[].username`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Nome de usuário para autenticação de câmera
- **Exemplo**: `"admin"`

### `cameras[].password`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Senha para autenticação da câmera
- **Exemplo**: `"camera-password"`

### `cameras[].enabled`
- **Tipo**: booleano
- **Padrão**: `true`
- **Descrição**: Se a gravação da câmera está ativada
- **Exemplo**: `true` ou `false`

### `cameras[].onvif_endpoint`
- **Tipo**: string
- **Opcional**: Sim (obrigatório para câmeras ONVIF se não for fornecido URL)
- **Descrição**: URL do endpoint do serviço de ONVIF dispositivo
- **Exemplo**: `"http://192.168.1.100:80/onvif/device_service"`
- **Nota**: Se a URL for definida para ONVIF câmera, ela é automaticamente copiada para onvif_endpoint

### `cameras[].profile_token`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: ONVIF token de perfil de mídia para seleção específica de stream
- **Exemplo**: `"profile_1"`
- **Nota**: Opcional, usa o perfil padrão se não especificado

### `cameras[].stream_encoding`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Codificação de fluxo para câmeras ONVIF (H264 ou H265)
- **Opções**: `"H264"`, `"H265"`
- **Nota**: Vazio = auto-detectar a partir das capacidades do dispositivo ONVIF

### `cameras[].sub_stream_url`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: RTSP URL de uma sub-transmissão de resolução mais baixa para prévia ao vivo HLS. Quando configurado, o Dashboard usa esse fluxo em vez do fluxo principal, reduzindo o uso de largura de banda.
- **Nota**: O sub-stream deve usar o mesmo codec (H.264/H.265) do principal stream
- **Exemplo**: `"rtsp://192.168.1.100:554/stream2"`

### `cameras[].snapshot_url`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: URL HTTP retornando uma imagem JPEG snapshot. Quando configurado, o Dashboard exibe miniaturas de snapshot em vez de streams ao vivo HLS, reduzindo significativamente a largura de banda.
- **Comportamento**: Snapshots são armazenados em cache por 10 segundos; cache obsoleto é servido quando a câmera está temporariamente inacessível
- **Exemplo**: `"http://192.168.1.100/snapshot"`, `"http://192.168.1.100/cgi-bin/snapshot.cgi"`

### `cameras[].sample_interval`
- **Tipo**: inteiro
- **Opcional**: Sim
- **Padrão**: 1 (apenas para câmeras MJPEG)
- **Descrição**: Intervalo para amostragem MJPEG quadros (segundos). Valores mais altos reduzem o uso da CPU, mas diminuem a taxa de quadros.
- **Exemplo**: `1`, `2`, `5`

### `cameras[].hls_max_fps`
- **Tipo**: inteiro
- **Opcional**: Sim
- **Padrão**: 0 (sem limite)
- **Descrição**: Taxa máxima de quadros para HLS streaming. 0 = sem limite.
- **Exemplo**: `30`, `15`, `25`

### `cameras[].vendor`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Fornecedor de transporte para câmeras Xiaomi
- **Opções**: `"cs2"` (padrão)
- **Exemplo**: `"cs2"`

### `cameras[].audio_enabled`

- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilitar a gravação de áudio desta câmera. Quando ativado, o gravador captura o áudio do fluxo RTSP/ONVIF/Xiaomi e o insere na gravação MP4.
- **Formatos suportados**: AAC (câmeras RTSP), G.711 μ-law/A-law (câmeras ONVIF/Xiaomi)
- **Nota**: Não suportado para câmeras MJPEG ou HTTP-JPEG
- **Exemplo**: `true`, `false`


### `cameras[].did`
- **Tipo**: string
- **Opcional**: Sim (obrigatório para Xiaomi câmeras)
- **Descrição**: ID de Xiaomi do dispositivo do serviço em nuvem
- **Exemplo**: `"camera_did_123"`

### `cameras[].merge`
- **Tipo**: objeto
- **Opcional**: Sim
- **Descrição**: Substituições de configuração de fusão por câmera
- **Nota**: Apenas campos diferentes de zero sobrescrevem a configuração global de merge
- **Exemplo**: Veja [Configuração de Munção](#merge-configuration)

### `cameras[].transcoding`
- **Tipo**: objeto
- **Opcional**: Sim
- **Descrição**: Overries de configuração de transcodificação por câmera. Veja [Transcoding Configuration](#transcoding-configuration) para detalhes do campo.
- **Exemplo**:
  ```yaml
  cameras:
    - id: "cam1"
      transcoding:
        enabled: true
        target_codec: "h264"
        preset: "ultrafast"
        bitrate: "2M"
  ```

### `cameras[].timelapse`
- **Tipo**: objeto
- **Opcional**: Sim
- **Descrição**: Configuração de gravação timelapse por câmera
- **Campos**:
  - **`enabled`** (booleano, padrão: `false`) — Habilita gravação de lapso de tempo
  - **`interval`** (string, padrão: `"30s"`, min: 1s) — Intervalo de captura de instantâneo
  - **`output_fps`** (inteiro, padrão: 30, intervalo: 1-60) — Taxa de quadros de saída
  - **`video_codec`** (string, padrão: `"h264"`, opções: h264/h265) — Codec de vídeo (obsoleto)
  - **`delete_original`** (booleano, padrão: `false`) — Remover segmentos originais após lapso de tempo
  - **`merge_enabled`** (booleano, padrão: detecção automática) — Habilita mesclagem automática
  - **`merge_mode`** (string, padrão: `"auto"`, opções: auto/mp4/jpeg) — Mesclar formato de saída
  - **`daily_merge`** (booleano, padrão: `true`) — Mesclar segmentos em arquivos diários
  - **`merge_output_fps`** (inteiro, padrão: 30, intervalo: 1-60) — Mesclar taxa de quadros de saída
- **Exemplo**:
  ```yaml
  cameras:
    - id: "cam1"
      timelapse:
        enabled: true
        interval: "60s"
        delete_original: true
  ```

### `cameras[].health_overrides`
- **Tipo**: objeto
- **Opcional**: Sim
- **Descrição**: substituições do limite de monitoramento de integridade por câmera. Valores diferentes de zero têm precedência sobre a [Configuração de Funcionamento](#health-configuration) global.
- **Campos**:
  - **`max_idr_interval`** (string) — Substituição máxima do intervalo IDR (por exemplo, `"30s"`)
  - **`bitrate_change_threshold`** (flutuante, intervalo: 0-1) — Substituição do limite de alteração da taxa de bits
  - **`min_fps`** (inteiro) — Substituição mínima de FPS
  - **`offline_threshold`** (string) — Substituição do limite de detecção offline (por exemplo, `"15s"`)
  - **`freeze_timeout`** (string) — Substituição do tempo limite de detecção de congelamento (por exemplo, `"5s"`)
- **Exemplo**:
  ```yaml
  cameras:
    - id: "cam1"
      health_overrides:
        min_fps: 10
        offline_threshold: "15s"
  ```

### `cameras[].frame_watchdog_timeout`
- **Tipo**: string
- **Opcional**: Sim
- **Padrão**: `"30s"`
- **Descrição**: Tempo limite antes de declarar uma câmera não íntegra quando nenhum quadro é recebido. Substituição por câmera do watchdog de quadro.
- **Exemplo**: `"30s"`, `"60s"`, `"120s"`

### `cameras[].stream_key`
- **Tipo**: string
- **Opcional**: Sim (somente push-in)
- **Descrição**: chave de transmissão RTMP para câmeras push-in (`protocol: "rtmp"`). Mapeia o `rtmp://host:1935/live/{key}` de entrada para esta câmera. O editor envia PARA este endereço.

### `cameras[].srt_passphrase`
- **Tipo**: string
- **Opcional**: Sim (somente push-in)
- **Descrição**: senha AES para câmeras push-in criptografadas SRT (`protocol: "srt"`).

### `cameras[].srt_stream_id`
- **Tipo**: string
- **Opcional**: Sim (somente push-in)
- **Descrição**: ID de fluxo SRT para câmeras push-in (`protocol: "srt"`). Mapeia o SRT `streamid` de entrada para esta câmera.

### `cameras[].push_retention_days`
- **Tipo**: inteiro (anulável)
- **Opcional**: Sim (somente push-in: `protocol: "srt"` ou `"rtmp"`)
- **Padrão**: `null` (seguir retenção de limpeza global)
- **Descrição**: Substituição de retenção de gravação para câmeras push-in. `null` = seguir `cleanup.retention_days` global, `0` = somente ao vivo (sem gravação), `N` = manter N dias.

### `cameras[].push_targets`
- **Tipo**: array de objetos
- **Opcional**: Sim (qualquer protocolo de câmera)
- **Descrição**: Alvos de retransmissão push-out — encaminha a transmissão ao vivo desta câmera para destinos remotos (outra ingestão de NVR, uma plataforma ao vivo, um backup). Go puro, sem FFmpeg. Cada destino é uma conexão independente. Consulte [Relé de Push-Out](./camera-guide.md#push-out-relay--forward-a-camera-to-remote-destinations).
- **Campos por destino**:
  - `id` (string, obrigatório) — identificador estável dentro da câmera
  - `name` (string, opcional) — nome de exibição
  - `protocol` (string, obrigatório) — `"rtmp"` ou `"rtsp"`
  - `url` (string, obrigatório) — URL de destino (`rtmp://host:1935/app/key` ou `rtsp://host:8554/path`)
  - `enabled` (booleano, obrigatório) — se o destino está ativo
- **Observação**: Fonte H.264 necessária para destinos RTMP (somente remux, sem transcodificação). O relé se inscreve no StreamHub da câmera (cópia zero).

## Configuração de limpeza

### `cleanup.retention_days`
- **Tipo**: inteiro
- **Padrão**: 30
- **Intervalo**: 1-3650
- **Descrição**: Excluir gravações com mais de N dias
- **Exemplo**: `7`, `30`, `90`

### `cleanup.check_interval`
- **Tipo**: string
- **Padrão**: `"1h"`
- **Descrição**: Com que frequência verificar gravações expiradas
- **Exemplo**: `"30m"`, `"1h"`, `"2h"`

### `cleanup.disk_threshold_percent`
- **Tipo**: inteiro
- **Padrão**: 95
- **Intervalo**: 50-99
- **Descrição**: Iniciar a limpeza quando o uso do disco exceder N%
- **Exemplo**: `90`, `95`, `98`

## Mesclar configuração

### `merge.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: ativar a funcionalidade de mesclagem de segmentos

### `merge.check_interval`
- **Tipo**: string
- **Padrão**: `"1h"`
- **Descrição**: com que frequência verificar candidatos à mesclagem
- **Exemplo**: `"30m"`, `"1h"`, `"2h"`

### `merge.window_size`
- **Tipo**: string
- **Padrão**: `"1h"`
- **Descrição**: Janela de tempo para mesclar segmentos (segmentos dentro desta janela podem ser mesclados)
- **Exemplo**: `"30m"`, `"1h"`, `"2h"`

### `merge.batch_limit`
- **Tipo**: inteiro
- **Padrão**: 200
- **Descrição**: Número máximo de segmentos a serem mesclados em um lote
- **Exemplo**: `100`, `200`, `500`

### `merge.min_segment_age`
- **Tipo**: string
- **Padrão**: `"10m"`
- **Descrição**: Idade mínima antes que um segmento possa ser mesclado
- **Exemplo**: `"5m"`, `"10m"`, `"30m"`

### `merge.min_segments_to_merge`
- **Tipo**: inteiro
- **Padrão**: 3
- **Descrição**: número mínimo de segmentos necessários para acionar uma mesclagem
- **Exemplo**: `2`, `3`, `5`

## Configuração FTP

### `ftp.enabled`
- **Tipo**: booleano
- **Padrão**: `true`
- **Descrição**: Habilitar servidor FTP

### `ftp.port`
- **Tipo**: inteiro
- **Padrão**: 2121
- **Intervalo**: 1-65535
- **Descrição**: Porta de controle FTP
- **Exemplo**: `2121`, `990`

### `ftp.passive_port_range`
- **Tipo**: string
- **Padrão**: `"2122-2140"`
- **Descrição**: intervalo de portas do modo passivo (início-fim)
- **Exemplo**: `"2122-2140"`, `"40000-40100"`

## Configuração MQTT

### `mqtt.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilite o cliente MQTT para gravação baseada em gatilho

### `mqtt.broker`
- **Tipo**: string
- **Obrigatório**: Sim (se ativado)
- **Descrição**: URL do corretor MQTT
- **Exemplo**: `"tcp://localhost:1883"`, `"mqtt://192.168.1.100:1883"`

### `mqtt.topic`
- **Tipo**: string
- **Obrigatório**: Sim (se ativado)
- **Descrição**: tópico MQTT para assinatura para acionamentos de gravação
- **Exemplo**: `"aglusnvr/trigger"`, `"cameras/front-door/record"`

### `mqtt.client_id`
- **Tipo**: string
- **Padrão**: `"aglus-nvr"`
- **Descrição**: identificador do cliente MQTT
- **Exemplo**: `"aglus-nvr"`, `"nvr-client-01"`

### `mqtt.username`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: nome de usuário de autenticação do corretor MQTT
- **Exemplo**: `"mqtt-user"`, `"admin"`

### `mqtt.password`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Senha de autenticação do corretor MQTT
- **Exemplo**: `"mqtt-password"`

## Configuração WebDAV

### `webdav.enabled`
- **Tipo**: booleano
- **Padrão**: `true`
- **Descrição**: Habilitar servidor WebDAV

### `webdav.path_prefix`
- **Tipo**: string
- **Padrão**: `"/dav"`
- **Descrição**: prefixo do caminho da URL para acesso WebDAV
- **Exemplo**: `"/dav"`, `"/ recordings"`

### `webdav.read_write`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Permite operações de gravação (PUT, MKCOL, DELETE, etc.)
- **Exemplo**: `true`, `false`

## Configuração HLS

### `hls.write_buffer_size`
- **Tipo**: inteiro
- **Padrão**: 100
- **Descrição**: Tamanho do buffer de quadros assíncronos por stream (unidades de quadros)
- **Exemplo**: `40`, `100`, `200`

### `hls.segment_max_size_mb`
- **Tipo**: inteiro
- **Padrão**: 10
- **Descrição**: tamanho máximo do segmento HLS em megabytes
- **Exemplo**: `5`, `10`, `20`

### `hls.segment_count`
- **Tipo**: inteiro
- **Padrão**: 7
- **Intervalo**: 3-10
- **Descrição**: Número de segmentos HLS por stream
- **Exemplo**: `5`, `7`, `10`

### `hls.max_streams`
- **Tipo**: inteiro
- **Padrão**: 4
- **Intervalo**: 1-20
- **Restrição RPi**: Máximo 4 em Raspberry Pi 3B
- **Descrição**: Número máximo de streams HLS simultâneos
- **Exemplo**: `4`, `8`, `16`

### `hls.low_latency`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilite HLS de baixa latência (LL-HLS) usando segmentos parciais para latência reduzida
- **Observação**: Requer `segment_count` >= 7 quando ativado
- **Exemplo**: `true`, `false`

### `hls.part_min_duration`
- **Tipo**: string
- **Padrão**: `"200ms"`
- **Intervalo**: 100ms-1s
- **Descrição**: Duração mínima para segmentos parciais LL-HLS
- **Exemplo**: `"200ms"`, `"500ms"`, `"1s"`

## Configuração Xiaomi

### `xiaomi.user_id`
- **Tipo**: string
- **Obrigatório**: Sim (se câmeras Xiaomi configuradas)
- **Descrição**: ID de usuário da conta na nuvem Xiaomi (obtido após autenticação)
- **Exemplo**: `"1234567890"`

### `xiaomi.token`
- **Tipo**: string
- **Obrigatório**: Sim (se câmeras Xiaomi configuradas)
- **Descrição**: Xiaomi passToken para acesso à API (obtido via `/api/xiaomi/auth`)
- **Exemplo**: `"xiaomi_token_123"`

### `xiaomi.region`
- **Tipo**: string
- **Padrão**: `"cn"`
- **Descrição**: código de região da nuvem Xiaomi
- **Opções**: `"cn"`, `"sg"`, `"de"`, etc.
- **Exemplo**: `"cn"`, `"sg"`

## Configuração de observabilidade

### `observability.log_level`
- **Tipo**: string
- **Padrão**: `"info"`
- **Opções**: `"debug"`, `"info"`, `"warn"`, `"error"`
- **Descrição**: verbosidade em nível de log
- **Exemplo**: `"debug"`, `"info"`, `"error"`

### `observability.log_format`
- **Tipo**: string
- **Padrão**: `"text"`
- **Opções**: `"json"`, `"text"`
- **Descrição**: Formato de saída do log
- **Exemplo**: `"json"`, `"text"`

### `observability.enable_pprof`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilitar endpoints de depuração pprof para criação de perfil de desempenho
- **Observação**: Use com cuidado na produção

## Configuração de streaming

### `streaming.default_protocol`
- **Tipo**: string
- **Padrão**: `"hls"`
- **Opções**: `"hls"`, `"ll-hls"`, `"webrtc"`, `"flv"`
- **Descrição**: Protocolo de streaming padrão para visualização ao vivo na IU da Web
- **Exemplo**: `"hls"`, `"webrtc"`, `"flv"`

### `streaming.webrtc.enabled`
- **Tipo**: booleano
- **Padrão**: `true`
- **Descrição**: Habilite o streaming WebRTC WHEP para visualização ao vivo de baixa latência
- **Exemplo**: `true`, `false`

### `streaming.webrtc.max_viewers`
- **Tipo**: inteiro
- **Padrão**: 2
- **Intervalo**: 1-10
- **Descrição**: número máximo de visualizadores WebRTC simultâneos por stream
- **Exemplo**: `2`, `5`, `10`

### `streaming.webrtc.idle_timeout`
- **Tipo**: string
- **Padrão**: `"60s"`
- **Descrição**: Tempo limite de inatividade antes de fechar uma conexão WebRTC inativa
- **Exemplo**: `"30s"`, `"60s"`, `"120s"`

### `streaming.flv.enabled`
- **Tipo**: booleano
- **Padrão**: `true`
- **Descrição**: Habilite o streaming HTTP-FLV para visualização ao vivo compatível com navegador
- **Exemplo**: `true`, `false`

### `streaming.flv.max_viewers`
- **Tipo**: inteiro
- **Padrão**: 10
- **Intervalo**: 1-50
- **Descrição**: número máximo de visualizadores de FLV simultâneos por transmissão
- **Exemplo**: `10`, `25`, `50`

### `streaming.flv.idle_timeout`
- **Tipo**: string
- **Padrão**: `"60s"`
- **Descrição**: Tempo limite de inatividade antes de fechar uma conexão FLV inativa
- **Exemplo**: `"30s"`, `"60s"`, `"120s"`

### `streaming.flv.gop_cache_size`
- **Tipo**: inteiro
- **Padrão**: 1
- **Descrição**: Número de GOPs armazenados em cache para reprodução instantânea de FLV na conexão do visualizador
- **Exemplo**: `1`, `2`, `5`

## Configuração WebSocket

### `websocket.max_viewers`
- **Tipo**: inteiro
- **Padrão**: 10
- **Descrição**: número máximo de visualizadores WebSocket simultâneos por stream
- **Exemplo**: `10`, `20`, `50`

### `websocket.write_buf_size`
- **Tipo**: inteiro
- **Padrão**: 100
- **Descrição**: Tamanho do buffer de gravação para quadros WebSocket (unidades de quadros)
- **Exemplo**: `100`, `200`, `500`

### `websocket.idle_timeout`
- **Tipo**: duração
- **Padrão**: `60s`
- **Descrição**: Tempo limite de inatividade antes de fechar uma conexão WebSocket inativa
- **Exemplo**: `30s`, `60s`, `120s`

## Configuração de integridade

### `health.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Ativar o sistema de monitoramento da integridade da câmera
- **Exemplo**: `true`, `false`

### `health.events_retention`
- **Tipo**: string
- **Padrão**: `"720h"` (30 dias)
- **Descrição**: por quanto tempo reter eventos de monitoramento de integridade
- **Exemplo**: `"720h"`, `"168h"`, `"720h"`

### `health.alerts.cooldown`
- **Tipo**: string
- **Padrão**: `"5m"`
- **Descrição**: Período de espera entre alertas de saúde consecutivos
- **Exemplo**: `"1m"`, `"5m"`, `"10m"`

### `health.alerts.mqtt`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: ativar a publicação MQTT para alertas de integridade
- **Exemplo**: `true`, `false`

### `health.layer1.offline_threshold`
- **Tipo**: string
- **Padrão**: `"30s"`
- **Descrição**: Tempo sem quaisquer dados antes de uma câmera ser considerada off-line
- **Exemplo**: `"15s"`, `"30s"`, `"60s"`

### `health.layer2.bitrate_change_threshold`
- **Tipo**: flutuante
- **Padrão**: 0,5
- **Intervalo**: 0-1
- **Descrição**: limite de alteração da taxa de bits normalizado para detecção de anomalias de qualidade. Um valor de 0,5 significa que uma mudança de 50% desencadeia um evento de qualidade.
- **Exemplo**: `0.3`, `0.5`, `0.8`

### `health.layer2.min_fps`
- **Tipo**: inteiro
- **Padrão**: 5
- **Descrição**: FPS mínimo aceitável para uma câmera saudável
- **Exemplo**: `5`, `10`, `15`

### `health.layer2.max_idr_interval`
- **Tipo**: string
- **Padrão**: `"60s"`
- **Descrição**: Intervalo máximo permitido entre quadros IDR antes de acionar um evento de integridade
- **Exemplo**: `"30s"`, `"60s"`, `"120s"`

### `health.layer2_5.freeze_timeout`
- **Tipo**: string
- **Padrão**: `"10s"`
- **Descrição**: Tempo limite para detectar um stream de vídeo congelado (streaming de dados, mas sem movimento)
- **Exemplo**: `"5s"`, `"10s"`, `"30s"`

### `health.auto_remediation.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Ative a reinicialização automática da câmera quando forem detectados problemas de saúde
- **Exemplo**: `true`, `false`

### `health.auto_remediation.max_restarts_per_hour`
- **Tipo**: inteiro
- **Padrão**: 3
- **Descrição**: Número máximo de reinicializações automáticas da câmera por hora
- **Exemplo**: `3`, `5`, `10`

### `health.auto_remediation.cooldown_minutes`
- **Tipo**: inteiro
- **Padrão**: 5
- **Descrição**: Tempo de espera em minutos entre ações de correção automática
- **Exemplo**: `5`, `10`, `30`

### `health.auto_remediation.blacklist_hours`
- **Tipo**: inteiro
- **Padrão**: 1
- **Descrição**: horas para colocar uma câmera na lista negra da correção automática após exceder o limite de reinicialização
- **Exemplo**: `1`, `2`, `24`

### `health.auto_remediation.global_max_per_min`
- **Tipo**: inteiro
- **Padrão**: 10
- **Descrição**: número máximo global de ações de correção por minuto em todas as câmeras
- **Exemplo**: `10`, `20`, `50`

## Configuração de log remoto

### `remote_log.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilite o envio remoto de logs (por exemplo, para VictoriaLogs)
- **Exemplo**: `true`, `false`

### `remote_log.endpoint`
- **Tipo**: string
- **Obrigatório**: Sim (se ativado)
- **Descrição**: URL do endpoint de log remoto (por exemplo, URL de inserção do VictoriaLogs)
- **Exemplo**: `"http://localhost:9428/insert/jsonline"`

### `remote_log.format`
- **Tipo**: string
- **Padrão**: `"jsonline"`
- **Opções**: `"jsonline"`, `"loki"`
- **Descrição**: Formato de envio do log
- **Exemplo**: `"jsonline"`, `"loki"`

## Configuração de IA

### `ai.inference_timeout_ms`
- **Tipo**: inteiro
- **Padrão**: 0 (sem tempo limite)
- **Descrição**: Tempo limite de inferência em milissegundos para execução do modelo de IA
- **Exemplo**: `5000`, `10000`, `30000`

### `ai.frame_skip_rate`
- **Tipo**: inteiro
- **Padrão**: 0 (processar todos os quadros)
- **Descrição**: número de frames a serem ignorados entre execuções de inferência de IA
- **Exemplo**: `0`, `3`, `5`

### `ai.confidence_threshold`
- **Tipo**: flutuante
- **Padrão**: 0,0
- **Intervalo**: 0,0-1,0
- **Descrição**: Limite mínimo de confiança para resultados de detecção de IA
- **Exemplo**: `0.5`, `0.7`, `0.9`

### `ai.model_path`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: caminho para o arquivo do modelo ONNX para inferência de IA
- **Exemplo**: `"/models/yolo.onnx"`

## Configuração RTMP

### `rtmp.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilitar servidor de ingestão RTMP para receber fluxos push
- **Exemplo**: `true`, `false`

### `rtmp.port`
- **Tipo**: inteiro
- **Padrão**: 1935
- **Intervalo**: 1-65535
- **Descrição**: porta de escuta do servidor RTMP
- **Exemplo**: `1935`, `1936`

### `rtmp.stream_keys`
- **Tipo**: mapa (string → string)
- **Opcional**: Sim
- **Descrição**: Mapeamento de IDs de câmeras para chaves de streaming para autenticação RTMP
- **Exemplo**:
  ```yaml
  rtmp:
    stream_keys:
      cam1: "my-stream-key-1"
      cam2: "my-stream-key-2"
  ```

## Configuração SRT

### `srt.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilite o ouvinte SRT para receber fluxos MPEG-TS
- **Exemplo**: `true`, `false`

### `srt.port`
- **Tipo**: inteiro
- **Padrão**: 9000
- **Intervalo**: 1-65535
- **Descrição**: porta de escuta do listener SRT
- **Exemplo**: `9000`, `9001`

### `srt.streams`
- **Tipo**: array de objetos
- **Opcional**: Sim
- **Descrição**: mapeamentos de fluxo SRT que definem como os fluxos SRT de entrada são roteados para câmeras
- **Campos**:
  - **`camera_id`** (string, obrigatório) — ID da câmera de destino
  - **`mode`** (string, obrigatório, opções: `"listener"`/`"caller"`) — modo SRT
  - **`address`** (string, necessário para o modo chamador) — Endereço SRT remoto
  - **`passphrase`** (string, opcional) — senha de criptografia AES
  - **`stream_id`** (string, opcional) — ID de fluxo SRT para modo chamador
- **Exemplo**:
  ```yaml
  srt:
    streams:
      - camera_id: "cam1"
        mode: "listener"
      - camera_id: "cam2"
        mode: "caller"
        address: "192.168.1.100:9000"
  ```

## Configuração de autenticação de métricas

### `metrics_auth.username`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Nome de usuário para endpoint /metrics BasicAuth. Quando definido (com senha), o endpoint /metrics torna-se autenticado; caso contrário, permanecerá público.
- **Exemplo**: `"admin"`

### `metrics_auth.password`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Senha (texto simples) para o endpoint /metrics BasicAuth. Mutuamente exclusivo com password_hash.
- **Exemplo**: `"metrics-password"`

### `metrics_auth.password_hash`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Senha com hash bcrypt para endpoint /metrics BasicAuth. Tem precedência sobre a senha.
- **Exemplo**: `"$2a$10$..."`

## Configuração de transcodificação

### `transcoding.enabled`
- **Tipo**: booleano
- **Padrão**: `false`
- **Descrição**: Habilite globalmente a transcodificação baseada em FFmpeg
- **Exemplo**: `true`, `false`

### `transcoding.ffmpeg_path`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: Caminho para o binário FFmpeg. Detectado automaticamente se não for especificado.
- **Exemplo**: `"/usr/bin/ffmpeg"`

### `transcoding.max_workers`
- **Tipo**: inteiro
- **Padrão**: 1
- **Alcance**: 1-4
- **Descrição**: Número máximo de trabalhos de transcodificação simultâneos
- **Exemplo**: `1`, `2`, `4`

### `transcoding.download_url`
- **Tipo**: string
- **Opcional**: Sim
- **Descrição**: URL para baixar FFmpeg binário de (preenchido automaticamente por plataforma)
- **Exemplo**: `"https://github.com/.../ffmpeg"`

### `transcoding.job_timeout`
- **Tipo**: string
- **Padrão**: `"30m"`
- **Alcance**: 1s-4h
- **Descrição**: Timeout por trabalho para operações de transcodificação
- **Exemplo**: `"10m"`, `"30m"`, `"1h"`

### `transcoding.history_retention`
- **Tipo**: string
- **Padrão**: `"168h"` (7 dias)
- **Descrição**: Por quanto tempo manter o histórico de trabalho de transcodificação. String vazio significa nunca deletar.
- **Mínimo**: 24h
- **Exemplo**: `"168h"`, `"720h"`, `""`

## Exemplos de Protocolo de Câmera

### RTSP Câmera
```yaml
cameras:
  - id: "front-door"
    name: "Front Door Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    username: "admin"
    password: "camera-password"
    enabled: true
    sub_stream_url: "rtsp://192.168.1.100:554/stream2"
    snapshot_url: "http://192.168.1.100:8080/snapshot"
```

### HTTP JPEG Câmera
```yaml
cameras:
  - id: "backyard"
    name: "Back Yard Camera"
    protocol: "http"
    encoding: "jpeg"
    url: "http://192.168.1.101/capture"
    sample_interval: 1
    enabled: true
```

### ONVIF Câmera
```yaml
cameras:
  - id: "lobby"
    name: "Lobby Camera"
    protocol: "onvif"
    url: "http://192.168.1.102:80/onvif/device_service"
    enabled: true
    # Optional: specify encoding
    encoding: "h264"
    # Optional: specify stream encoding
    stream_encoding: "H264"
```

### Xiaomi Câmera
```yaml
xiaomi:
  user_id: "1234567890"
  token: "xiaomi_token_123"
  region: "cn"

cameras:
  - id: "xiaomi-cam"
    name: "Xiaomi Camera"
    protocol: "xiaomi"
    encoding: "h264"
    did: "xiaomi_device_id"
    vendor: "cs2"
    enabled: true
```

## Migração do Formato Legado

Formatos de protocolo legados como `"rtsp_h264"` são automaticamente convertidos para os novos campos separados de `protocol` e `encoding`:

```yaml
# Old format (still supported)
cameras:
  - id: "cam1"
    protocol: "rtsp_h264"
    url: "rtsp://..."

# Automatically converted to new format:
# protocol: "rtsp"
# encoding: "h264"
```

## Regras de validação

A configuração é validada na inicialização com as seguintes restrições:

- **IDs de câmera**: Devem ser únicos em todas as câmeras
- **URLs de câmera**: Deve ter um esquema válido (http/rtsp) e host
- **Protocolos de Câmera**: Combinações de protocolo/codificação devem ser válidas (rtsp+h264/h265/mjpeg, http+jpeg, onvif+h264/h265, xiaomi+h264/h265, timelapse)
- **ONVIF Câmeras**: Devem ter URL ou onvif_endpoint
- **Xiaomi Câmeras**: Deve ter o xiaomi.token configurado
- **Números de porta**: Devem estar na faixa 1-65535
- **Duração do Segmento**: Máximo de 30 segundos no RPi 3B
- **Dias de Retenção**: Devem ser entre 1 e 3650
- **Limiar de Disco**: Deve estar entre 50% e 99%
- **Configuração de Munção**: Todos os campos de duração devem ser válidos; min_segments_to_merge >= 2
- **HLS Configuração**:
  - Contagem de segmentos: 3-10
  - Streams máximos: 1-20 (4 no RPi 3B)
  - Baixa latência requer segment_count >= 7
  - Duração parcial min: 100ms-1s
- **Configuração de Streaming**:
  - O protocolo padrão deve ser um dos seguintes: HLS, LL-HLS, Webrtc, FLV
  - WebRTC visualização máxima: 1-10
  - Visualização máxima de FLV: 1-50
- **WebSocket Configuração**: max_viewers > 0, write_buf_size > 0, idle_timeout > 0
- **Configuração de Saúde**: Todos os campos de duração devem ser válidos quando a saúde está ativada
- **Configuração remota de log**: endpoint necessário quando ativado; O formato deve ser JSonline ou Loki
- **Configuração de Transcodificação**: max_workers 1-4; job_timeout 1s-4h; history_retention >= 24h
- **SRT Configuração**: porta 1-65535; O modo stream deve ser ouvinte ou chamador
- **Sobrescrições de Saúde da Câmera**: Todos os campos de duração devem ser válidos; bitrate_change_threshold 0-1; min_fps >= 0
- **Timelapse da câmera**: intervalo >= 1s; merge_mode deve ser auto/mp4/jpeg; mesclar_saída_fps 1-60
- **Transcodificação de câmera**: target_codec deve ser h264 ou h265; a predefinição deve ser ultrarrápida/mais rápida/média

## Caminhos e locais de arquivos

- **Caminho de configuração padrão**: `./aglus-nvr.yaml`
- **Armazenamento padrão**: `/var/lib/aglus-nvr`
- **Gravações**: `{root_dir}/recordings/{encoding}/{camera_id}/`
- **Segmentos**: `{root_dir}/recordings/{encoding}/{camera_id}/`
- **Instantâneos**: `{root_dir}/snapshots/{camera_id}/`
- **WebDAV**: `{root_dav}{root_dir}/` (onde root_dav é o caminho do proxy reverso)

## Configuração rápida

### Configuração básica
```yaml
server:
  listen: ":9090"
storage:
  root_dir: "/var/lib/aglus-nvr"
  segment_duration: "30s"
auth:
  username: "admin"
  password: "your-password-here"
cameras:
  - id: "cam1"
    name: "Camera 1"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
cleanup:
  retention_days: 30
  disk_threshold_percent: 95
```

### Configuração completa com todos os recursos
```yaml
server:
  listen: ":9090"
storage:
  root_dir: "/mnt/data/nvr"
  segment_duration: "30s"
auth:
  username: "admin"
  password_hash: "$2a$10$N9qo8uLOickgx2ZMRZoMy..."
cameras:
  - id: "front-door"
    name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    sub_stream_url: "rtsp://192.168.1.100:554/sub"
    audio_enabled: true
    transcoding:
      enabled: true
      target_codec: "h264"
      preset: "ultrafast"
  - id: "xiaomi-cam"
    name: "Xiaomi Camera"
    protocol: "xiaomi"
    encoding: "h264"
    did: "xiaomi_device_id"
    vendor: "cs2"
    enabled: true
xiaomi:
  user_id: "1234567890"
  token: "xiaomi_token_123"
  region: "cn"
cleanup:
  retention_days: 30
  disk_threshold_percent: 90
merge:
  enabled: true
  check_interval: "1h"
  batch_limit: 200
ftp:
  enabled: true
  port: 2121
mqtt:
  enabled: true
  broker: "tcp://192.168.1.100:1883"
  topic: "aglusnvr/trigger"
webdav:
  enabled: true
  read_write: false
hls:
  max_streams: 4
  low_latency: false
streaming:
  default_protocol: "hls"
  webrtc:
    enabled: true
    max_viewers: 2
  flv:
    enabled: true
    max_viewers: 10
websocket:
  max_viewers: 10
health:
  enabled: true
  layer1:
    offline_threshold: "30s"
observability:
  log_level: "info"
```