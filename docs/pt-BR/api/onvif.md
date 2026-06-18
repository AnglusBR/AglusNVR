# ONVIF API

## Controle de câmera ONVIF

### Obtenha perfis ONVIF

**Ponto final:** `GET /api/cameras/{id}/onvif/profiles`

Obtenha perfis de mídia disponíveis para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/onvif/profiles"
```

**Resposta:**
```json
{
  "profiles": [
    {
      "token": "profile_1",
      "name": "Profile 1",
      "encoding": "H264",
      "width": 1920,
      "height": 1080
    },
    {
      "token": "profile_2", 
      "name": "Profile 2",
      "encoding": "H264",
      "width": 1280,
      "height": 720
    }
  ],
  "capabilities": {
    "ptz": true,
    "streaming": true
  }
}
```

### Obtenha recursos ONVIF

**Ponto final:** `GET /api/cameras/{id}/onvif/capabilities`

Obtenha recursos detalhados do dispositivo para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/onvif/capabilities"
```

**Resposta:**
```json
{
  "ptz": true,
  "imaging": true,
  "events": false,
  "snapshot": true,
  "streaming": true,
  "device": true
}
```

### Mover PTZ

**Ponto final:** `POST /api/cameras/{id}/ptz/move`

Mova a câmera PTZ com posicionamento absoluto/relativo.

**Corpo da solicitação:**
```json
{
  "mode": "absolute",
  "pan": 0.5,
  "tilt": 0.3,
  "zoom": 1.0,
  "speed": 1.0
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "mode": "absolute",
    "pan": 0.5,
    "tilt": 0.3,
    "zoom": 1.0
  }' \
  "http://localhost:9090/api/cameras/lobby/ptz/move"
```

**Resposta:**
```json
{
  "status": "moving"
}
```

### Stop PTZ

**Ponto final:** `POST /api/cameras/{id}/ptz/stop`

Pare o movimento PTZ.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/cameras/lobby/ptz/stop"
```

**Resposta:**
```json
{
  "status": "stopped"
}
```

### Obter status PTZ

**Ponto final:** `GET /api/cameras/{id}/ptz/status`

Obtenha a posição atual do PTZ e o status do movimento.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/ptz/status"
```

**Resposta:**
```json
{
  "pan": 0.5,
  "tilt": 0.3,
  "zoom": 1.0,
  "moving": false
}
```

### Predefinições PTZ

**Ponto final:** `GET /api/cameras/{id}/ptz/presets`

Obtenha predefinições PTZ salvas para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/ptz/presets"
```

**Resposta:**
```json
{
  "presets": [
    {
      "token": "preset_1",
      "name": "Home Position",
      "position": {
        "pan": 0.0,
        "tilt": 0.0,
        "zoom": 1.0
      }
    },
    {
      "token": "preset_2",
      "name": "Corner View",
      "position": {
        "pan": 0.5,
        "tilt": 0.3,
        "zoom": 1.5
      }
    }
  ]
}
```

### Criar predefinição PTZ

**Ponto final:** `POST /api/cameras/{id}/ptz/presets`

Crie uma nova predefinição PTZ.

**Corpo da solicitação:**
```json
{
  "name": "Home Position"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Home Position"
  }' \
  "http://localhost:9090/api/cameras/lobby/ptz/presets"
```

**Resposta:**
```json
{
  "token": "preset_123"
}
```

### Go para predefinição PTZ

**Ponto final:** `POST /api/cameras/{id}/ptz/presets/{token}/goto`

Mova a câmera para uma predefinição PTZ salva.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/cameras/lobby/ptz/presets/preset_123/goto"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

### Excluir predefinição PTZ

**Ponto final:** `DELETE /api/cameras/{id}/ptz/presets/{token}`

Exclua uma predefinição PTZ.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/cameras/lobby/ptz/presets/preset_123"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

### Snapshot URI

**Ponto final:** `GET /api/cameras/{id}/snapshot/uri`

Obtenha o URI de instantâneo para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/snapshot/uri"
```

