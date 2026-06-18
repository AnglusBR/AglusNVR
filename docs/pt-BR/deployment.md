# Guia de implantação

Este guia aborda a instalação, configuração e manutenção do AglusNVR em produção.

## Métodos de instalação

### Script de instalação com um clique (recomendado)

O script de instalação baixa o binário da versão mais recente, cria o usuário do sistema `nvr`, inicializa a configuração e instala o serviço systemd – tudo em uma única etapa.

```bash
# Install latest version
curl -fsSL https://raw.githubusercontent.com/mms1688/AglusNVR/main/install.sh | sudo bash
```

Instale uma versão específica:

```bash
sudo ./install.sh --version v0.2.0
```

Desinstalar (preserva as gravações em `/var/lib/aglus-nvr`):

```bash
sudo ./install.sh --uninstall
```

O instalador solicitará uma senha de administrador se não existir nenhum arquivo de configuração. Após a instalação, a UI da Web estará disponível em `http://<host-ip>:9090`.

### Docker

#### Pré-requisitos

- Motor Docker 20.10+ e Docker Compose v2 (ou equivalente Podman)
- Verifique as versões:
  ```bash
  docker --version
  docker compose version
  ```

#### Início rápido

# Opção A: Basta executar – inicialização automática (recomendado)
janela de encaixe execute -d
--nome aglus-nvr \
--restart a menos que seja interrompido \
-p 9090:9090\
-v ./dados:/dados \
ghcr.io/mms1688/aglusnvr:latest

# Opção B: Com senha inicial
janela de encaixe execute -d
--nome aglus-nvr \
--restart a menos que seja interrompido \
-p 9090:9090\
-e NVR_PASSWORD=sua senha \
-v ./dados:/dados \
ghcr.io/mms1688/aglusnvr:latest

# Opção C: com docker-compose.yml
mkdir -p dados
docker compor -d

> **Configuração inicial**: quando iniciado sem um arquivo de configuração, o AglusNVR gera automaticamente uma configuração padrão e é executado no **modo de configuração** — todos os endpoints da API são acessíveis sem autenticação. Defina uma senha por meio da página Configurações da UI da Web ou da variável de ambiente `NVR_PASSWORD`. Depois que uma senha é definida, a autenticação é aplicada.

#### Notas de configuração

- **Inicialização automática**: Se não existir nenhum arquivo de configuração em `/data/aglus-nvr.yaml`, um será gerado automaticamente com padrões razoáveis. Nenhuma configuração manual necessária.
- **Senha inicial**: definida através da variável de ambiente `NVR_PASSWORD`. Se não for definido, o aplicativo será iniciado no modo de configuração (sem autenticação) – defina uma senha por meio da página Configurações da UI da Web.
- **Diretório de dados**: `storage.root_dir` é automaticamente definido como `/data` dentro de contêineres Docker por meio da variável de ambiente `NVR_DATA_DIR`.
#### Referência docker-compose.yml

Configuração completa com campos anotados:

```yaml
services:
  aglus-nvr:
    # Docker image — official pre-built image
    image: ghcr.io/mms1688/aglusnvr:latest

    # Container name (for easier management and log viewing)
    container_name: aglus-nvr

    # Auto-restart policy: always restart unless manually stopped
    restart: unless-stopped

    # Port mapping: host_port:container_port
    ports:
      - "9090:9090"               # Web UI and REST API
      - "2121:2121"               # FTP server
      - "2122-2140:2122-2140"     # FTP passive mode ports

    # Volume mount: map host ./data to container /data
    # Persists config, recordings, and database
    volumes:
      - ./data:/data

    # Environment variables
    environment:
      - NVR_DATA_DIR=/data         # Data directory path
      - TZ=Asia/Shanghai            # Timezone

    # Health check: verifies service status every 30 seconds
    healthcheck:
      test: ["CMD", "aglus-nvr", "health"]  # Health check command
      interval: 30s                           # Check interval
      timeout: 5s                             # Timeout
      start_period: 10s                       # Grace period after start
      retries: 3                              # Retry count
```

