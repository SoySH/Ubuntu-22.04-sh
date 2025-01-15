#!/bin/bash

# Función para limpiar la pantalla
clear_screen() {
    clear
}

# Función para comprobar si rsync está instalado
check_rsync_installed() {
    if ! command -v rsync &> /dev/null; then
        echo "rsync no está instalado. Procediendo con la instalación..."
        sudo apt update
        sudo apt install -y rsync
    else
        echo "rsync ya está instalado."
    fi
}

# Función para obtener la IP local de la máquina
get_local_ip() {
    local_ip=$(hostname -I | awk '{print $1}')
    echo "Tu IP local es: $local_ip"
}

# Función para detectar otras IPs en la misma red local usando nmap
detect_ips_in_network() {
    local_ip=$(hostname -I | awk '{print $1}')
    subnet=$(echo $local_ip | cut -d'.' -f1-3)
    echo "Detectando dispositivos en la red local ($subnet.0/24)..."

    # Realizar un escaneo para encontrar las IPs activas en la red
    nmap -sn $subnet.0/24 | grep "Nmap scan report" | awk '{print $5}'
}

# Función para transferir archivos/directorios usando rsync
transfer_files() {
    clear_screen
    echo "--------------------------------------"
    echo "   Transferir Archivos o Directorios"
    echo "--------------------------------------"

    # Listar los archivos y directorios en la ruta actual
    echo "Archivos y directorios en la ruta actual:"
    select source_path in *; do
        if [ -n "$source_path" ]; then
            echo "Has seleccionado: $source_path"
            break
        else
            echo "Opción inválida. Intenta nuevamente."
        fi
    done

    # Mostrar los archivos que se van a transferir
    echo "Detectando IPs en la red local..."
    detect_ips_in_network
    read -p "Introduce la dirección IP o nombre del servidor de destino (o deja vacío para seleccionar manualmente): " remote_ip

    if [ -z "$remote_ip" ]; then
        read -p "Introduce la dirección IP del servidor de destino manualmente: " remote_ip
    fi

    # Solicitar el nombre de usuario en el servidor remoto
    read -p "Introduce el nombre de usuario del servidor remoto: " remote_user

    # Solicitar la ruta de destino
    read -p "Introduce la ruta de destino en el servidor remoto: " remote_path

    # Confirmar si el usuario quiere continuar con la transferencia
    echo "¿Deseas continuar con la transferencia de los archivos seleccionados a '$remote_user@$remote_ip:$remote_path'? [S/n]"
    read -p "Respuesta: " confirmation
    if [[ "$confirmation" =~ ^[Ss]$ ]]; then
        # Ejecutar la transferencia usando rsync
        rsync -avz --progress "$source_path" "$remote_user@$remote_ip:$remote_path"
        echo "Transferencia completada."
    else
        echo "Transferencia cancelada."
    fi
}

# Función para crear un cron job programado
create_cron_job() {
    clear_screen
    echo "Selecciona la frecuencia del backup:"
    echo "1) Diario"
    echo "2) Semanal"
    echo "3) Mensual"
    echo "4) Personalizado (ingresar fecha, hora y minuto)"
    read -p "Selecciona una opción [1-4]: " freq_option

    # Variables para hora, minuto, día y mes
    minute=""
    hour=""
    day_of_month=""
    month=""
    day_of_week=""

    case $freq_option in
        1)
            minute="0"
            hour="0"
            day_of_month="*"
            month="*"
            day_of_week="*"
            ;;
        2)
            minute="0"
            hour="0"
            day_of_month="*"
            month="*"
            day_of_week="1"  # Lunes
            ;;
        3)
            minute="0"
            hour="0"
            day_of_month="1"  # Primer día del mes
            month="*"
            day_of_week="*"
            ;;
        4)
            # Personalizado: ingresar fecha y hora
            read -p "Introduce el minuto (0-59): " minute
            read -p "Introduce la hora (0-23): " hour
            read -p "Introduce el día del mes (1-31): " day_of_month
            read -p "Introduce el mes (1-12): " month
            read -p "Introduce el día de la semana (0-6, 0 es domingo): " day_of_week
            ;;
        *)
            echo "Opción no válida, regresando al menú..."
            return
            ;;
    esac

    # Solicitar la ruta de destino
    read -p "Introduce la ruta del destino para el backup: " backup_dest

    # Seleccionar los archivos o directorios a respaldar
    echo "Selecciona los archivos o directorios que deseas respaldar:"
    select source_path in *; do
        if [ -n "$source_path" ]; then
            echo "Has seleccionado: $source_path"
            break
        else
            echo "Opción inválida. Intenta nuevamente."
        fi
    done

    # Confirmación de cron job
    cron_command="rsync -avz $source_path $backup_dest"
    cron_time="$minute $hour $day_of_month $month $day_of_week"
    cron_job="$cron_time $cron_command"

    # Añadir al cron
    (crontab -l 2>/dev/null; echo "$cron_job") | crontab -

    clear_screen
    echo "Backup programado correctamente. El cron job es:"
    echo "$cron_job"
}

# Función para gestionar backups programados
manage_scheduled_backups() {
    clear_screen
    echo "Backups programados:"
    crontab -l
    echo ""
    read -p "Introduce el número del cron job que deseas eliminar (deja vacío para regresar al menú): " job_number

    if [ -z "$job_number" ]; then
        echo "Regresando al menú..."
        return
    fi

    # Eliminar cron job seleccionado
    crontab -l | nl | grep -v "^$job_number" | cut -f2- | crontab -
    clear_screen
    echo "Backup programado eliminado correctamente."
}

# Función para ver backups en ejecución
view_running_backups() {
    clear_screen
    echo "Verificando los backups en ejecución..."
    ps aux | grep rsync
}

# Función principal
while true; do
    clear_screen
    echo "--------------------------------------"
    echo "   Gestor de Archivos con rsync"
    echo "--------------------------------------"
    echo "1) Transferir archivos/directorios"
    echo "2) Backup programado"
    echo "3) Gestionar backups programados"
    echo "4) Ver backups en ejecución"
    echo "5) Salir"
    echo "--------------------------------------"
    read -p "Selecciona una opción [1-5]: " option

    case $option in
        1)
            transfer_files
            ;;
        2)
            create_cron_job
            ;;
        3)
            manage_scheduled_backups
            ;;
        4)
            view_running_backups
            ;;
        5)
            echo "Saliendo..."
            exit 0
            ;;
        *)
            clear_screen
            echo "Opción no válida. Por favor, elige entre 1 y 5."
            ;;
    esac
    read -p "Presiona Enter para continuar..."
done
