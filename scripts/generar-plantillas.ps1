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
$comandosAgenteFuenteDir = Join-Path $fuenteDir "comandos-agente"
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

$mapeoComandosAgente = @(
    @{
        Comando = "odd-apply"
        Encabezado = "antigravity.md"
        Destino = "templates/antigravity/skills/odd-apply/SKILL.md"
    },
    @{
        Comando = "odd-apply"
        Encabezado = "cursor.md"
        Destino = "templates/cursor/commands/odd-apply.md"
    },
    @{
        Comando = "odd-apply"
        Encabezado = "copilot.md"
        Destino = "templates/copilot/prompts/odd-apply.prompt.md"
    }
)

$avisoPlantillas = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
$avisoComandos = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
$avisoComandosAgente = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano. -->'
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

# 2b. Validar y generar comandos de agente en memoria
$comandosAgenteGenerados = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $mapeoComandosAgente) {
    $cmdDir = Join-Path $comandosAgenteFuenteDir $item.Comando
    $cuerpoPath = Join-Path $cmdDir "cuerpo.md"
    if (-not (Test-Path $cuerpoPath)) {
        Write-Host "Error: No existe el cuerpo en $cuerpoPath"
        exit 1
    }

    $cuerpoRaw = Normalizar-Texto (Get-Content -Path $cuerpoPath -Raw -Encoding UTF8)
    $lineasCuerpo = $cuerpoRaw -split "\n"
    $cuerpoResuelto = [System.Collections.Generic.List[string]]::new()

    foreach ($linea in $lineasCuerpo) {
        if ($linea -match "^\s*<!--\s*incluir:\s*([^\s>]+)\s*-->\s*$") {
            $fragNombre = $matches[1]
            $fragPath = Join-Path $fragmentosDir "$fragNombre.md"
            if (-not (Test-Path $fragPath)) {
                Write-Host "Error: No existe el fragmento $fragNombre en $fragmentosDir"
                exit 1
            }
            $fragRaw = Normalizar-Texto (Get-Content -Path $fragPath -Raw -Encoding UTF8)
            $cuerpoResuelto.Add($fragRaw.TrimEnd("`r", "`n"))
        } else {
            $cuerpoResuelto.Add($linea)
        }
    }

    $cuerpoTexto = $cuerpoResuelto -join "`n"

    $encPath = Join-Path $cmdDir $item.Encabezado
    if (-not (Test-Path $encPath)) {
        Write-Host "Error: No existe el encabezado $($item.Encabezado) en $cmdDir"
        exit 1
    }
    $encRaw = Normalizar-Texto (Get-Content -Path $encPath -Raw -Encoding UTF8)
    $encTrimmed = $encRaw.TrimEnd("`r", "`n")

    $contenidoFinal = "${encTrimmed}`n`n${avisoComandosAgente}`n`n" + $cuerpoTexto.TrimStart("`r", "`n")
    $contenidoFinal = (Normalizar-Texto $contenidoFinal).TrimEnd("`r", "`n") + "`n"

    $comandosAgenteGenerados.Add(@{
        Destino = $item.Destino
        Contenido = $contenidoFinal
    })
}

# 3. Validar y generar bloque de .claude/CLAUDE.md en memoria
$fragReglas = Join-Path $fragmentosDir "reglas-ejecucion.md"
if (-not (Test-Path $fragReglas)) {
    Write-Host "Error: No existe el fragmento de reglas en $fragReglas"
    exit 1
}
$fragTxt = Normalizar-Texto (Get-Content -Path $fragReglas -Raw -Encoding UTF8)
$fragSinFinal = $fragTxt.TrimEnd("`n", "`r")

$claudePath = Join-Path $repoRoot ".claude/CLAUDE.md"
if (-not (Test-Path $claudePath)) {
    Write-Host "Error: No existe .claude/CLAUDE.md en $repoRoot"
    exit 1
}
$claudeRaw = Normalizar-Texto (Get-Content -Path $claudePath -Raw -Encoding UTF8)

$marcaInicio = "<!-- inicio: reglas-ejecucion -->"
$marcaFin = "<!-- fin: reglas-ejecucion -->"

$matchesInicio = [regex]::Matches($claudeRaw, [regex]::Escape($marcaInicio))
$matchesFin = [regex]::Matches($claudeRaw, [regex]::Escape($marcaFin))

$claudeNuevo = $null
$bloqueDifiere = $false

