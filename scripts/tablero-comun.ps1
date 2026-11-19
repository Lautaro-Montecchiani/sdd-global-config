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
    $ordenClaves = @()

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
                if (-not $valores.ContainsKey($k)) {
                    $ordenClaves += $k
                }
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

    if ($valores.ContainsKey('cadencia-retro')) {
        $valCadencia = $valores['cadencia-retro']
        if ($valCadencia -notmatch '^[1-9][0-9]*$') {
            return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: cadencia-retro"; Codigo = 0 }
        }
    }

    $tableros = @(
        @{
            owner  = $valores['owner']
            numero = [int]$valores['numero']
        }
    )
    $duenos = @{}

    foreach ($k in $ordenClaves) {
        if ($k -like 'dueno-*') {
            if ($k.Length -le 6) {
                return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: $k"; Codigo = 0 }
            }
            $valDueno = $valores[$k]
            if ($valDueno -notmatch '^([A-Za-z0-9][A-Za-z0-9-]*)/([1-9][0-9]*)$') {
                return @{ Invalido = $true; Salir = $true; Mensaje = "tablero.md inválido: $k"; Codigo = 0 }
            }
            $duenoRepo = $k.Substring(6)
            $projOwner = $matches[1]
            $projNum = [int]$matches[2]
            $projObj = @{
                owner  = $projOwner
                numero = $projNum
            }
            $duenos[$duenoRepo] = $projObj
            $yaEsta = $tableros | Where-Object {
                $_.owner.ToLowerInvariant() -eq $projOwner.ToLowerInvariant() -and $_.numero -eq $projNum
            } | Select-Object -First 1
            if (-not $yaEsta) {
                $tableros += $projObj
            }
        }
    }

    $cfg = @{
        owner            = $valores['owner']
        numero           = [int]$valores['numero']
        'wip-diseno'     = if ($valores.ContainsKey('wip-diseno')) { [int]$valores['wip-diseno'] } else { $null }
        'wip-construccion'= if ($valores.ContainsKey('wip-construccion')) { [int]$valores['wip-construccion'] } else { $null }
        'wip-revision'   = if ($valores.ContainsKey('wip-revision')) { [int]$valores['wip-revision'] } else { $null }
        'cadencia-retro' = if ($valores.ContainsKey('cadencia-retro')) { [int]$valores['cadencia-retro'] } else { $null }
        tableros         = $tableros
        duenos           = $duenos
    }

    return @{ Config = $cfg; Salir = $false }
}

function Resolver-TableroDeIssue {
    param(
        [hashtable]$Config,
        [string]$IssueUrl
    )

    if ($IssueUrl -match '^https?://github\.com/([^/]+)/') {
        $dueno = $matches[1].ToLowerInvariant()
        if ($Config.duenos -and $Config.duenos.ContainsKey($dueno)) {
            return $Config.duenos[$dueno]
        }
    }

    return @{
        owner  = $Config.owner
        numero = $Config.numero
    }
}

function Unir-TarjetasDeTableros {
    param(
        [array]$Tarjetas
    )

    $porIssue = @{}
    $orden = @()

    foreach ($t in $Tarjetas) {
        $clave = "$($t.repo)#$($t.numero)".ToLowerInvariant()
        if (-not $porIssue.ContainsKey($clave)) {
            $orden += $clave
            $porIssue[$clave] = [PSCustomObject]@{
                repo    = $t.repo
                numero  = $t.numero
                titulo  = $t.titulo
                creado  = $t.creado
                cerrado = $t.cerrado
                eventos = @($t.eventos)
            }
        } else {
            $existente = $porIssue[$clave]
            $todosEventos = @($existente.eventos) + @($t.eventos)
            $existente.eventos = @($todosEventos | Sort-Object -Property creado)
        }
    }

    $resultado = @()
    foreach ($clave in $orden) {
        $resultado += $porIssue[$clave]
    }
    return $resultado
}