**Resposta:**
```json
{
  "uri": "http://192.168.1.100:8080/snapshot.jpg"
}
```

## Gerenciamento de câmera ONVIF

### Configurações de imagem

**Ponto final:** `GET /api/cameras/{id}/imaging/settings`

Obtenha as configurações de imagem atuais para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/imaging/settings"
```

**Resposta:**
```json
{
  "brightness": 0.5,
  "contrast": 0.7,
  "saturation": 0.6,
  "sharpness": 0.8,
  "exposure": {
    "mode": "auto",
    "exposure_time": 0.0,
    "gain": 1.0
  },
  "white_balance": {
    "mode": "auto",
    "color_temperature": 0.0
  }
}
```

### Set Imaging Settings

**Ponto final:** `PUT /api/cameras/{id}/imaging/settings`

Atualize os parâmetros de imagem para uma câmera ONVIF.

**Corpo da solicitação:**
```json
{
  "brightness": 0.6,
  "contrast": 0.8,
  "saturation": 0.7,
  "sharpness": 0.9,
  "exposure": {
    "mode": "manual",
    "exposure_time": 0.02,
    "gain": 1.2
  },
  "white_balance": {
    "mode": "manual",
    "color_temperature": 4500
  }
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "brightness": 0.6,
    "contrast": 0.8,
    "exposure": {
      "mode": "manual",
      "exposure_time": 0.02
    }
  }' \
  "http://localhost:9090/api/cameras/lobby/imaging/settings"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

### Obtenha opções de imagem

**Ponto final:** `GET /api/cameras/{id}/imaging/options`

Obtenha intervalos de parâmetros de imagem suportados para uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/imaging/options"
```

**Resposta:**
```json
{
  "brightness": {
    "min": 0.0,
    "max": 1.0
  },
  "contrast": {
    "min": 0.0,
    "max": 1.0
  },
  "saturation": {
    "min": 0.0,
    "max": 1.0
  },
  "exposure": {
    "modes": ["auto", "manual"],
    "exposure_time": {
      "min": 0.001,
      "max": 0.1
    },
    "gain": {
      "min": 1.0,
      "max": 10.0
    }
  },
  "white_balance": {
    "modes": ["auto", "manual"],
    "color_temperature": {
      "min": 2000,
      "max": 8000
    }
  }
}
```

### Reboot Camera

**Ponto final:** `POST /api/cameras/{id}/onvif/reboot`

Reinicie uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/cameras/lobby/onvif/reboot"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

**Observação:** Algumas câmeras podem não suportar esta operação e retornarão `501 Not Implemented`.

### Configuração de rede (GET)

**Ponto final:** `GET /api/cameras/{id}/onvif/network`

Obtenha a configuração da interface de rede de uma câmera ONVIF.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/onvif/network"
```

**Resposta:**
```json
{
  "interfaces": [
    {
      "name": "eth0",
      "enabled": true,
      "ipv4": {
        "enabled": true,
        "dhcp": false,
        "address": "192.168.1.100",
        "netmask": "255.255.255.0",
        "gateway": "192.168.1.1"
      },
      "dns": ["8.8.8.8", "8.8.4.4"]
    }
  ]
}
```

### Configuração de rede (PUT)

**Ponto final:** `PUT /api/cameras/{id}/onvif/network`

Configure interfaces de rede em uma câmera ONVIF.

**Corpo da solicitação:**
```json
{
  "interfaces": [
    {
      "name": "eth0",
      "enabled": true,
      "ipv4": {
        "enabled": true,
        "dhcp": false,
        "address": "192.168.1.101",
        "netmask": "255.255.255.0",
        "gateway": "192.168.1.1"
      }
    }
  ]
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "interfaces": [
      {
        "name": "eth0",
        "enabled": true,
        "ipv4": {
          "enabled": true,
          "dhcp": false,
          "address": "192.168.1.101",
          "netmask": "255.255.255.0",
          "gateway": "192.168.1.1"
        }
      }
    ]
  }' \
  "http://localhost:9090/api/cameras/lobby/onvif/network"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

**Observação:** Pode ser necessário reiniciar a câmera para que as alterações de rede tenham efeito. Some cameras may not support this operation.

### Users (GET)

**Ponto final:** `GET /api/cameras/{id}/onvif/users`

Get users configured on an ONVIF camera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/cameras/lobby/onvif/users"
```

