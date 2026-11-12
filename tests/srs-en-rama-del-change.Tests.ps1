# tests/srs-en-rama-del-change.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

function Normalizar-Contenido {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    return (Get-Content -Path $Path -Raw -Encoding UTF8) -replace "\r\n", "`n"
}

# test-plan: srs-en-rama-del-change/S01
Probar "S01 Archive en la rama antes del merge / Archive en la rama del change" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)change/<(?:nombre|name)>') "$a debe nombrar la rama change/<nombre>"
        Afirmar ($txt -match '(?i)chore:\s*archive\s+<(?:nombre|name)>') "$a debe nombrar el commit chore: archive <nombre>"
        Afirmar ($txt -match '(?i)Spec-ID:\s*<(?:nombre|name)>') "$a debe nombrar el trailer Spec-ID: <nombre>"
        Afirmar ($txt.Contains("git diff --staged")) "$a debe requerir git diff --staged antes del commit"
        Afirmar ($txt -match '(?i)(?:preguntar|confirmaci[oó]n|pregunta).*(?:git push|pushear)') "$a debe requerir confirmación antes de git push"
    }
}

# test-plan: srs-en-rama-del-change/S02
Probar "S02 Archive en la rama antes del merge / Fuera de la rama del change" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)(?:fuera de la rama|rama actual tiene que ser|frena.*rama.*change)') "$a debe frenar fuera de la rama del change"
    }
}

# test-plan: srs-en-rama-del-change/S03
Probar "S03 Archive en la rama antes del merge / Verify sin aprobar" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)(?:verify aprobado|AskUserQuestion.*verify|confirmaci[oó]n.*verify)') "$a debe controlar o preguntar por el verify aprobado"
        Afirmar ($txt -match '(?i)(?:sin confirmaci[oó]n.*frena|frena sin mover ni commitear)') "$a debe frenar si no se confirma el verify"
    }
}

# test-plan: srs-en-rama-del-change/S04
Probar "S04 Change mergeado sin archivar / Change del flujo anterior" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)change/<(?:nombre|name)>-archive') "$a debe nombrar la rama change/<nombre>-archive"
        Afirmar ($txt.Contains("/branch-pr")) "$a debe pedir abrir el PR con /branch-pr"
    }
}

# test-plan: srs-en-rama-del-change/S05
Probar "S05 Cierre en el vault después del merge / Cierre después del merge" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)(?:no crea commits en el repo|no realiza commits en el repositorio|no crear commits en el repo)') "$a debe especificar que la fase del vault no crea commits en el repo"
    }
}

# test-plan: srs-en-rama-del-change/S06
Probar "S06 Cierre en el vault después del merge / PR sin mergear" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt.Contains("falta el merge") -or $txt -match '(?i)(?:frena.*falta el merge|PR abierto.*frena)') "$a debe frenar con 'falta el merge' si el PR sigue abierto"
    }
}

# test-plan: srs-en-rama-del-change/S07
Probar "S07 Cierre en el vault después del merge / Dato inválido: config sin calidad ni nivel" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)Fase del vault|Fase 2|Vault phase') "$a debe definir explícitamente la fase del vault"
        Afirmar ($txt.Contains("sin declarar")) "$a debe escribir 'sin declarar' cuando falta calidad"
        Afirmar ($txt.Contains("sin evaluar")) "$a debe escribir 'sin evaluar' cuando falta nivel"
    }
}

# test-plan: srs-en-rama-del-change/S08
Probar "S08 Orden documentado en reglas y guías / Reglas de Git" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir .claude/CLAUDE.md"
    $txt = Normalizar-Contenido $claudePath

    Afirmar (-not $txt.Contains("El archive se ejecuta después del merge, nunca antes")) "CLAUDE.md ya no debe decir 'El archive se ejecuta después del merge, nunca antes'"
    Afirmar ($txt.Contains('El archive de specs (sync, move y SRS) se ejecuta en la rama del change después del verify aprobado y antes del merge; el cierre en el vault (`/opsx:archive` de nuevo) se ejecuta después del merge, nunca antes. El cambio mínimo de spec de un ODD se archiva en su branch durante `/odd:verify`.')) "CLAUDE.md debe contener el texto de D7 para Pull Requests"
    Afirmar ($txt.Contains("y con el archive hecho en la rama")) "CLAUDE.md debe incluir 'y con el archive hecho en la rama' en la condición de merge"
    Afirmar ($txt.Contains('rama: actualiza `context.md` (pendiente de merge) · después del merge: `archive\…` + reescribe `arquitectura.md` + actualiza `context.md`')) "CLAUDE.md tabla Cuándo actuar debe reflejar las dos fases de /opsx:archive"
}

