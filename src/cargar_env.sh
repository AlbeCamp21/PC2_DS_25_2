#!/usr/bin/env bash

verdeColor="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojoColor="\e[0;31m\033[1m"
azulColor="\e[0;34m\033[1m"
amarilloColor="\e[0;33m\033[1m"
moradoColor="\e[0;35m\033[1m"
turquesaColor="\e[0;36m\033[1m"
grisColor="\e[0;37m\033[1m"

# verificando que se ejecute con source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo -e "\n${rojoColor}[!]${finColor} ${grisColor}ERROR: Este script debe ejecutarse con 'source':${finColor}"
    echo -e "\t${turquesaColor}$ source <ruta de archivo>${finColor}"
else
    echo -e "\n${amarilloColor}[+]${finColor} ${grisColor}Cargando variables de entorno de '.env'...${finColor}"
    # cargando variables desde .env, si es que existe
    if [ -f ".env" ]; then
        sleep 1
        set -a
        source .env
        set +a
        echo -e "\n${verdeColor}[+]${finColor} ${grisColor}Variables cargadas exitosamente, compruébalas ejecutando 'mostrar_env.sh'${finColor}"
    else
        sleep 0.5
        echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: No se encontró el archivo '.env'${finColor}"
    fi
fi