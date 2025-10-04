export MAX_RETRIES="${MAX_RETRIES:-3}"
export BACKOFF_MS="${BACKOFF_MS:-10}"

setup_file() {
    mkdir -p out
}

setup() {
    # obtener el directorio que contiene este archivo
    # usa $BATS_TEST_FILENAME en lugar de ${BASH_SOURCE[0]} o $0,
    # ya que estas últimas apuntan a la ubicación del bats ejecutable
    # o al archivo preprocesado respectivamente
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"

    # hacer los ejecutables en src/ visibles a la variable de entorno PATH
    PATH="$DIR/../src:$PATH"

    TEST_URL="http://127.0.0.1"
    PORT=8080
}

teardown() {
    # Guardar salida y estado desde de cada prueba

    # Quitar secuencias ANSI y guardar salida
    echo "$output" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g' > "out/${BATS_TEST_NAME}.out"
    # Guardar estado 
    echo "$status" > "out/${BATS_TEST_NAME}.status"
}