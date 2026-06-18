# Gravação em Timelapse

A funcionalidade de timelapse cria vídeos time-lapse a partir de gravações de câmera, comprimindo horas ou dias em minutos. AglusNVR v2 introduz grandes melhorias com durações flexíveis de mescla, suporte H.264/H.265 modo duplo e uma interface unificada de gravações.

## Visão geral

O sistema de timelapse mescla automaticamente segmentos de vídeo em gravações de timelapse comprimidas. Principais melhorias na v2:

- **Durações flexíveis de fusão**: Suporte para intervalos de 8h, 12h, 24h, dia natural, 7d e 30d
- **H.264/H.265 Modo Duplo**: Qualquer câmera RTSP agora pode gerar gravações em timelapse sem hardware adicional
- **Interface Unificada**: Página integrada de gravações com modos de visualização de tabela, galeria e calendário
- **Extração de Quadros-Chave**: Geração de timelapse sem overhead usando fluxos de RTSP existentes

## Configuração

### Configuração Básica de Timelapse

Ative a gravação em timelapse para uma câmera na configuração:

```yaml
cameras:
  - name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    
    # Timelapse configuration (v2 features)
    timelapse:
      enabled: true
      merge_duration: "natural-day"  # v2: flexible merge intervals
      frame_source: "rtsp_keyframe"  # v2: dual-mode keyframe extraction
      output_fps: 30
```

### Configuração de Modo Duplo (RTSP Câmeras)

Para câmeras RTSP existentes, ative o timelapse de modo duplo sem alterar o protocolo da câmera:

```yaml
cameras:
  - name: "Living Room Camera"
    protocol: "rtsp"
    encoding: "h265"
    url: "rtsp://192.168.1.101:554/stream"
    enabled: true
    
    timelapse:
      enabled: true                          # Enable timelapse
      merge_duration: "24h"                  # Merge every 24 hours
      frame_source: "rtsp_keyframe"         # Extract from RTSP stream
      output_fps: 30
```

### Configuração Independente de Timelapse

Crie câmeras dedicadas de timelapse com fontes de RTSP separadas:

```yaml
cameras:
  - name: "Timelapse-Only Camera"
    protocol: "timelapse"
    encoding: "h264"
    url: "rtsp://backup-camera.example.com:554/stream"
    enabled: true
    
    timlapse:
      enabled: true
      merge_duration: "7d"                  # Weekly merges
      frame_source: "rtsp_keyframe"         # Extract from timelapse stream
      output_fps: 15                         # Lower fps for longer durations
```

## Opções de Duração da Fusão (v2)

O campo `merge_duration` suporta intervalos flexíveis para diferentes casos de uso:

| Duração | Descrição | Alinhamento | Caso de Uso |
|----------|-------------|-----------|----------|
| `8h` | Fusão de 8 horas | 00:00, 08:00, 16:00 UTC | Horários de expediente, mudanças de turno |
| `12h` | Fusão de 12 horas | 00:00, 12:00 UTC | Ciclos dia/noite, segmentos AM/PM |
| `24h` | Fusão 24 horas | 00:00 UTC diariamente | Visão geral diária, revisão de segurança |
| `natural-day` | Dia natural (0-24h) | Horário local | Resumo diário amigável de usar |
| `7d` | Fusão semanal | Segunda-feira 00:00 UTC | Revisões semanais, análise de padrões |
| `30d` | Fusão mensal | 1º do mês 00:00 UTC | Relatórios mensais, análise de longo prazo |

### Exemplos de Configuração

```yaml
# 8-hour business monitoring
timelapse:
  enabled: true
  merge_duration: "8h"
  output_fps: 30

# Daily summary with natural day
timelapse:
  enabled: true
  merge_duration: "natural-day"
  output_fps: 10

# Weekly pattern analysis
timelapse:
  enabled: true
  merge_duration: "7d"
  output_fps: 5

# Monthly reports
timelapse:
  enabled: true
  merge_duration: "30d"
  output_fps: 2
```

## Timelapse de Modo Duplo (v2)

