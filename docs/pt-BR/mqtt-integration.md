# MQTT Integração

AglusNVR suporta gatilhos de gravação baseados em MQTT para automação residencial inteligente e gravação orientada a eventos. Quando uma mensagem MQTT é recebida, o sistema pode começar a gravar em uma câmera específica por um período configurável.

## Visão geral

- **Protocolo**: MQTT (Transporte de Telemetria em Fila de Mensagens)
- **Padrão do Tópico**: `{prefix}/trigger/{camera_id}`
- **Carga útil**: JSON com campo `action`
- **Ações**: `record`, `stop`, `snapshot`
- **Reconexão automática**: Embutida com retrocesso exponencial

## Configuração

### Configuração Básica

```yaml
mqtt:
  broker_url: "tcp://192.168.1.100:1883"
  client_id: "aglus-nvr"
  topic_prefix: "aglus"
  username: "mqtt_user"
  password: "mqtt_password"
```

### Opções de configuração

| Campo | Obrigatório | Tipo | Padrão | Descrição |
|-------|----------|------|---------|-------------|
| `broker_url` | Sim | string | - | MQTT endereço do corretor (por exemplo, `tcp://192.168.1.100:1883`) |
| `client_id` | Sim | string | - | ID de cliente único para MQTT conexão |
| `topic_prefix` | Sim | string | - | Prefixo para tópicos de gatilho (por exemplo, `aglus`) |
| `username` | Não | string | - | MQTT nome de usuário (se o corretor exigir autorização) |
| `password` | Não | string | - | MQTT senha (se o corretor exigir autorização) |

### Configuração de Exemplo

```yaml
mqtt:
  broker_url: "tcp://mqtt.example.com:1883"
  client_id: "aglus-nvr-home"
  topic_prefix: "home/security"
  username: "smart_home_user"
  password: "secure_password_123"
```

## Uso

### MQTT Mensagens

#### Gravação de Gatilho

Comece a gravar em uma câmera específica por um período determinado:

```json
{
  "action": "record"
}
```

**Tópico**: `home/security/trigger/front-door`  
**Mensagem**: `{"action": "record"}`

**Tópico**: `home/security/trigger/backyard`  
**Mensagem**: `{"action": "record"}`

#### Pare a gravação

Pare de gravar em uma câmera específica:

```json
{
  "action": "stop"
}
```

**Tópico**: `home/security/trigger/front-door`  
**Mensagem**: `{"action": "stop"}`

#### Snapshot de Gatilho

Tire uma foto de uma câmera específica:

```json
{
  "action": "snapshot"
}
```

**Tópico**: `home/security/trigger/front-door`  
**Mensagem**: `{"action": "snapshot"}`

### Exemplos de Integração

#### Assistente Residencial

```yaml
# Home Assistant MQTT Automation
- alias: Motion Detection - Front Door
  trigger:
    - platform: mqtt
      topic: "zigbee2mqtt/front-door-motion/occupancy"
      payload: "ON"
  action:
    - service: mqtt.publish
      data:
        topic: "home/security/trigger/front-door"
        payload: '{"action": "record"}'
        retain: false
```

#### Node-RED

```json
// Node-RED Flow Example
[
  {"id": "1", "type": "mqtt in", "topic": "zigbee2mqtt/occupancy/+", "z": "2"},
  {"id": "2", "type": "switch", "name": "Motion Detection", "property": "payload", "propertyType": "msg", "rules": [{"t": "eq", "v": "ON"}], "checkall": "true", "outputs": 1},
  {"id": "3", "type": "function", "name": "Get Camera ID", "func": "const camera = msg.topic.split('/')[1]; msg.camera = camera; return msg;", "outputs": 1},
  {"id": "4", "type": "function", "name": "Build MQTT Message", "func": "msg.topic = `home/security/trigger/${msg.camera}`; msg.payload = '{\"action\": \"record\"}'; return msg;", "outputs": 1},
  {"id": "5", "type": "mqtt out", "topic": "home/security/trigger/+", "qos": "0", "retain": "false"}
]
```

#### ESP8266/ESP32

```cpp
// ESP8266 Motion Detection Example
#include <PubSubClient.h>
#include <WiFi.h>

const char* mqtt_server = "192.168.1.100";
const char* topic_prefix = "home/security";

void setup() {
  pinMode(D1, INPUT); // PIR sensor pin
  WiFi.begin("your_ssid", "password");
  
  client.setServer(mqtt_server, 1883);
}

void loop() {
  if (digitalRead(D1) == HIGH) {
    // Motion detected, trigger recording
    String payload = "{\"action\": \"record\"}";
    String topic = String(topic_prefix) + "/trigger/front-door";
    client.publish(topic.c_str(), payload.c_str());
    delay(30000); // Wait 30 seconds before next trigger
  }
  delay(1000);
}
```

#### Python Script

