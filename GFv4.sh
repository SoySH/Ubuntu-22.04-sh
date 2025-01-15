#!/bin/bash

# Este script instala Grafana Enterprise o OSS sin interacción del usuario.
# Permite al usuario elegir entre una versión normal o security y luego ingresar el número de versión deseado.

# Versión predeterminada
DEFAULT_VERSION_NORMAL="11.4.0"
DEFAULT_VERSION_SECURITY="11.3.0"
SECURITY_SUFFIX="+security~01"

# Función para mostrar el menú principal
mostrar_menu_principal() {
    clear
    echo "¿Qué tipo de versión deseas instalar?"
    echo "1. ENTERPRISE"
    echo "2. OSS"
    echo "3. Desinstalar Grafana"
    read -p "Por favor, ingresa el número correspondiente [1, 2 o 3]: " VERSION_TYPE_MAIN
}

# Función para el menú de selección de versión
mostrar_menu_version() {
    clear
    echo "¿Qué tipo de versión deseas instalar?"
    echo "1. Versión normal (por defecto 11.4.0)"
    echo "2. Versión security (por defecto 11.3.0+security~01)"
    read -p "Por favor, ingresa el número correspondiente [1 o 2]: " VERSION_TYPE
}

# Función principal de instalación
instalar_grafana() {
    # Determinar la URL de descarga y el tipo de Grafana según la elección principal
    if [ "$VERSION_TYPE_MAIN" == "1" ]; then
        clear
        echo "Has seleccionado ENTERPRISE."
        # Versión de Enterprise
        DEFAULT_DOWNLOAD_URL="https://dl.grafana.com/enterprise/release/grafana-enterprise_"
        DOWNLOAD_SUFFIX="_amd64.deb"
    elif [ "$VERSION_TYPE_MAIN" == "2" ]; then
        clear
        echo "Has seleccionado OSS."
        # Versión de OSS
        DEFAULT_DOWNLOAD_URL="https://dl.grafana.com/oss/release/grafana_"
        DOWNLOAD_SUFFIX="_amd64.deb"
    else
        # Opción no válida
        echo "Opción no válida. Salir del script."
        exit 1
    fi

    # Preguntar al usuario si desea una versión normal o security
    mostrar_menu_version

    # Determinar la versión según la elección de normal o security
    if [ "$VERSION_TYPE" == "1" ]; then
        # Versión normal
        VERSION=$DEFAULT_VERSION_NORMAL
        echo "Seleccionaste la versión normal: $VERSION"
        SECURITY_SUFFIX=""  # Aseguramos que no se agregue el sufijo de seguridad para versiones normales
    elif [ "$VERSION_TYPE" == "2" ]; then
        # Versión security
        VERSION=$DEFAULT_VERSION_SECURITY
        echo "Seleccionaste la versión de seguridad: $VERSION"
    else
        # Opción inválida
        echo "Opción no válida. Salir del script."
        exit 1
    fi

    # Preguntar si desea cambiar la versión predeterminada
    read -p "¿Quieres ingresar un número de versión diferente? [s/n]: " CHANGE_VERSION

    # Si el usuario quiere cambiar la versión, pedir el número de versión
    if [ "$CHANGE_VERSION" == "s" ]; then
        read -p "Ingresa el número de versión deseado (por ejemplo, 11.4.0): " USER_VERSION
        if [ -z "$USER_VERSION" ]; then
            echo "No se ingresó ninguna versión. Usando la versión predeterminada."
        else
            VERSION=$USER_VERSION
        fi
    fi

    # Crear la URL de descarga final
    DOWNLOAD_URL="${DEFAULT_DOWNLOAD_URL}${VERSION}${SECURITY_SUFFIX}${DOWNLOAD_SUFFIX}"

    # Verificar si la URL de la versión existe (con wget)
    echo "Verificando si la versión está disponible para descargar..."
    wget --spider $DOWNLOAD_URL > /dev/null 2>&1

    # Si la descarga no es exitosa, mostrar un mensaje de error y salir
    if [ $? -ne 0 ]; then
        echo "Error: No se pudo encontrar la versión $VERSION. Por favor, verifica la versión e intenta nuevamente."
        exit 1
    fi

    # Verificar si el archivo .deb ya existe
    if [ ! -f $(basename $DOWNLOAD_URL) ]; then
        # Descargar el paquete .deb de Grafana según la versión seleccionada
        echo "Descargando Grafana versión $VERSION..."
        wget $DOWNLOAD_URL -q --show-progress
    else
        echo "El archivo .deb de Grafana ya existe en la ruta actual. Continuando con la instalación."
    fi

    # Instalar dependencias necesarias
    echo "Instalando dependencias..."
    sudo apt-get install -y adduser libfontconfig1 musl > /dev/null 2>&1

    # Instalar Grafana
    echo "Instalando Grafana..."
    sudo dpkg -i $(basename $DOWNLOAD_URL) > /dev/null 2>&1

    # Resolver dependencias faltantes (si las hay)
    echo "Instalando dependencias faltantes..."
    sudo apt-get install -f -y > /dev/null 2>&1

    # Iniciar el servicio de Grafana
    echo "Iniciando el servicio de Grafana..."
    sudo systemctl start grafana-server > /dev/null 2>&1

    # Habilitar Grafana para que se inicie automáticamente al arrancar el sistema
    echo "Habilitando Grafana para iniciar automáticamente..."
    sudo systemctl enable grafana-server > /dev/null 2>&1

    # Verificar que el servicio de Grafana esté en funcionamiento
    echo "Verificando el estado del servicio de Grafana..."
    sudo systemctl status grafana-server > /dev/null 2>&1

    # Obtener la dirección IP del equipo
    IP_ADDRESS=$(hostname -I | awk '{print $1}')

    # Información adicional para acceder a Grafana
    echo "Grafana se ha instalado correctamente."
    echo "Puedes acceder a Grafana a través de tu navegador en http://$IP_ADDRESS:3000"
    echo "Las credenciales por defecto son:"
    echo "  Usuario: admin"
    echo "  Contraseña: admin"
    echo "Recuerda cambiar la contraseña al iniciar sesión por primera vez."

    # Fin de la instalación
    echo "Instalación completada."

    # Limpiar pantalla antes de la siguiente pregunta
    read -p "Presiona Enter para continuar..."
}

