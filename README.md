# AglusNVR
[![Versão](https://img.shields.io/github/v/release/seu-usuario/AglusNVR?style=flat&label=versão)](https://github.com/seu-usuario/AglusNVR/releases)
[![CI](https://img.shields.io/github/actions/workflow/status/seu-usuario/AglusNVR/ci.yml?style=flat&label=CI)](https://github.com/seu-usuario/AglusNVR/actions/workflows/ci.yml)
[![Go](https://img.shields.io/badge/Go-00ADD8?style=flat&logo=go&logoColor=white)](https://go.dev/)
[![Svelte](https://img.shields.io/badge/Svelte-FF3E00?style=flat&logo=svelte&logoColor=white)](https://svelte.dev/)
[![SQLite](https://img.shields.io/badge/SQLite-003B57?style=flat&logo=sqlite&logoColor=white)](https://www.sqlite.org/)
[![Docker](https://img.shields.io/badge/Docker-2496ED?style=flat&logo=docker&logoColor=white)](https://www.docker.com/)
[![Raspberry Pi](https://img.shields.io/badge/Raspberry_Pi-A22846?style=flat&logo=raspberrypi&logoColor=white)](https://www.raspberrypi.com/)
[![Licença: MIT](https://img.shields.io/badge/licença-MIT-yellow?style=flat)](LICENSE)

> **Transforme qualquer Raspberry Pi em um NVR profissional em 60 segundos.**
> Binário único, zero dependências, sem necessidade de nuvem. Roda em Raspberry Pi 3B com orçamento de memória de 512MB.

[Português (Brasil)](README.md) — [English](README.en.md) — [中文](README.zh.md)

## Início Rápido

### Instalar com um clique (Recomendado)

```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh | sudo bash
```

O instalador detecta a arquitetura, baixa e verifica o binário, cria o usuário
de sistema `aglus-nvr`, gera a configuração, instala o serviço systemd e inicia
o AglusNVR. O diretório padrão de dados é `/var/lib/aglus-nvr`.

Para uma instalação não interativa:

```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh \
  | sudo AGLUS_PASSWORD='uma-senha-segura' bash
```

Para desinstalar sem apagar as gravações:

```bash
curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh \
  | sudo bash -s -- --desinstalar
```

### Opção 1: Binário pré-construído

Baixe o binário mais recente do [GitHub Releases](https://github.com/seu-usuario/AglusNVR/releases):

```bash
# AMD64 (maioria dos PCs e servidores)
wget https://github.com/seu-usuario/AglusNVR/releases/latest/download/aglus-nvr-amd64
chmod +x aglus-nvr-amd64

# ARM64 (Raspberry Pi 4/5 etc.)
wget https://github.com/seu-usuario/AglusNVR/releases/latest/download/aglus-nvr-arm64
chmod +x aglus-nvr-arm64

# ARMv7 (Raspberry Pi 2/3 etc.)
wget https://github.com/seu-usuario/AglusNVR/releases/latest/download/aglus-nvr-armv7
chmod +x aglus-nvr-armv7
```

Inicialize a configuração e comece:

```bash
./aglus-nvr-amd64 init --password sua-senha
./aglus-nvr-amd64 -config aglus-nvr.yaml
```

Abra `http://localhost:9090` para acessar a interface web.

### Opção 2: Docker

```bash
docker compose up -d
```

Abra `http://localhost:9090` para acessar a interface web.

Para armazenar gravações em um drive externo, edite a montagem de volume em `docker-compose.yml`:

```yaml
    volumes:
      - /mnt/external/nvr:/data    # ← altere para o caminho desejado no host
    environment:
      - NVR_DATA_DIR=/data          # deve corresponder ? montagem do volume
```

### Opção 3: Construir a partir da Fonte

```bash
git clone https://github.com/seu-usuario/AglusNVR.git
cd AglusNVR
make build
./aglus-nvr init --password sua-senha
./aglus-nvr -config aglus-nvr.yaml
```

Para uma configuração detalhada, veja [Começando](docs/pt-BR/getting-started.md).

## Por que AglusNVR?

- **Binário Único**: Zero dependências, embutido Svelte 5 SPA, `CGO_ENABLED=0`
- **Raspberry Pi 3B Ready**: Roda com 1GB de RAM e orçamento de memória de 512MB
- **Streaming Multiprotocolo**: HLS, WebRTC, HTTP-FLV, RTMP, SRT, WebSocket
- **Não é necessário nuvem**: Autohospedado, sem assinaturas, sem lock-in de fornecedor
- **Interface Web Moderna**: Temas escuros/claros, suporte a i18n, design responsivo
- **ONVIF Suporte**: Auto-descoberta, controle de PTZ, gerenciamento de URI de fluxo
- **Integrações inteligentes**: MQTT triggers, WebDAV, FTP FFmpeg transcodificação

## Capturas de tela

![Login](docs/images/login-light.png)  
*Página de login com opção de alternância e autenticação do tema escuro/claro*

![Painel](docs/images/dashboard-light.png)
*Painel com transmissões ao vivo das câmeras, status de gravação e métricas do sistema*

![Configuração](docs/images/settings-light.png)
*Painel de configurações para configuração da câmera e gerenciamento do sistema*

## Características

### 📷 Suporte de Câmera
- RTSP (H.264/H.265/MJPEG) streaming
- HTTP JPEG streaming de snapshots
- ONVIF descoberta e gerenciamento com controle PTZ
- Xiaomi Suporte ao protocolo CS2 P2P
- SRT/RTMP câmeras push-in (ingestre entre redes — receber fluxos de publicadoras remotas)
- Relé nativo Go push-out (encaminhe qualquer câmera para alvos remotos RTMP/RTSP — sem FFmpeg)

### 📺 Transmissão e Visualização ao Vivo
- HLS streaming sob demanda com suporte LL-HLS
- WebRTC WHEP para visualização com latência abaixo de um segundo
- HTTP-FLV para streaming amigável ao navegador
- RTMP servidor de ingest para fluxos de trabalho push/pull
- SRT receptor de transporte de baixa latência
- WebSocket streaming binário de quadros em tempo real

### 💾 Gravação e Armazenamento
- Geração automática de segmentos MP4
- Gravação simultânea com múltiplas câmeras
- Políticas de retenção por câmera
- Captura de áudio (AAC + G.711)
- Fusão de segmentos com políticas configuráveis
- Gravação periódica em timelapse

### 🔧 Gestão
- Interface web Modern Svelte 5 com temas escuros/claros
- REST API para automação
- BasicAuth com hash de senha bcrypt
- Prometheus integração de métricas
- Configuração atômica com validação

### 🤖 Recursos Inteligentes
- Detecção de IA no navegador (ONNX Runtime Web, acelerada WebGPU) — sem inferência de backend
- Monitoramento de saúde de câmeras em múltiplas camadas
- Correção automática para problemas de conexão
- Sistema de eventos em tempo real baseado em SSE
- Pontuação de qualidade e alerta

### 🔌 Integrações
- MQTT gravação baseada em gatilhos
- WebDAV servidor para acesso a arquivos
- Servidor FTP para uploads remotos
- FFmpeg transcodificação de hardware
- Arquitetura orientada a eventos

## Protocolos Suportados

| Protocolo | Direção | Status | Notas |
|----------|----------|---------|-------|
| RTSP | Câmera → NVR | ✅ Feito | H.264/H.265/MJPEG suporte |
| HTTP JPEG | Câmera → NVR | ✅ Feito | Transmissão de snapshots |
| HLS | NVR → Navegador | ✅ Feito | Streaming sob demanda |
| WebRTC | NVR → Navegador | ✅ Feito | WHEP latência sub-segundo |
| HTTP-FLV | NVR → Navegador | ✅ Feito | Streaming amigável para navegador |
| RTMP (entrada) | Câmera → NVR | ✅ Feito | Push-in: receber streams de publicadores remotos |
| SRT (entrada) | Câmera → NVR | ✅ Feito | Push-in: transporte de baixa latência |
| RTMP (retransmissão) | NVR → Externo | ✅ Feito | Saída: retransmissão nativa em Go para destinos remotos |
| RTSP (retransmissão) | NVR → Externo | ✅ Feito | Saída: retransmissão nativa em Go para destinos remotos |
| ONVIF | Câmera ↔ NVR | ✅ Feito | Discovery, PTZ, stream URI |
| Xiaomi CS2 | Câmera → NVR | ✅ Feito | Protocolo P2P, autenticação na nuvem |

## Casos de Uso

### 🏠 Segurança residencial
Monitore sua propriedade com várias câmeras. Gravação acionada por movimento, alertas no smartphone e visualização remota fácil de qualquer lugar.

### 🏪 Pequenas Empresas
Sistema de segurança acessível para lojas, escritórios e armazéns. Suporte multi-câmera com políticas individuais de retenção.

### 🔧 DIY/Ajustes
Perfeito para entusiastas de homelab. Auto-hospedado, sem assinaturas, funciona com qualquer câmera RTSP e integra com sistemas domésticos inteligentes.

## Documentação

| Documento | Descrição |
|----------|-------------|
| [Começando](docs/pt-BR/getting-started.md) | Instalação, primeira configuração de câmera |
| [Configuração](docs/pt-BR/configuration.md) | Referência completa de configuração |
| [Referência API](docs/pt-BR/api/README.md) | REST API documentação |
| [MediaMTX Guia](docs/pt-BR/mediamtx-guide.md) | MediaMTX integração para câmeras CSI |
| [Implantação](docs/pt-BR/deployment.md) | systemd, proxy reverso, compilação cruzada |
| [Xiaomi Preparação](docs/pt-BR/xiaomi-setup.md) | Xiaomi integração com câmera em nuvem |
| [ONVIF Guia](docs/pt-BR/onvif-guide.md) | ONVIF configuração da câmera, controle de PTZ, solução de problemas |
| [Guia de Câmera](docs/pt-BR/camera-guide.md) | Configuração da câmera, protocolos, solução de problemas |
| [Integração FTP](docs/pt-BR/ftp-integration.md) | Configuração de acesso a arquivos FTP |
| [MQTT Integração](docs/pt-BR/mqtt-integration.md) | MQTT integração de casa inteligente |
| [WebDAV Integração](docs/pt-BR/webdav-integration.md) | WebDAV configuração de acesso a arquivos |
| [Solução de problemas](docs/pt-BR/troubleshooting.md) | Questões e soluções comuns |
| [Transcodificação](docs/pt-BR/transcoding.md) | FFmpeg configuração de transcodificação |
| [Prometheus Métricas](docs/pt-BR/metrics.md) | Referência completa Prometheus métrica com tipos, rótulos e exemplos |
| [Guia de retransmissão](docs/pt-BR/relay-guide.md) | Configuração e solução de problemas da retransmissão RTMP |
| [转发指南](docs/zh/relay-guide.md) | RTMP 直播平台转发配置和故障排除 |

## Construir e Implantar

```bash
# Compilar para a arquitetura atual
make build

# Compilar para ARM64 (Raspberry Pi)
make cross

# Executar os testes
make test

# Criar imagens Docker
make docker-build       # compilação em múltiplos estágios
make docker-build-arm64 # compilação cruzada + scratch
make docker-build-all   # todas as arquiteturas
```

Docker implantação:
```bash
docker compose up -d
```

Imagens publicadas para `ghcr.io/seu-usuario/aglusnvr` com tags: `latest`, `v1.2.3`, `sha-abc1234`

## Estrutura do Projeto

```
cmd/aglus-nvr/       # entrada da CLI e ciclo de vida do aplicativo
internal/            # pacotes centrais em Go
web/                 # interface SPA em Svelte 5
deploy/              # serviços systemd e Caddyfile
docs/                # documentação em PT-BR, inglês e chinês
tests/               # testes de integração
e2e-tests/           # testes E2E com Playwright
```



## Contribuição

1. Faça `make lint` antes de enviar
2. Adicionar testes para novos recursos
3. Escreva mensagens de commit claras

## Origem do projeto

AglusNVR é uma adaptação em português do Brasil baseada no projeto de código aberto
[MiBeeNvr](https://github.com/Mi-Bee-Studio/MiBeeNvr), de Mi&Bee Studio.
Esta versão preserva a licença MIT e os créditos do projeto original.

## Licença

[Licença MIT](LICENSE) — copyright original © 2026 Mi&Bee Studio
