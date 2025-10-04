# Bitácora Sprint 3

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
