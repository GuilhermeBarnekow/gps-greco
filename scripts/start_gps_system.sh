#!/bin/bash
# Script principal para iniciar o sistema GPS completo
# Autor: Configuração QtAgOpenGPS

echo "=== Sistema GPS QtAgOpenGPS - Inicialização ==="
echo

# Definir diretórios
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para log colorido
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Verificar se está no diretório correto
if [ ! -f "$SCRIPT_DIR/gps_bridge.py" ]; then
    log_error "Scripts não encontrados. Execute este script do diretório correto."
    exit 1
fi

# Função para verificar se um processo está rodando
check_process() {
    local process_name="$1"
    pgrep -f "$process_name" > /dev/null
    return $?
}

# Função para parar processos existentes
stop_existing_processes() {
    log_info "Parando processos GPS existentes..."
    
    # Parar gps_bridge.py
    if check_process "gps_bridge.py"; then
        pkill -f "gps_bridge.py"
        sleep 2
        log_success "GPS Bridge parado"
    fi
    
    # Parar QtAgIO
    if check_process "QtAgIO"; then
        pkill -f "QtAgIO"
        sleep 2
        log_success "QtAgIO parado"
    fi
    
    # Parar QtAgOpenGPS
    if check_process "QtAgOpenGPS"; then
        pkill -f "QtAgOpenGPS"
        sleep 2
        log_success "QtAgOpenGPS parado"
    fi
}

# Função para verificar dispositivo serial
check_serial_device() {
    log_info "Verificando dispositivo serial..."
    
    local devices=("/dev/ttyAMA0" "/dev/ttyS0")
    local found_device=""
    
    for device in "${devices[@]}"; do
        if [ -c "$device" ]; then
            found_device="$device"
            break
        fi
    done
    
    if [ -z "$found_device" ]; then
        log_error "Nenhum dispositivo serial encontrado!"
        log_error "Verifique se:"
        log_error "  - O módulo GNSS está conectado"
        log_error "  - O UART foi habilitado (execute gps_setup.sh)"
        log_error "  - O sistema foi reiniciado após configuração"
        return 1
    fi
    
    log_success "Dispositivo serial encontrado: $found_device"
    
    # Testar se há dados chegando
    log_info "Testando comunicação serial (5 segundos)..."
    timeout 5s cat "$found_device" > /tmp/gps_test.txt 2>/dev/null
    
    if [ -s /tmp/gps_test.txt ]; then
        local nmea_count=$(grep -c '^\$' /tmp/gps_test.txt 2>/dev/null || echo "0")
        if [ "$nmea_count" -gt 0 ]; then
            log_success "Dados NMEA detectados ($nmea_count sentenças)"
            rm -f /tmp/gps_test.txt
            return 0
        else
            log_warning "Dados recebidos mas não são NMEA válidos"
        fi
    else
        log_warning "Nenhum dado recebido do módulo GPS"
    fi
    
    rm -f /tmp/gps_test.txt
    log_warning "Continuando mesmo sem dados (módulo pode estar inicializando)"
    return 0
}

# Função para iniciar GPS Bridge
start_gps_bridge() {
    log_info "Iniciando GPS Bridge..."
    
    # Verificar se o script existe e é executável
    if [ ! -f "$SCRIPT_DIR/gps_bridge.py" ]; then
        log_error "gps_bridge.py não encontrado!"
        return 1
    fi
    
    # Tornar executável
    chmod +x "$SCRIPT_DIR/gps_bridge.py"
    
    # Iniciar em background
    cd "$SCRIPT_DIR"
    python3 gps_bridge.py > /tmp/gps_bridge.log 2>&1 &
    local bridge_pid=$!
    
    # Aguardar inicialização
    sleep 3
    
    # Verificar se ainda está rodando
    if kill -0 $bridge_pid 2>/dev/null; then
        log_success "GPS Bridge iniciado (PID: $bridge_pid)"
        echo $bridge_pid > /tmp/gps_bridge.pid
        return 0
    else
        log_error "GPS Bridge falhou ao iniciar"
        log_error "Verifique o log: tail -f /tmp/gps_bridge.log"
        return 1
    fi
}

