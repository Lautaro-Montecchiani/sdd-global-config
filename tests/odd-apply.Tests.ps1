# tests/odd-apply.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

function Ejecutar-Pwsh {
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

function Obtener-CuerpoComando {
    param([string]$Texto)
    $norm = $Texto -replace "\r\n", "`n"
    if ($norm -match "(?ms)^.*?<!-- Generado desde templates/fuente/.*?-->\s*(.*)$") {
        return $matches[1].Trim()
    }
    if ($norm -match "(?s)^---\n.*?\n---\n*(.*)$") {
        return $matches[1].Trim()
    }
    return $norm.Trim()
}

# test-plan: odd-apply/S01
Probar "S01 tres archivos con el mismo cuerpo" {
    $archivos = @(
        "$repoRoot/templates/antigravity/skills/odd-apply/SKILL.md",
        "$repoRoot/templates/cursor/commands/odd-apply.md",
        "$repoRoot/templates/copilot/prompts/odd-apply.prompt.md"
    )
    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
    }

    $cuerpos = @()
    foreach ($a in $archivos) {
        $txt = Get-Content -Path $a -Raw -Encoding UTF8
        $cuerpo = Obtener-CuerpoComando $txt
        Afirmar (-not [string]::IsNullOrWhiteSpace($cuerpo)) "El cuerpo de $a no puede estar vacío"
        $cuerpos += $cuerpo
    }

    Afirmar ($cuerpos[0] -eq $cuerpos[1]) "El cuerpo de Antigravity debe ser igual al de Cursor"
    Afirmar ($cuerpos[0] -eq $cuerpos[2]) "El cuerpo de Antigravity debe ser igual al de Copilot"
}

# test-plan: odd-apply/S02
Probar "S02 control de arranque en el comando" {
    $cmdPath = "$repoRoot/templates/cursor/commands/odd-apply.md"
    Afirmar (Test-Path $cmdPath) "Debe existir $cmdPath"
    $txt = Get-Content -Path $cmdPath -Raw -Encoding UTF8

    Afirmar ($txt -match 'docs/odd/<nombre>\.md') "Debe validar existencia de docs/odd/<nombre>.md"
    Afirmar ($txt -match 'odd/<nombre>') "Debe validar rama odd/<nombre>"
    Afirmar ($txt -match 'estado:\s*abierto') "Debe validar estado: abierto"
    Afirmar ($txt -match 'Spec-ID:\s*odd-<nombre>') "Debe pedir commit con Spec-ID: odd-<nombre>"
    Afirmar ($txt -match 'estado:\s*listo-para-verify') "Debe pedir dejar estado: listo-para-verify"
}

# test-plan: odd-apply/S03
Probar "S03 comando editado a mano falla en -Comprobar" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/templates" -Force | Out-Null
        Copy-Item -Recurse "$repoRoot/templates/*" "$dir/templates/"
        New-Item -ItemType Directory -Path "$dir/scripts" -Force | Out-Null
        Copy-Item -Recurse "$repoRoot/scripts/*" "$dir/scripts/"
        New-Item -ItemType Directory -Path "$dir/.claude" -Force | Out-Null
        Copy-Item -Recurse "$repoRoot/.claude/*" "$dir/.claude/"
        New-Item -ItemType Directory -Path "$dir/skills" -Force | Out-Null
        Copy-Item -Recurse "$repoRoot/skills/*" "$dir/skills/"

        $target = "$dir/templates/cursor/commands/odd-apply.md"
        Afirmar (Test-Path $target) "Debe existir $target en copia temporal"
        Add-Content -Path $target -Value "`n# Cambio no sincronizado" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath "$dir/scripts/generar-plantillas.ps1" -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "-Comprobar debe fallar con comando editado a mano"
        Afirmar ($res.Output -match "odd-apply\.md") "La salida debe nombrar odd-apply.md: $($res.Output)"
    }
}

