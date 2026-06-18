# Começando com AglusNVR

## O que é AglusNVR

AglusNVR é um gravador de vídeo de rede leve escrito em Go. Ele grava os feeds de vídeo de câmeras IP para MP4 segmentos em disco e oferece uma interface web para visualização de gravações, gerenciamento de câmeras e acesso a imagens gravadas.

**Principais Características:**

- Grava câmeras RTSP (H.264, H.265, MJPEG), HTTP JPEG, ONVIF, Xiaomi (CS2 P2P) e Timelapse para segmentos MP4
- Interface web com tema escuro/claro, visualização ao vivo multi-protocolo (HLS, WebRTC, HTTP-FLV, WebSocket) e estatísticas Chart.js
- WebDAV (somente leitura/leitura-gravação configurável) e acesso FTP às gravações
- MQTT integração para gravação orientada a eventos
- Fusão de segmentos para reduzir a contagem de arquivos
- Binário estático único com interface web embutida — sem dependências

## Início Rápido (5 minutos)

### Opção 1: Binário pré-montado (recomendado)

Baixe o binário mais recente para sua arquitetura em [GitHub Releases](https://github.com/mms1688/AglusNVR/releases):

```bash
# AMD64 (maioria dos PCs e servidores)
wget https://github.com/mms1688/AglusNVR/releases/latest/download/aglus-nvr-amd64
chmod +x aglus-nvr-amd64

# ARM64 (Raspberry Pi, etc.)
wget https://github.com/mms1688/AglusNVR/releases/latest/download/aglus-nvr-arm64
chmod +x aglus-nvr-arm64
```

Inicialize a configuração e comece:

```bash
./aglus-nvr-amd64 init --password sua-senha
./aglus-nvr-amd64 -config aglus-nvr.yaml
```

Abra http://localhost:9090 no seu navegador.

### Opção 2: Docker

```bash
docker compose up -d
```

Abra http://localhost:9090 no seu navegador.

> **Nota**: Não precisa de preparação de configuração! AglusNVR inicializa automaticamente quando iniciado sem um arquivo de configuração.

#### Mudança do local de armazenamento

Por padrão, as gravações são armazenadas em `./data` no host (mapeadas para `/data` dentro do container).
Para armazenar gravações em um disco externo ou em um diretório diferente, edite `docker-compose.yml`:

```yaml
    volumes:
      - /mnt/external/nvr:/data    # ← altere para o caminho desejado no host
    environment:
      - NVR_DATA_DIR=/data          # deve corresponder ao lado direito do volume
      # - NVR_UID=1000               # match the UID that owns the host directory
      # - NVR_GID=1000               # match the GID that owns the host directory
```

> **Importante**: O lado direito da montagem de volume (`:data`) e `NVR_DATA_DIR` devem sempre coincidir.
> Se o container falhar ao iniciar ou continuar reiniciando, verifique se o diretório host existe e está
> gravável pelo UID/GID configurado (padrão: 1000:1000).

### Opção 3: Script de Instalação com um clique

```bash
curl -fsSL https://raw.githubusercontent.com/mms1688/AglusNVR/main/install.sh | sudo bash
```

Isso baixa o binário, cria um usuário do sistema (`nvr`), gera a configuração com senha, instala um serviço systemd e o inicia automaticamente. Diretório de dados: `/var/lib/aglus-nvr`.

Para desinstalar (preservar gravações):

```bash
curl -fsSL https://raw.githubusercontent.com/mms1688/AglusNVR/main/install.sh | sudo bash -s -- --uninstall
```

### Opção 4: Construir a partir da Fonte

Requer Go 1.26+ e Node.js (para frontend):

```bash
git clone https://github.com/mms1688/AglusNVR.git
cd AglusNVR
make build
./aglus-nvr init --password sua-senha
./aglus-nvr -config aglus-nvr.yaml
```

Para compilação cruzada para ARM64 (por exemplo, Raspberry Pi):

```bash
make cross
```

## Primeira Configuração

### Usando `aglus-nvr init`

O subcomando `init` cria um arquivo de configuração com padrões seguros:

```bash
./aglus-nvr init --password sua-senha
```

Opções:

| Bandeira | Padrão | Descrição |
|------|---------|-------------|
| `--password` | (com incentivo) | Senha de administrador para Web UI |
| `--username` | `admin` | Nome de usuário do administrador |
| `--data-dir` | `/var/lib/aglus-nvr` | Diretório de dados para gravações e bases de dados |
| `--listen` | `:9090` | HTTP endereço de ouvir |
| `--config` | `aglus-nvr.yaml` | Caminho do arquivo de configuração |
| `--force` | falso | Sobrescrever a configuração existente |

### Configuração de senhas

Existem três maneiras de definir a senha de administrador:

1. **`aglus-nvr init --password <pw>`** — define a senha hash durante a configuração (recomendado)
2. **Texto simples na configuração** — definido `auth.password` em YAML; Auto-hash para `password_hash` na primeira partida
3. **Hash manual** — gerar com `aglus-nvr hash-password <pw>` e colar no `auth.password_hash`

### Caminhos Padrão

| Caminho | Descrição |
|------|-------------|
| `/var/lib/aglus-nvr/` | Diretório de dados (gravações, banco de dados) |
| `/var/lib/aglus-nvr/aglus-nvr.db` | SQLite banco de dados |
| `aglus-nvr.yaml` | Arquivo de configuração |

## Adicionando sua primeira câmera

AglusNVR usa um formato **separado de transporte + codificação** para protocolos de câmera:

- **Transporte**: `rtsp`, `http`, `onvif`, `xiaomi`, `timelapse`
- **Codificação**: `h264`, `h265`, `mjpeg`, `jpeg`

> O formato combinado antigo (`rtsp_h264`, `rtsp_h265`, `rtsp_mjpeg`, `http_jpeg`) ainda funciona para retrocompatibilidade.

### RTSP H.264 Câmera

```yaml
cameras:
  - id: "front-door"
    name: "Front Door"
    protocol: "rtsp"
    encoding: "h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
```

### RTSP H.265 Câmera

```yaml
cameras:
  - id: "driveway"
    name: "Driveway"
    protocol: "rtsp"
    encoding: "h265"
    url: "rtsp://192.168.1.103:554/stream"
    enabled: true
```

### HTTP JPEG Câmera

```yaml
cameras:
  - id: "garage"
    name: "Garage"
    protocol: "http"
    encoding: "jpeg"
    url: "http://192.168.1.102:8080/snapshot"
    enabled: true
```

### ONVIF Câmera

```yaml
cameras:
  - id: "lobby"
    name: "Lobby"
    protocol: "onvif"
    url: "http://192.168.1.104:80/onvif/device_service"
    username: "admin"
    password: "camera123"
    enabled: true
```

> ONVIF detecta automaticamente a codificação. O campo `encoding` pode ser omitido.

### Câmera Timelapse

```yaml
cameras:
  - id: "construction"
    name: "Construction Site"
    protocol: "timelapse"
    enabled: true
```

> Câmeras de timelapse capturam instantâneos periódicos sem um fluxo contínuo de vídeo.

### Usando o Antigo Formato Combinado

Todos esses ainda funcionam:

```yaml
cameras:
  - id: "cam1"
    name: "Legacy Cam"
    protocol: "rtsp_h264"
    url: "rtsp://192.168.1.100:554/stream"
    enabled: true
```

Após editar a configuração, reinicie AglusNVR ou use a interface web para adicionar câmeras em tempo de execução.

## Acessando AglusNVR

### Web UI

Abra http://your-server:9090 e faça login com suas credenciais configuradas. A partir da interface web você pode:

- Assista transmissões ao vivo das câmeras (HLS, WebRTC, HTTP-FLV, WebSocket)
- Reproduza e baixe as gravações
- Adicionar, editar e remover câmeras
- Veja estatísticas e tendências de armazenamento
- Configurar configurações

### WebDAV

WebDAV está disponível no `/dav/` (ativado por padrão, somente leitura por padrão):

```bash
curl -u admin:password http://your-server:9090/dav/
```

Monte em um gerenciador de arquivos: `davs://your-server:9090/dav/`

Para habilitar o acesso de leitura-escrita, defina `webdav.read_write: true` na configuração.

### FTP

FTP está disponível na porta 2121 (ativada por padrão):

```bash
ftp your-server 2121
# Username: admin
# Password: (your password)
```

## Questões Comuns

### O serviço não começa

- Verifique a sintaxe do arquivo de configuração: `cat aglus-nvr.yaml`
- Verifique se o diretório de dados existe e é gravável: `ls -la /var/lib/aglus-nvr/`
- Verifique os registros: `journalctl -u aglus-nvr -f`

### Erros de permissão

- O script `install.sh` cria um usuário `nvr` do sistema. Certifique-se de que o diretório de dados seja propriedade dele:
`sudo chown -R nvr:nvr /var/lib/aglus-nvr/`

### Conflitos portuários

- A porta padrão é 9090. Se estiver em uso, mude `server.listen` na configuração (por exemplo, `":8080"`)

### Não consigo conectar à câmera

- Verifique se a URL da câmera funciona com VLC ou ffplay: `ffplay rtsp://192.168.1.100:554/stream`
- Verifique conectividade de rede: `ping 192.168.1.100`
- Garanta que as credenciais da câmera estejam corretas
- Verifique se a câmera precisa de uma URL específica de substream para H.265

### Alto uso de memória em Raspberry Pi

- Reduza `segment_duration` para `30s` (padrão). Durações mais longas armazenam mais dados na RAM.
- O RPi 3B tem ~900MB de RAM. Com 4 câmeras em segmentos de 30 segundos, espere um uso estável de ~300MB.
