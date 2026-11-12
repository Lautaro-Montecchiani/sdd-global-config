# tests/sugerir-arquitectura.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

function Normalizar-Contenido {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    return (Get-Content -Path $Path -Raw -Encoding UTF8) -replace "\r\n", "`n"
}

$lineaD1 = 'Sugerencia: corré `/arquitectura` para evaluar la arquitectura del proyecto'

# test-plan: sugerir-arquitectura/S01
Probar "S01 Claude sugiere la skill arquitectura / Inicio de sesión sin nivel" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir $claudePath"
    $txt = Normalizar-Contenido $claudePath

    Afirmar ($txt.Contains($lineaD1)) "$claudePath debe contener la línea de sugerencia D1"
    Afirmar ($txt -match '(?i)(?:sin correrla|no corre la skill)') "$claudePath debe aclarar que sugiere sin correrla"
    Afirmar ($txt -match '(?i)(?:sin escribir|no escribe).*(?:config\.yaml|openspec)') "$claudePath debe aclarar que no escribe en openspec/config.yaml"
    Afirmar ($txt -match '(?i)## Arquitectura.*no declara.*nivel') "$claudePath debe tener el motivo de que no declara nivel"
}

# test-plan: sugerir-arquitectura/S02
Probar "S02 Claude sugiere la skill arquitectura / Propose sin nivel" {
    $archivos = @(
        "$repoRoot/skills/openspec-propose/SKILL.md",
        "$repoRoot/.claude/commands/opsx/propose.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt.Contains($lineaD1)) "$a debe contener la línea de sugerencia D1"
        Afirmar ($txt -match '(?i)(?:no se bloquea|no bloquea|contin[uú]a con todos sus artefactos)') "$a debe indicar que el propose no se bloquea por falta de nivel"
        Afirmar ($txt -match '(?i)## Arquitectura.*no declara.*nivel') "$a debe tener el motivo de que no declara nivel"
    }
}

# test-plan: sugerir-arquitectura/S03
Probar "S03 Claude sugiere la skill arquitectura / Verify con un archivo sobre la advertencia" {
    $archivos = @(
        "$repoRoot/skills/openspec-verify-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/verify.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt.Contains("Sugerencias de arquitectura")) "$a debe tener la sección o bloque 'Sugerencias de arquitectura'"
        Afirmar ($txt.Contains($lineaD1)) "$a debe contener la línea de sugerencia D1"
        Afirmar ($txt -match '(?i)sobre la advertencia de `?tamaño`?') "$a debe tener el motivo de archivo sobre la advertencia de tamaño"
        Afirmar ($txt -match '(?i)(?:no cambia severidades|no cuenta como desv[íi]o|no afecta.*evaluaci[oó]n final)') "$a debe aclarar que la sugerencia no cambia severidades ni es un desvío"

        # Verificar presencia en método legacy
        $mLegacy = [regex]::Match($txt, "(?ms)Legacy method.*")
        Afirmar ($mLegacy.Success -and $mLegacy.Value.Contains("Sugerencias de arquitectura")) "$a debe incluir 'Sugerencias de arquitectura' en el método legacy"
    }
}

# test-plan: sugerir-arquitectura/S04
Probar "S04 Claude sugiere la skill arquitectura / Archive con nivel sin evaluar" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt.Contains($lineaD1)) "$a debe contener la línea de sugerencia D1"
        Afirmar ($txt -match '(?i)`?arquitectura\.md`? qued[oó] en sin evaluar') "$a debe tener el motivo de arquitectura.md quedó en sin evaluar"
    }
}

# test-plan: sugerir-arquitectura/S05
Probar "S05 Claude sugiere la skill arquitectura / Proyecto con nivel declarado" {
    $configPath = "$repoRoot/openspec/config.yaml"
    Afirmar (Test-Path $configPath) "Debe existir $configPath"
    $configTxt = Normalizar-Contenido $configPath

    Afirmar ($configTxt -match '(?m)^\s*-?\s*nivel:\s*0\b') "$configPath debe declarar nivel: 0"
    Afirmar ($configTxt -match '(?m)^\s*-?\s*tamaño:\s*500,\s*1000\b') "$configPath debe declarar tamaño: 500, 1000"

    $fuentes = @(
        "$repoRoot/.claude/CLAUDE.md",
        "$repoRoot/skills/openspec-propose/SKILL.md",
        "$repoRoot/skills/openspec-verify-change/SKILL.md",
        "$repoRoot/skills/openspec-archive-change/SKILL.md"
    )

    foreach ($f in $fuentes) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Normalizar-Contenido $f
        Afirmar ($txt -match '(?i)(?:si falta nivel|sin nivel|falta `?nivel`?|solo si|condicion|ninguna operaci[oó]n sugiere|no sugiere)') "$f debe condicionar la sugerencia (no sugerir con nivel válido y sin advertencias)"
        Afirmar ($txt.Contains($lineaD1)) "$f debe contener la línea D1 para poder condicionarla"
    }
}

# test-plan: sugerir-arquitectura/S06
Probar "S06 Claude sugiere la skill arquitectura / Dato inválido: nivel desconocido" {
    $archivos = @(
        "$repoRoot/.claude/CLAUDE.md",
        "$repoRoot/skills/openspec-propose/SKILL.md",
        "$repoRoot/.claude/commands/opsx/propose.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)no corresponde a ninguna receta') "$a debe tener el motivo 'no corresponde a ninguna receta'"
        Afirmar ($txt -match '(?i)(?:no corrige|no corregir|no cambiar.*por su cuenta)') "$a debe indicar que no corrige el valor por su cuenta"
    }
}

# test-plan: sugerir-arquitectura/S07
Probar "S07 ADR y visión" {
    $adrPath = "$repoRoot/docs/adr/0003-nivel-0-para-sdd-global-config.md"
    Afirmar (Test-Path $adrPath) "Debe existir $adrPath"
    $adrTxt = Normalizar-Contenido $adrPath
    Afirmar ($adrTxt -match '(?i)Estado:\s*aceptada') "$adrPath debe tener 'Estado: aceptada'"

    $visionPath = "$repoRoot/docs/arquitectura/vision.md"
    Afirmar (Test-Path $visionPath) "Debe existir $visionPath"
    $visTxt = Normalizar-Contenido $visionPath

    Afirmar ($visTxt.Contains("0003-nivel-0-para-sdd-global-config.md")) "$visionPath debe enlazar al ADR 0003"
    Afirmar (-not ($visTxt -match '(?i)## Arquitectura.*no declara.*nivel')) "$visionPath ya no debe contener la deuda de que no declara nivel"
    Afirmar ($visTxt -match '(?i)scripts/instalar\.ps1.*(?:500 l[íi]neas|umbral de aviso|ADR 0003)') "$visionPath debe contener la deuda de scripts/instalar.ps1"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
