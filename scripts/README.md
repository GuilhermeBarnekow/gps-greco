# Scripts de Configuração GPS M10Fly

Este diretório contém todos os scripts necessários para configurar o módulo GNSS Quescan M10Fly com o QtAgOpenGPS.

## 🚀 Início Rápido

```bash
# 1. Tornar scripts executáveis
chmod +x scripts/*.sh scripts/*.py

# 2. Configurar sistema (como root)
sudo ./gps_setup.sh

# 3. Reiniciar sistema
sudo reboot

# 4. Testar comunicação
./test_serial.sh

# 5. Iniciar sistema GPS
./start_gps_system.sh start
```

## 📋 Scripts Disponíveis

### Configuração Inicial
- **`make_executable.sh`** - Torna todos os scripts executáveis
- **`gps_setup.sh`** - Configuração inicial do sistema (requer sudo)

### Testes e Diagnóstico
- **`test_serial.sh`** - Testa comunicação serial básica
- **`diagnose_gps.sh`** - Diagnóstico completo do sistema

### Configuração do Módulo
- **`configure_m10fly.py`** - Configura módulo M10Fly para uso otimizado

### Sistema Principal
- **`gps_bridge.py`** - Ponte serial-para-UDP (processo principal)
- **`start_gps_system.sh`** - Controla todo o sistema GPS

### Serviços Automáticos
- **`install_service.sh`** - Instala serviços systemd (requer sudo)

## 🔧 Ordem de Execução

1. **Primeira vez:**
   ```bash
   ./make_executable.sh
   sudo ./gps_setup.sh
   sudo reboot
   ```

2. **Após reiniciar:**
   ```bash
   ./test_serial.sh
   python3 ./configure_m10fly.py
   ./start_gps_system.sh start
   ```

3. **Para uso diário:**
   ```bash
   ./start_gps_system.sh start
   ```

## 📊 Logs e Monitoramento

```bash
# Ver logs em tempo real
tail -f /tmp/gps_bridge.log
tail -f /tmp/agio.log

# Status do sistema
./start_gps_system.sh status

# Diagnóstico completo
./diagnose_gps.sh
```

## 🆘 Resolução de Problemas

Se algo não funcionar:

1. **Execute diagnóstico:**
   ```bash
   ./diagnose_gps.sh
   ```

2. **Verifique logs:**
   ```bash
   tail -f /tmp/gps_bridge.log
   ```

3. **Reinicie sistema:**
   ```bash
   ./start_gps_system.sh restart
   ```

## 📚 Documentação Completa

Consulte `../GPS_M10FLY_SETUP.md` para documentação detalhada.