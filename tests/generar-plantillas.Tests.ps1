# tests/generar-plantillas.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$antesDir = "$PSScriptRoot/datos/plantillas-antes"

function Limpiar-PlantillaParaC01 {
    param([string]$Texto)
    $t = $Texto -replace "\r\n", "`n"
    $aviso = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
    
    if ($t.StartsWith($aviso + "`n`n")) {
        $t = $t.Substring(($aviso + "`n`n").Length)
    } elseif ($t.StartsWith($aviso + "`n")) {
        $t = $t.Substring(($aviso + "`n").Length)
    } elseif ($t -match "(?s)^(---\n.*?\n---\n\n)$([regex]::Escape($aviso))\n\n(.*)$") {
        $t = $matches[1] + $matches[2]
    }
    
    $idxPropio = $t.IndexOf("`n## Propio del proyecto")
    if ($idxPropio -ge 0) {
        $t = $t.Substring(0, $idxPropio)
    } elseif ($t.StartsWith("## Propio del proyecto")) {
        $t = ""
    }

    # Quita (a) clasificacion-odd-sdd: bloque desde ## Handoff ODD hasta la línea anterior al siguiente título ##
    if ($t -match "(?m)^## Handoff ODD\n") {
        $t = [regex]::Replace($t, "(?ms)^## Handoff ODD\n.*?\n(?=## )", "")
    }

    # Quita (b) clasificacion-odd-sdd: oración exacta de excepción ODD en regla 7
    $oracionOdd = ' En un handoff ODD, pegá la evidencia en `## Evidencia` del documento ODD y no escribas la nota `apply\` del vault.'
    if ($t.Contains($oracionOdd)) {
        $t = $t.Replace($oracionOdd, "")
    }
    
    return $t.TrimEnd("`n", "`r", " ")
}

function Copiar-EntornoTemporal {
    param([string]$Dir)
    New-Item -ItemType Directory -Path "$Dir/templates" -Force | Out-Null
    Copy-Item -Recurse "$repoRoot/templates/*" "$Dir/templates/"
    New-Item -ItemType Directory -Path "$Dir/scripts" -Force | Out-Null
    if (Test-Path "$repoRoot/scripts") {
        Copy-Item -Recurse "$repoRoot/scripts/*" "$Dir/scripts/"
    }
    New-Item -ItemType Directory -Path "$Dir/.claude" -Force | Out-Null
    Copy-Item "$repoRoot/.claude/CLAUDE.md" "$Dir/.claude/CLAUDE.md"
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
    }
}

# test-plan: sincronizar-reglas/C01
# test-plan: clasificacion-odd-sdd/C01
Probar "C01 plantillas sin cambios de texto" {
    $plantillas = @(
        @{ Actual = "$repoRoot/templates/comun/AGENTS.md"; Antes = "$antesDir/AGENTS.md" },
        @{ Actual = "$repoRoot/templates/copilot/copilot-instructions.md"; Antes = "$antesDir/copilot-instructions.md" },
        @{ Actual = "$repoRoot/templates/cursor/sdd-workflow.mdc"; Antes = "$antesDir/sdd-workflow.mdc" },
        @{ Actual = "$repoRoot/templates/antigravity/GEMINI.md"; Antes = "$antesDir/GEMINI.md" }
    )

    foreach ($p in $plantillas) {
        Afirmar (Test-Path $p.Actual) "No existe la plantilla actual $($p.Actual)"
        Afirmar (Test-Path $p.Antes) "No existe la copia de referencia $($p.Antes)"

        $txtActual = Get-Content -Path $p.Actual -Raw -Encoding UTF8
        $txtAntes = Get-Content -Path $p.Antes -Raw -Encoding UTF8

        $limpioActual = Limpiar-PlantillaParaC01 $txtActual
        $limpioAntes = Limpiar-PlantillaParaC01 $txtAntes

        Afirmar ($limpioActual -eq $limpioAntes) "El texto de $($p.Actual) difiere de $($p.Antes)"
    }
}

