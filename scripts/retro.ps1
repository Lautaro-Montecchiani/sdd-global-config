# scripts/retro.ps1
# Aviso de cadencia y cálculo del período para la retro semanal (Scrumban)

[CmdletBinding()]
param(
    [switch]$Aviso,
    [switch]$Periodo,
    [string]$Vault,
    [string]$Config,
    [string]$Ahora
)

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

. "$PSScriptRoot/tablero-comun.ps1"

function Obtener-FechasRetro {
    param([string[]]$Nombres)

    $fechas = @()
    if (-not $Nombres) { return $fechas }

    foreach ($nom in $Nombres) {
        $leaf = Split-Path -Leaf $nom
        if ($leaf -match '^(\d{4}-\d{2}-\d{2})\.md$') {
            $strFecha = $matches[1]
            $dt = [DateTime]::MinValue
            $exacto = [DateTime]::TryParseExact(
                $strFecha,
                'yyyy-MM-dd',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None,
                [ref]$dt
            )
            if ($exacto) {
                $fechas += $dt
            }
        }
    }

    return @($fechas | Sort-Object)
}

function Obtener-NotasArchive {
    param(
        $Items,
        [DateTime]$Desde,
        [DateTime]$Hasta
    )

    $resultado = @()
    if (-not $Items) { return $resultado }

    foreach ($item in $Items) {
        $nom = Split-Path -Leaf $item.Archivo
        if ($nom -match '^(\d{4}-\d{2}-\d{2})-(.+)\.md$') {
            $strFecha = $matches[1]
            $slug = $matches[2]
            $dt = [DateTime]::MinValue
            $exacto = [DateTime]::TryParseExact(
                $strFecha,
                'yyyy-MM-dd',
                [System.Globalization.CultureInfo]::InvariantCulture,
                [System.Globalization.DateTimeStyles]::None,
                [ref]$dt
            )
            if ($exacto) {
                if ($dt.Date -ge $Desde.Date -and $dt.Date -le $Hasta.Date) {
                    $tipo = "SDD"
                    $nombreFinal = $slug
                    if ($slug.StartsWith("odd-")) {
                        $tipo = "ODD"
                        $nombreFinal = $slug.Substring(4)
                    }
                    $resultado += [PSCustomObject]@{
                        Proyecto = $item.Proyecto
                        Nombre   = $nombreFinal
                        Fecha    = $dt
                        FechaStr = $strFecha
                        Tipo     = $tipo
                    }
                }
            }
        }
    }

    $ordenados = @($resultado | Sort-Object -Property Fecha, Proyecto)
    return $ordenados
}

# Si fue importado por dot-sourcing, no ejecutar lógica de invocación
if ($MyInvocation.InvocationName -eq '.') {
    return
}

# Validación de parámetros exactamente uno de -Aviso o -Periodo
if (($Aviso -and $Periodo) -or (-not $Aviso -and -not $Periodo)) {
    Write-Host "Error: se debe especificar exactamente uno de -Aviso o -Periodo"
    exit 1
}

# Resolver fecha Ahora
$ahoraFecha = [DateTime]::Today
if ($Ahora) {
    try {
        $ahoraFecha = [DateTime]::Parse($Ahora, [System.Globalization.CultureInfo]::InvariantCulture).Date
    } catch {
        Write-Host "Error: -Ahora debe ser una fecha válida"
        exit 1
    }
}

# Resolver Vault
$vaultRuta = $Vault
if (-not $vaultRuta) {
    if ($env:OBSIDIAN_VAULT) {
        $vaultRuta = $env:OBSIDIAN_VAULT
    }
}

# Resolver Config
$configRuta = $Config
if (-not $configRuta -and $vaultRuta) {
    $configRuta = Join-Path $vaultRuta "tablero.md"
}

