# tests/ejecutar.ps1
# Ejecuta cada tests/*.Tests.ps1 en un proceso pwsh -NoProfile aislado

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

$ErrorActionPreference = "Stop"
$testsDir = $PSScriptRoot

$testFiles = Get-ChildItem -Path $testsDir -Filter "*.Tests.ps1" | Sort-Object Name

if ($testFiles.Count -eq 0) {
    Write-Host "No se encontraron archivos de test (*.Tests.ps1) en $testsDir"
    exit 0
}

$tempBase = Join-Path ([System.IO.Path]::GetTempPath()) ("sdd-runner-" + [System.Guid]::NewGuid().ToString("N"))
$tempHome = Join-Path $tempBase "home"
$tempVault = Join-Path $tempBase "vault"

New-Item -ItemType Directory -Path $tempHome -Force | Out-Null
New-Item -ItemType Directory -Path $tempVault -Force | Out-Null

$huboFalla = $false

try {
    foreach ($file in $testFiles) {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = "pwsh"
        $psi.Arguments = "-NoProfile -File `"$($file.FullName)`""
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.EnvironmentVariables["HOME"] = $tempHome
        $psi.EnvironmentVariables["USERPROFILE"] = $tempHome
        $psi.EnvironmentVariables["OBSIDIAN_VAULT"] = $tempVault

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if (-not [string]::IsNullOrWhiteSpace($stdout)) {
            Write-Host $stdout.TrimEnd()
        }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) {
            Write-Host $stderr.TrimEnd()
        }

        if ($proc.ExitCode -ne 0 -or $stdout -match "(?m)^FALLA\s") {
            $huboFalla = $true
        }
    }
} finally {
    if (Test-Path $tempBase) {
        Remove-Item -Recurse -Force $tempBase -ErrorAction SilentlyContinue
    }
}

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

$controles = @(
    @{
        Nombre = "scripts/generar-plantillas.ps1 -Comprobar"
        Script = Join-Path $repoRoot "scripts/generar-plantillas.ps1"
        Args   = "-Comprobar"
    },
    @{
        Nombre = "scripts/sincronizar-proyecto.ps1 -Proyecto $repoRoot -Agentes copilot -Comprobar"
        Script = Join-Path $repoRoot "scripts/sincronizar-proyecto.ps1"
        Args   = "-Proyecto `"$repoRoot`" -Agentes copilot -Comprobar"
    }
)

foreach ($ctrl in $controles) {
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "pwsh"
    $psi.Arguments = "-NoProfile -File `"$($ctrl.Script)`" $($ctrl.Args)"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    if (-not [string]::IsNullOrWhiteSpace($stdout)) {
        Write-Host $stdout.TrimEnd()
    }
    if (-not [string]::IsNullOrWhiteSpace($stderr)) {
        Write-Host $stderr.TrimEnd()
    }

    if ($proc.ExitCode -eq 0) {
        Write-Host "OK $($ctrl.Nombre)"
    } else {
        Write-Host "FALLA $($ctrl.Nombre)"
        $huboFalla = $true
    }
}

if ($huboFalla) {
    exit 1
} else {
    exit 0
}
