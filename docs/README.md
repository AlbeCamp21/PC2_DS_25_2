# Proyecto 10 - Reintentos seguros con idempotencia por método

## Descripción
Cliente CLI que implementa llamadas HTTP (GET/PUT/POST) con reintentos automáticos y backoff exponencial, respetando las propiedades de idempotencia de cada método HTTP para evitar efectos secundarios no deseados.

## Variables de entorno

| Variable | Descripción | Valor por defecto | Rango recomendado |
|----------|-------------|-------------------|-------------------|
| `MAX_RETRIES` | Número máximo de reintentos antes de fallar | 3 | 1-10 |
| `BACKOFF_MS` | Tiempo base de espera en milisegundos para backoff exponencial | 500 | 100-5000 |

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

## Ejecución de pruebas

### Ejecución automatizada de pruebas

Ejecuta desde la raíz del proyecto:

```bash
make test
```

### Extensión de las dependencias de las pruebas

Para añadir más dependencias de Bats, como bats-file, agrega a la variable BATS_MODULES el nombre de la nueva dependencia, signo igual (=) y url del repo con .git al final:

```Makefile
BATS_MODULES := \
	bats-support=https://github.com/bats-core/bats-support.git \
	bats-assert=https://github.com/bats-core/bats-assert.git \
    nueva-dependencia=repo-url
```

