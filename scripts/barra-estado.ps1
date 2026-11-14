# scripts/barra-estado.ps1
# Funciones para la gestión e instalación de la barra de estado de cada CLI

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Normalizar-RutaBarra {
    param([string]$Ruta)
    if ([string]::IsNullOrWhiteSpace($Ruta)) { return "" }
    return ($Ruta -replace "\\", "/").Trim().ToLowerInvariant()
}

function Obtener-BarrasEsperadas {
    param(
        [string]$RepoRoot,
        [string]$Destino
    )

    $repoBarras = ($RepoRoot -replace "\\", "/").TrimEnd("/")
    $destBarras = ($Destino -replace "\\", "/").TrimEnd("/")

    $barras = [System.Collections.Generic.List[hashtable]]::new()

    # 1. Claude Code (siempre)
    $cmdClaudeEsperado = "bash `"$repoBarras/.claude/statusline.sh`""
    $barras.Add(@{
        CLI = "claude"
        Nombre = "barra Claude"
        FilaTabla = "settings: barra Claude"
        RutaRelativa = ".claude/settings.json"
        Ruta = Join-Path $Destino ".claude/settings.json"
        Esperada = [ordered]@{
            type = "command"
            command = $cmdClaudeEsperado
        }
    })

    # 2. Antigravity CLI (solo si existe <Destino>/.gemini/antigravity-cli)
    $agyDir = Join-Path $Destino ".gemini/antigravity-cli"
    if (Test-Path $agyDir) {
        $cmdAgyEsperado = "$destBarras/.gemini/antigravity-cli/scratch/statusline.bat"
        $barras.Add(@{
            CLI = "antigravity"
            Nombre = "barra Antigravity"
            FilaTabla = "settings: barra Antigravity"
            RutaRelativa = ".gemini/antigravity-cli/settings.json"
            Ruta = Join-Path $agyDir "settings.json"
            Esperada = [ordered]@{
                type = "command"
                command = $cmdAgyEsperado
                enabled = $true
            }
        })
    }

    # 3. Copilot CLI (solo si existe <Destino>/.copilot)
    $copilotDir = Join-Path $Destino ".copilot"
    if (Test-Path $copilotDir) {
        $cmdCopilotEsperado = "bash `"$repoBarras/.claude/statusline.sh`""
        $barras.Add(@{
            CLI = "copilot"
            Nombre = "barra Copilot"
            FilaTabla = "settings: barra Copilot"
            RutaRelativa = ".copilot/settings.json"
            Ruta = Join-Path $copilotDir "settings.json"
            Esperada = [ordered]@{
                type = "command"
                command = $cmdCopilotEsperado
            }
        })
    }

    return $barras
}

function Clasificar-Barra {
    param(
        [hashtable]$Barra
    )

    $ruta = $Barra.Ruta
    if (-not (Test-Path $ruta)) {
        return "falta"
    }

    $raw = Get-Content -LiteralPath $ruta -Raw -Encoding UTF8
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return "falta"
    }

    $data = $null
    try {
        $data = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
    } catch {
        return "json inválido"
    }

    if ($null -eq $data -or -not $data.Contains("statusLine") -or $null -eq $data["statusLine"]) {
        return "falta"
    }

    $sl = $data["statusLine"]
    if (-not ($sl -is [System.Collections.IDictionary])) {
        return "propia"
    }

    $cmdActual = if ($sl.Contains("command") -and $null -ne $sl["command"]) { [string]$sl["command"] } else { "" }
    $cmdNorm = Normalizar-RutaBarra $cmdActual
    $cmdEsperadoNorm = Normalizar-RutaBarra $Barra.Esperada.command

    $typeActual = if ($sl.Contains("type") -and $null -ne $sl["type"]) { [string]$sl["type"] } else { "" }
    $typeNorm = $typeActual.Trim().ToLowerInvariant()

    $cli = $Barra.CLI

    if ($cli -eq "claude" -or $cli -eq "copilot") {
        $cmdFormaVieja = Normalizar-RutaBarra 'bash "$SDD_CONFIG_REPO/.claude/statusline.sh"'
        $esDelRepo = ($cmdNorm -eq $cmdEsperadoNorm) -or ($cmdNorm -eq $cmdFormaVieja)
        if (-not $esDelRepo) {
            return "propia"
        }
        if ($cmdNorm -eq $cmdEsperadoNorm -and $typeNorm -eq "command") {
            return "igual"
        }
        return "atrasado"
    }

    if ($cli -eq "antigravity") {
        $sufijoEsperado = "/.gemini/antigravity-cli/scratch/statusline.bat"
        $esDelRepo = $cmdNorm.EndsWith($sufijoEsperado)
        if (-not $esDelRepo) {
            return "propia"
        }
        $enabled = if ($sl.Contains("enabled")) { [bool]$sl["enabled"] } else { $false }
        if ($cmdNorm -eq $cmdEsperadoNorm -and $typeNorm -eq "command" -and $enabled -eq $true) {
            return "igual"
        }
        return "atrasado"
    }

    return "propia"
}

function Escribir-Barra {
    param(
        [hashtable]$Barra
    )

    $ruta = $Barra.Ruta
    $data = [ordered]@{}

    if (Test-Path $ruta) {
        $raw = Get-Content -LiteralPath $ruta -Raw -Encoding UTF8
        if (-not [string]::IsNullOrWhiteSpace($raw)) {
            try {
                $parsed = $raw | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                if ($parsed -is [System.Collections.IDictionary]) {
                    $data = [ordered]@{}
                    foreach ($key in $parsed.Keys) {
                        $data[$key] = $parsed[$key]
                    }
                }
            } catch {
                return $false
            }
        }
    }

    # Conservar subclaves existentes de statusLine si era diccionario
    $slObj = [ordered]@{}
    if ($data.Contains("statusLine") -and ($data["statusLine"] -is [System.Collections.IDictionary])) {
        foreach ($k in $data["statusLine"].Keys) {
            $slObj[$k] = $data["statusLine"][$k]
        }
    }

    # Aplicar valores esperados
    foreach ($k in $Barra.Esperada.Keys) {
        $slObj[$k] = $Barra.Esperada[$k]
    }

    $data["statusLine"] = $slObj

    $jsonTxt = $data | ConvertTo-Json -Depth 32
    Escribir-ArchivoUtf8SinBom -Ruta $ruta -Texto $jsonTxt
    return $true
}
