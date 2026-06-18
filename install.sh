#!/usr/bin/env bash
set -Eeuo pipefail

# AglusNVR — instalador automático para Linux com systemd
#
# Instalação:
#   curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh | sudo bash
#
# Instalação não interativa:
#   curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh |
#     sudo AGLUS_PASSWORD='uma-senha-segura' bash
#
# Desinstalação (preserva gravações e configuração):
#   curl -fsSL https://raw.githubusercontent.com/seu-usuario/AglusNVR/main/install.sh |
#     sudo bash -s -- --desinstalar

REPO="${AGLUS_REPO:-seu-usuario/AglusNVR}"
VERSION=""
DATA_DIR="${AGLUS_DATA_DIR:-/var/lib/aglus-nvr}"
PORT="${AGLUS_PORT:-9090}"
ADMIN_USER="${AGLUS_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${AGLUS_PASSWORD:-}"
SYSTEM_USER="aglus-nvr"
BIN_PATH="/usr/local/bin/aglus-nvr"
SERVICE_NAME="aglus-nvr"
SERVICE_FILE="/etc/systemd/system/${SERVICE_NAME}.service"
CONFIG_FILE=""
NON_INTERACTIVE=0
UNINSTALL=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[AVISO]${NC} $*"; }
error() { echo -e "${RED}[ERRO]${NC} $*" >&2; }
die()   { error "$*"; exit 1; }

cleanup_files=()
cleanup() {
    local file
    for file in "${cleanup_files[@]:-}"; do
        [[ -n "$file" ]] && rm -f -- "$file"
    done
}
trap cleanup EXIT

show_help() {
    cat <<'EOF'
Instalador do AglusNVR

Uso:
  install.sh [opções]

Opções:
  --versao, --version <tag>  Instala uma versão específica, por exemplo v1.0.0
  --dados <diretório>        Diretório de dados (padrão: /var/lib/aglus-nvr)
  --porta <número>           Porta da interface web (padrão: 9090)
  --usuario <nome>           Usuário administrador (padrão: admin)
  --senha <senha>            Senha inicial (mínimo de 8 caracteres)
  --nao-interativo           Não solicita dados pelo terminal
  --desinstalar, --uninstall Remove o serviço e o binário, preservando os dados
  -h, --help                 Mostra esta ajuda

Variáveis equivalentes:
  AGLUS_PASSWORD, AGLUS_DATA_DIR, AGLUS_PORT, AGLUS_ADMIN_USER, AGLUS_REPO
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --versao|--version)
                [[ $# -ge 2 ]] || die "$1 exige uma versão, por exemplo v1.0.0."
                VERSION="$2"
                shift 2
                ;;
            --dados)
                [[ $# -ge 2 ]] || die "--dados exige um diretório."
                DATA_DIR="$2"
                shift 2
                ;;
            --porta)
                [[ $# -ge 2 ]] || die "--porta exige um número."
                PORT="$2"
                shift 2
                ;;
            --usuario)
                [[ $# -ge 2 ]] || die "--usuario exige um nome."
                ADMIN_USER="$2"
                shift 2
                ;;
            --senha)
                [[ $# -ge 2 ]] || die "--senha exige uma senha."
                ADMIN_PASSWORD="$2"
                shift 2
                ;;
            --nao-interativo)
                NON_INTERACTIVE=1
                shift
                ;;
            --desinstalar|--uninstall)
                UNINSTALL=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                die "Opção desconhecida: $1. Use --help para ver as opções."
                ;;
        esac
    done
    CONFIG_FILE="${DATA_DIR}/aglus-nvr.yaml"
}

check_requirements() {
    [[ "$(id -u)" -eq 0 ]] || die "Execute o instalador como root: sudo bash install.sh"
    command -v systemctl >/dev/null 2>&1 || die "Este instalador requer uma distribuição Linux com systemd."
    [[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1 && PORT <= 65535 )) ||
        die "Porta inválida: ${PORT}"
}

detect_downloader() {
    if command -v curl >/dev/null 2>&1; then
        echo "curl"
    elif command -v wget >/dev/null 2>&1; then
        echo "wget"
    else
        die "Instale curl ou wget e execute novamente."
    fi
}

download() {
    local url="$1"
    local output="$2"
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fL --retry 3 --connect-timeout 15 -o "$output" "$url"
    else
        wget -q --tries=3 --timeout=30 -O "$output" "$url"
    fi
}

download_stdout() {
    local url="$1"
    if [[ "$DOWNLOADER" == "curl" ]]; then
        curl -fsSL --retry 3 --connect-timeout 15 "$url"
    else
        wget -qO- --tries=3 --timeout=30 "$url"
    fi
}

detect_arch() {
    case "$(uname -m)" in
        x86_64|amd64) echo "amd64" ;;
        aarch64|arm64) echo "arm64" ;;
        armv7l|armv7|armhf) echo "armv7" ;;
        *) die "Arquitetura não suportada: $(uname -m)" ;;
    esac
}

latest_version() {
    local response
    response="$(download_stdout "https://api.github.com/repos/${REPO}/releases/latest")" ||
        die "Não foi possível consultar a versão mais recente no GitHub."
    echo "$response" |
        sed -nE 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/p' |
        head -n 1
}

