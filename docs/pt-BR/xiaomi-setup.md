# Xiaomi Integração com Câmeras

AglusNVR oferece suporte abrangente para câmeras em nuvem Xiaomi por meio do protocolo CS2 P2P. Essa integração permite conectar Xiaomi câmeras ao seu sistema NVR sem precisar de acesso direto à rede às próprias câmeras, já que toda a comunicação é feita pelos serviços em nuvem da Xiaomi.

## Visão geral

- **Protocolo**: CS2 P2P (protocolo proprietário de nuvem da Xiaomi)
- **Autenticação**: Xiaomi serviços em nuvem com autenticação baseada em token
- **Modelos suportados**: câmeras baseadas em CS2 (veja tabela abaixo)
- **Recursos**: Transmissão ao vivo, gravação, snapshots, controle PTZ
- **Rede**: Requer conectividade para Xiaomi serviços em nuvem

## Pré-requisitos

- Xiaomi conta com câmeras registradas
- Câmeras vinculadas à sua conta Xiaomi no app Mi Home
- Acesso à rede para Xiaomi serviços em nuvem (`openapi.io.mi.com`)
- Conexão de internet funcionando para NVR sistema

## Modelos de Câmeras Suportados

| Modelo | Identificador | Protocolo | Nível de Suporte | Notas |
|-------|------------|----------|---------------|-------|
| **Xiaomi C200** | `chuangmi.camera.046c04` | CS2 P2P | ✅ Completo | Câmera HD 1080p para ambientes internos |
| **Xiaomi C300** | `chuangmi.camera.72ac1` | CS2 P2P | ✅ Completo | Câmera interna 2K |
| **Xiaofang** | `isa.camera.isc5c1` | CS2 P2P | ✅ Completo | Câmera cúpula panorâmica/inclinação |
| **Loock V2** | `loock.cateye.v02` | CS2 P2P | ✅ Completo | Câmera inteligente da campainha |
| **Dafang** | `isa.camera.df3` | TUTK | ❌ Não Suportado | Usa protocolo diferente |
| **Mijia** | `chuangmi.camera.8ac63a` | CS2 P2P | ✅ Completo | Câmera básica de ambiente interno |

**Importante**: Apenas câmeras do protocolo CS2 são suportadas. As câmeras Dafang usam o protocolo TUTK, que não é implementado.

## Configuração

### Configuração Básica

```yaml
xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  region: "cn"
  auto_discovery: true

cameras:
  - id: "xiaomi_c200_front"
    name: "Xiaomi C200 - Front"
    protocol: "xiaomi"
    encoding: "h264"
    did: "device_id_here"
    vendor: "cs2"
    enabled: true
    # Optional settings
    sub_stream_url: "rtsp://xiaomi-c200-cs2.stream"
    hls_max_fps: 15
    sample_interval: 2
```

### Opções de configuração

| Campo | Obrigatório | Tipo | Padrão | Descrição |
|-------|----------|------|---------|-------------|
| `enabled` | Sim | Booleano | falso | Habilitar Xiaomi integração |
| `user_id` | Sim | string | - | ID de usuário Xiaomi |
| `token` | Sim | string | - | Xiaomi passToken |
| `region` | Não | string | "cn" | Código de região (cn, sg, de, etc.) |
| `auto_discovery` | Não | Booleano | Verdade | Habilitar a descoberta automática de dispositivos |

### Opções de configuração da câmera

| Campo | Obrigatório | Tipo | Padrão | Descrição |
|-------|----------|------|---------|-------------|
| `id` | Sim | string | - | Identificador único da câmera |
| `name` | Sim | string | - | Nome de exibição da câmera |
| `protocol` | Sim | string | "Xiaomi" | Deve ser "xiaomi" |
| `encoding` | Sim | string | "h264" | Codificação de vídeo (h264, h265) |
| `did` | Sim | string | - | ID do dispositivo Xiaomi |
| `vendor` | Sim | string | "CS2" | Deve ser "cs2" |
| `enabled` | Não | Booleano | Verdade | Ativar gravação com câmera |

