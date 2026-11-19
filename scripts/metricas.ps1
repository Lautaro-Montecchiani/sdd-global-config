# scripts/metricas.ps1
# Cálculo de métricas de flujo desde el historial del GitHub Project (Scrumban)

[CmdletBinding()]
param(
    [int]$Semanas = 4,
    [string]$Ahora,
    [string]$Config,
    [string]$Salida,
    [string]$Entrada
)

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

. "$PSScriptRoot/tablero-comun.ps1"

# Validación de parámetros
if ($PSBoundParameters.ContainsKey('Semanas') -and $Semanas -le 0) {
    Write-Host "Parámetro -Semanas inválido: debe ser un entero mayor que 0"
    exit 1
}

$ahoraFecha = [DateTime]::UtcNow
if ($Ahora) {
    try {
        $ahoraFecha = [DateTime]::Parse($Ahora, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
    } catch {
        Write-Host "Parámetro -Ahora inválido: debe ser una fecha ISO 8601 válida"
        exit 1
    }
}

# Resolución de salida
$rutaSalida = $Salida
if (-not $rutaSalida) {
    if ($env:OBSIDIAN_VAULT) {
        $rutaSalida = Join-Path $env:OBSIDIAN_VAULT "metricas.md"
    } else {
        $rutaSalida = "metricas.md"
    }
}

# Leer configuración del tablero
$cfgRes = Leer-ConfigTablero -RutaConfig $Config
if ($cfgRes.Salir) {
    if ($cfgRes.Mensaje) {
        Write-Host $cfgRes.Mensaje
    }
    exit $cfgRes.Codigo
}

$tableroCfg = $cfgRes.Config
$owner = $tableroCfg.owner
$numero = $tableroCfg.numero

# Funciones puras de ayuda
function Normalizar-NombreColumna {
    param([string]$Nombre)
    if (-not $Nombre) { return "" }
    switch ($Nombre.Trim().ToLowerInvariant()) {
        'backlog'      { return 'Backlog' }
        'listo'        { return 'Listo' }
        'diseño'       { return 'Diseño' }
        'diseno'       { return 'Diseño' }
        'construcción' { return 'Construcción' }
        'construccion' { return 'Construcción' }
        'revisión'     { return 'Revisión' }
        'revision'     { return 'Revisión' }
        'hecho'        { return 'Hecho' }
        default        { return $Nombre.Trim() }
    }
}

function Escapar-Titulo {
    param([string]$Texto)
    if (-not $Texto) { return "" }
    $t = $Texto -replace '\r?\n', ' '
    $t = $t -replace '\|', '\|'
    return $t.Trim()
}

function Formatear-Dias {
    param($Valor)
    if ($null -eq $Valor) { return '—' }
    return ($Valor.ToString("0.0", [System.Globalization.CultureInfo]::InvariantCulture)).Replace('.', ',')
}

function Calcular-Promedio {
    param([double[]]$Valores)
    if (-not $Valores -or $Valores.Count -eq 0) { return $null }
    $suma = 0.0
    foreach ($v in $Valores) { $suma += $v }
    return $suma / $Valores.Count
}

function Calcular-Mediana {
    param([double[]]$Valores)
    if (-not $Valores -or $Valores.Count -eq 0) { return $null }
    $ordenados = $Valores | Sort-Object
    $c = $ordenados.Count
    if ($c % 2 -ne 0) {
        return $ordenados[[Math]::Floor($c / 2)]
    } else {
        $m1 = $ordenados[($c / 2) - 1]
        $m2 = $ordenados[$c / 2]
        return ($m1 + $m2) / 2.0
    }
}

function Normalizar-Tarjetas {
    param(
        $Paginas,
        [string]$Owner,
        [int]$Numero
    )

    $tarjetasDescartadas = 0
    $eventosDescartados = 0
    $tarjetasValidas = @()

    foreach ($pag in $Paginas) {
        if (-not $pag.data -or -not $pag.data.repositoryOwner -or -not $pag.data.repositoryOwner.projectV2 -or -not $pag.data.repositoryOwner.projectV2.items -or -not $pag.data.repositoryOwner.projectV2.items.nodes) {
            continue
        }

        foreach ($node in $pag.data.repositoryOwner.projectV2.items.nodes) {
            $content = $node.content
            if (-not $content) {
                continue
            }

            # Validar tarjeta: number y createdAt
            if ($null -eq $content.number -or [string]::IsNullOrWhiteSpace($content.createdAt)) {
                $tarjetasDescartadas++
                continue
            }

            $creado = $null
            try {
                $creado = [DateTime]::Parse($content.createdAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
            } catch {
                $tarjetasDescartadas++
                continue
            }

            $cerrado = $null
            if (-not [string]::IsNullOrWhiteSpace($content.closedAt)) {
                try {
                    $cerrado = [DateTime]::Parse($content.closedAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                } catch {
                    $tarjetasDescartadas++
                    continue
                }
                if ($cerrado -lt $creado) {
                    $tarjetasDescartadas++
                    continue
                }
            }

            $repo = if ($content.repository -and $content.repository.nameWithOwner) {
                $content.repository.nameWithOwner
            } else {
                ""
            }

            # Validar y filtrar eventos
            $eventosValidos = @()
            if ($content.timelineItems -and $content.timelineItems.nodes) {
                foreach ($ev in $content.timelineItems.nodes) {
                    if ($null -eq $ev.status -or [string]::IsNullOrWhiteSpace($ev.status) -or [string]::IsNullOrWhiteSpace($ev.createdAt)) {
                        $eventosDescartados++
                        continue
                    }

                    # Filtrar por Project configurado
                    $evProjNum = if ($ev.project) { $ev.project.number } else { $null }
                    $evProjOwner = if ($ev.project -and $ev.project.owner) { $ev.project.owner.login } else { $null }

                    if ($null -eq $evProjNum -or $evProjNum -ne $Numero) {
                        continue
                    }
                    if ($null -eq $evProjOwner -or $evProjOwner.ToLowerInvariant() -ne $Owner.ToLowerInvariant()) {
                        continue
                    }

                    $evFecha = $null
                    try {
                        $evFecha = [DateTime]::Parse($ev.createdAt, [System.Globalization.CultureInfo]::InvariantCulture, [System.Globalization.DateTimeStyles]::AdjustToUniversal)
                    } catch {
                        $eventosDescartados++
                        continue
                    }

                    $eventosValidos += [PSCustomObject]@{
                        creado = $evFecha
                        status = Normalizar-NombreColumna -Nombre $ev.status
                    }
                }
            }

            $eventosOrdenados = @($eventosValidos | Sort-Object -Property creado)

            $tarjetasValidas += [PSCustomObject]@{
                repo    = $repo
                numero  = [int]$content.number
                titulo  = [string]$content.title
                creado  = $creado
                cerrado = $cerrado
                eventos = $eventosOrdenados
            }
        }
    }

    return @{
        Tarjetas            = $tarjetasValidas
        TarjetasDescartadas = $tarjetasDescartadas
        EventosDescartados  = $eventosDescartados
    }
}

# Obtención de datos de todos los tableros
$jsonObj = $null
if ($Entrada) {
    if (-not (Test-Path -LiteralPath $Entrada)) {
        Write-Host "Archivo de entrada no encontrado: $Entrada"
        exit 1
    }
    $rawJson = Get-Content -LiteralPath $Entrada -Raw -Encoding UTF8
    $jsonObj = $rawJson | ConvertFrom-Json
}

$tablerosCfg = @($tableroCfg.tableros)
$variosTableros = ($tablerosCfg.Count -gt 1)
$tablerosLeidos = @()
$tablerosFallidos = @()
$todasTarjetas = @()
$totalTarjetasDescartadas = 0
$totalEventosDescartados = 0

$query = 'query($owner: String!, $numero: Int!, $cursor: String) { repositoryOwner(login: $owner) { ... on ProjectV2Owner { projectV2(number: $numero) { items(first: 100, after: $cursor) { pageInfo { hasNextPage endCursor } nodes { content { ... on Issue { number title createdAt closedAt repository { nameWithOwner } timelineItems(first: 100, itemTypes: [PROJECT_V2_ITEM_STATUS_CHANGED_EVENT]) { nodes { ... on ProjectV2ItemStatusChangedEvent { createdAt status project { number owner { ... on User { login } ... on Organization { login } } } } } } } } } } } } } }'

foreach ($tb in $tablerosCfg) {
    $claveTb = "$($tb.owner)/$($tb.numero)"
    $paginasTb = @()
    $errorTb = $null

    if ($jsonObj) {
        if ($jsonObj.tableros) {
            $entradaTb = Buscar-EntradaTablero -TablerosObj $jsonObj.tableros -ClaveTablero $claveTb
            if (-not $entradaTb) {
                $errorTb = "sin datos en -Entrada"
            } elseif ($entradaTb.error) {
                $errorTb = [string]$entradaTb.error
            } elseif ($entradaTb.paginas) {
                $paginasTb = @($entradaTb.paginas)
            } else {
                $errorTb = "sin páginas en -Entrada"
            }
        } elseif ($jsonObj.paginas -and $tb.owner -eq $owner -and $tb.numero -eq $numero) {
            $paginasTb = @($jsonObj.paginas)
        } else {
            $errorTb = "sin datos en -Entrada"
        }
    } else {
        $cursor = $null
        do {
            $argumentosGh = @('api', 'graphql', '-f', "query=$query", '-F', "owner=$($tb.owner)", '-F', "numero=$($tb.numero)")
            if ($cursor) {
                $argumentosGh += @('-F', "cursor=$cursor")
            }

            $resGh = Invocar-Gh -Argumentos $argumentosGh
            if ($resGh.Salir) {
                $errorTb = $resGh.Error
                break
            }

            $datos = $resGh.Datos
            if ($datos.errors) {
                $errorTb = ($datos.errors | ForEach-Object { $_.message }) -join '; '
                break
            }

            $items = $datos.data.repositoryOwner.projectV2.items
            if (-not $items) {
                $errorTb = "Project no encontrado o sin datos"
                break
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
    }

    if ($errorTb) {
        if ($variosTableros) {
            Write-Host (Formatear-ErrorGh -ErrorTexto $errorTb -Tablero $claveTb)
        } else {
            Write-Host (Formatear-ErrorGh -ErrorTexto $errorTb)
        }
        $tablerosFallidos += $claveTb
        continue
    }

    $tablerosLeidos += $claveTb
    $norm = Normalizar-Tarjetas -Paginas $paginasTb -Owner $tb.owner -Numero $tb.numero
    $todasTarjetas += $norm.Tarjetas
    $totalTarjetasDescartadas += $norm.TarjetasDescartadas
    $totalEventosDescartados += $norm.EventosDescartados
}

if ($tablerosLeidos.Count -eq 0) {
    exit 0
}

if ($totalTarjetasDescartadas -gt 0 -or $totalEventosDescartados -gt 0) {
    Write-Host "Descartados por datos incompletos: $totalTarjetasDescartadas tarjetas y $totalEventosDescartados eventos."
}

$tarjetas = Unir-TarjetasDeTableros -Tarjetas $todasTarjetas

# Definir período
$fechaInicioPeriodo = $ahoraFecha.AddDays(-7 * $Semanas)
$fechaFinPeriodo = $ahoraFecha

# Filtrar cerrados en el período
$cerradosEnPeriodo = @($tarjetas | Where-Object {
    $null -ne $_.cerrado -and $_.cerrado -ge $fechaInicioPeriodo -and $_.cerrado -le $fechaFinPeriodo
})

# Calcular Lead Time y Cycle Time para cada issue cerrado en el período
foreach ($t in $cerradosEnPeriodo) {
    $t | Add-Member -MemberType NoteProperty -Name LeadTimeDias -Value (($t.cerrado - $t.creado).TotalDays) -Force
    $evFlujo = $t.eventos | Where-Object { $_.status -in @('Diseño', 'Construcción') } | Select-Object -First 1
    $cycleTime = if ($evFlujo) { ($t.cerrado - $evFlujo.creado).TotalDays } else { $null }
    $t | Add-Member -MemberType NoteProperty -Name CycleTimeDias -Value $cycleTime -Force
}

# 1. Sección Resumen
$lineasResumen = @()
if ($cerradosEnPeriodo.Count -eq 0) {
    $lineasResumen += "Sin issues cerrados en el período."
} else {
    $leadValores = [double[]]@($cerradosEnPeriodo | ForEach-Object { [double]$_.LeadTimeDias })
    $cycleValores = [double[]]@($cerradosEnPeriodo | Where-Object { $null -ne $_.CycleTimeDias } | ForEach-Object { [double]$_.CycleTimeDias })

    $promLead = Calcular-Promedio $leadValores
    $medLead = Calcular-Mediana $leadValores
    $promCycle = Calcular-Promedio $cycleValores
    $medCycle = Calcular-Mediana $cycleValores
    $sinCycle = ($cerradosEnPeriodo | Where-Object { $null -eq $_.CycleTimeDias }).Count

    $lineasResumen += "| Métrica | Promedio | Mediana | Issues |"
    $lineasResumen += "|---|---|---|---|"
    $lineasResumen += "| Lead time (días) | $(Formatear-Dias $promLead) | $(Formatear-Dias $medLead) | $($leadValores.Count) |"
    $lineasResumen += "| Cycle time (días) | $(Formatear-Dias $promCycle) | $(Formatear-Dias $medCycle) | $($cycleValores.Count) |"
    $lineasResumen += ""
    $lineasResumen += "Cerrados en el período: $($cerradosEnPeriodo.Count). Sin cycle time (no pasaron por Diseño ni Construcción): $sinCycle."
}

# 2. Sección Throughput
$lineasThroughput = @()
$lineasThroughput += "| Semana desde | Cerrados |"
$lineasThroughput += "|---|---|"
for ($k = 1; $k -le $Semanas; $k++) {
    $semInicio = $fechaInicioPeriodo.AddDays(7 * ($k - 1))
    $semFin = $fechaInicioPeriodo.AddDays(7 * $k)
    $cerradosSemana = ($cerradosEnPeriodo | Where-Object {
        $_.cerrado -ge $semInicio -and ($k -eq $Semanas ? ($_.cerrado -le $semFin) : ($_.cerrado -lt $semFin))
    }).Count
    $lineasThroughput += "| $($semInicio.ToString('dd/MM')) | $cerradosSemana |"
}

# 3. Sección Tiempo por columna
$columnasOrden = @('Backlog', 'Listo', 'Diseño', 'Construcción', 'Revisión', 'Hecho')
$tiemposColumna = @{}
foreach ($col in $columnasOrden) {
    $tiemposColumna[$col] = @{
        TotalDias = 0.0
        Issues    = [System.Collections.Generic.HashSet[string]]::new()
    }
}

foreach ($t in $cerradosEnPeriodo) {
    if (-not $t.eventos -or $t.eventos.Count -eq 0) {
        continue
    }
    $evs = $t.eventos
    $issueId = "$($t.repo)#$($t.numero)"
    for ($i = 0; $i -lt $evs.Count; $i++) {
        $colActual = $evs[$i].status
        $inicioTramo = $evs[$i].creado
        $finTramo = if ($i -lt ($evs.Count - 1)) { $evs[$i + 1].creado } else { $t.cerrado }
        $duracion = ($finTramo - $inicioTramo).TotalDays
        if ($duracion -lt 0) { $duracion = 0.0 }

        if (-not $tiemposColumna.ContainsKey($colActual)) {
            $tiemposColumna[$colActual] = @{
                TotalDias = 0.0
                Issues    = [System.Collections.Generic.HashSet[string]]::new()
            }
        }
        $tiemposColumna[$colActual].TotalDias += $duracion
        [void]$tiemposColumna[$colActual].Issues.Add($issueId)
    }
}

$filasCol = @()
foreach ($col in $columnasOrden) {
    if ($tiemposColumna.ContainsKey($col)) {
        $info = $tiemposColumna[$col]
        if ($info.Issues.Count -gt 0) {
            $promCol = $info.TotalDias / $info.Issues.Count
            $filasCol += "| $col | $(Formatear-Dias $promCol) | $($info.Issues.Count) |"
        }
    }
}

$lineasTiempoColumna = @()
if ($filasCol.Count -eq 0) {
    $lineasTiempoColumna += "Sin datos en el período."
} else {
    $lineasTiempoColumna += "| Columna | Promedio (días) | Issues |"
    $lineasTiempoColumna += "|---|---|---|"
    $lineasTiempoColumna += $filasCol
}

# 4. Sección Trabajo en curso
$tarjetasEnCurso = @()
foreach ($t in $tarjetas) {
    if ($null -ne $t.cerrado) {
        continue
    }
    if (-not $t.eventos -or $t.eventos.Count -eq 0) {
        continue
    }
    $ultimoEv = $t.eventos[-1]
    if ($ultimoEv.status -in @('Diseño', 'Construcción', 'Revisión')) {
        $diasEnColumna = ($ahoraFecha - $ultimoEv.creado).TotalDays
        if ($diasEnColumna -lt 0) { $diasEnColumna = 0.0 }
        $tarjetasEnCurso += [PSCustomObject]@{
            Issue   = "$($t.repo)#$($t.numero)"
            Titulo  = Escapar-Titulo $t.titulo
            Columna = $ultimoEv.status
            Dias    = $diasEnColumna
        }
    }
}

$tarjetasEnCursoOrdenadas = @($tarjetasEnCurso | Sort-Object -Property Dias -Descending)
$lineasTrabajoEnCurso = @()
if ($tarjetasEnCursoOrdenadas.Count -eq 0) {
    $lineasTrabajoEnCurso += "Sin trabajo en curso."
} else {
    $lineasTrabajoEnCurso += "| Issue | Título | Columna | Días en la columna |"
    $lineasTrabajoEnCurso += "|---|---|---|---|"
    foreach ($tc in $tarjetasEnCursoOrdenadas) {
        $lineasTrabajoEnCurso += "| $($tc.Issue) | $($tc.Titulo) | $($tc.Columna) | $(Formatear-Dias $tc.Dias) |"
    }
}

# 5. Sección Issues cerrados
$cerradosOrdenados = @($cerradosEnPeriodo | Sort-Object -Property cerrado)
$lineasIssuesCerrados = @()
if ($cerradosOrdenados.Count -eq 0) {
    $lineasIssuesCerrados += "Sin issues cerrados en el período."
} else {
    $lineasIssuesCerrados += "| Issue | Título | Lead time | Cycle time |"
    $lineasIssuesCerrados += "|---|---|---|---|"
    foreach ($c in $cerradosOrdenados) {
        $issId = "$($c.repo)#$($c.numero)"
        $tit = Escapar-Titulo $c.titulo
        $lt = Formatear-Dias $c.LeadTimeDias
        $ct = Formatear-Dias $c.CycleTimeDias
        $lineasIssuesCerrados += "| $issId | $tit | $lt | $ct |"
    }
}

# Construir contenido markdown con finales de línea LF
$lineaTableros = if (-not $variosTableros -and $tablerosFallidos.Count -eq 0) {
    "Tablero: $owner/$numero."
} else {
    $parteLeidos = "Tableros: $($tablerosLeidos -join ', ')."
    if ($tablerosFallidos.Count -gt 0) {
        "$parteLeidos Sin leer: $($tablerosFallidos -join ', ')."
    } else {
        $parteLeidos
    }
}

$encabezado = @(
    "<!-- Generado con scripts/metricas.ps1 desde el tablero de GitHub. No editar a mano. -->",
    "# Métricas de flujo",
    "Generado el $($ahoraFecha.ToString('dd/MM/yyyy')). Período: $($fechaInicioPeriodo.ToString('dd/MM/yyyy')) a $($fechaFinPeriodo.ToString('dd/MM/yyyy')) ($Semanas semanas). $lineaTableros",
    "",
    "## Resumen"
)

$bloques = @()
$bloques += ($encabezado -join "`n")
$bloques += ($lineasResumen -join "`n")
$bloques += "## Throughput"
$bloques += ($lineasThroughput -join "`n")
$bloques += "## Tiempo por columna"
$bloques += ($lineasTiempoColumna -join "`n")
$bloques += "## Trabajo en curso"
$bloques += ($lineasTrabajoEnCurso -join "`n")
$bloques += "## Issues cerrados"
$bloques += ($lineasIssuesCerrados -join "`n")

$contenidoFinal = ($bloques -join "`n`n") + "`n"

# Asegurar directorio de salida y escribir en UTF-8 sin BOM
$dirSalida = Split-Path -Parent $rutaSalida
if ($dirSalida -and -not (Test-Path -LiteralPath $dirSalida)) {
    New-Item -ItemType Directory -Path $dirSalida -Force | Out-Null
}

$utf8SinBom = [System.Text.UTF8Encoding]::new($false)
[System.IO.File]::WriteAllText($rutaSalida, $contenidoFinal, $utf8SinBom)

$salidaNombre = Split-Path -Leaf $rutaSalida
if (-not $salidaNombre) { $salidaNombre = "metricas.md" }
Write-Host "Métricas generadas: $salidaNombre ($($cerradosEnPeriodo.Count) cerrados en $Semanas semanas)."
exit 0