O modo duplo timelapse permite que qualquer câmera RTSP gere gravações de timelapse sem necessidade adicional de hardware.

### Como Funciona

1. **Stream RTSP Primário**: A câmera grava segmentos de vídeo normais como de costume
2. **Extração de Keyframes**: KeyframeExtractor assina o RTSP StreamHub
3. **Processamento de Quadros**: Extrai quadros IDR (tipo H.264 5, tipo H.265 tipo 19/20) do fluxo
4. **Geração de Timelapse**: Os quadros extraídos são processados em vídeos de timelapse comprimidos

### Tipos de Câmeras Suportados

- **RTSP H.264**: Câmeras IP padrão com codificação H.264
- **RTSP H.265**: Câmeras modernas com codificação H.265 para maior eficiência
- **ONVIF**: Câmeras descobertas automaticamente, tanto H.264 quanto H.265 suportadas

### H.265 Suporte

O sistema detecta automaticamente H.265 fluxos e configura o KeyframeExtractor de forma adequada:

```yaml
# ONVIF camera with H.265 stream
cameras:
  - name: "Security Camera 1"
    protocol: "onvif"
    encoding: "h265"                    # Primary encoding
    stream_encoding: "H265"            # ONVIF-specific field
    url: "onvif://192.168.1.102"
    enabled: true
    
    timelapse:
      enabled: true
      merge_duration: "24h"
      frame_source: "rtsp_keyframe"
```

## Interface Unificada de Gravações (v2)

A versão v2 une timelapse e gravações normais em uma página unificada de Biblioteca com capacidades aprimoradas de navegação e filtragem.

### Modos de visualização

Acesse diferentes visões através dos parâmetros de hash da URL:

- **Visualização da Tabela**: `#/recordings?view=table` - Lista detalhada com metadados
- **Vista da Galeria**: `#/recordings?view=gallery` - Layout em grade em miniatura
- **Visualização de Lista**: `#/recordings?view=list` - Layout compacto de lista

### Filtros de Formatação

Filtre gravações por formato usando o parâmetro `format`:

- **Todos os formatos**: `format=all` - Mostrar todos os tipos de gravação
- **Apenas vídeo**: `format=video` - Mostrar gravações de vídeo regulares
- **Somente Timelapse**: `format=timelapse` - Mostrar apenas gravações em timelapse
- **MJPEG Apenas**: `format=mjpeg` - Mostrar MJPEG gravações apenas

Os filtros de formato de navegação primário estão sempre visíveis na interface, permitindo a troca rápida entre formatos de gravação.

### Vista da Galeria

```bash
# URL: /#recordings?view=gallery&format=all
```

Exibe gravações em um layout de grade responsivo com:

- Prévias em miniatura
- Etiquetas de data/hora
- Emblemas de formato (vídeo/timelapse/mjpeg)
- Carregamento preguiçoso para desempenho
- Clique para ver/baixar as gravações

<!-- FAZER: captura de tela -->

### Vista de Lista

```bash
# URL: /#recordings?view=list&format=all
```

Fornece uma visão de lista compacta com:

- Metadados de gravação
- Informações sobre duração e tamanho do arquivo
- Indicadores de formato
- Botões de download rápido
- Capacidades de busca e filtro

<!-- FAZER: captura de tela -->

### Visualização do Calendário

```bash
# URL: /#recordings?view=calendar&format=all
```

Oferece navegação baseada em calendário com:

- Visualizações de mês/semana/dia
- Visualização de densidade de registro
- Filtragem específica por formato
- Clique nas datas para filtrar as gravações
- Controles de navegação na linha do tempo

<!-- FAZER: captura de tela -->

### Barra de Linha do Tempo

Acima das abas do modo de visualização, a barra da linha do tempo está sempre visível e fornece:

- Linha do tempo horizontal mostrando a densidade de gravação
- Seletor de intervalo de tempo (semana/mês/3 meses)
- Integração de filtros de formato
- Navegação clicável entre períodos de tempo
- Indicadores visuais para disponibilidade de registro

