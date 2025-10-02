#!/usr/bin/env bash

verdeColor="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojoColor="\e[0;31m\033[1m"
azulColor="\e[0;34m\033[1m"
amarilloColor="\e[0;33m\033[1m"
moradoColor="\e[0;35m\033[1m"
turquesaColor="\e[0;36m\033[1m"
grisColor="\e[0;37m\033[1m"

echo -e "\n${verdeColor}[+]${finColor} ${grisColor}Mostrando variables de entorno cargadas:${finColor}\n"
echo -e "\t${moradoColor}- MAX_RETRIES:\t\t${finColor}${grisColor}${MAX_RETRIES:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- BACKOFF_MS:\t${finColor}${grisColor}${BACKOFF_MS:-NO DEFINIDO}${finColor}"