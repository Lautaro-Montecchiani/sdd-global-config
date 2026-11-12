# tests/generar-comandos.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"
. "$PSScriptRoot/../scripts/comun.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptGenerar = "$repoRoot/scripts/generar-plantillas.ps1"

function Copiar-EntornoTemporalComandos {
    param([string]$Dir)
    New-Item -ItemType Directory -Path "$Dir/templates" -Force | Out-Null
    if (Test-Path "$repoRoot/templates") {
        Copy-Item -Recurse "$repoRoot/templates/*" "$Dir/templates/"
    }
    New-Item -ItemType Directory -Path "$Dir/scripts" -Force | Out-Null
    if (Test-Path "$repoRoot/scripts") {
        Copy-Item -Recurse "$repoRoot/scripts/*" "$Dir/scripts/"
    }
    New-Item -ItemType Directory -Path "$Dir/.claude" -Force | Out-Null
    if (Test-Path "$repoRoot/.claude") {
        Copy-Item -Recurse "$repoRoot/.claude/*" "$Dir/.claude/"
    }
    New-Item -ItemType Directory -Path "$Dir/skills" -Force | Out-Null
    if (Test-Path "$repoRoot/skills") {
        Copy-Item -Recurse "$repoRoot/skills/*" "$Dir/skills/"
    }
}

function Ejecutar-PwshScript {
    param(
        [string]$ScriptPath,
        [string]$Argumentos = "",
        [string]$WorkingDir = ""
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "pwsh"
    $psi.Arguments = "-NoProfile -File `"$ScriptPath`" $Argumentos"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    if ($WorkingDir) {
        $psi.WorkingDirectory = $WorkingDir
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{
        ExitCode = $proc.ExitCode
        Output = $stdout + $stderr
        Stdout = $stdout
        Stderr = $stderr
    }
}

# test-plan: generar-comandos-desde-skills/S01
Probar "S01 comando con la skill completa" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $script = "$dir/scripts/generar-plantillas.ps1"
        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($res.Output)"

        $dest = "$dir/.claude/commands/opsx/apply.md"
        Afirmar (Test-Path $dest) "No se generó opsx/apply.md"

        $txt = Get-Content -Path $dest -Raw -Encoding UTF8
        $aviso = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
        Afirmar ($txt -match [regex]::Escape($aviso)) "opsx/apply.md debe contener el aviso de archivo generado"
        Afirmar ($txt -match "^---\nname:\s*`"OPSX: Apply`"") "opsx/apply.md debe conservar el frontmatter del comando"
        Afirmar ($txt -notmatch "<!-- incluir-skill:") "opsx/apply.md no debe contener la marca incluir-skill"

        # Debe incluir cuerpo de la skill sin su frontmatter
        $skillTxt = Get-Content -Path "$dir/skills/openspec-apply-change/SKILL.md" -Raw -Encoding UTF8
        Afirmar ($txt -notmatch "license: MIT") "opsx/apply.md no debe contener el frontmatter de la skill"
        Afirmar ($txt -match "Claude is the architect: it does NOT implement tasks\.") "opsx/apply.md debe contener el cuerpo de la skill"
    }
}

# test-plan: generar-comandos-desde-skills/S02
Probar "S02 comando con secciones de una skill" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $script = "$dir/scripts/generar-plantillas.ps1"
        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($res.Output)"

        $dest = "$dir/.claude/commands/odd/verify.md"
        Afirmar (Test-Path $dest) "No se generó odd/verify.md"

        $txt = Get-Content -Path $dest -Raw -Encoding UTF8
        $aviso = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
        Afirmar ($txt -match [regex]::Escape($aviso)) "odd/verify.md debe contener el aviso de archivo generado"
        Afirmar ($txt -match '## Verify \(`\/odd:verify`\)') "odd/verify.md debe contener la sección Verify con backticks"
        Afirmar ($txt -match "## Escalado") "odd/verify.md debe contener la sección Escalado"
        Afirmar ($txt -notmatch '## Inicio \(`\/odd`\)') "odd/verify.md NO debe contener la sección Inicio"
        Afirmar ($txt -notmatch '## Cierre \(`\/odd:close`\)') "odd/verify.md NO debe contener la sección Cierre"
    }
}