### Configuração Avançada

```yaml
xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  region: "cn"
  auto_discovery: true
  connection_timeout: "30s"
  read_timeout: "60s"
  retry_attempts: 3
  retry_delay: "10s"
  
  # Performance settings
  max_concurrent_cameras: 10
  segment_buffer_size: "10MB"
  
  # Security settings
  encrypt_credentials: true
  credential_rotation_days: 90

cameras:
  - id: "xiaomi_c300_living_room"
    name: "Living Room Camera"
    protocol: "xiaomi"
    encoding: "h264"
    did: "device_id_12345"
    vendor: "cs2"
    enabled: true
    # Optimized settings for 2K cameras
    hls_max_fps: 20
    sample_interval: 1
    segment_duration: "30s"
    
    # Auto backup settings
    snapshot_interval: "5m"
    snapshot_quality: "high"
    
    # Alert settings
    motion_detection: true
    push_notifications: false
```

## Métodos de Configuração

### Método 1: Configuração da interface web (recomendado)

1. **Acesse a Interface Web**: Interface Web AglusNVR Aberta no `http://localhost:9090`

2. **Navegar para Câmeras**: Go para a página Câmeras

3. **Xiaomi Descoberta**: Expanda a seção "Descoberta de Dispositivos Xiaomi"

4. **Autenticar**: Insira suas credenciais de Xiaomi conta e clique em "Login"

5. **Selecione Dispositivos**: Navegue pelos dispositivos descobertos e selecione as câmeras que deseja adicionar

6. **Adicionar à NVR**: Clique em "Adicionar à NVR" para cada câmera selecionada

7. **Configurar**: Personalize as configurações de cada câmera (retenção, qualidade, etc.)

8. **Salvar**: Clique em "Salvar Configuração" para aplicar alterações

### Método 2: Autenticação de API

Use a API para obter credenciais de autenticação de forma programática:

```bash
# Authenticate with Xiaomi cloud
curl -X POST http://localhost:9090/api/xiaomi/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "your-email@example.com", "password": "your-password"}'

# Response example:
{
  "success": true,
  "user_id": "123456789",
  "pass_token": "your_passToken_here",
  "devices": [
    {
      "did": "device_id_12345",
      "name": "Xiaomi C200",
      "model": "chuangmi.camera.046c04",
      "online": true
    }
  ]
}
```

### Método 3: Configuração Manual

Edite o arquivo de configuração diretamente:

```yaml
xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  region: "cn"

cameras:
  - id: "xiaomi_c200_front"
    name: "Xiaomi C200 - Front"
    protocol: "xiaomi"
    encoding: "h264"
    did: "device_id_12345"
    vendor: "cs2"
    enabled: true
```

## API Endpoints

### Xiaomi Autenticação

**POST** `/api/xiaomi/auth`
- **Corpo**: `{username: string, password: string}`
- **Resposta**: Informações do usuário e lista de dispositivos
- **Descrição**: Autenticar-se com Xiaomi nuvem e obter credenciais

```bash
curl -X POST http://localhost:9090/api/xiaomi/auth \
  -H "Content-Type: application/json" \
  -d '{"username": "user@example.com", "password": "password"}'
```

### Gerenciamento de Dispositivos

**VAI** `/api/xiaomi/devices`
- **Resposta**: Lista de todos os dispositivos Xiaomi
- **Descrição**: Obtenha todos os dispositivos Xiaomi associados à conta

```bash
curl -u admin:password http://localhost:9090/api/xiaomi/devices
```

**POST** `/api/xiaomi/sync`
- **Resposta**: Status de sincronização
- **Descrição**: Forçar a sincronização de dispositivos Xiaomi nuvem

