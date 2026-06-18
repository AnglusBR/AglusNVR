# Guia de Transcodificação

## Visão geral

A transcodificação converte gravações de vídeo entre diferentes codecs para otimizar o armazenamento, melhorar a compatibilidade de reprodução ou reduzir o tamanho dos arquivos. AglusNVR suporta transcodificação em segundo plano de gravações de H.264 e H.265 para qualquer formato, com presets de qualidade configuráveis.

Use a transcodificação quando precisar:
- Reduza o uso de armazenamento convertendo para codecs mais eficientes
- Melhorar a compatibilidade de reprodução em dispositivos antigos
- Converter gravações para casos de uso específicos
- Arquivo de imagens com tamanhos de arquivo otimizados

## Início Rápido

### Passo 1: Verifique o Suporte ao Hardware

```bash
# Test if your system can handle transcoding
curl -u admin:password http://localhost:9090/api/transcoding/check
```

### Passo 2: Baixe FFmpeg (se necessário)

```bash
# Automatically download FFmpeg for your platform
curl -u admin:password \
  -X POST http://localhost:9090/api/transcoding/ffmpeg/download
```

### Passo 3: Habilitar a Transcodificação

Adicione a configuração de transcodificação ao seu arquivo de configuração:

```yaml
transcoding:
  enabled: true
  max_workers: 1
  replace_original: false

cameras:
  - id: "front-door"
    name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    transcoding:
      enabled: true
      target_codec: "h264"
      preset: "medium"
      bitrate: "2M"
```

Reinicie AglusNVR para aplicar a configuração.

## Referência de Configuração

### Configurações globais

A seção `transcoding` no seu arquivo de configuração principal controla o comportamento geral de transcodificação:

```yaml
transcoding:
  enabled: true                    # Enable/disable transcoding system
  ffmpeg_path: ""                 # Auto-detected if empty
  max_workers: 1                   # Maximum concurrent transcoding jobs (1-4)
  replace_original: false          # Delete original after successful transcode
```

**Detalhes do Campo**:

- **`enabled`**: `true`/`false` - Ativar todo o sistema de transcodificação
- **`ffmpeg_path`**: Caminho opcional para FFmpeg binário. Deixe vazio para detecção automática
- **`max_workers`**: Número de processos FFmpeg concorrentes (1-4). Comece com 1 no RPi 3B
- **`replace_original`**: `true`/`false` - Excluir o arquivo original após transcodificação bem-sucedida. **Use com cautela**

### Configurações por Câmera

Câmeras individuais podem ter sua própria configuração de transcodificação:

```yaml
cameras:
  - id: "front-door"
    name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    transcoding:
      enabled: true                 # Enable transcoding for this camera
      target_codec: "h264"         # h264 or h265
      preset: "medium"             # ultrafast, faster, medium
      bitrate: "2M"                # e.g., "1M", "2M", "5M"
```

**Detalhes do Campo**:

- **`enabled`**: `true`/`false` - Anular a configuração global desta câmera
- **`target_codec`**: `"h264"` ou `"h265"` - Codec de alvo para conversão
- **`preset`**: Equilíbrio entre velocidade/qualidade:
  - `"ultrafast"`: Arquivos mais rápidos e maiores
  - `"faster"`: Good balanceamento (recomendado)
  - `"medium"`: Arquivos mais lentos e menores
- **`bitrate`**: Bitrate alvo em formatos como `"2M"` (2 Mbps) ou `"500k"` (500 kbps)

### Performance Presets

| Preset | Velocidade | Qualidade | Tamanho do Arquivo | Uso da CPU | Melhor Para |
|--------|-------|---------|-----------|-----------|----------|
| `ultrafast` | Muito Rápido | Good | Grande | Alto | Reprodução RT, armazenamento temporário |
| `faster` | Rápido | Good | Médio | Médio | Uso geral, equilíbrio |
| `medium` | Médio | Good | Pequeno | Baixo | Armazenamento em arquivo, longo prazo |

## Autoavaliação Explicada

A auto-verificação de transcodificação valida suas capacidades de hardware e disponibilidade FFmpeg:

### O que ele verifica

- **FFmpeg disponibilidade**: Procura FFmpeg binário no PATH do sistema
- **Suporte a codificadores**: Verifica suporte a codificadores H.264/H.265
- **Capacidades de hardware**: Estima fluxos concorrentes máximos e FPS
- **Requisitos de memória**: Avisa se o sistema tiver RAM insuficiente
- **Desempenho da CPU**: Estima a velocidade e a qualidade da transcodificação

