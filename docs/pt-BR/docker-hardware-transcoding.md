# Guia de transcodificação de hardware Docker

## Visão geral

A passagem de hardware é essencial para o desempenho ideal de transcodificação em contêineres Docker. AglusNVR oferece suporte a vários caminhos de aceleração de hardware: V4L2 M2M para Raspberry Pi, VAAPI para GPUs Intel/AMD e NVENC para GPUs NVIDIA. Este guia explica como configurar Docker para expor dispositivos de hardware ao contêiner para máxima eficiência de transcodificação.

## Raspberry Pi V4L2 M2M

A aceleração de memória para memória (M2M) V4L2 fornece codificação H.264/H.265 acelerada por hardware em dispositivos Raspberry Pi, melhorando significativamente o desempenho em comparação com a codificação de software.

### Mapeamento de dispositivos

Câmeras Raspberry Pi ou placas de captura USB normalmente aparecem como `/dev/video10`, `/dev/video11`, `/dev/video12` no sistema host. Os números dos seus dispositivos podem variar.

#### Verifique os dispositivos disponíveis

```bash
# List video devices on the host
ls -la /dev/video*

# Check device capabilities
v4l2-ctl -d /dev/video10 --list-formats-ext
```

#### Configuração Docker Compose

Adicione mapeamento de dispositivos ao seu `docker-compose.yml`:

```yaml
services:
  aglus-nvr:
    image: ghcr.io/mms1688/aglusnvr:latest
    container_name: aglus-nvr
    restart: unless-stopped
    
    ports:
      - "9090:9090"   # Web UI / API
      - "2121:2121"   # FTP
      - "2122-2140:2122-2140"  # FTP passive ports
    
    # Map video devices for hardware acceleration
    devices:
      - /dev/video10:/dev/video10
      - /dev/video11:/dev/video11
      - /dev/video12:/dev/video12
    
    volumes:
      - ./data:/data
    environment:
      - NVR_DATA_DIR=/data
    healthcheck:
      test: ["CMD", "aglus-nvr", "health"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3
```

### Verificação

Verifique se os dispositivos estão acessíveis dentro do contêiner:

```bash
# Enter container shell (if available)
docker exec -it aglus-nvr sh

# List video devices inside container
ls -la /dev/video*

# Test V4L2 capabilities
v4l2-ctl -d /dev/video10 --list-formats-ext
```

### Problemas conhecidos

- **Kernel 6.6.63+**: Há um bug V4L2 M2M em kernels mais recentes que pode causar falhas de codificação. Considere fazer o downgrade para o kernel 6.6.62 ou anterior se encontrar problemas.
- **Permissões do dispositivo**: certifique-se de que seu usuário tenha acesso aos dispositivos de vídeo. Adicione-se ao grupo `video`: `sudo usermod -a -G video $USER`
- **Conflitos de dispositivos**: Evite usar o mesmo dispositivo de vídeo para o host Docker e outros aplicativos simultaneamente.

## Intel/AMD VAAPI

A API de aceleração de vídeo (VAAPI) fornece aceleração de hardware para GPUs Intel e AMD, permitindo transcodificação H.264/H.265 eficiente.

### Mapeamento de dispositivos

VAAPI requer acesso a todo o grupo de dispositivos `/dev/dri`, que inclui dispositivos de renderização e cartão.

#### Verifique os dispositivos disponíveis

```bash
# List DRI devices
ls -la /dev/dri/*

# Check GPU capabilities
 vainfo
```

#### Configuração Docker Compose

Adicione mapeamento de dispositivo DRI:

```yaml
services:
  aglus-nvr:
    image: ghcr.io/mms1688/aglusnvr:latest
    container_name: aglus-nvr
    restart: unless-stopped
    
    ports:
      - "9090:9090"   # Web UI / API
      - "2121:2121"   # FTP
      - "2122-2140:2122-2140"  # FTP passive ports
    
    # Map DRI devices for VAAPI acceleration
    devices:
      - /dev/dri/renderD128:/dev/dri/renderD128
      - /dev/dri/card0:/dev/dri/card0
    
    volumes:
      - ./data:/data
    environment:
      - NVR_DATA_DIR=/data
      - LIBVA_DRIVER_NAME=i965  # For Intel GPUs
      # - LIBVA_DRIVER_NAME=radeonsi  # For AMD GPUs
    healthcheck:
      test: ["CMD", "aglus-nvr", "health"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3
```

### Verificação

Teste a funcionalidade VAAPI dentro do contêiner:

```bash
# Enter container
docker exec -it aglus-nvr sh

# Check VAAPI info
vainfo
```

Você deverá ver a saída listando os drivers e formatos VAAPI disponíveis se a aceleração de hardware estiver funcionando corretamente.

## NVIDIA

As GPUs NVIDIA fornecem aceleração de hardware NVENC para codificação H.264/H.265 com excelente desempenho e qualidade.

### Pré-requisitos

Instale o kit de ferramentas de contêiner NVIDIA:

```bash
# Add the NVIDIA Container Toolkit repository
distribution=$(. /etc/os-release;echo $ID$VERSION_ID)
curl -s -L https://nvidia.github.io/nvidia-docker/gpgkey | sudo apt-key add -
curl -s -L https://nvidia.github.io/nvidia-docker/$distribution/nvidia-docker.list | sudo tee /etc/apt/sources.list.d/nvidia-docker.list

# Install the toolkit
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Restart Docker
sudo systemctl restart docker
```

#### Configuração Docker Compose

Use o tempo de execução NVIDIA para acesso à GPU:

```yaml
services:
  aglus-nvr:
    image: ghcr.io/mms1688/aglusnvr:latest
    container_name: aglus-nvr
    restart: unless-stopped
    
    ports:
      - "9090:9090"   # Web UI / API
      - "2121:2121"   # FTP
      - "2122-2140:2122-2140"  # FTP passive ports
    
    # Use NVIDIA runtime for GPU access
    deploy:
      resources:
        reservations:
          devices:
            - driver: nvidia
              count: all
              capabilities: [gpu]
    
    volumes:
      - ./data:/data
    environment:
      - NVR_DATA_DIR=/data
    healthcheck:
      test: ["CMD", "aglus-nvr", "health"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3
```

#### Mapeamento de dispositivos alternativos

Se você preferir o mapeamento de dispositivos em vez da configuração de implantação:

```yaml
services:
  aglus-nvr:
    # ... other configuration ...
    
    runtime: nvidia
    devices:
      - /dev/nvidia0:/dev/nvidia0
      - /dev/nvidia1:/dev/nvidia1
      - /dev/nvidiactl:/dev/nvidiactl
      - /dev/nvidia-uvm:/dev/nvidia-uvm
      - /dev/nvidia-uvm-tools:/dev/nvidia-uvm-tools
    
    # ... rest of configuration ...
```

### Verificação

Verifique se a GPU está acessível:

```bash
# Check GPU access in container
docker exec aglus-nvr nvidia-smi

# Test NVENC capability
docker exec aglus-nvr ffmpeg -encoders | grep nvenc
```

## Fallback apenas de software

Quando a aceleração de hardware não está disponível ou não é desejada, AglusNVR recorre à codificação de software usando libx264/libx265.

### Configuração

Nenhum mapeamento de dispositivo é necessário:

```yaml
services:
  aglus-nvr:
    image: ghcr.io/mms1688/aglusnvr:latest
    container_name: aglus-nvr
    restart: unless-stopped
    
    ports:
      - "9090:9090"   # Web UI / API
      - "2121:2121"   # FTP
      - "2122-2140:2122-2140"  # FTP passive ports
    
    volumes:
      - ./data:/data
    environment:
      - NVR_DATA_DIR=/data
    healthcheck:
      test: ["CMD", "aglus-nvr", "health"]
      interval: 30s
      timeout: 5s
      start_period: 10s
      retries: 3
```

### Expectativas de desempenho

| Ferragens | Codificação | Notas de Desempenho |
|----------|----------|------------------|
| Raspberry Pi 3B | Software H.264 | ~1-2 FPS por stream, uso intensivo de CPU |
| Raspberry Pi 4 | Software H.264 | ~3-5 FPS por stream, uso moderado de CPU |
| Intel NUC | Software H.264 | ~15-30 FPS por stream, uso moderado de CPU |
| CPU de Desktop | Software H.264 | ~30-60 FPS por stream, intensivo em CPU |

### Quando Usar Software vs Hardware

**Use aceleração por hardware quando:**
- Você precisa de taxas de quadros mais altas (>5 FPS)
- Os recursos da CPU são limitados
- Você tem muitos fluxos simultâneos
- Eficiência energética é importante

**Use codificação por software quando:**
- Dispositivos de hardware não estão disponíveis
- Você precisa de máxima compatibilidade
- As configurações de qualidade precisam de ajustes finos
- Desenvolvimento/testes sem hardware especial

## FFmpeg Dentro Docker