<!-- FAZER: captura de tela -->
<!-- FAZER: Adicionar uma captura de tela da página unificada de Gravações -->

## Guia de Migração

### De Timelapse v1 para v2

#### 1. Atualização de Configuração

**Antes (v1):**

```yaml
timelapse:
  enabled: true
  daily_merge: true
  output_fps: 30
```

**Depois de (v2):**

```yaml
timelapse:
  enabled: true
  merge_duration: "natural-day"  # v2 field
  frame_source: "rtsp_keyframe"   # v2 field
  output_fps: 30
```

#### 2. Novas Opções de Duração da Fusão

Se você quiser intervalos de merge diferentes:

```yaml
# Change from daily to 8-hour merges
timelapse:
  enabled: true
  merge_duration: "8h"            # v2: flexible intervals
  frame_source: "rtsp_keyframe"
  output_fps: 30
```

#### 3. Migração de modo duplo para câmeras RTSP existentes

Ative o timelapse nas câmeras RTSP existentes sem alterar sua configuração:

```yaml
# Before: Only regular recording
cameras:
  - name: "Existing Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true

# After: Add timelapse to existing camera
cameras:
  - name: "Existing Camera"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    
    timelapse:                     # Add this section
      enabled: true
      merge_duration: "natural-day"
      frame_source: "rtsp_keyframe"  # v2 dual-mode
      output_fps: 30
```

### Compatibilidade Retroativa

- **Câmeras existentes continuam funcionando** sem alterações
- **Legacy `daily_merge` campo** ainda funciona, mas está obsoleto
- **Gravações em timelapse existentes** permanecem acessíveis na interface unificada
- **Endpoints de API** mantêm compatibilidade com integrações existentes

### Lista de Verificação de Migração

1. [ ] Revise configurações de câmeras existentes
2. [ ] Adicionar `timelapse.enabled: true` às câmeras de RTSP desejadas
3. [ ] Defina `merge_duration` apropriada (padrão: "dia natural")
4. [ ] Teste funcionalidade de modo duplo com câmeras de amostra
5. [ ] Verifique o funcionamento da interface unificada de gravações
6. [ ] Verifique se as gravações existentes ainda estão acessíveis

## Solução de problemas

### Questões Comuns

#### 1. Extração de Quadros-Chave Não Funciona

**Sintoma**: Gravações em timelapse quadros vazios ou faltando

**Solução**: Verificar a codificação da câmera e a configuração do fluxo:

```bash
# Check if camera supports keyframe extraction
curl -u admin:password "http://localhost:9090/api/cameras/camera-id/status"
```

Certifique-se de que a codificação H.264/H.265 esteja corretamente especificada na configuração da câmera.

#### 2. Problemas com a Duração da Fusão

**Sintoma**: Fusão não rodando nos intervalos esperados

**Solução**: Verifique os registros de fusão e verifique o formato da duração:

```bash
# Check merge manager status
curl -u admin:password "http://localhost:9090/api/timelapse/status"

# Verify duration format in config
grep "merge_duration" /path/to/config.yaml
```

Valores válidos: `8h`, `12h`, `24h`, `natural-day`, `7d`, `30d`

#### 3. Configuração de Câmera de Modo Duplo

**Sintoma**: Câmera de modo duplo não gerando gravações em timelapse

**Solução**: Verificar a configuração de modo duplo:

```yaml
# Correct dual-mode setup
cameras:
  - name: "Dual-Mode Camera"
    protocol: "rtsp"                    # Must be rtsp/onvif
    encoding: "h264"                    or "h265"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
    
    timelapse:
      enabled: true                      # Must be enabled
      merge_duration: "24h"             # Set duration
      frame_source: "rtsp_keyframe"       # Keyframe source
      output_fps: 30
```

#### 4. ONVIF Codificação de Fluxo

**Sintoma**: ONVIF câmera H.265 timelapse não funcionando

**Solução**: Verifique tanto os campos `encoding` quanto `stream_encoding`:

