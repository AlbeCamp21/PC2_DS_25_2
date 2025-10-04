load 'common.bash'
load 'test_helper/bats-support/load'
load 'test_helper/bats-assert/load'

# Casos positivos (+)

@test "cliente POST responde exitosamente con body por defecto" {
    run cliente.sh POST "$TEST_URL:$PORT/create"
    assert_success
    assert_output --partial '[✓]'
}

@test "POST /create crea un curso nuevo con 201" {
  body='{"Nombre":"Inteligencia Artificial","Codigo":"CC500"}'
  run cliente.sh POST "$TEST_URL:$PORT/create" "$body"
  assert_success
  assert_output --partial "POST exitoso"
  assert_output --partial "Status: 201"
}

@test "cliente POST /create respeta idempotency key custom" {
    body='{"Nombre":"Probabilidades","Codigo":"PRB456"}'
    run cliente.sh POST "$TEST_URL:$PORT/create" "$body" --idempotencykey "customkey123"
    assert_success
    assert_output --partial "Status: 201"
}


# Casos negativos (-)

@test "cliente POST falla si falta valor para --idempotencykey" {
    run cliente.sh POST "$TEST_URL:$PORT/resource" --idempotencykey
    assert_failure
    assert_output --partial "Error: --idempotencykey requiere un valor"
}

@test "POST /create con mismo Codigo retorna 409 (idempotencia)" {
  body='{"Nombre":"Inteligencia Artificial","Codigo":"CC500"}'
  run cliente.sh POST "$TEST_URL:$PORT/create" "$body" --idempotencykey "fixed-key-123"
  run cliente.sh POST "$TEST_URL:$PORT/create" "$body" --idempotencykey "fixed-key-123"
  assert_failure
  assert_output --partial "Status: 409"
}