# WebDAV Integração

AglusNVR inclui um servidor WebDAV embutido que oferece acesso a gravações e snapshots de câmeras por meio do protocolo padrão WebDAV. Suporta modos somente leitura e leitura-escrita, facilitando a integração com sistemas de terceiros.

## Visão geral

- **Protocolo**: WebDAV (Autoria e Versão Distribuída Baseada na Web)
- **Método de Acesso**: cliente WebDAV padrão
- **Prefixo de Caminho**: `/dav` (configurável)
- **Modo**: Somente leitura ou leitura-gravação
- **Autenticação**: Autenticação HTTP básica
- **Compatibilidade**: Suporta clientes WebDAV padrão

## Configuração

### Configurações Básicas

```yaml
webdav:
  enabled: true
  path_prefix: "/dav"
  read_write: false
  username: "dav_user"
  password: "dav_password"
```

### Opções de configuração

| Campo | Obrigatório | Tipo | Padrão | Descrição |
|------|----------|------|--------|----------|
| `enabled` | Sim | Booleano | falso | Ativar WebDAV servidor |
| `path_prefix` | Não | string | "/dav" | WebDAV Prefixo URL |
| `read_write` | Não | Booleano | falso | Permitir operações de escrita |
| `username` | Não | string | - | WebDAV nome de usuário (se autenticação ativada) |
| `password` | Não | string | - | WebDAV senha (se autenticação ativada) |

### Exemplo completo de configuração

```yaml
webdav:
  enabled: true
  path_prefix: "/video"
  read_write: false
  username: "admin"
  password: "secure_password"
```

## Uso

### Acessando Recursos WebDAV

O servidor WebDAV pode ser acessado em `http://localhost:9090/dav`, com a seguinte estrutura de arquivos:

```
/dav/
├── recordings/
│   ├── h264/
│   │   ├── camera_1/
│   │   │   ├── 1704123456789012345.mp4
│   │   │   └── 1704123456789012346.mp4
│   │   └── camera_2/
│   │       ├── 1704123456789012347.mp4
│   │       └── 1704123456789012348.mp4
│   └── h265/
│       └── camera_1/
│           └── 1704123456789012349.mp4
└── snapshots/
    ├── camera_1/
    │   ├── 1704123456789012350.jpg
    │   └── 1704123456789012351.jpg
    └── camera_2/
        ├── 1704123456789012352.jpg
        └── 1704123456789012353.jpg
```

### WebDAV Operações

#### Modo Somente Leitura

**Acesso Básico**:
```bash
# List root directory
curl -u admin:password http://localhost:9090/dav/

# List recordings directory
curl -u admin:password http://localhost:9090/dav/recordings/h264/

# Download recording file
curl -u admin:password -O http://localhost:9090/dav/recordings/h264/camera_1/1704123456789012345.mp4

# Download snapshot
curl -u admin:password -O http://localhost:9090/dav/snapshots/camera_1/1704123456789012350.jpg
```

**Navegador de Arquivos**:
- Windows: Abra o Explorador de Arquivos, insira `http://localhost:9090/dav`
- macOS: Conecte-se ao servidor, endereço `http://localhost:9090/dav`
- Linux: Gerenciador de Arquivos → conectar ao servidor → endereço `http://localhost:9090/dav`

#### Modo de leitura-escrita

Após ativar o modo de leitura e gravação, você pode enviar arquivos e criar diretórios:

```yaml
webdav:
  enabled: true
  path_prefix: "/dav"
  read_write: true
  username: "upload_user"
  password: "upload_password"
```

**Enviar Arquivos**:
```bash
# Create directory
mkdir -p /tmp/test_upload
echo "test content" > /tmp/test_upload/test.txt

# Upload file
curl -u upload_user:upload_password -T /tmp/test_upload/test.txt \
  http://localhost:9090/dav/recordings/h264/uploaded_files/

# Upload directory
curl -u upload_user:upload_password -T /tmp/test_upload/ \
  http://localhost:9090/dav/recordings/h264/uploaded_directory/
```

## Integração com Clientes

### Janelas

1. Explorador de Arquivos Aberto
2. Digite `http://localhost:9090/dav` na barra de endereços
3. Digite nome de usuário e senha
4. Acessar gravações e arquivos snapshot

### macOS

1. Localizador Aberto
2. Go → Conectar ao servidor
3. Insira o endereço `http://localhost:9090/dav`
4. Digite nome de usuário e senha

### Linux

1. Gerenciador de arquivos aberto (Nautilus, Dolphin, Thunar, etc.)
2. Selecione "Conectar ao servidor"
3. Insira o endereço `http://localhost:9090/dav`
4. Digite nome de usuário e senha

### Aplicações de terceiros

#### VLC Media Player

```bash
# Direct playback of recordings
vlc http://localhost:9090/dav/recordings/h264/camera_1/1704123456789012345.mp4

# Access snapshot library
vlc http://localhost:9090/dav/snapshots/camera_1/
```

#### PotPlayer

