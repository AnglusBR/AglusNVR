# Prometheus Métricas

AglusNVR expõe um conjunto abrangente de métricas de Prometheus no endpoint `/metrics` HTTP para monitoramento, alerta e dashboard.

## Acessando Métricas

### Endpoint

```
GET /metrics
```

**Padrão:** `/metrics` é público (não é necessário autenticação).

**Autenticação Opcional:** Defina `metrics_auth` na configuração para proteger o endpoint de métricas com credenciais de BasicAuth separadas:

```yaml
metrics_auth:
  username: "metrics"
  password: "your_metrics_password"
```

### Configuração de Raspagem

Adicione ao seu `prometheus.yml`:

```yaml
scrape_configs:
  - job_name: 'aglus-nvr'
    static_configs:
      - targets: ['localhost:9090']
    metrics_path: '/metrics'
    # If metrics_auth is configured:
    basic_auth:
      username: 'metrics'
      password: 'your_metrics_password'
```

### Verificar

```bash
# Public endpoint
curl http://localhost:9090/metrics

# Authenticated endpoint
curl -u metrics:password http://localhost:9090/metrics
```

## Visão Geral das Métricas

Todas as métricas personalizadas usam o prefixo `nvr_`. Abaixo está o catálogo completo organizado por subsistema.

---

## 1. Métricas de Registro

Operações de gravação de rastreamento — criação de segmentos, contagem de bytes e sessões ativas.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_active_cameras` | Bitola | — | Número de câmeras atualmente ativas (conectadas e em streaming) |
| `nvr_active_recordings` | Bitola | — | Número de sessões de gravação atualmente ativas |
| `nvr_recording_bytes_total` | Contador | `camera_id`, `codec` | Total de bytes gravados nos segmentos de gravação |
| `nvr_segments_created_total` | Contador | `camera_id`, `codec` | Total de MP4 segmentos criados |
| `nvr_recording_count` | Bitola | — | Número atual de entradas de registro no banco de dados |
| `nvr_recorder_ring_buffer_drops_total` | Contador | `camera_id` | Quadros perdidos devido ao transbordamento do anel de buffer do gravador |

**`codec` valores de etiquetas:** `h264`, `h265`, `mjpeg`, `http_jpeg`, `timelapse` ou Xiaomi nome de codec.

**Uso:** Monitorar a saúde da gravação — uma taxa de queda que aumenta rapidamente indica que o gravador não consegue acompanhar a transmissão. Use `rate(nvr_recorder_ring_buffer_drops_total[5m])` para detectar perda de quadros.

---

## 2. Métricas de Armazenamento

Rastreie o uso e a capacidade do disco.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_storage_used_bytes` | Bitola | — | Espaço de armazenamento consumido pelas gravações |
| `nvr_storage_total_bytes` | Bitola | — | Capacidade total de armazenamento disponível |

**Uso:** Configure alertas em limites de 80%/90%:

```promql
nvr_storage_used_bytes / nvr_storage_total_bytes > 0.8
```

---

## 3. Métricas de Limpeza

Rastreie operações de retenção e limpeza de limiar de disco.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_cleanup_deleted_total` | Contador | `reason` | Total de gravações deletadas por trabalhos de limpeza |

**`reason` valores de etiquetas:** `retention`, `disk_threshold`, `archive_retention`, `orphan`.

**Uso:** Monitorar a atividade de limpeza:

```promql
rate(nvr_cleanup_deleted_total[1h])
```

---

## 4. HLS Métricas de Streaming

Acompanhe HLS desempenho de streaming sob demanda.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_hls_active_streams` | Bitola | `camera_id` | Número de riachos de HLS atualmente ativos |
| `nvr_hls_frames_dropped_total` | Contador | `camera_id` | HLS frames perdidos devido ao buffer cheio |
| `nvr_hls_write_errors_total` | Contador | `camera_id` | HLS erros de escrita no muxer |
| `nvr_hls_muxer_restarts_total` | Contador | `camera_id` | HLS muxer reinicia após erros de escrita |
| `nvr_hls_segment_size_bytes` | Histograma | `camera_id` | Distribuição de HLS tamanhos de arquivo de segmento |
| `nvr_hls_idle_evictions_total` | Contador | `camera_id` | HLS streams eliminados devido ao tempo de espera |

