# Guia de Solução de Problemas

Este guia ajuda você a diagnosticar e resolver problemas comuns com AglusNVR. Se você não encontrar uma solução aqui, verifique a [Configuração Reference](configuration.md) ou pesquise problemas existentes no GitHub.

## Questões Comuns

### Falhas no Exame de Saúde

#### Problemas de Conexão de Banco de Dados
**Sintoma**: Exame de saúde mostra `"database": {"status": "error", "message": "database is closed"}`
```json
{
  "status": "error",
  "checks": {
    "database": {"status": "error", "message": "database is closed"}
  }
}
```

**Solução**:
1. Verifique se o diretório de armazenamento existe e é gravável:
   ```bash
   ls -la /var/lib/aglus-nvr/
   sudo chown -R nvr:nvr /var/lib/aglus-nvr/
   ```
2. Verifique se o arquivo do banco de dados não está corrompido:
   ```bash
   ls -la /var/lib/aglus-nvr/aglus-nvr.db
   file /var/lib/aglus-nvr/aglus-nvr.db
   ```
3. Tente reinicializar o banco de dados:
   ```bash
   mv /var/lib/aglus-nvr/aglus-nvr.db /var/lib/aglus-nvr/aglus-nvr.db.backup
   ./aglus-nvr -config aglus-nvr.yaml
   ```

#### Problemas de Espaço de Armazenamento
**Sintoma**: Exame de saúde mostra `"storage": {"status": "error", "message": "disk space critically low"}`
```json
{
  "status": "error", 
  "checks": {
    "storage": {"status": "error", "message": "disk space critically low"}
  }
}
```

**Solução**:
1. Verifique o uso do disco:
   ```bash
   df -h
   du -sh /var/lib/aglus-nvr/recordings/
   ```
2. Limpe gravações antigas:
   ```bash
   find /var/lib/aglus-nvr/recordings/ -type f -mtime +30 -delete
   ```
3. Ajuste os dias de retenção na configuração:
   ```yaml
   cleanup:
     retention_days: 7  # Reduce from 30 to 7 days
     disk_threshold_percent: 90  # Lower from 95 to 90
   ```

## Problemas com a Câmera

### Câmera Não Encontrada

#### Autenticação Falhada
**Sintoma**: Erro `"authentication failed: invalid username or password"` ou `"camera authentication failed"`

**Solução**:
1. Teste a conexão da câmera manualmente:
   ```bash
   # For RTSP
   ffprobe -rtsp_transport tcp "rtsp://username:password@192.168.1.100:554/stream"
   
   # For HTTP JPEG
   curl -I "http://username:password@192.168.1.100/capture"
   ```
2. Verifique as credenciais da câmera na configuração
3. Verifique se a câmera é acessível pelo servidor:
   ```bash
   ping 192.168.1.100
   nc -zv 192.168.1.100 554
   ```

#### Problemas de Formato de URL
**Sintoma**: `"camera URL has invalid format"` de erro ou tempos de conexão

**Solução**:
1. Certifique-se de que a URL tenha o formato correto:
   ```yaml
   # RTSP - must include port
   url: "rtsp://192.168.1.100:554/stream"
   
   # HTTP - must include path to capture
   url: "http://192.168.1.100/capture"
   url: "http://192.168.1.100:8080/cgi-bin/snapshot.cgi"
   ```
2. Tente diferentes métodos de transporte para RTSP:
   ```yaml
   # Try TCP first (more reliable)
   protocol: "rtsp"
   # Try UDP if TCP fails
   ```

### Problemas de gravação de câmeras

#### Câmera mostra status "Sem sinal"
**Sintoma**: Câmera ativada, mas o status mostra `"status": "no_signal"`

**Solução**:
1. Verifique os registros das câmeras para erros de conexão:
   ```bash
   journalctl -u aglus-nvr -f
   ```
2. Teste do stream da câmera manualmente:
   ```bash
   # View RTSP stream
   ffplay -rtsp_transport tcp "rtsp://username:password@192.168.1.100:554/stream"
   
   # Test HTTP JPEG
   curl -o test.jpg "http://username:password@192.168.1.100/capture"
   file test.jpg
   ```
3. Tente ajustar a duração dos segmentos para câmeras problemáticas:
   ```yaml
   storage:
     segment_duration: "15s"  # Shorter segments for unstable cameras
   ```

