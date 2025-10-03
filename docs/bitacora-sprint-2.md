# Bitácora Sprint 2

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