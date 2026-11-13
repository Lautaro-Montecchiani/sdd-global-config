# tests/aviso-proyecto-atrasado.Tests.ps1

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

function Obtener-HashesDirectorio {
    param([string]$Dir)
    $hashes = @{}
    Get-ChildItem -Path $Dir -Recurse -File | ForEach-Object {
        $rel = $_.FullName.Substring($Dir.Length).TrimStart('\', '/')
        $hashes[$rel] = (Get-FileHash $_.FullName).Hash
    }
    return $hashes
}

# test-plan: aviso-proyecto-atrasado/S01
Probar "S01 Proyecto al día" {
    Con-CarpetaTemporal { param($dir)
        Copy-Item "$repoRoot/templates/comun/AGENTS.md" "$dir/AGENTS.md"
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        Copy-Item "$repoRoot/templates/copilot/copilot-instructions.md" "$dir/.github/copilot-instructions.md"

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -eq 0) "Aviso en proyecto al día debe salir con código 0. Salida: $($res.Output)"
    }
}

# test-plan: aviso-proyecto-atrasado/S02
Probar "S02 Archivo atrasado" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        $versionVieja = git -C $repoRoot show "998c010:templates/copilot/copilot-instructions.md"
        Afirmar ($null -ne $versionVieja -and $versionVieja.Count -gt 0) "No se pudo obtener versión vieja de git"
        Set-Content -Path "$dir/.github/copilot-instructions.md" -Value ($versionVieja -join "`n") -Encoding UTF8

        $hashesAntes = Obtener-HashesDirectorio $dir

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -ne 0) "Aviso con archivo atrasado debe salir con código distinto de 0"
        Afirmar ($res.Output -match "(?i)Aviso:.*desactualizadas") "La salida debe indicar reglas desactualizadas: $($res.Output)"
        Afirmar ($res.Output -match "Atrasados:") "La salida debe listar los archivos atrasados: $($res.Output)"

        $hashesDespues = Obtener-HashesDirectorio $dir
        Afirmar ($hashesAntes.Count -eq $hashesDespues.Count) "La cantidad de archivos cambió"
        foreach ($k in $hashesAntes.Keys) {
            Afirmar ($hashesAntes[$k] -eq $hashesDespues[$k]) "El archivo $k no debió modificarse"
        }
    }
}

# test-plan: aviso-proyecto-atrasado/S03
Probar "S03 Contenido propio sin marcar" {
    Con-CarpetaTemporal { param($dir)
        Set-Content -Path "$dir/AGENTS.md" -Value "Texto arbitrario sin sección propia ni versión git" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -ne 0) "Aviso con contenido propio sin marcar debe salir con código distinto de 0"
        Afirmar ($res.Output -match "Bloqueados por contenido propio:") "La salida debe indicar bloqueados por contenido propio: $($res.Output)"
    }
}

# test-plan: aviso-proyecto-atrasado/S04
Probar "S04 Solo archivos existentes" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        Copy-Item "$repoRoot/templates/copilot/copilot-instructions.md" "$dir/.github/copilot-instructions.md"

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -eq 0) "Aviso con solo copilot al día debe salir con código 0. Salida: $($res.Output)"
        Afirmar (-not ($res.Output -match "AGENTS\.md")) "La salida no debe mencionar AGENTS.md si no existe"
    }
}

# test-plan: aviso-proyecto-atrasado/S05
Probar "S05 Proyecto sin archivos del Agente" {
    Con-CarpetaTemporal { param($dir)
        Set-Content -Path "$dir/otro.txt" -Value "archivo cualquiera" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -eq 0) "Aviso en proyecto sin archivos del Agente debe salir con código 0. Salida: $($res.Output)"
    }
}

# test-plan: aviso-proyecto-atrasado/S06
Probar "S06 Parámetros incompatibles" {
    Con-CarpetaTemporal { param($dir)
        Copy-Item "$repoRoot/templates/comun/AGENTS.md" "$dir/AGENTS.md"
        $hashesAntes = Obtener-HashesDirectorio $dir

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso -Comprobar"
        Afirmar ($res.ExitCode -ne 0) "Parámetros incompatibles (-Aviso -Comprobar) debe fallar con código != 0"
        Afirmar ($res.Output -match "(?i)-Aviso no se combina|incompatible") "La salida debe avisar que -Aviso no se combina con otros modos: $($res.Output)"

        $hashesDespues = Obtener-HashesDirectorio $dir
        foreach ($k in $hashesAntes.Keys) {
            Afirmar ($hashesAntes[$k] -eq $hashesDespues[$k]) "El archivo $k no debió modificarse"
        }
    }
}

