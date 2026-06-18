# Autenticação

AglusNVR usa autenticação básica HTTP para terminais protegidos. As credenciais de autenticação são definidas nas configurações do aplicativo.

### How to Use Basic Auth

```bash
curl -u username:password http://localhost:9090/api/cameras
```

### Authentication Behavior

- Se `password_hash` estiver configurado nas configurações: Todos os endpoints protegidos requerem credenciais de autenticação básica válidas
- Se `password_hash` estiver vazio nas configurações: A autenticação é ignorada (sem proteção)
- Falha na autenticação retorna `401 Unauthorized` com corpo vazio

## Entrar

**Ponto final:** `POST /api/auth/login`

Valide as credenciais de autenticação. Retorna 200 OK se as credenciais forem válidas ou encaminha a resposta do middleware de autenticação (401 Não autorizado ou 503 SETUP_REQUIRED).

**Solicitação:**
```bash
curl -u username:password -X POST "http://localhost:9090/api/auth/login"
```

**Response (200 OK):**
```json
{
  "status": "ok"
}
```

**Resposta (401 não autorizado):**
```json
{
  "error": "authentication failed: invalid username or password",
  "code": "AUTH_FAILED"
}
```

## Configuração

**Ponto final:** `POST /api/setup`

Inicialização pela primeira vez. Só é bem-sucedido quando nenhum `password_hash` estiver configurado. Cria credenciais de administrador, define o caminho de armazenamento e retorna um token de autenticação básica para login automático.

**Corpo da solicitação:**
```json
{
  "username": "admin",
  "password": "securepassword",
  "language": "en",
  "storage_path": "/var/lib/aglus-nvr"
}
```

**Solicitação:**
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "securepassword",
    "language": "en"
  }' \
  "http://localhost:9090/api/setup"
```

**Response:**
```json
{
  "status": "ok",
  "token": "YWRtaW46c2VjdXJlcGFzc3dvcmQ="
}
```

**Resposta (já configurada):**
```json
{
  "error": "setup already completed",
  "code": "INVALID_INPUT"
}
```

## Capacidades

**Ponto final:** `GET /api/capabilities`

Obtenha recursos de ingestão do sistema (RTMP, SRT). Public endpoint.

**Solicitação:**
```bash
curl http://localhost:9090/api/capabilities
```

**Resposta:**
```json
{
  "ingest": {
    "rtmp": {
      "enabled": true,
      "port": 1935
    },
    "srt": {
      "enabled": true,
      "port": 8890
    }
  }
}
```