**Baldes** para `nvr_hls_segment_size_bytes`: 64KB, 128KB, 256KB, 512KB, 1MB, 2MB, 4MB, 8MB, 16MB.

**Uso:**

```promql
# HLS frame drop rate per camera
rate(nvr_hls_frames_dropped_total[5m])

# Active HLS viewers per camera
nvr_hls_active_streams

# Segment size P90
histogram_quantile(0.9, rate(nvr_hls_segment_size_bytes_bucket[5m]))
```

---

## 5. WebRTC Métricas de Streaming

Acompanhe WebRTC WHEP streaming com latência abaixo de um segundo.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_webrtc_active_peers` | Bitola | `camera_id` | Atividades WebRTC PeerConnections |
| `nvr_webrtc_frames_sent_total` | Contador | `camera_id` | Quadros enviados com sucesso via WebRTC |
| `nvr_webrtc_frames_dropped_total` | Contador | `camera_id` | Quadros perdidos devido ao buffer cheio |
| `nvr_webrtc_connection_state_changes_total` | Contador | `camera_id`, `state` | WebRTC transições de estado da conexão |

**`state` valores de rótulos:** `new`, `connecting`, `connected`, `disconnected`, `failed`, `closed`.

**Uso:**

```promql
# WebRTC frame loss rate
rate(nvr_webrtc_frames_dropped_total[5m]) / (rate(nvr_webrtc_frames_sent_total[5m]) + rate(nvr_webrtc_frames_dropped_total[5m]))

# Connection failures
rate(nvr_webrtc_connection_state_changes_total{state="failed"}[5m])
```

---

## 6. HTTP-FLV Métricas de Streaming

Acompanhe HTTP-FLV streaming no navegador.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_flv_active_streams` | Bitola | `camera_id` | Visualizadores FLV ativos |
| `nvr_flv_frames_sent_total` | Contador | `camera_id` | Quadros FLV enviados para os espectadores |
| `nvr_flv_frames_dropped_total` | Contador | `camera_id` | Frames FLV perdidos devido ao buffer cheio |
| `nvr_flv_gop_cache_hits_total` | Contador | `camera_id` | Acessos em cache FLV GOP (entrada rápida para novos visualizadores) |
| `nvr_flv_gop_cache_misses_total` | Contador | `camera_id` | Falhas no cache FLV GOP (novo visualizador, sem GOP em cache) |

**Uso:**

```promql
# FLV cache hit rate — high ratio means fast viewer joins
rate(nvr_flv_gop_cache_hits_total[5m]) / (rate(nvr_flv_gop_cache_hits_total[5m]) + rate(nvr_flv_gop_cache_misses_total[5m]))
```

---

## 7. Xiaomi Métricas de Câmera

Estabilidade da conexão da câmera P2P da Xiaomi Track .

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_xiaomi_disconnects_total` | Contador | `camera_id`, `reason` | Xiaomi desconexões da câmera |
| `nvr_xiaomi_reconnects_total` | Contador | `camera_id` | Xiaomi reconexões de câmeras |

**`reason` valores de etiquetas:** `network`, `eof`, `idle_timeout`.

**Uso:**

```promql
# Unstable Xiaomi cameras (high disconnect rate)
rate(nvr_xiaomi_disconnects_total[15m]) > 0.1
```

---

## 8. Métricas de Conexão de Câmera

Acompanhe a saúde geral da conexão da câmera e o comportamento de reconexão.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_camera_errors_total` | Contador | `camera_id`, `error_type` | Erros de câmera durante a gravação |
| `nvr_camera_connection_errors_total` | Contador | `camera_id`, `error_type` | Erros de conexão da câmera (timeout, auth, rede, desconhecido) |
| `nvr_camera_reconnect_attempts_total` | Contador | `camera_id` | Tentativas de reconexão da câmera |
| `nvr_camera_reconnect_backoff_seconds` | Bitola | `camera_id` | Duração do reconectivismo de corrente |

**`error_type` valores de rótulos para `nvr_camera_connection_errors_total`:** `timeout`, `auth`, `network`, `unknown`.

**`error_type` valores de rótulos para `nvr_camera_errors_total`:** Tipos de erro específicos de protocolo reportados por gravadores individuais.

**Uso:**

