$ErrorActionPreference = 'SilentlyContinue'
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$esc = [char]27
$green = "$esc[32m"
$reset = "$esc[0m"

$rawInput = ''
try {
    if ([Console]::IsInputRedirected) {
        $rawInput = [Console]::In.ReadToEnd()
    }
} catch {}

$data = $null
if (-not [string]::IsNullOrWhiteSpace($rawInput)) {
    try {
        $data = $rawInput | ConvertFrom-Json -ErrorAction Stop
    } catch {
        $data = $null
    }
}

# <proyecto>
$proyecto = $null
if ($null -ne $data) {
    $projDir = $null
    if ($null -ne $data.workspace -and -not [string]::IsNullOrWhiteSpace([string]$data.workspace.project_dir)) {
        $projDir = [string]$data.workspace.project_dir
    } elseif (-not [string]::IsNullOrWhiteSpace([string]$data.cwd)) {
        $projDir = [string]$data.cwd
    }
    if (-not [string]::IsNullOrWhiteSpace($projDir)) {
        $trimmed = $projDir.TrimEnd('/', '\')
        if (-not [string]::IsNullOrWhiteSpace($trimmed)) {
            $proyecto = Split-Path -Path $trimmed -Leaf
        }
    }
}
if ([string]::IsNullOrWhiteSpace($proyecto)) {
    try {
        $curDir = (Get-Location).Path.TrimEnd('/', '\')
        if (-not [string]::IsNullOrWhiteSpace($curDir)) {
            $proyecto = Split-Path -Path $curDir -Leaf
        }
    } catch {}
}
if ([string]::IsNullOrWhiteSpace($proyecto)) {
    $proyecto = 'desconocido'
}

# <contexto>
$contexto = 0
if ($null -ne $data -and $null -ne $data.context_window -and $null -ne $data.context_window.used_percentage) {
    try {
        $contexto = [int][Math]::Round([double]$data.context_window.used_percentage, [MidpointRounding]::AwayFromZero)
    } catch {
        $contexto = 0
    }
}
$contextoStr = "${green}${contexto}%${reset}"

# <cuota> y <reinicio>
$quotaObj = $null
if ($null -ne $data -and $null -ne $data.quota) {
    $q3p = $data.quota.'3p-5h'
    $qGem = $data.quota.'gemini-5h'
    if ($null -ne $q3p -and $null -ne $q3p.remaining_fraction -and ([double]$q3p.remaining_fraction -lt 1.0)) {
        $quotaObj = $q3p
    } elseif ($null -ne $qGem) {
        $quotaObj = $qGem
    } elseif ($null -ne $q3p) {
        $quotaObj = $q3p
    }
}

$cuota = 0
$reinicio = ''
if ($null -ne $quotaObj) {
    if ($null -ne $quotaObj.remaining_fraction) {
        try {
            $cuota = [int][Math]::Round((1.0 - [double]$quotaObj.remaining_fraction) * 100.0, [MidpointRounding]::AwayFromZero)
        } catch {
            $cuota = 0
        }
    }
    if ($null -ne $quotaObj.reset_in_seconds) {
        try {
            $sec = [double]$quotaObj.reset_in_seconds
            if ($sec -gt 0) {
                $h = [int][Math]::Floor($sec / 3600)
                $m = [int][Math]::Floor(($sec % 3600) / 60)
                $reinicio = ('{0}h{1:D2}m' -f $h, $m)
            }
        } catch {
            $reinicio = ''
        }
    }
}

$cuotaSegment = "${cuota}%"
if (-not [string]::IsNullOrWhiteSpace($reinicio)) {
    $cuotaSegment = "${cuota}% ${reinicio}"
}

# <rama>
$gitDir = $null
if ($null -ne $data -and -not [string]::IsNullOrWhiteSpace([string]$data.cwd) -and (Test-Path -LiteralPath ([string]$data.cwd))) {
    $gitDir = [string]$data.cwd
}
$rama = $null
try {
    if (-not [string]::IsNullOrWhiteSpace($gitDir)) {
        $gitOut = & git -C $gitDir rev-parse --abbrev-ref HEAD 2>$null
    } else {
        $gitOut = & git rev-parse --abbrev-ref HEAD 2>$null
    }
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($gitOut)) {
        $rama = ($gitOut | Select-Object -First 1).Trim()
    }
} catch {}

# <modelo>
$modelo = $null
if ($null -ne $data -and $null -ne $data.model) {
    if (-not [string]::IsNullOrWhiteSpace([string]$data.model.display_name)) {
        $modelo = [string]$data.model.display_name
    } elseif (-not [string]::IsNullOrWhiteSpace([string]$data.model.id)) {
        $modelo = [string]$data.model.id
    }
}

$line = "${proyecto}   ${contextoStr}   ${cuotaSegment}"
if (-not [string]::IsNullOrWhiteSpace($rama)) {
    $line += "  (${rama})"
}
if (-not [string]::IsNullOrWhiteSpace($modelo)) {
    $line += "  ${modelo}"
}

[Console]::WriteLine($line)
