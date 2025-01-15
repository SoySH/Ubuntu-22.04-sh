#!/bin/bash

# Obtener el nombre del script actual (sin la ruta)
nombre_script=$(basename "$0")

# Función para obtener la IP del equipo
obtener_ip() {
    ip_local=$(hostname -I | awk '{print $1}')
    echo "$ip_local"
}

# Función para obtener la fecha y hora actual en formato YYYY-MM-DD HH:MM:SS
obtener_fecha_hora() {
    fecha_hora=$(date +"%Y-%m-%d %H:%M:%S")
    echo "$fecha_hora"
}

# Función para mostrar el menú
mostrar_menu() {
    clear
    echo "====================================="
    echo "         Menú de administración"
    echo "====================================="
    echo "IP del equipo: $(obtener_ip)"
    echo "Fecha y hora: $(obtener_fecha_hora)"
    echo "====================================="
    echo "1. Administrar sitios"
    echo "2. Crear o editar sitios"
    echo "3. Gestionar puertos de UFW"
    echo "4. Ver estado de UFW y Nginx"
    echo "5. Administrar Nginx"
    echo "6. Administrar PHP"
    echo "7. Gestionar el sistema"
    echo "8. Ejecutar otro script"
    echo "9. Salir"
    echo "====================================="
}