# test-plan: srs-en-rama-del-change/S09
Probar "S09 Orden documentado en reglas y guías / Guías, verify y checklist del PR" {
    $verifyArchivos = @(
        "$repoRoot/skills/openspec-verify-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/verify.md"
    )
    foreach ($v in $verifyArchivos) {
        Afirmar (Test-Path $v) "Debe existir $v"
        $vTxt = Normalizar-Contenido $v
        Afirmar ($vTxt.Contains('Próximo paso: `/opsx:archive <nombre>` en la rama `change/<nombre>`, antes del merge')) "$v debe incluir el próximo paso en Ready for archive"
    }

    $branchPrPath = "$repoRoot/skills/branch-pr/SKILL.md"
    Afirmar (Test-Path $branchPrPath) "Debe existir skills/branch-pr/SKILL.md"
    $bTxt = Normalizar-Contenido $branchPrPath
    Afirmar ($bTxt.Contains("Archive hecho en la rama (specs sincronizadas y SRS si corresponde)")) "branch-pr debe incluir checklist de archive en la rama"
    Afirmar ($bTxt.Contains("y del archive en la rama")) "branch-pr debe incluir 'y del archive en la rama' en las instrucciones de merge"
    Afirmar ($bTxt -match 'openspec/changes/archive/\*-(?:\{nombre\}|<nombre>)') "branch-pr paso 2 debe aceptar openspec/changes/archive/*-{nombre}/"
    Afirmar ($bTxt -match 'change/\{nombre\}-archive|change/<nombre>-archive') "branch-pr debe contemplar rama change/{nombre}-archive"

    $guias = @(
        "$repoRoot/README.md",
        "$repoRoot/docs/workflow.md",
        "$repoRoot/docs/modo-de-uso.md"
    )
    foreach ($g in $guias) {
        Afirmar (Test-Path $g) "Debe existir $g"
        $gTxt = Normalizar-Contenido $g
        Afirmar (-not ($gTxt -match '\(post-merge\)')) "$g no debe contener '(post-merge)' para el archive de specs"
        Afirmar ($gTxt -match '(?i)en la rama, antes del merge|antes del merge.*cierre.*despu[eé]s') "$g debe reflejar el archive en la rama antes del merge"
    }
}

# test-plan: srs-en-rama-del-change/S10
Probar "S10 Enganche opcional en el archive / Archive en un proyecto que ya usa SRS" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)Fase de la rama|Branch phase') "$a debe definir la fase de la rama"
        Afirmar ($txt -match '(?is)(?:fase de la rama|branch phase).*?(?:docs:\s*regenerar\s+SRS).*?(?:Spec-ID:\s*<(?:nombre|name)>)') "$a debe incluir el paso de regenerar SRS en la fase de la rama con docs: regenerar SRS y Spec-ID"
        Afirmar ($txt -match '(?i)Regenerar ahora') "$a debe ofrecer opción Regenerar ahora"
        Afirmar ($txt -match '(?i)M[aá]s tarde') "$a debe ofrecer opción Más tarde"
    }
}

# test-plan: srs-en-rama-del-change/S11
Probar "S11 Enganche opcional en el archive / Archive en un proyecto sin SRS" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)Fase de la rama|Branch phase') "$a debe definir la fase de la rama"
        Afirmar ($txt -match '(?is)(?:fase de la rama|branch phase).*?(?:docs:\s*generar\s+SRS).*?(?:Spec-ID:\s*<(?:nombre|name)>)') "$a debe incluir el paso de generar SRS en la fase de la rama con docs: generar SRS y Spec-ID"
        Afirmar ($txt -match '(?i)Generar ahora') "$a debe ofrecer opción Generar ahora"
        Afirmar ($txt.Contains("entrevista corta")) "$a debe avisar sobre la entrevista corta"
    }
}

# test-plan: srs-en-rama-del-change/S12
Probar "S12 Enganche opcional en el archive / Usuario que posterga la generación" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)(?:pr[oó]ximo archive.*volver[aá] a ofrecer|pr[oó]ximo archive.*vuelve a ofrecer)') "$a debe indicar que el próximo archive volverá a ofrecer el SRS"
        Afirmar ($txt -match '(?i)(?:no bloquea|nunca bloquea|no se bloquea)') "$a debe indicar que postergar no bloquea el archive"
    }
}

# test-plan: srs-en-rama-del-change/S13
Probar "S13 Enganche opcional en el archive / El cierre en el vault no ofrece el SRS" {
    $archivos = @(
        "$repoRoot/skills/openspec-archive-change/SKILL.md",
        "$repoRoot/.claude/commands/opsx/archive.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?i)(?:fase del vault.*no ofrece.*SRS|no ofrece.*SRS.*fase del vault|cierre en el vault.*no ofrece.*SRS)') "$a debe indicar que la fase del vault no ofrece el SRS"
    }
}

# test-plan: srs-en-rama-del-change/S14
Probar "S14 Verify liviano / ODD con cambio de spec y SRS" {
    $archivos = @(
        "$repoRoot/skills/odd-change/SKILL.md",
        "$repoRoot/.claude/commands/odd/verify.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt.Contains("openspec archive odd-")) "$a debe incluir openspec archive odd-"
        Afirmar ($txt -match '(?i)(?:docs:\s*regenerar\s+SRS|docs:\s*generar\s+SRS)') "$a debe nombrar docs: regenerar SRS o docs: generar SRS"
        Afirmar ($txt -match '(?i)Spec-ID:\s*odd-<(?:nombre|name)>') "$a debe commitear el SRS con Spec-ID: odd-<nombre>"
        Afirmar ($txt.Contains("docs/srs.md") -and $txt.Contains("docs/srs.meta.yaml") -and $txt.Contains("docs/diagramas/")) "$a debe permitir docs/srs.md, docs/srs.meta.yaml y docs/diagramas/ en el alcance"
    }
}

# test-plan: srs-en-rama-del-change/S15
Probar "S15 Cierre en el vault de Obsidian / Cierre de un ODD con cambio de spec" {
    $archivos = @(
        "$repoRoot/skills/odd-change/SKILL.md",
        "$repoRoot/.claude/commands/odd/close.md"
    )

    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $txt = Normalizar-Contenido $a

        Afirmar ($txt -match '(?m)^## SRS|^SRS:') "$a formato de nota debe tener la línea o sección SRS:"
        Afirmar (-not ($txt -match '(?i)recomendar.*(?:al usuario correr\s+)?/srs-generate')) "$a no debe recomendar correr /srs-generate"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
