# Archive API

## Listar arquivos

**Ponto final:** `GET /api/archives`

Liste todos os grupos de arquivos por câmera.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/archives"
```

**Response:**
```json
{
  "archives": [
    {
      "camera_id": "front-door",
      "retention_days": 30,
      "recordings_count": 150,
      "total_size_mb": 1024
    }
  ]
}
```

## List Archive Recordings

**Ponto final:** `GET /api/archives/{cameraID}/recordings`

List recordings for a specific archive.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/archives/front-door/recordings"
```

**Response:**
```json
{
  "recordings": [
    {
      "id": "1704123456789012345",
      "started_at": "2024-01-01T12:34:56.789Z",
      "duration": 10.0,
      "file_size": 1048576
    }
  ],
  "total": 1
}
```

## Excluir grupo de arquivos

**Ponto final:** `DELETE /api/archives/{cameraID}`

Exclua um grupo de arquivos inteiro de uma câmera.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/archives/front-door"
```

**Response:**
```json
{
  "status": "deleted"
}
```

## Delete Archive Recording

**Ponto final:** `DELETE /api/archives/{cameraID}/recordings/{recordingID}`

Exclua uma gravação específica de um arquivo.

**Solicitação:**
```bash
curl -u username:password \
  -X DELETE \
  "http://localhost:9090/api/archives/front-door/recordings/1704123456789012345"
```

**Response:**
```json
{
  "status": "deleted"
}
```

## Set Archive Retention

**Ponto final:** `PUT /api/archives/{cameraID}/retention`

Defina o período de retenção para um grupo de arquivos.

**Corpo da solicitação:**
```json
{
  "retention_days": 60
}
```

**Solicitação:**
```bash
curl -u username:password \
  -X PUT \
  -H "Content-Type: application/json" \
  -d '{
    "retention_days": 60
  }' \
  "http://localhost:9090/api/archives/front-door/retention"
```

**Resposta:**
```json
{
  "status": "updated"
}
```