```bash
curl -X POST -u admin:password http://localhost:9090/api/xiaomi/sync
```

### Controle de Câmera

**VAI** `/api/xiaomi/cameras/{camera_id}/status`
- **Resposta**: Informações sobre o status da câmera
- **Descrição**: Veja o status atual da câmera

```bash
curl -u admin:password http://localhost:9090/api/xiaomi/cameras/xiaomi_c200_front/status
```

**POST** `/api/xiaomi/cameras/{camera_id}/ptz`
- **Corpo**: `{action: string, speed: number}`
- **Resposta**: Resultado do controle PTZ
- **Descrição**: Controle das funções de pan/inclinação/zoom (para modelos suportados)

```bash
curl -X POST -u admin:password \
  -H "Content-Type: application/json" \
  -d '{"action": "up", "speed": 1}' \
  http://localhost:9090/api/xiaomi/cameras/xiaofang_living_room/ptz
```

### Gerenciamento de Snapshots

**VAI** `/api/xiaomi/cameras/{camera_id}/snapshot`
- **Resposta**: JPEG dados da imagem
- **Descrição**: Tire uma foto com a câmera

```bash
curl -u admin:password -o snapshot.jpg \
  http://localhost:9090/api/xiaomi/cameras/xiaomi_c200_front/snapshot
```

## Exemplos de Integração

### Integração com o Home Assistant

```yaml
# Home Assistant configuration
homeassistant:
  # Xiaomi camera integration
  xiaomi:
    username: !secret xiaomi_username
    password: !secret xiaomi_password
    region: cn

# Camera entity in Home Assistant
camera:
  - platform: mjpeg
    name: "Xiaomi C200 Front"
    mjpeg_url: !secret xiaomi_c200_stream
    authentication: !secret xiaomi_auth

# Automation for motion detection
- id: "xiaomi_motion_alert"
  alias: "Xiaomi Camera Motion Detected"
  trigger:
    - platform: mqtt
      topic: "xiaomi/motion/camera_200/front"
      payload: "ON"
  action:
    - service: notify.mobile_app_iphone
      data:
        title: "Motion Detected"
        message: "Motion detected at front door"
```

### Integração Node-RED

```json
// Node-RED Flow - Xiaomi Camera Motion Detection
[
  {"id": "1", "type": "inject", "z": "flow", "name": "Test Motion", "payload":"ON", "payloadType":"str", "repeat": "", "crontab": "", "once": false, "onceDelay": 0.1, "topic": "", "x": 120, "y": 140},
  {"id": "2", "type": "switch", "z": "flow", "name": "Motion Detected", "property": "payload", "propertyType":"msg", "rules":[{"t":"eq","v":"ON"}],"checkall":"true,"outputs":1,"x": 320, "y": 140},
  {"id": "3", "type": "function", "name": "Build Message", "func": "msg.topic = \"xiaomi/motion/camera_200/front\";\nmsg.payload = {\"action\": \"record\", \"duration\": 60};\nreturn msg;", "outputs": 1, "x": 500, "y": 140},
  {"id": "4", "type": "mqtt out", "z": "flow", "name": "Trigger Recording", "topic": "xiaomi/trigger/+", "qos": "0", "retain": "false", "x": 680, "y": 140}
]
```

### Script de Automação em Python

