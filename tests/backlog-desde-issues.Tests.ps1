# tests/backlog-desde-issues.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

$issueCreationSkill = "$repoRoot/skills/issue-creation/SKILL.md"
$proposeSkill = "$repoRoot/skills/openspec-propose/SKILL.md"
$proposeCmd = "$repoRoot/.claude/commands/opsx/propose.md"
$branchPrSkill = "$repoRoot/skills/branch-pr/SKILL.md"
$archiveSkill = "$repoRoot/skills/openspec-archive-change/SKILL.md"
$archiveCmd = "$repoRoot/.claude/commands/opsx/archive.md"
$srsSkill = "$repoRoot/skills/srs-generate/SKILL.md"
$claudeGlobal = "$repoRoot/.claude/CLAUDE.md"
$oddSkill = "$repoRoot/skills/odd-change/SKILL.md"
$oddCmd = "$repoRoot/.claude/commands/odd.md"
$scriptBacklog = "$repoRoot/scripts/generar-backlog.ps1"

# Helper para ejecutar pwsh de forma aislada
function Ejecutar-ScriptBacklog {
    param(
        [string]$Proyecto,
        [string]$Entrada = $null,
        [string]$DirectorioTrabajo = $null
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argsList = "-NoProfile -File `"$scriptBacklog`" -Proyecto `"$Proyecto`""
    if ($null -ne $Entrada -and $Entrada -ne '') {
        $argsList += " -Entrada `"$Entrada`""
    }
    $psi.Arguments = $argsList
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    if ($null -ne $DirectorioTrabajo -and (Test-Path $DirectorioTrabajo)) {
        $psi.WorkingDirectory = $DirectorioTrabajo
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    return [PSCustomObject]@{
        ExitCode = $proc.ExitCode
        Stdout   = $stdout
        Stderr   = $stderr
    }
}

# test-plan: backlog-desde-issues/S01
Probar "S01 Issue de entrada con prioridad y tipo / Issue con prioridad y tipo" {
    Afirmar (Test-Path $issueCreationSkill) "Debe existir $issueCreationSkill"
    $txt = Get-Content -Path $issueCreationSkill -Raw -Encoding UTF8

    Afirmar ($txt -match [regex]::Escape('prioridad:alta') -and $txt -match [regex]::Escape('prioridad:media') -and $txt -match [regex]::Escape('prioridad:baja')) 'Debe pedir prioridad:alta, prioridad:media o prioridad:baja'
    Afirmar ($txt -match [regex]::Escape('tipo:feature') -and $txt -match [regex]::Escape('tipo:deuda') -and $txt -match [regex]::Escape('tipo:bug')) 'Debe pedir tipo:feature, tipo:deuda o tipo:bug'
    Afirmar ($txt -match 'AskUserQuestion') 'Debe mencionar AskUserQuestion'
    Afirmar ($txt -match '3\.\s+\*\*Ensure labels\*\*') 'Debe contener el paso 3. Ensure labels'

    $etiquetas = @('status:needs-review', 'status:approved', 'prioridad:alta', 'prioridad:media', 'prioridad:baja', 'tipo:feature', 'tipo:deuda', 'tipo:bug', 'bloqueado')
    $colores = @('ededed', '0e8a16', 'b60205', 'fbca04', 'c2e0c6', '1d76db', '5319e7', 'd73a4a', '000000')

    for ($i = 0; $i -lt $etiquetas.Count; $i++) {
        Afirmar ($txt -match [regex]::Escape($etiquetas[$i])) "Debe contener la etiqueta $($etiquetas[$i]) en el catalogo"
        Afirmar ($txt -match [regex]::Escape($colores[$i])) "Debe contener el color $($colores[$i]) en el catalogo"
    }

    Afirmar ($txt -match [regex]::Escape('--label "status:needs-review" --label "<prioridad>" --label "<tipo>"')) 'Debe incluir las tres etiquetas en el comando de creacion'
}

# test-plan: backlog-desde-issues/S02
Probar "S02 Issue de entrada con prioridad y tipo / Cuenta sin permiso" {
    Afirmar (Test-Path $issueCreationSkill) "Debe existir $issueCreationSkill"
    $txt = Get-Content -Path $issueCreationSkill -Raw -Encoding UTF8

    $mensajeEsperado = 'La cuenta activa de gh (<cuenta>) no tiene permiso en <owner>/<repo>: activá la cuenta dueña del repo con `gh auth switch -u <cuenta>` y volvé a correr /issue-creation'
    Afirmar ($txt -match [regex]::Escape($mensajeEsperado)) 'Debe contener el mensaje exacto con gh auth switch y volver a correr'
}

# test-plan: backlog-desde-issues/S03
Probar "S03 Issue en el proposal / Issue abierto y aprobado" {
    foreach ($f in @($proposeSkill, $proposeCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match '1b\.\s+\*\*Issue del change\*\*') "$f debe contener el paso 1b. Issue del change"
        Afirmar ($txt -match [regex]::Escape('gh issue view <NN> --json state,labels,title')) "$f debe contener el control con gh issue view"
        Afirmar ($txt -match [regex]::Escape('Write `Issue: #<NN>` (or `Issue: pendiente`) as the first line of `proposal.md`')) "$f debe indicar escribir Issue como primera linea de proposal.md"
    }
}

# test-plan: backlog-desde-issues/S04
Probar "S04 Issue en el proposal / Dato inválido: issue cerrado o inexistente" {
    foreach ($f in @($proposeSkill, $proposeCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('does not exist or its state is `CLOSED`')) "$f debe controlar si no existe o esta CLOSED"
        Afirmar ($txt -match [regex]::Escape('suggest `/issue-creation`')) "$f debe sugerir /issue-creation si esta cerrado o no existe"
    }
}

# test-plan: backlog-desde-issues/S05
Probar "S05 Issue en el proposal / Sin gh o sin permiso" {
    foreach ($f in @($proposeSkill, $proposeCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('use `Issue: pendiente` and continue')) "$f debe usar Issue: pendiente y continuar si gh no esta disponible o no hay permiso"
    }
}

# test-plan: backlog-desde-issues/S06
Probar "S06 Cierre del issue con el PR / PR que cierra el issue" {
    Afirmar (Test-Path $branchPrSkill) "Debe existir $branchPrSkill"
    $txt = Get-Content -Path $branchPrSkill -Raw -Encoding UTF8

    Afirmar ($txt -match [regex]::Escape('Read the first line of `openspec/changes/{nombre}/proposal.md`')) 'Debe indicar leer la primera linea del proposal'
    Afirmar ($txt -match [regex]::Escape('add the line `Closes #NN` right below the `Spec-ID:` line of the PR body')) 'Debe indicar agregar Closes #NN debajo de Spec-ID:'
    Afirmar ($txt -match [regex]::Escape('without `Closes` and say so in step 7')) 'Debe indicar abrir sin Closes si es pendiente o no existe'

    $matchesCloses = [regex]::Matches($txt, [regex]::Escape('Closes #{NN}  # solo si hay Issue: #NN'))
    Afirmar ($matchesCloses.Count -ge 2) 'Debe incluir Closes #{NN} en los dos cuerpos de ejemplo (SDD y ODD)'
}

# test-plan: backlog-desde-issues/S07
Probar "S07 Generación del backlog / Issues agrupados por prioridad" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        $jsonSample = @'
[
  {
    "number": 10,
    "title": "Feature diez",
    "labels": [{"name": "prioridad:alta"}, {"name": "tipo:feature"}],
    "url": "https://github.com/org/repo/issues/10"
  },
  {
    "number": 2,
    "title": "Feature dos",
    "labels": [{"name": "prioridad:alta"}, {"name": "tipo:feature"}],
    "url": "https://github.com/org/repo/issues/2"
  },
  {
    "number": 20,
    "title": "Bug veinte",
    "labels": [{"name": "prioridad:media"}, {"name": "tipo:bug"}],
    "url": "https://github.com/org/repo/issues/20"
  },
  {
    "number": 5,
    "title": "Deuda cinco",
    "labels": [{"name": "prioridad:baja"}, {"name": "tipo:deuda"}],
    "url": "https://github.com/org/repo/issues/5"
  }
]
'@
        $jsonPath = Join-Path $tempDir "issues.json"
        [System.IO.File]::WriteAllText($jsonPath, $jsonSample, [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "El script debe terminar con 0. Error: $($res.Stderr)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        Afirmar (Test-Path $backlogFile) "Debe crearse docs/backlog.md"
        $txt = Get-Content -Path $backlogFile -Raw -Encoding UTF8

        $posAlta = $txt.IndexOf('## Prioridad alta')
        $posMedia = $txt.IndexOf('## Prioridad media')
        $posBaja = $txt.IndexOf('## Prioridad baja')
        $posSin = $txt.IndexOf('## Sin prioridad')

        Afirmar ($posAlta -ge 0 -and $posMedia -gt $posAlta -and $posBaja -gt $posMedia -and $posSin -gt $posBaja) 'Las 4 secciones deben aparecer en el orden correcto'

        # En Prioridad alta, issue 2 antes que issue 10
        $posIssue2 = $txt.IndexOf('[#2](https://github.com/org/repo/issues/2)')
        $posIssue10 = $txt.IndexOf('[#10](https://github.com/org/repo/issues/10)')
        Afirmar ($posIssue2 -ge 0 -and $posIssue10 -gt $posIssue2) 'Los issues deben ordenarse por numero ascendente'

        # Formato de columnas | Issue | Titulo | Tipo |
        Afirmar ($txt -match '\|\s+\[#2\]\(https://github.com/org/repo/issues/2\)\s+\|\s+Feature dos\s+\|\s+feature\s+\|') 'Fila de issue con formato correcto'

        # Ultima linea
        Afirmar ($txt -match 'Total:\s+4\s+issues abiertos\.') 'Debe terminar con el total de issues abiertos'
    }
}

# test-plan: backlog-desde-issues/S08
Probar "S08 Generación del backlog / Tipo y bloqueado" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        $jsonSample = @'
[
  {
    "number": 15,
    "title": "Deuda bloqueada",
    "labels": [{"name": "prioridad:alta"}, {"name": "tipo:deuda"}, {"name": "bloqueado"}],
    "url": "https://github.com/org/repo/issues/15"
  },
  {
    "number": 16,
    "title": "Sin tipo",
    "labels": [{"name": "prioridad:media"}],
    "url": "https://github.com/org/repo/issues/16"
  }
]
'@
        $jsonPath = Join-Path $tempDir "issues.json"
        [System.IO.File]::WriteAllText($jsonPath, $jsonSample, [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "El script debe terminar con 0. Error: $($res.Stderr)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        $txt = Get-Content -Path $backlogFile -Raw -Encoding UTF8

        Afirmar ($txt -match '\|\s+\[#15\]\(https://github.com/org/repo/issues/15\)\s+\|\s+Deuda bloqueada \(bloqueado\)\s+\|\s+deuda\s+\|') 'Issue bloqueado debe terminar con (bloqueado) y tipo deuda'
        Afirmar ($txt -match '\|\s+\[#16\]\(https://github.com/org/repo/issues/16\)\s+\|\s+Sin tipo\s+\|\s+—\s+\|') 'Issue sin tipo debe mostrar em-dash —'
    }
}

# test-plan: backlog-desde-issues/S09
Probar "S09 Generación del backlog / Issues sin prioridad y secciones vacías" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        $jsonSample = @'
[
  {
    "number": 30,
    "title": "Sin prioridad",
    "labels": [{"name": "tipo:feature"}],
    "url": "https://github.com/org/repo/issues/30"
  },
  {
    "number": 31,
    "title": "Doble prioridad",
    "labels": [{"name": "prioridad:media"}, {"name": "prioridad:alta"}, {"name": "tipo:bug"}],
    "url": "https://github.com/org/repo/issues/31"
  }
]
'@
        $jsonPath = Join-Path $tempDir "issues.json"
        [System.IO.File]::WriteAllText($jsonPath, $jsonSample, [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "El script debe terminar con 0. Error: $($res.Stderr)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        $txt = Get-Content -Path $backlogFile -Raw -Encoding UTF8

        # Issue 30 en Sin prioridad
        $posSin = $txt.IndexOf('## Sin prioridad')
        $posIssue30 = $txt.IndexOf('[#30]')
        Afirmar ($posIssue30 -gt $posSin) 'Issue sin prioridad debe estar debajo de ## Sin prioridad'

        # Issue 31 en Prioridad alta (gana la mas alta)
        $posAlta = $txt.IndexOf('## Prioridad alta')
        $posMedia = $txt.IndexOf('## Prioridad media')
        $posIssue31 = $txt.IndexOf('[#31]')
        Afirmar ($posIssue31 -gt $posAlta -and $posIssue31 -lt $posMedia) 'Issue con doble prioridad debe estar en Prioridad alta'

        # Prioridad baja vacia debe decir Ninguno.
        $posBaja = $txt.IndexOf('## Prioridad baja')
        $subBaja = $txt.Substring($posBaja, $posSin - $posBaja)
        Afirmar ($subBaja -match 'Ninguno\.') 'Seccion vacia debe decir Ninguno.'
    }
}

# test-plan: backlog-desde-issues/S10
Probar "S10 Generación del backlog / Dato inválido: título con barra o salto de línea, o issue incompleto" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        $jsonSample = @'
[
  {
    "number": 40,
    "title": "Titulo con | barra y\nsalto de linea",
    "labels": [{"name": "prioridad:alta"}],
    "url": "https://github.com/org/repo/issues/40"
  },
  {
    "number": 41,
    "labels": [{"name": "prioridad:media"}],
    "url": "https://github.com/org/repo/issues/41"
  }
]
'@
        $jsonPath = Join-Path $tempDir "issues.json"
        [System.IO.File]::WriteAllText($jsonPath, $jsonSample, [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "El script debe terminar con 0. Error: $($res.Stderr)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        $txt = Get-Content -Path $backlogFile -Raw -Encoding UTF8

        Afirmar ($txt -match [regex]::Escape('Titulo con \| barra y salto de linea')) 'La barra debe estar escapada y el salto pasado a espacio'
        Afirmar ($txt -notmatch '\[#41\]') 'El issue sin titulo debe ser descartado'
        Afirmar ($res.Stdout -match 'Issues descartados por datos incompletos: 1\.') 'Consola debe informar los issues descartados'
    }
}

# test-plan: backlog-desde-issues/S11
Probar "S11 Generación del backlog / No se pueden leer los issues" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        # Correr sin -Entrada en tempDir que no tiene repo git ni conexion gh
        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -DirectorioTrabajo $tempDir
        Afirmar ($res.ExitCode -eq 1) "Debe fallar con codigo 1. Salida: $($res.Stdout)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        Afirmar (-not (Test-Path $backlogFile)) "NO debe crearse docs/backlog.md"

        $salidaCompleta = $res.Stdout + "`n" + $res.Stderr
        Afirmar ($salidaCompleta -match [regex]::Escape('No se pudo leer los issues del proyecto:')) 'Debe avisar que no se pudo leer los issues'
        Afirmar (-not ($salidaCompleta -match [regex]::Escape($tempDir))) 'El mensaje no debe contener rutas absolutas'
    }
}

