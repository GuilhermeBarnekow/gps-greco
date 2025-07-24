#!/bin/bash
# Script para instalar serviço systemd do GPS
# Autor: Configuração QtAgOpenGPS

echo "=== Instalação do Serviço GPS SystemD ==="
echo

# Verificar se está rodando como root
if [ "$EUID" -ne 0 ]; then
    echo "❌ Este script precisa ser executado como root (sudo)"
    exit 1
fi

# Obter diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
USER_NAME="$SUDO_USER"

echo "📋 Configurações:"
echo "   Diretório do projeto: $PROJECT_DIR"
echo "   Usuário: $USER_NAME"
echo

# Criar arquivo de serviço para GPS Bridge
cat > /etc/systemd/system/gps-bridge.service << EOF
[Unit]
Description=GPS Bridge para QtAgOpenGPS
Documentation=https://github.com/torriem/QtAgOpenGPS
After=network.target
Wants=network.target

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$SCRIPT_DIR
ExecStart=/usr/bin/python3 $SCRIPT_DIR/gps_bridge.py
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal

# Variáveis de ambiente
Environment=PYTHONUNBUFFERED=1

# Configurações de segurança
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Serviço gps-bridge.service criado"

# Criar arquivo de serviço para QtAgIO
cat > /etc/systemd/system/agio.service << EOF
[Unit]
Description=QtAgIO - Módulo de comunicação AgOpenGPS
Documentation=https://github.com/torriem/QtAgOpenGPS
After=network.target gps-bridge.service
Wants=network.target
Requires=gps-bridge.service

[Service]
Type=simple
User=$USER_NAME
Group=$USER_NAME
WorkingDirectory=$PROJECT_DIR
ExecStart=$PROJECT_DIR/build/QtAgIO/QtAgIO
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal

# Variáveis de ambiente para Qt
Environment=QT_QPA_PLATFORM=offscreen
Environment=DISPLAY=:0

# Configurações de segurança
NoNewPrivileges=true
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Serviço agio.service criado"

# Recarregar systemd
systemctl daemon-reload
echo "✅ SystemD recarregado"

# Habilitar serviços
systemctl enable gps-bridge.service
systemctl enable agio.service
echo "✅ Serviços habilitados para inicialização automática"

echo
echo "📋 Comandos úteis:"
echo "   Iniciar serviços:     sudo systemctl start gps-bridge agio"
echo "   Parar serviços:       sudo systemctl stop gps-bridge agio"
echo "   Status dos serviços:  sudo systemctl status gps-bridge agio"
echo "   Ver logs:             sudo journalctl -u gps-bridge -f"
echo "   Ver logs:             sudo journalctl -u agio -f"
echo
echo "⚠️  Nota: Os serviços iniciarão automaticamente na próxima reinicialização"
echo "   Para iniciar agora: sudo systemctl start gps-bridge agio"