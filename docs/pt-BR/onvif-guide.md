# ONVIF Guia para AglusNVR

Este guia aborda ONVIF integração (Open Network Video Interface Forum) com AglusNVR, incluindo descoberta de câmeras, gerenciamento, controle PTZ e solução de problemas.

## O que é ONVIF e Visão Geral do Perfil S

ONVIF é um padrão aberto da indústria para produtos de vídeo em rede, permitindo que câmeras IP de diferentes fabricantes trabalhem juntas. O Aglus N implementa ONVIF Perfil S, que foca na funcionalidade central de streaming de vídeo:

- **Perfil S**: Transmissão de vídeo, controle de PTZ, gerenciamento de dispositivos
- **Perfil T**: Melhorias de segurança (eventos de controle de acesso)
- **Perfil G**: Análise e metadados
- **Perfil Q**: Controle avançado de PTZ

AglusNVR suporta principalmente capacidades Profile S, com suporte opcional para gerenciamento de dispositivos e monitoramento de eventos, dependendo do firmware da câmera.

## Serviços de ONVIF Suportados

AglusNVR oferece as seguintes integrações de ONVIF serviços:

### Serviço de Dispositivo
- Informações e capacidades do dispositivo
- Configuração da interface de rede
- Gerenciamento de usuários
- Reinicialização do sistema

### Serviço de Mídia  
- Perfis de streaming de vídeo
- Suporte a resolução e codec
- Configurações de taxa de quadros e taxa de bits
- Configuração do fluxo de áudio

### Serviço PTZ
- Controle de panorâmica, inclinação, zoom
- Gerenciamento de pré-sets
- Movimento de posição
- Movimento contínuo

### Serviço de Imagem
- Configurações de imagem (brilho, contraste, saturação)
- Controle de exposição
- Ajuste de foco
- Balanço de branco

### Serviço de Eventos (Limitado)
- Eventos de detecção de movimento
- Mudanças no status do dispositivo
- **Nota**: O suporte ao serviço de eventos varia conforme o modelo da câmera

### Serviço de Gerenciamento de Dispositivos (Limitado)
- Configuração da rede
- Configurações do sistema
- Gerenciamento de usuários
- **Nota**: O suporte ao gerenciamento de dispositivos varia conforme o modelo da câmera

## Descoberta da Câmera

AglusNVR suporta dois métodos de descoberta de câmera:

### WS-Discovery (Multicast)

**Método**: UDP multicast para `239.255.255.250:3702`
```bash
# Test WS-Discovery manually
nmap -p 3702 --open 192.168.1.0/24
```

**Status**: 
- ✅ Funciona em metal nu/Raspberry Pi
- ❌ **Bloqueado em contêineres Docker** (multicast não suportado)

### HTTP Sonda

**Método**: Direcionar HTTP solicitação para ONVIF endpoint
```bash
# Probe specific IP address
curl -X POST http://localhost:9090/api/onvif/probe \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100", "port": 80}'
```

**Status**:
- ✅ Funciona em todos os ambientes, inclusive Docker
- ✅ Mais confiável para resolução de problemas de rede

### Adição Manual de Câmera

Quando a descoberta falha, você pode adicionar câmeras manualmente:

```yaml
cameras:
  - id: "manual_onvif"
    name: "Manual ONVIF Camera"
    protocol: "onvif"
    url: "http://192.168.1.100:80/onvif/device_service"
    username: "admin"
    password: "password"
    enabled: true
```

## Adicionando ONVIF Câmera Passo a Passo

### Método 1: Descoberta de Interface Web (Recomendado)

1. Interface Web AglusNVR aberta
2. Navegue até **Câmeras** → **Adicionar Câmera**
3. Selecione **ONVIF** no menu suspenso do protocolo
4. Clique **Descobrir Câmeras**
5. Se a descoberta automática falhar:
   - Use a seção de **Sonda Manual**
   - Insira o endereço IP da câmera diretamente
6. Selecione a câmera descoberta da lista
7. Configurar configurações:
   - Nome da câmera
   - Cronograma de gravações
   - Preferências de stream
8. Clique **Adicionar Câmera**

### Método 2: Configuração Manual

Para câmeras que não podem ser descobertas automaticamente:

1. Obtenha a URL da câmera ONVIF endpoint:
   ```bash
   # Find ONVIF device service
   nmap -p 80 --open 192.168.1.0/24 | grep 80/open
   curl http://192.168.1.100/onvif/device_service
   ```