#### Câmera mostra status de "Desativado"
**Sintoma**: A câmera mostra `"enabled": true` mas o status é `"disabled"`

**Solução**:
1. Verifique erros de validação de configuração:
   ```bash
   ./aglus-nvr -config aglus-nvr.yaml --validate
   ```
2. Verifique se todos os campos de câmera necessários estão presentes:
   ```yaml
   cameras:
     - id: "cam1"
       name: "Camera 1"
       protocol: "rtsp"
       encoding: "h264"
       url: "rtsp://..."  # Required for rtsp/http
       enabled: true
   ```
3. Verifique IDs de câmeras duplicados:
   ```bash
   grep -r "id:" aglus-nvr.yaml
   ```

#SX|## Edições de Visualização ao Vivo
#SY|
#HB|### Painel ou visualização ao vivo mostra carregamento indefinidamente
#SY|
#XW|**Sintoma**: A grade de câmeras do painel ou a página de Visualização ao Vivo mostra "Buffering" ou "Carregando..." indefinidamente. O vídeo nunca começa a tocar.
#PR|
#SY|**Root Cause**: HLS.js 1.6+ usa `fetch` API por padrão em vez de XHR. Se os cabeçalhos de autenticação não forem injetados nas requisições de busca, o servidor retorna 401 Unauthorized, e o fluxo não pode carregar.
#PR|
#SY|**Solução**:
#HB|1. Certifique-se de estar rodando AglusNVR v0.6.0 ou posterior, que inclui a correção `fetchSetup` autenticação
#RP|2. Verifique o console do navegador (F12) para erros 401 em requisições `.m3u8` ou `.ts`
#WW|3. Verifique se a câmera está gravando (status = "Gravando") antes de tentar a visualização ao vivo
#SR|4. Para câmeras em estado de "Reconectão", aguarde a câmera se reconectar — HLS requer um fluxo de gravação ativo
#SY|
#RM|### Stream mostra erro "SPS/PPS não disponível" (503)
#SY|
#XW|**Sintoma**: HLS endpoint retorna HTTP 503 com a mensagem "SPS/PPS não disponível ainda"
#PR|
#SY|**Solução**:
#HB|1. Isso é normal nos primeiros segundos após a câmera começar a gravar — o codificador de vídeo precisa produzir dados de quadros-chave
#RP|2. O frontend tenta automaticamente com recuo exponencial (5s, 10s, 20s, 40s)
#WW|3. Se o erro persistir por mais de 60 segundos, confira:
#SR|   - A câmera está realmente transmitindo vídeo (teste com `ffprobe`)
#XW|   - Gravação ativa (verifique o status da câmera via API)
#SY|   '''bash
#HB|   curl -u admin:password http://localhost:9090/api/cameras/{id}/stream/index.m3u8
#WW|   ```
#SY|
#HB|### Transmissão toca na visualização ao vivo, mas não no painel
#SY|
#XW|**Sintoma**: A Visualização ao Vivo de uma câmera individual funciona, mas a grade do Painel mostra todas as câmeras presas em "Buffering"
#PR|
#SY|**Solução**:
#HB|1. O painel carrega múltiplos fluxos simultaneamente — verifique `hls.max_streams` configuração (padrão: 4)
#RP|2. Reduzir a contagem de câmeras no painel (máximo 4, menos é melhor no RPi)
#WW|3. Use URLs de sub-stream para o Painel para reduzir a largura de banda:
#SR|   '''yaml
#HB|   Câmeras:
#XW|     - ID: "CAM1"
#SY|       sub_stream_url: "rtsp://192.168.1.100:554/sub" # Fluxo de resolução mais baixa
#WW|       hls_max_fps: 10 # Limite de taxa de quadros para o Dashboard
#SR|   ```
#WW|4. Em dispositivos de baixo consumo (RPi 3B), limite o Dashboard a 2 câmeras HLS
#SY|
#RM|### Fluxo máximo concorrente alcançado
#SY|
#XW|**Sintoma**: Stream não inicia com o erro "máximo de HLS concorrentes atingidas"
#PR|
#SY|**Solução**:
#HB|1. Feche abas não utilizadas do Painel ou do Live View
#RP|2. Aumente `max_streams` se seu hardware aguentar:
#WW|   '''yaml
#SR|   HLS:
#HB|     max_streams: 6 # Aumento em relação ao padrão 4
#WW|   ```
#SR|3. Use miniaturas de snapshot em vez de transmissões ao vivo para algumas câmeras:
#SY|   '''yaml
#HB|   Câmeras:
#XW|     - id: "cam-low-priority"
#SY|       snapshot_url: "http://192.168.1.100/snapshot"
#WW|   ```
#PR|
#JB|
#NX|## Problemas de Gravação
#SY|
### ONVIF Problemas com a Câmera