# test-plan: sincronizar-reglas/S01
Probar "S01 generar plantillas desde la fuente" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 terminó con código $($res.ExitCode): $($res.Output)"

        $plantillas = @(
            "$dir/templates/comun/AGENTS.md",
            "$dir/templates/copilot/copilot-instructions.md",
            "$dir/templates/cursor/sdd-workflow.mdc",
            "$dir/templates/antigravity/GEMINI.md"
        )
        foreach ($p in $plantillas) {
            Afirmar (Test-Path $p) "No existe $p"
            $txt = Get-Content -Path $p -Raw -Encoding UTF8
            Afirmar ($txt -match "Evidencia antes de ``\[x\]``") "$p no contiene el fragmento de reglas"
            Afirmar ($txt -notmatch "<!-- incluir: reglas-ejecucion -->") "$p contiene la marca sin reemplazar"
        }
    }
}

# test-plan: sincronizar-reglas/S02
Probar "S02 generar falla con fragmento inexistente" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        $esq = "$dir/templates/fuente/esqueletos/AGENTS.md"
        Afirmar (Test-Path $esq) "No existe esqueleto $esq"
        Add-Content -Path $esq -Value "`n<!-- incluir: no-existe -->"

        $hashAntes = (Get-FileHash "$dir/templates/comun/AGENTS.md").Hash

        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "generar-plantillas.ps1 debió fallar ante fragmento inexistente"
        Afirmar ($res.Output -match "no-existe") "La salida debe nombrar el fragmento no-existe: $($res.Output)"
        Afirmar ($res.Output -match "AGENTS\.md") "La salida debe nombrar el esqueleto AGENTS.md: $($res.Output)"

        $hashDespues = (Get-FileHash "$dir/templates/comun/AGENTS.md").Hash
        Afirmar ($hashAntes -eq $hashDespues) "Ninguna plantilla debió cambiar ante error"
    }
}

# test-plan: sincronizar-reglas/S03
Probar "S03 comprobar falla si una plantilla se editó a mano" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        # Generar primero
        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "Generación previa falló"

        # Modificar plantilla a mano
        Add-Content -Path "$dir/templates/cursor/sdd-workflow.mdc" -Value "`nLínea agregada a mano"

        $res = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "Comprobar debió fallar por edición a mano"
        Afirmar ($res.Output -match "sdd-workflow\.mdc") "La salida debe nombrar sdd-workflow.mdc: $($res.Output)"
    }
}

# test-plan: sincronizar-reglas/S04
Probar "S04 comprobar falla si reglas de CLAUDE.md tienen otro título" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        # Generar primero
        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "Generación previa falló"

        # Cambiar título en CLAUDE.md
        $claudeFile = "$dir/.claude/CLAUDE.md"
        $claudeTxt = Get-Content -Path $claudeFile -Raw -Encoding UTF8
        $claudeTxt = $claudeTxt.Replace("4. **No inventar:**", "4. **No inventar nada:**")
        Set-Content -Path $claudeFile -Value $claudeTxt -Encoding UTF8

        $res = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "Comprobar debió fallar por títulos distintos en CLAUDE.md"
        Afirmar ($res.Output -match "No inventar nada" -or $res.Output -match "títulos") "La salida debe mostrar las diferencias de títulos: $($res.Output)"
    }
}

# test-plan: sincronizar-reglas/S05
Probar "S05 comprobar pasa si todo está sincronizado" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "Generación previa falló"

        $res = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "Comprobar debió pasar con código 0: $($res.Output)"
    }
}

# test-plan: sincronizar-reglas/S21
Probar "S21 plantillas con aviso y sección propia" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        Afirmar (Test-Path $script) "No existe $script"

        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($resGen.ExitCode -eq 0) "Generación previa falló"

        $aviso = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
        $propio = "## Propio del proyecto"
        $propioComentario = '<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->'

        $plantillas = @(
            "$dir/templates/comun/AGENTS.md",
            "$dir/templates/copilot/copilot-instructions.md",
            "$dir/templates/cursor/sdd-workflow.mdc",
            "$dir/templates/antigravity/GEMINI.md"
        )

        foreach ($p in $plantillas) {
            $txt = (Get-Content -Path $p -Raw -Encoding UTF8) -replace "\r\n", "`n"
            if ($p -match "\.mdc$") {
                Afirmar ($txt -match "(?s)^---\n.*?\n---\n\n$([regex]::Escape($aviso))\n\n") "$p debe tener el aviso justo después del frontmatter"
            } else {
                Afirmar ($txt.StartsWith($aviso + "`n`n")) "$p debe comenzar con el aviso de archivo generado"
            }
            Afirmar ($txt -match "(?s)\n## Propio del proyecto\n$([regex]::Escape($propioComentario))\n?$") "$p debe terminar con ## Propio del proyecto y comentario"
        }
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
