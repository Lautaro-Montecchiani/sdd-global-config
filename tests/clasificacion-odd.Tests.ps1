# tests/clasificacion-odd.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$antesPrCheck = "$PSScriptRoot/datos/pr-check-antes.yml"

function Quitar-PasoCheckBranch {
    param([string]$Texto)
    $norm = $Texto -replace "\r\n", "`n"
    return [regex]::Replace($norm, "(?ms)^[ \t]*- name: Check branch name\n.*?(?=^[ \t]*- name:)", "")
}

function Quitar-Frontmatter {
    param([string]$Texto)
    if ($Texto -match "(?s)^---\n.*?\n---\n*(.*)$") {
        return $matches[1].Trim()
    }
    return $Texto.Trim()
}

function Extraer-Seccion {
    param([string]$Texto, [string]$Titulo)
    $patronSiguiente = '(?ms)^## (?:Inicio|Verify|Cierre|Escalado)|\Z'
    $m = [regex]::Match($Texto, "(?ms)^## $([regex]::Escape($Titulo))\n\n(.*?)(?=$patronSiguiente)")
    if ($m.Success) {
        return $m.Groups[1].Value.Trim()
    }
    return ""
}

# test-plan: clasificacion-odd-sdd/C02
Probar "C02 pr-check sin cambios fuera del paso de branch" {
    Afirmar (Test-Path $antesPrCheck) "Debe existir tests/datos/pr-check-antes.yml"
    $actual = Get-Content -Path "$repoRoot/.github/workflows/pr-check.yml" -Raw -Encoding UTF8
    $antes = Get-Content -Path $antesPrCheck -Raw -Encoding UTF8
    $limpioActual = Quitar-PasoCheckBranch $actual
    $limpioAntes = Quitar-PasoCheckBranch $antes
    Afirmar ($limpioActual -eq $limpioAntes) "pr-check.yml sin el paso de branch debe ser idéntico a pr-check-antes.yml"
}

# test-plan: clasificacion-odd-sdd/S16
Probar "S16 plantillas incluyen handoff ODD desde la fuente" {
    $frag = "$repoRoot/templates/fuente/fragmentos/handoff-odd.md"
    Afirmar (Test-Path $frag) "Debe existir templates/fuente/fragmentos/handoff-odd.md"

    $plantillas = @(
        "$repoRoot/templates/comun/AGENTS.md",
        "$repoRoot/templates/copilot/copilot-instructions.md",
        "$repoRoot/templates/cursor/sdd-workflow.mdc",
        "$repoRoot/templates/antigravity/GEMINI.md"
    )

    $cuerpos = @()
    foreach ($p in $plantillas) {
        Afirmar (Test-Path $p) "Debe existir plantilla $p"
        $txt = (Get-Content -Path $p -Raw -Encoding UTF8) -replace "\r\n", "`n"
        
        $matchesHandoff = [regex]::Matches($txt, "(?m)^## Handoff ODD$")
        Afirmar ($matchesHandoff.Count -eq 1) "$p debe contener exactamente una vez '## Handoff ODD'"

        $idxReglas = $txt.IndexOf("## Reglas de ejecución (obligatorias)")
        $idxHandoff = $txt.IndexOf("## Handoff ODD")
        Afirmar ($idxReglas -ge 0 -and $idxHandoff -gt $idxReglas) "$p debe tener '## Handoff ODD' después de '## Reglas de ejecución (obligatorias)'"

        $matchCuerpo = [regex]::Match($txt, "(?ms)^## Handoff ODD\n\n(.*?)(?=\n## |\Z)")
        Afirmar ($matchCuerpo.Success) "$p debe tener cuerpo de la sección Handoff ODD"
        $cuerpo = $matchCuerpo.Groups[1].Value.Trim()
        $cuerpos += $cuerpo

        Afirmar ($cuerpo.Contains("docs/odd/<nombre>.md")) "$p cuerpo debe mencionar 'docs/odd/<nombre>.md'"
        Afirmar ($cuerpo.Contains("odd/<nombre>")) "$p cuerpo debe mencionar 'odd/<nombre>'"
        Afirmar ($cuerpo.Contains("## Evidencia")) "$p cuerpo debe mencionar '## Evidencia'"
        Afirmar ($cuerpo.Contains("escalar a SDD")) "$p cuerpo debe mencionar 'escalar a SDD'"
        Afirmar ($cuerpo.Contains("Spec-ID: odd-<nombre>")) "$p cuerpo debe mencionar 'Spec-ID: odd-<nombre>'"
    }

    for ($i = 1; $i -lt $cuerpos.Count; $i++) {
        Afirmar ($cuerpos[$i] -eq $cuerpos[0]) "El cuerpo de Handoff ODD debe ser idéntico entre las plantillas"
    }
}