#### ONVIF Falha na Descoberta
**Sintoma**: Não é possível identificar câmeras ONVIF ou erros `"ONVIF not camera"`

**Solução**:
1. Teste ONVIF descoberta manualmente:
   ```bash
   onvif-discover
   ```
2. Verifique o suporte da câmera ONVIF:
   - Verifique a documentação do fabricante da câmera
   - Certifique-se de que ONVIF serviço esteja ativado na câmera
3. Tente diferentes métodos de descoberta:
   ```yaml
   # Use specific IP range
   onvif:
     discover:
       timeout: 10
       target: "192.168.1.0/24"
   ```

#### ONVIF Questões de Perfil
**Sintoma**: `"ONVIF no profiles"` ou controle PTZ não funcionando

**Solução**:
1. Acesse perfis disponíveis:
   ```bash
   curl -u admin:password http://localhost:9090/api/cameras/cam-id/onvif/profiles
   ```
2. Especificar manualmente o token de perfil:
   ```yaml
   cameras:
     - id: "onvif-cam"
       protocol: "onvif"
       profile_token: "profile_1"  # Use specific profile
       stream_encoding: "H264"
   ```

### Xiaomi Problemas com a Câmera

#### Xiaomi Falha na Autenticação
**Sintoma**: `"xiaomi authentication failed"` erros

**Solução**:
1. Teste Xiaomi autenticação manualmente:
   ```bash
   curl -X POST http://localhost:9090/api/xiaomi/auth \
     -H "Content-Type: application/json" \
     -d '{"username": "your-email@example.com", "password": "your-password"}'
   ```
2. Verifique Xiaomi conta:
   - Verifique se a conta tem Xiaomi dispositivos
   - Certifique-se de que a conta está na região correta
   - Tente reautenticar
3. Verifique Xiaomi status do dispositivo:
   ```bash
   curl -u admin:password http://localhost:9090/api/xiaomi/devices
   ```

#### Xiaomi Dispositivo Não Encontrado
**Sintoma**: Xiaomi câmera mostra `"online": false` ou não consegue conectar

**Solução**:
1. Verifique Xiaomi ID do dispositivo:
   ```bash
   # List devices to find correct DID
   curl -u admin:password http://localhost:9090/api/xiaomi/devices
   ```
2. Verifique a compatibilidade do dispositivo:
   - Apenas Xiaomi câmeras CS2 são suportadas
   - O modelo de dispositivo Verify é suportado
3. Tente sincronização manual:
   ```bash
   curl -X POST -u admin:password http://localhost:9090/api/xiaomi/sync
   ```

## Problemas de gravação

### Nenhuma gravação criada

#### Sem espaço em disco
**Sintoma**: Diretório de gravação vazio, mas câmeras ativas

**Solução**:
1. Verifique o espaço do disco:
   ```bash
   df -h
   du -sh /var/lib/aglus-nvr/
   ```
2. Limpar espaço em disco:
   ```bash
   # Find and delete old recordings
   find /var/lib/aglus-nvr/recordings/ -type f -mtime +30 -delete
   
   # Clean up snapshots
   find /var/lib/aglus-nvr/snapshots/ -type f -mtime +7 -delete
   ```
3. Limiar de disco inferior:
   ```yaml
   cleanup:
     disk_threshold_percent: 90  # Lower from 95
   ```

#### Questões de Permissão
**Sintoma**: Gravações não gravadas no disco

**Solução**:
1. Verifique as permissões do diretório:
   ```bash
   ls -la /var/lib/aglus-nvr/
   ls -la /var/lib/aglus-nvr/recordings/
   ```