# test-plan: backlog-desde-issues/S12
Probar "S12 Generación del backlog / Archivo generado" {
    Afirmar (Test-Path $scriptBacklog) "Debe existir $scriptBacklog"

    Con-CarpetaTemporal {
        param($tempDir)

        $jsonSample = @'
[
  {
    "number": 1,
    "title": "Primer issue",
    "labels": [{"name": "prioridad:alta"}],
    "url": "https://github.com/org/repo/issues/1"
  }
]
'@
        $jsonPath = Join-Path $tempDir "issues.json"
        [System.IO.File]::WriteAllText($jsonPath, $jsonSample, [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-ScriptBacklog -Proyecto $tempDir -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "El script debe terminar con 0. Error: $($res.Stderr)"

        $backlogFile = Join-Path $tempDir "docs/backlog.md"
        Afirmar (Test-Path $backlogFile) "Debe existir docs/backlog.md"

        $bytes = [System.IO.File]::ReadAllBytes($backlogFile)
        Afirmar ($bytes.Length -ge 3) "El archivo debe tener contenido"
        $tieneBom = ($bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)
        Afirmar (-not $tieneBom) "docs/backlog.md debe estar en UTF-8 sin BOM"

        $lineas = [System.IO.File]::ReadAllLines($backlogFile, [System.Text.UTF8Encoding]::new($false))
        $comentarioEsperado = '<!-- Generado con scripts/generar-backlog.ps1 desde los issues abiertos de GitHub. No editar a mano. -->'
        Afirmar ($lineas[0] -eq $comentarioEsperado) "La primera linea debe ser el comentario de archivo generado"

        $txt = [System.IO.File]::ReadAllText($backlogFile, [System.Text.UTF8Encoding]::new($false))
        Afirmar (-not ($txt -match [regex]::Escape($tempDir))) "docs/backlog.md no debe contener rutas absolutas"
        Afirmar (-not ($txt -match [regex]::Escape($repoRoot))) "docs/backlog.md no debe contener la ruta del repo"
    }
}

# test-plan: backlog-desde-issues/S13
Probar "S13 Backlog en el archive / Backlog regenerado en el archive" {
    foreach ($f in @($archiveSkill, $archiveCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match '6b\.\s+\*\*Backlog en la rama:\*\*') "$f debe contener el paso 6b. Backlog en la rama"
        Afirmar ($txt -match [regex]::Escape('scripts\generar-backlog.ps1 -Proyecto .')) "$f debe invocar generar-backlog.ps1"
        Afirmar ($txt -match [regex]::Escape('docs: regenerar backlog')) "$f debe commitear con docs: regenerar backlog"
        Afirmar ($txt -match [regex]::Escape('el backlog nunca bloquea el archive')) "$f debe indicar que el backlog nunca bloquea el archive"
    }
}

# test-plan: backlog-desde-issues/S14
Probar "S14 Issue de origen en el SRS / Requirement con issue" {
    Afirmar (Test-Path $srsSkill) "Debe existir $srsSkill"
    $txt = Get-Content -Path $srsSkill -Raw -Encoding UTF8

    Afirmar ($txt -match [regex]::Escape('- **Issue:**')) 'Debe describir el atributo Issue'
    Afirmar ($txt -match [regex]::Escape('docs/srs.meta.yaml')) 'Debe mencionar docs/srs.meta.yaml'
    Afirmar ($txt -match [regex]::Escape('el atributo se omite')) 'Debe indicar que si no tiene issue el atributo se omite'
    Afirmar ($txt -match [regex]::Escape('# Issue de origen de cada requirement (ID jerárquico -> número de issue)')) 'Debe incluir el comentario de issues en el YAML de ejemplo'
    Afirmar ($txt -match 'issues:\s*\r?\n\s+"3\.5\.1\.2":\s+52') 'Debe incluir issues: con "3.5.1.2": 52 en el YAML de ejemplo'
}

# test-plan: backlog-desde-issues/S15
Probar "S15 Hoja de ruta con número de issue / Formato con issue" {
    foreach ($f in @($claudeGlobal, $proposeSkill)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('— propuesta: <cómo pagarla> — issue: #NN')) "$f debe contener el formato de hoja de ruta con issue opcional"
    }
}

# test-plan: backlog-desde-issues/S16
Probar "S16 Issue opcional en el ODD / ODD con o sin issue" {
    foreach ($f in @($oddSkill, $oddCmd)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape('en ODD el issue no es obligatorio')) "$f debe contener la regla de que en ODD el issue no es obligatorio"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