```python
#!/usr/bin/env python3
import requests
import json
import time
from datetime import datetime

class XiaomiCameraClient:
    def __init__(self, base_url, username, password):
        self.base_url = base_url
        self.auth = (username, password)
        self.session = requests.Session()
    
    def authenticate(self, xiaomi_username, xiaomi_password):
        """Authenticate with Xiaomi cloud"""
        url = f"{self.base_url}/api/xiaomi/auth"
        data = {
            "username": xiaomi_username,
            "password": xiaomi_password
        }
        
        response = self.session.post(url, json=data)
        response.raise_for_status()
        return response.json()
    
    def get_devices(self):
        """Get all Xiaomi devices"""
        url = f"{self.base_url}/api/xiaomi/devices"
        response = self.session.get(url, auth=self.auth)
        response.raise_for_status()
        return response.json()
    
    def take_snapshot(self, camera_id):
        """Take snapshot from camera"""
        url = f"{self.base_url}/api/xiaomi/cameras/{camera_id}/snapshot"
        response = self.session.get(url, auth=self.auth)
        response.raise_for_status()
        return response.content
    
    def get_camera_status(self, camera_id):
        """Get camera status"""
        url = f"{self.base_url}/api/xiaomi/cameras/{camera_id}/status"
        response = self.session.get(url, auth=self.auth)
        response.raise_for_status()
        return response.json()
    
    def trigger_recording(self, camera_id, duration=60):
        """Trigger recording on camera"""
        url = f"{self.base_url}/api/xiaomi/cameras/{camera_id}/trigger"
        data = {
            "action": "record",
            "duration": duration
        }
        
        response = self.session.post(url, json=data, auth=self.auth)
        response.raise_for_status()
        return response.json()

def main():
    # Configuration
    NVR_URL = "http://localhost:9090"
    NVR_USERNAME = "admin"
    NVR_PASSWORD = "password"
    XIAOMI_USERNAME = "user@example.com"
    XIAOMI_PASSWORD = "xiaomi_password"
    
    # Create client
    client = XiaomiCameraClient(NVR_URL, NVR_USERNAME, NVR_PASSWORD)
    
    try:
        # Authenticate with Xiaomi
        print("Authenticating with Xiaomi...")
        auth_result = client.authenticate(XIAOMI_USERNAME, XIAOMI_PASSWORD)
        print(f"User ID: {auth_result['user_id']}")
        print(f"Devices found: {len(auth_result['devices'])}")
        
        # List devices
        print("\nAvailable devices:")
        for device in auth_result['devices']:
            print(f"- {device['name']} (DID: {device['did']})")
        
        # Monitor a specific camera
        camera_id = "xiaomi_c200_front"  # Replace with your camera ID
        
        # Get camera status
        status = client.get_camera_status(camera_id)
        print(f"\nCamera {camera_id} status:")
        print(json.dumps(status, indent=2))
        
        # Take snapshot
        print(f"\nTaking snapshot from {camera_id}...")
        snapshot_data = client.take_snapshot(camera_id)
        
        # Save snapshot
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        filename = f"xiaomi_snapshot_{timestamp}.jpg"
        with open(filename, 'wb') as f:
            f.write(snapshot_data)
        print(f"Snapshot saved as {filename}")
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
```

### Script Shell para Monitoramento

```bash
#!/bin/bash
# Xiaomi Camera Monitoring Script

NVR_URL="http://localhost:9090"
NVR_USER="admin"
NVR_PASS="password"
LOG_FILE="/var/log/xiaomi_monitor.log"

log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# Check Xiaomi devices status
check_devices() {
    response=$(curl -s -u "$NVR_USER:$NVR_PASS" "$NVR_URL/api/xiaomi/devices" 2>/dev/null)
    
    if [[ $? -eq 0 && $response != *"error"* ]]; then
        online_count=$(echo "$response" | grep -o '"online":true' | wc -l)
        total_count=$(echo "$response" | grep -o '"did"' | wc -l)
        
        log_message "Xiaomi devices status: $online_count/$total_count online"
        
        # Check if any device is offline
        if [[ $online_count -lt $total_count ]]; then
            log_message "WARNING: Some Xiaomi devices are offline"
            # Send notification
            # curl -X POST -d "message: Some Xiaomi devices offline" "your-webhook-url"
        fi
    else
        log_message "ERROR: Failed to get Xiaomi devices status"
    fi
}

# Take periodic snapshots
take_snapshots() {
    cameras=$(curl -s -u "$NVR_USER:$NVR_PASS" "$NVR_URL/api/xiaomi/devices" | grep -o '"did":"[^"]*"' | cut -d'"' -f4)
    
    for camera in $cameras; do
        # Skip if camera ID is empty
        [[ -z "$camera" ]] && continue
        
        # Take snapshot
        response=$(curl -s -u "$NVR_USER:$NVR_PASS" -o "/tmp/snapshot_${camera}.jpg" \
                  "$NVR_URL/api/xiaomi/cameras/${camera}/snapshot" 2>/dev/null)
        
        if [[ $? -eq 0 && -f "/tmp/snapshot_${camera}.jpg" ]]; then
            file_size=$(stat -c%s "/tmp/snapshot_${camera}.jpg")
            log_message "Snapshot taken for $camera: ${file_size} bytes"
            
            # Archive snapshot
            timestamp=$(date '+%Y%m%d_%H%M%S')
            cp "/tmp/snapshot_${camera}.jpg" "/var/backups/xiaomi/snapshot_${camera}_${timestamp}.jpg"
        fi
    done
}

# Main monitoring loop
while true; do
    check_devices
    take_snapshots
    
    # Wait 5 minutes before next check
    sleep 300
done
```

