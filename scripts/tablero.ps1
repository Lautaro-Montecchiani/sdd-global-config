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

. "$PSScriptRoot/tablero-comun.ps1"

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
    $tablerosCfg = @($cfg.tableros)
    $variosTableros = ($tablerosCfg.Count -gt 1)
    $leidos = 0
    $vistos = @{}
    $tarjetasUnicas = @()

    foreach ($tb in $tablerosCfg) {
        $claveTb = "$($tb.owner)/$($tb.numero)"
        $tarjetasData = $null
        $errorTb = $null

        if ($datosEntrada) {
            if ($datosEntrada.tableros) {
                $entradaTb = Buscar-EntradaTablero -TablerosObj $datosEntrada.tableros -ClaveTablero $claveTb
                if (-not $entradaTb) {
                    $errorTb = "sin datos en -Entrada"
                } elseif ($entradaTb.error) {
                    $errorTb = [string]$entradaTb.error
                } elseif ($entradaTb.tarjetas) {
                    $tarjetasData = $entradaTb.tarjetas
                } else {
                    $errorTb = "sin tarjetas en -Entrada"
                }
            } elseif ($datosEntrada.tarjetas -and $tb.owner -eq $cfg.owner -and $tb.numero -eq $cfg.numero) {
                $tarjetasData = $datosEntrada.tarjetas
            } else {
                $errorTb = "sin datos en -Entrada"
            }
        } else {
            $argsItem = @('project', 'item-list', "$($tb.numero)", '--owner', "$($tb.owner)", '--format', 'json', '--limit', '500')
            $resGh = Invocar-Gh -Argumentos $argsItem
            if ($resGh.Salir) {
                $errorTb = $resGh.Error
            } else {
                $tarjetasData = $resGh.Datos
            }
        }

        if ($errorTb) {
            if ($variosTableros) {
                Write-Host (Formatear-ErrorGh -ErrorTexto $errorTb -Tablero $claveTb)
            } else {
                Write-Host (Formatear-ErrorGh -ErrorTexto $errorTb)
            }
            continue
        }

        $leidos++
        $cuentaInfo = Contar-Columna -Tarjetas $tarjetasData -NombreOpcion $nombreOpcion
        foreach ($t in $cuentaInfo.Tarjetas) {
            $claveIssue = $null
            if ($t.content) {
                if ($t.content.url) {
                    $claveIssue = $t.content.url.Trim().ToLowerInvariant()
                } elseif ($t.content.repository -and $t.content.number) {
                    $claveIssue = "$($t.content.repository)#$($t.content.number)".ToLowerInvariant()
                } elseif ($t.content.number) {
                    $claveIssue = "#$($t.content.number)"
                }
            }
            if (-not $claveIssue) {
                $claveIssue = [System.Guid]::NewGuid().ToString()
            }
            if (-not $vistos.ContainsKey($claveIssue)) {
                $vistos[$claveIssue] = $true
                $tarjetasUnicas += [PSCustomObject]@{
                    Tarjeta = $t
                    Tablero = $claveTb
                }
            }
        }
    }

    if ($leidos -eq 0) {
        exit 0
    }

    $cuenta = $tarjetasUnicas.Count

    $aliasNorm = $Columna.Trim().ToLowerInvariant()
    $claveWip = "wip-$aliasNorm"
    $limite = if ($cfg.ContainsKey($claveWip)) { $cfg[$claveWip] } else { $null }

    if ($null -eq $limite) {
        Write-Host "${nombreOpcion}: $cuenta (sin límite)"
        exit 0
    }

    Write-Host "${nombreOpcion}: $cuenta de $limite"
    if ($cuenta -ge $limite) {
        foreach ($item in $tarjetasUnicas) {
            $t = $item.Tarjeta
            $sufijo = if ($variosTableros) { " ($($item.Tablero))" } else { "" }
            $num = $null
            $tit = $null
            if ($t.content) {
                if ($t.content.number) { $num = $t.content.number }
                if ($t.content.title) { $tit = $t.content.title }
            }
            if ($num -and $tit) {
                Write-Host "  #$num $tit$sufijo"
            } elseif ($num) {
                Write-Host "  #$num$sufijo"
            } elseif ($tit) {
                Write-Host "  $tit$sufijo"
            }
        }
        exit 2
    }
    exit 0
}

# Modo -Issue (Mover)
if ($Issue) {
    $Issue = $Issue.Trim()
    if ($Issue -match '^\d+$') {
        $remoto = (& git remote get-url origin 2>$null)
        $remotoStr = if ($remoto) { ($remoto -join '').Trim() } else { '' }
        if ($remotoStr -match '^(?:https?://github\.com/|git@github\.com:)([^/]+)/([^/]+?)(?:\.git)?/?$') {
            $owner = $matches[1]
            $repo = $matches[2]
            $Issue = "https://github.com/$owner/$repo/issues/$Issue"
        } else {
            Write-Host "-Issue: no se encontró un remoto origin de GitHub en la carpeta actual"
            exit 1
        }
    } elseif ($Issue -notmatch '^https?://github\.com/[^/]+/[^/]+/issues/\d+(?:/.*)?$') {
        Write-Host "-Issue debe ser una URL de issue de GitHub o el número de un issue"
        exit 1
    }

    $tableroDestino = Resolver-TableroDeIssue -Config $cfg -IssueUrl $Issue
    $destOwner = $tableroDestino.owner
    $destNumero = $tableroDestino.numero

    # 1. Project View
    $proyectoId = $null
    if ($datosEntrada -and $datosEntrada.proyecto) {
        $proyectoId = $datosEntrada.proyecto.id
    } else {
        $argsView = @('project', 'view', "$destNumero", '--owner', "$destOwner", '--format', 'json')
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
        $argsFields = @('project', 'field-list', "$destNumero", '--owner', "$destOwner", '--format', 'json')
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
            Write-Host "gh project item-add $destNumero --owner $destOwner --url $Issue"
            $tarjetaId = "PVTI_nuevo"
        } else {
            $argsAdd = @('project', 'item-add', "$destNumero", '--owner', "$destOwner", '--url', "$Issue", '--format', 'json')
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