# test-plan: generar-comandos-desde-skills/S03
Probar "S03 título dentro de un bloque de código" {
    $ejemploMarkdown = @'
# Título Principal

## Sección Buscada

Texto inicial de la sección.

```markdown
## Objetivo
Código de ejemplo dentro de bloque.
## Evidencia
Más código.
```

Texto posterior dentro de la sección.

## Otra Sección

Texto que no debe incluirse.
'@

    $cmd = Get-Command -Name "Extraer-SeccionMarkdown" -ErrorAction SilentlyContinue
    Afirmar ($null -ne $cmd) "La función Extraer-SeccionMarkdown debe existir en scripts/comun.ps1"

    $extraido = Extraer-SeccionMarkdown -Texto $ejemploMarkdown -Titulo "Sección Buscada"
    Afirmar ($extraido -match "## Objetivo") "Debe incluir el título dentro del bloque de código"
    Afirmar ($extraido -match "## Evidencia") "Debe incluir el segundo título dentro del bloque de código"
    Afirmar ($extraido -match "Texto posterior dentro de la sección\.") "Debe incluir el texto posterior al bloque"
    Afirmar ($extraido -notmatch "## Otra Sección") "No debe incluir la siguiente sección"
    Afirmar ($extraido -notmatch "Texto que no debe incluirse") "No debe incluir texto de la siguiente sección"
}

# test-plan: generar-comandos-desde-skills/S04
Probar "S04 mismo texto para /odd y /odd:start" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $script = "$dir/scripts/generar-plantillas.ps1"
        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($res.Output)"

        $oddStart = "$dir/.claude/commands/odd/start.md"
        $oddRoot = "$dir/.claude/commands/odd.md"
        Afirmar (Test-Path $oddStart) "No existe odd/start.md"
        Afirmar (Test-Path $oddRoot) "No existe odd.md"

        $txtStart = Get-Content -Path $oddStart -Raw -Encoding UTF8
        $txtRoot = Get-Content -Path $oddRoot -Raw -Encoding UTF8

        $aviso = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
        Afirmar ($txtStart -match [regex]::Escape($aviso)) "odd/start.md debe contener el aviso de archivo generado"
        Afirmar ($txtRoot -match [regex]::Escape($aviso)) "odd.md debe contener el aviso de archivo generado"
        Afirmar ($txtRoot -eq $txtStart) "odd.md y odd/start.md deben ser exactamente idénticos"
    }
}

# test-plan: generar-comandos-desde-skills/S05
Probar "S05 dato inválido: skill inexistente" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $hdr = "$dir/templates/fuente/comandos/opsx/apply.md"
        Afirmar (Test-Path $hdr) "El encabezado templates/fuente/comandos/opsx/apply.md debe existir"
        $hdrContent = @"
---
name: Test
---

<!-- incluir-skill: no-existe -->
"@
        Set-Content -Path $hdr -Value $hdrContent -Encoding UTF8

        $script = "$dir/scripts/generar-plantillas.ps1"
        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "El script debió fallar con código distinto de 0"
        Afirmar ($res.Output -match "apply\.md") "La salida debe nombrar el encabezado: $($res.Output)"
        Afirmar ($res.Output -match "no-existe") "La salida debe nombrar la marca inválida: $($res.Output)"
    }
}

# test-plan: generar-comandos-desde-skills/S06
Probar "S06 dato inválido: sección inexistente" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $hdr = "$dir/templates/fuente/comandos/odd/start.md"
        Afirmar (Test-Path $hdr) "El encabezado templates/fuente/comandos/odd/start.md debe existir"
        $hdrContent = @"
---
name: Test
---