# Función para ejecutar un script adicional
ejecutar_script_adicional() {
    # Obtener la lista de archivos .sh en el directorio
    scripts=($(ls *.sh | grep -v "$nombre_script"))
    
    # Si no hay scripts adicionales, informar al usuario
    if [ ${#scripts[@]} -eq 0 ]; then
        echo "No hay scripts disponibles para ejecutar."
        return
    fi
    
    echo "Seleccione el script que desea ejecutar:"
    i=1
    for script in "${scripts[@]}"; do
        echo "$i. $script"
        ((i++))
    done
    
    echo -n "Seleccione el número del script a ejecutar: "
    read opcion
    
    # Verificar que la opción sea válida
    if [[ $opcion -ge 1 && $opcion -le ${#scripts[@]} ]]; then
        script_a_ejecutar="${scripts[$((opcion - 1))]}"
        echo "Ejecutando el script: $script_a_ejecutar"
        
        # Ejecutar el script seleccionado
        bash "$script_a_ejecutar"
        
        echo "El script ha terminado. Regresando al menú..."
        read -n 1 -s -r -p "Presione cualquier tecla para continuar..."
    else
        echo "Opción no válida."
    fi
}

# Función para reiniciar nginx
reiniciar_nginx() {
    echo "Reiniciando Nginx..."
    if sudo systemctl restart nginx; then
        echo "Nginx reiniciado correctamente."
    else
        echo "Error al reiniciar Nginx."
    fi
}

# Función para habilitar un sitio
habilitar_sitio() {
    echo "Seleccione el archivo del sitio en sites-available para habilitar:"
    i=1
    for site in /etc/nginx/sites-available/*; do
        if [[ -f "$site" ]]; then
            echo "$i. $(basename $site)"
            ((i++))
        fi
    done
    echo -n "Seleccione el número del sitio a habilitar: "
    read opcion
    if [[ $opcion -ge 1 ]] && [[ $opcion -lt $i ]]; then
        sitio=$(ls /etc/nginx/sites-available/ | sed -n "${opcion}p")
        ln -s /etc/nginx/sites-available/$sitio /etc/nginx/sites-enabled/
        echo "Sitio $sitio habilitado."
        reiniciar_nginx
    else
        echo "Opción inválida."
    fi
}

# Función para deshabilitar un sitio
deshabilitar_sitio() {
    echo "Seleccione el archivo del sitio en sites-enabled para deshabilitar:"
    i=1
    for site in /etc/nginx/sites-enabled/*; do
        if [[ -f "$site" ]]; then
            echo "$i. $(basename $site)"
            ((i++))
        fi
    done
    echo -n "Seleccione el número del sitio a deshabilitar: "
    read opcion
    if [[ $opcion -ge 1 ]] && [[ $opcion -lt $i ]]; then
        sitio=$(ls /etc/nginx/sites-enabled/ | sed -n "${opcion}p")
        rm /etc/nginx/sites-enabled/$sitio
        echo "Sitio $sitio deshabilitado."
        reiniciar_nginx
    else
        echo "Opción inválida."
    fi
}

# Función para eliminar un sitio
eliminar_sitio() {
    echo "Seleccione el archivo del sitio en sites-available para eliminar:"
    i=1
    for site in /etc/nginx/sites-available/*; do
        if [[ -f "$site" ]]; then
            echo "$i. $(basename $site)"
            ((i++))
        fi
    done
    echo -n "Seleccione el número del sitio a eliminar: "
    read opcion
    if [[ $opcion -ge 1 ]] && [[ $opcion -lt $i ]]; then
        sitio=$(ls /etc/nginx/sites-available/ | sed -n "${opcion}p")
        rm /etc/nginx/sites-available/$sitio
        rm /etc/nginx/sites-enabled/$sitio 2>/dev/null
        echo "Sitio $sitio eliminado."
        reiniciar_nginx
    else
        echo "Opción inválida."
    fi
}

# Función para crear un nuevo sitio
crear_sitio() {
    echo -n "Ingrese el nombre del archivo para el nuevo sitio (sin extensión): "
    read nombre_sitio
    archivo="/etc/nginx/sites-available/$nombre_sitio"
    
    if [[ -f "$archivo" ]]; then
        echo "El archivo ya existe. No se puede crear el sitio."
        return 1
    fi
    
    nano $archivo
    echo "Nuevo archivo creado: $archivo"
    echo "¿Desea habilitar este sitio ahora? (s/n)"
    read respuesta
    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
        ln -s $archivo /etc/nginx/sites-enabled/
        echo "Sitio $nombre_sitio habilitado."
        reiniciar_nginx
    fi
}

# Función para editar un sitio existente
editar_sitio() {
    echo "Seleccione el archivo del sitio en sites-available para editar:"
    i=1
    for site in /etc/nginx/sites-available/*; do
        if [[ -f "$site" ]]; then
            echo "$i. $(basename $site)"
            ((i++))
        fi
    done
    echo -n "Seleccione el número del sitio a editar: "
    read opcion
    if [[ $opcion -ge 1 ]] && [[ $opcion -lt $i ]]; then
        sitio=$(ls /etc/nginx/sites-available/ | sed -n "${opcion}p")
        archivo="/etc/nginx/sites-available/$sitio"
        nano $archivo
        echo "Archivo $sitio editado."
    else
        echo "Opción inválida."
    fi
}

# Función para habilitar puertos en UFW
habilitar_puerto() {
    echo "Ingrese el número de puerto para habilitar (ej. 80, 443, 22, etc.): "
    read puerto
    sudo ufw allow $puerto
    if [ $? -eq 0 ]; then
        echo "Puerto $puerto habilitado en UFW."
    else
        echo "Error al habilitar el puerto $puerto."
    fi
}

# Función para deshabilitar puertos en UFW
deshabilitar_puerto() {
    echo "Ingrese el número de puerto para deshabilitar (ej. 80, 443, 22, etc.): "
    read puerto
    sudo ufw deny $puerto
    if [ $? -eq 0 ]; then
        echo "Puerto $puerto deshabilitado en UFW."
    else
        echo "Error al deshabilitar el puerto $puerto."
    fi
}

# Función para eliminar puertos en UFW
eliminar_puerto() {
    echo "Seleccione el número del puerto para eliminar:"
    i=1
    puertos=($(sudo ufw status | grep "ALLOW" | awk '{print $1}'))
    for puerto in "${puertos[@]}"; do
        echo "$i. $puerto"
        ((i++))
    done
    echo -n "Seleccione el número del puerto a eliminar: "
    read opcion
    if [[ $opcion -ge 1 ]] && [[ $opcion -le ${#puertos[@]} ]]; then
        puerto=${puertos[$((opcion - 1))]}
        sudo ufw delete allow $puerto
        if [ $? -eq 0 ]; then
            echo "Puerto $puerto eliminado de UFW."
        else
            echo "Error al eliminar el puerto $puerto."
        fi
    else
        echo "Opción inválida."
    fi
}

# Función para verificar si UFW está instalado
verificar_ufw_instalado() {
    if ! command -v ufw &> /dev/null; then
        echo "UFW no está instalado. ¿Desea instalarlo? (s/n)"
        read respuesta
        if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
            sudo apt-get update
            sudo apt-get install ufw -y
            echo "UFW instalado correctamente."
        else
            echo "UFW no se instalará."
            return 1
        fi
    fi
    return 0
}

# Función para gestionar UFW
gestionar_ufw() {
    verificar_ufw_instalado
    if [[ $? -ne 0 ]]; then
        return 1
    fi
    
    echo "¿Desea habilitar o deshabilitar un puerto o administrar UFW?"
    echo "1. Habilitar puerto"
    echo "2. Deshabilitar puerto"
    echo "3. Eliminar puerto"
    echo "4. Habilitar UFW"
    echo "5. Deshabilitar UFW"
    echo -n "Seleccione una opción: "
    read accion
    case $accion in
        1) habilitar_puerto ;;
        2) deshabilitar_puerto ;;
        3) eliminar_puerto ;;
        4) sudo ufw enable ;;
        5) sudo ufw disable ;;
        *) echo "Opción inválida." ;;
    esac
}

# Función para ver el estado de UFW y Nginx
ver_estado() {
    echo "====================================="
    echo "Estado de UFW:"
    sudo ufw status verbose
    echo ""
    echo "====================================="
    echo "Sitios habilitados en Nginx:"
    ls /etc/nginx/sites-enabled/
    echo "====================================="
}

# Función para administrar Nginx
administrar_nginx() {
    echo "Seleccione una opción:"
    echo "1. Iniciar Nginx"
    echo "2. Detener Nginx"
    echo "3. Reiniciar Nginx"
    echo "4. Recargar configuración de Nginx"
    echo "5. Verificar configuración de Nginx"
    echo "6. Ver estado de Nginx"
    echo "7. Habilitar inicio automático de Nginx"
    echo "8. Deshabilitar inicio automático de Nginx"
    echo -n "Seleccione una opción: "
    read opcion
    case $opcion in
        1) sudo systemctl start nginx ;;
        2) sudo systemctl stop nginx ;;
        3) sudo systemctl restart nginx ;;
        4) sudo systemctl reload nginx ;;
        5) sudo nginx -t ;;
        6) sudo systemctl status nginx ;;
        7) sudo systemctl enable nginx ;;
        8) sudo systemctl disable nginx ;;
        *) echo "Opción inválida." ;;
    esac
}

# Función para administrar PHP
administrar_php() {
    if ! command -v php &> /dev/null; then
        echo "PHP no está instalado o no se encuentra en el PATH."
        echo "Instale PHP o configure el PATH correctamente."
        return
    fi
    # Obtener solo la versión mayor y menor de PHP (por ejemplo, 8.3 de 8.3.12)
    version_php=$(php -v | head -n 1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    
    # Definir el servicio PHP-FPM usando la versión corta (por ejemplo, php8.3-fpm)
    service_php="php${version_php}-fpm"
    
    echo "Versión detectada de PHP: $version_php"
    
    echo "Seleccione una opción para administrar PHP ($version_php):"
    echo "1. Ver versión de PHP"
    echo "2. Ver estado de PHP-FPM"
    echo "3. Iniciar PHP-FPM"
    echo "4. Detener PHP-FPM"
    echo "5. Reiniciar PHP-FPM"
    echo "6. Recargar PHP-FPM"
    echo "7. Habilitar inicio automático de PHP-FPM"
    echo "8. Deshabilitar inicio automático de PHP-FPM"
    echo "9. Editar archivo php.ini"
    echo -n "Seleccione una opción: "
    read opcion
    case $opcion in
        1) php -v ;;
        2) sudo systemctl status $service_php ;;
        3) sudo systemctl start $service_php ;;
        4) sudo systemctl stop $service_php ;;
        5) sudo systemctl restart $service_php ;;
        6) sudo systemctl reload $service_php ;;
        7) sudo systemctl enable $service_php ;;
        8) sudo systemctl disable $service_php ;;
        9) sudo nano /etc/php/$version_php/fpm/php.ini ;;
        *) echo "Opción inválida." ;;
    esac
}

# Función para actualizar el sistema
actualizar_sistema() {
    sudo apt update -y
    echo "¿Desea realizar un upgrade del sistema? (s/n)"
    read respuesta
    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
        sudo apt upgrade -y
        echo "Sistema actualizado."
    else
        echo "Upgrade cancelado. Regresando al submenú..."
    fi
}

# Función para comprobar actualización del sistema
comprobar_actualizacion_sistema() {
    sudo apt update -y
    version_actual=$(lsb_release -d | awk -F"\t" '{print $2}')
    echo "Versión actual: $version_actual"
    sudo do-release-upgrade -c
    echo "¿Desea actualizar el sistema operativo a la última versión? (s/n)"
    read respuesta
    if [[ "$respuesta" == "s" || "$respuesta" == "S" ]]; then
        sudo do-release-upgrade -d
    else
        echo "Actualización cancelada. Regresando al submenú..."
    fi
}

# Función para gestionar el sistema (apagar, bloquear, reiniciar)
gestionar_sistema() {
    echo "Seleccione una opción:"
    echo "1. Apagar el sistema"
    echo "2. Bloquear el sistema"
    echo "3. Reiniciar el sistema"
    echo "4. Reiniciar las interfaces de red"
    echo "5. Renovar las interfaces de red"
    echo "6. Actualizar el sistema"
    echo "7. Comprobar y actualizar el sistema operativo"
    echo -n "Seleccione una opción: "
    read opcion
    case $opcion in
        1) sudo shutdown now ;;
        2) sudo loginctl lock-session ;;
        3) sudo reboot ;;
        4) sudo systemctl restart network-manager ;;
        5) sudo dhclient ;;
        6) actualizar_sistema ;;
        7) comprobar_actualizacion_sistema ;;
        *) echo "Opción inválida." ;;
    esac
}

# Menú principal
while true; do
    mostrar_menu
    echo -n "Seleccione una opción: "
    read opcion
    case $opcion in
        1) 
            echo "¿Desea habilitar, deshabilitar o eliminar un sitio?"
            echo "1. Habilitar sitio"
            echo "2. Deshabilitar sitio"
            echo "3. Eliminar sitio"
            echo -n "Seleccione una opción: "
            read accion
            if [[ $accion -eq 1 ]]; then
                habilitar_sitio
            elif [[ $accion -eq 2 ]]; then
                deshabilitar_sitio
            elif [[ $accion -eq 3 ]]; then
                eliminar_sitio
            else
                echo "Opción inválida."
            fi
            ;;
        2)
            echo "Seleccione una opción:"
            echo "1. Crear nuevo sitio"
            echo "2. Editar sitio existente"
            echo -n "Seleccione una opción: "
            read accion
            if [[ $accion -eq 1 ]]; then
                crear_sitio
            elif [[ $accion -eq 2 ]]; then
                editar_sitio
            else
                echo "Opción inválida."
            fi
            ;;
        3) gestionar_ufw ;;
        4) ver_estado ;;
        5) administrar_nginx ;;
        6) administrar_php ;;
        7) gestionar_sistema ;;
        8) ejecutar_script_adicional ;;
        9) echo "Saliendo del script..."; exit 0 ;;
        *) echo "Opción no válida. Intente de nuevo." ;;
    esac
    echo "Presione cualquier tecla para continuar..."
    read -n 1
done
