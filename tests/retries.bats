load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

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

@test "cliente reintenta en caso de timeout" {
    run cliente.sh "$TEST_URL"
    assert_failure
    assert_output --partial 'Intento 3'
}