**Resposta:**
```json
{
  "users": [
    {
      "username": "admin",
      "user_level": "Administrator"
    }
  ]
}
```

### Usuários (POST)

**Ponto final:** `POST /api/cameras/{id}/onvif/users`

Create a new user on an ONVIF camera.

**Corpo da solicitação:**
```json
{
  "username": "operator",
  "password": "securepass",
  "user_level": "Operator"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "operator",
    "password": "securepass",
    "user_level": "Operator"
  }' \
  "http://localhost:9090/api/cameras/lobby/onvif/users"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

### Usuários (EXCLUIR)

**Ponto final:** `DELETE /api/cameras/{id}/onvif/users`

Delete a user from an ONVIF camera.

**Corpo da solicitação:**
```json
{
  "username": "operator"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  -H "Content-Type: application/json" \
  -d '{
    "username": "operator"
  }' \
  "http://localhost:9090/api/cameras/lobby/onvif/users"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

### Users (PUT)

**Ponto final:** `PUT /api/cameras/{id}/onvif/users/{username}`

Update a specific user on an ONVIF camera.

**Corpo da solicitação:**
```json
{
  "password": "newpassword",
  "user_level": "Operator"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "password": "newpassword",
    "user_level": "Operator"
  }' \
  "http://localhost:9090/api/cameras/lobby/onvif/users/operator"
```

**Resposta:**
```json
{
  "status": "ok"
}
```

## ONVIF Discovery

### Discover ONVIF Devices

**Ponto final:** `POST /api/onvif/discover`

Descubra dispositivos ONVIF na rede usando WS-Discovery.

**Corpo da solicitação:**
```json
{
  "timeout": 5,
  "target": "192.168.1.0/24"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "timeout": 5
  }' \
  "http://localhost:9090/api/onvif/discover"
```

**Resposta:**
```json
{
  "devices": [
    {
      "uuid": "uuid-12345",
      "name": "Camera 1",
      "xaddrs": ["http://192.168.1.104:80/onvif/device_service"],
      "scopes": ["onvif://www.onvif.org/Profile/Video"],
      "hardware": "Camera Model ABC",
      "endpoint": "http://192.168.1.104:80/onvif/device_service"
    }
  ]
}
```

### Get ONVIF Device Detail

**Ponto final:** `GET /api/onvif/discover/{ip}`

Obtenha informações detalhadas sobre um dispositivo ONVIF específico.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/onvif/discover/192.168.1.104"
```

**Resposta:**
```json
{
  "device_info": {
    "manufacturer": "CameraCo",
    "model": "ABC-123",
    "firmware": "1.2.3",
    "serial_number": "CAM123456"
  },
  "profiles": [
    {
      "token": "profile_1",
      "name": "Profile 1",
      "encoding": "H264",
      "width": 1920,
      "height": 1080
    }
  ]
}
```

### Dispositivo da sonda ONVIF

**Ponto final:** `POST /api/onvif/probe`

Teste um único dispositivo ONVIF enviando uma investigação WS-Discovery via HTTP POST diretamente para o host e porta especificados (sem necessidade de multicast).

**Corpo da solicitação:**
```json
{
  "host": "192.168.1.104",
  "port": 80,
  "timeout": 5
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "host": "192.168.1.104",
    "port": 80,
    "timeout": 5
  }' \
  "http://localhost:9090/api/onvif/probe"
```

**Resposta:**
```json
{
  "device": {
    "manufacturer": "CameraCo",
    "model": "ABC-123",
    "firmware": "1.2.3",
    "serial_number": "CAM123456",
    "endpoint": "http://192.168.1.104:80/onvif/device_service"
  }
}
```
