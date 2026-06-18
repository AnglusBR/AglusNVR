# Respostas de erro

Todas as respostas de erro seguem este formato:

```json
{
  "error": "Error message",
  "code": "ERROR_CODE"
}
```

## Referência de código de erro

| Código | Descrição | Status HTTP |
|------|-------------|-------------|
| `CAMERA_NOT_FOUND` | A câmera com ID especificada não existe | 404 |
| `CAMERA_ALREADY_RUNNING` | O gravador da câmera já está ativo | 400 |
| `CAMERA_DISABLED` | Camera is disabled and cannot be started | 400 |
| `CAMERA_ALREADY_EXISTS` | Camera with specified ID already exists | 409 |
| `RECORDING_NOT_FOUND` | A gravação com ID especificado não existe | 404 |
| `STORAGE_FULL` | O espaço em disco está criticamente baixo | 507 |
| `AUTH_REQUIRED` | Authentication is required | 401 |
| `AUTH_FAILED` | As credenciais de autenticação foram rejeitadas | 401 |
| `INVALID_INPUT` | Request contains invalid parameters | 400 |
| `PATH_TRAVERSAL` | Path traversal attempt detected | 400 |
| `HLS_MAX_STREAMS` | Limite máximo de fluxo simultâneo HLS atingido | 503 |
| `HLS_UNSUPPORTED_CODEC` | O codec da câmera não é compatível com streaming HLS | 400 |
| `ONVIF_NOT_CAMERA` | O dispositivo não é uma câmera ONVIF | 400 |
| `ONVIF_CONNECTION_FAILED` | Failed to connect to ONVIF device | 500 |
| `ONVIF_NO_PROFILES` | No media profiles found for ONVIF camera | 400 |
| `INTERNAL` | Erro interno do servidor | 500 |

## Common Error Examples

### Authentication Failed
```json
{
  "error": "authentication failed: invalid username or password",
  "code": "AUTH_FAILED"
}
```

### Câmera não encontrada
```json
{
  "error": "camera not found: non-existent-camera",
  "code": "CAMERA_NOT_FOUND"
}
```

### Entrada inválida
```json
{
  "error": "invalid input: camera URL must be valid",
  "code": "INVALID_INPUT"
}
```

### Armazenamento cheio
```json
{
  "error": "storage full: disk space critically low",
  "code": "STORAGE_FULL"
}
```

## HTTP Status Codes

| Código de status | Descrição |
|-------------|-------------|
| 200 | OK - Request successful |
| 201 | Created - Resource successfully created |
| 202 | Aceito - Solicitação aceita para processamento (por exemplo, download assíncrono) |
| 204 | Sem conteúdo - Solicitação bem-sucedida, sem corpo de resposta |
| 400 | Bad Request - Invalid request parameters |
| 401 | Não autorizado - Autenticação falhada ou necessária |
| 403 | Forbidden - Resource access not allowed |
| 404 | Not Found - Resource does not exist |
| 409 | Conflito - Conflito de recursos (por exemplo, ID de câmera duplicada) |
| 500 | Internal Server Error - Server-side error |
| 502 | Gateway inválido - Erro de serviço upstream (por exemplo, sonda ONVIF) |
| 503 | Serviço indisponível - Serviço temporariamente indisponível |
| 507 | Insufficient Storage - Disk space insufficient |
