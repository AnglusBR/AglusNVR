# Backup API

## Criar backup

**Ponto final:** `POST /api/backup`

Create a backup of the database.

**Solicitação:**
```bash
curl -u username:password \
  -X POST \
  "http://localhost:9090/api/backup"
```

**Resposta:**
```json
{
  "status": "created",
  "file": "nvr-backup-20240101-123456.db"
}
```

## Listar backups

**Ponto final:** `GET /api/backups`

List available backup files.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/backups"
```

**Resposta:**
```json
["nvr-backup-20240101-123456.db", "nvr-backup-20240102-091234.db"]
```
