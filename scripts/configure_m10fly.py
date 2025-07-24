#!/usr/bin/env python3
"""
Configurador do Módulo GNSS M10Fly
Configura o módulo u-blox M10 para uso otimizado com QtAgOpenGPS

Autor: Configuração QtAgOpenGPS
Compatível com: Quescan M10Fly, u-blox M10
"""

import serial
import time
import sys
import logging

class M10FlyConfigurator:
    def __init__(self):
        self.serial_device = "/dev/ttyAMA0"
        self.serial_device_alt = "/dev/ttyS0"
        self.baud_rate = 115200
        self.serial_conn = None
        
        # Configurar logging
        logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
        self.logger = logging.getLogger(__name__)
        
        # Comandos UBX para configuração do M10
        self.ubx_commands = {
            # Configurar taxa de atualização para 10Hz (100ms)
            'set_rate_10hz': bytes([
                0xB5, 0x62, 0x06, 0x08, 0x06, 0x00,
                0x64, 0x00, 0x01, 0x00, 0x01, 0x00,
                0x7A, 0x12
            ]),
            
            # Habilitar sentenças NMEA importantes
            'enable_gga': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x00, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01,
                0x05, 0x38
            ]),
            
            'enable_rmc': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x04, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01,
                0x09, 0x54
            ]),
            
            'enable_vtg': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x05, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01,
                0x0A, 0x5B
            ]),
            
            'enable_gsa': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x02, 0x00, 0x01, 0x01, 0x01, 0x01, 0x01,
                0x07, 0x47
            ]),
            
            # Desabilitar sentenças desnecessárias
            'disable_gll': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x2A
            ]),
            
            'disable_gsv': bytes([
                0xB5, 0x62, 0x06, 0x01, 0x08, 0x00,
                0xF0, 0x03, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x02, 0x38
            ]),
            
            # Salvar configuração na memória não-volátil
            'save_config': bytes([
                0xB5, 0x62, 0x06, 0x09, 0x0D, 0x00,
                0x00, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x03, 0x1D, 0xAB
            ])
        }
        
        # Comandos NMEA alternativos (caso UBX não funcione)
        self.nmea_commands = [
            # Configurar taxa para 10Hz
            "$PUBX,40,GGA,0,1,0,0,0,0*5A\r\n",  # GGA a cada 1 segundo
            "$PUBX,40,RMC,0,1,0,0,0,0*46\r\n",  # RMC a cada 1 segundo
            "$PUBX,40,VTG,0,1,0,0,0,0*5E\r\n",  # VTG a cada 1 segundo
            "$PUBX,40,GSA,0,1,0,0,0,0*4E\r\n",  # GSA a cada 1 segundo
            "$PUBX,40,GLL,0,0,0,0,0,0*5C\r\n",  # Desabilitar GLL
            "$PUBX,40,GSV,0,0,0,0,0,0*59\r\n",  # Desabilitar GSV
        ]
    
    def connect_serial(self):
        """Conectar à porta serial"""
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
                    timeout=2,
                    xonxoff=False,
                    rtscts=False,
                    dsrdtr=False
                )
                
                self.logger.info(f"✅ Conectado em {device}")
                return True
                
            except Exception as e:
                self.logger.error(f"Erro ao conectar em {device}: {e}")
        
        return False
    
    def send_ubx_command(self, command_name, command_bytes):
        """Enviar comando UBX para o módulo"""
        try:
            self.logger.info(f"Enviando comando UBX: {command_name}")
            self.serial_conn.write(command_bytes)
            self.serial_conn.flush()
            
            # Aguardar resposta
            time.sleep(0.5)
            
            # Ler resposta (se houver)
            if self.serial_conn.in_waiting > 0:
                response = self.serial_conn.read(self.serial_conn.in_waiting)
                self.logger.debug(f"Resposta: {response.hex()}")
            
            return True
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar comando {command_name}: {e}")
            return False
    
    def send_nmea_command(self, command):
        """Enviar comando NMEA para o módulo"""
        try:
            self.logger.info(f"Enviando comando NMEA: {command.strip()}")
            self.serial_conn.write(command.encode('ascii'))
            self.serial_conn.flush()
            
            time.sleep(0.5)
            return True
            
        except Exception as e:
            self.logger.error(f"Erro ao enviar comando NMEA: {e}")
            return False
    
    def read_current_config(self):
        """Ler configuração atual do módulo"""
        self.logger.info("📋 Lendo configuração atual...")
        
        # Limpar buffer
        self.serial_conn.reset_input_buffer()
        
        # Aguardar algumas sentenças NMEA
        sentences = []
        start_time = time.time()
        
        while time.time() - start_time < 10 and len(sentences) < 20:
            if self.serial_conn.in_waiting > 0:
                line = self.serial_conn.readline().decode('ascii', errors='ignore').strip()
                if line.startswith('$'):
                    sentences.append(line)
        
        # Analisar sentenças recebidas
        sentence_types = {}
        for sentence in sentences:
            if len(sentence) > 6:
                sentence_type = sentence[1:6]  # Ex: GPGGA, GNRMC
                sentence_types[sentence_type] = sentence_types.get(sentence_type, 0) + 1
        
        self.logger.info("📊 Sentenças NMEA detectadas:")
        for sentence_type, count in sentence_types.items():
            self.logger.info(f"   {sentence_type}: {count} vezes")
        
        return sentence_types
    
    def configure_module(self):
        """Configurar o módulo M10Fly"""
        self.logger.info("🔧 Iniciando configuração do módulo M10Fly...")
        
        if not self.connect_serial():
            self.logger.error("❌ Falha ao conectar com o módulo")
            return False
        
        # Ler configuração atual
        current_config = self.read_current_config()
        
        # Tentar configuração via comandos UBX primeiro
        self.logger.info("🔄 Tentando configuração via comandos UBX...")
        ubx_success = True
        
        for command_name, command_bytes in self.ubx_commands.items():
            if not self.send_ubx_command(command_name, command_bytes):
                ubx_success = False
                break
            time.sleep(1)  # Pausa entre comandos
        
        if ubx_success:
            self.logger.info("✅ Configuração UBX aplicada com sucesso")
        else:
            self.logger.warning("⚠️  Configuração UBX falhou, tentando comandos NMEA...")
            
            # Tentar configuração via comandos NMEA
            for command in self.nmea_commands:
                self.send_nmea_command(command)
                time.sleep(1)
        
        # Aguardar aplicação das configurações
        self.logger.info("⏳ Aguardando aplicação das configurações...")
        time.sleep(3)
        
        # Verificar nova configuração
        self.logger.info("🔍 Verificando nova configuração...")
        new_config = self.read_current_config()
        
        # Comparar configurações
        self.logger.info("📊 Comparação de configurações:")
        all_sentence_types = set(current_config.keys()) | set(new_config.keys())
        
        for sentence_type in sorted(all_sentence_types):
            old_count = current_config.get(sentence_type, 0)
            new_count = new_config.get(sentence_type, 0)
            
            if old_count != new_count:
                status = "📈" if new_count > old_count else "📉" if new_count < old_count else "➡️"
                self.logger.info(f"   {sentence_type}: {old_count} → {new_count} {status}")
        
        # Verificar se as sentenças importantes estão presentes
        important_sentences = ['GPGGA', 'GNRMC', 'GPVTG', 'GNGGA', 'GPRMC']
        found_important = any(s in new_config for s in important_sentences)
        
        if found_important:
            self.logger.info("✅ Configuração concluída com sucesso!")
            self.logger.info("📡 Sentenças NMEA importantes detectadas")
            return True
        else:
            self.logger.warning("⚠️  Configuração pode não ter sido aplicada corretamente")
            self.logger.warning("📡 Verifique se o módulo está funcionando")
            return False
    
    def __del__(self):
        """Fechar conexão serial ao destruir objeto"""
        if self.serial_conn:
            self.serial_conn.close()

def main():
    """Função principal"""
    print("=== Configurador do Módulo GNSS M10Fly ===")
    print("Otimizando configurações para QtAgOpenGPS")
    print()
    
    configurator = M10FlyConfigurator()
    
    try:
        success = configurator.configure_module()
        
        if success:
            print("\n✅ Módulo configurado com sucesso!")
            print("📋 Próximos passos:")
            print("   1. Execute: ./gps_bridge.py")
            print("   2. Inicie o QtAgIO")
            print("   3. Inicie o QtAgOpenGPS")
        else:
            print("\n⚠️  Configuração pode ter falhado")
            print("📋 Verifique:")
            print("   - Conexões físicas do módulo")
            print("   - Se o módulo está recebendo energia")
            print("   - Se o UART está habilitado")
        
        sys.exit(0 if success else 1)
        
    except KeyboardInterrupt:
        print("\n🛑 Configuração interrompida pelo usuário")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Erro durante configuração: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()