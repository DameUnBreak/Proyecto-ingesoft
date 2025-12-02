# Script para correr el proyecto SmartCar (Backend Django + Frontend Flutter)
# Autor: Antigravity

Write-Host "=== Iniciando Setup de SmartCar ===" -ForegroundColor Cyan

# 1. Verificar Python
try {
    $pythonVersion = python --version 2>&1
    Write-Host "Python detectado: $pythonVersion" -ForegroundColor Green
} catch {
    Write-Error "Python no encontrado. Por favor instala Python 3.x y agrégalo al PATH."
    exit 1
}

# 2. Configurar Backend
$backendPath = Join-Path $PSScriptRoot "Proyecto\backend"
if (-not (Test-Path $backendPath)) {
    Write-Error "No se encontró la carpeta del backend en: $backendPath"
    exit 1
}

Push-Location $backendPath
Write-Host "`n--- Configurando Backend (Django) ---" -ForegroundColor Yellow

# Crear entorno virtual si no existe
if (-not (Test-Path ".venv")) {
    Write-Host "Creando entorno virtual..."
    python -m venv .venv
}

# Activar entorno virtual
$venvActivate = ".\.venv\Scripts\Activate.ps1"
if (Test-Path $venvActivate) {
    # Intentar activar, si falla por políticas de ejecución, usar python directo del venv
    Write-Host "Usando entorno virtual..."
} else {
    Write-Warning "No se encontró script de activación. Intentando continuar..."
}

# Definir ruta al python del venv
$venvPython = ".\.venv\Scripts\python.exe"
if (-not (Test-Path $venvPython)) {
    $venvPython = "python" # Fallback
}

# Instalar dependencias
if (Test-Path "requirements.txt") {
    Write-Host "Instalando dependencias..."
    & $venvPython -m pip install -r requirements.txt | Out-Null
}

# Migraciones
Write-Host "Aplicando migraciones..."
& $venvPython manage.py migrate | Out-Null

# Iniciar Servidor en un proceso separado
Write-Host "Iniciando servidor Django en puerto 8000..." -ForegroundColor Green
Start-Process -FilePath $venvPython -ArgumentList "manage.py runserver 0.0.0.0:8000" -WindowStyle Normal

Pop-Location

# 3. Configurar Frontend
$frontendPath = Join-Path $PSScriptRoot "Proyecto\frontend"
if (-not (Test-Path $frontendPath)) {
    Write-Warning "No se encontró la carpeta del frontend en: $frontendPath"
    exit
}

Push-Location $frontendPath
Write-Host "`n--- Configurando Frontend (Flutter) ---" -ForegroundColor Yellow

# Verificar Flutter
try {
    $flutterVersion = flutter --version 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Flutter detectado." -ForegroundColor Green
        
        Write-Host "Instalando dependencias de Flutter..."
        flutter pub get | Out-Null

        Write-Host "Iniciando aplicación Flutter..." -ForegroundColor Green
        # Ejecutar flutter run. Esto bloqueará la terminal actual, lo cual está bien.
        # O podemos abrirlo en otra ventana si el usuario quiere seguir usando esta.
        # Vamos a abrirlo en esta para ver logs.
        flutter run
    } else {
        Write-Warning "El comando 'flutter' no devolvió éxito. Asegúrate de tener Flutter instalado y en el PATH."
    }
} catch {
    Write-Warning "Flutter no encontrado. El backend está corriendo, pero necesitas instalar Flutter para correr la app móvil/desktop."
    Write-Warning "Visita: https://docs.flutter.dev/get-started/install/windows"
}

Pop-Location

Write-Host "`n=== Script finalizado ===" -ForegroundColor Cyan
