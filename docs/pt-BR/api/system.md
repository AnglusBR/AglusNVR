# API de integridade e sistema

## Verificação de saúde

**Ponto final:** `GET /api/health`

Obtenha o status geral da integridade do sistema, incluindo banco de dados e espaço em disco de armazenamento.

**Solicitação:**
```bash
curl http://localhost:9090/api/health
```

**Resposta:**
```json
{
  "status": "ok",
  "checks": {
    "database": {
      "status": "ok",
      "message": ""
    },
    "storage": {
      "status": "ok", 
      "message": ""
    }
  },
  "uptime": "2h34m15s"
}
```

## Readiness Check

**Ponto final:** `GET /api/readyz`

Check if the system is ready to accept requests (same as health check).

**Solicitação:**
```bash
curl http://localhost:9090/api/readyz
```

**Resposta:**
```json
{
  "status": "ok"
}
```

## Estatísticas do sistema

**Ponto final:** `GET /api/stats/system`

Obtenha estatísticas detalhadas do sistema, incluindo uso de CPU, memória e rede.

**Solicitação:**
```bash
curl -u username:password \
  "http://localhost:9090/api/stats/system"
```

**Resposta:**
```json
{
  "cpu": {
    "total": 1234567,
    "idle": 987654
  },
  "memory": {
    "total": 1073741824,
    "available": 536870912,
    "process_rss": 10485760
  },
  "network": {
    "bytes_sent": 1048576,
    "bytes_recv": 2097152
  },
  "uptime": "2h34m15s",
  "timestamp": 1716789012
}
```