function Leer-PaginasTableroMetricas {
    param(
        [hashtable]$Tablero,
        [string]$DefaultOwner,
        [int]$DefaultNumero,
        $JsonEntrada
    )

    $claveTb = "$($Tablero.owner)/$($Tablero.numero)"
    $paginasTb = @()

    if ($JsonEntrada) {
        if ($JsonEntrada.PSObject.Properties['tableros'] -and $JsonEntrada.tableros) {
            $entradaTb = Buscar-EntradaTablero -TablerosObj $JsonEntrada.tableros -ClaveTablero $claveTb
            if (-not $entradaTb) {
                return @{ Error = "sin datos en -Entrada" }
            }
            if ($entradaTb.PSObject.Properties['error'] -and $entradaTb.error) {
                return @{ Error = [string]$entradaTb.error }
            }
            if ($entradaTb.PSObject.Properties['paginas'] -and $null -ne $entradaTb.paginas) {
                $paginasTb = @($entradaTb.paginas)
                return @{ Paginas = $paginasTb }
            }
            return @{ Error = "sin páginas en -Entrada" }
        }
        if ($JsonEntrada.PSObject.Properties['paginas'] -and $null -ne $JsonEntrada.paginas -and $Tablero.owner -eq $DefaultOwner -and $Tablero.numero -eq $DefaultNumero) {
            $paginasTb = @($JsonEntrada.paginas)
            return @{ Paginas = $paginasTb }
        }
        return @{ Error = "sin datos en -Entrada" }
    }

    $query = 'query($owner: String!, $numero: Int!, $cursor: String) { repositoryOwner(login: $owner) { ... on ProjectV2Owner { projectV2(number: $numero) { items(first: 100, after: $cursor) { pageInfo { hasNextPage endCursor } nodes { content { ... on Issue { number title createdAt closedAt repository { nameWithOwner } timelineItems(first: 100, itemTypes: [PROJECT_V2_ITEM_STATUS_CHANGED_EVENT]) { nodes { ... on ProjectV2ItemStatusChangedEvent { createdAt status project { number owner { ... on User { login } ... on Organization { login } } } } } } } } } } } } } }'

    $cursor = $null
    do {
        $argumentosGh = @('api', 'graphql', '-f', "query=$query", '-F', "owner=$($Tablero.owner)", '-F', "numero=$($Tablero.numero)")
        if ($cursor) {
            $argumentosGh += @('-F', "cursor=$cursor")
        }

        $resGh = Invocar-Gh -Argumentos $argumentosGh
        if ($resGh.Salir) {
            return @{ Error = $resGh.Error }
        }

        $datos = $resGh.Datos
        if ($datos.errors) {
            return @{ Error = (($datos.errors | ForEach-Object { $_.message }) -join '; ') }
        }

        $items = $datos.data.repositoryOwner.projectV2.items
        if (-not $items) {
            return @{ Error = "Project no encontrado o sin datos" }
        }

        $paginasTb += $datos
        $pageInfo = $items.pageInfo
        if ($pageInfo -and $pageInfo.hasNextPage) {
            $cursor = $pageInfo.endCursor
            $hasMore = $true
        } else {
            $hasMore = $false
        }
    } while ($hasMore)

    return @{ Paginas = $paginasTb }
}

function Formatear-ErrorGh {
    param(
        [string]$ErrorTexto,
        [string]$Tablero
    )

    $limpio = $ErrorTexto -replace '(?i)[a-z]:\\[^:\s]+', '' -replace '/[^\s:]+/[^\s:]+', ''
    $lineas = @(($limpio -split "`r?`n") | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $primeraLinea = if ($lineas.Count -gt 0) { $lineas[0] } else { "error al ejecutar gh" }

    $sugerencia = ""
    if ($ErrorTexto -match '(?i)(scope|project)') {
        $sugerencia = " — corré gh auth refresh -s project"
    }

    $prefijo = if ($Tablero) { "Tablero $Tablero no disponible" } else { "Tablero no disponible" }
    return "${prefijo}: $primeraLinea$sugerencia"
}

function Buscar-EntradaTablero {
    param(
        $TablerosObj,
        [string]$ClaveTablero
    )

    if (-not $TablerosObj) { return $null }
    $prop = $TablerosObj.PSObject.Properties | Where-Object { $_.Name.ToLowerInvariant() -eq $ClaveTablero.ToLowerInvariant() } | Select-Object -First 1
    if ($prop) { return $prop.Value }
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
