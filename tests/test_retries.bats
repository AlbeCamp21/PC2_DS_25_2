load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "cliente reintenta 2 veces en caso de timeout" {
    export MAX_RETRIES=2
    run cliente.sh GET "$TEST_URL:9999/unreachable"
    assert_failure
    assert_output --partial 'Intento 2'
    refute_output --partial 'Intento 3'
}

@test "cliente reintenta 3 veces en caso de timeout" {
    export MAX_RETRIES=3
    run cliente.sh GET "$TEST_URL:9999/unreachable"
    assert_failure
    assert_output --partial 'Intento 3'
    refute_output --partial 'Intento 4'
}

@test "cliente respeta el tiempo de espera total configurado por BACKOFF_MS" {
    export MAX_RETRIES=4
    export BACKOFF_MS=200  # tiempo entre intentos

    # Definimos el rango esperado en milisegundos
    local min_ms=1400
    local max_ms=2000

    local start=$(date +%s%3N)
    run cliente.sh GET "$TEST_URL:9999/unreachable"
    local end=$(date +%s%3N)

    local elapsed=$((end - start))
    echo "Duración total: ${elapsed} ms"

    # Verifica que la duración esté dentro del rango
    if (( elapsed < min_ms || elapsed > max_ms )); then
        echo "Tiempo fuera del rango esperado (${min_ms}-${max_ms} ms)"
        false  # fuerza fallo en la prueba
    fi
}

@test "cliente PUT /update reintenta si el servidor no responde" {
    run cliente.sh PUT "$TEST_URL:9999/update" '{"Nombre":"Dummy","Codigo":"X999"}'
    assert_failure
    assert_output --partial "Intento 3"
}