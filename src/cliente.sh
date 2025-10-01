#!/bin/bash

verdeColor="\e[0;32m\033[1m"
finColor="\033[0m\e[0m"
rojoColor="\e[0;31m\033[1m"
azulColor="\e[0;34m\033[1m"
amarilloColor="\e[0;33m\033[1m"
moradoColor="\e[0;35m\033[1m"
turquesaColor="\e[0;36m\033[1m"
grisColor="\e[0;37m\033[1m"

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE_GENERIC=1
readonly EXIT_FAILURE_NETWORK=2

show_help() {
    echo -e "\n${amarilloColor}[■]${finColor}${grisColor} Uso: $0 ${finColor}${moradoColor}[GET|POST|PUST] <URL> <BODY(opcional)>${finColor}\n"
    echo -e "\t${turquesaColor}- Descripción:${finColor}${grisColor} CLI para HTTP con reintentos, backoff exponencial y métricas de latencia ${finColor}"
    echo -e "\t${turquesaColor}- Variables:${finColor}${grisColor} MAX_RETRIES, BACKOFF_MS ${finColor}"
    echo -e "\t${turquesaColor}- Códigos de salida:${finColor} ${amarilloColor}0 = ok$, 1 = error generico, 2 = error de red${finColor}\n"
}

now_ms(){
    echo $(($(date +%s) * 1000 + 10#$(date +%N) / 1000000))
}

calculate_backoff() {
    local attempt=$1
    local backoff_ms=$((BACKOFF_MS * (2 ** (attempt - 1))))
    echo $backoff_ms
}

do_request() {
    local method="$1"
    local url="$2"
    local body="$3"
    local attempt=1
    local status_code=0
    local start_time=$(now_ms)
    local output_file="out/response_${method}_$(basename "$url")_$(date +%d-%b-%Y_%H%M%S).txt"

    echo -e "\n${moradoColor}Realizando petición $method a: $url ${finColor}\n"

    while [ $attempt -le $MAX_RETRIES ]; do
        local attempt_start=$(now_ms)
        curl_comand="curl -s -w '- HTTP Status: %{http_code}' -o '$output_file' --connect-timeout 5 --max-time 5"

        case "$method" in
            "GET")
                curl_comand="$curl_comand -X GET '$url'"
                ;;
            "POST")
                curl_comand="$curl_comand -X POST -H 'Content-Type: application/json' -d '$body' $url"
                ;;
            "PUT")
                curl_comand="$curl_comand -X PUT -H 'Content-Type: application/json' -d '$body' '$url'"
                ;;
            *)
                echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Método no soportado: $method${finColor}" >&2
                return $EXIT_FAILURE_GENERIC
                ;;
        esac

        status_code=$(eval $curl_comand 2>/dev/null | sed 's/.*HTTP Status: //')
        local curl_exit_code=$?
        local attempt_end=$(now_ms)
        local attempt_duration=$((attempt_end - attempt_start))

        echo "$(date '+%d-%b-%Y_%H%M%S') - Intento $attempt/$MAX_RETRIES - $method $url - Status: $status_code - Duración: ${attempt_duration}ms" >> out/requests_${method}_$(basename "$url").log

        if [ $curl_exit_code -eq 0 ] && [ "$status_code" -ge 200 ] && [ "$status_code" -lt 300 ]; then
            local total_duration=$(($(now_ms) - start_time))
            echo "$(date '+%Y-%m-%d %H:%M:%S'),$method,$url,$attempt,$status_code,$total_duration" >> out/metrics.csv
            echo -e "${verdeColor}[✓]${finColor} ${grisColor}$method exitoso (intento $attempt) - Status: $status_code - Duración: ${total_duration}ms${finColor}\n"
            return $EXIT_SUCCESS
        fi

        if [ $attempt -lt $MAX_RETRIES ]; then
            local backoff_time=$(calculate_backoff $attempt)
            echo -e "${amarilloColor}[!]${finColor} ${grisColor}Intento $attempt falló (Status: $status_code). Reintentando en ${backoff_time}ms...${finColor}"
            sleep $(echo "scale=3; $backoff_time / 1000" | bc -l)
        fi
        
        attempt=$((attempt + 1))
    done

    local total_duration=$(($(now_ms) - start_time))
    echo "$(date '+%Y-%m-%d %H:%M:%S'),$method,$url,$attempt,$status_code,$total_duration" >> out/metrics.csv
    echo -e "${amarilloColor}[!]${finColor} ${grisColor}Intento $((attempt-1)) falló (Status: $status_code)."
    echo -e "\n${rojoColor}[✗]${finColor} ${grisColor}Todos los intentos fallaron para $method $url - Status final: $status_code${finColor}\n" >&2

    return $EXIT_FAILURE_NETWORK
}

request_get() {
    local url="$1"
    do_request "GET" "$url"
}

request_post() {
    local url="$1"
    local body="${2:-{ \"Nombre\" : \"Fisica 2\", \"Codigo\" : \"CF2A2\" }}"
    do_request "POST" "$url" "$body"
}

request_put() {
    local url="$1"
    local body="${2:-{ \"Nombre\" : \"Laboratorio de Fisica 1\", \"Codigo\" : \"CF2A2\" }}"
    do_request "PUT" "$url" "$body"
}

validate_url() {
    local url="$1"
    url=$(echo "$1" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    if [[ ! "$url" =~ ^https?:// ]]; then
        echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: URL debe comenzar con http:// o https://${finColor}">&2
        return $EXIT_FAILURE_GENERIC
    fi
    return $EXIT_SUCCESS
}

# FLUJO DE PETICIONES

mkdir -p out

# Valida si existe .env
if [ -f ".env" ]; then
    source ".env"
else
    echo -e "\n${rojoColor}[!]${finColor} ${grisColor}ERROR: No se encontró '.env'${finColor}">&2
    exit 1
fi

# Extrae las variables de entorno
readonly MAX_RETRIES=${MAX_RETRIES:-3}
readonly BACKOFF_MS=${BACKOFF_MS:-500}

# Creacion las metricas en caso no exista
if [ ! -f "out/metrics.csv" ]; then
    echo "timestamp,método,URL,intentos,status_code,duración_ms" > out/metrics.csv
fi

# Verificar argumentos
if [ $# -lt 2 ] || [ $# -gt 3 ]; then
    echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: Número incorrecto de argumentos${finColor}">&2
    show_help
    exit $EXIT_FAILURE_GENERIC
fi

# Parametros de entrada
METHOD=$(echo "$1" | tr '[:lower:]' '[:upper:]')
URL="$2"
BODY="$3"

validate_url "$URL"

case "$METHOD" in
    "GET")
        request_get "$URL"
        ;;
    "POST")
        request_post "$URL" "$BODY"
        ;;
    "PUT")
        request_put "$URL" "$BODY"
        ;;
    *)
        echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: Método no soportado. Use GET, POST o PUT${finColor}">&2
        show_help
        exit $EXIT_FAILURE_GENERIC
        ;;
esac