AglusNVR baixa e usa builds estáticas de FFmpeg do johnvansickle para arquiteturas ARM64/ARMv7 em tempo de execução.

### FFmpeg Download e Armazenamento

FFmpeg é baixado para `{StorageConfig.RootDir}/tools/` dentro do recipiente:

```bash
# Default location inside container
/data/tools/ffmpeg

# Check available FFmpeg version
docker exec aglus-nvr /data/tools/ffmpeg -version
```

### Recomendação de Armazenamento Persistente

Para melhor desempenho e evitar baixar novamente FFmpeg, monte um volume persistente:

```yaml
services:
  aglus-nvr:
    # ... other configuration ...
    
    volumes:
      - ./data:/data
      - ./tools:/data/tools  # Persistent FFmpeg storage
    
    environment:
      - NVR_DATA_DIR=/data
      - NVR_FFMPEG_PATH=/data/tools/ffmpeg  # Optional: specify custom FFmpeg path
```

### Build FFmpeg Personalizada

Se você precisar de uma build personalizada de FFmpeg, coloque-a no diretório de ferramentas:

```bash
# Download custom FFmpeg
wget -O ./tools/ffmpeg https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-linux64-gpl.tar.xz

# Make executable
chmod +x ./tools/ffmpeg
```

## Lista de Verificação de Solução de Problemas

### Problemas de acesso ao dispositivo

**Problema**: `Permission denied` ao acessar dispositivos
```bash
# Fix device permissions
sudo usermod -a -G video $USER
newgrp video

# For Docker-specific permissions
sudo chown -R 65534:65534 ./data
```

**Problema**: Dispositivo não encontrado no contêiner
```bash
# Check host devices
ls -la /dev/video*

# Verify device mapping
docker exec aglus-nvr ls -la /dev/video*
```

### Problemas de desempenho

**Problema**: Alto uso de CPU com codificação por software
- Adicionar aceleração por hardware, se disponível
- Reduzir a duração do segmento para 30s
- Limitar fluxos concorrentes com base nos núcleos da CPU

**Problema**: Qualidade de transcodificação ruim
- Verifique as configurações do codificador na configuração
- Considere usar taxas de bits adequadas para sua resolução
- Utilização de hardware do monitor

### Questões do VAAPI

**Problema**: `vainfo` não mostra drivers
- Verifique se a GPU está instalada e funcionando no host
- Verifique LIBVA_DRIVER_NAME variável de ambiente
- Garanta que os dispositivos DRI corretos estejam mapeados

**Problema**: Saída de vídeo preta
- Verifique se os drivers da GPU estão atualizados
- Verificar permissões de dispositivo de renderização
- Teste primeiro com comando simples FFmpeg

### Problemas com NVIDIA

**Problema**: `nvidia-smi` não encontrado no recipiente
- Instalar o Kit de Ferramentas de Contêineres da NVIDIA
- Verifique Docker runtime está configurado para `nvidia`
- Verifique o mapeamento dos dispositivos GPU

**Problema**: codificador NVENC não disponível
- Verificar GPU que suporta NVENC
- Verifique se os drivers da NVIDIA estão atualizados
- Teste com FFmpeg: `ffmpeg -encoders | grep nvenc`

### Questões Gerais Docker

**Problema**: O contêiner reinicia continuamente
- Confira Docker registros: `docker compose logs aglus-nvr`
- Verificar a sintaxe de configuração
- Verifique o espaço do disco e as permissões

**Problema**: Falha no exame de saúde
- Exame manual de saúde: `docker exec aglus-nvr aglus-nvr health`
- Verifique se o binário existe e é executável
- Verificar permissões de diretório de dados

### Comandos de Depuração

```bash
# View container logs
docker compose logs -f aglus-nvr

# Check resource usage
docker stats aglus-nvr

# Test health check
docker exec aglus-nvr aglus-nvr health

# Check FFmpeg availability
docker exec aglus-nvr /data/tools/ffmpeg -version

# List available encoders
docker exec aglus-nvr /data/tools/ffmpeg -encoders | grep -E "(h264|h265|nvenc|vaapi|v4l2)"
```

## Dicas Adicionais

1. **Comece simples**: Comece com configuração apenas de software para verificar a funcionalidade básica
2. **Teste Incremental**: Adicionar um componente de hardware por vez
3. **Recursos de monitoramento**: use `docker stats` para monitorar CPU, memória e E/S
4. **Atualize regularmente**: mantenha as imagens e drivers Docker atualizados
5. **Configuração de backup**: sempre faça backup do seu `docker-compose.yml` antes de grandes alterações