```
# Play recording
http://localhost:9090/dav/recordings/h264/camera_1/1704123456789012345.mp4

# Browse snapshots
http://localhost:9090/dav/snapshots/camera_1/
```

#### Adobe Premiere Pro

1. Arquivo → Aberto
2. Insira URL: `http://localhost:9090/dav/recordings/h264/`
3. Selecione arquivos de gravação para importar

## Integração de Armazenamento em Nuvem

### Backup de Unidade na Nuvem

Use o rclone para sincronizar WebDAV recursos com armazenamento em nuvem:

```bash
# Configure rclone remote
rclone config

# Set up remote named backup
# Choose WebDAV
# Address: http://localhost:9090/dav
# Username: admin
# Password: password
# Rename to backup

# Perform sync
rclone sync /mnt/disk/nvr backup:video/recordings/

# Regular backup script
#!/bin/bash
rclone sync /var/lib/aglus-nvr/recordings/ backup:recordings/
rclone sync /var/lib/aglus-nvr/snapshots/ backup:snapshots/
```

### Ferramentas de Backup do Windows

Use o Robocopy para backup:

```batch
@echo off
set SOURCE=D:\aglus-nvr\recordings\
set DEST=\\192.168.1.100\dav\recordings\
set USER=admin
set PASS=password

net use %DEST% %PASS% /user:%USER%
robocopy %SOURCE% %DEST% /E /R:2 /W:5
net use %DEST% /delete
```

## Configuração de Segurança

### HTTPS Suporte

Recomenda-se ativar HTTPS por meio de um reverse proxy:

```nginx
# Nginx configuration example
server {
    listen 443 ssl;
    server_name nvr.example.com;
    
    ssl_certificate /path/to/cert.pem;
    ssl_certificate_key /path/to/key.pem;
    
    location /dav/ {
        proxy_pass http://localhost:9090/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        auth_basic "WebDAV Access";
        auth_basic_user_file /path/to/.htpasswd;
    }
}
```

### Autenticação do Usuário

Use o htpasswd para gerar senhas de usuário:

```bash
# Install htpasswd (Ubuntu/Debian)
sudo apt-get install apache2-utils

# Create user
htpasswd -c /etc/nginx/.htpasswd dav_user

# Add more users
htpasswd /etc/nginx/.htpasswd upload_user
```

### Restrições de Rede

Use firewall para restringir o acesso:

```bash
# Allow specific IP to access WebDAV
iptables -A INPUT -p tcp --dport 9090 -s 192.168.1.0/24 -j ACCEPT
iptables -A INPUT -p tcp --dport 9090 -j DROP

# Or use UFW
ufw allow from 192.168.1.0/24 to any port 9090
ufw deny to any port 9090
```

## Solução de problemas

### Questões Comuns

**Conexão recusada**
```
curl: (7) Failed to connect to localhost port 9090: Connection refused
```
**Solução**: Garantir que WebDAV esteja ativado e em funcionamento

**Autenticação Falhada**
```
HTTP/1.1 401 Unauthorized
```
**Solução**: Verifique se nome de usuário e senha estão corretos

**Erro de permissão**
```
HTTP/1.1 403 Forbidden
```
**Solução**: Verifique as configurações do modo leitura-escrita, confirme permissões de diretório

**Erro de Tempo**
```
curl: (28) Operation timed out after 30001 milliseconds
```
**Solução**: Problema de rede, verifique a conexão ou aumente o tempo de espera

### Métodos de Depuração

**Ativar Logs de Depuração**
```yaml
observability:
  log_level: "debug"
```

**Teste WebDAV Conexão**
```bash
# Test basic connection
curl -v http://localhost:9090/dav/

# Test authentication
curl -v -u admin:password http://localhost:9090/dav/

# Test file upload (read-write mode only)
curl -v -u admin:password -T /etc/hosts http://localhost:9090/dav/test.txt
```

**Verifique os registros do sistema**
```bash
# View detailed logs
journalctl -u aglus-nvr -f | grep webdav

# Docker container
docker logs -f aglus-nvr | grep webdav
```

### Otimização de Desempenho

#### Upload de Arquivos Grandes

```yaml
# Adjust server configuration
server:
  max_upload_size: "1GB"
  read_timeout: "300s"
  write_timeout: "300s"
```

#### Otimização de Rede

```bash
# Adjust TCP settings (for large file transfers)
sysctl -w net.core.rmem_max=134217728
sysctl -w net.core.wmem_max=134217728
sysctl -w net.ipv4.tcp_rmem="4096 87380 134217728"
sysctl -w net.ipv4.tcp_wmem="4096 65536 134217728"
```

## Exemplos de Integração

### Apple Time Machine

Implemente backup do Time Machine via WebDAV:

```bash
# Create backup task
defaults write com.apple.TimeMachine DoNotOfferNewDisks false
defaults write com.apple.TimeMachine CustomBackupDisk "http://localhost:9090/dav/time_machine"

# Or use manual setup
# Open Time Machine → Select Disk → Enter WebDAV address
```

### rsync Backup