# Modo -Aviso
if ($Aviso) {
    if (-not $vaultRuta -and -not $Config) {
        exit 0
    }

    $cfgRes = Leer-ConfigTablero -RutaConfig $configRuta -ModoComprobar
    if ($cfgRes.NoConfigurado) {
        exit 0
    }
    if ($cfgRes.Invalido) {
        if ($cfgRes.Mensaje) {
            Write-Host $cfgRes.Mensaje
        }
        exit 0
    }

    $tableroCfg = $cfgRes.Config
    $cadencia = $tableroCfg['cadencia-retro']
    if ($null -eq $cadencia) {
        exit 0
    }

    $retrosDir = if ($vaultRuta) { Join-Path $vaultRuta "retros" } else { $null }
    $nombresRetros = @()
    if ($retrosDir -and (Test-Path -LiteralPath $retrosDir)) {
        $nombresRetros = @(Get-ChildItem -LiteralPath $retrosDir -Filter "*.md" | Select-Object -ExpandProperty Name)
    }

    $fechasRetros = Obtener-FechasRetro -Nombres $nombresRetros
    if ($fechasRetros.Count -eq 0) {
        Write-Host "Todavía no hay retros en el vault: corré /retro"
        exit 1
    }

    $ultimaFecha = $fechasRetros[-1]
    $dias = ($ahoraFecha - $ultimaFecha.Date).Days
    if ($dias -ge $cadencia) {
        Write-Host "Retro vencida: pasaron $dias días desde la última ($($ultimaFecha.ToString('yyyy-MM-dd'))): corré /retro"
        exit 1
    }

    exit 0
}

# Modo -Periodo
if ($Periodo) {
    if (-not $vaultRuta) {
        Write-Host "Sin vault: OBSIDIAN_VAULT no definida"
        exit 0
    }

    $cadencia = 7
    if ($configRuta -and (Test-Path -LiteralPath $configRuta)) {
        $cfgRes = Leer-ConfigTablero -RutaConfig $configRuta -ModoComprobar
        if (-not $cfgRes.Salir -and $cfgRes.Config -and $null -ne $cfgRes.Config['cadencia-retro']) {
            $cadencia = [int]$cfgRes.Config['cadencia-retro']
        }
    }

    $retrosDir = Join-Path $vaultRuta "retros"
    $nombresRetros = @()
    if (Test-Path -LiteralPath $retrosDir) {
        $nombresRetros = @(Get-ChildItem -LiteralPath $retrosDir -Filter "*.md" | Select-Object -ExpandProperty Name)
    }

    $fechasRetros = Obtener-FechasRetro -Nombres $nombresRetros

    $retroAnteriorStr = "Retro anterior: ninguna"
    $desdeFecha = $null
    if ($fechasRetros.Count -gt 0) {
        $ultimaRetro = $fechasRetros[-1]
        $desdeFecha = $ultimaRetro.Date
        $retroAnteriorStr = "Retro anterior: retros/$($ultimaRetro.ToString('yyyy-MM-dd')).md"
    } else {
        $desdeFecha = $ahoraFecha.AddDays(-1 * $cadencia)
    }
    $hastaFecha = $ahoraFecha

    $diasPeriodo = ($hastaFecha - $desdeFecha).Days
    $semanas = [Math]::Ceiling($diasPeriodo / 7.0)
    if ($semanas -lt 1) { $semanas = 1 }

    Write-Host "Desde: $($desdeFecha.ToString('yyyy-MM-dd'))"
    Write-Host "Hasta: $($hastaFecha.ToString('yyyy-MM-dd'))"
    Write-Host "Semanas: $semanas"
    Write-Host $retroAnteriorStr
    Write-Host "Terminado:"

    $itemsArchive = @()
    $projectsDir = Join-Path $vaultRuta "projects"
    if (Test-Path -LiteralPath $projectsDir) {
        $projDirs = Get-ChildItem -LiteralPath $projectsDir -Directory
        foreach ($pd in $projDirs) {
            $pName = $pd.Name
            $archDir = Join-Path $pd.FullName "archive"
            if (Test-Path -LiteralPath $archDir) {
                $files = Get-ChildItem -LiteralPath $archDir -Filter "*.md"
                foreach ($f in $files) {
                    $itemsArchive += [PSCustomObject]@{
                        Proyecto = $pName
                        Archivo  = $f.Name
                    }
                }
            }
        }
    }

    $notasPeriodo = Obtener-NotasArchive -Items $itemsArchive -Desde $desdeFecha -Hasta $hastaFecha
    if ($notasPeriodo.Count -eq 0) {
        Write-Host "Sin changes ni ODD archivados en el período."
    } else {
        foreach ($nota in $notasPeriodo) {
            Write-Host "- $($nota.Proyecto): $($nota.Nombre) ($($nota.FechaStr), $($nota.Tipo))"
        }
    }

    exit 0
}
