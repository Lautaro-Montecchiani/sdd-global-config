# tests/statusline-instalable.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$repoRootConBarras = $repoRoot.Replace('\', '/')
$scriptInstalar = "$repoRoot/scripts/instalar.ps1"

function Obtener-ComandoBash {
    if (-not $IsWindows) { return "bash" }
    $git = Get-Command git -ErrorAction SilentlyContinue
    if ($git -and $git.Source) {
        $gitDir = Split-Path (Split-Path $git.Source -Parent) -Parent
        $gitBash = Join-Path $gitDir "bin/bash.exe"
        if (Test-Path $gitBash) { return $gitBash }
    }
    if ($env:ProgramFiles) {
        $p = Join-Path $env:ProgramFiles "Git/bin/bash.exe"
        if (Test-Path $p) { return $p }
    }
    return "bash"
}

function Ejecutar-BashStatusline {
    param(
        [string]$ScriptPath,
        [string]$InputJson,
        [string]$WorkingDir = ""
    )
    $bash = Obtener-ComandoBash
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $bash
    $psi.Arguments = "`"$ScriptPath`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    if ($WorkingDir) {
        $psi.WorkingDirectory = $WorkingDir
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    if ($InputJson) {
        $proc.StandardInput.Write($InputJson)
    }
    $proc.StandardInput.Close()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{
        ExitCode = $proc.ExitCode
        Output = $stdout
        Stderr = $stderr
        SinAnsi = ($stdout -replace '\x1b\[[0-9;]*[a-zA-Z]', '')
    }
}

function Ejecutar-AntigravityStatusline {
    param(
        [string]$ScriptPath,
        [string]$InputJson,
        [string]$WorkingDir = ""
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "pwsh"
    $psi.Arguments = "-NoProfile -File `"$ScriptPath`""
    $psi.RedirectStandardInput = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    if ($WorkingDir) {
        $psi.WorkingDirectory = $WorkingDir
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    if ($InputJson) {
        $proc.StandardInput.Write($InputJson)
    }
    $proc.StandardInput.Close()
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{
        ExitCode = $proc.ExitCode
        Output = $stdout
        Stderr = $stderr
        SinAnsi = ($stdout -replace '\x1b\[[0-9;]*[a-zA-Z]', '')
    }
}

function Ejecutar-Instalar {
    param(
        [string]$Argumentos = ""
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "pwsh"
    $psi.Arguments = "-NoProfile -File `"$scriptInstalar`" $Argumentos"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
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

# test-plan: statusline-instalable/C02
Probar "statusline-instalable/C02 caracterizacion actual de statusline.sh" {
    $script = "$repoRoot/.claude/statusline.sh"
    Afirmar (Test-Path $script) "Debe existir $script"
    $entradaS14 = '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25}}}'
    $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson $entradaS14
    Afirmar ($res.ExitCode -eq 0) "El script debe salir con código 0"
    $lineas = ($res.SinAnsi -split "`r?`n") | Where-Object { $_ -ne "" }
    Afirmar ($lineas.Count -ge 2) "Debe tener al menos 2 líneas"
    Afirmar ($lineas[0] -match "mi-proyecto") "Línea 1 debe tener nombre de carpeta 'mi-proyecto'"
    Afirmar ($lineas[0] -match "50%") "Línea 1 debe tener '50%'"
    Afirmar ($lineas[0] -match "25%") "Línea 1 debe tener '25%'"
    Afirmar ($lineas[0] -match "\([^)]+\)") "Línea 1 debe tener la rama entre paréntesis"
    Afirmar ($lineas[1] -match "Modelo Ejemplo") "Línea 2 debe tener 'Modelo Ejemplo'"
}

# test-plan: statusline-instalable/S01
Probar "statusline-instalable/S01 Barra de Claude Code instalada por maquina / Destino sin settings.json" {
    Con-CarpetaTemporal { param($temp)
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $settingsPath = Join-Path $temp ".claude/settings.json"
        Afirmar (Test-Path $settingsPath) "Debe existir $settingsPath"
        $json = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.statusLine.type -eq "command") "statusLine.type debe ser command"
        Afirmar ($json.statusLine.command -eq "bash `"$repoRootConBarras/.claude/statusline.sh`"") "statusLine.command debe ser el esperado"
    }
}

# test-plan: statusline-instalable/S02
Probar "statusline-instalable/S02 Barra de Claude Code instalada por maquina / Forma anterior con variable de entorno" {
    Con-CarpetaTemporal { param($temp)
        $claudeDir = Join-Path $temp ".claude"
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        $oldSettings = @{
            statusLine = @{
                type = "command"
                command = 'bash "$SDD_CONFIG_REPO/.claude/statusline.sh"'
            }
        } | ConvertTo-Json
        Set-Content -Path (Join-Path $claudeDir "settings.json") -Value $oldSettings -Encoding UTF8
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $json = Get-Content (Join-Path $claudeDir "settings.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.statusLine.command -eq "bash `"$repoRootConBarras/.claude/statusline.sh`"") "statusLine.command debe actualizarse con la ruta absoluta"
        Afirmar ($res.Output -match "settings:\s*barra Claude.*atrasado") "La tabla debe mostrar la barra de Claude como atrasado"
    }
}

# test-plan: statusline-instalable/S03
Probar "statusline-instalable/S03 Barra de Antigravity CLI instalada por maquina / Barra apagada" {
    Con-CarpetaTemporal { param($temp)
        $agyDir = Join-Path $temp ".gemini/antigravity-cli"
        New-Item -ItemType Directory -Path $agyDir -Force | Out-Null
        $destBarras = $temp.Replace('\', '/')
        $initialSettings = [ordered]@{
            allowNonWorkspaceAccess = $true
            permissions = @{
                allow = @("command(git status)")
            }
            statusLine = @{
                type = "command"
                command = "$destBarras/.gemini/antigravity-cli/scratch/statusline.bat"
                enabled = $false
            }
            toolPermission = "always-proceed"
            trustedWorkspaces = @("C:/test")
        } | ConvertTo-Json -Depth 5
        Set-Content -Path (Join-Path $agyDir "settings.json") -Value $initialSettings -Encoding UTF8
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $json = Get-Content (Join-Path $agyDir "settings.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.statusLine.enabled -eq $true) "statusLine.enabled debe quedar en true"
        Afirmar ($json.toolPermission -eq "always-proceed") "toolPermission debe ser igual"
        Afirmar ($json.permissions.allow[0] -eq "command(git status)") "permissions debe ser igual"
        Afirmar ($json.trustedWorkspaces[0] -eq "C:/test") "trustedWorkspaces debe ser igual"
    }
}

# test-plan: statusline-instalable/S04
Probar "statusline-instalable/S04 Barra de Antigravity CLI instalada por maquina / Scripts instalados" {
    Con-CarpetaTemporal { param($temp)
        $agyDir = Join-Path $temp ".gemini/antigravity-cli"
        New-Item -ItemType Directory -Path $agyDir -Force | Out-Null
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $batDest = Join-Path $agyDir "scratch/statusline.bat"
        $ps1Dest = Join-Path $agyDir "scratch/statusline_new.ps1"
        Afirmar (Test-Path $batDest) "Debe existir scratch/statusline.bat"
        Afirmar (Test-Path $ps1Dest) "Debe existir scratch/statusline_new.ps1"
        $batSrc = "$repoRoot/templates/antigravity/statusline.bat"
        $ps1Src = "$repoRoot/templates/antigravity/statusline_new.ps1"
        Afirmar (Test-Path $batSrc) "Debe existir $batSrc"
        Afirmar (Test-Path $ps1Src) "Debe existir $ps1Src"
        Afirmar ((Get-Content $batDest -Raw) -eq (Get-Content $batSrc -Raw)) "statusline.bat debe tener el mismo contenido que la fuente"
        Afirmar ((Get-Content $ps1Dest -Raw) -eq (Get-Content $ps1Src -Raw)) "statusline_new.ps1 debe tener el mismo contenido que la fuente"
        $manifestPath = Join-Path $temp ".claude/.sdd-global-config.json"
        Afirmar (Test-Path $manifestPath) "Debe existir manifiesto"
        $manifest = Get-Content $manifestPath -Raw | ConvertFrom-Json
        Afirmar ($manifest.archivos.PSObject.Properties.Name -contains ".gemini/antigravity-cli/scratch/statusline.bat") "Manifiesto debe incluir statusline.bat"
        Afirmar ($manifest.archivos.PSObject.Properties.Name -contains ".gemini/antigravity-cli/scratch/statusline_new.ps1") "Manifiesto debe incluir statusline_new.ps1"
    }
}

# test-plan: statusline-instalable/S05
Probar "statusline-instalable/S05 Barra de Antigravity CLI instalada por maquina / Sin Antigravity" {
    Con-CarpetaTemporal { param($temp)
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $agyDir = Join-Path $temp ".gemini/antigravity-cli"
        Afirmar (-not (Test-Path $agyDir)) "No se debe crear carpeta .gemini/antigravity-cli"
        Afirmar (-not ($res.Output -match "settings:\s*barra Antigravity")) "La tabla no debe tener fila de barra Antigravity"
    }
}

# test-plan: statusline-instalable/S06
Probar "statusline-instalable/S06 Barra de Copilot CLI instalada por maquina / Copilot instalado" {
    Con-CarpetaTemporal { param($temp)
        $copilotDir = Join-Path $temp ".copilot"
        New-Item -ItemType Directory -Path $copilotDir -Force | Out-Null
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $settingsPath = Join-Path $copilotDir "settings.json"
        Afirmar (Test-Path $settingsPath) "Debe existir $settingsPath"
        $json = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.statusLine.type -eq "command") "statusLine.type en copilot"
        Afirmar ($json.statusLine.command -eq "bash `"$repoRootConBarras/.claude/statusline.sh`"") "command igual al de Claude"
        Afirmar (-not (Test-Path (Join-Path $copilotDir "config.json"))) "No debe existir config.json"
    }
}

# test-plan: statusline-instalable/S07
Probar "statusline-instalable/S07 Barra de Copilot CLI instalada por maquina / Sin Copilot" {
    Con-CarpetaTemporal { param($temp)
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $copilotDir = Join-Path $temp ".copilot"
        Afirmar (-not (Test-Path $copilotDir)) "No se debe crear .copilot"
        Afirmar (-not ($res.Output -match "settings:\s*barra Copilot")) "La tabla no debe tener fila de barra Copilot"
    }
}

# test-plan: statusline-instalable/S08
Probar "statusline-instalable/S08 Convivencia con la configuracion propia / Barra propia" {
    Con-CarpetaTemporal { param($temp)
        $claudeDir = Join-Path $temp ".claude"
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        $customSettings = @{
            statusLine = @{
                type = "command"
                command = "mi-barra.sh"
            }
        } | ConvertTo-Json
        Set-Content -Path (Join-Path $claudeDir "settings.json") -Value $customSettings -Encoding UTF8
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $json = Get-Content (Join-Path $claudeDir "settings.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.statusLine.command -eq "mi-barra.sh") "statusLine.command sigue siendo mi-barra.sh"
        Afirmar ($res.Output -match "Aviso:.*\.claude/settings\.json.*barra propia") "Salida muestra aviso nombrando .claude/settings.json"
    }
}

# test-plan: statusline-instalable/S09
Probar "statusline-instalable/S09 Convivencia con la configuracion propia / Otras claves intactas" {
    Con-CarpetaTemporal { param($temp)
        $claudeDir = Join-Path $temp ".claude"
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        $settings = [ordered]@{
            model = "claude-3-5-sonnet"
            permissions = @{
                allow = @("PowerShell(agy -p *)")
            }
            theme = "dark"
        } | ConvertTo-Json -Depth 5
        Set-Content -Path (Join-Path $claudeDir "settings.json") -Value $settings -Encoding UTF8
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $json = Get-Content (Join-Path $claudeDir "settings.json") -Raw -Encoding UTF8 | ConvertFrom-Json
        Afirmar ($json.model -eq "claude-3-5-sonnet") "model se mantiene"
        Afirmar ($json.permissions.allow[0] -eq "PowerShell(agy -p *)") "permissions.allow se mantiene"
        Afirmar ($json.theme -eq "dark") "theme se mantiene"
        Afirmar ($json.statusLine.command -eq "bash `"$repoRootConBarras/.claude/statusline.sh`"") "statusLine es la del repo"
    }
}

# test-plan: statusline-instalable/S10
Probar "statusline-instalable/S10 Convivencia con la configuracion propia / Dato invalido: settings.json que no es JSON" {
    Con-CarpetaTemporal { param($temp)
        $claudeDir = Join-Path $temp ".claude"
        New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null
        $rawContent = '{ "model": '
        Set-Content -Path (Join-Path $claudeDir "settings.json") -Value $rawContent -NoNewline -Encoding UTF8
        $bytesBefore = [System.IO.File]::ReadAllBytes((Join-Path $claudeDir "settings.json"))
        $res = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "ExitCode debe ser 0"
        $bytesAfter = [System.IO.File]::ReadAllBytes((Join-Path $claudeDir "settings.json"))
        Afirmar (($bytesBefore -join ",") -eq ($bytesAfter -join ",")) "El archivo queda byte a byte igual"
        Afirmar ($res.Output -match "Aviso:.*\.claude/settings\.json.*json inv[aá]lido") "Aviso de json inválido con .claude/settings.json"
        Afirmar (Test-Path (Join-Path $temp ".claude/CLAUDE.md")) "El resto de los archivos se instala"
    }
}

# test-plan: statusline-instalable/S11
Probar "statusline-instalable/S11 Comprobacion de la barra / Barra al dia" {
    Con-CarpetaTemporal { param($temp)
        $res1 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res1.ExitCode -eq 0) "Instalacion exitosa"
        $res2 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault -Comprobar"
        Afirmar ($res2.ExitCode -eq 0) "Comprobar debe salir con 0"
        Afirmar ($res2.Output -match "settings:\s*barra Claude.*igual") "settings: barra Claude está igual"
    }
}

# test-plan: statusline-instalable/S12
Probar "statusline-instalable/S12 Comprobacion de la barra / Barra que falta" {
    Con-CarpetaTemporal { param($temp)
        $res1 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res1.ExitCode -eq 0) "Instalacion exitosa"
        $settingsPath = Join-Path $temp ".claude/settings.json"
        $json = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $hash = [ordered]@{}
        foreach ($prop in $json.PSObject.Properties) {
            if ($prop.Name -ne "statusLine") {
                $hash[$prop.Name] = $prop.Value
            }
        }
        $hash | ConvertTo-Json | Set-Content -Path $settingsPath -Encoding UTF8
        $contentBefore = Get-Content $settingsPath -Raw -Encoding UTF8
        $res2 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault -Comprobar"
        Afirmar ($res2.ExitCode -ne 0) "Comprobar debe fallar"
        Afirmar ($res2.Output -match "settings:\s*barra Claude.*falta") "Debe marcar settings: barra Claude como falta"
        $contentAfter = Get-Content $settingsPath -Raw -Encoding UTF8
        Afirmar ($contentBefore -eq $contentAfter) "settings.json no debe cambiar con -Comprobar"
    }
}

# test-plan: statusline-instalable/S13
Probar "statusline-instalable/S13 Comprobacion de la barra / Barra propia en la comprobacion" {
    Con-CarpetaTemporal { param($temp)
        $res1 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault"
        Afirmar ($res1.ExitCode -eq 0) "Instalacion exitosa"
        $settingsPath = Join-Path $temp ".claude/settings.json"
        $json = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
        $json.statusLine.command = "mi-barra.sh"
        $json | ConvertTo-Json | Set-Content -Path $settingsPath -Encoding UTF8
        $res2 = Ejecutar-Instalar "-Destino `"$temp`" -SinVault -Comprobar"
        Afirmar ($res2.ExitCode -eq 0) "Comprobar con barra propia debe terminar con 0"
        Afirmar ($res2.Output -match "Aviso:.*\.claude/settings\.json.*barra propia") "Aviso con barra propia"
    }
}

# test-plan: statusline-instalable/S14
Probar "statusline-instalable/S14 Formato de la barra de Claude y Copilot / Entrada de Claude Code" {
    $script = "$repoRoot/.claude/statusline.sh"
    $entrada = '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25}}}'
    $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    $lineas = ($res.SinAnsi -split "`r?`n") | Where-Object { $_ -ne "" }
    Afirmar ($lineas[0].StartsWith("mi-proyecto")) "Línea 1 empieza con mi-proyecto"
    Afirmar ($lineas[0] -match "######------ 50%") "Línea 1 contiene ######------ 50%"
    Afirmar ($lineas[0] -match "###--------- 25%") "Línea 1 contiene ###--------- 25%"
    Afirmar ($lineas[1] -eq "Modelo Ejemplo") "Línea 2 es Modelo Ejemplo"
}

# test-plan: statusline-instalable/S15
Probar "statusline-instalable/S15 Formato de la barra de Claude y Copilot / Entrada de Copilot CLI" {
    $script = "$repoRoot/.claude/statusline.sh"
    $entrada = '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":10,"current_context_used_percentage":50}}'
    $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    $lineas = ($res.SinAnsi -split "`r?`n") | Where-Object { $_ -ne "" }
    Afirmar ($lineas[0] -match "50%") "Barra de contexto muestra 50%"
    Afirmar (-not ($lineas[0] -match "25%|10%")) "No debe tener barra de cuota"
}

# test-plan: statusline-instalable/S16
Probar "statusline-instalable/S16 Formato de la barra de Claude y Copilot / Solo caracteres de ancho simple" {
    $script = "$repoRoot/.claude/statusline.sh"
    $entradas = @(
        '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25,"resets_at":1900000000}}}',
        '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":10,"current_context_used_percentage":50}}'
    )
    foreach ($ent in $entradas) {
        $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson $ent
        Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
        # Todo carácter visible debe ser ASCII imprimible (32 a 126, o retorno de carro/salto de línea)
        foreach ($char in $res.SinAnsi.ToCharArray()) {
            $code = [int][char]$char
            $esAscii = ($code -ge 32 -and $code -le 126) -or $code -eq 10 -or $code -eq 13
            Afirmar $esAscii "Carácter '$char' (código $code) no es ASCII imprimible"
        }
    }
}

# test-plan: statusline-instalable/S17
Probar "statusline-instalable/S17 Formato de la barra de Claude y Copilot / Dato invalido: entrada que no es JSON" {
    $script = "$repoRoot/.claude/statusline.sh"
    $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson "no es json"
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    Afirmar ($res.SinAnsi -match "--") "Debe mostrar -- como contexto"
    Afirmar ([string]::IsNullOrWhiteSpace($res.Stderr)) "No debe producir errores en stderr"
}

# test-plan: statusline-instalable/S18
Probar "statusline-instalable/S18 Una sola configuracion de la barra en el repo / Sin barra de proyecto" {
    $settingsFiles = git ls-files ".claude/settings*.json"
    if ($settingsFiles) {
        foreach ($f in $settingsFiles) {
            $content = Get-Content $f -Raw -Encoding UTF8
            Afirmar (-not ($content -match '"statusLine"')) "$f no debe contener statusLine"
        }
    }
}

# test-plan: statusline-instalable/S19
Probar "statusline-instalable/S19 Barra de estado documentada por agente / Matriz actualizada" {
    $readme = Get-Content "$repoRoot/templates/README.md" -Raw -Encoding UTF8
    Afirmar ($readme -match '(?m)\|.*Copilot.*\|.*~/\.copilot/settings\.json.*instalar\.ps1') "Fila de Copilot debe nombrar ~/.copilot/settings.json instalado por instalar.ps1"
    Afirmar ($readme -match '(?m)\|.*Cursor.*\|.*no verificado') "Fila de Cursor debe decir no verificado"
}

# test-plan: statusline-instalable/S20
Probar "statusline-instalable/S20 Barra de estado documentada por agente / Que hacer si no aparece" {
    $modoUso = Get-Content "$repoRoot/docs/modo-de-uso.md" -Raw -Encoding UTF8
    Afirmar ($modoUso -match "instalar\.ps1 -Comprobar") "docs/modo-de-uso.md debe mencionar instalar.ps1 -Comprobar"
    Afirmar ($modoUso -match "reiniciar el CLI") "docs/modo-de-uso.md debe mencionar reiniciar el CLI"
    Afirmar ($modoUso -match "/experimental on") "docs/modo-de-uso.md debe mencionar /experimental on para Copilot"
}

# test-plan: statusline-instalable/S21
Probar "statusline-instalable/S21 Barra de estado especificada por comportamiento / Linea con datos completos" {
    $script = "$repoRoot/templates/antigravity/statusline_new.ps1"
    Afirmar (Test-Path $script) "Debe existir $script"
    $entrada = '{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":42.4},"quota":{"gemini-5h":{"remaining_fraction":0.75,"reset_in_seconds":5400}},"model":{"display_name":"Modelo Ejemplo"}}'
    $res = Ejecutar-AntigravityStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    $sinAnsi = $res.SinAnsi.TrimEnd()
    Afirmar ($sinAnsi.StartsWith("mi-proyecto   42%   25% 1h30m")) "Debe empezar con 'mi-proyecto   42%   25% 1h30m'"
    Afirmar ($sinAnsi.EndsWith("Modelo Ejemplo")) "Debe terminar con 'Modelo Ejemplo'"
}

# test-plan: statusline-instalable/S22
Probar "statusline-instalable/S22 Barra de estado especificada por comportamiento / Seleccion de la cuota" {
    $script = "$repoRoot/templates/antigravity/statusline_new.ps1"
    Afirmar (Test-Path $script) "Debe existir $script"
    $entrada = '{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":0},"quota":{"3p-5h":{"remaining_fraction":1.0,"reset_in_seconds":0},"gemini-5h":{"remaining_fraction":0.75,"reset_in_seconds":5400}},"model":{"display_name":"Modelo Ejemplo"}}'
    $res = Ejecutar-AntigravityStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    Afirmar ($res.SinAnsi -match "25%") "Cuota mostrada debe ser 25%"
}

# test-plan: statusline-instalable/S23
Probar "statusline-instalable/S23 Barra de estado especificada por comportamiento / Entrada invalida" {
    $script = "$repoRoot/templates/antigravity/statusline_new.ps1"
    Afirmar (Test-Path $script) "Debe existir $script"
    $res = Ejecutar-AntigravityStatusline -ScriptPath $script -InputJson "no es json valido"
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    Afirmar ($res.SinAnsi -match "0%\s+0%") "Debe mostrar 0% de contexto y 0% de cuota"
    Afirmar ([string]::IsNullOrWhiteSpace($res.Stderr)) "No debe producir error en stderr"
}

# test-plan: statusline-instalable/S24
Probar "statusline-instalable/S24 Barra de estado especificada por comportamiento / Barra prendida en la plantilla" {
    $settingsPath = "$repoRoot/templates/antigravity/settings.json"
    Afirmar (Test-Path $settingsPath) "Debe existir $settingsPath"
    $json = Get-Content $settingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    Afirmar ($json.statusLine.enabled -eq $true) "statusLine.enabled debe ser true"
}

# test-plan: statusline-instalable/S25
Probar "statusline-instalable/S25 Barra de estado especificada por comportamiento / Scripts versionados sin rutas de la maquina" {
    $archivos = git ls-files templates/antigravity/statusline.bat templates/antigravity/statusline_new.ps1
    Afirmar (($archivos -split "`r?`n" | Where-Object { $_ -ne "" }).Count -eq 2) "git ls-files debe devolver ambos archivos"
    foreach ($f in $archivos -split "`r?`n" | Where-Object { $_ -ne "" }) {
        $content = Get-Content "$repoRoot/$f" -Raw -Encoding UTF8
        Afirmar (-not ($content -match "C:\\Users|C:/Users")) "$f no debe contener C:\Users ni C:/Users"
        if ($env:USERNAME) {
            Afirmar (-not ($content -match [regex]::Escape($env:USERNAME))) "$f no debe contener nombre de usuario"
        }
    }
}

# test-plan: statusline-instalable/S26
Probar "statusline-instalable/S26 La instalacion por maquina esta documentada / Pasos de instalacion visibles" {
    $readme = Get-Content "$repoRoot/README.md" -Raw -Encoding UTF8
    $modoUso = Get-Content "$repoRoot/docs/modo-de-uso.md" -Raw -Encoding UTF8
    Afirmar ($readme -match "templates[/|\\]antigravity[/|\\]settings\.json") "README.md describe dónde copiar settings.json"
    Afirmar ($readme -match "trustedWorkspaces") "README.md indica reemplazar placeholder de trustedWorkspaces"
    Afirmar ($readme -match "instalar\.ps1.*barra de estado|barra de estado.*instalar\.ps1") "README.md dice que la barra la instala instalar.ps1"
    Afirmar ($modoUso -match "templates[/|\\]antigravity[/|\\]settings\.json") "docs/modo-de-uso.md describe dónde copiar settings.json"
    Afirmar ($modoUso -match "trustedWorkspaces") "docs/modo-de-uso.md indica reemplazar placeholder de trustedWorkspaces"
    Afirmar ($modoUso -match "instalar\.ps1.*barra de estado|barra de estado.*instalar\.ps1") "docs/modo-de-uso.md dice que la barra la instala instalar.ps1"
}

# test-plan: statusline-instalable/S27
Probar "statusline-instalable/S27 La instalacion por maquina esta documentada / Prompt para generar la barra de estado" {
    $agyReadme = Get-Content "$repoRoot/templates/antigravity/README.md" -Raw -Encoding UTF8
    Afirmar (-not ($agyReadme -match "prompt.*statusline|Genera la barra de estado")) "No debe incluir prompt para generar los scripts"
    Afirmar ($agyReadme -match "instalar\.ps1") "templates/antigravity/README.md debe indicar correr instalar.ps1"
    Afirmar ($agyReadme -match "reiniciar el CLI") "templates/antigravity/README.md debe indicar reiniciar el CLI"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
