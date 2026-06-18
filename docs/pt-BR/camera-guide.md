#KJ|# Guia de Compatibilidade de Marcas de Câmeras
#KM|
#RW|AglusNVR suporta uma ampla variedade de câmeras IP por meio de vários protocolos, incluindo RTSP (H.264/H.265/MJPEG), HTTP JPEG e ONVIF. Este guia fornece informações abrangentes de compatibilidade para marcas populares de câmeras, incluindo protocolos suportados, exemplos de configuração e dicas de solução de problemas.
#SY|
#BV|#KM|**ONVIF Integração**: Para suporte abrangente de câmeras ONVIF, métodos de descoberta, controle PTZ e solução de problemas, consulte o [Guia ONVIF](./onvif-guide.md).
#BV|#KM|
#PX|## Quick Start (Top 3 Marcas)
#JW|
#QW|### Hikvision
#HX|
#VY|'''yaml
#BB|câmeras:
#RW|  - id: "hikvision_front_door"
#SX|    nome: "Porta da Frente - Hikvision"
#MK|    Protocolo: "RTSP"
#BB|    Codificação: "H264"
#HM|    URL: "rtsp://admin:password123@192.168.1.100:554/Streaming/Channels/101"
#SJ|    ativado: true
#KB|'''
#XS|
#YJ|1. **Acessar Câmera**: Encontre o endereço IP da câmera via Hikvision iVMS-4200 ou interface web
#VT|2. **Ativar RTSP**: Garantir que RTSP streaming esteja ativado na interface web da câmera (geralmente em Network → Advanced)
#RW|3. **Configurar**: Use a URL acima com o IP e credenciais da sua câmera
#QQ|
#XQ|### Dahua
#BX|
#VY|'''yaml
#BB|câmeras:
#RW|  - id: "dahua_driveway"
#SX|    nome: "Entrada - Dahua"
#MK|    Protocolo: "RTSP"
#BB|    Codificação: "H264"
#HM|    URL: "rtsp://admin:admin@192.168.1.101:554/cam/realmonitor?channel=1&subtype=0"
#SJ|    ativado: true
#KB|'''
#XS|
#YJ|1. **Acessar Câmera**: Encontre o endereço IP da câmera via Dahua SmartPSS ou interface web
#VT|2. **Ativar RTSP**: Ativar RTSP streaming nas configurações da câmera (geralmente em Configuração → Rede → Stream)
#RW|3. **Configurar**: Use a URL acima com o IP e credenciais da sua câmera
#QQ|
#XQ|### Uniview
#VX|
#VY|'''yaml
#BB|câmeras:
#RW|  - id: "uniview_parking"
#SX|    nome: "Estacionamento - Uniview"
#MK|    Protocolo: "RTSP"
#BB|    Codificação: "H264"
#HM|    URL: "rtsp://admin:123456@192.168.1.102:554/unicast/c1/s0/live"
#SJ|    ativado: true
#KB|'''
#XS|
#YJ|1. **Acessar Câmera**: Encontre o endereço IP da câmera via Uniview iViewer ou interface web
#VT|2. **Ativar RTSP**: Ativar RTSP streaming nas configurações da câmera (geralmente em Network → Streaming)
#RW|3. **Configurar**: Use a URL acima com o IP e credenciais da sua câmera
#QQ|
#QX|## Visão Geral da Compatibilidade
#MB|
#JW|| Tier | Nível de Suporte | Protocolo | Marcas | Notas |
#SX||------|---------------|----------|--------|-------|
#RW|| **Suporte total** | ✅ Detecção automática + PTZ | RTSP + ONVIF | Hikvision, Dahua, Uniview, Axis, Bosch, Vivotek, Hanwha, Amcrest, Reolink | Melhor experiência, recursos completos |
#BB|| **Configuração manual** | ⚠️ Somente RTSP, ONVIF limitado | Apenas RTSP | TP-Link VIGI, EZVIZ, ANNKE, Lorex, Swann, Speco | Configuração manual necessária |
#MK|| **Limitado/Especial** | 🔧 Necessário manuseio especial | Vários | Xiaomi, BESDER, Genérico, Wyze | Configuração personalizada ou limitações |
#BW|
#YY|## Suporte total (ONVIF + RTSP)
#WV|
#XS|### 1. Hikvision
#JZ|
#MH|**Modelos**: DS-2CD2T42WDG1-I, DS-2CD2143G0-I, DS-2CD2343G0-I
#KQ|
#TM|#### URLs RTSP:
#VW|- Fluxo principal: `rtsp://user:pass@ip:554/Streaming/Channels/101`
#NV|- Transmissão secundária: `rtsp://user:pass@ip:554/Streaming/Channels/102`
#XS|- Canal de áudio: `rtsp://user:pass@ip:554/Streaming/Channels/101_1`
#JQ|
#HT|#### Configuração:
#VY|```yaml
#BB|câmeras:
#RW|  - id: "hikvision_main"
#SX|    nome: "Hikvision Main Stream"
#MK|    protocolo: "rtsp"
#BB|    codificação: "h264"
#HM|    url: "rtsp://admin:password123@192.168.1.100:554/Streaming/Channels/101"
#SJ|    habilitado: verdadeiro
#KB|```
#XS|
#YJ|#### Credenciais padrão:
#BK|- Nome de usuário: `admin`
#KQ|- Senha: `password123` (padrão, pode variar)
#MS|
#MT|#### Problemas conhecidos:
#BK|- Alguns modelos exigem a ativação do RTSP primeiro na interface web
#KQ|- ONVIF pode não funcionar em firmware anterior a V5.3.x
#MS|- Streams de áudio às vezes separados do vídeo
#KQ|
#YX|### 2. Dahua
#POR|
#JB|**Modelos**: IPC-HFW1237S-Z, IPC-HDW2831R-ZS, IPC-HFW5442E-Z
#QW|
#TM|#### URLs RTSP:
#VW|- Canal 1: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0`
#NV|- Canal 2: `rtsp://user:pass@ip:554/cam/realmonitor?channel=2&subtype=0`
#XS|- Fluxo de áudio: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=1`
#JQ|
#HT|#### Configuração:
#VY|```yaml
#BB|câmeras:
#RW|  - id: "dahua_main"
#SX|    nome: "Córrego Principal Dahua"
#MK|    protocolo: "rtsp"
#BB|    codificação: "h264"
#HM|    url: "rtsp://admin:admin@192.168.1.101:554/cam/realmonitor?channel=1&subtype=0"
#SJ|    habilitado: verdadeiro
#KB|```
#XS|
#YJ|#### Credenciais padrão:
#BK|- Nome de usuário: `admin`
#KQ|- Senha: `admin` (padrão)
#MS|
#MT|#### Problemas conhecidos:
#BK>- Alguns modelos usam URLs de substream diferentes (`subtype=1` para substream)
#KQ>- O áudio pode precisar de configuração separada
#MS>- A descoberta de ONVIF pode demorar mais do que RTSP direta
#KQ>
#YX>### 3. Uniview
#POR>
#JB>**Modelos**: U-AI1208LBF, U-AI1208LBFZ, U-CV3208ERBU
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/unicast/c1/s0/live`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/unicast/c1/s1/live`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/unicast/c1/s0/live`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “uniview_main”
#SX> nome: "Fluxo principal Uniview"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:123456@192.168.1.102:554/unicast/c1/s0/live"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `123456` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos exigem que RTSP esteja habilitado nas configurações da câmera
#KQ>- Os fluxos de áudio podem ser separados do vídeo
#MS>- A porta ONVIF pode variar (geralmente 80, mas verifique as configurações da câmera)
#KQ>
#YX>### 4. Eixo
#POR>
#JB>**Modelos**: M3045-V, M3054-V, M3065-V
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://root:pass@ip:554/axis-media/media.amp`
#NV>- Alta qualidade: `rtsp://root:pass@ip:554/axis-media/media.amp?videoType=1`
#XS>- Fluxo de áudio: `rtsp://root:pass@ip:554/axis-media/media.amp?videoType=3`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "axis_main"
#SX> nome: "Fluxo principal do eixo"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://root:password@192.168.1.103:554/axis-media/media.amp"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `root`
#KQ>- Senha: `pass` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos requerem métodos de autenticação específicos
#KQ>- Streams de áudio podem precisar de configuração separada
#MS>- As atualizações de firmware da câmera podem alterar os endpoints RTSP
#KQ>
#YX>### 5. Bosch
#POR>
#JB>**Modelos**: FLEXIDOME 5000I, MIC IP, DINION 6000I
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo de vídeo 1: `rtsp://user:pass@ip:554/rtp_video1`
#NV>- Fluxo de vídeo 2: `rtsp://user:pass@ip:554/rtp_video2`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/rtp_audio1`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “bosch_main”
#SX> nome: "Bosch Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:12345@192.168.1.104:554/rtp_video1"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `12345` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos usam intervalos de portas diferentes para RTSP
#KQ>- O áudio pode exigir configuração separada
#MS>- A configuração do ONVIF pode ser complexa
#KQ>
#YX>### 6. Vivotek
#POR>
#JB>**Modelos**: IB8369, IP8332-H, FD8166
#QW>
#TM>#### URLs RTSP:
#VW>- Transmissão ao vivo: `rtsp://user:pass@ip:554/live.sdp`
#NV>- Fluxo principal: `rtsp://user:pass@ip:554/h264/ch1/main/av_stream`
#XS>- Transmissão secundária: `rtsp://user:pass@ip:554/h264/ch1/sub/av_stream`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "vivotek_main"
#SX> nome: "Fluxo principal Vivotek"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://root:123456@192.168.1.105:554/live.sdp"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `root`
#KQ>- Senha: `123456` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos requerem caminhos RTSP específicos
#KQ>- Os fluxos de áudio podem não funcionar com todos os modelos
#MS>- A descoberta ONVIF pode precisar de configuração manual
#KQ>
#YX>### 7. Hanwha
#POR>
#JB>**Modelos**: XNV-6081R, XND-6081R, XNV-8081R
#QW>
#TM>#### URLs RTSP:
#VW>- Perfil 1: `rtsp://user:pass@ip:554/profile1/media.smp`
#NV>- Perfil 2: `rtsp://user:pass@ip:554/profile2/media.smp`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/profile1/audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “hanwha_main”
#SX> nome: "Hanwha Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:123456@192.168.1.106:554/profile1/media.smp"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `123456` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos usam números de perfil diferentes
#KQ>- Streams de áudio podem exigir configuração separada
#MS>- A porta ONVIF varia de acordo com o modelo (verifique a interface web da câmera)
#KQ>
#YX>### 8. Amcrest
#POR>
#JB>**Modelos**: IP8M-T1179EW, IP5M-T1177EW, IP2M-841EB
#QW>
#TM>#### URLs RTSP:
#VW>- Canal 1: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0`
#NV>- Canal 2: `rtsp://user:pass@ip:554/cam/realmonitor?channel=2&subtype=0`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=1`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "amcrest_main"
#SX> nome: "Fluxo principal Amcrest"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:admin@192.168.1.107:554/cam/realmonitor?channel=1&subtype=0"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `admin` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Semelhante às câmeras Dahua, mas com firmware diferente
#KQ>- Alguns modelos usam subtipos de maneira diferente
#MS>- A descoberta de ONVIF funciona, mas pode ser lenta
#KQ>
#YX>### 9. Vincular novamente
#POR>
#JB>**Models**: RLC-810A, RLC-510A, RLC-823A
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/h264Preview_01_main`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/h264Preview_01_sub`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/h264Preview_01_main`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW>  - id: "reolink_main"
#SX>    name: "Reolink Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:123456@192.168.1.108:554/h264Preview_01_main"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `123456` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Alguns modelos requerem autenticação específica do Reolink
#KQ>- Streams de áudio podem precisar de configuração separada
#MS>- A descoberta ONVIF funciona, mas a porta pode ser diferente (8000)
#KQ>
#YX>## Manual Setup (RTSP Only)
#POR>
#JB>### 10. TP-Link VIGI
#QW>
#JM>**Models**: TC-VR303, TC-VR307, TC-V304GS
#SX>
#TM>#### URLs RTSP:
#VW>- Stream 1: `rtsp://user:pass@ip:554/stream1`
#NV>- Stream 2: `rtsp://user:pass@ip:554/stream2`
#XS>- Transmissão secundária: `rtsp://user:pass@ip:554/stream1_sub`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW>  - id: "tplink_vigi"
#SX>    name: "TP-Link VIGI"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:admin@192.168.1.109:554/stream1"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `admin` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Suporte limitado a ONVIF (pode não ser descoberto automaticamente)
#KQ>- Alguns modelos requerem configuração manual de URL
#MS>- Audio streams not always available
#KQ>
#YX>### 11. EZVIZ
#POR>
#JB>**Models**: CS-CV248, CS-CV228, CS-CV208
#QW>
#TM>#### URLs RTSP:
#VW>- Canal 1: `rtsp://user:pass@ip:554/h264/ch1/main/av_stream`
#NV>- Canal 2: `rtsp://user:pass@ip:554/h264/ch2/main/av_stream`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/h264/ch1/main/audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “ezviz_main”
#SX>    name: "EZVIZ Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:verification_code@192.168.1.110:554/h264/ch1/main/av_stream"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: Código de verificação do adesivo da câmera
#MS>
#MT>#### Problemas conhecidos:
#BK>- Sem suporte para ONVIF na maioria dos modelos
#KQ>- A senha muda frequentemente (com base em adesivos)
#MS>- Alguns modelos requerem atualizações de firmware para suporte RTSP
#KQ>
#YX>### 12. ANNKE
#POR>
#JB>**Modelos**: 8CH H.265, 4CH H.264, 16CH NVR
#QW>
#TM>#### URLs RTSP:
#VW>- Canal 1: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=0`
#NV>- Canal 2: `rtsp://user:pass@ip:554/cam/realmonitor?channel=2&subtype=0`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/cam/realmonitor?channel=1&subtype=1`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "annke_main"
#SX> nome: "Transmissão principal ANNKE"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:admin123@192.168.1.111:554/cam/realmonitor?channel=1&subtype=0"
#SJ> ativado: verdadeiro
#KB>```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `admin123` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Dahua OEM, formato de URL semelhante ao Dahua
#KQ>- O suporte ONVIF varia de acordo com o modelo
#MS>- Alguns modelos requerem versões específicas de firmware
#KQ>
#YX>### 13. Lorex
#POR>
#JB>**Modelos**: LNB4432, LNC22852B, LNE8832
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/stream`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/stream_sub`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/stream_audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "lorex_main"
#SX> nome: "Lorex Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:000000@192.168.1.112:554/stream"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `000000` ou `123456` (varia conforme modelo)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Dahua/FLIR OEM, formato RTSP varia de acordo com o modelo
#KQ>- Suporte ONVIF inconsistente entre modelos
#MS>- Alguns modelos requerem etapas de configuração específicas
#KQ>
#YX>### 14. Cisne
#POR>
#JB>**Modelos**: SWPRO-890MS, SWPRO-882MS, SWPRO-848MS
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/stream`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/stream_sub`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/stream_audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “swann_main”
#SX> nome: "Swann Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:123456@192.168.1.113:554/stream"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `123456` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Semelhante ao Lorex, varia de acordo com o modelo
#KQ>- Suporte ONVIF inconsistente
#MS>- Alguns modelos requerem atualizações de firmware
#KQ>
#YX>### 15. Tecnologias Especográficas
#POR>
#JB>**Modelos**: C128-HV, C828-HV, C168-HV
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/stream`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/stream_sub`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/stream_audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "speco_main"
#SX> nome: "Speco Main Stream"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:1234@192.168.1.114:554/stream"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Credenciais padrão:
#BK>- Nome de usuário: `admin`
#KQ>- Senha: `1234` (padrão)
#MS>
#MT>#### Problemas conhecidos:
#BK>- Suporte Good ONVIF, mas o formato RTSP varia
#KQ>- Alguns modelos requerem configuração manual
#MS>- A documentação pode estar desatualizada
#KQ>
#YX>## Casos limitados/especiais
#POR>
#JB>### 16. Xiaomi
#QW>
#JM>**Modelos**: C200, C300, Xiaofang, Dafang
#SX>
#TM>#### Configuração especial:
#VW>- Use a integração Xiaomi integrada do AglusNVR, NÃO RTSP diretamente
#NV>- Configurar via UI da Web → Descoberta de dispositivo Xiaomi
#XS>- Autenticação via serviços em nuvem Xiaomi
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>xiaomi:
#RW> ativado: verdadeiro
#SX> ID_do_usuário: "123456789"
#MK> token: "seu_passToken_here"
#BB>  region: "cn"
#HM|  
#BB|câmeras:
#RW> - id: "xiaomi_c200"
#SX> nome: "Xiaomi C200"
#MK> protocolo: "xiaomi"
#BB> codificação: "h264"
#HM|    did: "device_id_here"
#SJ|    vendor: "cs2"
#KB|    habilitado: verdadeiro
#BB|```
#XS>
#YJ>#### Problemas conhecidos:
#BK>- Não é compatível diretamente com RTSP
#KQ>- Requer conectividade em nuvem Xiaomi
#MS>- Somente protocolo P2P, sem acesso IP direto
#KQ>
#YX>### 17. BESDER
#POR>
#JB>**Modelos**: BCS-SR-505, BCS-SR-608, BCS-SR-702
#QW>
#TM>#### URLs RTSP:
#VW>- Fluxo principal: `rtsp://user:pass@ip:554/stream`
#NV>- Transmissão secundária: `rtsp://user:pass@ip:554/sub`
#XS>- Fluxo de áudio: `rtsp://user:pass@ip:554/audio`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "besder_main"
#SX> nome: "Transmissão principal BESDER"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:password@192.168.1.115:554/stream"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Problemas conhecidos:
#BK>- Geralmente compatível com ONVIF, mas a qualidade varia
#KQ>- Formato RTSP não padronizado entre modelos
#MS>- Alguns modelos apresentam qualidade de vídeo ruim em relação ao RTSP
#KQ>
#YX>### 18. RTSP genérico
#POR>
#JB>**Modelos**: Várias marcas chinesas, câmeras de marca branca
#QW>
#TM>#### URLs RTSP:
#VW>- Formatos comuns: `rtsp://user:pass@ip:554/stream`
#NV>- Formatos alternativos: `rtsp://user:pass@ip:554/live`
#XS>- Outra opção: `rtsp://user:pass@ip:554/h264`
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "generic_rtsp"
#SX> nome: "Câmera RTSP genérica"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:password@192.168.1.116:554/stream"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Problemas conhecidos:
#BK>- O formato RTSP varia muito de acordo com o fabricante
#KQ>- Tentativa e erro necessários para formato de URL
#MS>- A descoberta de ONVIF pode não funcionar
#KQ>
#YX>### 19. ONVIF genérico
#POR>
#JB>**Modelos**: Várias câmeras compatíveis com ONVIF
#QW>
#TM>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> – id: “generic_onvif”
#SX> nome: "Câmera ONVIF genérica"
#MK> protocolo: "onvif"
#BB> url: "http://192.168.1.117:80/onvif/device_service"
#HM|    nome de usuário: "admin"
#SJ|    senha: "senha"
#KB|    habilitado: verdadeiro
#BB|```
#XS>
#YJ>#### Problemas conhecidos:
#BK>- Use o recurso ONVIF Scan da Aglus para descoberta automática
#KQ>- Pode exigir configuração manual se a descoberta falhar
#MS>- Os perfis ONVIF podem variar entre os modelos
#KQ>
#YX>### 20. Wyze
#POR>
#JB>**Modelos**: Wyze Cam v3, Wyze Cam Outdoor, Wyze Cam Pan
#QW>
#TM>#### Configuração especial:
#VW>- Suporte limitado a RTSP via firmware personalizado
#NV>- Requer garfo Wyze RTSP ou equivalente
#XS>- Principalmente baseado em nuvem, não é ideal para NVR
#JQ>
#HT>#### Configuração:
#VY>```yaml
#BB>câmeras:
#RW> - id: "wyze_rtsp"
#SX> nome: "Fluxo Wyze RTSP"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:password@192.168.1.118:554/live"
#SJ> ativado: verdadeiro
#KB|```
#XS>
#YJ>#### Problemas conhecidos:
#BK>- Não é oficialmente suportado pela Wyze
#KQ>- Requer modificações específicas de firmware
#MS> - O desempenho pode ser ruim com firmware personalizado
#KQ>
#YX>## Dicas Gerais de Configuração
#BY>
#JB>### RTSP Teste de URL
#QW>
#JM>Antes de adicionar a AglusNVR, teste URLs RTSP com VLC ou FFPLAY:
#SX>
#BV>'''bash
#BB># Teste RTSP conexão
#RW>ffplay rtsp://admin:password@192.168.1.100:554/stream
#SX>
#BB># Teste HTTP JPEG
#RW>curl http://admin:password@192.168.1.101:8080/snapshot
#SX>
#BB># Verificar conectividade de rede de câmeras
#RW>ping 192.168.1.100
#SX>
#BB># Descoberta ONVIF Teste
#RW>nmap -p 80 192.168.1.102
#BB>'''
#XS>
#YJ>### Otimização de Desempenho
#BY>
#JB>Para Raspberry Pi usuários, otimize as configurações para recursos limitados:
#QW>
#VY>'yaml
#BB>câmeras:
#RW> - id: "optimized_camera"
#SX> nome: "Câmera Otimizada"
#MK> protocolo: "rtsp"
#BB> codificação: "h264"
#HM> url: "rtsp://admin:password@192.168.1.100:554/stream"
#SJ> ativado: verdadeiro
#KB|    # Otimize para Raspberry Pi
#RW> segment_duration: "30 e poucos anos"
#SX> hls_max_fps: 15
#RW> sample_interval: 2
#BB>'''
#XS>
#YJ>### Considerações de Rede
#BY>
#JB>- Garantir que câmeras e AglusNVR estejam na mesma rede
#QW> - Considere a segmentação de VLAN para segurança
#SX>- Use endereços IP estáticos para conexões confiáveis
#RW>- Monitorar o uso de largura de banda para múltiplas câmeras
#BB>
#YJ>### Melhores Práticas de Segurança
#BY>
#JB>- Alterar senhas padrão da câmera
#QW>- Use credenciais diferentes para cada câmera
#SX>- Ativar regras de firewall para restringir o acesso às câmeras
#RW> - Atualizações regulares de firmware para câmeras
#BB> - Considere HTTPS para interfaces web de câmeras
#BB>
#YX>## Solução de problemas
#BY>
#JB>### Questões comuns RTSP
#QW>
#JM>**"RTSP conexão falhou"**:
#SX>
#BV>'''bash
#BB># Verifique se a câmera está online
#RW>ping 192.168.1.100
#SX>
#BB># Teste RTSP manualmente
#RW>ffplay rtsp://admin:password@192.168.1.100:554/stream
#SX>
#BB># Verifique acessibilidade da porta da câmera
#RW>nc -ZV 192.168.1.100 554
#BB>'''
#XS>
#YJ>**"Nenhuma transmissão de vídeo disponível"**:
#BY>
#JB> - Verifique se RTSP está ativado nas configurações da câmera
#QW>- Verifique se a câmera requer autenticação
#SX>- Tente diferentes formatos de stream (principal/sub)
#RW> - URL de teste com VLC para confirmar que o fluxo funciona
#BB>
#YJ>### Questões de Descoberta ONVIF
#BY>
#JB>**Câmera não descoberta via ONVIF**:
#QW>
#BV>```yaml
#BB># Configuração manual do ONVIF
#RW>câmeras:
#SX> - id: "manual_onvif"
#RW> nome: "Câmera ONVIF Manual"
#RW> protocolo: "onvif"
#RW>url: "http://192.168.1.100:80/onvif/device_service"
#RW|    nome de usuário: "admin"
#RW|    senha: "senha"
#RW|    habilitado: verdadeiro
#BB>```
#XS>
#YJ>**Falha na autenticação ONVIF**:
#POR>
#JB>- Verifique a porta ONVIF (geralmente 80, mas varia)
#QW>- Verifique se a câmera suporta ONVIF
#SX>- Experimente diferentes métodos de autenticação
#RW>- Verifique a versão do firmware da câmera para suporte ONVIF
#BB>
#YJ>### Configuração de áudio
#POR>
#JB>**Sem áudio nas gravações**:
#QW>
#BV>```yaml
#BB># Habilitar áudio na configuração da câmera
#RW>câmeras:
#SX> - id: "câmera_com_áudio"
#RW> nome: "Câmera com Áudio"
#RW> protocolo: "rtsp"
#RW> codificação: "h264"
#RW> url: "rtsp://admin:password@192.168.1.100:554/stream"
#RW|    habilitado: verdadeiro
#RW|    # Configurações de áudio
#RW|    enable_audio: verdadeiro
#RW|    audio_codec: "aac" # ou pcm, g711
#RW|    taxa de bits de áudio: "128k"
#BB>```
#XS>
#YJ>**Problemas de sincronização de áudio**:
#POR>
#JB>- Verifique se o fluxo de áudio está separado do vídeo
#QW>- Ajuste as configurações de sincronização de áudio, se disponível
#SX>- Algumas câmeras não suportam áudio no stream RTSP
#RW>- Considere a gravação de áudio separada, se necessário
#BB>
#YX>## Recursos de suporte
#POR>
#JB>### Documentação
#QW>
#JM>- [Guia de configuração AglusNVR](./configuration.md)
- [Referência da API AglusNVR](./api/README.md)
#RW>- [AglusNVR Primeiros passos](./getting-started.md)
#BB>
#YJ>### Apoio da comunidade
#POR>
#JB>- Problemas GitHub: [Problemas AglusNVR](https://github.com/mms1688/AglusNVR/issues)
#QW>- Discussões: [Discussões AglusNVR](https://github.com/mms1688/AglusNVR/discussions)
#SX>- Discord: Junte-se ao nosso servidor da comunidade para obter ajuda
#BB>
#YJ>### Suporte Profissional
#POR>
#JB>- Suporte comercial disponível para usuários corporativos
#QW>- Contate-nos para integração de câmera personalizada
#SX>- Consulta no local disponível para grandes implantações
#BB>
#YX>## Ferramentas de descoberta de câmera
#POR>
#JB>### Gerenciador de dispositivos ONVIF
#QW>
#JM>Baixe e instale o [Gerenciador de dispositivos ONVIF](https://www.onvif.org/) para:
#SX>
#RW>- Descubra câmeras ONVIF em sua rede
#RW>- Obtenha informações detalhadas da câmera
#RW>- Teste a conformidade com ONVIF
#RW>- Baixe os recursos da câmera
#BB>
#YJ>### iSpy
#POR>
#JB>[iSpy](https://www.ispyconnect.com/) pode ajudar a descobrir câmeras e gerar URLs RTSP:
#QW>
#RW> - Descoberta automática de câmeras
#RW>- RTSP geração de URL
#RW> - Testando a compatibilidade de fluxos
#RW> - Gerenciamento de configuração de câmeras
#BB>
#YJ>### FFMPEG RTSP Testador de URL
#BY>
#JM>Crie um script simples para testar RTSP URLs:
#QW>
#BV>'''bash
#BB>#!/lixo/batida
#RW>
#RW># Função de URL RTSP Teste
#RW>test_rtsp_url() {
#RW> URL local="$1"
#RW> tempo de espera local=10
#RW>    
#RW> ecoam "Testing RTSP URL: $url"
#RW>    
#RW> # Teste com tempo de espera
#RW> timeout $timeout ffmpeg -i "$url" -t 1 -f null - 2>/dev/null && {
#RW> ecoa "✅ RTSP URL funciona: $url"
#RW> retorno 0
#RW> } || {
#RW> eco " ❌ RTSP URL falhou: $url"
#RW> retorno 1
#RW> }
#RW>}
#RW>
#RW># Exemplo de uso
#RW>test_rtsp_url "rtsp://admin:password@192.168.1.100:554/stream"
#RW>
#RW># Teste em lote múltiplas URLs
#RW>para IP em 192.168.1. {100..120}; faça
#RW> test_rtsp_url "rtsp://admin:password@$ip:554/stream"
#RW> feito
#BB>'''
#XS>
#YJ>### Ferramentas de Varredura de Rede
#BY>
#JB>Use estas ferramentas para encontrar câmeras na sua rede:
#QW>
#BV>'''bash
#RW>
#RW># Encontre ONVIF câmeras
#RW>nmap -p 80 --aberto 192.168.1.0/24 | grep -v "Escaneamento Nmap"
#RW>
#RW># Encontrar servidores RTSP
#RW>nmap -p 554 --aberto 192.168.1.0/24 | grep -v "Escaneamento Nmap"
#RW>
#RW># Encontre HTTP câmeras
#RW>nmap -p 80.8080 --aberto 192.168.1.0/24 | grep -v "Escaneamento Nmap"
#RW>
#RW># Descoberta rápida da câmera
#BB>sudo nmap -sV -p 554,80,8080 --aberto 192.168.1.0/24
#BB>'''
#XS>
#YJ>## Push Cameras (SRT / RTMP) — Ingesta Multi-Rede
#YJ>
#YJ>Diferente dos protocolos pull acima (RTSP/ONVIF/HTTP), onde o NVR disca **out** para a câmera, as câmeras **push** funcionam no sentido inverso: um publisher remoto (ffmpeg, OBS, um telefone ou outro NVR) empurra um stream **para** o NVR. Isso permite que você grave câmeras em uma **rede diferente** (outra LAN, na internet, atrás de NAT) sem VPN — desde que o editor consiga acessar o IP público da NVR (ou uma porta com port forwarding).
#YJ>
#YJ>Essa é a forma recomendada de conectar câmeras que o NVR não pode discar diretamente.
#YJ>
#YJ>### Como funciona
#YJ>
#YJ>1. O NVR roda um ouvinte **SRT** (UDP, `9000` de porta padrão) e/ou um servidor **RTMP** (TCP, `1935` de porta padrão).
#YJ>2. Você adiciona uma câmera com `protocol: srt` ou `protocol: rtmp`. O NVR cria um `IngestRecorder` para ele e espera (o status aparece como *reconectando* / ocioso).
#YJ>3. Quando a publicadora conecta e começa a transmitir, o gravador muda para *gravação*, ventila os quadros para HLS/WebRTC/FLV ao vivo, **e** grava segmentos rolando MP4 no disco — exatamente como uma câmera RTSP.
#YJ>
#YJ>### Pré-requisitos
#YJ>
#YJ>- A SRT (`UDP 9000`) e/ou RTMP porta (`TCP 1935`) da NVR deve ser acessível pela rede da editora. Se o NVR estiver atrás do NAT/roteador, configure o **encaminhamento de porta** para essa porta para o host NVR.
#YJ> - A editora precisa de ffmpeg, OBS, GStreamer ou qualquer ferramenta que possa enviar RTMP/SRT.
#YJ>
#YJ>### Habilitar os servidores de ingest.
#YJ>
#YJ>Em `aglus-nvr.yaml` (ou via Configurações):
#YJ>
#YJ>'''yaml
#YJ>srt:
#YJ> ativado: verdadeiro
#YJ> porto: 9000
#YJ>
#YJ>rtmp:
#YJ> ativado: verdadeiro
#YJ> porto: 1935
#YJ>'''
#YJ>
#YJ>### Adicione uma câmera push (RTMP)
#YJ>
#YJ>'''yaml
#YJ>câmeras:
#YJ> - ID: "Loja Remota"
#YJ> nome: "Câmera de Loja Remota"
#YJ> protocolo: "rtmp"
#YJ> codificação: "h264"
#YJ> stream_key: "remote-shop" # o último segmento de caminho da URL de publicação
#YJ> ativado: verdadeiro
#YJ>'''
#YJ>
#YJ>Publique do site remoto (exemplo ffmpeg, substituindo `NVR_IP`):
#YJ>
#YJ>'''bash
#YJ># De uma câmera RTSP na rede remota, republique como RTMP na NVR
#YJ>ffmpeg -rtsp_transport tcp -i "rtsp://admin:pass@192.168.1.50:554/stream" \
#YJ> -c copy -f flv "rtmp://NVR_IP:1935/live/remote-shop"
#YJ>'''
#YJ>
#YJ>O `stream_key` (`remote-shop`) mapeia o último segmento da URL de publicação para esta câmera. Você também pode definir a chave na forma de câmera; O formulário mostra o endereço completo de publicação.
#YJ>
#YJ>### Adicione uma câmera push (SRT)
#YJ>
#YJ>'''yaml
#YJ>câmeras:
#YJ> - ID: "garage-cam"
#YJ> nome: "Câmera de Garagem"
#YJ> protocolo: "srt"
#YJ> codificação: "h264"
#YJ> srt_stream_id: "garage-cam" # mapeia o SRT streamid para esta câmera
#YJ> srt_passphrase: "meu-segredo" # criptografia AES opcional
#YJ> ativado: verdadeiro
#YJ>'''
#YJ>
#YJ>Publique do site remoto:
#YJ>
#YJ>'''bash
#YJ>ffmpeg -rtsp_transport tcp -i "rtsp://admin:pass@192.168.1.60:554/stream" \
#YJ> -c copy -f mpegts "srt://NVR_IP:9000?streamid=garage-cam&passphrase=my-secret"
#YJ>'''
#YJ>
#YJ>SRT usa UDP, que alguns provedores domésticos bloqueiam ou dificultam o encaminhamento. Se SRT não conectar, use RTMP (TCP) — ele atravessa NAT/firewalls de consumo de forma mais confiável.
#YJ>
#YJ>### Notas e limitações
#YJ>
#YJ>- **H.264 hoje só mais de SRT/RTMP.** O demuxer MPEG-TS SRT e o clássico RTMP ambos têm H.264. H.265 desses transportes é um acompanhamento. (Para H.265 câmeras, transcode para H.264 na editora ou use MediaMTX como ponte.)
#YJ>- **A câmera mostra *offline* até que um editor se conecte** — isso é esperado para câmeras push. Não há fonte para "discar" até que a editora chegue.
#YJ>- **Requer encaminhamento de portas / IP público.** A ingestão push não atravessa o NAT sozinha (sem STUN/TURN). Se nenhum dos lados tiver uma porta acessível, use uma rede de sobreposição (Tailscale/WireGuard) ou MediaMTX como intermediária.
#YJ>- **Áudio**: RTMP/SRT push atualmente grava apenas vídeo (ainda sem fiação de áudio no caminho de ingestão por enquanto).
#YJ>- **Configuração global legada** (`srt.streams[]`, `rtmp.stream_keys`) ainda funciona e é fundida com campos por câmera; Campos por câmera têm prioridade.
#YJ>
#YJ>## Push-Out (Relé) — Encaminhe uma câmera para destinos remotos
#YJ>
#YJ>Push-out (relé) é o oposto do push-in: o NVR encaminha a transmissão ao vivo de uma câmera para destinos remotos — a ingestão RTMP/SRT de outra NVR, uma plataforma de streaming ao vivo ou um servidor de backup. **É pura Go, sem necessidade de FFmpeg** — o relé utiliza as bibliotecas de `gortsplib`/`gortmplib` existentes em processo.
#YJ>
#YJ>Isso é ideal para: enviar o feed de uma câmera para um NVR remoto pela internet, espelhar para um site de backup ou publicar em uma plataforma ao vivo — tudo isso sem um processo externo.
#YJ>
#YJ>### Como funciona
#YJ>
#YJ>Cada alvo push-out assina o `StreamHub` existente da câmera (o mesmo barramento de quadros usado na gravação e na visualização ao vivo). Os quadros são remuxados (não recodificados) e escritos no alvo por meio de uma conexão dedicada RTMP ou RTSP. Cada alvo roda em sua própria goroutine, com reconexão independente e contabilidade de taxa de bits.
#YJ>
#YJ>- **Fonte de cópia zero**: sem repull, sem decodificação — adicionar um alvo de relé adiciona uma goroutine + um soquete de saída (~5-10 MB no RPi 3B).
#YJ>- **H.264 apenas remux**: RTMP alvos exigem uma fonte H.264 (RTMP não carrega H.265). RTSP alvos também estão H.264 atualmente. Transcodificação NÃO é suportada no relé (use o recurso de transcodificação para H.265→H.264 se necessário, depois retransmita o fluxo transcodificado).
#YJ>- **Múltiplos alvos por câmera**: uma câmera pode avançar para vários destinos simultaneamente.
#YJ>
#YJ>### Configurar alvos push-out
#YJ>
#YJ>Adicione `push_targets` a QUALQUER câmera (RTSP, ONVIF, Xiaomi, até mesmo câmeras push-in):
#YJ>
#YJ>'''yaml
#YJ>câmeras:
#YJ> - ID: "porta da frente"
#YJ> protocolo: "rtsp"
#YJ> url: "rtsp://admin:pass@192.168.1.50/stream"
#YJ> push_targets:
#YJ> - ID: "backup-NVR"
#YJ> nome: "Backup NVR"
#YJ> protocolo: "rtmp"
#YJ> url: "rtmp://backup.example.com:1935/live/front-door"
#YJ> ativado: verdadeiro
#YJ> - id: "Plataforma ao Vivo"
#YJ> nome: "Live Platform"
#YJ> protocolo: "rtsp"
#YJ> url: "rtsp://live.example.com:8554/front-door"
#YJ> ativado: falso
#YJ> ativado: verdadeiro
#YJ>'''
#YJ>
#YJ>Ou configure via interface web: edite uma câmera → expanda a seção "Push-Out (Relay)" → adicione alvos (nome, protocolo, URL, ativar alternância).
#YJ>
#YJ>### Monitorando o status do relé
#YJ>
#YJ>O cartão da câmera mostra um distintivo com alvos ativos/totais (por exemplo, `↑ 2/2`). No formulário de edição, cada alvo mostra uma pílula de status ao vivo (streaming + kbps / conexão / reconexão / erro). O endpoint da API `GET /api/cameras/{id}/push-status` retorna o status de runtime por alvo.
#YJ>
#YJ>### Exemplo de NVR para NVR entre redes
#YJ>
#YJ>O caso de uso mais comum — enviar uma câmera de um NVR para outro pela internet, sem FFmpeg:
#YJ>
#YJ>'''
#YJ>[Câmera] ──RTSP── ▶ [NVR-A] ── relé push-out (RTMP)── ▶ [NVR-B (ingesta push-in)] ── ▶ discos + ao vivo
#YJ>'''
#YJ>
#YJ>1. No **NVR-B** (o receptor): ative RTMP ingerência, adicione uma câmera push-in com uma chave de fluxo (por exemplo, `front-door-relay`).
#YJ>2. Em **NVR-A** (o remetente): adicione um `push_target` à câmera de origem apontando para `rtmp://NVR-B-IP:1935/live/front-door-relay`.
#YJ>3. O motor de relé do NVR-A conecta-se aos quadros NVR-B e avança. NVR-B grava e atende a transmissão como uma câmera local.
#YJ>
#YJ>### Notas e limitações
#YJ>
#YJ>- **H.264 fonte necessária** para RTMP alvos. H.265 fontes são rejeitadas (o relé é apenas remux; sem transcodificação).
#YJ>- **Apenas vídeo** (ainda sem retransmissão de áudio).
#YJ>- **O alvo deve ser alcançável**: o relé disca para o alvo, então a porta de RTMP/RTSP do alvo deve estar acessível (encaminhamento de porta se estiver atrás do NAT).
#YJ>- **Reconexão resiliente**: se a câmera de origem ou a conexão do alvo cair, o relé tenta com recuo exponencial e retoma automaticamente.
#YJ>
#YJ>Por meio de informações abrangentes sobre compatibilidade de marcas de câmeras, este guia ajuda você a integrar com sucesso diversas câmeras IP com AglusNVR, garantindo desempenho de gravação ideal e confiabilidade para seu sistema de vigilância.