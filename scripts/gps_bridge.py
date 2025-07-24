#!/usr/bin/env python3
"""
GPS Bridge - Ponte Serial para UDP
Conecta módulo GNSS M10Fly (serial) ao QtAgOpenGPS (UDP)

Autor: Configuração QtAgOpenGPS
Compatível com: Quescan M10Fly, u-blox M10, outros módulos NMEA
"""

import serial
import socket
import threading
import time
import sys
import signal
import logging
from datetime import datetime

class GPSBridge:
    def __init__(self):
        # Configurações do dispositivo serial
        self.serial_device = "/dev/ttyAMA0"  # Porta UART primária
        self.serial_device_alt = "/dev/ttyS0"  # Porta alternativa
        self.baud_rate = 115200  # Baud rate do M10Fly
        
        # Configurações UDP para QtAgIO
        self.udp_host = "127.0.0.1"  # Localhost
        self.udp_port = 9999  # Porta padrão do QtAgIO
        
        # Configurações de controle
        self.running = False
        self.serial_conn = None
        self.udp_socket = None
        
        # Estatísticas
        self.sentences_received = 0
        self.sentences_sent = 0
        self.errors = 0
        self.start_time = None
        
        # Configurar logging
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(levelname)s - %(message)s',
            handlers=[
                logging.FileHandler('/tmp/gps_bridge.log'),
                logging.StreamHandler(sys.stdout)
            ]
        )
        self.logger = logging.getLogger(__name__)
        
    def setup_serial(self):
        """Configurar conexão serial com o módulo GNSS"""
        devices_to_try = [self.serial_device, self.serial_device_alt]
        
        for device in devices_to_try:
            try:
                self.logger.info(f"Tentando conectar em {device}...")
                self.serial_conn = serial.Serial(
                    port=device,
                    baudrate=self.baud_rate,
                    bytesize=serial.EIGHTBITS,
                    parity=serial.PARITY_NONE,
                    stopbits=serial.STOPBITS_ONE,
                    timeout=1,
                    xonxoff=False,
                    rtscts=False,
                    dsrdtr=False
                )
                
                # Testar se está recebendo dados
                self.logger.info(f"Testando comunicação em {device}...")
                test_start = time.time()
                while time.time() - test_start < 5:  # Testar por 5 segundos
                    if self.serial_conn.in_waiting > 0:
                        test_data = self.serial_conn.readline().decode('ascii', errors='ignore').strip()
                        if test_data.startswith('$') and ',' in test_data:
                            self.logger.info(f"✅ Conexão estabelecida em {device}")
                            self.logger.info(f"Exemplo de dados: {test_data[:50]}...")
                            return True
                    time.sleep(0.1)
                
                # Se chegou aqui, não recebeu dados válidos
                self.serial_conn.close()
                self.logger.warning(f"Nenhum dado NMEA recebido em {device}")
                
            except Exception as e:
                self.logger.error(f"Erro ao conectar em {device}: {e}")
                if self.serial_conn:
                    self.serial_conn.close()
                    self.serial_conn = None
        
        return False
    
    def setup_udp(self):
        """Configurar socket UDP para envio ao QtAgIO"""
        try:
            self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.udp_socket.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            self.logger.info(f"✅ Socket UDP configurado para {self.udp_host}:{self.udp_port}")
            return True
        except Exception as e:
            self.logger.error(f"Erro ao configurar UDP: {e}")
            return False
    
    def validate_nmea_checksum(self, sentence):
        """Validar checksum de sentença NMEA"""
        if '*' not in sentence:
            return False
        
        try:
            data, checksum = sentence.split('*')
            data = data[1:]  # Remove o '$'
            
            calculated_checksum = 0
            for char in data:
                calculated_checksum ^= ord(char)
            
            return format(calculated_checksum, '02X') == checksum.upper()
        except:
            return False
    
    def process_nmea_sentence(self, sentence):
        """Processar e filtrar sentenças NMEA"""
        sentence = sentence.strip()
        
        # Verificar se é uma sentença NMEA válida
        if not sentence.startswith('$') or ',' not in sentence:
            return None
        
        # Validar checksum se presente
        if '*' in sentence and not self.validate_nmea_checksum(sentence):
            self.logger.warning(f"Checksum inválido: {sentence[:30]}...")
            return None
        
        # Filtrar sentenças importantes para QtAgOpenGPS
        important_sentences = ['GGA', 'RMC', 'VTG', 'HDT', 'GSA']
        sentence_type = sentence[3:6] if len(sentence) > 6 else ""
        
        if any(sentence_type == s for s in important_sentences):
            return sentence
        
        # Também aceitar sentenças com prefixos diferentes (GP, GN, GL, etc.)
        if len(sentence) > 6:
            sentence_type = sentence[1:6]  # Pegar GPGGA, GNRMC, etc.
            if any(sentence_type.endswith(s) for s in important_sentences):
                return sentence
        
        return None
    
    def send_udp_packet(self, data):
        """Enviar dados via UDP para QtAgIO"""
        try:
            # Formato esperado pelo QtAgIO (baseado na análise do código)
            # Adicionar quebra de linha se não tiver
            if not data.endswith('\n'):
                data += '\n'
            
            # Enviar dados
            self.udp_socket.sendto(data.encode('ascii'), (self.udp_host, self.udp_port))
            self.sentences_sent += 1
            return True
        except Exception as e:
            self.logger.error(f"Erro ao enviar UDP: {e}")
            self.errors += 1
            return False
    
    def serial_reader_thread(self):
        """Thread para ler dados da porta serial"""
        self.logger.info("🔄 Thread de leitura serial iniciada")
        
        while self.running:
            try:
                if self.serial_conn and self.serial_conn.in_waiting > 0:
                    # Ler linha da porta serial
                    raw_data = self.serial_conn.readline()
                    sentence = raw_data.decode('ascii', errors='ignore').strip()
                    
                    if sentence:
                        self.sentences_received += 1
                        
                        # Processar sentença NMEA
                        processed_sentence = self.process_nmea_sentence(sentence)
                        
                        if processed_sentence:
                            # Enviar via UDP
                            if self.send_udp_packet(processed_sentence):
                                self.logger.debug(f"📡 Enviado: {processed_sentence[:50]}...")
                            
                        # Log periódico de estatísticas
                        if self.sentences_received % 100 == 0:
                            self.print_statistics()
                
                time.sleep(0.01)  # Pequena pausa para não sobrecarregar CPU
                
            except Exception as e:
                self.logger.error(f"Erro na thread de leitura: {e}")
                self.errors += 1
                time.sleep(1)
    
    def print_statistics(self):
        """Imprimir estatísticas de funcionamento"""
        if self.start_time:
            uptime = time.time() - self.start_time
            rate = self.sentences_received / uptime if uptime > 0 else 0
            
            self.logger.info(f"📊 Stats: Recebidas={self.sentences_received}, "
                           f"Enviadas={self.sentences_sent}, Erros={self.errors}, "
                           f"Taxa={rate:.1f}/s, Uptime={uptime:.0f}s")
    
    def signal_handler(self, signum, frame):
        """Handler para sinais de sistema (Ctrl+C)"""
        self.logger.info("🛑 Sinal de parada recebido...")
        self.stop()
    
    def start(self):
        """Iniciar a ponte GPS"""
        self.logger.info("🚀 Iniciando GPS Bridge...")
        
        # Configurar handlers de sinal
        signal.signal(signal.SIGINT, self.signal_handler)
        signal.signal(signal.SIGTERM, self.signal_handler)
        
        # Configurar conexões
        if not self.setup_serial():
            self.logger.error("❌ Falha ao configurar conexão serial")
            return False
        
        if not self.setup_udp():
            self.logger.error("❌ Falha ao configurar conexão UDP")
            return False
        
        # Iniciar operação
        self.running = True
        self.start_time = time.time()
        
        # Iniciar thread de leitura serial
        serial_thread = threading.Thread(target=self.serial_reader_thread, daemon=True)
        serial_thread.start()
        
        self.logger.info("✅ GPS Bridge iniciado com sucesso!")
        self.logger.info(f"📡 Serial: {self.serial_conn.port} @ {self.baud_rate}")
        self.logger.info(f"🌐 UDP: {self.udp_host}:{self.udp_port}")
        self.logger.info("Pressione Ctrl+C para parar")
        
        # Loop principal
        try:
            while self.running:
                time.sleep(1)
                
        except KeyboardInterrupt:
            self.logger.info("Interrompido pelo usuário")
        
        self.stop()
        return True
    
    def stop(self):
        """Parar a ponte GPS"""
        self.logger.info("🛑 Parando GPS Bridge...")
        self.running = False
        
        # Fechar conexões
        if self.serial_conn:
            self.serial_conn.close()
            self.logger.info("📱 Conexão serial fechada")
        
        if self.udp_socket:
            self.udp_socket.close()
            self.logger.info("🌐 Socket UDP fechado")
        
        # Estatísticas finais
        self.print_statistics()
        self.logger.info("✅ GPS Bridge parado")

def main():
    """Função principal"""
    print("=== GPS Bridge para QtAgOpenGPS ===")
    print("Conectando módulo GNSS M10Fly ao QtAgIO via UDP")
    print()
    
    bridge = GPSBridge()
    
    try:
        success = bridge.start()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"❌ Erro fatal: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()