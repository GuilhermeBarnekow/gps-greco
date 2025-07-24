#!/bin/bash
# Script de configuração inicial para módulo GNSS M10Fly
# Autor: Configuração QtAgOpenGPS
# Data: $(date)

echo "=== Configuração do Módulo GNSS M10Fly para QtAgOpenGPS ==="
echo

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root (sudo)"
    exit 1
fi

echo "📋 Etapa 1: Habilitando UART no Raspberry Pi..."

# Backup do config.txt
cp /boot/config.txt /boot/config.txt.backup.$(date +%Y%m%d_%H%M%S)

# Habilitar UART
if ! grep -q "enable_uart=1" /boot/config.txt; then
    echo "enable_uart=1" >> /boot/config.txt
    echo "✅ UART habilitado em /boot/config.txt"
else
    echo "✅ UART já estava habilitado"
fi

# Desabilitar Bluetooth para liberar UART (opcional mas recomendado)
if ! grep -q "dtoverlay=disable-bt" /boot/config.txt; then
    echo "dtoverlay=disable-bt" >> /boot/config.txt
    echo "✅ Bluetooth desabilitado para liberar UART"
fi

echo
echo "📋 Etapa 2: Configurando console serial..."

# Desabilitar console serial no cmdline.txt
if [ -f /boot/cmdline.txt ]; then
    cp /boot/cmdline.txt /boot/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
    sed -i 's/console=serial0,115200 //g' /boot/cmdline.txt
    sed -i 's/console=ttyAMA0,115200 //g' /boot/cmdline.txt
    echo "✅ Console serial desabilitado"
fi

echo
echo "📋 Etapa 3: Configurando permissões de acesso..."

# Adicionar usuário ao grupo dialout
usermod -a -G dialout $SUDO_USER
echo "✅ Usuário $SUDO_USER adicionado ao grupo dialout"

echo
echo "📋 Etapa 4: Instalando dependências Python..."

# Instalar dependências necessárias
apt update
apt install -y python3-serial python3-socket python3-threading

echo "✅ Dependências Python instaladas"

echo
echo "📋 Etapa 5: Criando regras udev para dispositivo serial..."

# Criar regra udev para o dispositivo GPS
cat > /etc/udev/rules.d/99-gps-m10fly.rules << 'EOF'
# Regra para módulo GNSS M10Fly
KERNEL=="ttyAMA0", SYMLINK+="gps0", GROUP="dialout", MODE="0666"
KERNEL=="ttyS0", SYMLINK+="gps1", GROUP="dialout", MODE="0666"
EOF

echo "✅ Regras udev criadas"

echo
echo "📋 Etapa 6: Configurando serviços systemd..."

# Desabilitar serviços que podem interferir
systemctl disable hciuart 2>/dev/null || true
systemctl disable bluetooth 2>/dev/null || true

echo "✅ Serviços conflitantes desabilitados"

echo
echo "🔧 Configuração concluída!"
echo
echo "⚠️  IMPORTANTE: É necessário reiniciar o Raspberry Pi para aplicar as mudanças:"
echo "   sudo reboot"
echo
echo "📋 Após reiniciar, execute os próximos passos:"
echo "   1. Conecte fisicamente o módulo M10Fly"
echo "   2. Execute: ./test_serial.sh"
echo "   3. Execute: ./start_gps_bridge.sh"
echo