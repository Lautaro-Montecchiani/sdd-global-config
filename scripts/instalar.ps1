# scripts/instalar.ps1
# Instala las reglas globales, skills, comandos y espejo del vault
# Uso: pwsh scripts/instalar.ps1 [-Destino <ruta>] [-Vault <ruta>] [-SinVault] [-Simular] [-Forzar]

param(
    [string]$Destino = $HOME,
    [string]$Vault = $env:OBSIDIAN_VAULT,
    [switch]$SinVault,
    [switch]$Simular,
    [switch]$Forzar
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/comun.ps1"

$repoRoot = Obtener-RepoRoot

if ([string]::IsNullOrWhiteSpace($Destino)) {
    $Destino = $HOME
}

# 1. Definir lista de archivos a instalar
# Estructura: @{ RutaRepoRel = ...; RutaDestRel = ...; FuentePath = ...; DestinoPath = ...; EsGemini = ... }
$items = [System.Collections.Generic.List[hashtable]]::new()

# .claude/CLAUDE.md
$claudeRepo = Join-Path $repoRoot ".claude/CLAUDE.md"
if (Test-Path $claudeRepo) {
    $items.Add(@{
        RutaRepoRel = ".claude/CLAUDE.md"
        RutaDestRel = ".claude/CLAUDE.md"
        FuentePath = $claudeRepo
        DestinoPath = Join-Path $Destino ".claude/CLAUDE.md"
        EsGemini = $false
    })
}

# skills/
$skillsDir = Join-Path $repoRoot "skills"
if (Test-Path $skillsDir) {
    $skillFiles = Get-ChildItem -Path $skillsDir -Recurse -File
    foreach ($sf in $skillFiles) {
        $sub = $sf.FullName.Substring($skillsDir.Length).TrimStart("\", "/")
        $items.Add(@{
            RutaRepoRel = ("skills/$sub" -replace "\\", "/")
            RutaDestRel = (".claude/skills/$sub" -replace "\\", "/")
            FuentePath = $sf.FullName
            DestinoPath = Join-Path $Destino (".claude/skills/$sub" -replace "/", "\")
            EsGemini = $false
        })
    }
}

# .claude/commands/ (*.md)
$commandsDir = Join-Path $repoRoot ".claude/commands"
if (Test-Path $commandsDir) {
    $cmdFiles = Get-ChildItem -Path $commandsDir -Filter "*.md" -Recurse -File
    foreach ($cf in $cmdFiles) {
        $sub = $cf.FullName.Substring($commandsDir.Length).TrimStart("\", "/")
        $items.Add(@{
            RutaRepoRel = (".claude/commands/$sub" -replace "\\", "/")
            RutaDestRel = (".claude/commands/$sub" -replace "\\", "/")
            FuentePath = $cf.FullName
            DestinoPath = Join-Path $Destino (".claude/commands/$sub" -replace "/", "\")
            EsGemini = $false
        })
    }
}

# templates/antigravity/GEMINI.md (solo si existe <Destino>/.gemini)
$geminiDestDir = Join-Path $Destino ".gemini"
$geminiPlantilla = Join-Path $repoRoot "templates/antigravity/GEMINI.md"
if ((Test-Path $geminiDestDir) -and (Test-Path $geminiPlantilla)) {
    $items.Add(@{
        RutaRepoRel = "templates/antigravity/GEMINI.md"
        RutaDestRel = ".gemini/GEMINI.md"
        FuentePath = $geminiPlantilla
        DestinoPath = Join-Path $Destino ".gemini/GEMINI.md"
        EsGemini = $true
    })
}

# 2. Cargar manifiesto previo si existe
$manifiestoPath = Join-Path $Destino ".claude/.sdd-global-config.json"
$manifiestoPrevio = $null
if (Test-Path $manifiestoPath) {
    try {
        $manifiestoRaw = Get-Content -Path $manifiestoPath -Raw -Encoding UTF8
        $manifiestoPrevio = $manifiestoRaw | ConvertFrom-Json
    } catch {
        $manifiestoPrevio = $null
    }
}

# 3. Evaluar estado de cada archivo
$filasTabla = [System.Collections.Generic.List[hashtable]]::new()
$cambiosLocales = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $items) {
    $fuenteTxt = Normalizar-Texto (Get-Content -Path $item.FuentePath -Raw -Encoding UTF8)
    $hashRepo = Obtener-HashNormalizado $fuenteTxt

    $existeDestino = Test-Path $item.DestinoPath
    $hashInstalado = "-"
    $estado = "creado"
    $esIgual = "no"
    $targetContenido = $fuenteTxt

    if ($existeDestino) {
        $destTxt = Normalizar-Texto (Get-Content -Path $item.DestinoPath -Raw -Encoding UTF8)
        $hashInstalado = Obtener-HashNormalizado $destTxt

        if ($item.EsGemini) {
            $sep = Separar-PropioProyecto $destTxt
            if ($sep.TienePropio) {
                $hashBaseDest = Obtener-HashNormalizado $sep.Base
                $sepRepo = Separar-PropioProyecto $fuenteTxt
                $hashBaseRepo = Obtener-HashNormalizado $sepRepo.Base

                $targetContenido = Combinar-PropioProyecto -Generado $fuenteTxt -Propio $sep.Propio
                $hashTarget = Obtener-HashNormalizado $targetContenido

                if ($hashInstalado -eq $hashTarget -or $hashBaseDest -eq $hashBaseRepo) {
                    $estado = "igual"
                    $esIgual = "sí"
                } else {
                    $estado = "atrasado"
                }
            } else {
                if ($hashInstalado -eq $hashRepo) {
                    $estado = "igual"
                    $esIgual = "sí"
                } else {
                    $claveManifiesto = $item.RutaDestRel
                    $hashManifiesto = $null
                    if ($manifiestoPrevio -and $manifiestoPrevio.archivos -and $manifiestoPrevio.archivos.$claveManifiesto) {
                        $hashManifiesto = $manifiestoPrevio.archivos.$claveManifiesto
                    }

                    if ($hashManifiesto -and $hashInstalado -eq $hashManifiesto) {
                        $estado = "atrasado"
                    } elseif (Test-EsVersionGitHistorica -RepoPath $repoRoot -RutaRelativa $item.RutaRepoRel -TextoAComparar $destTxt) {
                        $estado = "atrasado"
                    } else {
                        $estado = "con cambios locales"
                    }
                }
            }
        } else {
            if ($hashInstalado -eq $hashRepo) {
                $estado = "igual"
                $esIgual = "sí"
            } else {
                $claveManifiesto = $item.RutaDestRel
                $hashManifiesto = $null
                if ($manifiestoPrevio -and $manifiestoPrevio.archivos -and $manifiestoPrevio.archivos.$claveManifiesto) {
                    $hashManifiesto = $manifiestoPrevio.archivos.$claveManifiesto
                }

                if ($hashManifiesto -and $hashInstalado -eq $hashManifiesto) {
                    $estado = "atrasado"
                } elseif (Test-EsVersionGitHistorica -RepoPath $repoRoot -RutaRelativa $item.RutaRepoRel -TextoAComparar $destTxt) {
                    $estado = "atrasado"
                } else {
                    $estado = "con cambios locales"
                }
            }
        }
    }

    $item["Estado"] = $estado
    $item["HashRepo"] = $hashRepo
    $item["HashInstalado"] = $hashInstalado
    $item["EsIgual"] = $esIgual
    $item["TargetContenido"] = $targetContenido

    if ($estado -eq "con cambios locales") {
        $cambiosLocales.Add($item)
    }

    $hashRepo12 = if ($hashRepo.Length -ge 12) { $hashRepo.Substring(0, 12) } else { $hashRepo }
    $hashInst12 = if ($hashInstalado -ne "-" -and $hashInstalado.Length -ge 12) { $hashInstalado.Substring(0, 12) } else { $hashInstalado }

    $filasTabla.Add(@{
        "Archivo" = $item.RutaDestRel
        "Estado previo" = $estado
        "Hash repo" = $hashRepo12
        "Hash instalado" = $hashInst12
        "Igual" = $esIgual
    })
}

# 4. Mostrar tabla
Write-Host "Estado de instalación en $Destino"
$formateada = $filasTabla | Select-Object "Archivo", "Estado previo", "Hash repo", "Hash instalado", "Igual"
$formateada | Format-Table -AutoSize | Out-String | Write-Host

# Chequear sobrantes en manifiesto
if ($manifiestoPrevio -and $manifiestoPrevio.archivos) {
    $archivosInstalados = $items | ForEach-Object { $_.RutaDestRel }
    foreach ($prop in $manifiestoPrevio.archivos.PSObject.Properties) {
        if ($archivosInstalados -notcontains $prop.Name) {
            $destSobrante = Join-Path $Destino ($prop.Name -replace "/", "\")
            if (Test-Path $destSobrante) {
                Write-Host "Aviso: Archivo sobrante detectado (no se borra): $($prop.Name)"
            }
        }
    }
}

# Chequear cambios sin commitear en repo
$rutasRepo = @(".claude/CLAUDE.md", "skills", ".claude/commands", "templates/antigravity/GEMINI.md")
$cambiosRepo = git -C $repoRoot status --porcelain -- $rutasRepo 2>$null
if ($cambiosRepo) {
    Write-Host "Aviso: El repositorio tiene cambios sin commitear en las rutas instaladas."
}

# 5. Manejo de cambios locales
if ($cambiosLocales.Count -gt 0) {
    if (-not $Forzar) {
        Write-Host "`nError: Se encontraron archivos con cambios locales:"
        foreach ($cl in $cambiosLocales) {
            Write-Host "  - $($cl.RutaDestRel) ($($cl.DestinoPath))"
        }
        Write-Host "Use -Forzar para respaldar y sobreescribir."
        exit 1
    } else {
        $rutasARespaldar = $cambiosLocales | ForEach-Object { $_.DestinoPath }
        $respaldoDir = Respaldar-Archivos -Rutas $rutasARespaldar -BaseDir $Destino
        Write-Host "Archivos con cambios locales respaldados en: $respaldoDir"
    }
}

# 6. Si es simulación, terminar
if ($Simular) {
    Write-Host "`nSimular: No se realizaron cambios en destino, manifiesto ni vault."
    exit 0
}

# 7. Copiar archivos y construir nuevo manifiesto
$manifiestoNuevoArchivos = @{}

foreach ($item in $items) {
    Escribir-ArchivoUtf8SinBom -Ruta $item.DestinoPath -Texto $item.TargetContenido
    $hashEscrito = Obtener-HashNormalizado $item.TargetContenido
    $manifiestoNuevoArchivos[$item.RutaDestRel] = $hashEscrito
}

# Escribir manifiesto
$shortCommit = (git -C $repoRoot rev-parse --short HEAD 2>$null)
if (-not $shortCommit) { $shortCommit = "desconocido" } else { $shortCommit = $shortCommit.Trim() }

$manifiestoObj = [ordered]@{
    commit = $shortCommit
    fecha = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    archivos = $manifiestoNuevoArchivos
}
$manifiestoJson = $manifiestoObj | ConvertTo-Json -Depth 5
Escribir-ArchivoUtf8SinBom -Ruta $manifiestoPath -Texto $manifiestoJson
Write-Host "Manifiesto actualizado en: $manifiestoPath"

# 8. Espejo del vault
if (-not $SinVault) {
    if ([string]::IsNullOrWhiteSpace($Vault) -or -not (Test-Path $Vault)) {
        Write-Host "Aviso: El vault de Obsidian no está configurado o no existe ($Vault). Continuando sin espejo del vault."
    } else {
        $globalDir = Join-Path $Vault "_global"
        $espejoPath = Join-Path $globalDir "reglas-globales.md"
        $hoy = Get-Date -Format "yyyy-MM-dd"
        $header = "---`ntype: reglas-globales`nsource: ~/.claude/CLAUDE.md`nupdated: $hoy`n---`n`n> [!info] Espejo de solo lectura. Fuente canónica: ``~/.claude/CLAUDE.md``. No editar acá.`n`n"
        $claudeInstalado = Get-Content -Path (Join-Path $Destino ".claude/CLAUDE.md") -Raw -Encoding UTF8
        $contenidoEspejo = $header + (Normalizar-Texto $claudeInstalado)
        Escribir-ArchivoUtf8SinBom -Ruta $espejoPath -Texto $contenidoEspejo

        git -C $Vault add "_global/reglas-globales.md" 2>$null
        $staged = git -C $Vault diff --staged --name-only 2>$null
        if ($staged) {
            # Intentar commit
            git -C $Vault commit -m "chore: sdd-global-config — sync reglas" 2>$null
            if ($LASTEXITCODE -ne 0) {
                git -C $Vault -c user.name="sdd-global-config" -c user.email="sdd@local" commit -m "chore: sdd-global-config — sync reglas" 2>$null
            }
            git -C $Vault push 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Host "Aviso: Falló git push en el vault."
            }
        }
        Write-Host "Espejo del vault actualizado en: $espejoPath"
    }
}

Write-Host "Instalación completada con éxito."
exit 0