# test-plan: aviso-proyecto-atrasado/S07
Probar "S07 Dato inválido: archivo del Agente vacío" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType File -Path "$dir/AGENTS.md" -Force | Out-Null

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -ne 0) "Archivo del agente vacío debe tratarse como bloqueado y salir != 0"
        Afirmar ($res.Output -match "Bloqueados por contenido propio:") "La salida debe indicar bloqueados por contenido propio: $($res.Output)"
    }
}

# test-plan: aviso-proyecto-atrasado/S08
Probar "S08 Salida del aviso de proyecto / Línea al día" {
    Con-CarpetaTemporal { param($dir)
        Copy-Item "$repoRoot/templates/comun/AGENTS.md" "$dir/AGENTS.md"

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        $lineas = @(($res.Stdout.Trim() -split "\r?\n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Afirmar ($lineas.Count -eq 1) "La salida de -Aviso debe ser exactamente una línea. Salida: $($res.Stdout)"
        Afirmar ($lineas[0] -match "Reglas del Agente al día en este proyecto\.") "Línea debe coincidir con D1: $($lineas[0])"
    }
}

# test-plan: aviso-proyecto-atrasado/S09
Probar "S09 Salida del aviso de proyecto / Línea con atrasados" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        $versionVieja = git -C $repoRoot show "998c010:templates/copilot/copilot-instructions.md"
        Set-Content -Path "$dir/.github/copilot-instructions.md" -Value ($versionVieja -join "`n") -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        $lineas = @(($res.Stdout.Trim() -split "\r?\n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Afirmar ($lineas.Count -eq 1) "La salida de -Aviso debe ser exactamente una línea. Salida: $($res.Stdout)"
        Afirmar ($lineas[0] -match [regex]::Escape(".github/copilot-instructions.md")) "Línea debe nombrar .github/copilot-instructions.md: $($lineas[0])"
        Afirmar ($lineas[0] -match [regex]::Escape("sincronizar-proyecto.ps1 -Proyecto .")) "Línea debe incluir sincronizar-proyecto.ps1 -Proyecto ."
    }
}

# test-plan: aviso-proyecto-atrasado/S10
Probar "S10 Salida del aviso de proyecto / Línea con bloqueados" {
    Con-CarpetaTemporal { param($dir)
        Set-Content -Path "$dir/AGENTS.md" -Value "Contenido propio sin marcar" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        $lineas = @(($res.Stdout.Trim() -split "\r?\n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Afirmar ($lineas.Count -eq 1) "La salida de -Aviso debe ser exactamente una línea. Salida: $($res.Stdout)"
        Afirmar ($lineas[0] -match "AGENTS\.md") "Línea debe nombrar AGENTS.md: $($lineas[0])"
        Afirmar ($lineas[0] -match [regex]::Escape("## Propio del proyecto")) "Línea debe mencionar ## Propio del proyecto"
    }
}

# test-plan: aviso-proyecto-atrasado/S11
Probar "S11 Salida del aviso de proyecto / Línea sin archivos del Agente" {
    Con-CarpetaTemporal { param($dir)
        Set-Content -Path "$dir/readme.txt" -Value "nada" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        $lineas = @(($res.Stdout.Trim() -split "\r?\n") | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
        Afirmar ($lineas.Count -eq 1) "La salida de -Aviso debe ser exactamente una línea. Salida: $($res.Stdout)"
        Afirmar ($lineas[0] -match "Este proyecto no tiene archivos del Agente\.") "Línea debe coincidir con D1: $($lineas[0])"
    }
}

# test-plan: aviso-proyecto-atrasado/S12
Probar "S12 Salida del aviso de proyecto / Sin rutas absolutas en la salida" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github" -Force | Out-Null
        $versionVieja = git -C $repoRoot show "998c010:templates/copilot/copilot-instructions.md"
        Set-Content -Path "$dir/.github/copilot-instructions.md" -Value ($versionVieja -join "`n") -Encoding UTF8
        Set-Content -Path "$dir/AGENTS.md" -Value "Contenido propio sin marcar" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.Output -match "(?i)Aviso:.*desactualizadas") "La salida debe emitir el aviso: $($res.Output)"
        Afirmar (-not ($res.Output -match [regex]::Escape($dir))) "La salida no debe contener la ruta del proyecto"
        Afirmar (-not ($res.Output -match [regex]::Escape($repoRoot))) "La salida no debe contener la ruta del repo"
    }
}

# test-plan: aviso-proyecto-atrasado/S13
Probar "S13 Aviso al iniciar sesión en un proyecto / Paso en el inicio de sesión" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir $claudePath"
    $lineas = Get-Content -Path $claudePath -Encoding UTF8
    $lineaItem = $lineas | Where-Object { $_ -match "^\s*-\s+Comprobar el proyecto:" } | Select-Object -First 1
    Afirmar ($null -ne $lineaItem -and $lineaItem.Trim().Length -gt 0) "No se encontró el ítem '- Comprobar el proyecto:' en $claudePath"

    Afirmar ($lineaItem -match [regex]::Escape("sincronizar-proyecto.ps1 -Proyecto . -Aviso")) "El ítem debe contener 'sincronizar-proyecto.ps1 -Proyecto . -Aviso'"
    Afirmar ($lineaItem -match "sdd-global-config") "El ítem debe excluir sdd-global-config"
    Afirmar ($lineaItem -match "AGENTS\.md" -and $lineaItem -match [regex]::Escape(".github/workflows/pr-check.yml")) "El ítem debe listar archivos del Agente (AGENTS.md y .github/workflows/pr-check.yml)"
    Afirmar ($lineaItem -match "No sincronizar ni editar") "El ítem debe decir 'No sincronizar ni editar'"
}

# test-plan: aviso-proyecto-atrasado/S14
Probar "S14 Aviso al iniciar sesión en un proyecto / Sin variable del repo" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir $claudePath"
    $lineas = Get-Content -Path $claudePath -Encoding UTF8
    $lineaItem = $lineas | Where-Object { $_ -match "^\s*-\s+Comprobar el proyecto:" } | Select-Object -First 1
    Afirmar ($null -ne $lineaItem -and $lineaItem.Trim().Length -gt 0) "No se encontró el ítem '- Comprobar el proyecto:' en $claudePath"

    Afirmar ($lineaItem -match [regex]::Escape('$env:SDD_CONFIG_REPO')) "El ítem debe mencionar `$env:SDD_CONFIG_REPO"
    Afirmar ($lineaItem -match "avisar que no se pudo controlar el proyecto y continuar") "El ítem debe decir 'avisar que no se pudo controlar el proyecto y continuar'"
}

