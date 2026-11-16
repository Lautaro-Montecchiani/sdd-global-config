# scripts/tablero.ps1
# Movimiento de tarjetas y control de WIP en GitHub Project de usuario (Scrumban)

[CmdletBinding()]
param(
    [string]$Columna,
    [string]$Issue,
    [switch]$Wip,
    [switch]$Comprobar,
    [switch]$Simular,
    [string]$Config,
    [string]$Entrada
)

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

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

function Resolver-Columna {
    param([string]$Alias)

    if (-not $Alias) { return $null }
    $mapa = @{
        'backlog'      = 'Backlog'
        'listo'        = 'Listo'
        'diseno'       = 'Diseño'
        'construccion' = 'Construcción'
        'revision'     = 'Revisión'
        'hecho'        = 'Hecho'
    }

    $clave = $Alias.Trim().ToLowerInvariant()
    if ($mapa.ContainsKey($clave)) {
        return $mapa[$clave]
    }
    return $null
}

function Formatear-ErrorGh {
    param([string]$ErrorTexto)

    $limpio = $ErrorTexto -replace '(?i)[a-z]:\\[^:\s]+', '' -replace '/[^\s:]+/[^\s:]+', ''
    $lineas = ($limpio -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ }
    $primeraLinea = if ($lineas.Count -gt 0) { $lineas[0] } else { "error al ejecutar gh" }

    $sugerencia = ""
    if ($ErrorTexto -match '(?i)(scope|project)') {
        $sugerencia = " — corré gh auth refresh -s project"
    }

    return "Tablero no disponible: $primeraLinea$sugerencia"
}

