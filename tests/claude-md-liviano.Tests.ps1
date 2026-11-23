# tests/claude-md-liviano.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$claudePath = Join-Path $repoRoot ".claude/CLAUDE.md"
$readmePath = Join-Path $repoRoot "README.md"
$fichaSkillPath = Join-Path $repoRoot "skills/ficha/SKILL.md"
$recetasPath = Join-Path $repoRoot "skills/arquitectura/references/recetas.md"
$oddSkillPath = Join-Path $repoRoot "skills/odd-change/SKILL.md"

function Leer-Normalizado {
    param([string]$Ruta)
    return ((Get-Content -Path $Ruta -Raw -Encoding UTF8) -replace "\r\n", "`n")
}

function Extraer-Seccion {
    param(
        [string]$Texto,
        [string]$Encabezado,
        [string]$Nivel = "##"
    )
    $esc = [regex]::Escape($Encabezado)
    $patron = "(?ms)^$esc\n(.*?)(?=^$Nivel |\z)"
    $m = [regex]::Match($Texto, $patron)
    if ($m.Success) {
        return $m.Groups[1].Value
    }
    return ""
}

# test-plan: claude-md-liviano/S01
Probar "S01 Detalle operativo fuera del CLAUDE.md global / Una sola sección de OpenSpec" {
    $claude = Leer-Normalizado $claudePath
    $matchesModo = [regex]::Matches($claude, '(?m)^## Modo OpenSpec \(cuando `openspec` CLI está disponible\)$')
    Afirmar ($matchesModo.Count -eq 1) "Debe haber exactamente una sección '## Modo OpenSpec (cuando ``openspec`` CLI está disponible)', encontradas: $($matchesModo.Count)"
    Afirmar (-not ($claude -match '(?m)^## Flujo OpenSpec')) "No debe existir ninguna sección '## Flujo OpenSpec'"

    $sec = Extraer-Seccion -Texto $claude -Encabezado '## Modo OpenSpec (cuando `openspec` CLI está disponible)' -Nivel "##"
    Afirmar ($sec.Contains('openspec status --change "{nombre}" --json')) "La sección debe incluir 'openspec status --change `"{nombre}`" --json'"
    Afirmar ($sec.Contains('openspec/changes/{nombre}/')) "La sección debe incluir 'openspec/changes/{nombre}/'"
    Afirmar ($sec.Contains('/opsx:apply')) "La sección debe incluir '/opsx:apply'"
    Afirmar ($sec -match 'specs/`\s+legacy') "La sección debe incluir 'specs/ legacy'"
}

# test-plan: claude-md-liviano/S02
Probar "S02 Detalle operativo fuera del CLAUDE.md global / Comandos del vault en el README" {
    $claude = Leer-Normalizado $claudePath
    Afirmar (-not $claude.Contains('```powershell')) "CLAUDE.md no debe contener bloques '```powershell'"
    Afirmar ($claude.Contains('Comandos del vault')) "CLAUDE.md debe nombrar 'Comandos del vault'"

    $readme = Leer-Normalizado $readmePath
    Afirmar ($readme -match '(?m)^## Comandos del vault$') "README.md debe tener la sección '## Comandos del vault'"
    $sec = Extraer-Seccion -Texto $readme -Encabezado '## Comandos del vault' -Nivel "##"
    foreach ($texto in @(
        'context.md',
        'decisions\YYYY-MM-DD-{change}.md',
        '$vault\projects\$p\archive',
        'YYYY-MM-DD-{change}.md',
        'AAAA-MM-DD-odd-{nombre}.md',
        "'status: activo', 'status: archivado'",
        'Remove-Item',
        'instalar.ps1'
    )) {
        Afirmar ($sec.Contains($texto)) "La sección '## Comandos del vault' de README.md debe incluir: $texto"
    }
}

# test-plan: claude-md-liviano/S03
Probar "S03 Detalle operativo fuera del CLAUDE.md global / Ejemplos de la ficha en la skill" {
    $claude = Leer-Normalizado $claudePath
    $sec = Extraer-Seccion -Texto $claude -Encabezado '## Ficha del proyecto' -Nivel "##"
    Afirmar ($sec.Length -gt 0) "Debe existir '## Ficha del proyecto' en CLAUDE.md"
    Afirmar (-not $sec.Contains('```yaml')) "'## Ficha del proyecto' no debe contener bloques '```yaml'"
    foreach ($texto in @('## Alcance', '## Datos', '## Stack', '## Calidad', '/ficha')) {
        Afirmar ($sec.Contains($texto)) "'## Ficha del proyecto' debe nombrar '$texto'"
    }

    $ficha = Leer-Normalizado $fichaSkillPath
    foreach ($ejemplo in @(
        '- versión: V1',
        '- leads (nombre, teléfono, email): formulario web (externo) | personal',
        '- framework: FastAPI',
        '- rendimiento: respuesta de la API < 500 ms p95 | alta'
    )) {
        Afirmar ($ficha.Contains($ejemplo)) "skills/ficha/SKILL.md debe contener el ejemplo: $ejemplo"
    }
}

