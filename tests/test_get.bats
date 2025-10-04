load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Casos positivos (+)

@test "GET courses retorna 200 y lista de cursos" {
  run cliente.sh GET "$TEST_URL:$PORT/courses"
  assert_success
  assert_output --partial "GET exitoso"
  assert_output --partial "Status: 200"
}


# Casos negativos (-)

@test "cliente falla con URL inválida" {
    run cliente.sh GET "ftp://bad-url"
    assert_failure
    assert_output --partial "Error: URL debe comenzar con http:// o https://"
}