2. Adicionar à configuração:
   ```yaml
   cameras:
     - id: "camera_ip"
       name: "Camera Location"
       protocol: "onvif"
       url: "http://192.168.1.100:80/onvif/device_service"  
       username: "admin"
       password: "password"
       encoding: "h264"  # or h265, mjpeg
       enabled: true
   ```

### Método 3: Configuração da API

```bash
# Add camera via API
curl -X POST http://localhost:9090/api/cameras \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "id": "api_camera",
    "name": "API Camera", 
    "protocol": "onvif",
    "url": "http://192.168.1.100/onvif/device_service",
    "username": "admin",
    "password": "password",
    "encoding": "h264",
    "enabled": true
  }'
```

## Controle PTZ e Predefinições

### Endpoints da API de Controle PTZ

Todas as operações da PTZ estão disponíveis via REST API:

#### Move Camera
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/ptz/move \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "pan": 0.5,
    "tilt": 0.3,
    "zoom": 1.0,
    "relative": true
  }'
```

#### Movimento Stop PTZ
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/ptz/stop \
  -H "Authorization: Bearer your-token"
```

#### Obtenha o status PTZ
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/ptz/status \
  -H "Authorization: Bearer your-token"
```

### Gerenciamento de Pré-Definições

#### Presets de Lista
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/ptz/presets \
  -H "Authorization: Bearer your-token"
```

#### Criar Predefinição
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/ptz/presets \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "name": "Main Entrance",
    "position": {
      "pan": 0.0,
      "tilt": 0.0,
      "zoom": 1.0
    }
  }'
```

#### Go ao Preset
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/ptz/presets/{token}/goto \
  -H "Authorization: Bearer your-token"
```

#### Delete Preset
```bash
curl -X DELETE http://localhost:9090/api/cameras/{id}/ptz/presets/{token} \
  -H "Authorization: Bearer your-token"
```

### Controle PTZ da interface web

1. Câmera aberta ao vivo
2. Clique no botão **PTZ Control**
3. Use o direcional para panoramagem/inclinação
4. Use os botões +/- para dar zoom
5. Salvar posições como presets
6. Acessar presets a partir do menu suspenso

## Configuração das Configurações de Imagem

### Configurações de Imagem Disponíveis

#### Obtenha as configurações atuais
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/imaging/settings \
  -H "Authorization: Bearer your-token"
```

**Exemplo de resposta**:
```json
{
  "brightness": 50,
  "contrast": 50, 
  "saturation": 50,
  "sharpness": 50,
  "exposure_mode": "auto",
  "exposure_priority": "normal",
  "backlight_compensation": false,
  "wide_dynamic_range": false
}
```

#### Atualizar as configurações de imagem
```bash
curl -X PUT http://localhost:9090/api/cameras/{id}/imaging/settings \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "brightness": 70,
    "contrast": 60,
    "saturation": 55,
    "sharpness": 65,
    "exposure_mode": "auto",
    "exposure_priority": "normal",
    "backlight_compensation": true
  }'
```

### Obtenha Opções de Suporte
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/imaging/options \
  -H "Authorization: Bearer your-token"
```

**Exemplo de resposta**:
```json
{
  "brightness": {
    "min": 0,
    "max": 100,
    "step": 1
  },
  "exposure_mode": ["auto", "manual", "aperture_priority"],
  "wide_dynamic_range": [false, true]
}
```

### Notas sobre Configurações de Imagem

- **OV5647 Raspberry Pi Câmera**: As mudanças nas configurações podem não persistir
- **Diferenças na Câmera**: As configurações suportadas variam conforme o fabricante
- **Persistência**: Algumas câmeras precisam de reinicialização para que as mudanças tenham efeito
- **Reset**: Use a interface web da câmera para resetar os padrões de fábrica, se necessário

## Suporte a Snapshots

### Obtenha o URI do Snapshot

```bash
curl -X GET http://localhost:9090/api/cameras/{id}/snapshot/uri \
  -H "Authorization: Bearer your-token"
```

**Exemplo de resposta**:
```json
{
  "uri": "http://192.168.1.100/snapshot.jpg",
  "expires": "2024-01-01T12:00:00Z"
}
```

### Obtenha Snapshot Direto