### Cenários de Falha

**FFmpeg Não Disponível**:
- FFmpeg será baixado automaticamente no primeiro uso
- Monitore o progresso do download via `/api/transcoding/ffmpeg/status`

**Memória Baixa (<512MB)**:
- Aviso: O sistema pode ficar instável
- Solução: Reduzir `max_workers` para 1, evitar `replace_original`

**FPS Estimados Baixos (<5.0)**:
- Aviso: Transcodificação em tempo real pode ser muito lenta
- Solução: Use resoluções mais baixas ou reduza `max_workers`

**Codificador Não Suportado**:
- Erro: FFmpeg compilado sem suporte a H.264/H.265
- Solução: Reconstruir FFmpeg com suporte a codificadores

## Requisitos de Hardware

| Plataforma | Trabalhadores Máximos | FPS recomendados | Uso da Memória | Notas |
|----------|-------------|----------------|--------------|-------|
| Raspberry Pi 3B | 1 | 1-2 FPS | 512MB+ | Comece com apenas 1 trabalhador |
| Raspberry Pi 4 | 2 | 2-4 FPS | 1GB+ | Adequado para transcodificação de luz |
| Raspberry Pi 5 | 2-3 | 3-6 FPS | 1GB+ | Melhor desempenho |
| x86 Server | 4 | 5+ FPS | 2GB+ | Potencial total de desempenho |
| Docker | 1-2 | 2-4 FPS | 1GB+ | Depende dos recursos do host |

## Expectativas de Desempenho

### Raspberry Pi 3B
- **1 trabalhador**: ~1-2 FPS para 720p, ~1 FPS para 1080p
- **Memória**: ~300-500MB durante a transcodificação
- **Armazenamento**: ~15-30% mais velocidade de gravação
- **Recomendado**: Use `ultrafast` preset para reprodução RT

### Raspberry Pi 4/5  
- **2 trabalhadores**: ~3-4 FPS para 720p, ~2-3 FPS para 1080p
- **Memória**: ~500MB-1GB por trabalhador
- **Armazenamento**: ~25-40% mais velocidade de gravação
- **Recomendado**: `faster` preset para uso geral

### Sistemas x86
- **4 trabalhadores**: Desempenho em tempo real para múltiplos fluxos
- **Memória**: ~200-500MB por trabalhador
- **Armazenamento**: Desempenho quase em tempo real
- **Recomendado**: `medium` preset para otimização do tamanho do arquivo

## Transcodificação de Arquivos Armazenados

### Gatilho Manual via API

Transcodifica gravações existentes manualmente:

```bash
# Queue a transcoding job for a specific recording
curl -u admin:password \
  -X POST http://localhost:9090/api/transcoding/tasks \
  -H "Content-Type: application/json" \
  -d '{
    "camera_id": "front-door",
    "recording_id": "1704123456789012345",
    "target_codec": "h264",
    "replace_original": false
  }'
```

### Transcodificação Automática

Ative a transcodificação por câmera para processar automaticamente novas gravações:

```yaml
cameras:
  - id: "front-door"
    name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    transcoding:
      enabled: true
      target_codec: "h264"
      preset: "faster"
      bitrate: "2M"
```

### Monitore o Progresso

Verifique o status da transcodificação:

```bash
# View system status
curl -u admin:password http://localhost:9090/api/transcoding/status

# List all transcoding tasks
curl -u admin:password http://localhost:9090/api/transcoding/tasks

# View FFmpeg download progress
curl -u admin:password http://localhost:9090/api/transcoding/ffmpeg/status
```

## Modo Substituir

### Como Funciona

Quando `replace_original: true`, o sistema:

1. Transcodifica o arquivo original para um novo arquivo
2. Verifica se o arquivo transcodificado é válido
3. Exclui o arquivo original
4. Atualizações referências ao banco de dados

### Concessões

**Benefícios**:
- **Economia de Armazenamento**: Redução de 30-50% no tamanho do arquivo
- **Fonte do Single**: Apenas uma versão de cada gravação
- **Armazenamento Limpo**: Sem arquivos de qualidade mista

**Riscos**:
- **Perda de dados**: Gravação original deletada permanentemente
- **Verificação necessária**: Deve validar o funcionamento dos arquivos transcodificados
- **Sem recuperação**: Não é possível reverter ao original se a transcodificação falhar

### Recomendações de Segurança

1. **Sempre faça backup das gravações originais** antes de ativar o modo de substituição
2. **Teste a transcodificação** com uma única câmera primeiro
3. **Monitorar as taxas de sucesso das tarefas** via API
4. **Mantenha `replace_original: false`** para sistemas de produção
5. **Use `replace_original: true`** apenas para otimização temporária de armazenamento

