# scripts/generar-plantillas.ps1
# Genera las cuatro plantillas del Agente y los nueve comandos de Claude a partir de templates/fuente/ y skills/
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
$comandosFuenteDir = Join-Path $fuenteDir "comandos"
$skillsDir = Join-Path $repoRoot "skills"

$mapeoPlantillas = @(
    @{ Esqueleto = "AGENTS.md"; Destino = "templates/comun/AGENTS.md" },
    @{ Esqueleto = "copilot-instructions.md"; Destino = "templates/copilot/copilot-instructions.md" },
    @{ Esqueleto = "sdd-workflow.mdc"; Destino = "templates/cursor/sdd-workflow.mdc" },
    @{ Esqueleto = "GEMINI.md"; Destino = "templates/antigravity/GEMINI.md" }
)

$mapeoComandos = @(
    @{ Encabezado = "opsx/apply.md"; Destino = ".claude/commands/opsx/apply.md" },
    @{ Encabezado = "opsx/archive.md"; Destino = ".claude/commands/opsx/archive.md" },
    @{ Encabezado = "opsx/explore.md"; Destino = ".claude/commands/opsx/explore.md" },
    @{ Encabezado = "opsx/propose.md"; Destino = ".claude/commands/opsx/propose.md" },
    @{ Encabezado = "opsx/verify.md"; Destino = ".claude/commands/opsx/verify.md" },
    @{ Encabezado = "odd/start.md"; Destino = ".claude/commands/odd/start.md" },
    @{ Encabezado = "odd/start.md"; Destino = ".claude/commands/odd.md" },
    @{ Encabezado = "odd/verify.md"; Destino = ".claude/commands/odd/verify.md" },
    @{ Encabezado = "odd/close.md"; Destino = ".claude/commands/odd/close.md" }
)

$avisoPlantillas = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
$avisoComandos = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
$propioTitulo = "## Propio del proyecto"
$propioComentario = '<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->'

# 1. Validar y generar plantillas en memoria
$plantillasGeneradas = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $mapeoPlantillas) {
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
            $cuerpo = "${front}`n${avisoPlantillas}`n`n${resto}"
        } else {
            $cuerpo = "${avisoPlantillas}`n`n" + $cuerpo.TrimStart("`n")
        }
    } else {
        $cuerpo = "${avisoPlantillas}`n`n" + $cuerpo.TrimStart("`n")
    }

    # Pie de sección propia
    $cuerpo = $cuerpo.TrimEnd("`n") + "`n`n${propioTitulo}`n${propioComentario}`n"

    $plantillasGeneradas.Add(@{
        Esqueleto = $item.Esqueleto
        Destino = $item.Destino
        Contenido = $cuerpo
    })
}

# 2. Validar y generar comandos en memoria
$comandosGenerados = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $mapeoComandos) {
    $encPath = Join-Path $comandosFuenteDir $item.Encabezado
    if (-not (Test-Path $encPath)) {
        Write-Host "Error: No existe el encabezado $($item.Encabezado) en $comandosFuenteDir"
        exit 1
    }

    $encRaw = Normalizar-Texto (Get-Content -Path $encPath -Raw -Encoding UTF8)
    if ($encRaw -notmatch "(?s)^(---\n.*?\n---)(.*)$") {
        Write-Host "Error: El encabezado $($item.Encabezado) no contiene frontmatter válido"
        exit 1
    }

    $frontmatter = $matches[1]
    $resto = $matches[2]

    $lineasResto = $resto -split "\n"
    $cuerpoPartes = [System.Collections.Generic.List[string]]::new()

    foreach ($linea in $lineasResto) {
        if ($linea -match "^\s*<!--\s*incluir-skill:\s*(.+?)\s*-->\s*$") {
            $marca = $matches[1].Trim()
            if ($marca -match "^([^#]+)#(.+)$") {
                $skillNombre = $matches[1].Trim()
                $seccionTitulo = $matches[2].Trim()
                $skillPath = Join-Path $skillsDir "$skillNombre/SKILL.md"
                if (-not (Test-Path $skillPath)) {
                    Write-Host "Error: El encabezado $($item.Encabezado) referencia la skill inexistente '$skillNombre' (marca '$marca')"
                    exit 1
                }
                $skillRaw = Normalizar-Texto (Get-Content -Path $skillPath -Raw -Encoding UTF8)
                $seccionTxt = Extraer-SeccionMarkdown -Texto $skillRaw -Titulo $seccionTitulo
                if ($null -eq $seccionTxt) {
                    Write-Host "Error: El encabezado $($item.Encabezado) referencia la sección inexistente '$seccionTitulo' en skill '$skillNombre' (marca '$marca')"
                    exit 1
                }
                $cuerpoPartes.Add($seccionTxt.TrimEnd("`r", "`n"))
            } else {
                $skillNombre = $marca
                $skillPath = Join-Path $skillsDir "$skillNombre/SKILL.md"
                if (-not (Test-Path $skillPath)) {
                    Write-Host "Error: El encabezado $($item.Encabezado) referencia la skill inexistente '$skillNombre' (marca '$marca')"
                    exit 1
                }
                $skillRaw = Normalizar-Texto (Get-Content -Path $skillPath -Raw -Encoding UTF8)
                $cuerpoSkill = Obtener-CuerpoSinFrontmatter -Texto $skillRaw
                $cuerpoPartes.Add($cuerpoSkill.TrimEnd("`r", "`n"))
            }
        }
    }

    $cuerpoUnido = $cuerpoPartes -join "`n`n"
    $contenidoFinal = "${frontmatter}`n`n${avisoComandos}`n`n" + $cuerpoUnido.TrimStart("`r", "`n")
    $contenidoFinal = (Normalizar-Texto $contenidoFinal).TrimEnd("`r", "`n") + "`n"

    $comandosGenerados.Add(@{
        Encabezado = $item.Encabezado
        Destino = $item.Destino
        Contenido = $contenidoFinal
    })
}

# 3. Si se solicitó -Comprobar
if ($Comprobar) {
    $plantillasDifieren = [System.Collections.Generic.List[string]]::new()

    foreach ($g in $plantillasGeneradas) {
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

    $comandosDifieren = [System.Collections.Generic.List[string]]::new()

    foreach ($c in $comandosGenerados) {
        $destPath = Join-Path $repoRoot $c.Destino
        if (-not (Test-Path $destPath)) {
            $comandosDifieren.Add($c.Destino)
            continue
        }
        $actual = Normalizar-Texto (Get-Content -Path $destPath -Raw -Encoding UTF8)
        $gen = Normalizar-Texto $c.Contenido
        if ($actual -ne $gen) {
            $comandosDifieren.Add($c.Destino)
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

    if ($comandosDifieren.Count -gt 0) {
        Write-Host "Error: Los siguientes comandos difieren de lo generado desde skills/ y templates/fuente/comandos/:"
        foreach ($c in $comandosDifieren) {
            Write-Host "  - $c"
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

    if ($plantillasDifieren.Count -gt 0 -or $comandosDifieren.Count -gt 0 -or $titulosDifieren) {
        exit 1
    }

    Write-Host "OK: Todas las plantillas, comandos y títulos de reglas están sincronizados."
    exit 0
}

# 4. Escribir plantillas
foreach ($g in $plantillasGeneradas) {
    $destPath = Join-Path $repoRoot $g.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $g.Contenido
    Write-Host "Generado: $($g.Destino)"
}

# 5. Escribir comandos
foreach ($c in $comandosGenerados) {
    $destPath = Join-Path $repoRoot $c.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $c.Contenido
    Write-Host "Generado: $($c.Destino)"
}