```python
# Python MQTT Publisher Example
import paho.mqtt.client as mqtt
import json
import time

def on_connect(client, userdata, flags, rc):
    print("Connected to MQTT broker")

client = mqtt.Client("aglus-nvr-trigger")
client.username_pw_set("mqtt_user", "mqtt_password")
client.connect("192.168.1.100", 1883)

# Trigger recording from Python
def trigger_recording(camera_id, action="record"):
    topic = f"home/security/trigger/{camera_id}"
    payload = json.dumps({"action": action})
    client.publish(topic, payload)
    print(f"Triggered {action} for {camera_id}")

# Example usage
trigger_recording("front-door", "record")
time.sleep(30)  # Record for 30 seconds
trigger_recording("front-door", "stop")
```

### Monitoramento

#### Logs do Sistema

Verifique MQTT status da conexão e as mensagens:

```bash
# View system logs
journalctl -u aglus-nvr -f | grep mqtt

# Docker logs
docker logs -f aglus-nvr | grep mqtt
```

#### Exame de saúde

Verifique MQTT status do cliente:

```bash
curl -u admin:password http://localhost:9090/api/system/health
```

Fique atento a `"mqtt": {"status": "ok"}` na resposta.

### Tratamento de Erros

#### Questões Comuns

**Conexão falhada**
```
WARN: mqtt connection failed: connection refused
```
- **Solução**: Verifique a URL do corretor, certifique-se de que o corretor está em execução
- **Depuração**: Teste com `mosquitto_pub -h 192.168.1.100 -t test -m hello`

**Autenticação Falhada**
```
WARN: mqtt authentication failed
```
- **Solução**: Verificar nome de usuário e senha na configuração
- **Depuração**: Teste com credenciais: `mosquitto_pub -u user -P pass -h broker -t test -m hello`

**Mensagem Não Processada**
```
WARN: invalid mqtt message payload format
```
- **Solução**: Garantir que JSON carga útil contenha `action` campo
- **Depuração**: Validar a carga útil com JSON validador

### Configuração Avançada

#### Múltiplos Tópicos

```yaml
mqtt:
  broker_url: "tcp://192.168.1.100:1883"
  client_id: "aglus-nvr"
  topic_prefix: "security"
```

Múltiplas câmeras podem ser acionadas no mesmo corretor:

```
security/trigger/camera1
security/trigger/camera2
security/trigger/camera3
```

#### Valores Mobiliários de Corretor

```yaml
mqtt:
  broker_url: "ssl://mqtt.example.com:8883"
  client_id: "aglus-nvr"
  topic_prefix: "home/security"
  username: "secure_user"
  password: "complex_password"
  # For SSL, certificates must be properly configured
  ca_cert: "/path/to/ca.crt"
  client_cert: "/path/to/client.crt"
  client_key: "/path/to/client.key"
```

### Integração com Outros Sistemas

#### Zigbee2MQTT

```yaml
# Zigbee2MQTT Integration
mqtt:
  broker_url: "tcp://192.168.1.100:1883"
  client_id: "aglus-nvr"
  topic_prefix: "zigbee2mqtt"

# Camera trigger from motion sensor
```

#### Automação do Home Assistant

```yaml
# Home Assistant automation to record when someone rings doorbell
- alias: Doorbell Recording
  trigger:
    - platform: mqtt
      topic: "zigbee2mqtt/doorbell/bell_pressed"
      payload: "ON"
  action:
    - service: mqtt.publish
      data:
        topic: "zigbee2mqtt/trigger/doorbell"
        payload: '{"action": "record", "duration": 60}'
        retain: false
```

### Melhores Práticas

1. **Organização do Tema**: Use prefixos de tópicos significativos para organizar diferentes áreas
2. **Validação de Carga Útil**: Sempre incluir o campo `action` em JSON cargas úteis
3. **Confiabilidade da Conexão**: Configurar o corretor para reconexão automática
4. **Tratamento de erros**: Implementar lógica de retentativas em aplicações cliente
5. **Retenção de Mensagens**: Use políticas apropriadas de retenção de mensagens no corretor
6. **Segurança**: Use senhas fortes e SSL/TLS para implantações em produção

### Solução de problemas

#### Problemas de conexão

1. Verifique se o corretor está acessível:
   ```bash
   ping 192.168.1.100
   nc -zv 192.168.1.100 1883
   ```

2. Teste MQTT conexão manualmente:
   ```bash
   mosquitto_sub -h 192.168.1.100 -t "test" -u user -P pass
   mosquitto_pub -h 192.168.1.100 -t "test" -m "hello" -u user -P pass
   ```

#### Problemas de entrega de mensagens

1. Verifique os logs para erros de processamento:
   ```bash
   journalctl -u aglus-nvr -f | grep mqtt
   ```

2. Verifique a correspondência de tópicos:
   ```bash
   # Test topic matching
   echo '{"action": "record"}' | mosquitto_pub -h 192.168.1.100 -t "security/trigger/camera1" -u user -P pass
   ```

#### Validação de Configuração

Validar o arquivo de configuração:
```bash
./aglus-nvr -config aglus-nvr.yaml --validate
```

#### Modo Depuração

Ative o registro de depuração:
```yaml
mqtt:
  broker_url: "tcp://192.168.1.100:1883"
  client_id: "aglus-nvr"
  topic_prefix: "home/security"

observability:
  log_level: "debug"
```