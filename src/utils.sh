#!/bin/bash

verdeColor="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojoColor="\e[0;31m\033[1m"
azulColor="\e[0;34m\033[1m"
amarilloColor="\e[0;33m\033[1m"
moradoColor="\e[0;35m\033[1m"
turquesaColor="\e[0;36m\033[1m"
grisColor="\e[0;37m\033[1m"

# Función cargar variables del .env
cargar_env() {
    if [ -f ".env" ]; then
        source ".env"
        echo -e "\n${verdeColor}[+]${finColor} Variables .env cargadas"
        return 0
    else
        echo -e "\n${rojoColor}[!]${finColor} ${grisColor}ERROR: No se encontró '.env'${finColor}" >&2
        return 1
    fi
}

# Función logs con timestamp
log_con_tiempo() {
    local mensaje="$1"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $mensaje"
}

# Función generar UUID
generar_uuid() {
    # Usar uuidgen si existe, sino usar date + random
    if command -v uuidgen &> /dev/null; then
        uuidgen
    else
        echo "$(date +%s)-$RANDOM"
    fi
}

# Genera una llave con el hash de los parametros
generar_llave_hash(){
    local content="$*"
    echo "$(echo "${content}" | sha256sum | cut -d' ' -f1 | head -c 32)"
}

# Función verificación de que variables existan
verificar_variables_env() {
    local errores=0
    
    if [ -z "${MAX_RETRIES:-}" ]; then
        echo -e "${rojoColor}[!]${finColor} MAX_RETRIES no está definida" >&2
        errores=1
    fi
    
    if [ -z "${BACKOFF_MS:-}" ]; then
        echo -e "${rojoColor}[!]${finColor} BACKOFF_MS no está definida" >&2
        errores=1
    fi
    
    return $errores
}