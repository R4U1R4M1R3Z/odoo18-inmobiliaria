# ==========================================
#  Makefile Profesional
# ==========================================

# Cargar variables desde .env
ifneq (,$(wildcard ./.env))
    include .env
    export
endif

.PHONY: help up down restart logs shell psql redis-cli new install update uninstall \
        init dropdb reset backup restore list-backups clean-logs env status health \
        dev prod tools test install-multi update-multi prune generate-password

# Variables con valores por defecto
DB_NAME ?= $(ODOO_DB_NAME)
DB_USER ?= $(POSTGRES_USER)
DB_LANG ?= $(ODOO_DB_LANG)
MODULE ?= real_estate_base
BACKUP_DIR := ./backups
TIMESTAMP := $(shell date +%Y%m%d_%H%M%S)

# Colores
RESET := \033[0m
BOLD := \033[1m
DIM := \033[2m
RED := \033[31m
GREEN := \033[32m
YELLOW := \033[33m
BLUE := \033[34m
MAGENTA := \033[35m
CYAN := \033[36m
WHITE := \033[37m

# ==========================================
#  AYUDA
# ==========================================

help:
	@echo ""
	@echo "$(CYAN)$(BOLD)╔═══════════════════════════════════════════════════════════╗$(RESET)"
	@echo "$(CYAN)$(BOLD)║        			 Comandos disponibles    	              ║$(RESET)"
	@echo "$(CYAN)$(BOLD)╚═══════════════════════════════════════════════════════════╝$(RESET)"
	@echo ""
	@echo "$(BLUE)  Configuración actual (.env):$(RESET)"
	@echo "   BD: $(BOLD)$(DB_NAME)$(RESET) | Usuario: $(BOLD)$(DB_USER)$(RESET) | Idioma: $(BOLD)$(DB_LANG)$(RESET)"
	@echo ""
	@echo "$(YELLOW) SERVICIOS:$(RESET)"
	@echo "  $(GREEN)make up$(RESET)                -  Levantar servicios base (odoo + db + redis)"
	@echo "  $(GREEN)make down$(RESET)              -  Bajar todos los servicios"
	@echo "  $(GREEN)make restart$(RESET)           -  Reiniciar Odoo"
	@echo "  $(GREEN)make logs$(RESET)              -  Ver logs en tiempo real"
	@echo "  $(GREEN)make status$(RESET)            -  Estado de los servicios"
	@echo "  $(GREEN)make health$(RESET)            -  Verificar salud de servicios"
	@echo ""
	@echo "$(YELLOW) PERFILES:$(RESET)"
	@echo "  $(GREEN)make dev$(RESET)               -  Modo desarrollo (+ mailpit)"
	@echo "  $(GREEN)make prod$(RESET)              -  Modo producción (+ traefik)"
	@echo "  $(GREEN)make tools$(RESET)             -  Herramientas (pgadmin, redis-commander, mailpit)"
	@echo ""
	@echo "$(YELLOW) ACCESO:$(RESET)"
	@echo "  $(GREEN)make shell$(RESET)             -  Shell en contenedor Odoo"
	@echo "  $(GREEN)make psql$(RESET)              -  Consola PostgreSQL"
	@echo "  $(GREEN)make redis-cli$(RESET)         -  Consola Redis"
	@echo ""
	@echo "$(YELLOW) MÓDULOS:$(RESET)"
	@echo "  $(GREEN)make new m=nombre$(RESET)      -  Crear módulo nuevo"
	@echo "  $(GREEN)make install m=nombre$(RESET)  -  Instalar módulo"
	@echo "  $(GREEN)make update m=nombre$(RESET)   -  Actualizar módulo"
	@echo "  $(GREEN)make uninstall m=nombre$(RESET)-   Desinstalar módulo"
	@echo "  $(GREEN)make install-multi m=\"a,b\"$(RESET) -  Instalar varios módulos"
	@echo "  $(GREEN)make test m=nombre$(RESET)     -  Ejecutar tests del módulo"
	@echo ""
	@echo "$(YELLOW) BASE DE DATOS:$(RESET)"
	@echo "  $(GREEN)make init$(RESET)              -  Crear BD base"
	@echo "  $(GREEN)make dropdb$(RESET)            -  Eliminar BD"
	@echo "  $(GREEN)make reset$(RESET)             -  Recrear BD desde cero"
	@echo "  $(GREEN)make backup$(RESET)            -  Backup comprimido"
	@echo "  $(GREEN)make restore f=file$(RESET)    -  Restaurar backup"
	@echo "  $(GREEN)make list-backups$(RESET)      -  Listar backups"
	@echo ""
	@echo "$(YELLOW) MANTENIMIENTO:$(RESET)"
	@echo "  $(GREEN)make clean-logs$(RESET)        -  Limpiar logs Docker"
	@echo "  $(GREEN)make prune$(RESET)             -  Limpiar recursos Docker no usados"
	@echo "  $(GREEN)make env$(RESET)               -  Mostrar configuración"
	@echo "  $(GREEN)make generate-password$(RESET) -  Generar password para Traefik"
	@echo ""
	@echo "$(CYAN) Accesos:$(RESET)"
	@echo "  • Odoo:           $(BOLD)http://localhost:$(ODOO_PORT)$(RESET)"
	@echo "  • Mailpit:        $(BOLD)http://localhost:$(MAILPIT_UI_PORT)$(RESET) $(DIM)(make dev)$(RESET)"
	@echo "  • pgAdmin:        $(BOLD)http://localhost:$(PGADMIN_PORT)$(RESET) $(DIM)(make tools)$(RESET)"
	@echo "  • Redis Commander:$(BOLD)http://localhost:$(REDIS_COMMANDER_PORT)$(RESET) $(DIM)(make tools)$(RESET)"
	@echo "  • Traefik:        $(BOLD)http://localhost:$(TRAEFIK_DASHBOARD_PORT)$(RESET) $(DIM)(make prod)$(RESET)"
	@echo ""

# ==========================================
#  VERIFICACIONES
# ==========================================

check-docker:
	@docker info > /dev/null 2>&1 || (echo "$(RED) Docker no está corriendo$(RESET)" && exit 1)

check-env:
	@if [ ! -f .env ]; then \
		echo "$(RED) Archivo .env no encontrado$(RESET)"; \
		echo "   $(YELLOW)Copia .env.example a .env y configura las variables$(RESET)"; \
		exit 1; \
	fi

check-module:
	@if [ -z "$(m)" ]; then \
		echo "$(RED) Error: Especifica el módulo$(RESET)"; \
		echo "   Uso: $(YELLOW)make $(MAKECMDGOALS) m=nombre_modulo$(RESET)"; \
		exit 1; \
	fi

# ==========================================
#   CONFIGURACIÓN
# ==========================================

env: check-env
	@echo "$(CYAN)$(BOLD) Configuración actual (.env):$(RESET)"
	@echo ""
	@echo "$(YELLOW)General:$(RESET)"
	@echo "  COMPOSE_PROJECT_NAME = $(COMPOSE_PROJECT_NAME)"
	@echo "  TIMEZONE            = $(TIMEZONE)"
	@echo ""
	@echo "$(YELLOW)Odoo:$(RESET)"
	@echo "  ODOO_VERSION        = $(ODOO_VERSION)"
	@echo "  ODOO_PORT           = $(ODOO_PORT)"
	@echo "  ODOO_DEV_MODE       = $(ODOO_DEV_MODE)"
	@echo "  ODOO_DB_NAME        = $(ODOO_DB_NAME)"
	@echo "  ODOO_DB_LANG        = $(ODOO_DB_LANG)"
	@echo "  ODOO_CPU_LIMIT      = $(ODOO_CPU_LIMIT)"
	@echo "  ODOO_MEMORY_LIMIT   = $(ODOO_MEMORY_LIMIT)"
	@echo ""
	@echo "$(YELLOW)PostgreSQL:$(RESET)"
	@echo "  POSTGRES_VERSION    = $(POSTGRES_VERSION)"
	@echo "  POSTGRES_USER       = $(POSTGRES_USER)"
	@echo "  POSTGRES_PORT       = $(POSTGRES_PORT)"
	@echo "  DB_CPU_LIMIT        = $(DB_CPU_LIMIT)"
	@echo "  DB_MEMORY_LIMIT     = $(DB_MEMORY_LIMIT)"
	@echo ""
	@echo "$(YELLOW)Redis:$(RESET)"
	@echo "  REDIS_VERSION       = $(REDIS_VERSION)"
	@echo "  REDIS_MAXMEMORY     = $(REDIS_MAXMEMORY)"
	@echo ""
	@echo "$(YELLOW)Dominios (prod):$(RESET)"
	@echo "  ODOO_DOMAIN         = $(ODOO_DOMAIN)"
	@echo "  ACME_EMAIL          = $(ACME_EMAIL)"

generate-password:
	@echo "$(CYAN) Generador de password para Traefik Basic Auth$(RESET)"
	@read -p "Usuario: " user; \
	read -s -p "Password: " pass; \
	echo ""; \
	if command -v htpasswd > /dev/null; then \
		result=$$(htpasswd -nb $$user $$pass | sed -e 's/\$$/\$$\$$/g'); \
		echo "$(GREEN) Añade esto a tu .env:$(RESET)"; \
		echo "TRAEFIK_BASIC_AUTH=$$result"; \
	else \
		echo "$(YELLOW)  htpasswd no instalado. Instala apache2-utils$(RESET)"; \
	fi

# ==========================================
#  GESTIÓN DE SERVICIOS
# ==========================================

up: check-docker check-env
	@echo "$(GREEN) Levantando servicios base...$(RESET)"
	@docker-compose up -d web db redis
	@$(MAKE) -s _wait-healthy
	@echo "$(GREEN) Servicios activos$(RESET)"
	@echo "   $(CYAN)→ Odoo: http://localhost:$(ODOO_PORT)$(RESET)"

down: check-docker
	@echo "$(YELLOW) Bajando servicios...$(RESET)"
	@docker-compose --profile dev --profile prod --profile tools down
	@echo "$(GREEN) Servicios detenidos$(RESET)"

restart: check-docker
	@echo "$(YELLOW) Reiniciando Odoo...$(RESET)"
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Odoo reiniciado$(RESET)"

logs: check-docker
	@echo "$(CYAN) Logs de Odoo (Ctrl+C para salir)...$(RESET)"
	@docker-compose logs -f --tail=100 web

logs-all: check-docker
	@echo "$(CYAN) Logs de todos los servicios (Ctrl+C para salir)...$(RESET)"
	@docker-compose logs -f --tail=50

status: check-docker
	@echo "$(CYAN) Estado de los servicios:$(RESET)"
	@echo ""
	@docker-compose ps -a
	@echo ""
	@echo "$(CYAN) Uso de volúmenes:$(RESET)"
	@docker system df -v 2>/dev/null | grep -E "$(COMPOSE_PROJECT_NAME)" || echo "   No hay volúmenes del proyecto"

health: check-docker
	@echo "$(CYAN) Estado de salud de los servicios:$(RESET)"
	@echo ""
	@for svc in web db redis; do \
		status=$$(docker inspect --format='{{.State.Health.Status}}' $(COMPOSE_PROJECT_NAME)_$$svc 2>/dev/null || echo "not running"); \
		case $$status in \
			healthy) echo "  $(GREEN) $$svc: $$status$(RESET)" ;; \
			unhealthy) echo "  $(RED) $$svc: $$status$(RESET)" ;; \
			starting) echo "  $(YELLOW)⏳ $$svc: $$status$(RESET)" ;; \
			*) echo "  $(DIM) $$svc: $$status$(RESET)" ;; \
		esac; \
	done

_wait-healthy:
	@echo "$(YELLOW) Esperando a que los servicios estén listos...$(RESET)"
	@timeout=60; \
	while [ $$timeout -gt 0 ]; do \
		db_health=$$(docker inspect --format='{{.State.Health.Status}}' $(DB_CONTAINER_NAME) 2>/dev/null); \
		if [ "$$db_health" = "healthy" ]; then \
			echo "$(GREEN)   ✓ PostgreSQL listo$(RESET)"; \
			break; \
		fi; \
		sleep 2; \
		timeout=$$((timeout - 2)); \
	done

# ==========================================
# 🎯 PERFILES
# ==========================================

dev: check-docker check-env
	@echo "$(GREEN)🔧 Levantando modo DESARROLLO...$(RESET)"
	@docker-compose --profile dev up -d
	@$(MAKE) -s _wait-healthy
	@echo "$(GREEN) Modo desarrollo activo$(RESET)"
	@echo "   $(CYAN)→ Odoo:    http://localhost:$(ODOO_PORT)$(RESET)"
	@echo "   $(CYAN)→ Mailpit: http://localhost:$(MAILPIT_UI_PORT)$(RESET)"

prod: check-docker check-env
	@echo "$(GREEN)🏭 Levantando modo PRODUCCIÓN...$(RESET)"
	@if [ -z "$(TRAEFIK_BASIC_AUTH)" ]; then \
		echo "$(YELLOW)  TRAEFIK_BASIC_AUTH no configurado en .env$(RESET)"; \
		echo "   $(CYAN)Usa: make generate-password$(RESET)"; \
	fi
	@docker-compose --profile prod up -d
	@$(MAKE) -s _wait-healthy
	@echo "$(GREEN) Modo producción activo$(RESET)"
	@echo "   $(CYAN)→ Odoo:    https://$(ODOO_DOMAIN)$(RESET)"
	@echo "   $(CYAN)→ Traefik: http://localhost:$(TRAEFIK_DASHBOARD_PORT)$(RESET)"

tools: check-docker check-env
	@echo "$(GREEN) Levantando herramientas...$(RESET)"
	@docker-compose --profile tools up -d
	@echo "$(GREEN) Herramientas activas$(RESET)"
	@echo "   $(CYAN)→ pgAdmin:         http://localhost:$(PGADMIN_PORT)$(RESET)"
	@echo "   $(CYAN)→ Redis Commander: http://localhost:$(REDIS_COMMANDER_PORT)$(RESET)"
	@echo "   $(CYAN)→ Mailpit:         http://localhost:$(MAILPIT_UI_PORT)$(RESET)"

# ==========================================
#  ACCESO A CONTENEDORES
# ==========================================

shell: check-docker
	@echo "$(CYAN) Accediendo al contenedor de Odoo...$(RESET)"
	@docker-compose exec web bash

psql: check-docker
	@echo "$(CYAN) Conectando a PostgreSQL (BD: $(DB_NAME))...$(RESET)"
	@docker-compose exec db psql -U $(DB_USER) -d $(DB_NAME)

psql-admin: check-docker
	@echo "$(CYAN) Conectando a PostgreSQL (admin)...$(RESET)"
	@docker-compose exec db psql -U $(DB_USER) -d postgres

redis-cli: check-docker
	@echo "$(CYAN) Conectando a Redis...$(RESET)"
	@docker-compose exec redis redis-cli

# ==========================================
#  GESTIÓN DE MÓDULOS
# ==========================================

new: check-docker check-module
	@echo "$(GREEN) Creando módulo '$(m)'...$(RESET)"
	@docker-compose exec web odoo scaffold $(m) /mnt/extra-addons/
	@echo "$(GREEN) Módulo creado en ./addons/$(m)$(RESET)"

install: check-docker check-module
	@echo "$(GREEN) Instalando '$(m)' en $(DB_NAME)...$(RESET)"
	@docker-compose exec web odoo -d $(DB_NAME) -i $(m) --stop-after-init --without-demo=all
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Módulo '$(m)' instalado$(RESET)"

install-multi: check-docker check-module
	@echo "$(GREEN) Instalando módulos: $(m)...$(RESET)"
	@modules=$$(echo "$(m)" | tr ',' ' '); \
	for mod in $$modules; do \
		echo "   $(CYAN)→ Instalando $$mod...$(RESET)"; \
		docker-compose exec web odoo -d $(DB_NAME) -i $$mod --stop-after-init --without-demo=all; \
	done
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Módulos instalados$(RESET)"

update: check-docker check-module
	@echo "$(GREEN) Actualizando '$(m)' en $(DB_NAME)...$(RESET)"
	@docker-compose exec web odoo -d $(DB_NAME) -u $(m) --stop-after-init
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Módulo '$(m)' actualizado$(RESET)"

update-multi: check-docker check-module
	@echo "$(GREEN) Actualizando módulos: $(m)...$(RESET)"
	@modules=$$(echo "$(m)" | tr ',' ' '); \
	for mod in $$modules; do \
		echo "   $(CYAN)→ Actualizando $$mod...$(RESET)"; \
		docker-compose exec web odoo -d $(DB_NAME) -u $$mod --stop-after-init; \
	done
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Módulos actualizados$(RESET)"

uninstall: check-docker check-module
	@echo "$(RED)  Desinstalando '$(m)'...$(RESET)"
	@docker-compose exec web odoo shell -d $(DB_NAME) -c "self.env['ir.module.module'].search([('name','=','$(m)')]).button_immediate_uninstall()"
	@docker-compose restart web
	@echo "$(GREEN) Módulo desinstalado$(RESET)"

test: check-docker check-module
	@echo "$(CYAN) Ejecutando tests de '$(m)'...$(RESET)"
	@docker-compose exec web odoo -d $(DB_NAME) -i $(m) --test-enable --stop-after-init --log-level=test
	@echo "$(GREEN) Tests completados$(RESET)"

# ==========================================
#  GESTIÓN DE BASE DE DATOS
# ==========================================

init: check-docker check-env
	@echo "$(GREEN) Creando BD '$(DB_NAME)' en $(DB_LANG)...$(RESET)"
	@docker-compose stop web 2>/dev/null || true
	@sleep 2
	@docker-compose exec db psql -U $(DB_USER) postgres -c "DROP DATABASE IF EXISTS $(DB_NAME);" 2>/dev/null || true
	@docker-compose exec db psql -U $(DB_USER) postgres -c "CREATE DATABASE $(DB_NAME);"
	@docker-compose up -d web
	@$(MAKE) -s _wait-healthy
	@sleep 5
	@echo "$(YELLOW) Instalando Odoo base...$(RESET)"
	@docker-compose exec web odoo -d $(DB_NAME) -i base --stop-after-init --without-demo=all --load-language=$(DB_LANG)
	@docker-compose restart web
	@sleep 3
	@echo "$(GREEN) Base de datos creada$(RESET)"
	@echo "   $(CYAN) Usuario: admin |  Password: admin$(RESET)"
	@echo "   $(CYAN) http://localhost:$(ODOO_PORT)$(RESET)"

dropdb: check-docker
	@echo "$(RED)$(BOLD)  ADVERTENCIA: Esto borrará TODOS los datos de '$(DB_NAME)'$(RESET)"
	@read -p "¿Continuar? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker-compose stop web 2>/dev/null || true; \
		sleep 2; \
		docker-compose exec db psql -U $(DB_USER) postgres -c "DROP DATABASE IF EXISTS $(DB_NAME);" 2>/dev/null || true; \
		echo "$(GREEN) Base de datos eliminada$(RESET)"; \
		docker-compose up -d web; \
	else \
		echo "$(YELLOW) Operación cancelada$(RESET)"; \
	fi

reset: check-docker check-env
	@echo "$(RED)$(BOLD)  RESET COMPLETO: Se borrarán TODOS los datos$(RESET)"
	@read -p "¿Continuar? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		$(MAKE) -s dropdb; \
		$(MAKE) -s init; \
	else \
		echo "$(YELLOW) Operación cancelada$(RESET)"; \
	fi

# ==========================================
#  BACKUPS Y RESTAURACIÓN
# ==========================================

backup: check-docker
	@mkdir -p $(BACKUP_DIR)
	@echo "$(GREEN)💾 Creando backup comprimido de $(DB_NAME)...$(RESET)"
	@docker-compose exec -T db pg_dump -U $(DB_USER) $(DB_NAME) | gzip > $(BACKUP_DIR)/$(DB_NAME)_$(TIMESTAMP).sql.gz
	@echo "$(GREEN) Backup creado:$(RESET)"
	@ls -lh $(BACKUP_DIR)/$(DB_NAME)_$(TIMESTAMP).sql.gz

backup-full: check-docker
	@mkdir -p $(BACKUP_DIR)
	@echo "$(GREEN)💾 Creando backup completo (BD + filestore)...$(RESET)"
	@docker-compose exec -T db pg_dump -U $(DB_USER) $(DB_NAME) | gzip > $(BACKUP_DIR)/$(DB_NAME)_$(TIMESTAMP).sql.gz
	@docker run --rm -v $(COMPOSE_PROJECT_NAME)_odoo-data:/data -v $$(pwd)/$(BACKUP_DIR):/backup alpine \
		tar czf /backup/$(DB_NAME)_filestore_$(TIMESTAMP).tar.gz -C /data .
	@echo "$(GREEN) Backup completo creado:$(RESET)"
	@ls -lh $(BACKUP_DIR)/$(DB_NAME)_$(TIMESTAMP).sql.gz
	@ls -lh $(BACKUP_DIR)/$(DB_NAME)_filestore_$(TIMESTAMP).tar.gz

restore: check-docker
	@if [ -z "$(f)" ]; then \
		echo "$(RED) Error: Especifica el archivo$(RESET)"; \
		echo "   Uso: $(YELLOW)make restore f=nombre_backup.sql.gz$(RESET)"; \
		echo ""; \
		$(MAKE) -s list-backups; \
		exit 1; \
	fi
	@if [ ! -f "$(BACKUP_DIR)/$(f)" ]; then \
		echo "$(RED) Error: Archivo no encontrado: $(BACKUP_DIR)/$(f)$(RESET)"; \
		$(MAKE) -s list-backups; \
		exit 1; \
	fi
	@echo "$(YELLOW)  Esto sobrescribirá la BD '$(DB_NAME)'$(RESET)"
	@read -p "¿Restaurar desde $(f)? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		echo "$(YELLOW) Restaurando...$(RESET)"; \
		docker-compose stop web; \
		sleep 2; \
		docker-compose exec db psql -U $(DB_USER) postgres -c "DROP DATABASE IF EXISTS $(DB_NAME);" 2>/dev/null || true; \
		docker-compose exec db psql -U $(DB_USER) postgres -c "CREATE DATABASE $(DB_NAME);"; \
		if echo "$(f)" | grep -q "\.gz$$"; then \
			gunzip -c $(BACKUP_DIR)/$(f) | docker-compose exec -T db psql -U $(DB_USER) $(DB_NAME); \
		else \
			cat $(BACKUP_DIR)/$(f) | docker-compose exec -T db psql -U $(DB_USER) $(DB_NAME); \
		fi; \
		docker-compose up -d web; \
		sleep 5; \
		echo "$(GREEN) BD restaurada correctamente$(RESET)"; \
	else \
		echo "$(YELLOW) Restauración cancelada$(RESET)"; \
	fi

list-backups:
	@echo "$(CYAN) Backups disponibles:$(RESET)"
	@if [ -d "$(BACKUP_DIR)" ] && [ -n "$$(ls -A $(BACKUP_DIR)/*.sql* 2>/dev/null)" ]; then \
		ls -lht $(BACKUP_DIR)/*.sql* 2>/dev/null | awk '{print "   " $$9 " (" $$5 ")"}'; \
	else \
		echo "   $(YELLOW)No hay backups disponibles$(RESET)"; \
		echo "   $(CYAN)Usa: make backup$(RESET)"; \
	fi

# ==========================================
#  MANTENIMIENTO
# ==========================================

clean-logs: check-docker
	@echo "$(YELLOW) Limpiando logs de Docker...$(RESET)"
	@for container in $$(docker-compose ps -q); do \
		LOG_PATH=$$(docker inspect --format='{{.LogPath}}' $$container 2>/dev/null); \
		if [ -n "$$LOG_PATH" ] && [ -f "$$LOG_PATH" ]; then \
			sudo truncate -s 0 "$$LOG_PATH" 2>/dev/null || truncate -s 0 "$$LOG_PATH"; \
		fi; \
	done
	@echo "$(GREEN) Logs limpiados$(RESET)"

prune:
	@echo "$(YELLOW)  Limpiando recursos Docker no utilizados...$(RESET)"
	@read -p "¿Continuar? [y/N]: " confirm; \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		docker system prune -f; \
		docker volume prune -f; \
		echo "$(GREEN) Limpieza completada$(RESET)"; \
	else \
		echo "$(YELLOW) Operación cancelada$(RESET)"; \
	fi

# ==========================================
#  UTILIDADES DE DESARROLLO
# ==========================================

watch: check-docker
	@echo "$(CYAN) Modo watch: logs + auto-reload$(RESET)"
	@echo "   $(DIM)Ctrl+C para salir$(RESET)"
	@docker-compose logs -f --tail=50 web

odoo-shell: check-docker
	@echo "$(CYAN) Abriendo Odoo shell...$(RESET)"
	@docker-compose exec web odoo shell -d $(DB_NAME)

db-size: check-docker
	@echo "$(CYAN) Tamaño de la base de datos:$(RESET)"
	@docker-compose exec db psql -U $(DB_USER) -d $(DB_NAME) -c "\
		SELECT pg_size_pretty(pg_database_size('$(DB_NAME)')) as total_size;"
	@echo ""
	@echo "$(CYAN) Tablas más grandes:$(RESET)"
	@docker-compose exec db psql -U $(DB_USER) -d $(DB_NAME) -c "\
		SELECT schemaname || '.' || relname as table, \
		       pg_size_pretty(pg_total_relation_size(relid)) as size \
		FROM pg_catalog.pg_statio_user_tables \
		ORDER BY pg_total_relation_size(relid) DESC \
		LIMIT 10;"
