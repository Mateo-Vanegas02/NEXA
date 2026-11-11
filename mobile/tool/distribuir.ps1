<#
  Compila el APK release firmado y lo sube a Firebase App Distribution.

  Requisitos (una sola vez, ver docs/DISTRIBUCION.md):
    - android/key.properties + keystore (firma release)
    - Firebase CLI:  npm install -g firebase-tools   y   firebase login
    - Variable de entorno FIREBASE_APP_ID (ID de la app Android en Firebase,
      p. ej. 1:1234567890:android:abc123). No se guarda en el repositorio.

  Uso:
    .\tool\distribuir.ps1 -Notas "Popup de bienvenida" -Grupos "testers"
    .\tool\distribuir.ps1 -UsarMocks $true      # versión de demostración, sin backend
    .\tool\distribuir.ps1 -SoloCompilar        # genera el APK sin subirlo
#>
param(
  [string]$Notas = 'Nueva versión de NEXA',
  [string]$Grupos = 'testers',
  [string]$Testers = '',
  [bool]$UsarMocks = $false,
  [string]$ApiBaseUrl = 'https://18-227-59-40.sslip.io',   # web de NEXA en AWS (ver lib/core/config/env.dart)
  [switch]$SoloCompilar,
  [switch]$SinSubirVersion
)

$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
if (-not $env:ANDROID_HOME) { $env:ANDROID_HOME = 'C:\Android\sdk' }

if (-not (Test-Path 'android\key.properties')) {
  throw 'Falta android\key.properties: sin él el APK se firmaría con la clave debug y no se podría actualizar. Ver docs/DISTRIBUCION.md'
}

# Firebase solo instala una actualización si el número de compilación (+N) sube.
if (-not $SinSubirVersion) {
  $pub = Get-Content pubspec.yaml -Raw
  if ($pub -match '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$') {
    $nueva = "$($Matches[1])+$([int]$Matches[2] + 1)"
    $pub = $pub -replace '(?m)^version:\s*.+$', "version: $nueva"
    Set-Content pubspec.yaml $pub -NoNewline
    Write-Host "Versión -> $nueva"
  } else {
    throw 'No se pudo leer la versión de pubspec.yaml (formato esperado: 1.0.0+1)'
  }
}

flutter build apk --release `
  --dart-define=USE_MOCKS=$($UsarMocks.ToString().ToLower()) `
  --dart-define=API_BASE_URL=$ApiBaseUrl
if ($LASTEXITCODE -ne 0) { throw 'Falló flutter build apk --release' }

$apk = 'build\app\outputs\flutter-apk\app-release.apk'
Write-Host "APK listo: $apk"
if ($SoloCompilar) { return }

if (-not $env:FIREBASE_APP_ID) { throw 'Define FIREBASE_APP_ID (ID de la app Android en Firebase)' }
# Con -Testers (correos separados por coma) se invita directamente; si no, al grupo.
$destino = if ($Testers) { @('--testers', $Testers) } else { @('--groups', $Grupos) }
firebase appdistribution:distribute $apk `
  --app $env:FIREBASE_APP_ID `
  @destino `
  --release-notes $Notas