```yaml
# Safe configuration (recommended for production)
transcoding:
  enabled: true
  max_workers: 1
  replace_original: false  # Keep originals for safety

cameras:
  - id: "front-door"
    transcoding:
      enabled: true
      target_codec: "h264"
      preset: "medium"
      bitrate: "2M"
```

## Monitoramento

### Prometheus Métricas

Métricas de transcodificação são expostas em `/api/metrics`:
- `aglus_nvr_transcoding_queue_length`: Tamanho atual da fila
- `aglus_nvr_transcoding_active_jobs`: Execução de processos FFmpeg
- `aglus_nvr_transcoding_total_completed`: Total de tarefas concluídas
- `aglus_nvr_transcoding_failed_total`: Tarefas fracassadas contam

### Status da interface web

Verifique o status da transcodificação na Web UI:
- **Configurações → Transcodificação**: Status do sistema e progresso FFmpeg download
- **Gravações → Ações**: Botão de transcodificação para arquivos individuais
- **Status da Fila**: Vagas ativas e pendentes contam

### API Endpoints

- `GET /api/transcoding/check` - Autochecagem de hardware
- `GET /api/transcoding/status` - Status do sistema
- `GET /api/transcoding/ffmpeg/status` - FFmpeg progresso
- `POST /api/transcoding/ffmpeg/download` - Iniciar o download
- `POST /api/transcoding/ffmpeg/download/retry` - Tentar baixar
- `GET /api/transcoding/tasks` - Listar tarefas com paginação
- `POST /api/transcoding/tasks` - Criar tarefas manuais
- `DELETE /api/transcoding/tasks/{id}` - Cancelar tarefa
- `GET /api/transcoding/cameras` - Configurações por câmera

## FAQ

### Perguntas gerais

**P: A transcodificação afeta o desempenho da gravação?**
R: Sim, a transcodificação consome CPU e memória adicionais. Comece com um trabalhador e monitore a carga do sistema.

**P: Posso transcodificar enquanto a câmera está gravando?**
R: Sim, a transcodificação roda em processos em segundo plano e não interrompe a gravação.

**P: O que acontece se a transcodificação falhar?**
R: Tarefas falhadas permanecem na fila. Verifique os logs para detalhes FFmpeg erro. Tente manualmente ou corrija o problema.

### Perguntas Técnicas

**P: Por que preciso baixar FFmpeg?**
R: FFmpeg fornece as capacidades de processamento de vídeo. AglusNVR inclui um download para obter a versão adequada para sua plataforma.

**P: Qual é a diferença entre transcodificação e fusão?**
R: A transcodificação altera o codec/formato de vídeo, enquanto a mescla combina múltiplos segmentos em menos arquivos.

**P: Posso transcodificar H.265 para H.264 em Raspberry Pi?**
R: Sim, mas o desempenho será limitado. Use `ultrafast` preset e apenas 1 trabalhador.

### Perguntas sobre Desempenho

**P: Quanto espaço de armazenamento a transcodificação vai economizar?**
R: Normalmente 30-50% para H.265→H.264 conversão, dependendo da qualidade da fonte e das configurações de bitrate.

**P: Qual é o número ideal de trabalhadores?**
R: Comece com 1 trabalhador e aumente somente se o uso da CPU permanecer abaixo de 80% durante a transcodificação.

**P: A transcodificação funciona em um Raspberry Pi 3B?**
R: Sim, mas espere desempenho reduzido. Use 1 trabalhador e presets simples para melhores resultados.

### Solução de problemas

**FFmpeg Questões**:
- Veja o progresso do download: `GET /api/transcoding/ffmpeg/status`
- Retentar downloads falhados: `POST /api/transcoding/ffmpeg/download/retry`
- Verifique FFmpeg caminho: Verifique `ffmpeg_path` na configuração

**Problemas de desempenho**:
- Reduza `max_workers` se o uso da CPU >80%
- Use `ultrafast` preset para sistemas RPi
- Desative `replace_original` se o espaço em disco for crítico

**Problemas na Fila**:
- Verifique o status da tarefa: `GET /api/transcoding/tasks`
- Cancelar tarefas travadas: `DELETE /api/transcoding/tasks/{id}`
- Verifique a câmera que tem transcodificação ativada

Para uma solução de problemas mais detalhada, verifique os documentos [Configuração](configuration.md) e [Referência da API](./api/README.md).