# scripts/tablero-comun.ps1
# Funciones compartidas para scripts del tablero Scrumban y métricas

function Leer-ConfigTablero {
    param(
        [string]$RutaConfig,
        [switch]$ModoComprobar
    )

    $ruta = $RutaConfig
    if (-not $ruta) {
        if (-not $env:OBSIDIAN_VAULT) {
            if ($ModoComprobar) {
                return @{ NoConfigurado = $true; Salir = $true; Mensaje = $null; Codigo = 0 }
            }
            return @{ NoConfigurado = $true; Salir = $true; Mensaje = "Tablero no configurado (OBSIDIAN_VAULT no definida)"; Codigo = 0 }
        }
        $ruta = Join-Path $env:OBSIDIAN_VAULT "tablero.md"
    }

    if (-not (Test-Path -LiteralPath $ruta)) {
        if ($ModoComprobar) {
            return @{ NoConfigurado = $true; Salir = $true; Mensaje = $null; Codigo = 0 }
        }
        return @{ NoConfigurado = $true; Salir = $true; Mensaje = "Tablero no configurado (falta tablero.md en el vault)"; Codigo = 0 }
    }

    $lineas = Get-Content -LiteralPath $ruta -Encoding UTF8
    $enBloque = $false
    $valores = @{}

    foreach ($linea in $lineas) {
        $l = $linea.Trim()
        if ($l -eq '---') {
            if (-not $enBloque) {
                $enBloque = $true
                continue
            } else {
                break
            }
        }
        if ($enBloque) {
            if ($l -match '^([a-zA-Z0-9_-]+)\s*:\s*(.*)$') {
                $k = $matches[1].Trim().ToLowerInvariant()
                $v = $matches[2].Trim()
                $valores[$k] = $v
            }
        }
    }

    # Validaciones de claves
    if (-not $valores.ContainsKey('owner') -or [string]::IsNullOrWhiteSpace($valores['owner'])) {
        return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: owner"; Codigo = 0 }
    }

    if (-not $valores.ContainsKey('numero') -or $valores['numero'] -notmatch '^[1-9][0-9]*$') {
        return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: numero"; Codigo = 0 }
    }

    $clavesWip = @('wip-diseno', 'wip-construccion', 'wip-revision')
    foreach ($w in $clavesWip) {
        if ($valores.ContainsKey($w)) {
            $val = $valores[$w]
            if ($val -notmatch '^[1-9][0-9]*$') {
                return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: $w"; Codigo = 0 }
            }
        }
    }

    $cfg = @{
        owner            = $valores['owner']
        numero           = [int]$valores['numero']
        'wip-diseno'     = if ($valores.ContainsKey('wip-diseno')) { [int]$valores['wip-diseno'] } else { $null }
        'wip-construccion'= if ($valores.ContainsKey('wip-construccion')) { [int]$valores['wip-construccion'] } else { $null }
        'wip-revision'   = if ($valores.ContainsKey('wip-revision')) { [int]$valores['wip-revision'] } else { $null }
    }

    return @{ Config = $cfg; Salir = $false }
}

function Formatear-ErrorGh {
    param([string]$ErrorTexto)

    $limpio = $ErrorTexto -replace '(?i)[a-z]:\\[^:\s]+', '' -replace '/[^\s:]+/[^\s:]+', ''
    $lineas = @(($limpio -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $primeraLinea = if ($lineas.Count -gt 0) { $lineas[0] } else { "error al ejecutar gh" }

    $sugerencia = ""
    if ($ErrorTexto -match '(?i)(scope|project)') {
        $sugerencia = " — corré gh auth refresh -s project"
    }

    return "Tablero no disponible: $primeraLinea$sugerencia"
}

function Invocar-Gh {
    param(
        [string[]]$Argumentos
    )

    $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
    if (-not $ghCmd) {
        return @{ Error = "gh no está instalado o no se encuentra en PATH"; Salir = $true }
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $ghCmd.Source
    foreach ($arg in $Argumentos) {
        $psi.ArgumentList.Add($arg)
    }
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    if ($proc.ExitCode -ne 0) {
        $err = if ($stderr) { $stderr } else { $stdout }
        return @{ Error = $err; Salir = $true }
    }

    try {
        $json = $stdout | ConvertFrom-Json
        return @{ Datos = $json; Salir = $false }
    } catch {
        return @{ Raw = $stdout; Salir = $false }
    }
}
