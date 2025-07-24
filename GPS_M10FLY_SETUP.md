# Configuração do Módulo GNSS Quescan M10Fly para QtAgOpenGPS

## 📋 Visão Geral

Este guia completo mostra como configurar o módulo GNSS Quescan M10Fly com o QtAgOpenGPS no Raspberry Pi 4, conectado via UART/GPIO.

### 🎯 Objetivos
- Conectar fisicamente o módulo M10Fly ao Raspberry Pi
- Configurar o sistema para comunicação serial
- Criar ponte serial-para-UDP para compatibilidade com QtAgOpenGPS
- Configurar e testar o sistema completo

### 📊 Especificações do Sistema
- **Módulo GNSS**: Quescan M10Fly (u-blox M10 chipset)
- **Baud Rate**: 115200 (máximo suportado)
- **Conexão**: UART/GPIO (pinos 14/15)
- **Sistema**: Raspberry Pi 4 com Raspberry Pi OS
- **Software**: QtAgOpenGPS + QtAgIO

---

## 🔌 Fase 1: Conexão Física

### Diagrama de Conexões

```
Módulo M10Fly    →    Raspberry Pi 4
─────────────────────────────────────
VCC (3.3V/5V)   →    Pino 2 (5V) ou Pino 4 (5V)
GND             →    Pino 6 (GND) ou qualquer GND
TX              →    Pino 10 (GPIO 15 - RX)
RX              →    Pino 8 (GPIO 14 - TX)
```

### ⚠️ Importante
- **Verifique a tensão**: Alguns módulos M10Fly operam em 3.3V, outros em 5V
- **Não inverta TX/RX**: TX do módulo vai para RX do Pi (GPIO 15)
- **Conexão firme**: Use jumpers de qualidade ou solde as conexões

### 🔧 Passos da Conexão
1. **Desligue o Raspberry Pi** completamente
2. **Identifique os pinos** usando o diagrama GPIO do Pi
3. **Conecte os fios** seguindo o diagrama acima
4. **Verifique as conexões** antes de ligar
5. **Ligue o Raspberry Pi**

---

## ⚙️ Fase 2: Configuração do Sistema

### 2.1 Executar Configuração Inicial

```bash
# Navegar para o diretório do projeto
cd /home/desenvolvimento/QtAgOpenGPS

# Tornar scripts executáveis
chmod +x scripts/*.sh scripts/*.py

# Executar configuração do sistema (como root)
sudo ./scripts/gps_setup.sh
```

### 2.2 Reiniciar o Sistema

```bash
# OBRIGATÓRIO: Reiniciar para aplicar configurações UART
sudo reboot
```

### 2.3 Verificar Configuração

Após reiniciar:

```bash
# Executar diagnóstico completo
./scripts/diagnose_gps.sh
```

---

## 🧪 Fase 3: Testes de Comunicação

### 3.1 Teste Serial Básico

```bash
# Testar comunicação serial com o módulo
./scripts/test_serial.sh
```

**Resultado esperado:**
```
✅ Dispositivo encontrado: /dev/ttyAMA0
✅ NMEA recebido: $GPGGA,123456.00,1234.56789,N,12345.67890,W,1,08,1.0,123.4,M,45.6,M,,*47
   📍 Sentença GGA (Posição GPS) detectada
✅ Teste concluído com sucesso!
```

### 3.2 Configurar Módulo M10Fly

```bash
# Configurar módulo para uso otimizado
python3 ./scripts/configure_m10fly.py
```

**Este script irá:**
- Configurar taxa de atualização para 10Hz
- Habilitar sentenças NMEA importantes (GGA, RMC, VTG, GSA)
- Desabilitar sentenças desnecessárias
- Salvar configuração na memória do módulo

---

## 🚀 Fase 4: Inicialização do Sistema GPS

### 4.1 Compilar QtAgOpenGPS (se necessário)

```bash
# Navegar para diretório de build
cd /home/desenvolvimento/QtAgOpenGPS
mkdir -p build && cd build

# Compilar projeto
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j4
```