```promql
# Cameras with excessive reconnect attempts
rate(nvr_camera_reconnect_attempts_total[5m]) > 0.1

# Connection errors by type
rate(nvr_camera_connection_errors_total[5m])
```

---

## 9. StreamHub / Métricas de Pipeline

Acompanhe o pipeline interno de distribuição de quadros. Essas métricas ajudam a diagnosticar gargalos e perda de quadros no sistema de distribuição do StreamHub.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_streamhub_frames_in_total` | Contador | `camera_id` | Total de quadros transmitidos no StreamHub |
| `nvr_streamhub_frames_dropped_total` | Contador | `camera_id`, `consumer`, `is_idr` | Frames perdidos pelo StreamHub (buffer cheio) |
| `nvr_streamhub_consumer_buffer_depth` | Bitola | `camera_id`, `consumer` | Profundidade atual do buffer para cada consumidor |
| `nvr_frame_processing_duration_seconds` | Histograma | `camera_id`, `protocol` | Tempo de processamento de quadros através do pipeline (amostragem 1:100) |
| `nvr_jitter_buffer_depth` | Bitola | `camera_id` | Contagem atual de frames de buffer de jitter |
| `nvr_jitter_buffer_reorders_total` | Contador | `camera_id` | Quadros fora de ordem detectados |

**`consumer` valores de etiquetas:** `hls`, `webrtc`, `flv`, `wsstream`, `recorder`, `ai`, etc.

**`is_idr` valores de etiquetas:** `true` (IDR/quadro chave), `false`.

**Baldes** para `nvr_frame_processing_duration_seconds`: 1ms, 2ms, 5ms, 10ms, 25ms, 50ms, 100ms, 250ms, 500ms, 1s, 2,5s, 5s.

**Uso:**

```promql
# StreamHub frame drop rate per consumer
rate(nvr_streamhub_frames_dropped_total[5m])

# High consumer buffer depth (potential bottleneck)
nvr_streamhub_consumer_buffer_depth > 100

# Frame processing latency P99
histogram_quantile(0.99, rate(nvr_frame_processing_duration_seconds_bucket[5m]))

# Jitter buffer activity — non-zero = out-of-order frames
nvr_jitter_buffer_depth
```

---

## 10. Métricas de Ponte → Prometheus Saúde

Métricas de qualidade de transmissão de câmeras em tempo real conectadas pelo sistema de monitoramento de saúde.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_stream_fps` | Bitola | `camera_id` | Quadros atuais por segundo |
| `nvr_stream_bitrate_kbps` | Bitola | `camera_id` | Taxa de bits do fluxo atual em kbps |
| `nvr_stream_idr_interval_seconds` | Bitola | `camera_id` | Segundos desde o último quadro IDR (key) |

**Uso:**

```promql
# Low FPS alert
nvr_stream_fps < 10

# Stale IDR — no keyframe received recently (potential stream freeze)
nvr_stream_idr_interval_seconds > 30

# Bitrate drops to zero (stream disconnected)
nvr_stream_bitrate_kbps == 0
```

---

## 11. Métricas de Transcodificação

Acompanhe FFmpeg trabalhos de transcodificação.

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_transcoding_jobs_total` | Contador | `codec_from`, `codec_to`, `status` | Total de trabalhos de transcodificação por conversão de codec e resultado |
| `nvr_transcoding_active_jobs` | Bitola | — | Atualmente executando trabalhos de transcodificação |
| `nvr_transcoding_duration_seconds` | Histograma | `codec_from`, `codec_to` | Duração dos trabalhos de transcodificação concluídos |
| `nvr_transcoding_bytes_processed` | Contador | — | Bytes totais processados por transcodificação |
| `nvr_transcoding_ffmpeg_status` | Bitola | — | FFmpeg disponibilidade: 0=not_installed, 1=baixando, 2=disponível |

**`status` valores de etiquetas:** `completed`, `failed`, `cancelled`.

**Uso:**

```promql
# Transcoding failure rate
rate(nvr_transcoding_jobs_total{status="failed"}[5m]) / rate(nvr_transcoding_jobs_total[5m])

# Active jobs vs capacity
nvr_transcoding_active_jobs