# test-plan: aviso-proyecto-atrasado/S15
Probar "S15 Aviso al iniciar sesión en un proyecto / Documentación del modo aviso" {
    $archivos = @(
        "$repoRoot/README.md",
        "$repoRoot/docs/modo-de-uso.md"
    )

    foreach ($archivo in $archivos) {
        Afirmar (Test-Path $archivo) "Debe existir $archivo"
        $lines = Get-Content -Path $archivo -Encoding UTF8
        $capturando = $false
        $tramoLineas = [System.Collections.Generic.List[string]]::new()
        foreach ($line in $lines) {
            if (-not $capturando) {
                if ($line -match "-Aviso") {
                    $capturando = $true
                    $tramoLineas.Add($line)
                }
            } else {
                if ($line -match "^\s*#") {
                    break
                }
                $tramoLineas.Add($line)
            }
        }

        Afirmar ($capturando) "No se encontró mención de -Aviso en $archivo"
        $tramo = $tramoLineas -join "`n"

        Afirmar ($tramo -match "(?i)archivos del agente") "El tramo de -Aviso en $archivo debe mencionar los archivos del Agente"
        Afirmar ($tramo -match "(?i)no escribe") "El tramo de -Aviso en $archivo debe mencionar 'no escribe'"
        Afirmar ($tramo -match "(?i)al iniciar cada sesión") "El tramo de -Aviso en $archivo debe mencionar 'al iniciar cada sesión'"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
