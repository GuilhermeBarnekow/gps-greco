#!/bin/bash
# Script para corrigir dependências específicas do Raspberry Pi OS
# Autor: Configuração QtAgOpenGPS para Raspberry Pi

echo "=== Correção de Dependências Raspberry Pi OS ==="
echo

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}ℹ️  $1${NC}"; }
log_success() { echo -e "${GREEN}✅ $1${NC}"; }
log_warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
log_error() { echo -e "${RED}❌ $1${NC}"; }

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    log_error "Este script precisa ser executado como root (sudo)"
    exit 1
fi

echo "📋 Etapa 1: Verificando e corrigindo sources.list"
echo "================================================"

# Backup do sources.list original
cp /etc/apt/sources.list /etc/apt/sources.list.backup.$(date +%Y%m%d_%H%M%S)

# Verificar se os repositórios estão corretos
log_info "Verificando repositórios..."

# Garantir que os repositórios principais estão presentes
if ! grep -q "deb http://deb.debian.org/debian bookworm main" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian bookworm main contrib non-free" >> /etc/apt/sources.list
    log_info "Adicionado repositório Debian bookworm main"
fi

if ! grep -q "deb http://deb.debian.org/debian-security bookworm-security main" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian-security bookworm-security main contrib non-free" >> /etc/apt/sources.list
    log_info "Adicionado repositório Debian security"
fi

if ! grep -q "deb http://deb.debian.org/debian bookworm-updates main" /etc/apt/sources.list; then
    echo "deb http://deb.debian.org/debian bookworm-updates main contrib non-free" >> /etc/apt/sources.list
    log_info "Adicionado repositório Debian updates"
fi

echo
echo "📋 Etapa 2: Adicionando repositório testing para Qt6"
echo "=================================================="

# Criar arquivo separado para testing
cat > /etc/apt/sources.list.d/testing.list << 'EOF'
# Repositório Debian testing para Qt6
deb http://deb.debian.org/debian testing main contrib non-free
deb-src http://deb.debian.org/debian testing main contrib non-free
EOF

# Configurar prioridades para evitar conflitos
cat > /etc/apt/preferences.d/testing << 'EOF'
# Prioridades para repositório testing
Package: *
Pin: release a=testing
Pin-Priority: 50

# Qt6 packages com prioridade alta do testing
Package: qt6-*
Pin: release a=testing
Pin-Priority: 500

Package: libqt6*
Pin: release a=testing
Pin-Priority: 500

Package: qml6-*
Pin: release a=testing
Pin-Priority: 500

# CMake e Ninja do testing se necessário
Package: cmake
Pin: release a=testing
Pin-Priority: 400

Package: ninja-build
Pin: release a=testing
Pin-Priority: 400
EOF

log_success "Repositório testing configurado"

echo
echo "📋 Etapa 3: Atualizando chaves GPG"
echo "================================="

# Atualizar chaves GPG
log_info "Atualizando chaves GPG..."
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138 2>/dev/null || true
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 0E98404D386FA1D9 2>/dev/null || true

echo
echo "📋 Etapa 4: Atualizando listas de pacotes"
echo "========================================"

log_info "Atualizando apt..."
apt update

echo
echo "📋 Etapa 5: Instalando dependências básicas que faltam"
echo "===================================================="

# Lista de pacotes essenciais que podem estar faltando
ESSENTIAL_PACKAGES=(
    "build-essential"
    "git"
    "wget"
    "curl"
    "pkg-config"
    "python3"
    "python3-pip"
    "python3-serial"
)

log_info "Instalando pacotes essenciais..."
for package in "${ESSENTIAL_PACKAGES[@]}"; do
    if apt install -y "$package" 2>/dev/null; then
        log_success "$package instalado"
    else
        log_warning "Falha ao instalar $package"
    fi
done

echo
echo "📋 Etapa 6: Tentando instalar CMake e Ninja"
echo "=========================================="

# Tentar instalar cmake e ninja-build
log_info "Tentando instalar CMake..."
if apt install -y cmake; then
    log_success "CMake instalado"
elif apt install -y -t testing cmake; then
    log_success "CMake instalado do testing"
else
    log_warning "Falha ao instalar CMake - será necessário compilar manualmente"
fi

log_info "Tentando instalar Ninja..."
if apt install -y ninja-build; then
    log_success "Ninja instalado"
elif apt install -y -t testing ninja-build; then
    log_success "Ninja instalado do testing"
else
    log_warning "Ninja não disponível - usará Make"
fi

echo
echo "📋 Etapa 7: Configurando swap se necessário"
echo "=========================================="

# Verificar e configurar swap se necessário
TOTAL_MEM=$(free -m | awk 'NR==2{printf "%.0f", $2}')
SWAP_SIZE=$(free -m | awk 'NR==3{printf "%.0f", $2}')

log_info "Memória RAM: ${TOTAL_MEM}MB"
log_info "Swap atual: ${SWAP_SIZE}MB"

if [ "$TOTAL_MEM" -lt 4096 ] && [ "$SWAP_SIZE" -lt 2048 ]; then
    log_warning "Pouca memória detectada, configurando swap adicional..."
    
    # Criar arquivo de swap de 2GB se não existir
    if [ ! -f /swapfile_build ]; then
        log_info "Criando arquivo de swap de 2GB..."
        dd if=/dev/zero of=/swapfile_build bs=1M count=2048 status=progress
        chmod 600 /swapfile_build
        mkswap /swapfile_build
        swapon /swapfile_build
        
        # Adicionar ao fstab temporariamente
        echo "/swapfile_build none swap sw 0 0" >> /etc/fstab
        
        log_success "Swap adicional de 2GB criado"
        log_warning "Lembre-se de remover após a compilação: sudo swapoff /swapfile_build && sudo rm /swapfile_build"
    fi
fi

echo
echo "📋 Etapa 8: Limpando cache e otimizando"
echo "======================================"

# Limpar cache desnecessário
log_info "Limpando cache..."
apt autoremove -y
apt autoclean

# Otimizar para compilação
echo "vm.swappiness=10" >> /etc/sysctl.conf
sysctl -p

log_success "Sistema otimizado"

echo
echo "📋 Etapa 9: Verificação final"
echo "============================"

# Verificar se os comandos essenciais estão disponíveis
COMMANDS=("gcc" "g++" "make" "git" "python3")

for cmd in "${COMMANDS[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        log_success "$cmd disponível"
    else
        log_error "$cmd não encontrado!"
    fi
done

# Verificar se cmake está disponível
if command -v cmake >/dev/null 2>&1; then
    CMAKE_VERSION=$(cmake --version | head -1)
    log_success "CMake disponível: $CMAKE_VERSION"
else
    log_warning "CMake não encontrado - pode ser necessário instalar manualmente"
fi

echo
echo "✅ CORREÇÃO DE DEPENDÊNCIAS CONCLUÍDA!"
echo "====================================="
echo
log_success "Sistema preparado para compilação"
echo
echo "📋 Próximos passos:"
echo "   1. Execute: ./build_qtag_rasppi.sh"
echo "   2. Aguarde a compilação (15-30 minutos)"
echo "   3. Teste o sistema compilado"
echo
echo "💡 Dicas:"
echo "   - Feche outros programas durante a compilação"
echo "   - Monitore a temperatura do Pi durante o processo"
echo "   - Use 'htop' para monitorar uso de recursos"