# FFmpeg not installed alert
nvr_transcoding_ffmpeg_status == 0
```

---

## 12. Métricas de Logs Remotas

Rastrear o transporte remoto de toras (VictoriaLogs / Loki).

| Métrica | Tipo | Gravadoras | Descrição |
|--------|------|--------|-------------|
| `nvr_remote_log_sent_total` | Contador | — | Envio de lotes de logs remotos bem-sucedidos |
| `nvr_remote_log_dropped_total` | Contador | — | Lotes de logs remotos foram descartados devido a falha de envio |
| `nvr_remote_log_batch_size` | Histograma | — | Distribuição de tamanhos de lotes logarímicos remotos |

**Balas** para `nvr_remote_log_batch_size`: 1, 2, 4, 8, 16, 32, 64, 128 (exponencial).

**Uso:**

```promql
# Remote log drop rate
rate(nvr_remote_log_dropped_total[5m]) > 0
```

---

## 13. Métricas de Tempo de Execução Embutidas

Além das métricas de NVR personalizadas, esses coletores padrão são registrados:

### Go Estatísticas de Memória em Tempo de Execução (limitadas para RPi 3B)

Todas as métricas padrão de Go de memória prefixadas com `go_*`: uso de memória, contagem de gorotinas, estatísticas GC, etc.

Somente `GoRuntimeMemStatsCollection` é ativada para minimizar a sobrecarga em dispositivos com recursos limitados.

### Coletor de Processos

| Métrica | Descrição |
|--------|-------------|
| `nvr_process_cpu_seconds_total` | Tempo total consumido pela CPU |
| `nvr_process_open_fds` | Número de descritores de arquivo abertos |
| `nvr_process_max_fds` | Descritores máximos de arquivo |
| `nvr_process_resident_memory_bytes` | Tamanho da memória residente |
| `nvr_process_virtual_memory_bytes` | Tamanho da memória virtual |
| `nvr_process_virtual_memory_max_bytes` | Memória virtual máxima |

**Uso:**

```promql
# Memory usage alert (RPi 3B: 512MB budget)
nvr_process_resident_memory_bytes > 500 * 1024 * 1024

# Goroutine leak detection
go_goroutines > 500
```

---

## Exemplo: Consultas no Painel Grafana

### Painel de Saúde do Sistema

```promql
# Uptime — process start time
time() - process_start_time_seconds{job="aglus-nvr"}

# Memory usage
nvr_process_resident_memory_bytes

# CPU usage rate
rate(nvr_process_cpu_seconds_total[1m])
```

### Painel de Visão Geral da Câmera

```promql
# Active cameras
nvr_active_cameras

# Active recordings
nvr_active_recordings

# Total cameras (from recording count)
nvr_recording_count
```

### Painel de Streaming

```promql
# HLS viewers per camera
nvr_hls_active_streams

# WebRTC viewers per camera
nvr_webrtc_active_peers

# FLV viewers per camera
nvr_flv_active_streams
```

### Painel de Qualidade

```promql
# Top cameras by frame drop rate
topk(5, rate(nvr_streamhub_frames_dropped_total[5m]))

# Slow cameras by processing time
topk(5, histogram_quantile(0.99, rate(nvr_frame_processing_duration_seconds_bucket[5m])))
```

---

## Lenda: Tipos Métricos

| Tipo | Comportamento | Caso de Uso |
|------|----------|----------|
| **Calibre** | Valor único que pode subir e descer | Fluxos ativos, profundidade do buffer, uso de armazenamento |
| **Contador** | Aumentando monotonicamente (reinicia ao reiniciar) | Total de bytes, quadros enviados, erros |
| **Histograma** | Observações em baldes com contagem/soma | Duração, distribuição de tamanho |

---

## Referência de Configuração

O `/metrics` endpoint é configurado em `cmd/aglus-nvr/main.go` usando `promhttp.HandlerFor` com `ContinueOnError` tratamento de erros. Ele usa um registro de Prometheus personalizado (não o padrão global) para isolar NVR métricas.

Campo de configuração para autenticação de métricas:

```yaml
metrics_auth:
  username: "metrics"         # Required
  password: "secret"          # Mutually exclusive with password_hash
  password_hash: "$2a$10$..." # bcrypt hash (alternative to password)
```

Quando `metrics_auth` não está configurado, o endpoint `/metrics` fica acessível sem autenticação.

Para configurar, use `aglus-nvr hash-password sua-senha` para gerar um hash bcrypt, ou defina a senha como texto simples (ela será convertida automaticamente na primeira execução).
