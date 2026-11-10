# scripts/generar-plantillas.ps1
# Genera las cuatro plantillas del Agente a partir de templates/fuente/
# Uso: pwsh scripts/generar-plantillas.ps1 [-Comprobar]

param(
    [switch]$Comprobar
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/comun.ps1"

$repoRoot = Obtener-RepoRoot
$fuenteDir = Join-Path $repoRoot "templates/fuente"
$fragmentosDir = Join-Path $fuenteDir "fragmentos"
$esqueletosDir = Join-Path $fuenteDir "esqueletos"

$mapeo = @(
    @{ Esqueleto = "AGENTS.md"; Destino = "templates/comun/AGENTS.md" },
    @{ Esqueleto = "copilot-instructions.md"; Destino = "templates/copilot/copilot-instructions.md" },
    @{ Esqueleto = "sdd-workflow.mdc"; Destino = "templates/cursor/sdd-workflow.mdc" },
    @{ Esqueleto = "GEMINI.md"; Destino = "templates/antigravity/GEMINI.md" }
)

$aviso = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
$propioTitulo = "## Propio del proyecto"
$propioComentario = '<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->'

# 1. Validar y generar en memoria
$generados = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $mapeo) {
    $esqPath = Join-Path $esqueletosDir $item.Esqueleto
    if (-not (Test-Path $esqPath)) {
        Write-Error "No existe el esqueleto $($item.Esqueleto) en $esqueletosDir"
        exit 1
    }

    $esqRaw = Normalizar-Texto (Get-Content -Path $esqPath -Raw -Encoding UTF8)
    $lineas = $esqRaw -split "\n"
    $resultadoLineas = [System.Collections.Generic.List[string]]::new()

    foreach ($linea in $lineas) {
        if ($linea -match "^\s*<!--\s*incluir:\s*([^\s>]+)\s*-->\s*$") {
            $fragNombre = $matches[1]
            $fragPath = Join-Path $fragmentosDir "$fragNombre.md"
            if (-not (Test-Path $fragPath)) {
                Write-Host "Error: El esqueleto $($item.Esqueleto) referencia el fragmento inexistente '$fragNombre'"
                exit 1
            }
            $fragTxt = Normalizar-Texto (Get-Content -Path $fragPath -Raw -Encoding UTF8)
            $fragSinFinal = $fragTxt.TrimEnd("`n", "`r")
            $resultadoLineas.Add($fragSinFinal)
        } else {
            $resultadoLineas.Add($linea)
        }
    }

    $cuerpo = $resultadoLineas -join "`n"

    # Encabezado con aviso
    if ($item.Esqueleto -match "\.mdc$") {
        if ($cuerpo -match "(?s)^(---\n.*?\n---\n)(.*)$") {
            $front = $matches[1]
            $resto = $matches[2].TrimStart("`n")
            $cuerpo = "${front}`n${aviso}`n`n${resto}"
        } else {
            $cuerpo = "${aviso}`n`n" + $cuerpo.TrimStart("`n")
        }
    } else {
        $cuerpo = "${aviso}`n`n" + $cuerpo.TrimStart("`n")
    }

    # Pie de sección propia
    $cuerpo = $cuerpo.TrimEnd("`n") + "`n`n${propioTitulo}`n${propioComentario}`n"

    $generados.Add(@{
        Esqueleto = $item.Esqueleto
        Destino = $item.Destino
        Contenido = $cuerpo
    })
}

# 2. Si se solicitó -Comprobar
if ($Comprobar) {
    $plantillasDifieren = [System.Collections.Generic.List[string]]::new()

    foreach ($g in $generados) {
        $destPath = Join-Path $repoRoot $g.Destino
        if (-not (Test-Path $destPath)) {
            $plantillasDifieren.Add($g.Destino)
            continue
        }
        $actual = Normalizar-Texto (Get-Content -Path $destPath -Raw -Encoding UTF8)
        $gen = Normalizar-Texto $g.Contenido
        if ($actual -ne $gen) {
            $plantillasDifieren.Add($g.Destino)
        }
    }

    # Comparar títulos de reglas con .claude/CLAUDE.md
    $fragReglas = Join-Path $fragmentosDir "reglas-ejecucion.md"
    $titulosFuente = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $fragReglas) {
        $lineasReglas = (Normalizar-Texto (Get-Content -Path $fragReglas -Raw -Encoding UTF8)) -split "\n"
        foreach ($l in $lineasReglas) {
            if ($l -match "^\d+\.\s+\*\*(.+?):\*\*") {
                $titulosFuente.Add($matches[1].Trim())
            }
        }
    }

    $claudePath = Join-Path $repoRoot ".claude/CLAUDE.md"
    $titulosClaude = [System.Collections.Generic.List[string]]::new()
    if (Test-Path $claudePath) {
        $claudeTxt = Normalizar-Texto (Get-Content -Path $claudePath -Raw -Encoding UTF8)
        $idxInicio = $claudeTxt.IndexOf("### Reglas de ejecución del Agente")
        if ($idxInicio -ge 0) {
            $sub = $claudeTxt.Substring($idxInicio)
            $lineasClaude = $sub -split "\n"
            $enSeccion = $false
            foreach ($l in $lineasClaude) {
                if ($l.StartsWith("### Reglas de ejecución del Agente")) {
                    $enSeccion = $true
                    continue
                }
                if ($enSeccion) {
                    if ($l -match "^#{2,3}\s+") {
                        break
                    }
                    if ($l -match "^\d+\.\s+\*\*(.+?):\*\*") {
                        $titulosClaude.Add($matches[1].Trim())
                    }
                }
            }
        }
    }

    $titulosDifieren = $false
    if ($titulosFuente.Count -ne $titulosClaude.Count) {
        $titulosDifieren = $true
    } else {
        for ($i = 0; $i -lt $titulosFuente.Count; $i++) {
            if ($titulosFuente[$i] -ne $titulosClaude[$i]) {
                $titulosDifieren = $true
                break
            }
        }
    }

    if ($plantillasDifieren.Count -gt 0) {
        Write-Host "Error: Las siguientes plantillas difieren de lo generado desde templates/fuente/:"
        foreach ($p in $plantillasDifieren) {
            Write-Host "  - $p"
        }
    }

    if ($titulosDifieren) {
        Write-Host "Error: Los títulos de las reglas difieren entre fragmentos/reglas-ejecucion.md y .claude/CLAUDE.md"
        Write-Host "Títulos en fuente ($($titulosFuente.Count)):"
        for ($i = 0; $i -lt $titulosFuente.Count; $i++) {
            Write-Host "  $($i + 1). $($titulosFuente[$i])"
        }
        Write-Host "Títulos en CLAUDE.md ($($titulosClaude.Count)):"
        for ($i = 0; $i -lt $titulosClaude.Count; $i++) {
            Write-Host "  $($i + 1). $($titulosClaude[$i])"
        }
    }

    if ($plantillasDifieren.Count -gt 0 -or $titulosDifieren) {
        exit 1
    }

    Write-Host "OK: Todas las plantillas y títulos de reglas están sincronizados."
    exit 0
}

# 3. Escribir plantillas
foreach ($g in $generados) {
    $destPath = Join-Path $repoRoot $g.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $g.Contenido
    Write-Host "Generado: $($g.Destino)"
}
