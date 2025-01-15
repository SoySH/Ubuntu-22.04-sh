#!/bin/bash

check_ssh_installed() {
    if ! dpkg-query -W -f='${Status}' openssh-server 2>/dev/null | grep -q "install ok installed"; then
        echo "SSH no está instalado. Instalando 'openssh-server'..."
        sudo apt update -qq
        sudo apt-get install -qq -y openssh-server > /dev/null 2>&1
        echo "Instalación completada."
    else
        echo "SSH ya está instalado."
    fi
}

check_ssh_service() {
    echo "Verificando el estado del servicio SSH..."
    if systemctl is-active --quiet ssh || systemctl is-active --quiet sshd; then
        echo "El servicio SSH está activo."
    else
        echo "El servicio SSH no está activo. Iniciando el servicio..."
        if systemctl is-enabled --quiet ssh || systemctl is-enabled --quiet sshd; then
            sudo systemctl start ssh || sudo systemctl start sshd
            sudo systemctl enable ssh || sudo systemctl enable sshd
            echo "Servicio SSH iniciado y habilitado."
        else
            echo "El servicio SSH no está disponible. Asegúrate de que 'openssh-server' esté instalado correctamente."
        fi
    fi
}

generate_ssh_key() {
    if [ ! -f ~/.ssh/id_rsa ]; then
        echo "Generando nueva clave SSH..."
        ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa -N "" > /dev/null
        echo "Clave SSH generada exitosamente."
    else
        echo "La clave SSH ya existe en ~/.ssh/id_rsa."
    fi
}

export_ssh_public_key() {
    echo "Exportando la clave pública para otros usuarios..."
    if [ -f ~/.ssh/id_rsa.pub ]; then
        cat ~/.ssh/id_rsa.pub
        echo "Clave pública mostrada. Copia y usa esta clave para configurar el acceso SSH."
    else
        echo "No se encontró ninguna clave pública. Genera una clave primero."
    fi
}

uninstall_ssh() {
    echo "Desinstalando SSH y eliminando configuraciones..."
    sudo systemctl stop ssh > /dev/null 2>&1 || sudo systemctl stop sshd > /dev/null 2>&1
    sudo systemctl disable ssh > /dev/null 2>&1 || sudo systemctl disable sshd > /dev/null 2>&1
    sudo apt remove --purge -qq -y openssh-server > /dev/null 2>&1
    rm -rf ~/.ssh
    sudo rm -rf /etc/ssh
    sudo apt autoremove -qq -y > /dev/null 2>&1
    echo "SSH ha sido desinstalado completamente."
}

show_menu() {
    clear
    echo "--------------------------------------"
    echo "   Gestión de SSH en el servidor"
    echo "--------------------------------------"
    echo "1) Instalar y configurar SSH"
    echo "2) Generar clave SSH (si no existe)"
    echo "3) Exportar clave pública para otros usuarios"
    echo "4) Ver el estado del servicio SSH"
    echo "5) Desinstalar SSH y eliminar configuraciones"
    echo "6) Salir"
    echo "--------------------------------------"
    read -p "Selecciona una opción [1-6]: " option
}

main() {
    while true; do
        show_menu

        case $option in
            1)
                check_ssh_installed
                check_ssh_service
                ;;
            2)
                generate_ssh_key
                ;;
            3)
                export_ssh_public_key
                ;;
            4)
                check_ssh_service
                ;;
            5)
                uninstall_ssh
                ;;
            6)
                echo "Saliendo..."
                exit 0
                ;;
            *)
                echo "Opción inválida, por favor elige entre 1 y 6."
                ;;
        esac
        read -p "Presiona Enter para continuar..."
    done
}

main