2. Permissões de correção:
   ```bash
   sudo chown -R nvr:nvr /var/lib/aglus-nvr/
   sudo chmod -R 755 /var/lib/aglus-nvr/
   ```
3. Verifique se o disco está montado corretamente:
   ```bash
   mount | grep aglus-nvr
   df -h /var/lib/aglus-nvr/
   ```

### Gravações Corrompidas

#### MP4 Arquivos Não Funcionam
**Sintoma**: Gravações criadas, mas que não podem ser reproduzidas com reprodutores de mídia

**Solução**:
1. Verifique a integridade do arquivo:
   ```bash
   file /var/lib/aglus-nvr/recordings/h264/cam_1704123456789012345.mp4
   ffprobe -v quiet -show_format -show_streams /var/lib/aglus-nvr/recordings/h264/cam_1704123456789012345.mp4
   ```
2. Ajuste a duração do segmento:
   ```yaml
   storage:
     segment_duration: "30s"  # Use standard duration
   ```
3. Verifique se há problemas na fusão de segmentos:
   ```bash
   # Check merge status
   curl -u admin:password http://localhost:9090/api/merge/status
   
   # Check pending segments
   curl -u admin:password http://localhost:9090/api/merge/pending
   ```

### Alto Uso de Memória

#### Câmera consome RAM demais
**Sintoma**: Sistema fica sem resposta ou o assassino OOM ativa

**Solução**:
1. Verifique o uso da memória:
   ```bash
   free -h
   ps aux | grep aglus-nvr
   ```
2. Reduzir a duração do segmento:
   ```yaml
   storage:
     segment_duration: "15s"  # Shorter segments = less RAM usage
   ```
3. Ative sub-streams para prévia ao vivo:
   ```yaml
   cameras:
     - id: "cam1"
       sub_stream_url: "rtsp://192.168.1.100:554/low"  # Lower bandwidth stream
   ```
4. Limite de FPS para câmeras MJPEG:
   ```yaml
   cameras:
     - id: "mjpeg-cam"
       sample_interval: 2  # Sample every 2 seconds
       hls_max_fps: 15      # Limit to 15 FPS
   ```

## Problemas com a rede

### Conflitos nos Portos

#### Porta já em uso
**Sintoma**: Não é possível iniciar o servidor, porta já vinculada

**Solução**:
1. Verifique qual processo está usando a porta:
   ```bash
   sudo netstat -tulpn | grep :9090
   sudo lsof -i :9090
   ```
2. Troque a configuração da porta:
   ```yaml
   server:
     listen: ":8080"  # Use different port
   ```
3. Elimine o processo conflitante:
   ```bash
   sudo kill -9 <PID>
   ```

### Problemas com firewall

#### Não é possível acessar a interface web
**Sintoma**: Conexões externas para a interface web falham

**Solução**:
1. Verifique o status do firewall:
   ```bash
   sudo ufw status
   sudo iptables -L -n
   ```
2. Abra portas obrigatórias:
   ```bash
   # For Ubuntu/Debian
   sudo ufw allow 9090/tcp
   sudo ufw allow 2121/tcp  # FTP
   sudo ufw allow 5005/tcp  # WebDAV (if enabled)
   
   # For CentOS/RHEL
   sudo firewall-cmd --permanent --add-port=9090/tcp
   sudo firewall-cmd --reload
   ```
3. Verifique a configuração do proxy reverso (se utilizada):
   ```nginx
   # Caddy example
   reverse_proxy localhost:9090
   ```

## Problemas de desempenho

### Alto Uso de CPU

#### Câmeras demais
**Sintoma**: Alto uso de CPU afetando o desempenho do sistema

**Solução**:
1. Monitore o uso da CPU:
   ```bash
   top -p $(pgrep aglus-nvr)
   htop -p $(pgrep aglus-nvr)
   ```
2. Reduzir o processamento simultâneo da câmera:
   - Desative câmeras desnecessárias
   - Use subtransmissões para assistir ao vivo
   - Aumentar os intervalos de amostragem para câmeras MJPEG
3. Otimize a fusão de segmentos:
   ```yaml
   merge:
     batch_limit: 100  # Reduce from 200
     check_interval: "2h"  # Less frequent checks
   ```

#### Muitos Fluxos Simultâneos
**Sintoma**: CPU alta durante a exibição ao vivo

