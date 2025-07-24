#!/bin/bash
# Script para testar comunicação serial com módulo GNSS M10Fly
# Autor: Configuração QtAgOpenGPS

echo "=== Teste de Comunicação Serial - Módulo GNSS M10Fly ==="
echo

# Verificar se o dispositivo serial existe
DEVICE="/dev/ttyAMA0"
ALT_DEVICE="/dev/ttyS0"

if [ -c "$DEVICE" ]; then
    GPS_DEVICE="$DEVICE"
    echo "✅ Dispositivo encontrado: $GPS_DEVICE"
elif [ -c "$ALT_DEVICE" ]; then
    GPS_DEVICE="$ALT_DEVICE"
    echo "✅ Dispositivo encontrado: $GPS_DEVICE"
else
    echo "❌ Nenhum dispositivo serial encontrado!"
    echo "   Verifique se:"
    echo "   - O módulo está conectado corretamente"
    echo "   - O UART foi habilitado (execute gps_setup.sh)"
    echo "   - O sistema foi reiniciado após a configuração"
    exit 1
fi

echo
echo "📋 Testando comunicação serial..."
echo "   Dispositivo: $GPS_DEVICE"
echo "   Baud Rate: 115200"
echo "   Pressione Ctrl+C para parar"
echo

# Configurar porta serial e ler dados
stty -F $GPS_DEVICE 115200 cs8 -cstopb -parenb -echo -echoe -echok -echoctl -echoke

echo "🔍 Aguardando dados NMEA..."
echo "   (Pode levar alguns segundos para o módulo inicializar)"
echo

# Contador para timeout
timeout_counter=0
max_timeout=30

# Ler dados da porta serial
while IFS= read -r line <&3; do
    # Verificar se é uma sentença NMEA válida
    if [[ $line =~ ^\$[A-Z]{2}[A-Z]{3}, ]]; then
        echo "✅ NMEA recebido: $line"
        
        # Identificar tipo de sentença
        if [[ $line =~ ^\$[A-Z]{2}GGA, ]]; then
            echo "   📍 Sentença GGA (Posição GPS) detectada"
        elif [[ $line =~ ^\$[A-Z]{2}RMC, ]]; then
            echo "   🧭 Sentença RMC (Dados mínimos) detectada"
        elif [[ $line =~ ^\$[A-Z]{2}VTG, ]]; then
            echo "   🚀 Sentença VTG (Velocidade) detectada"
        elif [[ $line =~ ^\$[A-Z]{2}GSA, ]]; then
            echo "   🛰️  Sentença GSA (Satélites ativos) detectada"
        elif [[ $line =~ ^\$[A-Z]{2}GSV, ]]; then
            echo "   📡 Sentença GSV (Satélites visíveis) detectada"
        fi
        
        # Parar após receber algumas sentenças válidas
        ((timeout_counter++))
        if [ $timeout_counter -ge 10 ]; then
            echo
            echo "✅ Teste concluído com sucesso!"
            echo "   O módulo GNSS está funcionando corretamente"
            break
        fi
    else
        # Mostrar dados não-NMEA (pode ser ruído ou configuração)
        if [ ${#line} -gt 0 ]; then
            echo "📄 Dados recebidos: $line"
        fi
    fi
    
    # Timeout de segurança
    ((timeout_counter++))
    if [ $timeout_counter -ge 100 ]; then
        echo
        echo "⚠️  Timeout atingido. Possíveis problemas:"
        echo "   - Módulo não está enviando dados"
        echo "   - Baud rate incorreto"
        echo "   - Conexão física com problemas"
        echo "   - Módulo ainda inicializando"
        break
    fi
    
done 3< $GPS_DEVICE

echo
echo "📋 Informações do dispositivo:"
ls -la $GPS_DEVICE
echo
echo "📋 Configuração atual da porta:"
stty -F $GPS_DEVICE -a
echo
echo "💡 Próximos passos:"
echo "   1. Se viu sentenças NMEA: execute ./gps_bridge.py"
echo "   2. Se não viu dados: verifique conexões físicas"
echo "   3. Se viu dados mas não NMEA: verifique configuração do módulo"