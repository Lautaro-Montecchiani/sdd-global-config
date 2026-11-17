# tests/barra-de-estado-con-bloques.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

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

function Obtener-PowershellExe {
    $cmd = Get-Command powershell.exe -ErrorAction SilentlyContinue
    if ($cmd -and $cmd.Source) { return $cmd.Source }
    return $null
}

function Ejecutar-WinPowerShellStatusline {
    param(
        [string]$ScriptPath,
        [string]$InputJson,
        [string]$WorkingDir = ""
    )
    $psExe = Obtener-PowershellExe
    if (-not $psExe) { return $null }
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = $psExe
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
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

# test-plan: barra-de-estado-con-bloques/S01
Probar "barra-de-estado-con-bloques/S01 Barra con bloques y reinicio con flecha / Barra de Claude Code y Copilot" {
    $script = "$repoRoot/.claude/statusline.sh"
    $resetsAt = [int]([DateTimeOffset]::UtcNow.ToUnixTimeSeconds() + 15370)
    $entrada = @"
{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50},"rate_limits":{"five_hour":{"used_percentage":25,"resets_at":$resetsAt}}}
"@
    $res = Ejecutar-BashStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    $lineas = ($res.SinAnsi -split "`r?`n") | Where-Object { $_ -ne "" }
    Afirmar ($lineas[0] -match "████████████ 50%") "Línea 1 debe tener barra de contexto con bloques: ████████████ 50%"
    Afirmar ($lineas[0] -match "████████████ 25%") "Línea 1 debe tener barra de límite con bloques: ████████████ 25%"
    Afirmar ($lineas[0] -match "↺ 4h16m") "Línea 1 debe tener ↺ 4h16m"
    Afirmar (-not ($lineas[0] -match "[#\-]{3,}")) "Línea 1 no debe tener # ni - como relleno de barra"
}

# test-plan: barra-de-estado-con-bloques/S02
Probar "barra-de-estado-con-bloques/S02 Barra con bloques y reinicio con flecha / Barra de Antigravity" {
    $psExe = Obtener-PowershellExe
    if (-not $psExe) {
        Write-Host "SKIP: powershell.exe no existe en este entorno"
        return
    }
    $script = "$repoRoot/templates/antigravity/statusline_new.ps1"
    $entrada = '{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":50},"quota":{"gemini-5h":{"remaining_fraction":0.75,"reset_in_seconds":15360}},"model":{"display_name":"Modelo Ejemplo"}}'
    $res = Ejecutar-WinPowerShellStatusline -ScriptPath $script -InputJson $entrada
    Afirmar ($res.ExitCode -eq 0) "ExitCode 0"
    $sinAnsi = $res.SinAnsi.TrimEnd()
    Afirmar ($sinAnsi -match "████████████ 50%") "Debe tener barra de contexto con bloques: ████████████ 50%"
    Afirmar ($sinAnsi -match "████████████ 25%") "Debe tener barra de cuota con bloques: ████████████ 25%"
    Afirmar ($sinAnsi -match "↺ 4h16m") "Debe tener ↺ 4h16m"
}

# test-plan: barra-de-estado-con-bloques/S03
Probar "barra-de-estado-con-bloques/S03 Barra con bloques y reinicio con flecha / Script de Antigravity legible por Windows PowerShell" {
    $script = "$repoRoot/templates/antigravity/statusline_new.ps1"
    Afirmar (Test-Path $script) "Debe existir $script"
    $bytes = [System.IO.File]::ReadAllBytes($script)
    Afirmar ($bytes.Length -gt 0) "El archivo no debe estar vacío"
    $noAscii = $bytes | Where-Object { $_ -ge 128 }
    Afirmar ($null -eq $noAscii -or $noAscii.Count -eq 0) "Todos los bytes deben ser menores que 128 (ASCII puro, sin BOM)"
    $contenido = Get-Content -Path $script -Raw
    Afirmar ($contenido -match '\[char\]0x2588') "Debe contener [char]0x2588"
    Afirmar (-not ($contenido -match '0x2591')) "No debe contener 0x2591"
    Afirmar ($contenido -match '\[char\]0x21BA') "Debe contener [char]0x21BA"
}

# test-plan: barra-de-estado-con-bloques/S04
Probar "barra-de-estado-con-bloques/S04 Barra con bloques y reinicio con flecha / Dato inválido: sin límite de uso o porcentaje fuera de rango" {
    $scriptBash = "$repoRoot/.claude/statusline.sh"
    $entradaSinLimite = '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":50}}'
    $resBashSin = Ejecutar-BashStatusline -ScriptPath $scriptBash -InputJson $entradaSinLimite
    Afirmar ($resBashSin.ExitCode -eq 0) "ExitCode 0 para statusline.sh sin límite"
    $lineasBashSin = ($resBashSin.SinAnsi -split "`r?`n") | Where-Object { $_ -ne "" }
    Afirmar (-not ($lineasBashSin[0] -match "↺")) "statusline.sh sin límite de uso no debe mostrar ↺"
    $matchesBashSin = [regex]::Matches($lineasBashSin[0], "█{12}")
    Afirmar ($matchesBashSin.Count -eq 1) "statusline.sh sin límite debe mostrar solo una barra de 12 unidades"

    $entrada150 = '{"workspace":{"current_dir":"C:/x/mi-proyecto"},"model":{"display_name":"Modelo Ejemplo"},"context_window":{"used_percentage":150}}'
    $resBash150 = Ejecutar-BashStatusline -ScriptPath $scriptBash -InputJson $entrada150
    Afirmar ($resBash150.ExitCode -eq 0) "ExitCode 0 para statusline.sh con contexto 150"
    Afirmar ($resBash150.SinAnsi -match "████████████") "statusline.sh con contexto 150 debe dibujar barra de 12 bloques llenos"

    $psExe = Obtener-PowershellExe
    if (-not $psExe) {
        Write-Host "SKIP: powershell.exe no existe en este entorno para Antigravity en S04"
        return
    }
    $scriptAgy = "$repoRoot/templates/antigravity/statusline_new.ps1"
    $entradaAgySin = '{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":50}}'
    $resAgySin = Ejecutar-WinPowerShellStatusline -ScriptPath $scriptAgy -InputJson $entradaAgySin
    Afirmar ($resAgySin.ExitCode -eq 0) "ExitCode 0 para statusline_new.ps1 sin cuota"
    Afirmar ($resAgySin.SinAnsi -match "████████████ 0%") "statusline_new.ps1 sin cuota debe mostrar barra vacía: ████████████ 0%"
    Afirmar (-not ($resAgySin.SinAnsi -match "↺")) "statusline_new.ps1 sin cuota no debe mostrar ↺"

    $entradaAgy150 = '{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":150}}'
    $resAgy150 = Ejecutar-WinPowerShellStatusline -ScriptPath $scriptAgy -InputJson $entradaAgy150
    Afirmar ($resAgy150.ExitCode -eq 0) "ExitCode 0 para statusline_new.ps1 con contexto 150"
    Afirmar ($resAgy150.SinAnsi -match "████████████") "statusline_new.ps1 con contexto 150 debe dibujar barra de 12 bloques llenos"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
