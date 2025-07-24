#!/bin/bash
# Script de diagnóstico completo para sistema GPS
# Autor: Configuração QtAgOpenGPS

echo "=== Diagnóstico do Sistema GPS QtAgOpenGPS ==="
echo "Data: $(date)"
echo "Sistema: $(uname -a)"
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

# Função para verificar comando
check_command() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 está disponível"
        return 0
    else
        log_error "$1 não está disponível"
        return 1
    fi
}

# Função para verificar arquivo
check_file() {
    if [ -f "$1" ]; then
        log_success "Arquivo encontrado: $1"
        return 0
    else
        log_error "Arquivo não encontrado: $1"
        return 1
    fi
}

# Função para verificar processo
check_process() {
    if pgrep -f "$1" > /dev/null; then
        local pid=$(pgrep -f "$1")
        log_success "Processo rodando: $1 (PID: $pid)"
        return 0
    else
        log_warning "Processo não está rodando: $1"
        return 1
    fi
}

echo "📋 1. VERIFICAÇÃO DO SISTEMA BASE"
echo "=================================="

# Verificar se é Raspberry Pi
if [ -f /proc/device-tree/model ]; then
    MODEL=$(cat /proc/device-tree/model)
    log_info "Modelo detectado: $MODEL"
else
    log_warning "Não foi possível detectar o modelo do dispositivo"
fi

# Verificar versão do kernel
KERNEL=$(uname -r)
log_info "Kernel: $KERNEL"

# Verificar comandos essenciais
echo
log_info "Verificando comandos essenciais..."
check_command "python3"
check_command "stty"
check_command "lsof"
check_command "netstat"

echo
echo "📋 2. VERIFICAÇÃO DO UART"
echo "========================="

# Verificar configuração do UART no config.txt
log_info "Verificando configuração UART em /boot/config.txt..."
if [ -f /boot/config.txt ]; then
    if grep -q "enable_uart=1" /boot/config.txt; then
        log_success "UART habilitado no config.txt"
    else
        log_error "UART não habilitado no config.txt"
        log_error "Execute: echo 'enable_uart=1' | sudo tee -a /boot/config.txt"
    fi
    
    if grep -q "dtoverlay=disable-bt" /boot/config.txt; then
        log_success "Bluetooth desabilitado (recomendado)"
    else
        log_warning "Bluetooth não foi desabilitado"
    fi
else
    log_error "/boot/config.txt não encontrado"
fi

# Verificar cmdline.txt
log_info "Verificando console serial em /boot/cmdline.txt..."
if [ -f /boot/cmdline.txt ]; then
    if grep -q "console=serial0\|console=ttyAMA0" /boot/cmdline.txt; then
        log_warning "Console serial ainda habilitado (pode causar conflitos)"
    else
        log_success "Console serial desabilitado"
    fi
else
    log_error "/boot/cmdline.txt não encontrado"
fi

echo
echo "📋 3. VERIFICAÇÃO DOS DISPOSITIVOS SERIAIS"
echo "=========================================="

# Verificar dispositivos seriais
DEVICES=("/dev/ttyAMA0" "/dev/ttyS0" "/dev/serial0" "/dev/serial1")
FOUND_DEVICE=""

for device in "${DEVICES[@]}"; do
    if [ -c "$device" ]; then
        log_success "Dispositivo encontrado: $device"
        ls -la "$device"
        FOUND_DEVICE="$device"
    else
        log_warning "Dispositivo não encontrado: $device"
    fi
done

if [ -z "$FOUND_DEVICE" ]; then
    log_error "Nenhum dispositivo serial encontrado!"
else
    # Testar comunicação com o dispositivo encontrado
    log_info "Testando comunicação com $FOUND_DEVICE..."
    
    # Verificar se o dispositivo está sendo usado
    if lsof "$FOUND_DEVICE" 2>/dev/null; then
        log_warning "Dispositivo está sendo usado por outro processo:"
        lsof "$FOUND_DEVICE"
    else
        log_success "Dispositivo está livre"
        
        # Testar leitura de dados
        log_info "Testando recepção de dados (5 segundos)..."
        timeout 5s cat "$FOUND_DEVICE" > /tmp/gps_diag_test.txt 2>/dev/null
        
        if [ -s /tmp/gps_diag_test.txt ]; then
            local data_size=$(wc -c < /tmp/gps_diag_test.txt)
            local nmea_count=$(grep -c '^\$' /tmp/gps_diag_test.txt 2>/dev/null || echo "0")
            
            log_success "Dados recebidos: $data_size bytes"
            log_success "Sentenças NMEA: $nmea_count"
            
            if [ "$nmea_count" -gt 0 ]; then
                log_info "Exemplos de sentenças NMEA:"
                head -5 /tmp/gps_diag_test.txt | grep '^\$' | while read line; do
                    echo "   $line"
                done
            fi
        else
            log_error "Nenhum dado recebido do dispositivo"
            log_error "Verifique se o módulo GNSS está conectado e funcionando"
        fi
        
        rm -f /tmp/gps_diag_test.txt
    fi
fi

echo
echo "📋 4. VERIFICAÇÃO DA REDE UDP"
echo "============================="

# Verificar portas UDP
log_info "Verificando portas UDP..."

