# tests/generar-plantillas.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

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
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S18
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
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S31
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
        Afirmar ($res.Output -match "El bloque de reglas de \.claude/CLAUDE\.md difiere") "La salida debe indicar que el bloque de reglas de .claude/CLAUDE.md difiere: $($res.Output)"
    }
}

# test-plan: sincronizar-reglas/S05
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S22
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

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S01
Probar "reglas-fuente-unica/S01 bloque generado desde el fragmento" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        $fragFile = "$dir/templates/fuente/fragmentos/reglas-ejecucion.md"
        $claudeFile = "$dir/.claude/CLAUDE.md"

        # Modificar una palabra de la regla 3 en el fragmento
        $fragTxt = Get-Content -Path $fragFile -Raw -Encoding UTF8
        $fragMod = $fragTxt.Replace("No debilitar tests", "No debilitar tests nunca")
        Set-Content -Path $fragFile -Value $fragMod -Encoding UTF8

        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($res.Output)"

        $claudeTxt = (Get-Content -Path $claudeFile -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $marcaInicio = "<!-- inicio: reglas-ejecucion -->"
        $marcaFin = "<!-- fin: reglas-ejecucion -->"

        $matchesInicio = [regex]::Matches($claudeTxt, [regex]::Escape($marcaInicio))
        $matchesFin = [regex]::Matches($claudeTxt, [regex]::Escape($marcaFin))
        Afirmar ($matchesInicio.Count -eq 1) "La marca de inicio debe aparecer exactamente una vez en CLAUDE.md"
        Afirmar ($matchesFin.Count -eq 1) "La marca de fin debe aparecer exactamente una vez en CLAUDE.md"

        $idxInicio = $claudeTxt.IndexOf($marcaInicio)
        $idxFin = $claudeTxt.IndexOf($marcaFin)
        Afirmar ($idxFin -gt $idxInicio) "La marca de fin debe ir después de la de inicio"

        $bloque = $claudeTxt.Substring($idxInicio + $marcaInicio.Length, $idxFin - ($idxInicio + $marcaInicio.Length)).Trim("`n", "`r")
        $fragNorm = ((Get-Content -Path $fragFile -Raw -Encoding UTF8) -replace "\r\n", "`n").Trim("`n", "`r")
        Afirmar ($bloque -eq $fragNorm) "El bloque entre marcas de CLAUDE.md debe ser igual al fragmento"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S02
Probar "reglas-fuente-unica/S02 el resto del CLAUDE.md no cambia" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        $claudeFile = "$dir/.claude/CLAUDE.md"

        $marcaInicio = "<!-- inicio: reglas-ejecucion -->"
        $marcaFin = "<!-- fin: reglas-ejecucion -->"

        $claudeOriginal = (Get-Content -Path $claudeFile -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $idxInicio = $claudeOriginal.IndexOf($marcaInicio)
        $idxFin = $claudeOriginal.IndexOf($marcaFin)
        Afirmar ($idxInicio -ge 0) "CLAUDE.md debe contener marca de inicio"
        Afirmar ($idxFin -ge 0) "CLAUDE.md debe contener marca de fin"

        $antesEsperado = $claudeOriginal.Substring(0, $idxInicio)
        $despuesEsperado = $claudeOriginal.Substring($idxFin + $marcaFin.Length)

        # Dejar el bloque atrasado
        $claudeModificado = $antesEsperado + "$marcaInicio`n1. **Regla vieja:** bloque atrasado de prueba`n$marcaFin" + $despuesEsperado
        Set-Content -Path $claudeFile -Value $claudeModificado -NoNewline -Encoding UTF8

        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -eq 0) "generar-plantillas.ps1 falló: $($res.Output)"

        $claudeDespues = (Get-Content -Path $claudeFile -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $idxInicioDespues = $claudeDespues.IndexOf($marcaInicio)
        $idxFinDespues = $claudeDespues.IndexOf($marcaFin)

        $antesDespues = $claudeDespues.Substring(0, $idxInicioDespues)
        $despuesDespues = $claudeDespues.Substring($idxFinDespues + $marcaFin.Length)

        Afirmar ($antesDespues -eq $antesEsperado) "El texto anterior a la marca de inicio no debió cambiar"
        Afirmar ($despuesDespues -eq $despuesEsperado) "El texto posterior a la marca de fin no debió cambiar"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S03
Probar "reglas-fuente-unica/S03 marcas faltantes" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        $claudeFile = "$dir/.claude/CLAUDE.md"

        $marcaFin = "<!-- fin: reglas-ejecucion -->"
        $claudeTxt = (Get-Content -Path $claudeFile -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $claudeTxt = $claudeTxt.Replace($marcaFin, "")
        if (-not ($claudeTxt.Contains("<!-- inicio: reglas-ejecucion -->"))) {
            $claudeTxt = "<!-- inicio: reglas-ejecucion -->`n" + $claudeTxt
        }
        Set-Content -Path $claudeFile -Value $claudeTxt -Encoding UTF8

        $hashClaudeAntes = (Get-FileHash $claudeFile).Hash
        $hashPlantillaAntes = (Get-FileHash "$dir/templates/comun/AGENTS.md").Hash

        $res = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "generar-plantillas.ps1 debió fallar por marca de fin faltante"
        Afirmar ($res.Output -match "\.claude/CLAUDE\.md" -or $res.Output -match "CLAUDE\.md") "La salida debe nombrar .claude/CLAUDE.md: $($res.Output)"
        Afirmar ($res.Output -match [regex]::Escape($marcaFin)) "La salida debe nombrar la marca faltante: $($res.Output)"

        $hashClaudeDespues = (Get-FileHash $claudeFile).Hash
        $hashPlantillaDespues = (Get-FileHash "$dir/templates/comun/AGENTS.md").Hash
        Afirmar ($hashClaudeAntes -eq $hashClaudeDespues) "CLAUDE.md no debió cambiar ante error"
        Afirmar ($hashPlantillaAntes -eq $hashPlantillaDespues) "Ninguna plantilla debió cambiar ante error"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S21
Probar "reglas-fuente-unica/S21 bloque de reglas del CLAUDE.md editado a mano" {
    Con-CarpetaTemporal { param($dir)
        Copiar-EntornoTemporal $dir
        $script = "$dir/scripts/generar-plantillas.ps1"
        $claudeFile = "$dir/.claude/CLAUDE.md"

        # Generar primero
        $resGen = Ejecutar-PwshScript -ScriptPath $script -WorkingDir $dir

        # Cambiar una palabra del cuerpo de la regla 4 dentro del bloque de .claude/CLAUDE.md
        # sin tocar su título ni la fuente
        $claudeTxt = Get-Content -Path $claudeFile -Raw -Encoding UTF8
        Afirmar ($claudeTxt.Contains("selectores, rutas, endpoints")) "CLAUDE.md debe contener el cuerpo de la regla 4"
        $claudeTxtMod = $claudeTxt.Replace("selectores, rutas, endpoints", "selectores, rutas, endpoints_modificados")
        Set-Content -Path $claudeFile -Value $claudeTxtMod -Encoding UTF8
        $hashAntes = (Get-FileHash $claudeFile).Hash

        $res = Ejecutar-PwshScript -ScriptPath $script -Argumentos "-Comprobar" -WorkingDir $dir
        Afirmar ($res.ExitCode -ne 0) "Comprobar debió fallar por edición en el cuerpo de la regla: $($res.Output)"
        Afirmar ($res.Output -match [regex]::Escape(".claude/CLAUDE.md")) "La salida debe nombrar .claude/CLAUDE.md: $($res.Output)"

        $hashDespues = (Get-FileHash $claudeFile).Hash
        Afirmar ($hashAntes -eq $hashDespues) "El archivo no debe cambiar en -Comprobar"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