## Considerações de Segurança

### Segurança de Autenticação

**Armazenamento de Tokens**:
```yaml
xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  encrypt_credentials: true  # Enable if available in your version
```

**Permissão de Arquivo**:
```bash
# Secure configuration file
chmod 600 aglus-nvr.yaml
chown nvr:nvr aglus-nvr.yaml
```

### Segurança de Rede

**Configuração do firewall**:
```bash
# Allow access to Xiaomi cloud services
ufw allow to openapi.io.mi.com port 443 proto tcp

# Restrict NVR access
ufw allow from 192.168.1.0/24 to any port 9090 proto tcp
```

### Requisitos de Rede

**Acesso Obrigatório**:
- `openapi.io.mi.com:443` - Xiaomi API de nuvem
- `globalmiot.cn:443` - Xiaomi gerenciamento de dispositivos
- `https://xiaomioa.com` - Xiaomi autenticação

**Solução de Problemas de Rede**:
```bash
# Test connectivity to Xiaomi services
curl -v https://openapi.io.mi.com

# Test DNS resolution
nslookup openapi.io.mi.com
```

## Otimização de Desempenho

### Configurações Específicas da Câmera

**Para Câmeras de Alta Resolução (C300)**:
```yaml
cameras:
  - id: "xiaomi_c300"
    name: "Xiaomi C300 - Living Room"
    protocol: "xiaomi"
    encoding: "h264"
    did: "device_id_12345"
    vendor: "cs2"
    enabled: true
    hls_max_fps: 20        # Higher frame rate for 2K
    sample_interval: 1      # More frequent sampling
    segment_duration: "30s"  # Standard segment duration
    snapshot_interval: "5m" # Regular snapshots
```

**Para redes de menor largura de banda**:
```yaml
cameras:
  - id: "xiaomi_c200"
    name: "Xiaomi C200 - Backyard"
    protocol: "xiaomi"
    encoding: "h264"
    did: "device_id_67890"
    vendor: "cs2"
    enabled: true
    hls_max_fps: 10        # Lower frame rate
    sample_interval: 3      # Less frequent sampling
    snapshot_quality: "medium"  # Lower quality snapshots
```

### Configurações em Nível de Sistema

```yaml
xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  region: "cn"
  
  # Performance optimizations
  connection_timeout: "20s"    # Faster timeout
  read_timeout: "45s"        # Adjusted for network conditions
  retry_attempts: 2          # Fewer retries
  retry_delay: "5s"          # Faster retry
  
  # Memory management
  max_concurrent_cameras: 5   # Limit concurrent connections
  segment_buffer_size: "5MB" # Smaller buffer for limited RAM
```

## Solução de problemas

### Questões Comuns