```bash
# Use rsync to backup to WebDAV
rsync -avz /var/lib/aglus-nvr/recordings/ \
  admin@localhost:/var/lib/aglus-nvr/recordings/backup/

# Exclude specific files
rsync -avz --exclude='*.tmp' /var/lib/aglus-nvr/recordings/ \
  admin@localhost:/var/lib/aglus-nvr/recordings/backup/
```

### Script de Automação em Python

```python
#!/usr/bin/env python3
import requests
import os
from datetime import datetime, timedelta

def download_snapshots(camera_id, output_dir):
    """Download snapshots for a specific camera"""
    base_url = "http://localhost:9090/dav/snapshots"
    auth = ("admin", "password")
    
    url = f"{base_url}/{camera_id}/"
    response = requests.get(url, auth=auth)
    
    if response.status_code == 200:
        # Create output directory
        os.makedirs(output_dir, exist_ok=True)
        
        # Here we need to parse WebDAV list response
        # Actual implementation needs to handle WebDAV XML response
        print(f"Downloading snapshots for camera {camera_id} to {output_dir}")

def list_recordings(camera_id=None, encoding=None):
    """List recording files"""
    base_url = "http://localhost:9090/dav/recordings"
    auth = ("admin", "password")
    
    if camera_id and encoding:
        url = f"{base_url}/{encoding}/{camera_id}/"
    elif encoding:
        url = f"{base_url}/{encoding}/"
    else:
        url = f"{base_url}/"
    
    response = requests.get(url, auth=auth)
    
    if response.status_code == 200:
        print("Available files:")
        print(response.text)

if __name__ == "__main__":
    # Example usage
    list_recordings(camera_id="camera_1", encoding="h264")
    download_snapshots("camera_1", "/tmp/snapshots")
```

### Node.js Roteiro

```javascript
const fs = require('fs');
const axios = require('axios');

class WebDAVClient {
  constructor(baseUrl, username, password) {
    this.baseUrl = baseUrl;
    this.auth = {
      username: username,
      password: password
    };
  }

  async listDirectory(path) {
    const url = `${this.baseUrl}${path}`;
    const response = await axios.get(url, {
      auth: this.auth,
      headers: {
        Depth: 1
      }
    });
    return response.data;
  }

  async downloadFile(remotePath, localPath) {
    const url = `${this.baseUrl}${remotePath}`;
    const response = await axios.get(url, {
      auth: this.auth,
      responseType: 'stream'
    });
    
    const writer = fs.createWriteStream(localPath);
    response.data.pipe(writer);
    
    return new Promise((resolve, reject) => {
      writer.on('finish', resolve);
      writer.on('error', reject);
    });
  }

  async uploadFile(localPath, remotePath) {
    const url = `${this.baseUrl}${remotePath}`;
    const fileData = fs.readFileSync(localPath);
    
    await axios.put(url, fileData, {
      auth: this.auth,
      headers: {
        'Content-Type': 'application/octet-stream'
      }
    });
  }
}

// Usage example
const client = new WebDAVClient('http://localhost:9090/dav', 'admin', 'password');

// List directory
client.listDirectory('/recordings/h264/').then(console.log);

// Download file
client.downloadFile('/recordings/h264/camera_1/latest.mp4', '/tmp/latest.mp4');

// Upload file
client.uploadFile('/tmp/upload.mp4', '/recordings/h264/uploaded/video.mp4');
```

## Melhores Práticas

1. **Limpeza regular**: Estabeleça políticas de limpeza automática para evitar o esgotamento do espaço de armazenamento
2. **Estratégia de backup**: Backup regular de gravações importantes para outros locais
3. **Controle de acesso**: Defina permissões de acesso apropriadas para diferentes usuários
4. **Monitoramento**: Monitorar o uso e o desempenho do WebDAV servidor
5. **Registros**: Habilitar logs detalhados para solução de problemas
6. **Segurança de rede**: Use senhas HTTPS e fortes para proteger a segurança dos dados

### Exemplo de Script de Monitoramento

```bash
#!/bin/bash
# Monitor WebDAV usage

WEBDAV_URL="http://localhost:9090/dav"
USERNAME="admin"
PASSWORD="password"

# Get disk usage
DISK_USAGE=$(curl -s -u $USERNAME:$PASSWORD $WEBDAV_URL/ | grep -o '[0-9]*%' | head -1)

# Get file count
FILE_COUNT=$(curl -s -u $USERNAME:$PASSWORD $WEBDAV_URL/recordings/ | grep -o '<[^>]*>' | wc -l)

echo "Disk usage: $DISK_USAGE"
echo "File count: $FILE_COUNT"

# Send warning if usage exceeds 90%
if [[ ${DISK_USAGE%?} -gt 90 ]]; then
    echo "Warning: Disk usage exceeds 90%"
    # Could send email or notification
fi
```

Por meio da integração WebDAV, AglusNVR pode facilmente se integrar a diversos sistemas de terceiros para alcançar backup automático, acesso remoto e recursos de gerenciamento de arquivos.