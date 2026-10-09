# Arranque fácil de NAP Entity Auditor Pro (Windows) — modo gratuito
Set-Location $PSScriptRoot
Write-Host "=== NAP Entity Auditor Pro ==="
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
  Write-Host "No encuentro Docker. Instala Docker Desktop desde https://www.docker.com/products/docker-desktop/ y vuelve a ejecutar este archivo."
  Read-Host "Pulsa Intro para salir"; exit 1
}
docker info *> $null
if ($LASTEXITCODE -ne 0) {
  Write-Host "Docker está instalado pero no está abierto. Abre Docker Desktop, espera a que esté en marcha y vuelve a ejecutar este archivo."
  Read-Host "Pulsa Intro para salir"; exit 1
}
function Rand { -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 48 | ForEach-Object { [char]$_ }) }
if (-not (Test-Path .env)) {
  Write-Host "Primera vez: vamos a crear tu usuario de acceso."
  $email = Read-Host "Tu correo (será tu usuario)"
  do {
    $sec = Read-Host "Elige una contraseña (mínimo 10 caracteres)" -AsSecureString
    $pass = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($sec))
    $bad = $pass -match '[\s''"#\\$]'
    if ($bad) { Write-Host "Sin espacios, comillas, #, $ ni \, por favor." }
    elseif ($pass.Length -lt 10) { Write-Host "Demasiado corta, prueba otra." }
  } while ($bad -or $pass.Length -lt 10)
  $content = @(Get-Content .env.free.example | Where-Object { $_ -notmatch '^(SECRET_KEY|SEARXNG_SECRET|ADMIN_EMAIL|ADMIN_PASSWORD)=' })
  $content += "SECRET_KEY=" + (Rand)
  $content += "SEARXNG_SECRET=" + (Rand)
  $content += "ADMIN_EMAIL=" + $email
  $content += "ADMIN_PASSWORD=" + $pass
  [IO.File]::WriteAllLines((Join-Path $PSScriptRoot ".env"), [string[]]$content, (New-Object System.Text.UTF8Encoding $false))
  Write-Host "Configuración guardada en el archivo .env"
}
Write-Host "Arrancando (la primera vez tarda varios minutos)..."
docker compose -f docker-compose.free.yml up -d --build
if ($LASTEXITCODE -ne 0) { Read-Host "Algo ha fallado. Pulsa Intro para salir"; exit 1 }
Write-Host "Esperando a que la aplicación responda..."
for ($i = 0; $i -lt 90; $i++) {
  try {
    Invoke-WebRequest -UseBasicParsing http://localhost:3000/api/health -TimeoutSec 3 | Out-Null
    Write-Host "¡Lista! Abriendo http://localhost:3000"
    Start-Process "http://localhost:3000"
    Write-Host "Para pararla: docker compose -f docker-compose.free.yml down"
    Read-Host "Pulsa Intro para cerrar esta ventana"; exit 0
  } catch { Start-Sleep -Seconds 2 }
}
Write-Host "Tarda más de lo normal. Prueba a abrir http://localhost:3000 dentro de un minuto."
Read-Host "Pulsa Intro para cerrar"