<!-- incluir-skill: odd-change#No existe -->
"@
        Set-Content -Path $hdr -Value $hdrContent -Encoding UTF8

        $script = "$dir/scripts/generar-plantillas.ps1"
        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "El script debió fallar con código distinto de 0"
        Afirmar ($res.Output -match "start\.md") "La salida debe nombrar el encabezado: $($res.Output)"
        Afirmar ($res.Output -match "No existe") "La salida debe nombrar la marca inválida: $($res.Output)"
    }
}

# test-plan: generar-comandos-desde-skills/S07
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S19
Probar "S07 comando editado a mano falla en -Comprobar" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $script = "$dir/scripts/generar-plantillas.ps1"
        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($resGen.Output)"

        $cmdVerify = "$dir/.claude/commands/opsx/verify.md"
        Afirmar (Test-Path $cmdVerify) "No existe opsx/verify.md"
        Add-Content -Path $cmdVerify -Value "`n<!-- edición manual no autorizada -->" -Encoding UTF8

        $resComp = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($resComp.ExitCode -ne 0) "-Comprobar debió fallar al detectar comando editado a mano"
        Afirmar ($resComp.Output -match "opsx/verify\.md|\.claude/commands/opsx/verify\.md") "La salida debe listar el comando modificado: $($resComp.Output)"
    }
}

# test-plan: generar-comandos-desde-skills/S08
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S20
Probar "S08 skill editada sin regenerar falla en -Comprobar" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporalComandos -Dir $dir

        $script = "$dir/scripts/generar-plantillas.ps1"
        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($resGen.Output)"

        $skillOdd = "$dir/skills/odd-change/SKILL.md"
        $skillTxt = Get-Content -Path $skillOdd -Raw -Encoding UTF8
        $skillMod = $skillTxt -replace "(?m)^## Escalado", "## Escalado`n`n<!-- cambio en skill -->"
        Set-Content -Path $skillOdd -Value $skillMod -Encoding UTF8

        $resComp = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($resComp.ExitCode -ne 0) "-Comprobar debió fallar tras modificar la skill sin regenerar"
        Afirmar ($resComp.Output -match "odd/start\.md") "Debe nombrar odd/start.md: $($resComp.Output)"
        Afirmar ($resComp.Output -match "odd/verify\.md") "Debe nombrar odd/verify.md: $($resComp.Output)"
        Afirmar ($resComp.Output -match "odd\.md") "Debe nombrar odd.md: $($resComp.Output)"
    }
}

# test-plan: generar-comandos-desde-skills/S09
Probar "S09 todo sincronizado pasa en el repositorio real" {
    $res = Ejecutar-PwshScript -ScriptPath $scriptGenerar -Argumentos "-Comprobar" -WorkingDir $repoRoot
    Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 -Comprobar falló: $($res.Output)"

    $aviso = '<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->'
    $comandos = @(
        ".claude/commands/opsx/apply.md",
        ".claude/commands/opsx/archive.md",
        ".claude/commands/opsx/explore.md",
        ".claude/commands/opsx/propose.md",
        ".claude/commands/opsx/verify.md",
        ".claude/commands/odd/start.md",
        ".claude/commands/odd/verify.md",
        ".claude/commands/odd/close.md",
        ".claude/commands/odd.md"
    )
    foreach ($cmd in $comandos) {
        $full = Join-Path $repoRoot $cmd
        Afirmar (Test-Path $full) "No existe el comando $cmd"
        $txt = Get-Content -Path $full -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape($aviso)) "El comando $cmd debe tener el aviso de generado"
    }
}

# test-plan: generar-comandos-desde-skills/S10
Probar "S10 security layer: el script no ejecuta texto leído" {
    $scriptTxt = Get-Content -Path $scriptGenerar -Raw -Encoding UTF8
    Afirmar ($scriptTxt -notmatch "Invoke-Expression") "El script no debe usar Invoke-Expression"
    Afirmar ($scriptTxt -notmatch "(?i)\biex\b") "El script no debe usar el alias iex"
    Afirmar ($scriptTxt -notmatch "&\s*\$") "El script no debe ejecutar variables (& $)"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