# Função para iniciar QtAgIO
start_agio() {
    log_info "Iniciando QtAgIO..."
    
    # Verificar se o executável existe
    local agio_path="$PROJECT_DIR/build/QtAgIO/QtAgIO"
    if [ ! -f "$agio_path" ]; then
        # Tentar localizar em outros lugares
        agio_path=$(find "$PROJECT_DIR" -name "QtAgIO" -type f -executable 2>/dev/null | head -1)
        
        if [ -z "$agio_path" ]; then
            log_error "QtAgIO não encontrado!"
            log_error "Compile o projeto primeiro: cd build && make"
            return 1
        fi
    fi
    
    log_info "Executável encontrado: $agio_path"
    
    # Iniciar QtAgIO em background
    cd "$PROJECT_DIR"
    "$agio_path" > /tmp/agio.log 2>&1 &
    local agio_pid=$!
    
    # Aguardar inicialização
    sleep 5
    
    # Verificar se ainda está rodando
    if kill -0 $agio_pid 2>/dev/null; then
        log_success "QtAgIO iniciado (PID: $agio_pid)"
        echo $agio_pid > /tmp/agio.pid
        return 0
    else
        log_error "QtAgIO falhou ao iniciar"
        log_error "Verifique o log: tail -f /tmp/agio.log"
        return 1
    fi
}

# Função para iniciar QtAgOpenGPS
start_qtag() {
    log_info "Iniciando QtAgOpenGPS..."
    
    # Verificar se o executável existe
    local qtag_path="$PROJECT_DIR/build/QtAgOpenGPS"
    if [ ! -f "$qtag_path" ]; then
        # Tentar localizar em outros lugares
        qtag_path=$(find "$PROJECT_DIR" -name "QtAgOpenGPS" -type f -executable 2>/dev/null | head -1)
        
        if [ -z "$qtag_path" ]; then
            log_error "QtAgOpenGPS não encontrado!"
            log_error "Compile o projeto primeiro: cd build && make"
            return 1
        fi
    fi
    
    log_info "Executável encontrado: $qtag_path"
    
    # Iniciar QtAgOpenGPS
    cd "$PROJECT_DIR"
    log_success "Iniciando interface principal..."
    "$qtag_path"
    
    return $?
}

# Função para mostrar status do sistema
show_status() {
    echo
    log_info "Status do Sistema GPS:"
    echo
    
    # GPS Bridge
    if check_process "gps_bridge.py"; then
        log_success "GPS Bridge: Rodando"
    else
        log_error "GPS Bridge: Parado"
    fi
    
    # QtAgIO
    if check_process "QtAgIO"; then
        log_success "QtAgIO: Rodando"
    else
        log_error "QtAgIO: Parado"
    fi
    
    # QtAgOpenGPS
    if check_process "QtAgOpenGPS"; then
        log_success "QtAgOpenGPS: Rodando"
    else
        log_warning "QtAgOpenGPS: Parado (normal se não foi iniciado)"
    fi
    
    echo
    log_info "Logs disponíveis:"
    echo "  GPS Bridge: tail -f /tmp/gps_bridge.log"
    echo "  QtAgIO: tail -f /tmp/agio.log"
    echo
}

# Função principal
main() {
    case "${1:-start}" in
        "start")
            log_info "Iniciando sistema GPS completo..."
            
            # Parar processos existentes
            stop_existing_processes
            
            # Verificar dispositivo serial
            if ! check_serial_device; then
                log_error "Falha na verificação do dispositivo serial"
                exit 1
            fi
            
            # Iniciar GPS Bridge
            if ! start_gps_bridge; then
                log_error "Falha ao iniciar GPS Bridge"
                exit 1
            fi
            
            # Aguardar um pouco
            sleep 2
            
            # Iniciar QtAgIO
            if ! start_agio; then
                log_error "Falha ao iniciar QtAgIO"
                exit 1
            fi
            
            # Aguardar um pouco mais
            sleep 3
            
            # Mostrar status
            show_status
            
            # Iniciar QtAgOpenGPS (interface principal)
            log_info "Pressione Enter para iniciar a interface principal..."
            read -r
            start_qtag
            ;;
            
        "stop")
            log_info "Parando sistema GPS..."
            stop_existing_processes
            log_success "Sistema GPS parado"
            ;;
            
        "status")
            show_status
            ;;
            
        "restart")
            log_info "Reiniciando sistema GPS..."
            stop_existing_processes
            sleep 2
            $0 start
            ;;
            
        *)
            echo "Uso: $0 {start|stop|status|restart}"
            echo
            echo "Comandos:"
            echo "  start   - Iniciar sistema GPS completo"
            echo "  stop    - Parar todos os processos GPS"
            echo "  status  - Mostrar status dos processos"
            echo "  restart - Reiniciar sistema GPS"
            exit 1
            ;;
    esac
}

# Executar função principal
main "$@"