```bash
curl -X GET http://localhost:9090/api/cameras/{id}/snapshot \
  -H "Authorization: Bearer your-token" \
  -o camera_snapshot.jpg
```

### Uso de Snapshots

- **Formato**: Formato nativo da câmera (geralmente JPEG)
- **Compatibilidade de Navegador**: A maioria dos navegadores suporta snapshots JPEG
- **Resolução**: Resolução nativa da câmera (pode não ser visualizada em todos os navegadores)
- **Cache**: AglusNVR armazena snapshots em cache por 5 segundos para reduzir a carga
- **Alternativas**: Use RTSP/HTTP JPEG stream para formatar de forma consistente

### Snapshots da interface web

1. Câmera aberta ao vivo
2. Clique no botão **Snapshot**
3. Baixe a imagem capturada
4. Snapshots são armazenados em cache para acesso imediato

## Monitoramento de Eventos (Detecção de Movimento)

### ONVIF Suporte ao Serviço de Eventos

**Nota**: O suporte ao serviço de eventos varia significativamente de acordo com o modelo da câmera.

#### Verifique o Suporte ao Serviço de Eventos
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/onvif/capabilities \
  -H "Authorization: Bearer your-token"
```

Procure `Events` em respostas de capacidades:
```json
{
  "capabilities": {
    "Events": true,
    "Media": true,
    "PTZ": true
  }
}
```

### Eventos de Detecção de Movimento

Quando suportados, os eventos de movimento estão disponíveis por meio de assinatura ONVIF:

#### Assine os Eventos Motion
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/onvif/events/subscribe \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "topic": "tns1:MotionAlarm",
    "filter": {
      "SimpleItem": {
        "Name": "RegionOfInterest",
        "Value": "1"
      }
    }
  }'
```

### Limitações de Eventos

- **Dependente da Câmera**: Apenas câmeras com suporte ONVIF Serviço de Eventos
- **Firmware Necessário**: Frequentemente requer uma versão específica de firmware
- **Variações de protocolo**: Implementações diferentes entre fabricantes
- **AglusNVR Integração**: Atualmente suporta assinatura básica de eventos

### Detecção de Movimento Alternativa

Para câmeras sem suporte a eventos ONVIF:
- Use a detecção de movimento embutida da câmera
- Configure a detecção de movimento externa em AglusNVR
- Use soluções de detecção de movimento de terceiros

## Gerenciamento de Dispositivos

### Dispositivo de Reinicialização

```bash
curl -X POST http://localhost:9090/api/cameras/{id}/onvif/reboot \
  -H "Authorization: Bearer your-token"
```

### Configuração da Rede

#### Obtenha Interfaces de Rede
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/onvif/network \
  -H "Authorization: Bearer your-token"
```

#### Configurar a Rede
```bash
curl -X PUT http://localhost:9090/api/cameras/{id}/onvif/network \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "interface": "eth0",
    "mode": "static",
    "ip_address": "192.168.1.100",
    "subnet_mask": "255.255.255.0",
    "default_gateway": "192.168.1.1"
  }'
```

### Gerenciamento de Usuários

#### Usuários da Lista
```bash
curl -X GET http://localhost:9090/api/cameras/{id}/onvif/users \
  -H "Authorization: Bearer your-token"
```

#### Criar Usuários
```bash
curl -X POST http://localhost:9090/api/cameras/{id}/onvif/users \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-token" \
  -d '{
    "username": "viewer",
    "password": "password123",
    "user_level": "operator"
  }'
```

#### Excluir usuários
```bash
curl -X DELETE http://localhost:9090/api/cameras/{id}/onvif/users/username \
  -H "Authorization: Bearer your-token"
```

### Notas sobre Gerenciamento de Dispositivos

- **Suporte a Câmeras**: O gerenciamento de dispositivos varia conforme o modelo da câmera
- **Câmera de Teste OV5647**: Capacidades limitadas de gerenciamento de dispositivos
- **Mudanças na rede**: Pode exigir reinício da câmera
- **Níveis de Usuário**: Padrão: `admin`, `operator`, `viewer`, `user`

## Solução de problemas

### Questões comuns ONVIF

#### Falhas de autenticação

**Sintoma**: erro `401 Unauthorized` ao acessar ONVIF endpoints

**Soluções**:
```bash
# Test basic ONVIF connectivity
curl -I http://192.168.1.100/onvif/device_service

