# tests/apoyo.ps1
# Funciones de aserción y ejecución de tests sin dependencias externas

$script:HayFallas = $false

function Afirmar {
    param(
        [bool]$Condicion,
        [string]$Mensaje = "Afirmación fallida"
    )
    if (-not $Condicion) {
        throw $Mensaje
    }
}

function Probar {
    param(
        [string]$Nombre,
        [scriptblock]$Bloque
    )
    try {
        & $Bloque
        Write-Host "OK $Nombre"
    } catch {
        $msg = $_.Exception.Message
        Write-Host "FALLA ${Nombre}: $msg"
        $script:HayFallas = $true
    }
}

function Con-CarpetaTemporal {
    param(
        [scriptblock]$Accion
    )
    $dir = Join-Path ([System.IO.Path]::GetTempPath()) ("sdd-test-" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    try {
        & $Accion $dir
    } finally {
        if (Test-Path $dir) {
            Remove-Item -Recurse -Force $dir -ErrorAction SilentlyContinue
        }
    }
}
