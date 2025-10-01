# Variables
SHELL := /bin/bash
.PHONY: tools prepare build test run pack clean help deps
.DEFAULT_GOAL := help
OUT_DIR := out
DIST_DIR := dist
TEST_DIR := tests
BATS_HELPER_DIR:= $(TEST_DIR)/test_helper

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

tools: ## Verificación de herramientas requeridas
	@echo -e "\n[+] Verificando herramientas...\n"
	@for cmd in curl ss nc dig bats; do \
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

build: ## Generar artefactos intermedios en out/
	@echo -e "\n[+] Generando..."

test: deps ## Ejecutar tests
	@echo -e "\n[+] Ejecutando pruebas..."
	bats tests/*.bats

run: ## Ejecutar cliente CLI con reintentos y métricas
	@echo -e "\n[+] Ejecutando cliente CLI..."

pack: ## Empaquetar proyecto para distribución (tar.gz)
	@echo -e "\n[+] Empaquetando proyecto..."

clean: ## Limpiar archivos generados
	@echo -e "\n[+] Limpiando directorios/archivos generados..."
	@rm -rf $(OUT_DIR) $(DIST_DIR)
	@echo -e "\n[+] Entorno limpio"

help: ## Mostrar las opciones disponibles
	@echo -e "\n[+] Opciones:\n"
	@grep -E '^[a-zA-Z0-9_\-]+:.*?##' $(MAKEFILE_LIST) | \
		awk 'BEGIN{FS=":.*?##"}{printf "  \033[36m%-22s\033[0m %s\n", $$1, $$2}'
