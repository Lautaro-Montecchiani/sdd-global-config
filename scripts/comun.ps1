# scripts/comun.ps1
# Funciones compartidas del workflow SDD Híbrido

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Obtener-RepoRoot {
    return ((Resolve-Path "$PSScriptRoot/..").Path -replace "\\", "/")
}

function Normalizar-Texto {
    param([string]$Texto)
    if ([string]::IsNullOrEmpty($Texto)) {
        return ""
    }
    # Quitar BOM UTF-8 si existe
    if ($Texto[0] -eq [char]0xFEFF) {
        $Texto = $Texto.Substring(1)
    }
    # Normalizar CRLF y CR a LF
    return ($Texto -replace "\r\n", "`n" -replace "\r", "")
}

function Obtener-HashNormalizado {
    param([string]$Texto)
    $norm = Normalizar-Texto $Texto
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($norm)
    $sha256 = [System.Security.Cryptography.SHA256]::Create()
    $hashBytes = $sha256.ComputeHash($bytes)
    return ($hashBytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Escribir-ArchivoUtf8SinBom {
    param(
        [string]$Ruta,
        [string]$Texto
    )
    $dir = Split-Path -Parent $Ruta
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    $norm = Normalizar-Texto $Texto
    $utf8SinBom = [System.Text.UTF8Encoding]::new($false)
    [System.IO.File]::WriteAllText($Ruta, $norm, $utf8SinBom)
}

function Separar-PropioProyecto {
    param([string]$Texto)
    $norm = Normalizar-Texto $Texto
    if ($norm -match "(?m)^## Propio del proyecto\s*$") {
        $m = [regex]::Match($norm, "(?m)^## Propio del proyecto[^\n]*\n?")
        $idx = $m.Index
        $base = $norm.Substring(0, $idx)
        $despues = $norm.Substring($idx + $m.Length)

        $comentario = '<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->'
        if ($despues.StartsWith($comentario)) {
            $despues = $despues.Substring($comentario.Length)
            if ($despues.StartsWith("`n")) {
                $despues = $despues.Substring(1)
            }
        }

        return @{
            TienePropio = $true
            Base = $base
            Propio = $despues
        }
    }

    return @{
        TienePropio = $false
        Base = $norm
        Propio = ""
    }
}

function Combinar-PropioProyecto {
    param(
        [string]$Generado,
        [string]$Propio
    )
    $genNorm = Normalizar-Texto $Generado
    if ([string]::IsNullOrWhiteSpace($Propio)) {
        return $genNorm
    }

    $propioTrimmed = $Propio.TrimStart("`r", "`n")
    if (-not $genNorm.EndsWith("`n")) {
        $genNorm += "`n"
    }
    return $genNorm + "`n" + $propioTrimmed
}

function Test-EsVersionGitHistorica {
    param(
        [string]$RepoPath,
        [string]$RutaRelativa,
        [string]$TextoAComparar
    )
    $targetNorm = (Normalizar-Texto $TextoAComparar).TrimEnd("`r", "`n")
    $rutaGit = $RutaRelativa -replace "\\", "/"
    $commits = git -C $RepoPath log --format=%H -- $rutaGit 2>$null
    if ($commits) {
        foreach ($c in ($commits -split "\r?\n")) {
            $c = $c.Trim()
            if (-not [string]::IsNullOrEmpty($c)) {
                $raw = git -C $RepoPath show "${c}:${rutaGit}" 2>$null
                if ($raw) {
                    $txt = if ($raw -is [array]) { $raw -join "`n" } else { [string]$raw }
                    $txtNorm = (Normalizar-Texto $txt).TrimEnd("`r", "`n")
                    if ($txtNorm -eq $targetNorm) {
                        return $true
                    }
                }
            }
        }
    }
    return $false
}

function Respaldar-Archivos {
    param(
        [string[]]$Rutas,
        [string]$BaseDir = ""
    )
    $fecha = Get-Date -Format "yyyyMMdd-HHmmss"
    $tempDir = [System.IO.Path]::GetTempPath()
    $respaldoDir = Join-Path $tempDir "sdd-respaldo-$fecha"
    New-Item -ItemType Directory -Path $respaldoDir -Force | Out-Null

    foreach ($ruta in $Rutas) {
        if (Test-Path $ruta) {
            $rel = if ($BaseDir) {
                $resolvedRuta = (Resolve-Path $ruta).Path
                $resolvedBase = (Resolve-Path $BaseDir).Path
                if ($resolvedRuta.StartsWith($resolvedBase)) {
                    $resolvedRuta.Substring($resolvedBase.Length).TrimStart("\", "/")
                } else {
                    Split-Path -Leaf $ruta
                }
            } else {
                Split-Path -Leaf $ruta
            }
            $destino = Join-Path $respaldoDir $rel
            $destPadre = Split-Path -Parent $destino
            if ($destPadre -and -not (Test-Path $destPadre)) {
                New-Item -ItemType Directory -Path $destPadre -Force | Out-Null
            }
            Copy-Item -Path $ruta -Destination $destino -Force
        }
    }
    return $respaldoDir
}

function Obtener-CuerpoSinFrontmatter {
    param([string]$Texto)
    $norm = Normalizar-Texto $Texto
    if ($norm -match "(?s)^---\n.*?\n---\n?(.*)$") {
        return $matches[1].TrimStart([char]10, [char]13)
    }
    return $norm.TrimStart([char]10, [char]13)
}

function Extraer-SeccionMarkdown {
    param(
        [string]$Texto,
        [string]$Titulo
    )
    $norm = Normalizar-Texto $Texto
    $lineas = $norm -split "\n"

    $enBloqueCodigo = $false
    $capturando = $false
    $lineasResultado = [System.Collections.Generic.List[string]]::new()
    $tituloBuscado = "## " + $Titulo

    foreach ($l in $lineas) {
        if ($l -match '^\s*```') {
            $enBloqueCodigo = -not $enBloqueCodigo
            if ($capturando) {
                $lineasResultado.Add($l)
            }
            continue
        }

        if (-not $enBloqueCodigo) {
            if ($capturando) {
                if ($l -match "^##\s+") {
                    break
                }
            } else {
                if ($l.TrimEnd() -eq $tituloBuscado) {
                    $capturando = $true
                    $lineasResultado.Add($l)
                    continue
                }
            }
        }

        if ($capturando) {
            $lineasResultado.Add($l)
        }
    }

    if (-not $capturando) {
        return $null
    }

    $resultado = $lineasResultado -join [string][char]10
    return $resultado.TrimEnd([char]10, [char]13)
}

function Obtener-HuellaInstalacion {
    param([string]$RepoRoot)

    $repo = ((Resolve-Path $RepoRoot).Path -replace "\\", "/").TrimEnd("/")
    $entradas = [System.Collections.Generic.List[PSCustomObject]]::new()

    $dirSkills = "$repo/skills"
    if (Test-Path $dirSkills) {
        $archivosSkills = Get-ChildItem -Path $dirSkills -Recurse -File
        foreach ($f in $archivosSkills) {
            $fNorm = ($f.FullName -replace "\\", "/")
            $rel = $fNorm.Substring($repo.Length + 1)
            $txt = Get-Content -Path $f.FullName -Raw -Encoding UTF8
            $hash = Obtener-HashNormalizado $txt
            [void]$entradas.Add([PSCustomObject]@{ Ruta = $rel; Hash = $hash })
        }
    }

    $dirCommands = "$repo/.claude/commands"
    if (Test-Path $dirCommands) {
        $archivosCommands = Get-ChildItem -Path $dirCommands -Filter "*.md" -Recurse -File
        foreach ($f in $archivosCommands) {
            $fNorm = ($f.FullName -replace "\\", "/")
            $rel = $fNorm.Substring($repo.Length + 1)
            $txt = Get-Content -Path $f.FullName -Raw -Encoding UTF8
            $hash = Obtener-HashNormalizado $txt
            [void]$entradas.Add([PSCustomObject]@{ Ruta = $rel; Hash = $hash })
        }
    }

    $fijos = @(
        "templates/antigravity/GEMINI.md",
        "templates/antigravity/skills/odd-apply/SKILL.md",
        "templates/antigravity/statusline.bat",
        "templates/antigravity/statusline_new.ps1"
    )
    foreach ($rel in $fijos) {
        $rutaCompleta = "$repo/$rel"
        if (Test-Path $rutaCompleta -PathType Leaf) {
            $txt = Get-Content -Path $rutaCompleta -Raw -Encoding UTF8
            $hash = Obtener-HashNormalizado $txt
            [void]$entradas.Add([PSCustomObject]@{ Ruta = $rel; Hash = $hash })
        }
    }

    $comparer = [System.StringComparer]::Ordinal
    $entradas.Sort([System.Comparison[PSCustomObject]]{ param($a, $b) $comparer.Compare($a.Ruta, $b.Ruta) })

    $lineas = @($entradas | ForEach-Object { "$($_.Ruta)`t$($_.Hash)" })
    $textoUnido = $lineas -join "`n"
    $hashTotal = Obtener-HashNormalizado $textoUnido
    return $hashTotal.Substring(0, 12)
}
