# scripts/instalar.ps1
# Instala las reglas globales, skills, comandos y espejo del vault
# Uso: pwsh scripts/instalar.ps1 [-Destino <ruta>] [-Vault <ruta>] [-SinVault] [-Simular] [-Forzar] [-Comprobar]

param(
    [string]$Destino = $HOME,
    [string]$Vault,
    [switch]$SinVault,
    [switch]$Simular,
    [switch]$Forzar,
    [switch]$Comprobar
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/comun.ps1"

$repoRoot = Obtener-RepoRoot

if ([string]::IsNullOrWhiteSpace($Destino)) {
    $Destino = $HOME
}

# D9: Resolución del vault
if (-not $SinVault) {
    if ([string]::IsNullOrWhiteSpace($Vault)) {
        if (-not [string]::IsNullOrWhiteSpace($env:OBSIDIAN_VAULT)) {
            $Vault = $env:OBSIDIAN_VAULT
        } else {
            $userVault = [Environment]::GetEnvironmentVariable("OBSIDIAN_VAULT", "User")
            if (-not [string]::IsNullOrWhiteSpace($userVault)) {
                $Vault = $userVault
            }
        }
    }
}

$hayVault = $false
$vaultPathAbs = $null
$vaultTieneEspacios = $false
$vaultAbsBarras = $null

if (-not $SinVault) {
    if ([string]::IsNullOrWhiteSpace($Vault) -or -not (Test-Path $Vault)) {
        Write-Host "Aviso: El vault de Obsidian no está configurado o no existe ($Vault). Continuando sin espejo del vault."
    } else {
        $hayVault = $true
        $vaultPathAbs = (Resolve-Path $Vault).Path
        $vaultAbsBarras = $vaultPathAbs -replace "\\", "/"
        if ($vaultPathAbs.Contains(" ")) {
            $vaultTieneEspacios = $true
            Write-Host "Aviso: La ruta del vault tiene espacios; se instala la copia completa del CLAUDE.md en lugar del archivo de carga."
        }
    }
}

# D4: Contenido esperado de .claude/CLAUDE.md según haya vault
$claudeRepo = Join-Path $repoRoot ".claude/CLAUDE.md"
$cuerpoRepo = Normalizar-Texto (Get-Content -Path $claudeRepo -Raw -Encoding UTF8)

$claudeEsperado = $null
$esArchivoCarga = $false

if ($hayVault -and (-not $vaultTieneEspacios)) {
    $esArchivoCarga = $true
    $plantillaCarga = @'
<!-- Generado por scripts/instalar.ps1 de sdd-global-config. No editar a mano: las reglas se editan en el repo. -->

# Reglas globales del workflow SDD

Las reglas se cargan desde el vault con la línea de abajo. Si después de esa línea no ves la sección "Roles Claude / Agente (OpenSpec)", el vault no cargó: avisá al usuario antes de seguir y pedile que corra `scripts/instalar.ps1` del repo `sdd-global-config`.

@<VAULT_PATH>/_global/reglas-globales.md
'@
    $claudeEsperado = Normalizar-Texto ($plantillaCarga.Replace('<VAULT_PATH>', $vaultAbsBarras))
} else {
    $claudeEsperado = $cuerpoRepo
}

# 1. Definir lista de archivos a instalar en destino
$items = [System.Collections.Generic.List[hashtable]]::new()

# .claude/CLAUDE.md
if (Test-Path $claudeRepo) {
    $items.Add(@{
        RutaRepoRel = ".claude/CLAUDE.md"
        RutaDestRel = ".claude/CLAUDE.md"
        FuentePath = $claudeRepo
        DestinoPath = Join-Path $Destino ".claude/CLAUDE.md"
        EsGemini = $false
        ContenidoEsperado = $claudeEsperado
        EsArchivoCarga = $esArchivoCarga
    })
}

# skills/
$skillsDir = Join-Path $repoRoot "skills"
if (Test-Path $skillsDir) {
    $skillFiles = Get-ChildItem -Path $skillsDir -Recurse -File
    foreach ($sf in $skillFiles) {
        $sub = $sf.FullName.Substring($skillsDir.Length).TrimStart("\", "/")
        $txtSkill = Normalizar-Texto (Get-Content -Path $sf.FullName -Raw -Encoding UTF8)
        $items.Add(@{
            RutaRepoRel = ("skills/$sub" -replace "\\", "/")
            RutaDestRel = (".claude/skills/$sub" -replace "\\", "/")
            FuentePath = $sf.FullName
            DestinoPath = Join-Path $Destino (".claude/skills/$sub" -replace "/", "\")
            EsGemini = $false
            ContenidoEsperado = $txtSkill
            EsArchivoCarga = $false
        })
    }
}

# .claude/commands/ (*.md)
$commandsDir = Join-Path $repoRoot ".claude/commands"
if (Test-Path $commandsDir) {
    $cmdFiles = Get-ChildItem -Path $commandsDir -Filter "*.md" -Recurse -File
    foreach ($cf in $cmdFiles) {
        $sub = $cf.FullName.Substring($commandsDir.Length).TrimStart("\", "/")
        $txtCmd = Normalizar-Texto (Get-Content -Path $cf.FullName -Raw -Encoding UTF8)
        $items.Add(@{
            RutaRepoRel = (".claude/commands/$sub" -replace "\\", "/")
            RutaDestRel = (".claude/commands/$sub" -replace "\\", "/")
            FuentePath = $cf.FullName
            DestinoPath = Join-Path $Destino (".claude/commands/$sub" -replace "/", "\")
            EsGemini = $false
            ContenidoEsperado = $txtCmd
            EsArchivoCarga = $false
        })
    }
}

# templates/antigravity/GEMINI.md (solo si existe <Destino>/.gemini)
$geminiDestDir = Join-Path $Destino ".gemini"
$geminiPlantilla = Join-Path $repoRoot "templates/antigravity/GEMINI.md"
if ((Test-Path $geminiDestDir) -and (Test-Path $geminiPlantilla)) {
    $txtGemini = Normalizar-Texto (Get-Content -Path $geminiPlantilla -Raw -Encoding UTF8)
    $items.Add(@{
        RutaRepoRel = "templates/antigravity/GEMINI.md"
        RutaDestRel = ".gemini/GEMINI.md"
        FuentePath = $geminiPlantilla
        DestinoPath = Join-Path $Destino ".gemini/GEMINI.md"
        EsGemini = $true
        ContenidoEsperado = $txtGemini
        EsArchivoCarga = $false
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

# 3. Evaluar estado de cada archivo de destino
$filasTabla = [System.Collections.Generic.List[hashtable]]::new()
$cambiosLocales = [System.Collections.Generic.List[hashtable]]::new()

foreach ($item in $items) {
    $targetContenido = $item.ContenidoEsperado
    $hashRepo = Obtener-HashNormalizado $targetContenido

    $existeDestino = Test-Path $item.DestinoPath
    $hashInstalado = "-"
    $estado = "creado"
    $esIgual = "no"

    if ($existeDestino) {
        $destTxt = Normalizar-Texto (Get-Content -Path $item.DestinoPath -Raw -Encoding UTF8)
        $hashInstalado = Obtener-HashNormalizado $destTxt

        if ($item.EsGemini) {
            $sep = Separar-PropioProyecto $destTxt
            if ($sep.TienePropio) {
                $hashBaseDest = Obtener-HashNormalizado $sep.Base
                $sepRepo = Separar-PropioProyecto $targetContenido
                $hashBaseRepo = Obtener-HashNormalizado $sepRepo.Base

                $targetContenido = Combinar-PropioProyecto -Generado $item.ContenidoEsperado -Propio $sep.Propio
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

# D5 y D6: Evaluar y clasificar el espejo del vault antes de escribir
$shortCommit = (git -C $repoRoot rev-parse --short HEAD 2>$null)
if (-not $shortCommit) { $shortCommit = "desconocido" } else { $shortCommit = $shortCommit.Trim() }
$hoy = Get-Date -Format "yyyy-MM-dd"

$espejoNuevo = Normalizar-Texto @"
---
type: reglas-globales
source: sdd-global-config/.claude/CLAUDE.md
commit: $shortCommit
updated: $hoy
---

> [!info] Espejo de solo lectura. Fuente: ``.claude/CLAUDE.md`` del repo ``sdd-global-config``. Lo escribe solo ``scripts/instalar.ps1``. No editar acá.

$cuerpoRepo
"@

function Quitar-LineasDinamicasEspejo {
    param([string]$Texto)
    if ([string]::IsNullOrWhiteSpace($Texto)) { return "" }
    $norm = Normalizar-Texto $Texto
    $lineas = $norm -split "\n"
    $filtradas = @($lineas | Where-Object {
        $_ -notmatch "^\s*commit:\s*" -and $_ -notmatch "^\s*updated:\s*"
    })
    return ($filtradas -join "`n").TrimEnd("`n", "`r")
}

function Extraer-CuerpoEspejo {
    param([string]$TextoEspejo)
    if ([string]::IsNullOrWhiteSpace($TextoEspejo)) { return $null }
    $norm = Normalizar-Texto $TextoEspejo
    $lineas = $norm -split "\n"
    for ($i = 0; $i -lt $lineas.Count; $i++) {
        if ($lineas[$i] -match "^\s*>\s*\[!info\]") {
            $idxCuerpo = $i + 1
            if ($idxCuerpo -lt $lineas.Count -and [string]::IsNullOrWhiteSpace($lineas[$idxCuerpo])) {
                $idxCuerpo++
            }
            if ($idxCuerpo -lt $lineas.Count) {
                return ($lineas[$idxCuerpo..($lineas.Count - 1)] -join "`n").TrimEnd("`n", "`r")
            }
            return ""
        }
    }
    return $null
}

$estadoEspejo = "creado"
$espejoPath = $null
$globalDir = $null
$commitDesconocido = $null

if ($hayVault) {
    $globalDir = Join-Path $vaultPathAbs "_global"
    $espejoPath = Join-Path $globalDir "reglas-globales.md"
    $hashEspejoNuevo = Obtener-HashNormalizado $espejoNuevo
    $hashEspejoInstalado = "-"
    $espejoIgual = "no"

    if (-not (Test-Path $espejoPath)) {
        # 1. No existe el archivo: creado
        $estadoEspejo = "creado"
    } else {
        $espejoTxt = Normalizar-Texto (Get-Content -Path $espejoPath -Raw -Encoding UTF8)
        $hashEspejoInstalado = Obtener-HashNormalizado $espejoTxt

        # 2. El espejo es igual al que se generaría, sin contar commit: y updated:
        $dinamicasInst = Quitar-LineasDinamicasEspejo $espejoTxt
        $dinamicasNuevo = Quitar-LineasDinamicasEspejo $espejoNuevo

        if ($dinamicasInst -eq $dinamicasNuevo) {
            $estadoEspejo = "igual"
            $espejoIgual = "sí"
        } else {
            $cuerpoEspejo = Extraer-CuerpoEspejo $espejoTxt
            $cuerpoRepoNorm = (Normalizar-Texto $cuerpoRepo).TrimEnd("`n", "`r")

            if ($null -ne $cuerpoEspejo -and $cuerpoEspejo -eq $cuerpoRepoNorm) {
                # 3. El cuerpo es igual a .claude/CLAUDE.md del repo (solo cambia el encabezado): atrasado
                $estadoEspejo = "atrasado"
            } else {
                # 4. El encabezado tiene commit: y git cat-file falla: repo atrasado
                $matchCommit = [regex]::Match($espejoTxt, "(?m)^\s*commit:\s*([a-fA-F0-9]+)\s*$")
                $repoAtrasado = $false
                if ($matchCommit.Success) {
                    $commitVal = $matchCommit.Groups[1].Value.Trim()
                    git -C $repoRoot cat-file -e "${commitVal}^{commit}" 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        $repoAtrasado = $true
                        $commitDesconocido = $commitVal
                    }
                }

                if ($repoAtrasado) {
                    $estadoEspejo = "repo atrasado"
                } elseif ($null -ne $cuerpoEspejo -and (Test-EsVersionGitHistorica -RepoPath $repoRoot -RutaRelativa ".claude/CLAUDE.md" -TextoAComparar $cuerpoEspejo)) {
                    # 5. El cuerpo es una versión anterior según Test-EsVersionGitHistorica: atrasado
                    $estadoEspejo = "atrasado"
                } else {
                    # 6. Cualquier otro caso: con cambios locales
                    $estadoEspejo = "con cambios locales"
                }
            }
        }
    }

    $hashEspN12 = if ($hashEspejoNuevo.Length -ge 12) { $hashEspejoNuevo.Substring(0, 12) } else { $hashEspejoNuevo }
    $hashEspI12 = if ($hashEspejoInstalado -ne "-" -and $hashEspejoInstalado.Length -ge 12) { $hashEspejoInstalado.Substring(0, 12) } else { $hashEspejoInstalado }

    $filasTabla.Add(@{
        "Archivo" = "vault: _global/reglas-globales.md"
        "Estado previo" = $estadoEspejo
        "Hash repo" = $hashEspN12
        "Hash instalado" = $hashEspI12
        "Igual" = $espejoIgual
    })

    if ($estadoEspejo -eq "con cambios locales") {
        $cambiosLocales.Add(@{
            RutaDestRel = "_global/reglas-globales.md"
            DestinoPath = $espejoPath
        })
    }
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

# D8: -Comprobar
if ($Comprobar) {
    $archivosDifieren = [System.Collections.Generic.List[hashtable]]::new()
    foreach ($f in $filasTabla) {
        if ($f["Igual"] -ne "sí") {
            $archivosDifieren.Add($f)
        }
    }
    if ($archivosDifieren.Count -gt 0) {
        Write-Host "`nError: Los siguientes archivos no están sincronizados:"
        foreach ($ad in $archivosDifieren) {
            Write-Host "  - $($ad["Archivo"]) ($($ad["Estado previo"]))"
        }
        exit 1
    }
    Write-Host "`nOK: Todos los archivos están sincronizados."
    exit 0
}

# D6 paso 4: Repo atrasado frena siempre
if ($hayVault -and $estadoEspejo -eq "repo atrasado") {
    Write-Host "`nError: El espejo del vault viene de un commit que este repo no tiene ($commitDesconocido). Corré git pull en el repo y volvé a instalar."
    exit 1
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

# D7: 7. Escribir primero el espejo del vault
if ($hayVault -and $estadoEspejo -ne "igual") {
    if (-not (Test-Path $globalDir)) {
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
    }
    Escribir-ArchivoUtf8SinBom -Ruta $espejoPath -Texto $espejoNuevo

    git -C $vaultPathAbs add "_global/reglas-globales.md" 2>$null
    $staged = git -C $vaultPathAbs diff --staged --name-only 2>$null
    if ($staged) {
        git -C $vaultPathAbs commit -m "chore: sdd-global-config — sync reglas" 2>$null
        if ($LASTEXITCODE -ne 0) {
            git -C $vaultPathAbs -c user.name="sdd-global-config" -c user.email="sdd@local" commit -m "chore: sdd-global-config — sync reglas" 2>$null
        }
        git -C $vaultPathAbs push 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Aviso: Falló git push en el vault."
        }
    }
    Write-Host "Espejo del vault actualizado en: $espejoPath"
}

# 8. Copiar archivos en destino y construir nuevo manifiesto
$manifiestoNuevoArchivos = @{}

foreach ($item in $items) {
    Escribir-ArchivoUtf8SinBom -Ruta $item.DestinoPath -Texto $item.TargetContenido
    $hashEscrito = Obtener-HashNormalizado $item.TargetContenido
    $manifiestoNuevoArchivos[$item.RutaDestRel] = $hashEscrito
}

# Escribir manifiesto
$manifiestoObj = [ordered]@{
    commit = $shortCommit
    fecha = (Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ")
    archivos = $manifiestoNuevoArchivos
}
$manifiestoJson = $manifiestoObj | ConvertTo-Json -Depth 5
Escribir-ArchivoUtf8SinBom -Ruta $manifiestoPath -Texto $manifiestoJson
Write-Host "Manifiesto actualizado en: $manifiestoPath"

Write-Host "Instalación completada con éxito."
exit 0
