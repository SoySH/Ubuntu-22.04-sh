#!/bin/bash

# Encabezado persistente
clear
echo "========================================="
echo ">>> INSTALANDO KUMA <<<"
echo ">>> @slayerpsy <<<"
echo ">>> YOUTUBE <<<"
echo "========================================="

# Función para mostrar barra de progreso
show_progress() {
    local completed=$1
    local total=$2
    local width=50
    local percent=$((completed * 100 / total))
    local filled=$((width * completed / total))
    local empty=$((width - filled))
    
    echo -ne "\r["
    printf "%0.s#" $(seq 1 $filled)
    printf "%0.s " $(seq 1 $empty)
    printf "] %3d%%" "$percent"
}

# Total de pasos del proceso
TOTAL_STEPS=10
CURRENT_STEP=0

# Mostrar barra de progreso inicial
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 1: Actualizar el sistema
sudo apt update -y > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 2: Instalar dependencias necesarias
sudo apt install curl git build-essential python3 g++ make -y > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 3: Instalar Node.js (versión LTS)
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - > /dev/null 2>&1
sudo apt install nodejs -y > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 4: Clonar el repositorio de Uptime Kuma
git clone https://github.com/louislam/uptime-kuma.git > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 5: Entrar en el directorio de Uptime Kuma
cd uptime-kuma > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 6: Instalar las dependencias de Node.js
npm run setup > /dev/null 2>&1
npm install > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 7: Instalar pm2 para gestionar la ejecución en segundo plano
sudo npm install pm2 -g > /dev/null 2>&1
pm2 install pm2-logrotate > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 8: Iniciar Uptime Kuma con pm2 y especificar el puerto por defecto
PORT=3001
pm2 start server/server.js --name uptime-kuma -- --port $PORT > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 9: Configurar pm2 para que se reinicie automáticamente al reiniciar el sistema
pm2 save > /dev/null 2>&1
pm2 startup | sudo bash > /dev/null 2>&1
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Paso 10: Detectar la IP local del servidor y mostrar información al usuario
SERVER_IP=$(hostname -I | awk '{print $1}')
((CURRENT_STEP++))
show_progress $CURRENT_STEP $TOTAL_STEPS

# Finalización
echo
echo "========================================="
echo ">>> INSTALACIÓN COMPLETADA <<<"
echo "Uptime Kuma se ha instalado correctamente."
echo "Accede al servicio en: http://$SERVER_IP:$PORT"
echo "========================================="