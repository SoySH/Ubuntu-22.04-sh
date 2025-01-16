#!/bin/bash

# Función para detectar la dirección IP local
detect_ip() {
    ip_address=$(hostname -I | awk '{print $1}')
    echo "$ip_address"
}

# Función para eliminar Plex Media Server
remove_plex() {
    echo "Eliminando Plex Media Server..."
    sudo systemctl stop plexmediaserver.service
    sudo apt remove --purge plexmediaserver -y
    sudo apt autoremove -y
    sudo rm -rf /var/lib/plexmediaserver
    sudo rm -rf /etc/plex
    echo "Plex Media Server ha sido eliminado con éxito."
}

# Función para instalar Plex Media Server
install_plex() {
    # Variables predeterminadas
    DEFAULT_PORT=32400
    DEFAULT_DOMAIN="localhost"

    # Actualizar Ubuntu e instalar dependencias
    echo "Actualizando el sistema e instalando dependencias..."
    sudo apt update && sudo apt upgrade -y
    sudo apt install apt-transport-https curl wget -y

    # Pedir al usuario la configuración de dominio y puerto
    echo -e "\nConfiguración del servidor Plex Media Server"
    read -p "Ingrese el dominio o IP (por defecto: $DEFAULT_DOMAIN): " domain
    read -p "Ingrese el puerto (por defecto: $DEFAULT_PORT): " port

    # Establecer los valores predeterminados si el usuario deja en blanco
    domain=${domain:-$DEFAULT_DOMAIN}
    port=${port:-$DEFAULT_PORT}

    # Instalar Plex Media Server
    echo "Instalando Plex Media Server..."
    sudo wget -O- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex.gpg > /dev/null
    echo "deb [signed-by=/usr/share/keyrings/plex.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plexmediaserver.list > /dev/null
    sudo apt update
    sudo apt install plexmediaserver -y

    # Verificar el estado del servicio
    echo "Verificando el estado del servicio Plex Media Server..."
    systemctl status plexmediaserver.service --no-pager > /dev/null

    # Configurar el firewall
    echo "Configurando el firewall..."
    sudo ufw allow $port
    sudo ufw allow OpenSSH
    sudo ufw enable

    # Detectar la IP local
    ip_address=$(detect_ip)

    # Limpiar la pantalla
    clear

    # Mensaje final (destacado con colores)
    echo -e "\033[1;32m==============================="
    echo -e "¡Instalación completada con éxito!"
    echo -e "===============================\033[0m\n"

    echo -e "\033[1;34mPuede acceder al servidor Plex Media Server en las siguientes direcciones:\033[0m"
    echo -e "\033[1;36m1. http://$domain:$port/web\033[0m"
    echo -e "\033[1;36m2. http://$ip_address:$port/web\033[0m\n"

    echo -e "\033[1;33mInstrucciones para comenzar:\033[0m"
    echo -e "  1. Inicie sesión en su servidor Plex con una cuenta Plex (puede ser Google, Apple o correo electrónico)."
    echo -e "  2. Agregue su contenido dentro de la plataforma Plex."
    echo -e "\033[1;31m  3. Se recomienda utilizar TLS válido para asegurar las conexiones.\033[0m"
}

# Menú interactivo
echo "Bienvenido al instalador de Plex Media Server."
echo "¿Qué desea hacer?"
echo "1. Instalar Plex Media Server"
echo "2. Eliminar Plex Media Server"
read -p "Seleccione una opción (1 o 2): " option

case $option in
    1)
        install_plex
        ;;
    2)
        remove_plex
        ;;
    *)
        echo "Opción no válida. Saliendo..."
        exit 1
        ;;
esac
