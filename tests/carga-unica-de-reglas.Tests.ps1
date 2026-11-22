# tests/carga-unica-de-reglas.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$settingsPath = "$repoRoot/.claude/settings.json"
$readmePath = "$repoRoot/README.md"

function Test-CoincidePicomatchPrefijoDobleAsterisco {
    param(
        [string]$Ruta,
        [string]$Patron
    )
    Afirmar ($Patron.StartsWith("**/")) "El patrón debe comenzar con '**/'"
    $resto = $Patron.Substring(3)
    Afirmar ($resto -notmatch "[\*\?\[\]]") "El resto del patrón no debe contener comodines"

    $rutaNorm = $Ruta -replace "\\", "/"
    return ($rutaNorm -eq $resto -or $rutaNorm.EndsWith("/$resto"))
}

# test-plan: carga-unica-de-reglas/S01
Probar "S01 patrón de exclusión versionado en .claude/settings.json" {
    Afirmar (Test-Path $settingsPath) "El archivo .claude/settings.json debe existir"

    $bytes = [System.IO.File]::ReadAllBytes($settingsPath)
    if ($bytes.Length -ge 3) {
        $hex = ($bytes[0..2] | ForEach-Object { $_.ToString("X2") }) -join " "
        Afirmar ($hex -ne "EF BB BF") ".claude/settings.json no debe tener BOM UTF-8"
    }

    $raw = Get-Content -Path $settingsPath -Raw -Encoding UTF8
    $json = $raw | ConvertFrom-Json
    $props = @($json.psobject.properties.Name)
    Afirmar ($props.Count -eq 1) "settings.json debe tener exactamente una propiedad"
    Afirmar ($props[0] -eq "claudeMdExcludes") "La única propiedad debe ser 'claudeMdExcludes'"

    $excludes = @($json.claudeMdExcludes)
    Afirmar ($excludes.Count -eq 1) "claudeMdExcludes debe contener exactamente un elemento"
    Afirmar ($excludes[0] -eq "**/sdd-global-config/.claude/CLAUDE.md") "El patrón debe ser '**/sdd-global-config/.claude/CLAUDE.md'"
}

# test-plan: carga-unica-de-reglas/S02
Probar "S02 excluye solo la copia del repo y no la global" {
    Afirmar (Test-Path $settingsPath) "El archivo .claude/settings.json debe existir"
    $raw = Get-Content -Path $settingsPath -Raw -Encoding UTF8
    $json = $raw | ConvertFrom-Json
    $patron = $json.claudeMdExcludes[0]

    $rutaRepoWin = "C:/Users/ana/sdd-global-config/.claude/CLAUDE.md"
    $rutaRepoLinux = "/home/ana/sdd-global-config/.claude/CLAUDE.md"
    $rutaGlobalWin = "C:/Users/ana/.claude/CLAUDE.md"
    $rutaGlobalLinux = "/home/ana/.claude/CLAUDE.md"

    Afirmar (Test-CoincidePicomatchPrefijoDobleAsterisco -Ruta $rutaRepoWin -Patron $patron) "Debe coincidir con la copia del repo en Windows"
    Afirmar (Test-CoincidePicomatchPrefijoDobleAsterisco -Ruta $rutaRepoLinux -Patron $patron) "Debe coincidir con la copia del repo en Linux"
    Afirmar (-not (Test-CoincidePicomatchPrefijoDobleAsterisco -Ruta $rutaGlobalWin -Patron $patron)) "No debe coincidir con la copia global en Windows"
    Afirmar (-not (Test-CoincidePicomatchPrefijoDobleAsterisco -Ruta $rutaGlobalLinux -Patron $patron)) "No debe coincidir con la copia global en Linux"
}

# test-plan: carga-unica-de-reglas/S03
Probar "S03 sin rutas personales en .claude/settings.json" {
    Afirmar (Test-Path $settingsPath) "El archivo .claude/settings.json debe existir"
    $raw = Get-Content -Path $settingsPath -Raw -Encoding UTF8

    Afirmar ($raw -notmatch "(?i)C:") "settings.json no debe contener letras de unidad (C:)"
    Afirmar ($raw -notmatch "/Users/") "settings.json no debe contener /Users/"
    Afirmar ($raw -notmatch "/home/") "settings.json no debe contener /home/"
    if (-not [string]::IsNullOrWhiteSpace($env:USERNAME)) {
        Afirmar (-not $raw.Contains($env:USERNAME)) "settings.json no debe contener el nombre de usuario ($env:USERNAME)"
    }
}

# test-plan: carga-unica-de-reglas/S04
Probar "S04 documentación de la carga única en README.md" {
    $readme = Get-Content -Path $readmePath -Raw -Encoding UTF8
    Afirmar ($readme.Contains("**Reglas en este repo.**")) "README.md debe contener el encabezado '**Reglas en este repo.**'"

    $seccion = [regex]::Match($readme, "(?s)\*\*Reglas en este repo\.\*\*.*?(?=\r?\n\r?\n|\Z)").Value
    Afirmar ($seccion -match "claudeMdExcludes") "La sección debe mencionar 'claudeMdExcludes'"
    Afirmar ($seccion -match "sdd-global-config") "La sección debe mencionar 'sdd-global-config'"
    Afirmar ($seccion -match "instalar\.ps1") "La sección debe mencionar 'instalar.ps1'"
}