PORTS=(9999 8888 15550 17770)
for port in "${PORTS[@]}"; do
    if netstat -ulnp 2>/dev/null | grep -q ":$port "; then
        local process=$(netstat -ulnp 2>/dev/null | grep ":$port " | awk '{print $7}')
        log_success "Porta $port está em uso por: $process"
    else
        log_warning "Porta $port está livre"
    fi
done

echo
echo "📋 5. VERIFICAÇÃO DOS PROCESSOS"
echo "==============================="

# Verificar processos GPS
log_info "Verificando processos GPS..."
check_process "gps_bridge.py"
check_process "QtAgIO"
check_process "QtAgOpenGPS"

echo
echo "📋 6. VERIFICAÇÃO DOS ARQUIVOS DO PROJETO"
echo "========================================"

# Definir diretório do projeto
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

log_info "Diretório do projeto: $PROJECT_DIR"

# Verificar scripts
log_info "Verificando scripts..."
check_file "$SCRIPT_DIR/gps_setup.sh"
check_file "$SCRIPT_DIR/test_serial.sh"
check_file "$SCRIPT_DIR/gps_bridge.py"
check_file "$SCRIPT_DIR/configure_m10fly.py"
check_file "$SCRIPT_DIR/start_gps_system.sh"

# Verificar executáveis compilados
log_info "Verificando executáveis compilados..."
check_file "$PROJECT_DIR/build/QtAgIO/QtAgIO"
check_file "$PROJECT_DIR/build/QtAgOpenGPS"

# Verificar permissões
log_info "Verificando permissões dos scripts..."
for script in gps_setup.sh test_serial.sh gps_bridge.py configure_m10fly.py start_gps_system.sh; do
    if [ -x "$SCRIPT_DIR/$script" ]; then
        log_success "$script é executável"
    else
        log_warning "$script não é executável"
        log_info "Execute: chmod +x $SCRIPT_DIR/$script"
    fi
done

echo
echo "📋 7. VERIFICAÇÃO DOS LOGS"
echo "========================="

# Verificar logs existentes
LOG_FILES=("/tmp/gps_bridge.log" "/tmp/agio.log" "/var/log/syslog")

for log_file in "${LOG_FILES[@]}"; do
    if [ -f "$log_file" ]; then
        log_success "Log encontrado: $log_file"
        local size=$(du -h "$log_file" | cut -f1)
        log_info "Tamanho: $size"
        
        # Mostrar últimas linhas se for log do GPS
        if [[ "$log_file" == *"gps"* ]] || [[ "$log_file" == *"agio"* ]]; then
            log_info "Últimas 3 linhas:"
            tail -3 "$log_file" 2>/dev/null | sed 's/^/   /'
        fi
    else
        log_warning "Log não encontrado: $log_file"
    fi
done

echo
echo "📋 8. VERIFICAÇÃO DOS SERVIÇOS SYSTEMD"
echo "======================================"

# Verificar serviços systemd
SERVICES=("gps-bridge.service" "agio.service")

for service in "${SERVICES[@]}"; do
    if systemctl list-unit-files | grep -q "$service"; then
        local status=$(systemctl is-enabled "$service" 2>/dev/null)
        local active=$(systemctl is-active "$service" 2>/dev/null)
        
        log_info "Serviço: $service"
        log_info "  Habilitado: $status"
        log_info "  Status: $active"
    else
        log_warning "Serviço não instalado: $service"
    fi
done

echo
echo "📋 9. RECOMENDAÇÕES"
echo "=================="

# Gerar recomendações baseadas nos testes
echo
if [ -z "$FOUND_DEVICE" ]; then
    log_error "CRÍTICO: Nenhum dispositivo serial encontrado"
    echo "   1. Verifique as conexões físicas do módulo GNSS"
    echo "   2. Execute: sudo ./gps_setup.sh"
    echo "   3. Reinicie o sistema: sudo reboot"
fi

if ! pgrep -f "gps_bridge.py" > /dev/null; then
    log_warning "GPS Bridge não está rodando"
    echo "   Execute: ./start_gps_system.sh start"
fi

if ! pgrep -f "QtAgIO" > /dev/null; then
    log_warning "QtAgIO não está rodando"
    echo "   1. Compile o projeto: cd build && make"
    echo "   2. Execute: ./start_gps_system.sh start"
fi

echo
echo "📋 10. COMANDOS ÚTEIS PARA DIAGNÓSTICO"
echo "====================================="
echo
echo "Testar dispositivo serial:"
echo "   sudo cat /dev/ttyAMA0"
echo
echo "Monitorar logs em tempo real:"
echo "   tail -f /tmp/gps_bridge.log"
echo "   tail -f /tmp/agio.log"
echo
echo "Verificar processos GPS:"
echo "   ps aux | grep -E '(gps_bridge|QtAgIO|QtAgOpenGPS)'"
echo
echo "Verificar portas UDP:"
echo "   sudo netstat -ulnp | grep -E '(9999|8888|15550)'"
echo
echo "Testar conectividade UDP:"
echo "   echo 'test' | nc -u 127.0.0.1 9999"
echo

echo "=== Diagnóstico Concluído ==="
echo "Salve esta saída para referência futura"