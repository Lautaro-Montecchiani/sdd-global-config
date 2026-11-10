# scripts/sincronizar-proyecto.ps1
# Sincroniza las reglas del Agente y pr-check.yml en un proyecto conservando ## Propio del proyecto
# Uso: pwsh scripts/sincronizar-proyecto.ps1 -Proyecto <ruta> [-Agentes comun,copilot,cursor] [-PrCheck] [-Comprobar] [-Simular] [-Forzar]

param(
    [Parameter(Mandatory = $true)]
    [string]$Proyecto,
    [string[]]$Agentes,
    [switch]$PrCheck,
    [switch]$Comprobar,
    [switch]$Simular,
    [switch]$Forzar
)

$ErrorActionPreference = "Stop"

. "$PSScriptRoot/comun.ps1"

$repoRoot = Obtener-RepoRoot
$proyPath = (Resolve-Path $Proyecto).Path

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
    if (Test-Path (Join-Path $proyPath ".github/copilot-instructions.md")) {
        $agentesLista.Add("copilot")
    }
    if (Test-Path (Join-Path $proyPath ".cursor")) {
        $agentesLista.Add("cursor")
    }
}

$sincronizarPrCheck = $PrCheck -or (Test-Path (Join-Path $proyPath ".github/workflows/pr-check.yml"))

# 2. Definir lista de destinos
$destinos = [System.Collections.Generic.List[hashtable]]::new()

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
}

if ($agentesLista -contains "cursor") {
    $destinos.Add(@{
        Agente = "cursor"
        RutaRelativa = ".cursor/rules/sdd-workflow.mdc"
        FuentePath = Join-Path $repoRoot "templates/cursor/sdd-workflow.mdc"
        RutaRepoRel = "templates/cursor/sdd-workflow.mdc"
        TieneSeccionPropia = $true
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
        $destTxt = Normalizar-Texto (Get-Content -Path $targetPath -Raw -Encoding UTF8)
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
