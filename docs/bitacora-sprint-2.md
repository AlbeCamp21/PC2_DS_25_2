# Bitácora Sprint 2

Video realizado por el sprint 2: [Sprint 2](https://youtu.be/TLqKNjE7PEQ)

## **Cliente HTTP CLI**

Se implementó un cliente HTTP de línea de comandos robusto con capacidades de reintentos, backoff exponencial, métricas de latencia y **soporte de idempotencia**. El cliente fue desarrollado en el archivo `src/cliente.sh` con las siguientes características:

### **Configuración del Cliente**

El cliente utiliza variables de entorno para la configuración, evitando valores hardcodeados:

```bash
readonly MAX_RETRIES=${MAX_RETRIES:-3}
readonly BACKOFF_MS=${BACKOFF_MS:-500}
```

Por defecto, el cliente realiza máximo 3 reintentos con un backoff inicial de 500ms, pero puede ser configurado mediante las variables de entorno `MAX_RETRIES` y `BACKOFF_MS` en el archivo `.env`.

### **Estructura de Reintentos**

Se implementó un algoritmo de **backoff exponencial** para manejar fallos de red de manera eficiente:

```bash
calculate_backoff() {
    local attempt=$1
    local backoff_ms=$((BACKOFF_MS * (2 ** (attempt - 1))))
    echo $backoff_ms
}
```

Los tiempos de espera siguen la progresión: 500ms → 1000ms → 2000ms → 4000ms...

### **Soporte de Idempotencia**

#### **Políticas por Método HTTP:**

**GET y PUT: Idempotentes por naturaleza**
- Reintentos seguros sin riesgo de duplicación
- No requieren claves de idempotencia especiales
- Pueden reintentarse múltiples veces sin efectos secundarios

**POST: No idempotente**
- Requiere clave de idempotencia única para evitar duplicados
- Generación automática de claves basadas en contenido (URL + body)
- Soporte para claves manuales mediante flag `--idempotencykey`

#### **Generación automatica de Claves de Idempotencia:**

```bash
generar_llave_hash(){
    local content="$*"
    echo "$(echo "${content}" | sha256sum | cut -d' ' -f1 | head -c 32)"
}
```

### **Métodos HTTP Soportados**

**1. GET**
- Realiza peticiones de consulta al servidor
- Sintaxis: `./cliente.sh GET <URL>`
- **Idempotencia**: Natural, reintentos seguros

**2. POST**
- Crea nuevos recursos en el servidor
- Sintaxis: `./cliente.sh POST <URL> [BODY] [--idempotencykey <KEY>]`
- Body por defecto: `{"Nombre":"Fisica 2","Codigo":"CF2A2"}`
- **Idempotencia**: Requiere clave única, generada automáticamente o manual

**3. PUT**
- Actualiza recursos existentes en el servidor
- Sintaxis: `./cliente.sh PUT <URL> [BODY]`
- Body por defecto: `{"Nombre":"Laboratorio de Fisica 1","Codigo":"CF2A2"}`
- **Idempotencia**: Natural, reintentos seguros


### **Headers HTTP de Idempotencia**

Para operaciones POST, el cliente envía automáticamente:

```http
POST /create HTTP/1.1
Content-Type: application/json
Idempotency-Key: auto-a1b2c3d4e5f67890
```

**Comportamiento en el servidor:**
- Primera petición con clave: Se procesa y almacena resultado
- Petición repetida con misma clave: Se devuelve resultado almacenado
- Sin duplicación de recursos ni efectos secundarios

### **Timeouts y Configuración de cURL**

```bash
curl -s -w '- HTTP Status: %{http_code}' -o '$output_file' --connect-timeout 5 --max-time 5
```

- **Connect timeout**: 5 segundos para establecer conexión
- **Max timeout**: 5 segundos para completar la petición
- **Modo silencioso**: Sin mostrar progreso de cURL
- **Headers de idempotencia**: Agregados automáticamente para POST

### **Sistema de Métricas y Logging**

**Métricas CSV:**
- Archivo: `out/metrics.csv`
- Formato: `timestamp,método,URL,intentos,status_code,duración_ms`
- Registra todas las peticiones exitosas y fallidas

**Logs detallados:**
- Archivo: `out/requests_{MÉTODO}_{HOST}.log`
- Incluye timestamp, intentos, duración, códigos de estado y claves de idempotencia
- Formato mejorado para POST: `IdempotencyKey: <clave>`

**Logs de idempotencia:**
- Archivo: `out/post-keys.log`
- Rastrea todas las claves de idempotencia utilizadas
- Permite auditoría de operaciones POST

**Respuestas del servidor:**
- Archivo: `out/response_{MÉTODO}_{HOST}_{TIMESTAMP}.txt`
- Almacena el contenido completo de las respuestas del servidor

### **Ejecución del Cliente**

Para ejecutar el cliente, primero dar permisos de ejecución y luego ejecutar desde la raíz del proyecto:

```bash
chmod +x src/cliente.sh

# Ejemplos básicos
./src/cliente.sh GET http://localhost:8080/courses
./src/cliente.sh POST http://localhost:8080/create '{"Nombre":"Calculo 1","Codigo":"MAT101"}'
./src/cliente.sh PUT http://localhost:8080/update '{"Nombre":"Calculo Avanzado","Codigo":"MAT101"}'

# Ejemplos con idempotencia
./src/cliente.sh POST http://localhost:8080/create --idempotencykey 123456
./src/cliente.sh POST http://localhost:8080/create '{"Nombre":"Fisica","Codigo":"FIS101"}' --idempotencykey curso-fisica-2025
```

El cliente creará automáticamente el directorio `out/` para almacenar métricas, logs, claves de idempotencia y respuestas, mostrando información detallada sobre el progreso de las peticiones con códigos de color para facilitar la lectura.

## Pruebas End-to-End con Bats

El objetivo actual fue **ampliar y automatizar las pruebas end-to-end** (E2E), verificando la interacción real entre los componentes cliente.sh y server.py mediante el framework Bats.

### Objetivos

1. **Refactorizar la estructura de pruebas** para permitir la extensión modular de casos de test.
2. **Centralizar la configuración común de entorno** (hooks de Bats).
3. **Automatizar la ejecución completa de pruebas** desde el Makefile, incluyendo:

   - Levantamiento y apagado del servidor.
   - Creación de entorno virtual Python.
   - Instalación de dependencias.
4. **Ampliar la cobertura** con nuevos casos positivos y negativos para los métodos HTTP `GET`, `POST`, `PUT` y manejo de *retries*.

### Refactorización Realizada

#### Estructura modular de pruebas

Se reorganizaron los tests en varios archivos:

| Archivo                   | Propósito principal                                                           |
| ------------------------- | ----------------------------------------------------------------------------- |
| `tests/test_retries.bats` | Casos de reintentos por timeout o falta de respuesta del servidor.            |
| `tests/test_get.bats`     | Pruebas del endpoint `GET /courses`.                                          |
| `tests/test_post.bats`    | Pruebas de creación (`POST /create`) e idempotencia.                          |
| `tests/test_put.bats`     | Pruebas de actualización (`PUT /update`).                                     |
| `tests/common.bash`       | Hooks comunes (`setup_file`, `setup`, `teardown`) y configuración de entorno. |

Los archivos `.bats` cargan `common.bash` para compartir configuración y utilidades.

#### Hooks centralizados

El nuevo archivo `common.bash` define:

- **`setup_file()`**: crea el directorio `out/` para almacenar resultados.
- **`setup()`**: configura `PATH`, URL base y puerto del servidor.
- **`teardown()`**: limpia las secuencias ANSI de la salida y guarda logs individuales de cada prueba:

  - `out/<nombre_prueba>.out` - salida limpia.
  - `out/<nombre_prueba>.status` - código de salida.

### Automatización con Makefile

Se actualizó el Makefile para incluir un flujo de pruebas completamente automatizado:

#### Nuevo target `prepare`

Crea y configura un entorno de desarrollo reproducible:

1. Copia `.env.example` -> `.env`.
2. Da permisos de ejecución a los scripts Bash.
3. Crea entorno virtual `.venv` (si no existe).
4. Instala dependencias desde `requirements.txt`.

#### Nuevo target `test`

Ejecuta las pruebas end-to-end:

1. Levanta temporalmente el servidor Python.
2. Corre todos los tests Bats (`tests/*.bats`).
3. Detiene el servidor automáticamente.

### Casos de Prueba Implementados

#### `test_retries.bats`

Verifica que el cliente reintente hasta 3 veces ante *timeout* o puertos inaccesibles (assert_output --partial 'Intento 3'), y evita falsos positivos validando que no sean más de 3 (refute_output --partial 'Intento 4')

#### `test_get.bats`

- **Positivo:** `GET /courses` retorna status 200 y mensaje de éxito.
- **Negativo:** URL con esquema inválido (`ftp://...`) genera error.

#### `test_post.bats`

- **Positivos:**

  - Creación de curso (`Status: 201`).
  - Soporte para `--idempotencykey` custom.
- **Negativos:**

  - Falta de valor en `--idempotencykey` produce error.
  - Repetir `POST` con mismo `idempotencykey` retorna `409 Conflict`.

#### `test_put.bats`

- **Positivo:** `PUT /update` actualiza curso existente correctamente.
- **Negativo:** reintento automático si el servidor no responde.

### Resultados Esperados

| Categoría                 | Resultado                             |
| ------------------------- | ------------------------------------- |
| Configuración del entorno | Exitosa (entorno virtual funcional).  |
| Ejecución de pruebas      | Completada sin intervención manual.   |
| Logs individuales         | Generados en carpeta `out/`.          |
| Cobertura de endpoints    | GET, POST, PUT, manejo de reintentos. |
