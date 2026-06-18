# API Xiaomi

## Autenticação em nuvem Xiaomi

**Ponto final:** `POST /api/xiaomi/auth`

Autentique com serviços em nuvem Xiaomi.

**Corpo da solicitação:**
```json
{
  "username": "xiaomi@example.com",
  "password": "password123"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "xiaomi@example.com",
    "password": "password123"
  }' \
  "http://localhost:9090/api/xiaomi/auth"
```

**Resposta:**
```json
{
  "user_id": "1234567890",
  "token": "xiaomi_token_123",
  "region": "cn"
}
```

## Get Xiaomi Captcha

**Ponto final:** `POST /api/xiaomi/captcha`

Obtenha captcha para autenticação Xiaomi.

**Corpo da solicitação:**
```json
{
  "username": "xiaomi@example.com"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "xiaomi@example.com"
  }' \
  "http://localhost:9090/api/xiaomi/captcha"
```

**Resposta:**
```json
{
  "captcha_id": "captcha_123",
  "captcha_image": "base64_encoded_image"
}
```

## Verifique o Captcha Xiaomi

**Ponto final:** `POST /api/xiaomi/verify`

Verifique o captcha e conclua a autenticação.

**Corpo da solicitação:**
```json
{
  "captcha_id": "captcha_123",
  "captcha_code": "ABC123",
  "username": "xiaomi@example.com",
  "password": "password123"
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "captcha_id": "captcha_123",
    "captcha_code": "ABC123",
    "username": "xiaomi@example.com",
    "password": "password123"
  }' \
  "http://localhost:9090/api/xiaomi/verify"
```

**Resposta:**
```json
{
  "user_id": "1234567890",
  "token": "xiaomi_token_123",
  "region": "cn"
}
```

## Listar dispositivos Xiaomi

**Ponto final:** `GET /api/xiaomi/devices`

Obtenha a lista de dispositivos Xiaomi da nuvem.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/xiaomi/devices"
```

**Resposta:**
```json
{
  "devices": [
    {
      "did": "camera_did_123",
      "name": "Front Door Camera",
      "model": "xiaomi.camera.v2",
      "online": true
    }
  ]
}
```

## Sincronizar dispositivos Xiaomi

**Ponto final:** `POST /api/xiaomi/sync`

Sincronize dispositivos Xiaomi com configuração local.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/xiaomi/sync"
```

**Resposta:**
```json
{
  "synced": 2,
  "added": 1,
  "removed": 0
}
```

## Verifique o fornecedor Xiaomi

**Ponto final:** `GET /api/xiaomi/check-vendor`

Verifique o protocolo do fornecedor para um dispositivo Xiaomi por DID. Valida se o dispositivo usa o protocolo CS2 (suportado) ou protocolo TUTK (sem suporte).

**Parâmetros de consulta:**

| Parâmetro | Tipo | Obrigatório | Descrição | Exemplo |
|-----------|------|----------|-------------|---------|
| `did` | corda | Sim | Dispositivo DID para verificar | `camera_did_123` |

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/xiaomi/check-vendor?did=camera_did_123"
```

**Resposta (CS2 - compatível):**
```json
{
  "vendor": "cs2",
  "compatible": true
}
```

**Resposta (TUTK - incompatível):**
```json
{
  "vendor": "tutk",
  "compatible": false,
  "message": "This device uses TUTK protocol which is not supported by AglusNVR. Only CS2 protocol cameras are supported."
}
```