### 4.2 Iniciar Sistema Completo

```bash
# Voltar para diretório principal
cd /home/desenvolvimento/QtAgOpenGPS

# Iniciar sistema GPS completo
./scripts/start_gps_system.sh start
```

**O script irá:**
1. ✅ Verificar dispositivo serial
2. ✅ Iniciar GPS Bridge (ponte serial-UDP)
3. ✅ Iniciar QtAgIO (processamento NMEA)
4. ✅ Aguardar confirmação para iniciar QtAgOpenGPS

### 4.3 Verificar Status

```bash
# Verificar status dos processos
./scripts/start_gps_system.sh status
```

---

## 🔧 Fase 5: Configuração Avançada

### 5.1 Instalar Serviços Automáticos

```bash
# Instalar serviços systemd para inicialização automática
sudo ./scripts/install_service.sh
```

### 5.2 Comandos de Controle dos Serviços

```bash
# Iniciar serviços
sudo systemctl start gps-bridge agio

# Parar serviços
sudo systemctl stop gps-bridge agio

# Ver status
sudo systemctl status gps-bridge agio

# Ver logs em tempo real
sudo journalctl -u gps-bridge -f
sudo journalctl -u agio -f
```

---

## 📊 Fase 6: Monitoramento e Logs

### 6.1 Logs Principais

```bash
# Log do GPS Bridge
tail -f /tmp/gps_bridge.log

# Log do QtAgIO
tail -f /tmp/agio.log

# Logs do sistema
sudo journalctl -u gps-bridge -f
sudo journalctl -u agio -f
```

### 6.2 Estatísticas em Tempo Real

O GPS Bridge mostra estatísticas a cada 100 sentenças processadas:

```
📊 Stats: Recebidas=500, Enviadas=450, Erros=0, Taxa=8.5/s, Uptime=60s
```

---

## 🛠️ Resolução de Problemas

### Problema: Nenhum dispositivo serial encontrado

**Sintomas:**
```
❌ Nenhum dispositivo serial encontrado!
```

**Soluções:**
1. Verificar conexões físicas
2. Executar `sudo ./scripts/gps_setup.sh`
3. Reiniciar: `sudo reboot`
4. Verificar se UART está habilitado: `cat /boot/config.txt | grep uart`

### Problema: Dados recebidos mas não são NMEA

**Sintomas:**
```
📄 Dados recebidos: 
```

**Soluções:**
1. Verificar baud rate: pode ser 9600 em vez de 115200
2. Verificar conexões TX/RX (podem estar invertidas)
3. Executar `python3 ./scripts/configure_m10fly.py`

### Problema: GPS Bridge não conecta ao QtAgIO

**Sintomas:**
```
❌ Erro ao enviar UDP: [Errno 111] Connection refused
```

**Soluções:**
1. Verificar se QtAgIO está rodando: `ps aux | grep QtAgIO`
2. Verificar portas UDP: `netstat -ulnp | grep 9999`
3. Reiniciar sistema: `./scripts/start_gps_system.sh restart`

### Problema: QtAgOpenGPS não recebe dados GPS

**Sintomas:**
- Interface mostra "No GPS" ou posição fixa
- Não há movimento no mapa

**Soluções:**
1. Verificar se todos os processos estão rodando:
   ```bash
   ./scripts/start_gps_system.sh status
   ```
2. Verificar logs:
   ```bash
   tail -f /tmp/gps_bridge.log
   tail -f /tmp/agio.log
   ```
3. Executar diagnóstico completo:
   ```bash
   ./scripts/diagnose_gps.sh
   ```

---

## 📋 Comandos de Referência Rápida

### Controle do Sistema
```bash
# Iniciar sistema completo
./scripts/start_gps_system.sh start

# Parar sistema
./scripts/start_gps_system.sh stop

# Reiniciar sistema
./scripts/start_gps_system.sh restart

# Ver status
./scripts/start_gps_system.sh status
```

