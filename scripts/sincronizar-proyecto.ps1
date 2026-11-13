# scripts/sincronizar-proyecto.ps1
# Sincroniza las reglas del Agente y pr-check.yml en un proyecto conservando ## Propio del proyecto
# Uso: pwsh scripts/sincronizar-proyecto.ps1 -Proyecto <ruta> [-Agentes comun,copilot,cursor] [-PrCheck] [-Comprobar] [-Simular] [-Forzar] [-Aviso]

param(
    [Parameter(Mandatory = $true)]
    [string]$Proyecto,
    [string[]]$Agentes,
    [switch]$PrCheck,
    [switch]$Comprobar,
    [switch]$Simular,
    [switch]$Forzar,
    [switch]$Aviso
)

$ErrorActionPreference = "Stop"

if ($Aviso -and ($Comprobar -or $Simular -or $Forzar -or $Agentes -or $PrCheck)) {
    Write-Host "Error: -Aviso no se combina con otros modos (-Comprobar, -Simular, -Forzar, -Agentes, -PrCheck)."
    exit 1
}

. "$PSScriptRoot/comun.ps1"

$repoRoot = Obtener-RepoRoot
$proyPath = (Resolve-Path $Proyecto).Path

# 2. Definir lista de destinos
$destinos = [System.Collections.Generic.List[hashtable]]::new()

if ($Aviso) {
    $candidatosAviso = @(
        @{
            Agente = "comun"
            RutaRelativa = "AGENTS.md"
            FuentePath = Join-Path $repoRoot "templates/comun/AGENTS.md"
            RutaRepoRel = "templates/comun/AGENTS.md"
            TieneSeccionPropia = $true
        },
        @{
            Agente = "copilot"
            RutaRelativa = ".github/copilot-instructions.md"
            FuentePath = Join-Path $repoRoot "templates/copilot/copilot-instructions.md"
            RutaRepoRel = "templates/copilot/copilot-instructions.md"
            TieneSeccionPropia = $true
        },
        @{
            Agente = "copilot"
            RutaRelativa = ".github/prompts/odd-apply.prompt.md"
            FuentePath = Join-Path $repoRoot "templates/copilot/prompts/odd-apply.prompt.md"
            RutaRepoRel = "templates/copilot/prompts/odd-apply.prompt.md"
            TieneSeccionPropia = $false
        },
        @{
            Agente = "cursor"
            RutaRelativa = ".cursor/rules/sdd-workflow.mdc"
            FuentePath = Join-Path $repoRoot "templates/cursor/sdd-workflow.mdc"
            RutaRepoRel = "templates/cursor/sdd-workflow.mdc"
            TieneSeccionPropia = $true
        },
        @{
            Agente = "cursor"
            RutaRelativa = ".cursor/commands/odd-apply.md"
            FuentePath = Join-Path $repoRoot "templates/cursor/commands/odd-apply.md"
            RutaRepoRel = "templates/cursor/commands/odd-apply.md"
            TieneSeccionPropia = $false
        },
        @{
            Agente = "pr-check"
            RutaRelativa = ".github/workflows/pr-check.yml"
            FuentePath = Join-Path $repoRoot ".github/workflows/pr-check.yml"
            RutaRepoRel = ".github/workflows/pr-check.yml"
            TieneSeccionPropia = $false
        }
    )

    foreach ($cand in $candidatosAviso) {
        if (Test-Path (Join-Path $proyPath $cand.RutaRelativa)) {
            $destinos.Add($cand)
        }
    }

    if ($destinos.Count -eq 0) {
        Write-Host "Este proyecto no tiene archivos del Agente."
        exit 0
    }
} else {
    # 1. Determinar agentes a sincronizar
    $agentesLista = [System.Collections.Generic.List[string]]::new()
    if ($Agentes) {
        foreach ($a in $Agentes) {
            foreach ($sub in ($a -split ",")) {
                $trimmed = $sub.Trim().ToLowerInvariant()
                if ($trimmed) { $agentesLista.Add($trimmed) }
            }
        }
    }

    if ($agentesLista.Count -eq 0) {
        $agentesLista.Add("comun")
        if ((Test-Path (Join-Path $proyPath ".github/copilot-instructions.md")) -or (Test-Path (Join-Path $proyPath ".github/prompts/odd-apply.prompt.md"))) {
            $agentesLista.Add("copilot")
        }
        if (Test-Path (Join-Path $proyPath ".cursor")) {
            $agentesLista.Add("cursor")
        }
    }

    $sincronizarPrCheck = $PrCheck -or (Test-Path (Join-Path $proyPath ".github/workflows/pr-check.yml"))

    if ($agentesLista -contains "comun") {
        $destinos.Add(@{
            Agente = "comun"
            RutaRelativa = "AGENTS.md"
            FuentePath = Join-Path $repoRoot "templates/comun/AGENTS.md"
            RutaRepoRel = "templates/comun/AGENTS.md"
            TieneSeccionPropia = $true
        })
    }

    if ($agentesLista -contains "copilot") {
        $destinos.Add(@{
            Agente = "copilot"
            RutaRelativa = ".github/copilot-instructions.md"
            FuentePath = Join-Path $repoRoot "templates/copilot/copilot-instructions.md"
            RutaRepoRel = "templates/copilot/copilot-instructions.md"
            TieneSeccionPropia = $true
        })
        $destinos.Add(@{
            Agente = "copilot"
            RutaRelativa = ".github/prompts/odd-apply.prompt.md"
            FuentePath = Join-Path $repoRoot "templates/copilot/prompts/odd-apply.prompt.md"
            RutaRepoRel = "templates/copilot/prompts/odd-apply.prompt.md"
            TieneSeccionPropia = $false
        })
    }

    if ($agentesLista -contains "cursor") {
        $destinos.Add(@{
            Agente = "cursor"
            RutaRelativa = ".cursor/rules/sdd-workflow.mdc"
            FuentePath = Join-Path $repoRoot "templates/cursor/sdd-workflow.mdc"
            RutaRepoRel = "templates/cursor/sdd-workflow.mdc"
            TieneSeccionPropia = $true
        })
        $destinos.Add(@{
            Agente = "cursor"
            RutaRelativa = ".cursor/commands/odd-apply.md"
            FuentePath = Join-Path $repoRoot "templates/cursor/commands/odd-apply.md"
            RutaRepoRel = "templates/cursor/commands/odd-apply.md"
            TieneSeccionPropia = $false
        })
    }

    if ($sincronizarPrCheck) {
        $destinos.Add(@{
            Agente = "pr-check"
            RutaRelativa = ".github/workflows/pr-check.yml"
            FuentePath = Join-Path $repoRoot ".github/workflows/pr-check.yml"
            RutaRepoRel = ".github/workflows/pr-check.yml"
            TieneSeccionPropia = $false
        })
    }
}