# Check ONVIF port accessibility
nc -zv 192.168.1.100 80

# Test authentication
curl -u admin:password http://192.168.1.100/onvif/device_service
```

**Correções de configuração**:
```yaml
# Check username/password in camera config
cameras:
  - id: "problem_camera"
    protocol: "onvif"
    username: "admin"        # Verify correct username
    password: "correct_pass" # Verify correct password
```

#### Questões de Descoberta

**Docker Problema de Multicast**:
- **Problema**: WS-Discovery não funciona em contêineres Docker
- **Solução**: Usar HTTP Sonda ou configuração manual

**Solução de Rede Host**:
```yaml
# docker-compose.yml with host network
services:
  aglus-nvr:
    network_mode: host  # Enables multicast
    ports:
      - "9090:9090"
```

**Solução Manual da Sonda**:
```bash
curl -X POST http://localhost:9090/api/onvif/probe \
  -H "Content-Type: application/json" \
  -d '{"ip": "192.168.1.100", "port": 80}'
```

#### Operações sem apoio

**Sintoma**: erro `501 Not Implemented`

**Causas**:
- A câmera não suporta ONVIF solicitado
- O recurso requer uma versão específica de firmware
- Diferenças na implementação do fabricante das câmeras

**Soluções**:
```bash
# Check supported capabilities
curl -X GET http://localhost:9090/api/cameras/{id}/onvif/capabilities \
  -H "Authorization: Bearer your-token"

# Find alternative configuration
# Use camera's native interface for unsupported features
```

#### Tempos de Conexão

**Soluções**:
```bash
# Test camera network connectivity
ping 192.168.1.100

# Check firewall rules
sudo ufw status

# Test ONVIF endpoint directly
curl --connect-timeout 5 http://192.168.1.100/onvif/device_service
```

### Docker Limitações

#### Limitação de Descoberta WS

**Problema**: a rede bridge padrão da Docker bloqueia o tráfego multicast (239.255.255.250:3702)

**Soluções**:

1. **Networking de Anfitrião** (Recomendado):
   ```yaml
   services:
     aglus-nvr:
       network_mode: host
       ports:
         - "9090:9090"
   ```

2. **Sonda Manual** (Funciona em qualquer rede):
   ```bash
   # In Web UI, use "Manual Probe" section
   # Or use API endpoint
   curl -X POST http://localhost:9090/api/onvif/probe \
     -d '{"ip": "192.168.1.100"}'
   ```

3. **Adição Manual de Câmera**:
   ```yaml
   cameras:
     - id: "manual_camera"
       protocol: "onvif"
       url: "http://192.168.1.100:80/onvif/device_service"
       username: "admin"
       password: "password"
   ```

#### Configuração da Rede

**Docker Mapeamento de Portas**:
```yaml
services:
  aglus-nvr:
    ports:
      - "9090:9090"        # Web UI
      - "2121:2121"        # FTP
      - "2122-2140:2122-2140"  # FTP passive
