#!/usr/bin/env bash
# Arranque fácil de NAP Entity Auditor Pro (Mac y Linux) — modo gratuito
set -e
cd "$(dirname "$0")"

echo "=== NAP Entity Auditor Pro ==="
if ! command -v docker >/dev/null 2>&1; then
  echo "No encuentro Docker. Instala Docker Desktop desde https://www.docker.com/products/docker-desktop/ y vuelve a ejecutar este archivo."
  read -r -p "Pulsa Intro para salir" _; exit 1
fi
if ! docker info >/dev/null 2>&1; then
  echo "Docker está instalado pero no está abierto. Abre Docker Desktop, espera a que diga que está en marcha y vuelve a ejecutar este archivo."
  read -r -p "Pulsa Intro para salir" _; exit 1
fi

if [ ! -f .env ]; then
  echo "Primera vez: vamos a crear tu usuario de acceso."
  read -r -p "Tu correo (será tu usuario): " EMAIL
  while true; do
    read -r -s -p "Elige una contraseña (mínimo 10 caracteres): " PASS; echo
    case "$PASS" in *[[:space:]\'\"\#\\\$]*) echo "Sin espacios, comillas, #, \$ ni \\, por favor."; continue;; esac
    [ "${#PASS}" -ge 10 ] && break
    echo "Demasiado corta, prueba otra."
  done
  rand() { LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 48; }
  grep -vE '^(SECRET_KEY|SEARXNG_SECRET|ADMIN_EMAIL|ADMIN_PASSWORD)=' .env.free.example > .env
  {
    echo "SECRET_KEY=$(rand)"
    echo "SEARXNG_SECRET=$(rand)"
    echo "ADMIN_EMAIL=${EMAIL}"
    echo "ADMIN_PASSWORD=${PASS}"
  } >> .env
  echo "Configuración guardada en el archivo .env"
fi

echo "Arrancando (la primera vez tarda varios minutos)..."
docker compose -f docker-compose.free.yml up -d --build

echo "Esperando a que la aplicación responda..."
for _ in $(seq 1 90); do
  if curl -fs http://localhost:3000/api/health >/dev/null 2>&1; then
    echo "¡Lista! Abriendo http://localhost:3000"
    (open http://localhost:3000 2>/dev/null || xdg-open http://localhost:3000 2>/dev/null) || true
    echo "Para pararla: docker compose -f docker-compose.free.yml down"
    exit 0
  fi
  sleep 2
done
echo "Tarda más de lo normal. Prueba a abrir http://localhost:3000 dentro de un minuto."
