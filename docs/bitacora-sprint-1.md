# Bitácora Sprint 1

### **Carga de variables**

Debido a que es una mala práctica añadir el archivo `.env` al repositorio remoto, entonces se crea el archivo `docs/.env.example`, lo cual ayudará a los miembros del grupo (o personas externas) a tener una ídea del formato que debe tener el archivo `.env` para este proyecto.

Simplemente se devería ejecutar en la raiz del proyecto:

```bash
cp docs/.env.example .env
# Editar el .env según sus necesidades
nano .env
```
Ahora, en el nuevo archivo `.env`, modificar las variables con los valores correctos para su uso.

Para cargar los valores de entorno, se debe ejecutar el script `cargar_env.sh`, ubicado en el directorio `src`:

```bash
source src/cargar_env.sh
```

Y para verificar que las variables se cargaron éxitosamente, se debe ejecutar el script `mostrar_env.sh`, ubicado en el directorio `src` (dar permisos de ejecución previamente):

```bash
./src/mostrar_env.sh
```

Para evitar todo este proceso que se menciono anteriormente, tambien se implemento un target en el Makefile que realize estas tareas de forma automatica. Para ejecutar ecriba el comando:

```bash
make prepare
```

### **Servidor Básico**

Se implementó un servidor Flask básico para la gestión de cursos con endpoints CRUD siguiendo los principios de 12-Factor App. El servidor fue desarrollado en el archivo `src/server.py` con las siguientes características:

#### **Configuración del Servidor**

El servidor utiliza variables de entorno para la configuración, evitando valores hardcodeados:

```python
HOST = os.environ.get("HOST","127.0.0.1")
PORT = int(os.environ.get("PORT", "8080"))
```

Por defecto, el servidor se ejecuta en `127.0.0.1:8080`, pero puede ser configurado mediante variables de entorno.

#### **Estructura de Datos**

Se implementó una estructura de datos en memoria para almacenar los cursos y manejar la idempotencia:

```python
courses = {
    1: {"Nombre": "Desarrollo de software", "Codigo": "CC3S2S"},
    2: {"Nombre": "Computacion Grafica", "Codigo": "CC431"} 
}

used_course_codes = {"CC3S2S", "CC431"}  # Manejo de idempotencia
```

#### **Endpoints Implementados**

**1. GET /courses**
- Retorna la lista de todos los cursos registrados
- Código de respuesta: 200 OK
- Formato de respuesta: Array JSON con cursos incluyendo ID

**2. POST /create**
- Crea un nuevo curso en el sistema
- Implementa control de idempotencia usando el código del curso
- Validaciones: JSON válido, presencia de 'Codigo' y 'Nombre'
- Códigos de respuesta:
  - 201: Curso creado exitosamente
  - 400: JSON inválido o campos faltantes
  - 409: Código de curso ya existe (idempotencia)

**3. PUT /update**
- Actualiza el nombre de un curso existente usando su código
- Validaciones: JSON válido, presencia de 'Codigo' y 'Nombre', existencia del curso
- Códigos de respuesta:
  - 200: Curso actualizado exitosamente
  - 400: JSON inválido o campos faltantes
  - 404: Código de curso no existe

#### **Ejecución del Servidor**

Para ejecutar el servidor, simplemente ejecutar desde la raíz del proyecto:

```bash
pip install -r requirements.txt
python3 src/server.py
```

El servidor se iniciará en modo debug y mostrará la URL de acceso en la consola.

### Primera prueba Bats

Resumen de lo avanzado:

- Creamos la prueba Bats mínima "cliente reintenta en caso de timeout" siguiendo el método RGR (rojo, verde, refactorizar) sin que todavía exista el ejecutable cliente.sh que queremos testear.
- También integramos en nuestro makefile con el target "deps" la instalación automática de dependencias complementarias a Bats. Make clone repos externos como bats-support y bats-assert de manera fácilmente extensible gracias a la declaración de estos en forma de pares clave-valor en el makefile.
- Además, si en el futuro añadimos más dependencias para nuestras preubas Bats, solo tenemos que volver a correr "make deps" para clonar los nuevos repos requeridos.
- Por último, como estamos clonando repositorios externos, para evitar que git los añada al hacer un "git add ." los estamos ignorando en la ruta tests/test_helper, que es donde se instalan.

#### Ejecución manual de la primera prueba

Creamos la prueba mínima "cliente reintenta en caso de timeout" en el archivo test/retries.bats. 
Si queremos ejecutarla manualmente, desde la raíz del repo ejecutamos este comando:

```bash
bats tests/retries.bats
```

Para lograr esto previamente necesitamos clonar los repositorios que complementan nuestro Bats en la ruta tests/test_helper con el comando "git clone --depth 1 <repo-url> <ruta-local>". 
Estos son los repos que usamos por ahora:

- bats-support: https://github.com/bats-core/bats-support.git
- bats-assert: https://github.com/bats-core/bats-assert.git

La prueba falla al no existir todavía el script de CLI que queremos testear:

```txt
-- output does not contain substring --
   substring : Intento 3
   output    : /home/aldolunab/.local/lib/bats-core/test_functions.bash: line 158: cliente.sh: command not found
```

También se agregó una función setup_file() para crear el directorio out/ si no existiera, y un teardown() para crear reportes de la salida y código de estado al finalizar cada prueba.

#### Ejecución automatizada de la prueba

Integramos en el Makefile un target "deps" para instalar dependencias de Bats, y este target a su vez es prerequisito del target "test", el cual ejecuta todas las pruebas en el directorio tests de extensión .bats como retries.bats con el comando generalizado "bats tests/*.bats". Los targets dependen entre sí de esta forma:

```txt
(target real para clonar repos) -> deps -> test
```

Entonces, basta con ejecutar este comando para correr las pruebas bats:

```bash
make test
```

#### Extender las dependencias de las pruebas bats

Diseñamos la instalación de las pruebas bats para que fácilmente extensible. Para agregar más dependencias de Bats solo añadimos un par clave-valor separado con el signo igual (=) en la variable BATS_MODULES, así:

```Makefile
BATS_MODULES := \
	bats-support=https://github.com/bats-core/bats-support.git \
	bats-assert=https://github.com/bats-core/bats-assert.git \
  nueva-dependencia=url-del-repo-complementario-de-bats
```

Para instalar la nueva dependencia ejecutamos el comando:

```bash
make deps
```

Se clonará el repo en la ruta tests/test_helper/nueva-dependencia.