# 3. Evaluar cada archivo
$filas = [System.Collections.Generic.List[hashtable]]::new()
$bloqueados = [System.Collections.Generic.List[hashtable]]::new()
$aEscribir = [System.Collections.Generic.List[hashtable]]::new()
$hayDistintos = $false

foreach ($d in $destinos) {
    $targetPath = Join-Path $proyPath $d.RutaRelativa
    $fuenteTxt = Normalizar-Texto (Get-Content -Path $d.FuentePath -Raw -Encoding UTF8)
    $hashFuente = Obtener-HashNormalizado $fuenteTxt

    $estado = ""
    $contenidoFinal = $fuenteTxt
    $esDistinto = $false
    $bloqueado = $false

    if (-not (Test-Path $targetPath)) {
        $estado = "creado"
        $esDistinto = $true
        $contenidoFinal = $fuenteTxt
    } else {
        $destTxt = ""
        $lecturaOk = $true
        try {
            $destTxt = Normalizar-Texto (Get-Content -Path $targetPath -Raw -Encoding UTF8)
        } catch {
            $lecturaOk = $false
        }

        if (-not $lecturaOk) {
            $estado = if ($d.TieneSeccionPropia) { "bloqueado: contenido propio" } else { "bloqueado" }
            $esDistinto = $true
            $bloqueado = $true
            $bloqueados.Add($d)
        } else {
            $hashDest = Obtener-HashNormalizado $destTxt

            if ($d.TieneSeccionPropia) {
                $sep = Separar-PropioProyecto $destTxt
                if ($sep.TienePropio) {
                    $combinado = Combinar-PropioProyecto -Generado $fuenteTxt -Propio $sep.Propio
                    $hashCombinado = Obtener-HashNormalizado $combinado
                    if ($hashDest -eq $hashCombinado) {
                        $estado = "igual"
                        $esDistinto = $false
                    } else {
                        $estado = "actualizado"
                        $esDistinto = $true
                    }
                    $contenidoFinal = $combinado
                } else {
                    if ($hashDest -eq $hashFuente) {
                        $estado = "igual"
                        $esDistinto = $false
                        $contenidoFinal = $fuenteTxt
                    } elseif (Test-EsVersionGitHistorica -RepoPath $repoRoot -RutaRelativa $d.RutaRepoRel -TextoAComparar $destTxt) {
                        $estado = "actualizado"
                        $esDistinto = $true
                        $contenidoFinal = $fuenteTxt
                    } else {
                        if ($Forzar) {
                            $estado = "actualizado"
                            $esDistinto = $true
                            $contenidoFinal = $fuenteTxt
                            $d["RutaBloqueada"] = $targetPath
                            $bloqueados.Add($d)
                        } else {
                            $estado = "bloqueado: contenido propio"
                            $esDistinto = $true
                            $bloqueado = $true
                            $bloqueados.Add($d)
                        }
                    }
                }
            } else {
                # Sin sección propia (pr-check.yml)
                if ($hashDest -eq $hashFuente) {
                    $estado = "igual"
                    $esDistinto = $false
                } elseif (Test-EsVersionGitHistorica -RepoPath $repoRoot -RutaRelativa $d.RutaRepoRel -TextoAComparar $destTxt) {
                    $estado = "actualizado"
                    $esDistinto = $true
                } else {
                    if ($Forzar) {
                        $estado = "actualizado"
                        $esDistinto = $true
                        $d["RutaBloqueada"] = $targetPath
                        $bloqueados.Add($d)
                    } else {
                        $estado = "bloqueado"
                        $esDistinto = $true
                        $bloqueado = $true
                        $bloqueados.Add($d)
                    }
                }
                $contenidoFinal = $fuenteTxt
            }
        }
    }

    if ($esDistinto) {
        $hayDistintos = $true
    }

    $d["TargetPath"] = $targetPath
    $d["ContenidoFinal"] = $contenidoFinal
    $d["Estado"] = $estado
    $d["Bloqueado"] = $bloqueado

    if (-not $bloqueado -and $esDistinto) {
        $aEscribir.Add($d)
    }

    $filas.Add(@{
        "Archivo" = $d.RutaRelativa
        "Estado" = $estado
    })
}