function Leer-PermisosGh {
    param([string]$TextoAuthStatus)

    if (-not $TextoAuthStatus) { return @() }
    $lineas = $TextoAuthStatus -split "`r?`n"
    foreach ($linea in $lineas) {
        if ($linea -match '(?i)Token scopes:\s*(.*)$') {
            $raw = $matches[1]
            $scopes = [regex]::Matches($raw, "'([^']+)'") | ForEach-Object { $_.Groups[1].Value.Trim() }
            if ($scopes.Count -eq 0) {
                $scopes = $raw -split ',\s*' | ForEach-Object { $_.Trim().Trim("'").Trim('"') } | Where-Object { $_ }
            }
            return @($scopes)
        }
    }
    return $null
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

function Buscar-Opcion {
    param(
        $Campos,
        [string]$NombreOpcion
    )

    $fieldList = $null
    if ($Campos.fields) {
        $fieldList = $Campos.fields
    } elseif ($Campos -is [System.Collections.IEnumerable]) {
        $fieldList = $Campos
    }

    if (-not $fieldList) {
        return $null
    }

    $statusField = $fieldList | Where-Object { $_.name -eq 'Status' } | Select-Object -First 1
    if (-not $statusField) {
        return $null
    }

    $opcion = $statusField.options | Where-Object { $_.name -eq $NombreOpcion } | Select-Object -First 1
    if (-not $opcion) {
        return $null
    }

    return @{
        FieldId  = $statusField.id
        OptionId = $opcion.id
    }
}

function Contar-Columna {
    param(
        $Tarjetas,
        [string]$NombreOpcion
    )

    $items = @()
    if ($Tarjetas.items) {
        $items = @($Tarjetas.items)
    } elseif ($Tarjetas -is [System.Collections.IEnumerable]) {
        $items = @($Tarjetas)
    }

    $coincidentes = @()
    foreach ($item in $items) {
        if ($item.status -and $item.status -eq $NombreOpcion) {
            $coincidentes += $item
        }
    }

    return @{
        Cuenta  = $coincidentes.Count
        Tarjetas = $coincidentes
    }
}

# Si fue importado por dot-sourcing, no ejecutar lógica de invocación
if ($MyInvocation.InvocationName -eq '.') {
    return
}

# --- LÓGICA PRINCIPAL ---

# Validar parámetros obligatorios y exclusiones
if ($Comprobar) {
    if ($Issue -or $Wip) {
        Write-Host "Error: -Comprobar no se puede combinar con -Issue ni -Wip"
        exit 1
    }
} else {
    if (-not $Columna) {
        Write-Host "Error: -Columna es obligatorio"
        exit 1
    }
    if ((-not $Issue -and -not $Wip) -or ($Issue -and $Wip)) {
        Write-Host "Error: se debe especificar exactamente uno de -Issue o -Wip"
        exit 1
    }
}

# Leer tablero.md
$resConfig = Leer-ConfigTablero -RutaConfig $Config -ModoComprobar:$Comprobar
if ($resConfig.Salir) {
    if ($resConfig.Mensaje) {
        Write-Host $resConfig.Mensaje
    }
    exit $resConfig.Codigo
}
$cfg = $resConfig.Config

# Cargar -Entrada si existe
$datosEntrada = $null
if ($Entrada) {
    if (Test-Path -LiteralPath $Entrada) {
        $datosEntrada = Get-Content -LiteralPath $Entrada -Raw -Encoding UTF8 | ConvertFrom-Json
    }
}

# Modo -Comprobar (D7b)
if ($Comprobar) {
    $textoAuth = $null
    if ($datosEntrada -and $datosEntrada.estadoGh) {
        $textoAuth = $datosEntrada.estadoGh
    } else {
        $ghCmd = Get-Command gh -ErrorAction SilentlyContinue
        if ($ghCmd) {
            $psi = [System.Diagnostics.ProcessStartInfo]::new()
            $psi.FileName = $ghCmd.Source
            $psi.ArgumentList.Add("auth")
            $psi.ArgumentList.Add("status")
            $psi.RedirectStandardOutput = $true
            $psi.RedirectStandardError = $true
            $psi.UseShellExecute = $false
            $proc = [System.Diagnostics.Process]::Start($psi)
            $stdout = $proc.StandardOutput.ReadToEnd()
            $stderr = $proc.StandardError.ReadToEnd()
            $proc.WaitForExit()
            $textoAuth = "$stdout`n$stderr"
        }
    }

    if (-not $textoAuth) {
        Write-Host "No se pudo leer el permiso de gh"
        exit 0
    }

    $permisos = Leer-PermisosGh -TextoAuthStatus $textoAuth
    if ($null -eq $permisos) {
        Write-Host "No se pudo leer el permiso de gh"
        exit 0
    }

    if ($permisos -contains 'project') {
        exit 0
    } else {
        Write-Host "Falta el permiso project en gh de esta máquina: corré ! gh auth refresh -h github.com -s project"
        exit 1
    }
}

# Resolver columna
$nombreOpcion = Resolver-Columna -Alias $Columna
if (-not $nombreOpcion) {
    Write-Host "Columna desconocida: $Columna. Válidas: backlog, listo, diseno, construccion, revision, hecho"
    exit 1
}

# Modo -Wip
if ($Wip) {
    $tarjetasData = $null
    if ($datosEntrada -and $datosEntrada.tarjetas) {
        $tarjetasData = $datosEntrada.tarjetas
    } else {
        $argsItem = @('project', 'item-list', "$($cfg.numero)", '--owner', "$($cfg.owner)", '--format', 'json', '--limit', '500')
        $resGh = Invocar-Gh -Argumentos $argsItem
        if ($resGh.Salir) {
            Write-Host (Formatear-ErrorGh $resGh.Error)
            exit 0
        }
        $tarjetasData = $resGh.Datos
    }

    $cuentaInfo = Contar-Columna -Tarjetas $tarjetasData -NombreOpcion $nombreOpcion
    $cuenta = $cuentaInfo.Cuenta

    $aliasNorm = $Columna.Trim().ToLowerInvariant()
    $claveWip = "wip-$aliasNorm"
    $limite = if ($cfg.ContainsKey($claveWip)) { $cfg[$claveWip] } else { $null }

    if ($null -eq $limite) {
        Write-Host "${nombreOpcion}: $cuenta (sin límite)"
        exit 0
    }

    Write-Host "${nombreOpcion}: $cuenta de $limite"
    if ($cuenta -ge $limite) {
        foreach ($t in $cuentaInfo.Tarjetas) {
            $num = $null
            $tit = $null
            if ($t.content) {
                if ($t.content.number) { $num = $t.content.number }
                if ($t.content.title) { $tit = $t.content.title }
            }
            if ($num -and $tit) {
                Write-Host "  #$num $tit"
            } elseif ($num) {
                Write-Host "  #$num"
            } elseif ($tit) {
                Write-Host "  $tit"
            }
        }
        exit 2
    }
    exit 0
}

# Modo -Issue (Mover)
if ($Issue) {
    # 1. Project View
    $proyectoId = $null
    if ($datosEntrada -and $datosEntrada.proyecto) {
        $proyectoId = $datosEntrada.proyecto.id
    } else {
        $argsView = @('project', 'view', "$($cfg.numero)", '--owner', "$($cfg.owner)", '--format', 'json')
        $resView = Invocar-Gh -Argumentos $argsView
        if ($resView.Salir) {
            Write-Host (Formatear-ErrorGh $resView.Error)
            exit 0
        }
        $proyectoId = $resView.Datos.id
    }

    # 2. Field List
    $camposData = $null
    if ($datosEntrada -and $datosEntrada.campos) {
        $camposData = $datosEntrada.campos
    } else {
        $argsFields = @('project', 'field-list', "$($cfg.numero)", '--owner', "$($cfg.owner)", '--format', 'json')
        $resFields = Invocar-Gh -Argumentos $argsFields
        if ($resFields.Salir) {
            Write-Host (Formatear-ErrorGh $resFields.Error)
            exit 0
        }
        $camposData = $resFields.Datos
    }

    $opcionInfo = Buscar-Opcion -Campos $camposData -NombreOpcion $nombreOpcion
    if (-not $opcionInfo) {
        Write-Host "el tablero no tiene la columna $nombreOpcion"
        exit 0
    }

    $fieldId = $opcionInfo.FieldId
    $optionId = $opcionInfo.OptionId

    # 3. Item Add o recuperar id de tarjeta
    $tarjetaId = $null
    $yaExiste = $false
    $issueNum = $null
    if ($Issue -match '/issues/(\d+)') {
        $issueNum = $matches[1]
    }

    if ($datosEntrada -and $datosEntrada.tarjetas -and $datosEntrada.tarjetas.items) {
        $existente = $datosEntrada.tarjetas.items | Where-Object {
            ($_.content -and $_.content.url -and $_.content.url -eq $Issue) -or
            ($issueNum -and $_.content -and $_.content.number -and $_.content.number -eq [int]$issueNum)
        } | Select-Object -First 1
        if ($existente) {
            $tarjetaId = $existente.id
            $yaExiste = $true
        }
    }

    if (-not $tarjetaId) {
        if ($Simular -or $datosEntrada) {
            Write-Host "gh project item-add $($cfg.numero) --owner $($cfg.owner) --url $Issue"
            $tarjetaId = "PVTI_nuevo"
        } else {
            $argsAdd = @('project', 'item-add', "$($cfg.numero)", '--owner', "$($cfg.owner)", '--url', "$Issue", '--format', 'json')
            $resAdd = Invocar-Gh -Argumentos $argsAdd
            if ($resAdd.Salir) {
                Write-Host (Formatear-ErrorGh $resAdd.Error)
                exit 0
            }
            $tarjetaId = $resAdd.Datos.id
        }
    }

    # 4. Item Edit
    if ($Simular -or $datosEntrada) {
        Write-Host "gh project item-edit --id $tarjetaId --project-id $proyectoId --field-id $fieldId --single-select-option-id $optionId"
    } else {
        $argsEdit = @('project', 'item-edit', '--id', "$tarjetaId", '--project-id', "$proyectoId", '--field-id', "$fieldId", '--single-select-option-id', "$optionId")
        $resEdit = Invocar-Gh -Argumentos $argsEdit
        if ($resEdit.Salir) {
            Write-Host (Formatear-ErrorGh $resEdit.Error)
            exit 0
        }
    }

    # Salida: #<n> → <Columna>
    if ($issueNum) {
        Write-Host "#$issueNum → $nombreOpcion"
    } else {
        Write-Host "$Issue → $nombreOpcion"
    }
    exit 0
}
