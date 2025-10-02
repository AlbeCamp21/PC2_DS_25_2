#!/bin/bash

# Configuracion de robustez
set -eo pipefail

# Trap para capturar errores
trap 'echo -e "\n${rojoColor}[ERROR]${finColor} Script terminado en línea $LINENO" >&2; exit 1' ERR

# Cargar funciones de src/utils.sh
source "$(dirname "$0")/utils.sh"

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
    echo -e "\n${amarilloColor}[■]${finColor}${grisColor} Uso: $0 ${finColor}${moradoColor}[GET|POST|PUST] <URL> <BODY(opcional)> [--idempotencykey <KEY>]${finColor}\n"
    echo -e "\t${turquesaColor}- Descripción:${finColor}${grisColor} CLI para HTTP con reintentos, backoff exponencial y métricas de latencia ${finColor}"
    echo -e "\t${turquesaColor}- Variables:${finColor}${grisColor} MAX_RETRIES, BACKOFF_MS ${finColor}"
    echo -e "\t${turquesaColor}- Idempotencia:${finColor}${grisColor} POST genera key automático o usa --idempotencykey ${finColor}"
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
    local idempotency_key="$4"
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
                curl_comand="$curl_comand -X POST -H 'Content-Type: application/json' -H 'Idempotency-Key: $idempotency_key' -d '$body' $url"
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

        local log_entry="- Intento $attempt/$MAX_RETRIES - $method $url - Status: $status_code - Duración: ${attempt_duration}ms"
        
        if [ "$method" = "POST" ] && [ -n "$idempotency_key" ]; then
            log_entry="$log_entry - IdempotencyKey: $idempotency_key"
        fi
        
        log_con_tiempo "$log_entry">> out/requests_${method}_$(basename "$url").log

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
    do_request "GET" "$url" "" ""
}

request_post() {
    local url="$1"
    local body="$2"
    local idempotency_key="$3"
    if [ -z "$body" ]; then
        body='{"Nombre":"Fisica 2","Codigo":"CF2A2"}'
    fi
    if [ -z "$idempotency_key" ]; then
        idempotency_key=$(generar_llave_hash "$url" "$body")
    fi
    log_con_tiempo "- POST $url - Key: $idempotency_key" >> out/post-keys.log
    do_request "POST" "$url" "$body" "$idempotency_key"
}

request_put() {
    local url="$1"
    local body="$2"
    if [ -z "$body" ]; then
        body='{"Nombre":"Laboratorio de Fisica 1","Codigo":"CF2A2"}'
    fi
    do_request "PUT" "$url" "$body" ""
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

# Cargar variables de entorno usando función de utils
cargar_env || exit 1

# Verificar que las variables críticas existen
verificar_variables_env || exit 1

# Extrae las variables de entorno
readonly MAX_RETRIES=${MAX_RETRIES:-3}
readonly BACKOFF_MS=${BACKOFF_MS:-500}

# Creacion las metricas en caso no exista
if [ ! -f "out/metrics.csv" ]; then
    echo "timestamp,método,URL,intentos,status_code,duración_ms" > out/metrics.csv
fi

# Verificar la llave en caso puso la flag --idempotencykey
CUSTOM_IDEMPOTENCY_KEY=""
ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --idempotencykey)
            if [[ -z "$2" ]]; then
                echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: --idempotencykey requiere un valor${finColor}">&2
                show_help
                exit $EXIT_FAILURE_GENERIC
            fi
            CUSTOM_IDEMPOTENCY_KEY="$2"
            shift 2
        ;;
        *)
            ARGS+=("$1")
            shift
        ;;
    esac
done

# Verificar argumentos
if [ ${#ARGS[@]} -lt 2 ] || [ ${#ARGS[@]} -gt 3 ]; then
    echo -e "\n${rojoColor}[!]${finColor} ${grisColor}Error: Número incorrecto de argumentos o flags mal escritas${finColor}">&2
    show_help
    exit $EXIT_FAILURE_GENERIC
fi

# Parametros de entrada
METHOD=$(echo "${ARGS[0]}" | tr '[:lower:]' '[:upper:]')
URL="${ARGS[1]}"
BODY="${ARGS[2]:-}"

validate_url "$URL"

case "$METHOD" in
    "GET")
        request_get "$URL"
        ;;
    "POST")
        if [ -n "$CUSTOM_IDEMPOTENCY_KEY" ]; then
            request_post "$URL" "$BODY" "$CUSTOM_IDEMPOTENCY_KEY"
        else
            request_post "$URL" "$BODY" ""
        fi
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