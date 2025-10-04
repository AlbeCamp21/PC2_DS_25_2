load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Casos positivos (-)

@test "PUT /update actualiza un curso existente" {
    cliente.sh POST "$TEST_URL:$PORT/create" '{"Nombre":"Nuevo","Codigo":"X1"}'
    run cliente.sh PUT "$TEST_URL:$PORT/update" '{"Nombre":"Actualizado","Codigo":"X1"}'
    assert_success
    assert_output --partial "PUT exitoso"
    assert_output --partial "Status: 200"
}


# Casos negativos (-)

@test "cliente PUT /update reintenta si el servidor no responde" {
    run cliente.sh PUT "$TEST_URL:9999/update" '{"Nombre":"Dummy","Codigo":"X999"}'
    assert_failure
    assert_output --partial "Intento 3"
}