# test-plan: claude-md-liviano/S04
Probar "S04 Detalle operativo fuera del CLAUDE.md global / Escalera en las recetas" {
    $claude = Leer-Normalizado $claudePath
    $sec = Extraer-Seccion -Texto $claude -Encabezado '### Escalera de niveles' -Nivel "###"
    Afirmar ($sec.Length -gt 0) "Debe existir '### Escalera de niveles' en CLAUDE.md"
    Afirmar (-not ($sec -match '(?m)^\|')) "'### Escalera de niveles' no debe tener líneas que empiecen con '|'"
    Afirmar ($sec.Contains('recetas.md')) "'### Escalera de niveles' debe nombrar 'recetas.md'"

    $niveles = @('0', '1-nucleo-funcional', '2-tuberias', '2-capas', '3-hexagonal', '3-modular')
    foreach ($n in $niveles) {
        Afirmar ($sec.Contains($n)) "'### Escalera de niveles' debe nombrar el nivel '$n'"
    }

    $recetas = Leer-Normalizado $recetasPath
    foreach ($n in $niveles) {
        Afirmar ($recetas.Contains("| ``$n`` |")) "recetas.md debe tener una fila para el nivel '$n'"
    }
    foreach ($n in $niveles[1..($niveles.Length - 1)]) {
        $secNivel = Extraer-Seccion -Texto $recetas -Encabezado "## $n" -Nivel "##"
        Afirmar ($secNivel.Contains('**Señales**')) "recetas.md debe tener '**Señales**' en la sección '## $n'"
    }
}

# test-plan: claude-md-liviano/S05
Probar "S05 Detalle operativo fuera del CLAUDE.md global / Flujo ODD en la skill" {
    $claude = Leer-Normalizado $claudePath
    $sec = Extraer-Seccion -Texto $claude -Encabezado '## Clasificación ODD / SDD' -Nivel "##"
    Afirmar ($sec.Length -gt 0) "Debe existir '## Clasificación ODD / SDD' en CLAUDE.md"
    Afirmar (-not $sec.Contains('### Flujo ODD resumido')) "No debe existir '### Flujo ODD resumido' en CLAUDE.md"
    Afirmar (-not $sec.Contains('### Escalado a SDD')) "No debe existir '### Escalado a SDD' en CLAUDE.md"
    foreach ($texto in @('odd-change', 'odd/<nombre>', '/odd:close', 'estado: escalado', 'no se mergea', '/opsx:propose <nombre>')) {
        Afirmar ($sec.Contains($texto)) "'## Clasificación ODD / SDD' debe contener '$texto'"
    }

    $odd = Leer-Normalizado $oddSkillPath
    foreach ($texto in @('estado: escalado', 'no se mergea', 'ODD `<nombre>` escalado a SDD', '/opsx:propose <nombre>')) {
        Afirmar ($odd.Contains($texto)) "skills/odd-change/SKILL.md debe contener '$texto'"
    }
}

# test-plan: claude-md-liviano/S06
Probar "S06 Detalle operativo fuera del CLAUDE.md global / Espejo del vault en el README" {
    $claude = Leer-Normalizado $claudePath
    Afirmar ($claude.Contains('solo `scripts/instalar.ps1` escribe el espejo')) "CLAUDE.md debe indicar que solo scripts/instalar.ps1 escribe el espejo"
    Afirmar ($claude.Contains('Espejo del vault')) "CLAUDE.md debe nombrar 'Espejo del vault'"

    $readme = Leer-Normalizado $readmePath
    Afirmar ($readme -match '(?m)^## Espejo del vault$') "README.md debe tener la sección '## Espejo del vault'"
    $sec = Extraer-Seccion -Texto $readme -Encabezado '## Espejo del vault' -Nivel "##"
    foreach ($texto in @('-Forzar', 'commit:', 'instalacion:')) {
        Afirmar ($sec.Contains($texto)) "La sección '## Espejo del vault' de README.md debe contener '$texto'"
    }
}

# test-plan: claude-md-liviano/S07
Probar "S07 El detalle operativo nuevo va en la skill o en el README / Regla de dónde va el detalle" {
    $claude = Leer-Normalizado $claudePath
    $sec = Extraer-Seccion -Texto $claude -Encabezado '### Fuente de las reglas: repo `sdd-global-config`' -Nivel "###"
    Afirmar ($sec.Length -gt 0) "Debe existir '### Fuente de las reglas: repo ``sdd-global-config``' en CLAUDE.md"
    $regla = 'El detalle operativo de un flujo (pasos, comandos y ejemplos) va en la skill que lo usa o en el README'
    Afirmar ($sec.Contains($regla)) "La sección debe contener: $regla"
}

if ($script:HayFallas) { exit 1 }
