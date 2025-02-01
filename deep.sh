#!/bin/bash

# Actualizar el sistema
echo "Actualizando el sistema..."
sudo apt update -y

# Comprobar si snapd está instalado, si no, instalarlo
echo "Comprobando si snapd está instalado..."
if ! command -v snap &> /dev/null; then
    echo "snapd no encontrado. Instalando snapd..."
    sudo apt install snapd -y
else
    echo "snapd ya está instalado."
    echo "Actualizando snapd..."
    sudo snap refresh snapd
fi

# Instalar el snap core más reciente
echo "Instalando o actualizando snap core..."
sudo snap install core || sudo snap refresh core

# Instalar Astral-UV asegurando compatibilidad
echo "Instalando o actualizando Astral-UV..."
sudo snap install astral-uv --classic || { echo "Error al instalar Astral-UV."; exit 1; }

# Instalar curl
echo "Instalando curl..."
sudo apt install curl -y

# Instalar ollama
echo "Instalando ollama..."
curl -fsSL https://ollama.com/install.sh | sh

# Selección de versión de ollama
echo "Selecciona la versión de deepseek-r1:"
options=(
    "PESO: (4.7 GB) deepseek-r1"
    "PESO: (1.1 GB) deepseek-r1:1.5b"
    "PESO: (9.0 GB) deepseek-r1:14b"
    "PESO: (20.00 GB) deepseek-r1:32b"
    "PESO: (1.3 TB) deepseek-r1:671b-fp16"
    "Ingresar versión manualmente"
)

for i in "${!options[@]}"; do
    echo "$((i+1)). ${options[$i]}"
done

read -p "Introduce el número de la versión deseada o ingresa manualmente: " choice

case $choice in
    1) version="deepseek-r1" ;;
    2) version="deepseek-r1:1.5b" ;;
    3) version="deepseek-r1:14b" ;;
    4) version="deepseek-r1:32b" ;;
    5) version="deepseek-r1:671b-fp16" ;;
    6) read -p "Introduce la versión manualmente: " version ;;
    *) echo "Opción no válida. Saliendo..."; exit 1 ;;
esac

# Ejecutar ollama con la versión seleccionada en segundo plano
echo "Ejecutando ollama con la versión seleccionada: $version..."
ollama run "$version" &

# Determinar la ruta de uvx
UVX_PATH=$(command -v uvx)
if [ -z "$UVX_PATH" ]; then
    echo "Error: No se encontró uvx. Asegúrate de que está instalado correctamente."
    exit 1
fi

# Crear servicio systemd para Open WebUI
echo "Creando servicio systemd para Open WebUI..."
SERVICE_PATH="/etc/systemd/system/open-webui.service"
LOG_PATH="/var/log/open-webui.log"
USER_HOME=$(eval echo ~$USER)

sudo bash -c "cat > $SERVICE_PATH" <<EOF
[Unit]
Description=Open WebUI Service
After=network.target

[Service]
User=$USER
WorkingDirectory=$USER_HOME
Environment="DATA_DIR=$USER_HOME/.open-webui"
ExecStart=$UVX_PATH --python 3.11 open-webui@latest serve
Restart=always
RestartSec=5
StandardOutput=append:$LOG_PATH
StandardError=append:$LOG_PATH
KillMode=process
Type=simple

[Install]
WantedBy=multi-user.target
EOF

# Asegurar que el archivo de logs existe y tiene permisos adecuados
sudo touch $LOG_PATH
sudo chmod 664 $LOG_PATH

# Recargar systemd y habilitar el servicio
echo "Habilitando el servicio Open WebUI..."
sudo systemctl daemon-reload
sudo systemctl enable open-webui.service
sudo systemctl start open-webui.service

# Obtener la IP del equipo y mostrar la URL final
ip=$(hostname -I | awk '{print $1}')
echo "La instalación ha terminado. Accede a la web UI en: http://$ip:8080"

# Verificar el estado del servicio
sleep 3
sudo systemctl status open-webui.service --no-pager --lines=10
