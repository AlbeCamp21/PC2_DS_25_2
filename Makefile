# Variables
SHELL := /bin/bash
.PHONY: check-env tools prepare test server run pack clean help
.DEFAULT_GOAL := help
OUT_DIR := out
DIST_DIR := dist
TEST_DIR := tests
BATS_HELPER_DIR:= $(TEST_DIR)/test_helper
VENV :=.venv
PY :=$(VENV)/bin/python

# Timestamp fijo para reproducibilidad  
BUILD_TIME = 2025-01-01 00:00:00

# pares "nombre=repo", extensible desde un solo lugar
BATS_MODULES := \
	bats-support=https://github.com/bats-core/bats-support.git \
	bats-assert=https://github.com/bats-core/bats-assert.git

# expande en rutas locales, ej. tests/test_helper/bats-support/.git
BATS_TARGETS := $(foreach m,$(BATS_MODULES),$(BATS_HELPER_DIR)/$(firstword $(subst =, ,$m))/.git)

deps: $(BATS_TARGETS) ## Instala dependencias

# clona si no existe el directorio .git
$(BATS_HELPER_DIR)/%/.git:
	@echo "Instalando $*..."
	@git clone --depth 1 $(word 2,$(subst =, ,$(filter $*=%,$(BATS_MODULES)))) $(BATS_HELPER_DIR)/$*

check-env: ## Verificar que MAX_RETRIES y BACKOFF_MS están definidos en .env
	@echo -e "\n[+] Verificando variables en .env..."
	@if [ ! -f ".env" ]; then \
		echo -e "\n[!] ERROR: Archivo .env no encontrado"; \
		echo -e "\tEjecute 'make prepare' para crearlo"; \
		exit 1; \
	fi
	@source .env && \
	if [ -z "$$MAX_RETRIES" ]; then \
		echo -e "\n\t[!] ERROR: MAX_RETRIES no definida"; exit 1; \
	else \
		echo -e "\n\t[+] MAX_RETRIES = $$MAX_RETRIES"; \
	fi && \
	if [ -z "$$BACKOFF_MS" ]; then \
		echo -e "\t[!] ERROR: BACKOFF_MS no definida"; exit 1; \
	else \
		echo -e "\t[+] BACKOFF_MS = $$BACKOFF_MS"; \
	fi && \
	if [ -z "$$HOST" ]; then \
		echo -e "\t[!] ERROR: HOST no definida"; exit 1; \
	else \
		echo -e "\t[+] BACKOFF_MS = $$HOST"; \
	fi && \
	if [ -z "$$PORT" ]; then \
		echo -e "\t[!] ERROR: PORT no definida"; exit 1; \
	else \
		echo -e "\t[+] BACKOFF_MS = $$PORT"; \
	fi
	@echo -e "\n[+] Variables verificadas correctamente"

tools: ## Verificación de herramientas requeridas
	@echo -e "\n[+] Verificando herramientas...\n"
	@for cmd in bc curl ss nc dig bats; do \
		if ! command -v $$cmd &>/dev/null; then \
			echo -e "\t[!] Falta instalar $$cmd"; exit 1; \
		else \
			echo -e "\tEncontrado: $$cmd"; \
		fi; \
	done
	@echo -e "\n[+] Todas las herramientas están instaladas" 

prepare: ## Crear entorno de trabajo
	@echo -e "\n[+] Configurando entorno de trabajo..."
	@cp docs/.env.example .env
	@chmod +x src/*.sh
	@echo -e "\n[+] Entorno creado correctamente" 
	@if [ ! -d $(VENV) ]; then \
		echo -e "\n[+] Creando entorno virtual de Python..."; \
		python3 -m venv $(VENV); \
	else \
		echo -e "\n[+] Entorno virtual ya existe, usando $(VENV)"; \
	fi
	@echo -e "\n[+] Instalando dependencias desde requirements.txt..."
	@. $(VENV)/bin/activate && pip install --upgrade pip && pip install -r requirements.txt
	@echo -e "\n[+] Entorno creado correctamente"

build: $(OUT_DIR)/build.log ## Generar artefactos intermedios en out/

$(OUT_DIR)/build.log: src/*.sh src/*.py Makefile
	@mkdir -p $(OUT_DIR)
	@echo -e "[+] Build Log" > $@
	@echo "Timestamp: $(BUILD_TIME)" >> $@
	@echo "Validando sintaxis bash..." >> $@
	@bash -n src/cliente.sh && echo -e "\t[+] cliente.sh OK" >> $@ || echo -e "\t[!] cliente.sh ERROR" >> $@
	@bash -n src/utils.sh && echo -e "\t[+] utils.sh OK" >> $@ || echo -e "\t[!] utils.sh ERROR" >> $@
	@echo "Validando sintaxis Python..." >> $@
	@python3 -m py_compile src/server.py && echo -e "\t[+] server.py OK" >> $@ || echo -e "\t[!] server.py ERROR" >> $@
	@echo "Build completado" >> $@
	@echo -e "\n[+] Build completado"

server: ## Levantar servidor Flask en background
	@echo -e "\n[+] Levantando servidor Flask..."
	@$(PY) src/server.py

test: deps prepare ## Ejecutar tests
	@echo -e "\n[+] Ejecutando pruebas..."
	@echo "Levantando servidor..."
	@$(PY) src/server.py & SERVER_PID=$$!; \
	sleep 1; \
	bats tests/*.bats; \
	kill $$SERVER_PID

run: ## Ejecutar cliente CLI con métricas por defecto
	@echo -e "\n[+] Ejecutando cliente CLI..."
	@echo -e "\n[+] 1. GET - Listar cursos"
	@source .env && bash src/cliente.sh GET "http://$$HOST:$$PORT/courses"
	@echo -e "\n[+] 2. POST - Crear curso"
	@source .env && bash src/cliente.sh POST "http://$$HOST:$$PORT/create"
	@echo -e "\n[+] 3. PUT - Actualizar curso"
	@source .env && bash src/cliente.sh PUT "http://$$HOST:$$PORT/update"

pack: build ## Empaquetar proyecto para distribución (tar.gz)
	@mkdir -p $(DIST_DIR)
	@tar --mtime='$(BUILD_TIME)' --sort=name --owner=0 --group=0 \
		-czf $(DIST_DIR)/proyecto10.tar.gz \
		--exclude='$(OUT_DIR)' --exclude='$(DIST_DIR)' --exclude='.git' --exclude='.env' \
		src/ docs/ tests/ Makefile requirements.txt README.md
	@echo -e "\n[+] Paquete creado: $(DIST_DIR)/proyecto10.tar.gz"

clean: ## Limpiar archivos generados
	@echo -e "\n[+] Limpiando directorios/archivos generados..."
	@rm -rf $(OUT_DIR) $(DIST_DIR)
	@echo -e "\n[+] Entorno limpio"

help: ## Mostrar las opciones disponibles
	@echo -e "\033[1;32mComandos disponibles:\033[0m\n"
	@echo -e "\033[1;35mConfiguración:\033[0m"
	@grep -E '^(check-env|tools|prepare):.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[1;35mDesarrollo:\033[0m"
	@grep -E '^(build|server|test|run):.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[1;35mUtilidades:\033[0m"
	@grep -E '^(pack|clean|help):.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'
	@echo -e "\n\033[1;33mEjemplo de uso:\033[0m"
	@echo -e "  make prepare && make check-env && make tools"
	@echo -e "\n\033[1;33mVariables requeridas:\033[0m MAX_RETRIES, BACKOFF_MS\n"
