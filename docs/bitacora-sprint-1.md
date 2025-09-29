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
