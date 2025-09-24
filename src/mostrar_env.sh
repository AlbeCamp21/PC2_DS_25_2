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
echo -e "\t${moradoColor}- PORT:\t\t${finColor}${grisColor}${PORT:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- MESSAGE:\t${finColor}${grisColor}${MESSAGE:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- RELEASE:\t${finColor}${grisColor}${RELEASE:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- CONFIG_URL:\t${finColor}${grisColor}${CONFIG_URL:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- DNS_SERVER:\t${finColor}${grisColor}${DNS_SERVER:-NO DEFINIDO}${finColor}"
echo -e "\t${moradoColor}- TARGETS:\t${finColor}${grisColor}${TARGETS:-NO DEFINIDO}${finColor}"