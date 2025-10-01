load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

setup_file() {
    mkdir -p out
}

setup() {
    # obtener el directorio que contiene este archivo
    # usa $BATS_TEST_FILENAME en lugar de ${BASH_SOURCE[0]} o $0,
    # ya que estas últimas apuntan a la ubicación del bats ejecutable
    # o al archivo preprocesado respectivamente
    DIR="$( cd "$( dirname "$BATS_TEST_FILENAME" )" >/dev/null 2>&1 && pwd )"

    # make executables in src/ visible to PATH
    PATH="$DIR/../src:$PATH"

    TEST_URL="http://127.0.0.1:9999/unreachable"
}

teardown() {
    # Guardar salida y estado después de cada test
    # Quitar secuencias ANSI
    echo "$output" | sed -r 's/\x1B\[[0-9;]*[A-Za-z]//g' > "out/${BATS_TEST_NAME}.out"
    echo "$status" > "out/${BATS_TEST_NAME}.status"
}

@test "cliente reintenta en caso de timeout" {
    run cliente.sh GET "$TEST_URL"
    assert_failure
    assert_output --partial 'Intento 3'
}