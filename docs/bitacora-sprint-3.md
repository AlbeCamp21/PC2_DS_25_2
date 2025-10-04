# Bitácora Sprint 3

Video realizado por el sprint 3: [Sprint 3](https://youtu.be/qP6ESG5FVBQ)

## Empaquetado reproducible y caché incremental

### Target `pack` - Empaquetado reproducible

Se configuró el target `pack` en el Makefile que genera un archivo `dist/proyecto10.tar.gz` reproducible incluyendo todos los archivos necesarios:

```makefile
pack: build ## Empaquetar proyecto para distribución (tar.gz)
	@mkdir -p $(DIST_DIR)
	@tar --mtime='$(BUILD_TIME)' --sort=name --owner=0 --group=0 \
		-czf $(DIST_DIR)/proyecto10.tar.gz \
		--exclude='$(OUT_DIR)' --exclude='$(DIST_DIR)' --exclude='.git' --exclude='.env' \
		src/ docs/ tests/ Makefile requirements.txt README.md
	@echo -e "\n[+] Paquete creado: $(DIST_DIR)/proyecto10.tar.gz"
```

**Características del empaquetado reproducible:**
- **Timestamp fijo**: `--mtime='2025-01-01 00:00:00'` garantiza archivos idénticos
- **Orden determinista**: `--sort=name` ordena archivos alfabéticamente
- **Owner/group consistente**: `--owner=0 --group=0` elimina variaciones de usuario
- **Exclusiones**: Se excluyen directorios temporales y archivos sensibles

**Contenido incluido:**
- `src/` - Scripts y servidor Python
- `docs/` - Documentación del proyecto
- `tests/` - Pruebas BATS y dependencias
- `Makefile` - Sistema de build
- `requirements.txt` - Dependencias Python
- `README.md` - Documentación principal

### Caché incremental - Evidencia de funcionamiento

Se implementó un sistema de caché incremental que evita reconstruir artefactos si no hay cambios en los archivos fuente.

**Configuración de dependencias:**
```makefile
build: $(OUT_DIR)/build.log

$(OUT_DIR)/build.log: src/*.sh src/*.py Makefile
	@mkdir -p $(OUT_DIR)
	@echo "Build timestamp: $(BUILD_TIME)" > $@
	@echo "Scripts validated at build" >> $@
	@echo -e "\n[+] Build completado"
```

### Evidencia del caché incremental

#### Primera ejecución (build inicial):
```bash
$ make build

[+] Build completado
```

#### Segunda ejecución (sin cambios - CACHE FUNCIONA):
```bash
$ make build
make: Nothing to be done for 'build'.
```

Esta salida demuestra que **el caché incremental funciona correctamente**:
- Primera vez: Se ejecuta el build completo
- Segunda vez: Make detecta que `out/build.log` está actualizado y no hace nada
- El sistema evita trabajo innecesario cuando no hay cambios

#### Para forzar rebuild (si modificas archivos):
```bash
$ touch src/cliente.sh  # Simulando cambio en un archivo
$ make build
[+] Build completado   # Se rebuildeará porque detecta cambios
```

---

## Pruebas de reintentos y manejo de entorno

### Cambios realizados

1. **Nueva lógica de carga de entorno en `utils.sh`**
   Se modificó la función `cargar_env()` para que las variables definidas en el entorno del proceso no sean sobreescritas por las del archivo `.env`.

   Esto permite inyectar variables específicas por prueba sin perder compatibilidad con la configuración global del proyecto.
   Resultado: el entorno de ejecución se volvió **más flexible y predecible** durante las pruebas.

2. **Preconfiguración de entorno común (`common.bash`)**
   Se agregaron valores por defecto que funcionan como **fixtures** globales para todas las pruebas.

   De esta forma, las pruebas que no requieren personalización usan estos valores base, reduciendo el tiempo total de ejecución (por el `BACKOFF_MS` reducido).

3. **Nuevas pruebas en `test_retries.bats`**

   - **Prueba 1:** Verifica que el cliente respete la cantidad de reintentos cuando `MAX_RETRIES=2`.
   - **Prueba 2:** Extiende la verificación para `MAX_RETRIES=3`, asegurando aislamiento entre tests.
   - **Prueba 3:** Comprueba que el cliente respete el tiempo total de espera derivado de `BACKOFF_MS`, midiendo la duración total de ejecución y asegurando que esté dentro de un rango establecido:

### Resultados

* Las pruebas ahora **corren en aislamiento completo**, sin interferencias del entorno global ni dependencias del archivo `.env`.
* Se validó exitosamente que:

  * `MAX_RETRIES` se respete en cada ejecución.
  * El cliente espere el tiempo configurado por `BACKOFF_MS`.
  * El entorno base (fixtures) acelere las pruebas que no dependen del tiempo.

Esta refactorización mejora significativamente la **modularidad**, **reproducibilidad** y **velocidad** de la suite de pruebas Bats.
Cada prueba puede ahora definir su propio entorno sin comprometer el comportamiento global del cliente, cumpliendo con las mejores prácticas de **testeo aislado y controlado por entorno**.
