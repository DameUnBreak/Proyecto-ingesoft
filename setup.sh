#!/usr/bin/env bash
set -euo pipefail

echo "=== SmartCar Backend • Setup inicial ==="

# -------- 0) Utilidades / helpers --------
# Detectar python
if command -v python3 >/dev/null 2>&1; then PY=python3; else PY=python; fi

# Función para esperar un puerto
wait_for_port () {
  local host="$1" port="$2" retries="${3:-30}"
  for i in $(seq 1 "$retries"); do
    if (echo > /dev/tcp/"$host"/"$port") >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  return 1
}

# -------- 1) Levantar repo / variables --------
# Si existe .env.example y no existe .env, lo copiamos
if [ -f ".env.example" ] && [ ! -f ".env" ]; then
  cp .env.example .env
  echo "[INFO] .env creado desde .env.example (ajusta credenciales)."
fi

# -------- 2) Crear venv e instalar dependencias --------
if [ ! -d ".venv" ]; then
  echo "[INFO] Creando entorno virtual (.venv)..."
  $PY -m venv .venv
fi

# shellcheck disable=SC1091
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
elif [ -f ".venv/Scripts/activate" ]; then
    source .venv/Scripts/activate
else
    echo "[ERROR] No se encontró el entorno virtual (.venv)."
    exit 1
fi

python -m pip install --upgrade pip
if [ -f "requirements.txt" ]; then
  echo "[INFO] Instalando dependencias de requirements.txt..."
  pip install -r requirements.txt
else
  echo "[WARN] No hay requirements.txt; omitiendo instalación."
fi

# -------- 3) Chequeo rápido de conexión a MySQL (opcional pero útil) --------
# Requiere que uses variables en .env (ver ejemplo abajo).
echo "[INFO] Probando conexión a MySQL (si configuraste .env)..."
python - <<'PY'
import os, sys
host=os.getenv("DB_HOST")
user=os.getenv("DB_USER")
pwd=os.getenv("DB_PASSWORD")
db=os.getenv("DB_NAME")
port=int(os.getenv("DB_PORT", "3306"))
if not all([host,user,pwd,db]):
    print("[INFO] Variables DB_* no definidas; salto chequeo de MySQL.")
    sys.exit(0)
try:
    import pymysql  # suele venir en proyectos con SQLAlchemy+MySQL
    conn=pymysql.connect(host=host,user=user,password=pwd,db=db,port=port,connect_timeout=3)
    conn.close()
    print("[OK] Conexión MySQL exitosa.")
except Exception as e:
    print("[WARN] No se pudo conectar a MySQL:", e)
    # No abortamos para permitir desarrollo sin BD en local
PY

# -------- 4) Pruebas básicas (smoke test) --------
# Levantamos el server en background, probamos /hola_mundo y lo cerramos.
echo "[INFO] Iniciando FastAPI temporalmente para smoke test..."
UVICORN_BIN="$(python -c 'import sys,shutil; print(shutil.which("uvicorn") or "")')"
if [ -z "$UVICORN_BIN" ]; then
  echo "[ERROR] uvicorn no está instalado en el entorno. Revisa requirements.txt."
  exit 1
fi

# Puerto configurable vía env; por defecto 8000
PORT="${PORT:-8000}"
HOST="${HOST:-127.0.0.1}"

# Arrancar en background
$UVICORN_BIN main:app --host "$HOST" --port "$PORT" >/tmp/uvicorn.log 2>&1 &
UV_PID=$!

# Esperar a que abra el puerto
if ! wait_for_port "$HOST" "$PORT" 30; then
  echo "[ERROR] El servidor no abrió el puerto $PORT. Logs:"
  tail -n +1 /tmp/uvicorn.log || true
  kill "$UV_PID" >/dev/null 2>&1 || true
  exit 1
fi

# Smoke test del endpoint
echo "[INFO] Probando GET http://$HOST:$PORT/hola_mundo ..."
SMOKE_RESP="$(curl -s -m 5 "http://$HOST:$PORT/hola_mundo" || true)"
echo "Respuesta: $SMOKE_RESP"

# Apagar el server temporal
kill "$UV_PID" >/dev/null 2>&1 || true

echo "=== Setup completado. ==="
echo "Para desarrollar: "
echo "  source .venv/bin/activate      # (en Windows: .venv\\Scripts\\activate)"
echo "  uvicorn main:app --reload"
