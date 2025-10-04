load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "cliente reintenta en caso de timeout" {
    run cliente.sh GET "$TEST_URL:9999/unreachable"
    assert_failure
    assert_output --partial 'Intento 3'
    refute_output --partial 'Intento 4'
}

@test "cliente PUT /update reintenta si el servidor no responde" {
    run cliente.sh PUT "$TEST_URL:9999/update" '{"Nombre":"Dummy","Codigo":"X999"}'
    assert_failure
    assert_output --partial "Intento 3"
}