# Función para manejar el menú posterior a la instalación
manejar_menu_post_instalacion() {
    clear
    read -p "¿Quieres regresar al menú principal o salir? [1 para regresar, 2 para salir]: " SELECCION
    if [ "$SELECCION" == "1" ]; then
        ejecutar_script
    else
        exit 0
    fi
}

# Función para desinstalar Grafana
desinstalar_grafana() {
    clear
    echo "Desinstalando Grafana..."

    # Detener el servicio de Grafana
    sudo systemctl stop grafana-server > /dev/null 2>&1

    # Eliminar el paquete de Grafana
    sudo apt-get remove --purge grafana* -y > /dev/null 2>&1

    # Eliminar configuraciones y datos persistentes de Grafana
    echo "Eliminando configuraciones y datos persistentes de Grafana..."
    sudo rm -rf /etc/grafana
    sudo rm -rf /var/lib/grafana
    sudo rm -rf /var/log/grafana
    sudo rm -rf /var/run/grafana

    # Limpiar dependencias innecesarias
    sudo apt-get autoremove -y > /dev/null 2>&1
    sudo apt-get clean > /dev/null 2>&1

    # Verificar que Grafana haya sido desinstalado
    echo "Grafana ha sido desinstalado completamente, incluyendo configuraciones y datos persistentes."

    # Limpiar pantalla antes de la siguiente pregunta
    read -p "Presiona Enter para continuar..."
}

# Función para ejecutar el script
ejecutar_script() {
    # Mostrar menú principal
    mostrar_menu_principal

    # Según la selección principal, realizar la instalación o desinstalar Grafana
    if [ "$VERSION_TYPE_MAIN" == "1" ] || [ "$VERSION_TYPE_MAIN" == "2" ]; then
        instalar_grafana
        manejar_menu_post_instalacion
    elif [ "$VERSION_TYPE_MAIN" == "3" ]; then
        desinstalar_grafana
        manejar_menu_post_instalacion
    else
        echo "Opción no válida. Salir del script."
        exit 1
    fi
}

# Llamada inicial para ejecutar el script
ejecutar_script