#### Erro "Auth Failed"
```
ERROR: xiaomi authentication failed: invalid credentials
```
**Causas**:
- Nome de usuário/senha Xiaomi inválido
- Conta exige verificação de captcha
- Autenticação de dois fatores ativada
- Xiaomi problemas com serviços em nuvem

**Soluções**:
```bash
# Test Xiaomi credentials manually
curl -X POST https://openapi.io.mi.com/login \
  -H "Content-Type: application/json" \
  -d '{"username": "user@example.com", "password": "password"}'

# Check account status in Mi Home app
# Verify no captcha is required
# Try with a fresh Xiaomi account if needed
```

#### Erro "Dispositivo Não Encontrado"
```
ERROR: xiaomi device not found: device_id_12345
```
**Causas**:
- Câmera não vinculada à Xiaomi conta
- Câmera offline
- ID de dispositivo incorreto (DID)
- Desajuste regional

**Soluções**:
```bash
# List available devices
curl -u admin:password http://localhost:9090/api/xiaomi/devices

# Check device online status
curl -u admin:password http://localhost:9090/api/xiaomi/cameras/device_id_12345/status

# Verify camera is online in Mi Home app
# Check network connectivity
# Try refreshing device list
```

#### Erro "Gravação Falhou"
```
ERROR: xiaomi recording failed: device offline
```
**Causas**:
- Problemas de conectividade de rede
- Xiaomi Tempo de inatividade dos serviços em nuvem
- Bateria da câmera descarregada (para modelos sem fio)
- Token de autenticação expirado

**Soluções**:
```bash
# Test network connectivity to Xiaomi services
ping openapi.io.mi.com
curl -v https://globalmiot.cn

# Check token validity
curl -u admin:password http://localhost:9090/api/xiaomi/auth

# Re-authenticate if needed
curl -X POST -H "Content-Type: application/json" \
  -d '{"username": "user@example.com", "password": "new_password"}' \
  http://localhost:9090/api/xiaomi/auth
```

#### Problemas de Qualidade do Fluxo
**Sintomas**: Vídeo entrecortado, alta latência, baixa resolução

**Soluções**:
```yaml
# Adjust camera settings
cameras:
  - id: "xiaomi_camera"
    hls_max_fps: 15        # Reduce frame rate
    sample_interval: 2      # Increase sampling interval
    segment_duration: "15s" # Shorter segments
```

### Modo Depuração

Ative o registro detalhado para resolução de problemas:

```yaml
observability:
  log_level: "debug"

xiaomi:
  enabled: true
  user_id: "123456789"
  token: "your_passToken_here"
  debug: true  # Enable detailed Xiaomi logging
```

**Verifique os registros**:
```bash
# System logs
journalctl -u aglus-nvr -f | grep xiaomi

# Docker logs
docker logs -f aglus-nvr | grep xiaomi

# Configuration validation
./aglus-nvr -config aglus-nvr.yaml --validate
```

### Monitoramento de Desempenho

Monitore Xiaomi desempenho da câmera:

```bash
#!/bin/bash
# Xiaomi Performance Monitor

LOG_FILE="/var/log/xiaomi_performance.log"
NVR_URL="http://localhost:9090"
NVR_USER="admin"
NVR_PASS="password"

# Monitor response times
response_time=$(curl -o /dev/null -s -w '%{time_total}' -u "$NVR_USER:$NVR_PASS" "$NVR_URL/api/xiaomi/devices")
echo "$(date) - Xiaomi API response time: ${response_time}s" >> "$LOG_FILE"

# Monitor camera status
status=$(curl -s -u "$NVR_USER:$NVR_PASS" "$NVR_URL/api/xiaomi/devices")
online_count=$(echo "$status" | grep -o '"online":true' | wc -l)
echo "$(date) - Online cameras: $online_count" >> "$LOG_FILE"
```

## Migração e Atualizações

### Rotação de Fichas

