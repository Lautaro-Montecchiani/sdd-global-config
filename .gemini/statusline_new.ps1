# 1. Leer el JSON enviado por agy a través de la entrada estándar (stdin)
try {
    $inputJson = [Console]::In.ReadToEnd()
    $data = ConvertFrom-Json $inputJson
} catch {
    $data = $null
}

# 2. Obtener el nombre del proyecto
$projectName = "desconocido"
if ($data) {
    if ($data.workspace -and $data.workspace.project_dir) {
        $projectName = Split-Path $data.workspace.project_dir -Leaf
    } elseif ($data.cwd) {
        $projectName = Split-Path $data.cwd -Leaf
    }
} else {
    $projectName = Split-Path (Get-Location) -Leaf
}

# 3. Obtener el porcentaje de uso de contexto
$contextPercentVal = 0
if ($data -and $data.context_window -and $data.context_window.used_percentage -ne $null) {
    $contextPercentVal = [math]::Round($data.context_window.used_percentage)
}

# 4. Obtener el porcentaje de uso de la cuota de 5 horas y el tiempo de reset
$quotaPercentVal = 0
$resetTimeStr = ""
if ($data -and $data.quota) {
    $quota5h = $null
    if ($data.quota.'3p-5h' -and $data.quota.'3p-5h'.remaining_fraction -lt 1) {
        $quota5h = $data.quota.'3p-5h'
    } elseif ($data.quota.'gemini-5h') {
        $quota5h = $data.quota.'gemini-5h'
    } elseif ($data.quota.'3p-5h') {
        $quota5h = $data.quota.'3p-5h'
    }

    if ($quota5h) {
        $quotaPercentVal = [math]::Round((1 - $quota5h.remaining_fraction) * 100)
        if ($quota5h.reset_in_seconds -gt 0) {
            $seconds = $quota5h.reset_in_seconds
            $hours = [math]::Floor($seconds / 3600)
            $minutes = [math]::Floor(($seconds % 3600) / 60)
            $resetTimeStr = "{0}h{1:00}m" -f $hours, $minutes
        }
    }
}
$resetStr = if ($resetTimeStr) { " $resetTimeStr" } else { "" }

# 5. Obtener el nombre de la rama de Git
$branch = ""
if ($data -and $data.cwd -and (Test-Path $data.cwd)) {
    try {
        $prevDir = Get-Location
        Set-Location $data.cwd
        $branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
        Set-Location $prevDir
    } catch {}
}
if (!$branch) {
    try {
        $branch = (git rev-parse --abbrev-ref HEAD 2>$null).Trim()
    } catch {}
}
$branchStr = if ($branch) { "($branch)" } else { "" }

# 6. Obtener el modelo seleccionado
$modelName = ""
if ($data -and $data.model -and $data.model.display_name) {
    $modelName = $data.model.display_name
} elseif ($data -and $data.model -and $data.model.id) {
    $modelName = $data.model.id
}

# 7. Formatear la salida con colores ANSI
$esc = [char]27
$green = "${esc}[32m"
$reset = "${esc}[0m"

# Primera barra/porcentaje (verde)
$contextStr = "${green}${contextPercentVal}%${reset}"

# Segunda barra/porcentaje (cuota de 5 horas)
$quotaStr = "${quotaPercentVal}%"

# Imprimir con el formato de espaciado solicitado:
# <proyecto>   <contexto>%   <cuota>% <tiempo_reset>  (<rama>)  <modelo>
$output = "${projectName}   ${contextStr}   ${quotaStr}${resetStr}  ${branchStr}"
if ($modelName) {
    $output += "  ${modelName}"
}

Write-Output $output