# test-plan: odd-apply/S04
Probar "S04 matriz con el comando ODD" {
    $readmePath = "$repoRoot/templates/README.md"
    Afirmar (Test-Path $readmePath) "Debe existir templates/README.md"
    $txt = (Get-Content -Path $readmePath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    Afirmar ($txt -match '\|\s*Comando ODD\s*\|') "README.md debe tener la columna 'Comando ODD'"
    Afirmar ($txt -match 'Antigravity.*odd-apply') "Fila de Antigravity debe mencionar odd-apply"
    Afirmar ($txt -match 'Cursor.*odd-apply') "Fila de Cursor debe mencionar odd-apply"
    Afirmar ($txt -match 'Copilot.*odd-apply') "Fila de Copilot debe mencionar odd-apply"
    Afirmar ($txt -match 'Codex.*(?:no soportado|No soportado)') "Fila de Codex debe indicar no soportado"
}

# test-plan: odd-apply/S10
Probar "S10 handoff ODD en las plantillas distingue falta en el alcance de escalar a SDD" {
    $plantillas = @(
        "$repoRoot/templates/comun/AGENTS.md",
        "$repoRoot/templates/copilot/copilot-instructions.md",
        "$repoRoot/templates/cursor/sdd-workflow.mdc",
        "$repoRoot/templates/antigravity/GEMINI.md"
    )
    foreach ($p in $plantillas) {
        Afirmar (Test-Path $p) "Debe existir $p"
        $txt = Get-Content -Path $p -Raw -Encoding UTF8
        Afirmar ($txt.Contains('falta en el alcance')) "$p debe contener 'falta en el alcance'"
        Afirmar ($txt.Contains('escalar a SDD')) "$p debe contener 'escalar a SDD'"
        Afirmar ($txt.Contains('cambiar una spec vigente')) "$p debe contener 'cambiar una spec vigente'"
    }
}

# test-plan: odd-apply/S12
Probar "S12 handoff ODD con comando del Agente en skill y comando" {
    $skill = "$repoRoot/skills/odd-change/SKILL.md"
    Afirmar (Test-Path $skill) "Debe existir $skill"
    $skillTxt = Get-Content -Path $skill -Raw -Encoding UTF8
    Afirmar ($skillTxt.Contains('/odd-apply')) "$skill debe mencionar '/odd-apply'"
    Afirmar ($skillTxt.Contains('falta en el alcance')) "$skill debe contemplar 'falta en el alcance'"

    $cmd = "$repoRoot/.claude/commands/odd.md"
    Afirmar (Test-Path $cmd) "Debe existir $cmd"
    $cmdTxt = Get-Content -Path $cmd -Raw -Encoding UTF8
    Afirmar ($cmdTxt.Contains('/odd-apply')) "$cmd debe mencionar '/odd-apply'"
    Afirmar ($cmdTxt.Contains('falta en el alcance')) "$cmd debe contemplar 'falta en el alcance'"
}

# test-plan: odd-apply/S05
Probar "S05 máquina con Antigravity instala skill odd-apply" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path "$dest/.gemini" -Force | Out-Null

        $res = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/instalar.ps1" -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        $skillDest = "$dest/.gemini/skills/odd-apply/SKILL.md"
        Afirmar (Test-Path $skillDest) "Debe existir $skillDest"
        $manifiesto = "$dest/.claude/.sdd-global-config.json"
        Afirmar (Test-Path $manifiesto) "Debe existir manifiesto"
        $manifiestoTxt = Get-Content -Path $manifiesto -Raw -Encoding UTF8
        Afirmar ($manifiestoTxt.Contains(".gemini/skills/odd-apply/SKILL.md")) "Manifiesto debe registrar la skill odd-apply"
    }
}

# test-plan: odd-apply/S06
Probar "S06 máquina sin Antigravity no crea .gemini" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        $res = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/instalar.ps1" -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        Afirmar (-not (Test-Path "$dest/.gemini")) "No debe crearse carpeta .gemini"
    }
}

# test-plan: odd-apply/S07
Probar "S07 proyecto con Copilot instala odd-apply sin tocar opsx" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github/prompts" -Force | Out-Null
        $opsxContenido = "prompt opsx de prueba"
        Set-Content -Path "$dir/.github/prompts/opsx-apply.prompt.md" -Value $opsxContenido -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/sincronizar-proyecto.ps1" -Argumentos "-Proyecto `"$dir`" -Agentes copilot"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló: $($res.Output)"

        $oddPrompt = "$dir/.github/prompts/odd-apply.prompt.md"
        Afirmar (Test-Path $oddPrompt) "Debe existir odd-apply.prompt.md"

        $opsxActual = Get-Content -Path "$dir/.github/prompts/opsx-apply.prompt.md" -Raw -Encoding UTF8
        Afirmar ($opsxActual.Trim() -eq $opsxContenido) "opsx-apply.prompt.md no debe ser modificado"
    }
}

# test-plan: odd-apply/S08
Probar "S08 proyecto con Cursor instala odd-apply" {
    Con-CarpetaTemporal { param($dir)
        $res = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/sincronizar-proyecto.ps1" -Argumentos "-Proyecto `"$dir`" -Agentes cursor"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló: $($res.Output)"

        $cursorCmd = "$dir/.cursor/commands/odd-apply.md"
        Afirmar (Test-Path $cursorCmd) "Debe existir $cursorCmd"
    }
}

# test-plan: odd-apply/S09
Probar "S09 comprobar con comando atrasado falla" {
    Con-CarpetaTemporal { param($dir)
        $res = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/sincronizar-proyecto.ps1" -Argumentos "-Proyecto `"$dir`" -Agentes cursor"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 inicial falló: $($res.Output)"

        $cursorCmd = "$dir/.cursor/commands/odd-apply.md"
        Afirmar (Test-Path $cursorCmd) "Debe existir $cursorCmd"
        Set-Content -Path $cursorCmd -Value "# Versión vieja desactualizada" -Encoding UTF8

        $resComp = Ejecutar-Pwsh -ScriptPath "$repoRoot/scripts/sincronizar-proyecto.ps1" -Argumentos "-Proyecto `"$dir`" -Agentes cursor -Comprobar"
        Afirmar ($resComp.ExitCode -ne 0) "-Comprobar debe fallar con comando atrasado"
        Afirmar ($resComp.Output -match "odd-apply\.md") "La salida debe mencionar odd-apply.md: $($resComp.Output)"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
