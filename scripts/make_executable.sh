#!/bin/bash
# Script para tornar todos os arquivos executáveis
# Autor: Configuração QtAgOpenGPS

echo "=== Configurando Permissões dos Scripts ==="
echo

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Lista de arquivos para tornar executáveis
FILES=(
    "gps_setup.sh"
    "test_serial.sh"
    "gps_bridge.py"
    "configure_m10fly.py"
    "start_gps_system.sh"
    "install_service.sh"
    "diagnose_gps.sh"
    "make_executable.sh"
)

echo "📋 Tornando scripts executáveis..."

for file in "${FILES[@]}"; do
    if [ -f "$SCRIPT_DIR/$file" ]; then
        chmod +x "$SCRIPT_DIR/$file"
        echo "✅ $file agora é executável"
    else
        echo "⚠️  $file não encontrado"
    fi
done

echo
echo "📋 Verificando permissões..."
ls -la "$SCRIPT_DIR"/*.sh "$SCRIPT_DIR"/*.py

echo
echo "✅ Configuração de permissões concluída!"
echo
echo "📋 Próximos passos:"
echo "   1. Conecte fisicamente o módulo M10Fly"
echo "   2. Execute: sudo ./gps_setup.sh"
echo "   3. Reinicie: sudo reboot"
echo "   4. Execute: ./test_serial.sh"
echo "   5. Execute: ./start_gps_system.sh start"