# 3.1 Modo -Aviso
if ($Aviso) {
    $atrasados = $destinos | Where-Object { $_.Estado -eq "actualizado" }
    $bloqueadosAviso = $destinos | Where-Object { $_.Bloqueado }

    if ($atrasados.Count -eq 0 -and $bloqueadosAviso.Count -eq 0) {
        Write-Host "Reglas del Agente al día en este proyecto."
        exit 0
    }

    $partes = [System.Collections.Generic.List[string]]::new()
    $partes.Add("Aviso: reglas del Agente desactualizadas en este proyecto.")

    if ($atrasados.Count -gt 0) {
        $listaAtrasados = ($atrasados | ForEach-Object { $_.RutaRelativa }) -join ", "
        $partes.Add("Atrasados: $listaAtrasados. Para actualizarlos: pwsh `$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .")
    }

    if ($bloqueadosAviso.Count -gt 0) {
        $listaBloqueados = ($bloqueadosAviso | ForEach-Object { $_.RutaRelativa }) -join ", "
        $partes.Add("Bloqueados por contenido propio: $listaBloqueados; pasá ese contenido debajo de `"## Propio del proyecto`" y volvé a sincronizar.")
    }

    Write-Host ($partes -join " ")
    exit 1
}

# 4. Mostrar tabla
Write-Host "Sincronización en proyecto: $proyPath"
$filas | Select-Object "Archivo", "Estado" | Format-Table -AutoSize | Out-String | Write-Host

# 5. Si se pidió -Comprobar
if ($Comprobar) {
    if ($hayDistintos -or $bloqueados.Count -gt 0) {
        Write-Host "Comprobar: Se encontraron archivos atrasados, modificados o bloqueados."
        exit 1
    }
    Write-Host "Comprobar: Todos los archivos están al día."
    exit 0
}

# 6. Manejo de bloqueados
if ($bloqueados.Count -gt 0 -and -not $Forzar) {
    Write-Host "`nError: Se encontraron archivos bloqueados por contenido propio:"
    foreach ($b in $bloqueados) {
        Write-Host "  - $($b.RutaRelativa)"
    }
    Write-Host "Para resolverlo, pase el contenido propio debajo de '## Propio del proyecto' del archivo generado o ejecute con -Forzar."
    exit 1
}

# Si -Forzar y hay respaldos pendientes
if ($Forzar -and $bloqueados.Count -gt 0) {
    $rutasARespaldar = $bloqueados | ForEach-Object { $_.RutaBloqueada } | Where-Object { $_ -and (Test-Path $_) }
    if ($rutasARespaldar) {
        $respaldoDir = Respaldar-Archivos -Rutas $rutasARespaldar -BaseDir $proyPath
        Write-Host "Archivos bloqueados respaldados en: $respaldoDir"
    }
}

# 7. Si es -Simular
if ($Simular) {
    Write-Host "Simular: No se realizaron escrituras en el proyecto."
    exit 0
}

# 8. Escribir archivos
foreach ($item in $aEscribir) {
    Escribir-ArchivoUtf8SinBom -Ruta $item.TargetPath -Texto $item.ContenidoFinal
}

Write-Host "Sincronización completada."
exit 0