**Solução**:
1. Limite HLS streams:
   ```yaml
   hls:
     max_streams: 2  # Reduce from 4
   ```
2. Use miniaturas de snapshot em vez de transmissões ao vivo:
   ```yaml
   cameras:
     - id: "cam1"
       snapshot_url: "http://192.168.1.100/snapshot"  # Use snapshots for thumbnails
   ```

### Alto Uso de Rede

#### Largura de Banda Saturada
**Sintoma**: Interface de rede saturada, afetando outros serviços

**Solução**:
1. Monitore o uso da rede:
   ```bash
   iftop -i eth0 -t
   nethogs
   ```
2. Otimize os fluxos de câmera:
   ```yaml
   cameras:
     - id: "cam1"
       sub_stream_url: "rtsp://192.168.1.100:554/sub"  # Lower bandwidth sub-stream
       hls_max_fps: 15  # Limit frame rate
   ```
3. Ative o cache de snapshots:
   ```yaml
   cameras:
     - id: "cam1"
       snapshot_url: "http://192.168.1.100/snapshot"  # Snapshots use less bandwidth
   ```

## Docker Questões

### O contêiner não liga
**Sintoma**: Docker contêiner sai imediatamente

**Solução**:
1. Verifique os registros dos contêineres:
   ```bash
   docker compose logs aglus-nvr
   docker logs aglus-nvr-container-id
   ```
2. Verifique se o arquivo de configuração está montado:
   ```yaml
   # docker-compose.yml
   volumes:
     - ./aglus-nvr.yaml:/aglus-nvr.yaml:ro
   ```
3. Verifique permissões de arquivo dentro do contêiner:
   ```bash
   docker exec -it aglus-nvr-container ls -la /aglus-nvr.yaml
   ```

### Questões de Permissão de Volume
**Sintoma**: Não é possível gravar gravações em volume montado

**Solução**:
1. Estabeleça propriedade adequada:
   ```bash
   sudo chown -R 1000:1000 ./data  # aglus-nvr runs as UID 1000
   ```
2. Use o usuário adequado em Docker:
   ```yaml
   # docker-compose.yml
   user: "1000:1000"
   volumes:
     - ./data:/var/lib/aglus-nvr
   ```

## Mensagens de Erro e Soluções

### Códigos de Erro Comuns

| Código de Erro | Descrição | Solução |
|------------|-------------|----------|
| `CAMERA_NOT_FOUND` | O ID da câmera não existe | Verifique a grafia do ID da câmera, verifique se a câmera existe na configuração |
| `CAMERA_ALREADY_EXISTS` | ID da câmera já usado | Escolha ID de câmera único |
| `RECORDING_NOT_FOUND` | Arquivo de gravação faltando | Verifique o diretório de armazenamento, verifique se o arquivo existe |
| `STORAGE_FULL` | Espaço em disco esgotado | Limpar gravações, aumentar o espaço em disco, diminuir a retenção |
| `AUTH_REQUIRED` | É necessária autenticação | Adicionar credenciais válidas ao pedido |
| `AUTH_FAILED` | Credenciais inválidas | Verifique nome de usuário/senha, verifique a geração de hash |
| `INVALID_INPUT` | Parâmetros inválidos | Verifique o formato da solicitação da API, valide a configuração |
| `PATH_TRAVERSAL` | Violação de segurança | Corrigir caminhos de arquivos, remover caracteres suspeitos |
| `HLS_MAX_STREAMS` | Muitos fluxos simultâneos | Reduzir o número de visualizadores simultâneos, aumentar `max_streams` |
| `ONVIF_CONNECTION_FAILED` | Não é possível conectar a ONVIF dispositivo | Verifique a rede, verifique ONVIF serviço está funcionando |

### Análise de Logs

#### Modo Depuração
Ative o registro de depuração para solução detalhada de problemas:
```yaml
observability:
  log_level: "debug"
```

#### Localizações dos Registros
**Serviço Systemd**:
```bash
journalctl -u aglus-nvr -f
```

**Docker Container**:
```bash
docker logs -f aglus-nvr-container
```

**Execução binária direta**:
```bash
./aglus-nvr -config aglus-nvr.yaml 2>&1 | tee aglus-nvr.log
```