ensure_password() {
    [[ -f "$CONFIG_FILE" ]] && return 0

    if [[ -z "$ADMIN_PASSWORD" && "$NON_INTERACTIVE" -eq 0 && -r /dev/tty ]]; then
        read -r -s -p "Digite a senha inicial do administrador (mínimo 8 caracteres): " ADMIN_PASSWORD </dev/tty
        echo >/dev/tty
    fi
    [[ ${#ADMIN_PASSWORD} -ge 8 ]] ||
        die "Informe uma senha com pelo menos 8 caracteres usando AGLUS_PASSWORD ou --senha."
}

create_system_user() {
    if ! id "$SYSTEM_USER" >/dev/null 2>&1; then
        useradd --system --home-dir "$DATA_DIR" --shell /usr/sbin/nologin "$SYSTEM_USER"
        info "Usuário de sistema ${SYSTEM_USER} criado."
    fi
    install -d -m 0750 -o "$SYSTEM_USER" -g "$SYSTEM_USER" "$DATA_DIR"
}

install_binary() {
    local arch="$1"
    local asset="aglus-nvr-${arch}"
    local base_url="https://github.com/${REPO}/releases/download/${VERSION}"
    local binary_tmp
    local checksums_tmp
    binary_tmp="$(mktemp)"
    checksums_tmp="$(mktemp)"
    cleanup_files+=("$binary_tmp" "$checksums_tmp")

    info "Baixando AglusNVR ${VERSION} para ${arch}..."
    download "${base_url}/${asset}" "$binary_tmp" ||
        die "Falha ao baixar ${base_url}/${asset}"

    if download "${base_url}/SHA256SUMS" "$checksums_tmp" 2>/dev/null; then
        local expected actual
        expected="$(awk -v name="$asset" '$2 == name || $2 == "*" name { print $1; exit }' "$checksums_tmp")"
        [[ -n "$expected" ]] || die "O arquivo SHA256SUMS não contém ${asset}."
        actual="$(sha256sum "$binary_tmp" | awk '{print $1}')"
        [[ "$actual" == "$expected" ]] || die "A verificação SHA-256 do binário falhou."
        info "Integridade SHA-256 verificada."
    else
        warn "SHA256SUMS indisponível nesta versão; continuando sem verificação."
    fi

    install -m 0755 "$binary_tmp" "$BIN_PATH"
    "$BIN_PATH" -version
}

initialize_config() {
    if [[ -f "$CONFIG_FILE" ]]; then
        info "Configuração existente preservada em ${CONFIG_FILE}."
        chown "$SYSTEM_USER:$SYSTEM_USER" "$CONFIG_FILE"
        chmod 0600 "$CONFIG_FILE"
        return 0
    fi

    info "Criando a configuração inicial..."
    runuser -u "$SYSTEM_USER" -- "$BIN_PATH" init \
        --username "$ADMIN_USER" \
        --password "$ADMIN_PASSWORD" \
        --data-dir "$DATA_DIR" \
        --config "$CONFIG_FILE" \
        --listen ":${PORT}"
    chmod 0600 "$CONFIG_FILE"
}

install_service() {
    local service_tmp
    service_tmp="$(mktemp)"
    cleanup_files+=("$service_tmp")
    cat >"$service_tmp" <<EOF
[Unit]
Description=AglusNVR - Gravador de vídeo em rede
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=${SYSTEM_USER}
Group=${SYSTEM_USER}
WorkingDirectory=${DATA_DIR}
ExecStart=${BIN_PATH} -config ${CONFIG_FILE}
Restart=on-failure
RestartSec=5s
LimitNOFILE=65536
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${DATA_DIR}

[Install]
WantedBy=multi-user.target
EOF
    install -m 0644 "$service_tmp" "$SERVICE_FILE"
    systemctl daemon-reload
    systemctl enable "$SERVICE_NAME" >/dev/null
    systemctl restart "$SERVICE_NAME"
}

wait_until_ready() {
    local attempt
    for attempt in $(seq 1 30); do
        if "$BIN_PATH" health --config "$CONFIG_FILE" >/dev/null 2>&1; then
            return 0
        fi
        sleep 1
    done
    systemctl --no-pager --full status "$SERVICE_NAME" || true
    die "O serviço não ficou pronto. Consulte: journalctl -u ${SERVICE_NAME} -n 100"
}

primary_ip() {
    hostname -I 2>/dev/null | awk '{print $1}'
}

show_success() {
    local ip
    ip="$(primary_ip)"
    ip="${ip:-localhost}"
    echo
    echo -e "${GREEN}${BOLD}AglusNVR instalado com sucesso.${NC}"
    echo
    echo "  Interface:     http://${ip}:${PORT}"
    echo "  Configuração:  ${CONFIG_FILE}"
    echo "  Dados:         ${DATA_DIR}"
    echo "  Serviço:       systemctl status ${SERVICE_NAME}"
    echo "  Logs:          journalctl -u ${SERVICE_NAME} -f"
    echo
}

uninstall() {
    check_requirements
    info "Removendo o serviço e o binário..."
    systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    rm -f -- "$SERVICE_FILE" "$BIN_PATH"
    systemctl daemon-reload

    if id "$SYSTEM_USER" >/dev/null 2>&1; then
        userdel "$SYSTEM_USER" 2>/dev/null || true
    fi

    echo
    info "AglusNVR desinstalado."
    if [[ -d "$DATA_DIR" ]]; then
        warn "Os dados foram preservados em ${DATA_DIR}."
    fi
}

main() {
    parse_args "$@"
    if [[ "$UNINSTALL" -eq 1 ]]; then
        uninstall
        return
    fi

    check_requirements
    DOWNLOADER="$(detect_downloader)"
    ARCH="$(detect_arch)"
    if [[ -z "$VERSION" ]]; then
        info "Consultando a versão mais recente..."
        VERSION="$(latest_version)"
    fi
    [[ -n "$VERSION" ]] || die "Não foi possível determinar a versão para instalação."

    ensure_password
    create_system_user
    install_binary "$ARCH"
    initialize_config
    install_service
    wait_until_ready
    show_success
}

main "$@"