if ($Comprobar) {
    if ($matchesInicio.Count -ne 1 -or $matchesFin.Count -ne 1) {
        $bloqueDifiere = $true
    } else {
        $idxInicio = $claudeRaw.IndexOf($marcaInicio)
        $idxFin = $claudeRaw.IndexOf($marcaFin)
        if ($idxFin -le $idxInicio) {
            $bloqueDifiere = $true
        } else {
            $bloqueActual = $claudeRaw.Substring($idxInicio + $marcaInicio.Length, $idxFin - ($idxInicio + $marcaInicio.Length)).Trim("`n", "`r")
            if ($bloqueActual -ne $fragSinFinal) {
                $bloqueDifiere = $true
            }
        }
    }
} else {
    if ($matchesInicio.Count -eq 0) {
        Write-Host "Error: .claude/CLAUDE.md no tiene la marca '$marcaInicio'"
        exit 1
    }
    if ($matchesInicio.Count -gt 1) {
        Write-Host "Error: .claude/CLAUDE.md tiene más de una marca '$marcaInicio'"
        exit 1
    }
    if ($matchesFin.Count -eq 0) {
        Write-Host "Error: .claude/CLAUDE.md no tiene la marca '$marcaFin'"
        exit 1
    }
    if ($matchesFin.Count -gt 1) {
        Write-Host "Error: .claude/CLAUDE.md tiene más de una marca '$marcaFin'"
        exit 1
    }

    $idxInicio = $claudeRaw.IndexOf($marcaInicio)
    $idxFin = $claudeRaw.IndexOf($marcaFin)

    if ($idxFin -le $idxInicio) {
        Write-Host "Error: En .claude/CLAUDE.md la marca de fin está antes que la de inicio"
        exit 1
    }

    $antes = $claudeRaw.Substring(0, $idxInicio + $marcaInicio.Length)
    $despues = $claudeRaw.Substring($idxFin)
    $claudeNuevo = "${antes}`n${fragSinFinal}`n${despues}"
}

# 4. Si se solicitó -Comprobar
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

    $comandosAgenteDifieren = [System.Collections.Generic.List[string]]::new()

    foreach ($ca in $comandosAgenteGenerados) {
        $destPath = Join-Path $repoRoot $ca.Destino
        if (-not (Test-Path $destPath)) {
            $comandosAgenteDifieren.Add($ca.Destino)
            continue
        }
        $actual = Normalizar-Texto (Get-Content -Path $destPath -Raw -Encoding UTF8)
        $gen = Normalizar-Texto $ca.Contenido
        if ($actual -ne $gen) {
            $comandosAgenteDifieren.Add($ca.Destino)
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

    if ($comandosAgenteDifieren.Count -gt 0) {
        Write-Host "Error: Los siguientes comandos del Agente difieren de lo generado desde templates/fuente/comandos-agente/:"
        foreach ($ca in $comandosAgenteDifieren) {
            Write-Host "  - $ca"
        }
    }

    if ($bloqueDifiere) {
        Write-Host "Error: El bloque de reglas de .claude/CLAUDE.md difiere de templates/fuente/fragmentos/reglas-ejecucion.md"
    }

    if ($plantillasDifieren.Count -gt 0 -or $comandosDifieren.Count -gt 0 -or $comandosAgenteDifieren.Count -gt 0 -or $bloqueDifiere) {
        exit 1
    }

    Write-Host "OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados."
    exit 0
}

# 5. Escribir plantillas
foreach ($g in $plantillasGeneradas) {
    $destPath = Join-Path $repoRoot $g.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $g.Contenido
    Write-Host "Generado: $($g.Destino)"
}

# 6. Escribir comandos
foreach ($c in $comandosGenerados) {
    $destPath = Join-Path $repoRoot $c.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $c.Contenido
    Write-Host "Generado: $($c.Destino)"
}

# 6b. Escribir comandos de agente
foreach ($ca in $comandosAgenteGenerados) {
    $destPath = Join-Path $repoRoot $ca.Destino
    Escribir-ArchivoUtf8SinBom -Ruta $destPath -Texto $ca.Contenido
    Write-Host "Generado: $($ca.Destino)"
}

# 7. Escribir .claude/CLAUDE.md
if ($null -ne $claudeNuevo) {
    Escribir-ArchivoUtf8SinBom -Ruta $claudePath -Texto $claudeNuevo
    Write-Host "Generado: .claude/CLAUDE.md"
}