#### Imagens pré-construídas versus construção local

**Opção A: usar imagem pré-criada (recomendado)**

- Imagem: `ghcr.io/mms1688/aglusnvr:latest`
- Tags de arquitetura: `latest (multi-arch: amd64 + arm64)`

Não são necessárias etapas extras — o `docker-compose.yml` usa a imagem pré-construída por padrão.

**Opção B: construir localmente**

Se você precisar de versões personalizadas ou quiser o código-fonte mais recente:

```bash
# Multi-stage build (compiles frontend + backend inside container, requires network)
docker build -t aglus-nvr .

# Cross-compile ARM64 (on host, no QEMU needed)
make docker-build-arm64

# Build both architectures
make docker-build-all
```

Após construir localmente, substitua o campo `image:` em `docker-compose.yml` pela sua tag local.

#### Operações comuns Docker

```bash
# View logs (follow mode)
docker compose logs -f aglus-nvr

# View recent logs (last 100 lines)
docker compose logs --tail 100 aglus-nvr

# Restart container
docker compose restart aglus-nvr

# Stop container (preserves data)
docker compose down

# Stop and remove volumes (WARNING: deletes all data!)
docker compose down -v

# Update to latest image
docker compose pull
docker compose up -d

# Container status
docker compose ps

# Resource usage
docker stats aglus-nvr

# Health check status
docker inspect --format='{{.State.Health.Status}}' aglus-nvr
```

> **Observação**: O contêiner usa uma imagem base distroless/scratch, portanto, o acesso ao shell `docker exec` não está disponível. Use `docker compose logs` para depuração.

#### Usando CLI Docker

Se preferir não usar Docker Compose, você pode executar o contêiner diretamente:

```bash
# 1. Login to GHCR (required for private images)
echo YOUR_GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin

# 2. Pull the image
docker pull ghcr.io/mms1688/aglusnvr:latest

# 3. Run the container
docker run -d \
  --name aglus-nvr \
  --restart unless-stopped \
  -p 9090:9090 \
  -p 2121:2121 \
  -p 2122-2140:2122-2140 \
  -v ./data:/data \
  -e NVR_DATA_DIR=/data \
  -e TZ=Asia/Shanghai \
  ghcr.io/mms1688/aglusnvr:latest

# 4. Check status
docker ps
docker logs -f aglus-nvr
docker inspect --format='{{.State.Health.Status}}' aglus-nvr
```

**Execute uma versão específica:**

```bash
docker pull ghcr.io/mms1688/aglusnvr:v0.2.0
docker run -d --name aglus-nvr ... ghcr.io/mms1688/aglusnvr:v0.2.0
```

**Pare e remova:**

```bash
docker stop aglus-nvr
docker rm aglus-nvr
```

**Atualização para o mais recente:**

```bash
docker stop aglus-nvr
docker rm aglus-nvr
docker pull ghcr.io/mms1688/aglusnvr:latest
docker run -d ... ghcr.io/mms1688/aglusnvr:latest
```
#### Backup e restauração de dados

**Backup:**

```bash
# 1. Stop container
docker compose stop

# 2. Backup data directory
tar czf nvr-backup-$(date +%Y%m%d).tar.gz data/

# 3. Restart
docker compose start
```

**Restaurar:**

```bash
# 1. Stop and remove container
docker compose down

# 2. Extract backup
tar xzf nvr-backup-20240101.tar.gz

# 3. Start with restored data
docker compose up -d
```

#### Executando em Raspberry Pi

Raspberry Pi requer a imagem ARM64:

```yaml
# docker-compose.yml — Raspberry Pi configuration
services:
  aglus-nvr:
    image: ghcr.io/mms1688/aglusnvr:latest
    deploy:
      resources:
        limits:
          memory: 512m      # Prevent OOM on RPi 3B
```

Notas importantes:

- A duração do segmento deve permanecer em 30s (`segment_duration: "30s"`)
- Use um disco USB externo (ext4) para armazenamento de gravação
- Limite a gravação simultânea a 2 a 3 câmeras, dependendo da resolução e da taxa de bits

#### Solução de problemas Docker