```yaml
cameras:
  - name: "ONVIF H.265"
    protocol: "onvif"
    encoding: "h265"
    stream_encoding: "H265"  # ONVIF-specific field
    url: "onvif://192.168.1.102"
    enabled: true
    
    timelapse:
      enabled: true
      merge_duration: "24h"
      frame_source: "rtsp_keyframe"
```

### Comandos de Depuração

```bash
# Check timelapse manager status
curl -u admin:password "http://localhost:9090/api/timelapse/status"

# List all recordings (timelapse + regular)
curl -u admin:password "http://localhost:9090/api/recordings"

# Check camera timelapse configuration  
curl -u admin:password "http://localhost:9090/api/cameras/camera-id"

# View merge logs (if available)
journalctl -u aglus-nvr -f | grep merge
```

## Considerações de desempenho

### Uso da Memória

- **Extração de quadros-chave** usa memória mínima (sem decodificação de vídeo)
- **Operações de mescagem** usam arquivos temporários com buffer de 1MB
- **Compatível com RPi 3B**: Orçamento máximo de memória de 512MB

### Requisitos de Armazenamento

- **Arquivos de timelapse** são tipicamente 90-95% menores que as imagens originais
- **Duração da mescla** afeta o tamanho dos arquivos:
  - Fusão 8h: ~50-100MB por hora de filmagem
  - Fusão 24h: ~200-400MB por dia
  - Fusões 7D: ~1-2GB por semana

### Impacto na Rede

- **Modo duplo** não utiliza largura de banda adicional de rede
- **Extração de quadros-chave** funciona com fluxos de RTSP existentes
- **Interface web** carrega eficientemente com carregamento preguiçoso

## Referência API

### Pontos finais em timelapse

#### Obtenha o status de Timelapse

```bash
GET /api/timelapse/status
```

A resposta inclui configurações globais de timelapse e status de fusão.

#### Fusão do Manual do Gatilho

```bash
POST /api/timelapse/merge
```

Parámetro de consulta opcional `duration` para janelas de tempo específicas.

#### Gravações de Lista

```bash
GET /api/recordings?format=timelapse
```

Liste gravações em timelapse. Use `view=gallery|list&format=timelapse` na interface web ou acesse a página unificada da Biblioteca em `#/recordings?format=timelapse`.

### API de configuração

Atualize a configuração do timelapse da câmera:

```bash
PUT /api/cameras/camera-id
{
  "timelapse": {
    "enabled": true,
    "merge_duration": "24h",
    "frame_source": "rtsp_keyframe",
    "output_fps": 30
  }
}
```

## Melhores Práticas

### Dicas de Configuração

1. **Escolha durações de mescla apropriadas** com base no seu caso de uso:
   - Monitoramento de segurança: 8h ou 24h para revisão diária
   - Análise de negócios: 7d para padrões semanais
   - Armazenamento de longo prazo: 30d para relatórios mensais

2. **Otimizar o FPS de saída**:
   - 30 FPS: Eventos em tempo real
   - 15 FPS: Resumos diários
   - 5 FPS: Visões gerais semanais
   - 2 FPS: Relatórios mensais

3. **Use o dia natural** para resumos diários amigáveis alinhados com o horário local

### Configuração de Modo Duplo

1. **Teste com uma câmera** primeiro antes de ativar todas as câmeras
2. **Uso de armazenamento monitorado** para aumentar o volume de gravação
3. **Verificar se a codificação da câmera** está corretamente especificada (H.264/H.265)
4. **Verifique a codificação de stream** para câmeras ONVIF

### Monitoramento de Desempenho

1. **Manutenção regular**: Limpar gravações antigas de timelapse com base nas políticas de retenção
2. **Monitoramento de armazenamento**: Fique atento ao espaço disponível em disco, especialmente em mesturações de longa duração
3. **Recursos do sistema**: Monitorar o uso de memória durante operações de fusão em dispositivos com recursos limitados

## Documentação Relacionada

- [Referência de Configuração](configuration.md)
- [Guia de Câmera](camera-guide.md)
- [Referência API](api-reference.md)
- [Solução de problemas](troubleshooting.md)