### Testes e Diagnóstico
```bash
# Teste serial básico
./scripts/test_serial.sh

# Configurar módulo
python3 ./scripts/configure_m10fly.py

# Diagnóstico completo
./scripts/diagnose_gps.sh
```

### Monitoramento
```bash
# Logs em tempo real
tail -f /tmp/gps_bridge.log
tail -f /tmp/agio.log

# Status dos serviços
sudo systemctl status gps-bridge agio

# Processos GPS
ps aux | grep -E '(gps_bridge|QtAgIO|QtAgOpenGPS)'
```

---

## 🎯 Configurações do QtAgOpenGPS

### Configurações Recomendadas

Após iniciar o QtAgOpenGPS, configure:

1. **GPS Settings:**
   - Source: UDP (padrão)
   - Port: 15550 (padrão)
   - Baud Rate: N/A (UDP)

2. **Vehicle Settings:**
   - Configure dimensões do seu veículo
   - Posição da antena GPS
   - Largura da ferramenta

3. **Field Settings:**
   - Crie um novo campo
   - Configure limites se necessário

### Verificação de Funcionamento

**Indicadores de sucesso:**
- ✅ Ícone GPS verde na interface
- ✅ Coordenadas atualizando em tempo real
- ✅ Movimento visível no mapa
- ✅ Número de satélites > 4
- ✅ HDOP < 2.0 (precisão boa)

---

## 🔧 Configurações Avançadas

### RTK/NTRIP (Opcional)

Para precisão centimétrica, configure correções RTK:

1. **No QtAgIO:**
   - Habilitar NTRIP
   - Configurar servidor de correções
   - Inserir credenciais

2. **Verificar:**
   - Status RTK na interface
   - Precisão melhorada (< 10cm)

### Configurações de Performance

**Para melhor performance:**
```bash
# Aumentar prioridade do GPS Bridge
sudo nice -n -10 python3 ./scripts/gps_bridge.py

# Configurar CPU governor para performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor
```

---

## 📚 Arquivos Criados

### Scripts Principais
- `scripts/gps_setup.sh` - Configuração inicial do sistema
- `scripts/test_serial.sh` - Teste de comunicação serial
- `scripts/gps_bridge.py` - Ponte serial-para-UDP
- `scripts/configure_m10fly.py` - Configuração do módulo
- `scripts/start_gps_system.sh` - Controle do sistema
- `scripts/install_service.sh` - Instalação de serviços
- `scripts/diagnose_gps.sh` - Diagnóstico completo

### Logs e Configurações
- `/tmp/gps_bridge.log` - Log do GPS Bridge
- `/tmp/agio.log` - Log do QtAgIO
- `/etc/systemd/system/gps-bridge.service` - Serviço GPS Bridge
- `/etc/systemd/system/agio.service` - Serviço QtAgIO

---

## 🎉 Conclusão

Após seguir este guia, você terá:

✅ **Módulo M10Fly conectado e funcionando**
✅ **Sistema GPS integrado ao QtAgOpenGPS**
✅ **Inicialização automática configurada**
✅ **Ferramentas de diagnóstico disponíveis**
✅ **Sistema pronto para agricultura de precisão**

### Próximos Passos

1. **Calibrar sistema** em campo aberto
2. **Configurar implementos** agrícolas
3. **Testar navegação** e controle de seções
4. **Configurar RTK** para precisão centimétrica (opcional)

### Suporte

Para problemas ou dúvidas:
1. Execute `./scripts/diagnose_gps.sh` e analise a saída
2. Verifique logs em `/tmp/gps_bridge.log` e `/tmp/agio.log`
3. Consulte a documentação do QtAgOpenGPS
4. Participe da comunidade AgOpenGPS

---

**Autor:** Configuração QtAgOpenGPS  
**Data:** $(date)  
**Versão:** 1.0  
**Compatibilidade:** Raspberry Pi 4, Quescan M10Fly, QtAgOpenGPS