# 🚀 Início Rápido - QtAgOpenGPS + Módulo GNSS M10Fly

## 📋 Resumo

Este guia mostra como configurar rapidamente o QtAgOpenGPS com o módulo GNSS Quescan M10Fly no Raspberry Pi 4.

## ⚡ Passos Rápidos

### 1. Preparar Scripts
```bash
# Tornar todos os scripts executáveis
chmod +x scripts/*.sh scripts/*.py
```

### 2. Corrigir Dependências (OBRIGATÓRIO)
```bash
# Corrigir repositórios e dependências do Raspberry Pi OS
sudo ./scripts/fix_rasppi_deps.sh
```

### 3. Compilar QtAgOpenGPS
```bash
# Compilação automática (15-30 minutos)
./scripts/build_qtag_rasppi.sh
```

### 4. Conectar Módulo M10Fly

**Conexões físicas:**
```
Módulo M10Fly    →    Raspberry Pi 4
─────────────────────────────────────
VCC (5V)        →    Pino 2 (5V)
GND             →    Pino 6 (GND)
TX              →    Pino 10 (GPIO 15)
RX              →    Pino 8 (GPIO 14)
```

### 5. Configurar Sistema GPS
```bash
# Configurar UART e sistema
sudo ./scripts/gps_setup.sh

# OBRIGATÓRIO: Reiniciar
sudo reboot
```

### 6. Testar e Iniciar
```bash
# Após reiniciar, testar comunicação
./scripts/test_serial.sh

# Se OK, iniciar sistema completo
./scripts/start_gps_system.sh start
```

## 🔧 Resolução de Problemas

### Problema: Compilação falha
```bash
# Executar diagnóstico
./scripts/diagnose_gps.sh

# Verificar logs
tail -f /tmp/build.log
```

### Problema: Módulo GPS não responde
```bash
# Testar comunicação serial
./scripts/test_serial.sh

# Configurar módulo
python3 ./scripts/configure_m10fly.py
```

### Problema: QtAgOpenGPS não recebe GPS
```bash
# Verificar status do sistema
./scripts/start_gps_system.sh status

# Ver logs em tempo real
tail -f /tmp/gps_bridge.log
tail -f /tmp/agio.log
```

## 📊 Comandos Úteis

```bash
# Status do sistema
./scripts/start_gps_system.sh status

# Parar sistema
./scripts/start_gps_system.sh stop

# Reiniciar sistema
./scripts/start_gps_system.sh restart

# Diagnóstico completo
./scripts/diagnose_gps.sh

# Instalar serviços automáticos
sudo ./scripts/install_service.sh
```

## 📚 Documentação Completa

- **Guia detalhado:** [`GPS_M10FLY_SETUP.md`](GPS_M10FLY_SETUP.md)
- **Scripts:** [`scripts/README.md`](scripts/README.md)
- **Instalação:** [`instalacao.txt`](instalacao.txt)

## ✅ Verificação de Sucesso

**Sistema funcionando corretamente quando:**
- ✅ Módulo M10Fly conectado e enviando dados NMEA
- ✅ GPS Bridge convertendo serial para UDP
- ✅ QtAgIO processando dados GPS
- ✅ QtAgOpenGPS mostrando posição em tempo real
- ✅ Ícone GPS verde na interface
- ✅ Coordenadas atualizando continuamente

## 🎯 Próximos Passos

1. **Calibrar sistema** em campo aberto
2. **Configurar veículo** (dimensões, antena)
3. **Testar navegação** e controle de seções
4. **Configurar RTK** para precisão centimétrica (opcional)

---

**Tempo estimado:** 45-60 minutos (incluindo compilação)  
**Dificuldade:** Intermediária  
**Requisitos:** Raspberry Pi 4, 4GB+ RAM, conexão internet