# test-plan: clasificacion-odd-sdd/S17
Probar "S17 CI acepta branch odd" {
    $prCheckPath = "$repoRoot/.github/workflows/pr-check.yml"
    Afirmar (Test-Path $prCheckPath) "Debe existir pr-check.yml"
    $txt = (Get-Content -Path $prCheckPath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    $matchStep = [regex]::Match($txt, "(?ms)- name: Check branch name\n.*?(?=- name:|\Z)")
    Afirmar ($matchStep.Success) "Debe existir el paso 'Check branch name' en pr-check.yml"
    $stepTxt = $matchStep.Value

    Afirmar ($stepTxt.Contains("'change/'")) "Check branch name debe contener 'change/'"
    Afirmar ($stepTxt.Contains("'odd/'")) "Check branch name debe contener 'odd/'"
    Afirmar ($stepTxt.Contains("change/{nombre-change}")) "Error de Check branch name debe contener 'change/{nombre-change}'"
    Afirmar ($stepTxt.Contains("odd/{nombre}")) "Error de Check branch name debe contener 'odd/{nombre}'"
}

# test-plan: clasificacion-odd-sdd/S18
Probar "S18 reglas documentadas en CLAUDE.md y config.yaml" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir .claude/CLAUDE.md"
    $claudeTxt = (Get-Content -Path $claudePath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    $idxGlobales = $claudeTxt.IndexOf("## Reglas globales (obligatorias)")
    $idxOdd = $claudeTxt.IndexOf("## Clasificación ODD / SDD")
    Afirmar ($idxGlobales -ge 0 -and $idxOdd -gt $idxGlobales) ".claude/CLAUDE.md debe contener '## Clasificación ODD / SDD' después de '## Reglas globales (obligatorias)'"

    for ($k = 1; $k -le 10; $k++) {
        Afirmar ($claudeTxt -match "(?m)\|[ \t]*K$k[ \t]*\|") ".claude/CLAUDE.md debe contener la fila K$k en la tabla de clasificación"
    }

    $configPath = "$repoRoot/openspec/config.yaml"
    Afirmar (Test-Path $configPath) "Debe existir openspec/config.yaml"
    $configTxt = (Get-Content -Path $configPath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    Afirmar ($configTxt.Contains("documento ODD aprobado")) "config.yaml debe contener 'documento ODD aprobado'"
    Afirmar ($configTxt.Contains("ODD: flujo liviano para cambios")) "config.yaml debe contener la entrada ODD en el glosario"
    Afirmar ($configTxt.Contains("Clasificación: decisión ODD o SDD")) "config.yaml debe contener la entrada Clasificación en el glosario"
    Afirmar ($configTxt.Contains("Escalado: paso de un ODD a SDD")) "config.yaml debe contener la entrada Escalado en el glosario"
    Afirmar ($configTxt.Contains("Setup de máquina: clonar el repo y el vault y correr scripts/instalar.ps1")) "config.yaml debe tener la línea Setup de máquina actualizada"
}

# test-plan: srs-en-rama-del-change/S16
# test-plan: clasificacion-odd-sdd/S19
Probar "S19 puerta y merge en ODD" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir .claude/CLAUDE.md"
    $claudeTxt = (Get-Content -Path $claudePath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    $matchPR = [regex]::Match($claudeTxt, "(?ms)^### Pull Requests\n.*?(?=^###? [^#]|\Z)")
    Afirmar ($matchPR.Success -and $matchPR.Value.Contains("no aplica (ODD)")) "### Pull Requests en CLAUDE.md debe contener 'no aplica (ODD)'"

    $matchPuerta = [regex]::Match($claudeTxt, "(?ms)^## Puerta de integración\n.*?(?=^## [^#]|\Z)")
    Afirmar ($matchPuerta.Success -and $matchPuerta.Value.Contains("no aplica (ODD)")) "## Puerta de integración en CLAUDE.md debe contener 'no aplica (ODD)'"

    $branchPrPath = "$repoRoot/skills/branch-pr/SKILL.md"
    Afirmar (Test-Path $branchPrPath) "Debe existir skills/branch-pr/SKILL.md"
    $branchPrTxt = (Get-Content -Path $branchPrPath -Raw -Encoding UTF8) -replace "\r\n", "`n"
    Afirmar ($branchPrTxt.Contains("dato inesperado no aplica en ODD")) "skills/branch-pr/SKILL.md debe contener 'dato inesperado no aplica en ODD'"
}

# test-plan: clasificacion-odd-sdd/S20
Probar "S20 regla 7 con excepción ODD" {
    $oracionClaude = 'En un handoff ODD, la evidencia va en ## Evidencia del documento ODD y no se escribe la nota apply\ del vault.'
    $oracionAgente = 'En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault.'

    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    $claudeTxt = (Get-Content -Path $claudePath -Raw -Encoding UTF8) -replace "\r\n", "`n"
    $matchRegla7Claude = [regex]::Match($claudeTxt, "(?m)^7\.\s+\*\*Resumen final con evidencia:\*\*.*$")
    Afirmar ($matchRegla7Claude.Success) "Debe existir la regla 7 en .claude/CLAUDE.md"
    Afirmar ($matchRegla7Claude.Value.TrimEnd().EndsWith($oracionAgente)) ".claude/CLAUDE.md regla 7 debe terminar con la oración de D12"

    $fragReglasPath = "$repoRoot/templates/fuente/fragmentos/reglas-ejecucion.md"
    Afirmar (Test-Path $fragReglasPath) "Debe existir templates/fuente/fragmentos/reglas-ejecucion.md"
    $fragTxt = (Get-Content -Path $fragReglasPath -Raw -Encoding UTF8) -replace "\r\n", "`n"
    $matchRegla7Frag = [regex]::Match($fragTxt, "(?m)^7\.\s+\*\*Resumen final con evidencia:\*\*.*$")
    Afirmar ($matchRegla7Frag.Success) "Debe existir la regla 7 en fragmento reglas-ejecucion.md"
    Afirmar ($matchRegla7Frag.Value.TrimEnd().EndsWith($oracionAgente)) "Fragmento reglas-ejecucion.md regla 7 debe terminar con la oración de D13"

    $plantillas = @(
        "$repoRoot/templates/comun/AGENTS.md",
        "$repoRoot/templates/copilot/copilot-instructions.md",
        "$repoRoot/templates/cursor/sdd-workflow.mdc",
        "$repoRoot/templates/antigravity/GEMINI.md"
    )
    foreach ($p in $plantillas) {
        $ptxt = (Get-Content -Path $p -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $matchP = [regex]::Match($ptxt, "(?m)^7\.\s+\*\*Resumen final con evidencia:\*\*.*$")
        Afirmar ($matchP.Success) "$p debe contener la regla 7"
        Afirmar ($matchP.Value.TrimEnd().EndsWith($oracionAgente)) "$p regla 7 debe terminar con la oración de D13"
    }
}

# test-plan: clasificacion-odd-sdd/S25
Probar "S25 comandos ODD iguales a la skill" {
    $skillPath = "$repoRoot/skills/odd-change/SKILL.md"
    Afirmar (Test-Path $skillPath) "Debe existir skills/odd-change/SKILL.md"
    $skillTxt = (Get-Content -Path $skillPath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    $secInicio = Extraer-Seccion $skillTxt 'Inicio (`/odd`)'
    $secVerify = Extraer-Seccion $skillTxt 'Verify (`/odd:verify`)'
    $secClose = Extraer-Seccion $skillTxt 'Cierre (`/odd:close`)'
    $secEscalado = Extraer-Seccion $skillTxt 'Escalado'

    Afirmar ($secInicio -ne "") "skills/odd-change/SKILL.md debe tener sección 'Inicio (`/odd`)'"
    Afirmar ($secVerify -ne "") "skills/odd-change/SKILL.md debe tener sección 'Verify (`/odd:verify`)'"
    Afirmar ($secClose -ne "") "skills/odd-change/SKILL.md debe tener sección 'Cierre (`/odd:close`)'"
    Afirmar ($secEscalado -ne "") "skills/odd-change/SKILL.md debe tener sección 'Escalado'"

    $startPath = "$repoRoot/.claude/commands/odd/start.md"
    $verifyPath = "$repoRoot/.claude/commands/odd/verify.md"
    $closePath = "$repoRoot/.claude/commands/odd/close.md"
    $oddPath = "$repoRoot/.claude/commands/odd.md"

    Afirmar (Test-Path $startPath) "Debe existir .claude/commands/odd/start.md"
    Afirmar (Test-Path $verifyPath) "Debe existir .claude/commands/odd/verify.md"
    Afirmar (Test-Path $closePath) "Debe existir .claude/commands/odd/close.md"
    Afirmar (Test-Path $oddPath) "Debe existir .claude/commands/odd.md"

    $startTxt = Quitar-Frontmatter ((Get-Content -Path $startPath -Raw -Encoding UTF8) -replace "\r\n", "`n")
    $verifyTxt = Quitar-Frontmatter ((Get-Content -Path $verifyPath -Raw -Encoding UTF8) -replace "\r\n", "`n")
    $closeTxt = Quitar-Frontmatter ((Get-Content -Path $closePath -Raw -Encoding UTF8) -replace "\r\n", "`n")
    $oddTxt = (Get-Content -Path $oddPath -Raw -Encoding UTF8) -replace "\r\n", "`n"
    $startFullTxt = (Get-Content -Path $startPath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    Afirmar ($startTxt.Contains($secInicio)) "odd/start.md debe contener el texto de Inicio"
    Afirmar ($startTxt.Contains($secEscalado)) "odd/start.md debe contener el texto de Escalado"
    Afirmar ($verifyTxt.Contains($secVerify)) "odd/verify.md debe contener el texto de Verify"
    Afirmar ($verifyTxt.Contains($secEscalado)) "odd/verify.md debe contener el texto de Escalado"
    Afirmar ($closeTxt.Contains($secClose)) "odd/close.md debe contener el texto de Cierre"
    Afirmar ($oddTxt -eq $startFullTxt) ".claude/commands/odd.md debe ser exactamente igual a .claude/commands/odd/start.md"
}

# test-plan: srs-en-rama-del-change/S16
# test-plan: clasificacion-odd-sdd/S31
Probar "S31 reglas de D21 para ODD con cambio mínimo de spec" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir .claude/CLAUDE.md"
    $claudeTxt = (Get-Content -Path $claudePath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    $matchK1 = [regex]::Match($claudeTxt, "(?m)^\|[ \t]*K1[ \t]*\|(.*?)\|(.*?)\|$")
    Afirmar ($matchK1.Success) ".claude/CLAUDE.md debe contener la fila K1"
    $colPasa = $matchK1.Groups[2].Value.Trim()
    Afirmar ($colPasa.Contains("**no**")) "La fila K1 debe tener **no** en la columna de pasar a ODD"
    $colCriterio = $matchK1.Groups[1].Value.Trim()
    Afirmar ($colCriterio.Contains("una sola capability") -or $colCriterio.Contains("única capability")) "La fila K1 debe mencionar la modificación de una sola capability"

    $skillPath = "$repoRoot/skills/odd-change/SKILL.md"
    Afirmar (Test-Path $skillPath) "Debe existir skills/odd-change/SKILL.md"
    $skillTxt = (Get-Content -Path $skillPath -Raw -Encoding UTF8) -replace "\r\n", "`n"
    Afirmar ($skillTxt.Contains("openspec/changes/odd-<nombre>/")) "SKILL.md debe contener 'openspec/changes/odd-<nombre>/'"
    Afirmar ($skillTxt.Contains("## MODIFIED Requirements")) "SKILL.md debe contener '## MODIFIED Requirements'"
    Afirmar ($skillTxt.Contains("openspec validate odd-<nombre> --strict")) "SKILL.md debe contener 'openspec validate odd-<nombre> --strict'"
    Afirmar ($skillTxt.Contains("openspec archive odd-<nombre> -y")) "SKILL.md debe contener 'openspec archive odd-<nombre> -y'"

    $fragHandoff = "$repoRoot/templates/fuente/fragmentos/handoff-odd.md"
    Afirmar (Test-Path $fragHandoff) "Debe existir templates/fuente/fragmentos/handoff-odd.md"
    $fragTxt = (Get-Content -Path $fragHandoff -Raw -Encoding UTF8) -replace "\r\n", "`n"
    Afirmar ($fragTxt -match '(?m)No edites `?openspec/`? en un ODD') "handoff-odd.md debe decir que el Agente no edita openspec/ en un ODD"
    Afirmar (-not ($fragTxt -match '[\x00-\x08\x0B\x0C\x0E-\x1F]')) "handoff-odd.md no debe tener caracteres de control (backticks interpretados como escapes)"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
