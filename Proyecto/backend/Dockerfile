# Dockerfile - Backend Django SmartCar
FROM python:3.10-slim

# Evitar preguntas en apt y mejorar logs
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Dependencias del sistema (ajusta si luego necesitas más)
RUN apt-get update && apt-get install -y \
    build-essential \
    curl \
    gnupg2 \
    unixodbc \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Directorio de la app
WORKDIR /app

# Copiar requirements primero
COPY requirements.txt /app/

# Instalar dependencias de Python
RUN pip install --no-cache-dir -r requirements.txt

# Copiar el resto del código
COPY . /app

# Exponemos el puerto interno de Django
EXPOSE 8000

# 🔹 IMPORTANTE: no seteamos DJANGO_SETTINGS_MODULE aquí
# Django usará lo que diga manage.py

# Comando por defecto
CMD ["python", "manage.py", "runserver", "0.0.0.0:8000"]
