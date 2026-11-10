# tests/sincronizar-proyecto.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptSincronizar = "$repoRoot/scripts/sincronizar-proyecto.ps1"

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

# test-plan: sincronizar-reglas/S13
Probar "S13 proyecto nuevo crea agentes especificados" {
    Con-CarpetaTemporal { param($dir)
        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes comun,cursor"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló con código $($res.ExitCode): $($res.Output)"

        Afirmar (Test-Path "$dir/AGENTS.md") "No existe AGENTS.md en el proyecto"
        Afirmar (Test-Path "$dir/.cursor/rules/sdd-workflow.mdc") "No existe sdd-workflow.mdc en el proyecto"
        Afirmar (-not (Test-Path "$dir/.github/copilot-instructions.md")) "copilot-instructions.md no debió crearse"
    }
}

# test-plan: sincronizar-reglas/S14
Probar "S14 conserva contenido propio debajo del título" {
    Con-CarpetaTemporal { param($dir)
        $propio = "`n- Usar pnpm en este proyecto`n- Desplegar con Docker`n"
        $archivoBase = (Get-Content "$repoRoot/templates/comun/AGENTS.md" -Raw -Encoding UTF8) + $propio
        Set-Content -Path "$dir/AGENTS.md" -Value $archivoBase -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes comun"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló: $($res.Output)"

        $txt = Get-Content -Path "$dir/AGENTS.md" -Raw -Encoding UTF8
        Afirmar ($txt -match "Usar pnpm en este proyecto") "Debe conservar la línea propia Usar pnpm"
        Afirmar ($txt -match "Desplegar con Docker") "Debe conservar la línea propia Desplegar con Docker"
        Afirmar ($txt -match "Workflow SDD Híbrido") "Debe contener la plantilla de reglas"
    }
}

# test-plan: sincronizar-reglas/S15
Probar "S15 copia vieja reconocida en la historia se actualiza" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        $versionVieja = git -C $repoRoot show "998c010:templates/copilot/copilot-instructions.md"
        Afirmar ($null -ne $versionVieja -and $versionVieja.Count -gt 0) "No se pudo obtener la versión vieja desde git"
        Set-Content -Path "$dir/.github/copilot-instructions.md" -Value ($versionVieja -join "`n") -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes copilot"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló actualizando copia vieja: $($res.Output)"
        Afirmar ($res.Output -match "actualizado|igual") "La salida debe marcarlo actualizado: $($res.Output)"

        $txt = Get-Content -Path "$dir/.github/copilot-instructions.md" -Raw -Encoding UTF8
        Afirmar ($txt -match "## Propio del proyecto") "El archivo actualizado debe incluir ## Propio del proyecto"
    }
}

# test-plan: sincronizar-reglas/S16
Probar "S16 contenido propio sin marcar bloquea la sincronización" {
    Con-CarpetaTemporal { param($dir)
        Set-Content -Path "$dir/AGENTS.md" -Value "Contenido arbitrario sin sección propia ni historia" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes comun"
        Afirmar ($res.ExitCode -ne 0) "sincronizar-proyecto.ps1 debió fallar por contenido propio sin marcar"
        Afirmar ($res.Output -match "bloqueado") "La salida debe marcar bloqueado: $($res.Output)"

        $txt = Get-Content -Path "$dir/AGENTS.md" -Raw -Encoding UTF8
        Afirmar ($txt.Trim() -eq "Contenido arbitrario sin sección propia ni historia") "El archivo no debió modificarse"
    }
}

# test-plan: sincronizar-reglas/S17
Probar "S17 comprobar falla si está atrasado y pasa cuando está al día" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        $versionVieja = git -C $repoRoot show "998c010:templates/copilot/copilot-instructions.md"
        Set-Content -Path "$dir/.github/copilot-instructions.md" -Value ($versionVieja -join "`n") -Encoding UTF8

        $resComprobarAntes = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes copilot -Comprobar"
        Afirmar ($resComprobarAntes.ExitCode -ne 0) "Comprobar debió fallar cuando el archivo está atrasado"

        $resSinc = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes copilot"
        Afirmar ($resSinc.ExitCode -eq 0) "Sincronización falló"

        $resComprobarDespues = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes copilot -Comprobar"
        Afirmar ($resComprobarDespues.ExitCode -eq 0) "Comprobar debió pasar tras sincronizar: $($resComprobarDespues.Output)"
    }
}

# test-plan: sincronizar-reglas/S18
Probar "S18 no crea commits en el proyecto y deja cambios en el árbol de trabajo" {
    Con-CarpetaTemporal { param($dir)
        git -C $dir init 2>$null | Out-Null
        git -C $dir -c user.name="Tester" -c user.email="tester@example.com" commit --allow-empty -m "initial commit" 2>$null | Out-Null

        $countAntes = (git -C $dir rev-list --count HEAD).Trim()

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Agentes comun"
        Afirmar ($res.ExitCode -eq 0) "sincronizar-proyecto.ps1 falló: $($res.Output)"

        $countDespues = (git -C $dir rev-list --count HEAD).Trim()
        Afirmar ($countAntes -eq $countDespues) "El número de commits debió permanecer igual ($countAntes vs $countDespues)"

        $status = git -C $dir status --porcelain
        Afirmar ($status -match "AGENTS\.md") "git status debe mostrar AGENTS.md sin commitear"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
