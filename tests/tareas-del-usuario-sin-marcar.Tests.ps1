# tests/tareas-del-usuario-sin-marcar.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

$proposeSkill = "$repoRoot/skills/openspec-propose/SKILL.md"
$proposeCmd = "$repoRoot/.claude/commands/opsx/propose.md"

$verifySkill = "$repoRoot/skills/openspec-verify-change/SKILL.md"
$verifyCmd = "$repoRoot/.claude/commands/opsx/verify.md"

$fuenteReglas = "$repoRoot/templates/fuente/fragmentos/reglas-ejecucion.md"
$geminiTpl = "$repoRoot/templates/antigravity/GEMINI.md"
$copilotTpl = "$repoRoot/templates/copilot/copilot-instructions.md"
$cursorTpl = "$repoRoot/templates/cursor/sdd-workflow.mdc"
$agentsTpl = "$repoRoot/templates/comun/AGENTS.md"
$claudeGlobal = "$repoRoot/.claude/CLAUDE.md"

# test-plan: tareas-del-usuario-sin-marcar/S01
Probar "S01 Marca de tareas del usuario en el propose / Marca en las tareas del usuario" {
    $oracionD2 = 'Write the literal marker `(lo corre el usuario)` right after the ID of every manual task that needs the user (a real Claude Code or Agent session, another project, another machine or the user''s own credentials), and state in the task that it stays `[ ]` until the user confirms it in the verify.'

    foreach ($f in @($proposeSkill, $proposeCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape($oracionD2)) "$f debe contener la oración de D2"
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S02
Probar "S02 Control de tareas del usuario en el verify / Tarea del usuario marcada y confirmada" {
    foreach ($f in @($verifySkill, $verifyCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        $matches = [regex]::Matches($txt, '-\s+\*\*Tareas del usuario\*\*')
        Afirmar ($matches.Count -eq 2) "$f debe contener exactamente dos veces la viñeta '- **Tareas del usuario**' (paso 6 y Task Completion). Encontradas: $($matches.Count)"
        Afirmar ($txt -match [regex]::Escape('¿Corriste vos <ID> y la evidencia es tuya?')) "$f debe contener la pregunta de confirmación"
        Afirmar ($txt -match [regex]::Escape('"Sí, la corrí yo"')) "$f debe contener la opción 'Sí, la corrí yo'"
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S03
Probar "S03 Control de tareas del usuario en el verify / Tarea del usuario marcada por el Agente" {
    $critItem = 'user tasks `(lo corre el usuario)` not confirmed by the user ("tarea del usuario sin confirmar")'

    foreach ($f in @($verifySkill, $verifyCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('tarea del usuario sin confirmar')) "$f debe contener 'tarea del usuario sin confirmar' en la viñeta"
        $critMatches = [regex]::Matches($txt, [regex]::Escape($critItem))
        Afirmar ($critMatches.Count -ge 2) "$f debe contener el ítem CRITICAL en las dos listas de Issues by Priority. Encontradas: $($critMatches.Count)"
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S04
Probar "S04 Control de tareas del usuario en el verify / Evidencia del usuario en el verify" {
    foreach ($f in @($verifySkill, $verifyCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('mark it `[x]` in `tasks.md`')) ('El archivo ' + $f + ' debe indicar marcar [x] en tasks.md')
        Afirmar ($txt -match [regex]::Escape('state in the report that the evidence was provided by the user in the verify')) ('El archivo ' + $f + ' debe indicar que el reporte dice que la evidencia la entrego el usuario')
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S05
Probar "S05 Control de tareas del usuario en el verify / Verify sin interfaz interactiva" {
    foreach ($f in @($verifySkill, $verifyCmd)) {
        Afirmar (Test-Path $f) ('Debe existir ' + $f)
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('without an interactive interface (even if the request includes a written answer)')) ('El archivo ' + $f + ' debe contemplar la corrida sin interfaz interactiva')
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S06
Probar "S06 Control de tareas del usuario en el verify / Dato inválido: marca escrita de otra forma" {
    foreach ($f in @($verifySkill, $verifyCmd)) {
        Afirmar (Test-Path $f) ('Debe existir ' + $f)
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('case-insensitive')) ('El archivo ' + $f + ' debe indicar que la busqueda es case-insensitive')
        Afirmar ($txt -match [regex]::Escape('Tasks without the marker are checked as before')) ('El archivo ' + $f + ' debe indicar que las tareas sin la marca se controlan como antes')
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S07
Probar "S07 Regla 1 con tareas del usuario / Regla en la fuente y en lo generado" {
    $archivos = @(
        $fuenteReglas,
        $geminiTpl,
        $copilotTpl,
        $cursorTpl,
        $agentsTpl,
        $claudeGlobal
    )

    foreach ($f in $archivos) {
        Afirmar (Test-Path $f) ('Debe existir ' + $f)
        $lineas = Get-Content -Path $f -Encoding UTF8
        $lineaRegla1 = $lineas | Where-Object { $_ -match '^\s*1\.\s+.*Evidencia antes de' } | Select-Object -First 1
        Afirmar ($null -ne $lineaRegla1) ('No se encontro la regla 1 en ' + $f)
        Afirmar ($lineaRegla1 -match [regex]::Escape('(lo corre el usuario)')) ('La regla 1 en ' + $f + ' debe contener (lo corre el usuario)')
    }
}

# test-plan: tareas-del-usuario-sin-marcar/S08
Probar "S08 Regla 1 con tareas del usuario / Pedido del usuario" {
    Afirmar (Test-Path $fuenteReglas) ('Debe existir ' + $fuenteReglas)
    $txt = Get-Content -Path $fuenteReglas -Raw -Encoding UTF8
    $lineaRegla1 = ($txt -split '\r?\n') | Where-Object { $_ -match '^\s*1\.\s+.*Evidencia antes de' } | Select-Object -First 1
    Afirmar ($null -ne $lineaRegla1) ('No se encontro la regla 1 en ' + $fuenteReglas)

    Afirmar ($lineaRegla1 -match [regex]::Escape('aunque el usuario te pida correrla, queda `[ ]`')) 'La regla 1 en la fuente debe contener: aunque el usuario te pida correrla, queda `[ ]`'
    Afirmar ($lineaRegla1 -match [regex]::Escape('evidencia para que confirme el usuario')) 'La regla 1 en la fuente debe contener: evidencia para que confirme el usuario'
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