Rotative regularmente Xiaomi credenciais para segurança:

```bash
#!/bin/bash
# Token rotation script

NVR_URL="http://localhost:9090"
NVR_USER="admin"
NVR_PASS="password"
NEW_PASSWORD="new_xiaomi_password"

# Get new authentication
curl -X POST -H "Content-Type: application/json" \
  -d "{\"username\": \"user@example.com\", \"password\": \"$NEW_PASSWORD\"}" \
  "$NVR_URL/api/xiaomi/auth" | jq '.user_id, .pass_token'

# Update configuration with new token
# (Manual update required in config file)
```

### Compatibilidade de Versões

**Verifique compatibilidade**:
```bash
# Check current version
./aglus-nvr --version

# Check for updates
curl -s https://api.github.com/repos/mms1688/AglusNVR/releases/latest | grep 'tag_name'
```

### Configuração de Backup

Backup regular da configuração Xiaomi:

```bash
#!/bin/bash
# Xiaomi Configuration Backup

BACKUP_DIR="/var/backups/xiaomi"
DATE=$(date '+%Y%m%d_%H%M%S')
CONFIG_FILE="/var/lib/aglus-nvr/aglus-nvr.yaml"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup configuration with sensitive data removed
grep -v 'token:' "$CONFIG_FILE" > "$BACKUP_DIR/aglus-nvr_config_${DATE}.yaml"

# Backup device list
curl -s -u "admin:password" "http://localhost:9090/api/xiaomi/devices" \
  > "$BACKUP_DIR/xiaomi_devices_${DATE}.json"

echo "Backup completed: $BACKUP_DIR"
```

## Melhores Práticas

1. **Atualizações regulares**: Mantenha AglusNVR atualizado para o suporte mais recente ao protocolo Xiaomi
2. **Monitoramento de Rede**: Garantir conectividade confiável com Xiaomi serviços em nuvem
3. **Gerenciamento de Tokens**: Rotacione Xiaomi credenciais periodicamente
4. **Estratégia de Backup**: Backups regulares de configurações e listas de dispositivos
5. **Monitoramento**: Configurar o monitoramento para disponibilidade e desempenho das câmeras
6. **Segurança**: Use senhas fortes e restringa o acesso à rede
7. **Documentação**: Mantenha a documentação atualizada com as configurações das câmeras
8. **Testes**: Testes regulares da funcionalidade da câmera e dos alertas

### Painel de Monitoramento

Crie um painel simples de monitoramento:

```python
#!/usr/bin/env python3
import requests
import json
from datetime import datetime

def get_xiaomi_status():
    """Get comprehensive Xiaomi status"""
    try:
        # Get devices
        devices = requests.get("http://localhost:9090/api/xiaomi/devices", 
                            auth=("admin", "password")).json()
        
        online_count = sum(1 for d in devices if d.get('online', False))
        total_count = len(devices)
        
        # Get recent recordings
        recent = requests.get("http://localhost:9090/api/recordings?limit=10",
                            auth=("admin", "password")).json()
        
        # Create status report
        status = {
            "timestamp": datetime.now().isoformat(),
            "xiaomi_devices": {
                "total": total_count,
                "online": online_count,
                "offline": total_count - online_count,
                "health": (online_count / total_count * 100) if total_count > 0 else 0
            },
            "recent_recordings": len(recent.get("recordings", [])),
            "last_check": datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        }
        
        return status
        
    except Exception as e:
        return {"error": str(e), "timestamp": datetime.now().isoformat()}

if __name__ == "__main__":
    status = get_xiaomi_status()
    print(json.dumps(status, indent=2))
```

Por meio da integração abrangente de câmeras Xiaomi, AglusNVR possibilita gravação de câmeras em nuvem sem interrupção com ricos recursos de automação, facilitando a integração de câmeras Xiaomi ao seu ecossistema de vigilância e casa inteligente.