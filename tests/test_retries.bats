load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

@test "cliente reintenta en caso de timeout" {
    run cliente.sh GET "$TEST_URL:9999/unreachable"
    assert_failure
    assert_output --partial 'Intento 3'
    refute_output --partial 'Intento 4'
}