#### Padrões Comuns de Troncos

**Problemas de Conexão da Câmera**:
```
WARN: camera connection failed: rtsp://...: connection refused
WARN: camera authentication failed for camera_id
ERROR: camera stream error: read timeout
```

**Problemas de armazenamento**:
```
WARN: storage directory not writable: /var/lib/aglus-nvr
ERROR: cannot write recording file: no space left on device
```

**Problemas de configuração**:
```
ERROR: validation failed: camera[].url has invalid format
ERROR: validation failed: cleanup.retention_days must be between 1 and 3650
```

## Otimização de Desempenho

### Para Raspberry Pi 3B
```yaml
# Optimized for RPi 3B constraints
storage:
  segment_duration: "15s"  # Shorter segments = less RAM
hls:
  max_streams: 2          # RPi constraint: max 4, but 2 is safer
  segment_count: 5        # Fewer segments = less I/O
cleanup:
  check_interval: "30m"   # Less frequent checks
  retention_days: 7        # Shorter retention
merge:
  enabled: false          # Disable merging on RPi 3B
```

### Para Sistemas de Alto Desempenho
```yaml
# Optimized for performance
storage:
  segment_duration: "60s"  # Longer segments = fewer files
hls:
  max_streams: 10          # Allow more concurrent streams
  segment_count: 10        # More segments for smoother playback
merge:
  enabled: true
  batch_limit: 500        # Larger batches for efficiency
cleanup:
  check_interval: "15m"    # More frequent cleanup
  retention_days: 90       # Longer retention
```

## Buscando Ajuda

### Antes de relatar problemas
1. Confira este guia de solução de problemas
2. Revise [Referência de Configuração](configuration.md)
3. Pesquise questões de GitHub existentes
4. Verifique os logs para mensagens de erro

### Criando um Relatório de Bug
Ao criar uma questão GitHub, inclua:

1. **Informações do Sistema**:
   ```bash
   uname -a
   lsb_release -a
   ```

2. **AglusNVR Versão**:
   ```bash
   ./aglus-nvr --version
   ```

3. **Configuração** (remover dados sensíveis):
   ```bash
   grep -v password aglus-nvr.yaml
   ```

4. **Registros** (últimas 50 linhas):
   ```bash
   journalctl -u aglus-nvr --since "1 hour ago"
   ```

5. **Passos de Reprodução**:
   - O que você tentou fazer
   - O que aconteceu em vez disso
   - Comportamento esperado

### Apoio à comunidade
- Junte-se à nossa comunidade no Discord para ajuda em tempo real
- Confira a wiki para guias adicionais
- Revise edições encerradas para problemas semelhantes

## Procedimentos de Emergência

### Sistema fica sem resposta
1. Pare o serviço:
   ```bash
   sudo systemctl stop aglus-nvr
   ```
2. Elimine quaisquer processos restantes:
   ```bash
   sudo pkill -f aglus-nvr
   ```
3. Verifique os recursos do sistema:
   ```bash
   free -h
   df -h
   top
   ```
4. Reinicie com configuração reduzida:
   ```bash
   # Use minimal config
   cp aglus-nvr.yaml aglus-nvr.yaml.backup
   # Edit to enable only essential cameras
   sudo systemctl start aglus-nvr
   ```

### Configuração Corrompida
1. Restaure a partir do backup:
   ```bash
   cp aglus-nvr.yaml.backup aglus-nvr.yaml
   ```
2. Ou criar uma configuração mínima:
   ```yaml
   server:
     listen: ":9090"
   storage:
     root_dir: "/var/lib/aglus-nvr"
     segment_duration: "30s"
   auth:
     username: "admin"
     password: "temp-password"
   ```
3. Reiniciar o serviço e reconfigurar

### Corrupção do Banco de Dados
1. Banco de dados de backup:
   ```bash
   cp /var/lib/aglus-nvr/aglus-nvr.db /var/lib/aglus-nvr/aglus-nvr.db.backup
   ```
2. Remover banco de dados corrompido:
   ```bash
   rm /var/lib/aglus-nvr/aglus-nvr.db
   ```
3. Serviço de reinício (banco de dados será recriado):
   ```bash
   sudo systemctl restart aglus-nvr
   ```
4. Reconfigurar todas as câmeras