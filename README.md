# Proyecto 10 - Reintentos seguros con idempotencia por método

## Descripción
Cliente CLI que implementa llamadas HTTP (GET/PUT/POST) con reintentos automáticos y backoff exponencial, respetando las propiedades de idempotencia de cada método HTTP para evitar efectos secundarios no deseados.

## Variables de entorno

| Variable | Descripción | Valor por defecto | Rango recomendado |
|----------|-------------|-------------------|-------------------|
| `MAX_RETRIES` | Número máximo de reintentos antes de fallar | 3 | 1-10 |
| `BACKOFF_MS` | Tiempo base de espera en milisegundos para backoff exponencial | 500 | 100-5000 |
| `HOST` | Dirección IP o nombre de host del servidor de destino | 127.0.0.1 | localhost, IPs válidas |
| `PORT` | Puerto del servidor donde se ejecuta la API | 8080 | 1024-65535 |

## Configuración del entorno

Para implementar estas variables de entorno, elija una de las siguientes opciones:

### Opción 1: Configuración manual
Ejecute desde la raíz del proyecto:
```bash
cp docs/.env.example .env
# Editar el .env según sus necesidades
nano .env
```

### Opción 2: Configuración automática con Makefile
Ejecute desde la raíz del proyecto:
```bash
make prepare
```
Luego, editar el .env según sus necesidades.

## Servidor Flask

El servidor utiliza las variables de entorno para el `HOST` y el `PORT`, evitando valores harcodeados, por defecto se ejecuta en la direccion `127.0.0.1:8080`. Para ejecutar el servidor puede elegir las siguientes opciones.

### Opción 1: Configuración manual
Ejecute desde la raíz del proyecto:
```bash
python3 src/server.py
```

### Opción 2: Configuración automática con Makefile
Ejecute desde la raíz del proyecto:
```bash
make server
```

## Cliente

El Cliente utiliza las variables de entorno para el `MAX_RETRIES` y el `BACKOFF_MS`, evitando valores harcodeados. El cliente puede realizar peticiones `GET`, `POST`, `PUT`. Para ejecutar el servidor puede elegir las siguientes opciones.

### Opción 1: Configuración manual
Para una peticion `GET` ejecuta el siguiente comando con una cierta **URL**
```bash 
chmod +x src/cliente.sh
./src/cliente.sh GET <URL>
```

Para una peticion `POST` ejecuta el siguiente comando con una cierta **URL** y un body opcional (se tiene un body por defecto). 
```bash 
chmod +x src/cliente.sh
./src/cliente.sh POST <URL> <BODY>
```
Tambien se cuenta con una flag para la asignacion de una llave para la idempotencia del metodo `POST`, la flag es `--idempotencykey` y es obligatorio colocar una llave al poner la flag.

```bash 
./src/cliente.sh POST <URL> <BODY> --idempotencykey <KEY>
```
Para una peticion `PUT` ejecuta el siguiente comando con una cierta **URL** y un body opcional (se tiene un body por defecto). 
```bash 
chmod +x src/cliente.sh
./src/cliente.sh PUT <URL> <BODY>
```

### Opción 2: Configuración automática con Makefile

Ejecute desde la raíz del proyecto:
```bash
make run
```
Se ejecuta las peticiones `GET`, `POST`, `PUT`, en ese orden. Y con **URLs** y **BODYs** definidos por defecto.

## Ejecución de pruebas

Las pruebas están implementadas con Bats y cubren la interacción completa entre el cliente (cliente.sh) y el servidor (server.py), actuando como pruebas end-to-end (E2E). Cada conjunto de pruebas valida comportamientos específicos de los endpoints (GET, POST, PUT) y escenarios de reintento ante fallas de red. Cada archivo de prueba `tests/nombre_prueba.bats` genera su salida limpia en out/<nombre_prueba>.out y el código de estado en out/<nombre_prueba>.status.

### Ejecución automatizada de pruebas

Ejecuta desde la raíz del proyecto:

```bash
make test
```

Este comando:
- Crea el entorno virtual `.venv/` (si no existe) con dependencias instaladas desde `requirements.txt` para poder levantar el servidor.
- Levanta temporalmente el servidor (server.py) en segundo plano.
- Ejecuta todos los archivos .bats dentro de tests/ contra el cliente (cliente.sh).
- Detiene el servidor al finalizar las pruebas.

### Extensión de las dependencias de las pruebas

Para añadir más dependencias de Bats, como bats-file, agrega a la variable BATS_MODULES el nombre de la nueva dependencia, signo igual (=) y url del repo con .git al final:

```Makefile
BATS_MODULES := \
	bats-support=https://github.com/bats-core/bats-support.git \
	bats-assert=https://github.com/bats-core/bats-assert.git \
    nueva-dependencia=repo-url
```