**Erros de permissão**

O contêiner é executado como não raiz (UID 65534). Corrija problemas de permissão de montagem:

```bash
chown -R 65534:65534 ./data
```

**Conflitos de porta**

Altere a porta esquerda (host) em `docker-compose.yml`:

```yaml
ports:
  - "8090:9090"   # Change host port to 8090
```

**O contêiner continua reiniciando**

Geralmente um erro no arquivo de configuração. Verifique os registros:

```bash
docker compose logs aglus-nvr
```

**FTP não conecta**

Certifique-se de que o intervalo de portas passivas (2122-2140) esteja mapeado e não bloqueado pelo firewall.

**Fuso horário errado**

Adicione a variável de ambiente `TZ` a `docker-compose.yml`:

```yaml
environment:
  - TZ=America/New_York
```

**Docker Compose v1 versus v2**

- Use `docker compose` (com espaço, v2)
- Não `docker-compose` (com hífen, v1, obsoleto)

**A descoberta de dispositivo ONVIF não funciona em Docker**

A descoberta automática ONVIF usa WS-Discovery (multicast UDP para `239.255.255.250:3702`). A rede de ponte padrão do Docker bloqueia o tráfego multicast, portanto a descoberta automática não encontrará dispositivos.

Soluções:

1. **Rede de host** (recomendado para descoberta): remova o comentário de `network_mode: host` em `docker-compose.yml` e remova a seção `ports`. O contêiner compartilha a pilha de rede do host, permitindo o multicast.

2. **Sonda manual** (funciona em qualquer modo de rede): Na página da câmera da UI da Web, use a seção "Sonda manual" para inserir um endereço IP de dispositivo diretamente. Isso ignora o multicast e funciona em qualquer configuração Docker.

3. **Adição manual de câmera**: Adicione câmeras especificando o URL do endpoint ONVIF diretamente (por exemplo, `http://192.168.1.100/onvif/device_service`) no formulário da câmera. A conexão ONVIF, o controle PTZ e o streaming funcionam normalmente no modo bridge – apenas a descoberta automática é afetada.

### Instalação manual

Se você preferir controle total ou se o script de instalação não atender ao seu caso de uso:

```bash
# 1. Download binary from GitHub Releases
#    https://github.com/mms1688/AglusNVR/releases
sudo cp aglus-nvr /usr/local/bin/aglus-nvr
sudo chmod +x /usr/local/bin/aglus-nvr

# 2. Create system user and data directory
sudo useradd -r -s /bin/false -d /var/lib/aglus-nvr nvr
sudo mkdir -p /var/lib/aglus-nvr
sudo chown -R nvr:nvr /var/lib/aglus-nvr

# 3. Initialize config (prompts for admin password)
sudo -u nvr /usr/local/bin/aglus-nvr init \
    --password <your-password> \
    --data-dir /var/lib/aglus-nvr \
    --config /var/lib/aglus-nvr/aglus-nvr.yaml \
    --listen ":9090"

# 4. Install systemd service
sudo cp deploy/aglus-nvr.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now aglus-nvr
```

### Construindo a partir da fonte

```bash
git clone https://github.com/mms1688/AglusNVR.git
cd AglusNVR

# Build for current architecture
make build

# Cross-compile for ARM64 (e.g., Raspberry Pi)
make cross

# Run tests
make test

# Lint
make lint
```

Para implantar um binário compilado diretamente em um Raspberry Pi:

```bash
make deploy RPi_HOST=user@your-rpi-host
make deploy-check RPi_HOST=user@your-rpi-host
make rollback RPi_HOST=user@your-rpi-host
```

## Serviço Systemd

O arquivo de serviço é mantido em [`deploy/aglus-nvr.service`](../../deploy/aglus-nvr.service). Detalhes principais:

- **Binário**: `/usr/local/bin/aglus-nvr`
- **Configuração**: `/var/lib/aglus-nvr/aglus-nvr.yaml`
- **Diretório de trabalho**: `/var/lib/aglus-nvr`
- **Executado como**: usuário `nvr`
- **Segurança**: `NoNewPrivileges`, `PrivateTmp`, `ProtectSystem=strict`, `ProtectHome`
- **Limite de memória**: `MemoryMax=512M` (comentado por padrão; remova o comentário para RPi 3B)