```

## Limitações Conhecidas

### Problemas no formato do snapshot
- **Formato Nativo**: Retorna ao formato nativo da câmera (geralmente JPEG)
- **Compatibilidade do Navegador**: Pode não ser visualizável em todos os navegadores
- **Resolução**: A resolução nativa varia de câmera para câmera
- **Recomendação**: Use RTSP/HTTP JPEG para formato consistente

### Suporte ao Serviço de Eventos Varia
- **Dependente da Câmera**: Apenas modelos específicos suportam ONVIF Serviço de Eventos
- **Firmware Necessário**: Frequentemente requer uma versão específica de firmware
- **Diferenças entre fabricantes**: As implementações variam entre marcas

### Suporte ao Gerenciamento de Dispositivos
- **Disponibilidade Limitada**: Nem todas as câmeras suportam gerenciamento de dispositivos
- **Câmera de Teste OV5647**: Capacidades limitadas de gerenciamento de dispositivos
- **Mudanças na rede**: Pode exigir reinício da câmera

### ONVIF Compatibilidade de Perfil
- **Perfil S**: Totalmente suportado (streaming de vídeo, PTZ)
- **Perfil T**: Parcialmente suportado (eventos de segurança)
- **Perfil G**: Suporte limitado (análises)
- **Pergunta de perfil**: Suporte básico (PTZ avançado)

### Docker Limitações
- **Multicast Bloqueado**: WS-Discovery não funciona na rede padrão Docker
- **Requisitos de Rede**: Pode precisar de rede host para descoberta
- **Conflitos de Porta**: Garantir que os portos não entrem em conflito com os serviços anfitriões

### Limitações específicas de câmeras
- **Variações de firmware**: Diferentes implementações entre fabricantes
- **Extensões de Protocolo**: Extensões de ONVIF específicas de fornecedores não suportadas
- **Métodos de Autenticação**: Algumas câmeras usam autenticação não padrão

## Comportamento da Câmera de Teste

### Câmera Raspberry Pi OV5647
- **Controle PTZ**: Pan/tilt limitado, zoom básico
- **Configurações de Imagem**: As mudanças podem não persistir durante reiniciações
- **Formato de Snapshot**: formato JPEG, consistente
- **Serviço de Eventos**: Não suportado
- **Gerenciamento de Dispositivos**: Apenas configuração básica

### Resultados Gerais dos Testes
- **Descoberta**: Funciona de forma confiável com HTTP Sonda
- **Streaming**: formato H.264, boa qualidade
- **PTZ**: Funcional com controles padrão
- **Configuração**: A maioria das configurações persiste, algumas exigem reinicialização da câmera
- **Rede**: Estável em Raspberry Pi 3B com armazenamento USB externo

## Referência API

### Pontos Finais de Descoberta
- `POST /api/onvif/probe` - HTTP Probe para IP específico
- `POST /api/onvif/discover` - WS-Discovery multicast
- `GET /api/onvif/discover/{ip}` - Detalhes do dispositivo

### Endpoints em nível de câmera
- `GET /api/cameras/{id}/onvif/profiles` - Perfis de mídia
- `GET /api/cameras/{id}/onvif/capabilities` - Capacidades do dispositivo

### Pontos Finais PTZ
- `POST /api/cameras/{id}/ptz/move` - Move PTZ
- `POST /api/cameras/{id}/ptz/stop` - Parar o PTZ
- `GET /api/cameras/{id}/ptz/status` - Status PTZ
- `GET /api/cameras/{id}/ptz/presets` - Presets de lista
- `POST /api/cameras/{id}/ptz/presets` - Criar preset
- `POST /api/cameras/{id}/ptz/presets/{token}/goto` - Go para predefinir
- `DELETE /api/cameras/{id}/ptz/presets/{token}` - Excluir preset

### Pontos Finais de Imagem
- `GET /api/cameras/{id}/imaging/settings` - Obter configurações
- `PUT /api/cameras/{id}/imaging/settings` - Atualizar configurações
- `GET /api/cameras/{id}/imaging/options` - Consiga campos de apoio

### Snapshot Endpoints
- `GET /api/cameras/{id}/snapshot/uri` - Obter o URI do snapshot
- `GET /api/cameras/{id}/snapshot` - Obter uma foto

### Endpoints de Gerenciamento de Dispositivos
- `POST /api/cameras/{id}/onvif/reboot` - Reiniciar o dispositivo
- `GET /api/cameras/{id}/onvif/network` - Obter interfaces de rede
- `PUT /api/cameras/{id}/onvif/network` - Definir a configuração da rede
- `GET /api/cameras/{id}/onvif/users` - Lista de usuários
- `POST /api/cameras/{id}/onvif/users` - Criar usuários
- `DELETE /api/cameras/{id}/onvif/users` - Excluir usuários

## Recursos de Apoio

### Documentação
- [AglusNVR Começando](./getting-started.md)
- [AglusNVR Guia de Configuração](./configuration.md)
- [AglusNVR Referência da API](./api/README.md)

### Apoio à comunidade
- GitHub Questões: [AglusNVR Questões](https://github.com/mms1688/AglusNVR/issues)
- Discussões: [AglusNVR Discussões](https://github.com/mms1688/AglusNVR/discussions)

### ONVIF Recursos
- ONVIF Site Oficial: https://www.onvif.org/
- ONVIF Gerenciador de Dispositivos: https://www.onvif.org/Downloads/ONVIF-DM-Software.zip
- ONVIF Documentação: https://www.onvif.org/resources/

---

Este guia oferece uma cobertura abrangente da integração ONVIF com AglusNVR. Para modelos específicos de câmeras, verifique a documentação do fabricante para ONVIF capacidades e limitações.