Comandos comuns:

```bash
sudo systemctl start aglus-nvr
sudo systemctl stop aglus-nvr
sudo systemctl restart aglus-nvr
sudo systemctl status aglus-nvr
sudo journalctl -u aglus-nvr -f   # follow logs
```

## Proxy reverso

### Caddie

A Caddy fornece HTTPS automático com configuração mínima:

```caddyfile
nvr.example.com {
    reverse_proxy localhost:9090
}
```

Para TLS com email explícito:

```caddyfile
{
    email admin@example.com
}

nvr.example.com {
    reverse_proxy localhost:9090
}
```

### Nginx

```nginx
server {
    listen 80;
    server_name nvr.example.com;

    location / {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /dav/ {
        proxy_pass http://localhost:9090;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_request_buffering off;
        proxy_buffering off;
    }
}
```

## Notas RPi 3B

O Raspberry Pi 3B possui 905 MB de RAM. Para operação estável:

- **Duração do segmento**: Use 30s (`segment_duration: "30s"`). Durações mais longas retêm mais quadros na RAM (por exemplo, 120s = 60-80MB por segmento).
- **Limite de memória**: remova o comentário de `MemoryMax=512M` em `deploy/aglus-nvr.service` para evitar eliminações de OOM.
- **Armazenamento**: Use um disco USB externo (ext4) para gravações. O cartão SD se desgastará rapidamente com gravações contínuas.
- **Câmeras**: Limite de 2 a 3 fluxos H.264/H.265 simultâneos, dependendo da resolução e da taxa de bits.

## Atualizando

### Usando install.sh (recomendado)

```bash
sudo ./install.sh --version v0.2.0
```

O script interrompe o serviço, substitui o binário e reinicia automaticamente. A configuração e as gravações são preservadas.

### Atualização manual

```bash
sudo systemctl stop aglus-nvr
sudo cp aglus-nvr /usr/local/bin/aglus-nvr
sudo chmod +x /usr/local/bin/aglus-nvr
sudo systemctl start aglus-nvr
```

Sempre faça backup de sua configuração antes de atualizar:

```bash
sudo cp /var/lib/aglus-nvr/aglus-nvr.yaml /var/lib/aglus-nvr/aglus-nvr.yaml.backup
```

## Monitoramento

### Registros

```bash
sudo journalctl -u aglus-nvr -n 100    # last 100 lines
sudo journalctl -u aglus-nvr -f        # follow
sudo journalctl -u aglus-nvr --since "1 hour ago"
```

### Verificação de saúde

```bash
sudo systemctl is-active aglus-nvr
curl -f http://localhost:9090/api/health
```

### Uso de disco

```bash
df -h /var/lib/aglus-nvr
du -sh /var/lib/aglus-nvr/recordings
```

### Métricas Prometheus

As métricas estão disponíveis em `/metrics` (pública, sem necessidade de autenticação):

```bash
curl http://localhost:9090/metrics
```

## Solução de problemas

### O serviço não inicia

```bash
sudo journalctl -u aglus-nvr -n 50
# Verify config syntax
sudo -u nvr /usr/local/bin/aglus-nvr -config /var/lib/aglus-nvr/aglus-nvr.yaml
```

### Falhas na conexão da câmera

```bash
# Test RTSP connection
ffmpeg -rtsp_transport tcp -i "rtsp://admin:pass@192.168.1.100:554/stream" -t 5 -f null -

# Check network
ping 192.168.1.100
```

### Conflitos portuários

```bash
sudo lsof -i :9090
sudo lsof -i :2121
```

### Erros de permissão

```bash
ls -la /var/lib/aglus-nvr/
sudo -u nvr ls /var/lib/aglus-nvr/
```

### Alto uso de memória

Reduza `segment_duration` para 30s. No RPi 3B, remova o comentário `MemoryMax=512M` no arquivo de serviço.
