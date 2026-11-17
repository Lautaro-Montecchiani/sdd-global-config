# tests/metricas-de-flujo.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptMetricas = "$repoRoot/scripts/metricas.ps1"

function Ejecutar-Metricas {
    param(
        [int]$Semanas = 0,
        [string]$Ahora = $null,
        [string]$Config = $null,
        [string]$Salida = $null,
        [string]$Entrada = $null,
        [hashtable]$EnvExtra = @{}
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptMetricas`"")
    if ($Semanas -gt 0) { $argumentos += @('-Semanas', $Semanas) }
    if ($Ahora) { $argumentos += @('-Ahora', "`"$Ahora`"") }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
    if ($Salida) { $argumentos += @('-Salida', "`"$Salida`"") }
    if ($Entrada) { $argumentos += @('-Entrada', "`"$Entrada`"") }

    $psi.Arguments = $argumentos -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false

    foreach ($k in $EnvExtra.Keys) {
        $psi.EnvironmentVariables[$k] = $EnvExtra[$k]
    }

    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()

    return [PSCustomObject]@{
        ExitCode = $proc.ExitCode
        Stdout   = $stdout
        Stderr   = $stderr
    }
}

function Crear-ConfigTableroPrueba {
    param([string]$Ruta, [string]$Owner = "dueno-prueba", [int]$Numero = 7)
    $contenido = @"
---
owner: $Owner
numero: $Numero
wip-diseno: 1
wip-construccion: 2
wip-revision: 2
---
# Tablero de prueba
"@
    [System.IO.File]::WriteAllText($Ruta, $contenido, [System.Text.UTF8Encoding]::new($false))
}

function Crear-EntradaJson {
    param([string]$Ruta, [array]$Paginas)
    $obj = @{ paginas = $Paginas }
    $json = $obj | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($Ruta, $json, [System.Text.UTF8Encoding]::new($false))
}

function Crear-PaginaGraphQL {
    param(
        [array]$Items = @(),
        [bool]$HasNextPage = $false,
        [string]$EndCursor = $null
    )
    return @{
        data = @{
            repositoryOwner = @{
                projectV2 = @{
                    items = @{
                        pageInfo = @{
                            hasNextPage = $HasNextPage
                            endCursor   = $EndCursor
                        }
                        nodes = $Items
                    }
                }
            }
        }
    }
}

function Crear-ItemNodo {
    param(
        $Numero = 1,
        [string]$Titulo = "Issue de prueba",
        [string]$Repo = "dueno-prueba/repo-prueba",
        [string]$CreatedAt = "2026-03-20T12:00:00Z",
        [string]$ClosedAt = $null,
        [array]$Eventos = @()
    )

    $eventNodes = @()
    foreach ($ev in $Eventos) {
        $eventNodes += @{
            createdAt = $ev.createdAt
            status    = $ev.status
            project   = @{
                number = $ev.projectNumber
                owner  = @{
                    login = $ev.projectOwner
                }
            }
        }
    }

    $content = @{
        title     = $Titulo
        createdAt = $CreatedAt
        closedAt  = $ClosedAt
        repository = @{
            nameWithOwner = $Repo
        }
        timelineItems = @{
            nodes = $eventNodes
        }
    }
    if ($null -ne $Numero) {
        $content['number'] = $Numero
    }

    return @{ content = $content }
}

# test-plan: metricas-de-flujo/S01
Probar "S01 Historial del tablero para las métricas / Eventos de otros Projects" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath -Owner "dueno-prueba" -Numero 7

        $eventos = @(
            @{ createdAt = "2026-03-21T12:00:00Z"; status = "In progress"; projectNumber = 3; projectOwner = "dueno-prueba" },
            @{ createdAt = "2026-03-21T12:00:00Z"; status = "In progress"; projectNumber = 7; projectOwner = "otro-dueno" },
            @{ createdAt = "2026-03-22T12:00:00Z"; status = "Diseño"; projectNumber = 7; projectOwner = "dueno-prueba" }
        )
        $nodo = Crear-ItemNodo -Numero 10 -Titulo "Issue 10" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-27T12:00:00Z" -Eventos $eventos
        $pag = Crear-PaginaGraphQL -Items @($nodo)
        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0, salida: $($res.Stdout) $($res.Stderr)"
        Afirmar (Test-Path $salidaPath) "Debe generarse el archivo de salida"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8

        # Cycle time debe ser 5,0 (desde 22/03 a 27/03) y NO 6,0 (que sería desde 21/03)
        Afirmar ($txt -match '\|\s*dueno-prueba/repo-prueba#10\s*\|\s*Issue 10\s*\|\s*7,0\s*\|\s*5,0\s*\|') "Cycle time debe usar solo el evento del Project 7 de dueno-prueba (5,0 días)"
    }
}

# test-plan: metricas-de-flujo/S02
Probar "S02 Historial del tablero para las métricas / Más de una página de tarjetas" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath -Owner "dueno-prueba" -Numero 7

        $ev1 = @(@{ createdAt = "2026-03-21T12:00:00Z"; status = "Construcción"; projectNumber = 7; projectOwner = "dueno-prueba" })
        $nodo1 = Crear-ItemNodo -Numero 1 -Titulo "Issue P1" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-25T12:00:00Z" -Eventos $ev1

        $ev2 = @(@{ createdAt = "2026-03-22T12:00:00Z"; status = "Construcción"; projectNumber = 7; projectOwner = "dueno-prueba" })
        $nodo2 = Crear-ItemNodo -Numero 2 -Titulo "Issue P2" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-26T12:00:00Z" -Eventos $ev2

        $pag1 = Crear-PaginaGraphQL -Items @($nodo1) -HasNextPage $true -EndCursor "c1"
        $pag2 = Crear-PaginaGraphQL -Items @($nodo2) -HasNextPage $false

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag1, $pag2)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        Afirmar ($txt -match 'dueno-prueba/repo-prueba#1\b') "Debe incluir el issue 1 de la página 1 en cerrados"
        Afirmar ($txt -match 'dueno-prueba/repo-prueba#2\b') "Debe incluir el issue 2 de la página 2 en cerrados"
    }
}

# test-plan: metricas-de-flujo/S03
Probar "S03 Historial del tablero para las métricas / Dato inválido: evento o fecha incompletos" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath -Owner "dueno-prueba" -Numero 7

        # 1. Tarjeta sin number
        $nodoSinNum = Crear-ItemNodo -Numero $null -Titulo "Sin número" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-25T12:00:00Z"
        # 2. Tarjeta con closedAt anterior a createdAt
        $nodoFechaInv = Crear-ItemNodo -Numero 99 -Titulo "Fecha inválida" -CreatedAt "2026-03-25T12:00:00Z" -ClosedAt "2026-03-20T12:00:00Z"
        # 3. Tarjeta válida con 1 evento válido y 1 evento sin status
        $eventos = @(
            @{ createdAt = "2026-03-21T12:00:00Z"; status = $null; projectNumber = 7; projectOwner = "dueno-prueba" },
            @{ createdAt = "2026-03-22T12:00:00Z"; status = "Construcción"; projectNumber = 7; projectOwner = "dueno-prueba" }
        )
        $nodoValido = Crear-ItemNodo -Numero 50 -Titulo "Válido" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-27T12:00:00Z" -Eventos $eventos

        $pag = Crear-PaginaGraphQL -Items @($nodoSinNum, $nodoFechaInv, $nodoValido)
        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        Afirmar ($res.Stdout -match 'Descartados por datos incompletos: 2 tarjetas y 1 eventos\.') "Debe informar descartados por consola: $($res.Stdout)"

        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        Afirmar ($txt -notmatch 'Sin número') "No debe incluir la tarjeta sin número"
        Afirmar ($txt -notmatch 'Fecha inválida') "No debe incluir la tarjeta con fecha invertida"
        Afirmar ($txt -match 'dueno-prueba/repo-prueba#50\b') "Debe incluir la tarjeta válida"
    }
}

# test-plan: metricas-de-flujo/S04
Probar "S04 Cálculo de las métricas de flujo / Lead time y cycle time" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        $ev = @(@{ createdAt = "2026-03-22T12:00:00Z"; status = "Diseño"; projectNumber = 7; projectOwner = "dueno-prueba" })
        $nodo = Crear-ItemNodo -Numero 100 -Titulo "Feature X" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-27T12:00:00Z" -Eventos $ev
        $pag = Crear-PaginaGraphQL -Items @($nodo)

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        Afirmar ($txt -match '\|\s*dueno-prueba/repo-prueba#100\s*\|\s*Feature X\s*\|\s*7,0\s*\|\s*5,0\s*\|') "Fila con 7,0 y 5,0 en Issues cerrados"
    }
}

# test-plan: metricas-de-flujo/S05
Probar "S05 Cálculo de las métricas de flujo / Issue cerrado sin pasar por el flujo" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        $ev = @(@{ createdAt = "2026-03-21T12:00:00Z"; status = "Backlog"; projectNumber = 7; projectOwner = "dueno-prueba" })
        $nodo = Crear-ItemNodo -Numero 101 -Titulo "Directo sin flujo" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-27T12:00:00Z" -Eventos $ev
        $pag = Crear-PaginaGraphQL -Items @($nodo)

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        Afirmar ($txt -match 'Sin cycle time \(no pasaron por Diseño ni Construcción\): 1\.') "Debe reportar 1 sin cycle time en Resumen"
        Afirmar ($txt -match '\|\s*dueno-prueba/repo-prueba#101\s*\|\s*Directo sin flujo\s*\|\s*7,0\s*\|\s*—\s*\|') "Cycle time debe ser — en la tabla de cerrados"
    }
}

# test-plan: metricas-de-flujo/S06
Probar "S06 Cálculo de las métricas de flujo / Throughput por semana" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        # Período de 2 semanas hasta 2026-03-30T12:00:00Z -> inicio: 2026-03-16T12:00:00Z
        # Semana 1 (16/03 a 23/03): 3 cerrados
        $n1 = Crear-ItemNodo -Numero 1 -CreatedAt "2026-03-10T12:00:00Z" -ClosedAt "2026-03-17T12:00:00Z"
        $n2 = Crear-ItemNodo -Numero 2 -CreatedAt "2026-03-10T12:00:00Z" -ClosedAt "2026-03-18T12:00:00Z"
        $n3 = Crear-ItemNodo -Numero 3 -CreatedAt "2026-03-10T12:00:00Z" -ClosedAt "2026-03-20T12:00:00Z"
        # Semana 2 (23/03 a 30/03): 0 cerrados

        $pag = Crear-PaginaGraphQL -Items @($n1, $n2, $n3)
        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Semanas 2 -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        # Tabla Throughput: Semana desde | Cerrados
        # Semana 1: 16/03 -> 3
        # Semana 2: 23/03 -> 0
        Afirmar ($txt -match '\|\s*16/03\s*\|\s*3\s*\|') "Semana 1 debe tener 3 cerrados"
        Afirmar ($txt -match '\|\s*23/03\s*\|\s*0\s*\|') "Semana 2 debe tener 0 cerrados"
        $idx1 = $txt.IndexOf("16/03")
        $idx2 = $txt.IndexOf("23/03")
        Afirmar ($idx1 -lt $idx2) "La semana más vieja debe aparecer primero"
    }
}

# test-plan: metricas-de-flujo/S07
Probar "S07 Cálculo de las métricas de flujo / Trabajo en curso" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        # Tarjeta abierta: closedAt null, último evento a Construcción el 26/03 12:00
        $ev = @(
            @{ createdAt = "2026-03-24T12:00:00Z"; status = "Diseño"; projectNumber = 7; projectOwner = "dueno-prueba" },
            @{ createdAt = "2026-03-26T12:00:00Z"; status = "Construcción"; projectNumber = 7; projectOwner = "dueno-prueba" }
        )
        $nodo = Crear-ItemNodo -Numero 200 -Titulo "En curso" -CreatedAt "2026-03-24T12:00:00Z" -ClosedAt $null -Eventos $ev
        $pag = Crear-PaginaGraphQL -Items @($nodo)

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8
        # Tabla Trabajo en curso: Issue | Título | Columna | Días en la columna
        Afirmar ($txt -match '\|\s*dueno-prueba/repo-prueba#200\s*\|\s*En curso\s*\|\s*Construcción\s*\|\s*4,0\s*\|') "Fila con Construcción y 4,0 días en trabajo en curso"
    }
}

# test-plan: metricas-de-flujo/S08
Probar "S08 Archivo de métricas en el vault / Archivo generado" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        $nodo = Crear-ItemNodo -Numero 300 -Titulo "Gen" -CreatedAt "2026-03-20T12:00:00Z" -ClosedAt "2026-03-25T12:00:00Z"
        $pag = Crear-PaginaGraphQL -Items @($nodo)

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        Afirmar (Test-Path $salidaPath) "Debe existir el archivo generado"

        # Comprobar BOM
        $bytes = [System.IO.File]::ReadAllBytes($salidaPath)
        Afirmar (-not ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF)) "No debe tener BOM UTF-8"

        $lineas = [System.IO.File]::ReadAllLines($salidaPath)
        Afirmar ($lineas[0] -eq '<!-- Generado con scripts/metricas.ps1 desde el tablero de GitHub. No editar a mano. -->') "Primera línea debe coincidir con el comentario de D5"

        $txt = [System.IO.File]::ReadAllText($salidaPath)
        $secciones = @('## Resumen', '## Throughput', '## Tiempo por columna', '## Trabajo en curso', '## Issues cerrados')
        $ultimoIdx = -1
        foreach ($sec in $secciones) {
            $idx = $txt.IndexOf($sec)
            Afirmar ($idx -gt $ultimoIdx) "Sección $sec debe estar en el orden especificado"
            $ultimoIdx = $idx
        }

        # Sin rutas de la carpeta temporal
        Afirmar ($txt -notmatch [regex]::Escape($dir)) "No debe contener la ruta de la carpeta temporal"
        Afirmar ($txt -notmatch '[CD]:\\') "No debe contener rutas de unidad absoluta"
    }
}

# test-plan: metricas-de-flujo/S09
Probar "S09 Archivo de métricas en el vault / Período sin issues cerrados" {
    Con-CarpetaTemporal { param($dir)
        $configPath = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configPath

        # Tarjeta cerrada antes del período (más de 4 semanas antes de 30/03: antes de 02/03)
        $nodoViejo = Crear-ItemNodo -Numero 400 -Titulo "Viejo" -CreatedAt "2026-01-01T12:00:00Z" -ClosedAt "2026-01-15T12:00:00Z"
        $pag = Crear-PaginaGraphQL -Items @($nodoViejo)

        $entradaPath = Join-Path $dir "entrada.json"
        Crear-EntradaJson -Ruta $entradaPath -Paginas @($pag)

        $salidaPath = Join-Path $dir "metricas.md"
        $res = Ejecutar-Metricas -Config $configPath -Entrada $entradaPath -Salida $salidaPath -Ahora "2026-03-30T12:00:00Z"

        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        $txt = Get-Content -Path $salidaPath -Raw -Encoding UTF8

        Afirmar ($txt -match '## Resumen[\s\S]*?Sin issues cerrados en el período\.') "Resumen debe decir 'Sin issues cerrados en el período.'"
        Afirmar ($txt -match '## Issues cerrados[\s\S]*?Sin issues cerrados en el período\.') "Issues cerrados debe decir 'Sin issues cerrados en el período.'"
        Afirmar ($txt -match '\|\s*\d{2}/\d{2}\s*\|\s*0\s*\|') "Las filas de throughput deben tener 0 cerrados"
    }
}

# test-plan: metricas-de-flujo/S10
Probar "S10 Archivo de métricas en el vault / Sin tablero o sin gh" {
    Con-CarpetaTemporal { param($dir)
        $salidaPath = Join-Path $dir "metricas.md"
        [System.IO.File]::WriteAllText($salidaPath, "contenido original previo", [System.Text.UTF8Encoding]::new($false))

        # Caso a: -Config inexistente
        $configInexistente = Join-Path $dir "no-existe-tablero.md"
        $resA = Ejecutar-Metricas -Config $configInexistente -Salida $salidaPath
        Afirmar ($resA.ExitCode -eq 0) "Sin tablero debe salir con código 0"
        $lineasA = @(($resA.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineasA.Count -eq 1) "Debe imprimir una sola línea de aviso"
        Afirmar ((Get-Content -Path $salidaPath -Raw) -eq "contenido original previo") "Salida no debe modificarse"

        # Caso b: sin -Entrada y PATH sin gh
        $configValido = Join-Path $dir "tablero.md"
        Crear-ConfigTableroPrueba -Ruta $configValido
        $dirVacio = Join-Path $dir "empty-path"
        New-Item -ItemType Directory -Path $dirVacio -Force | Out-Null

        $resB = Ejecutar-Metricas -Config $configValido -Salida $salidaPath -EnvExtra @{ PATH = $dirVacio }
        Afirmar ($resB.ExitCode -eq 0) "Sin gh debe salir con código 0"
        $lineasB = @(($resB.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineasB.Count -eq 1) "Debe imprimir una sola línea de aviso"
        Afirmar ($lineasB[0] -match 'Tablero no disponible:') "El mensaje debe usar el formato de Formatear-ErrorGh"
        Afirmar ((Get-Content -Path $salidaPath -Raw) -eq "contenido original previo") "Salida no debe modificarse"
    }
}

# test-plan: metricas-de-flujo/S11
Probar "S11 Métricas recalculadas en el cierre / Paso en el cierre" {
    $skillArchive = "$repoRoot/skills/openspec-archive-change/SKILL.md"
    Afirmar (Test-Path $skillArchive) "Debe existir $skillArchive"
    $txtArchive = Get-Content -Path $skillArchive -Raw -Encoding UTF8

    Afirmar ($txtArchive -match 'e2\.\s*\*\*Métricas de flujo:\*\*') "skill archive debe contener el paso e2. Métricas de flujo:"
    Afirmar ($txtArchive -match [regex]::Escape('metricas.ps1')) "skill archive debe llamar a metricas.ps1"
    Afirmar ($txtArchive -match [regex]::Escape('Un aviso del script no frena el cierre.')) "skill archive debe aclarar que un aviso no frena el cierre"
    $idxE2 = $txtArchive.IndexOf('e2.')
    $idxF = $txtArchive.IndexOf('f. **Sync del vault:**')
    if ($idxF -eq -1) { $idxF = $txtArchive.IndexOf('f. **Sincronizar el vault:**') }
    Afirmar ($idxE2 -lt $idxF) "e2 debe estar antes de f en la fase del vault de archive"

    $skillOdd = "$repoRoot/skills/odd-change/SKILL.md"
    Afirmar (Test-Path $skillOdd) "Debe existir $skillOdd"
    $txtOdd = Get-Content -Path $skillOdd -Raw -Encoding UTF8

    Afirmar ($txtOdd -match '5b\.\s*\*\*Métricas de flujo:\*\*') "skill odd debe contener el paso 5b. Métricas de flujo:"
    Afirmar ($txtOdd -match [regex]::Escape('metricas.ps1')) "skill odd debe llamar a metricas.ps1"
    Afirmar ($txtOdd -match [regex]::Escape('Un aviso del script no frena el cierre.')) "skill odd debe aclarar que un aviso no frena el cierre"
    $idx5b = $txtOdd.IndexOf('5b.')
    $idx6 = $txtOdd.IndexOf('6. **Commit y push del vault:**')
    Afirmar ($idx5b -lt $idx6) "5b debe estar antes de 6 en /odd:close"
}

# test-plan: metricas-de-flujo/S12
Probar "S12 Métricas recalculadas en el cierre / Paso en el cierre (comandos)" {
    $cmdArchive = "$repoRoot/.claude/commands/opsx/archive.md"
    Afirmar (Test-Path $cmdArchive) "Debe existir $cmdArchive"
    $txtArchive = Get-Content -Path $cmdArchive -Raw -Encoding UTF8
    Afirmar ($txtArchive -match [regex]::Escape('metricas.ps1')) "$cmdArchive debe contener metricas.ps1"

    $cmdClose = "$repoRoot/.claude/commands/odd/close.md"
    Afirmar (Test-Path $cmdClose) "Debe existir $cmdClose"
    $txtClose = Get-Content -Path $cmdClose -Raw -Encoding UTF8
    Afirmar ($txtClose -match [regex]::Escape('metricas.ps1')) "$cmdClose debe contener metricas.ps1"

    $resComprobar = & pwsh -NoProfile -File "$repoRoot/scripts/generar-plantillas.ps1" -Comprobar
    Afirmar ($LASTEXITCODE -eq 0) "generar-plantillas.ps1 -Comprobar debe salir con código 0"
}

# test-plan: metricas-de-flujo/S13
Probar "S13 Métricas en las reglas y la guía / Reglas y guía" {
    $claudeMd = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudeMd) "Debe existir $claudeMd"
    $txtClaude = Get-Content -Path $claudeMd -Raw -Encoding UTF8

    Afirmar ($txtClaude -match '### Métricas') "$claudeMd debe contener '### Métricas'"
    Afirmar ($txtClaude -match [regex]::Escape('metricas.ps1')) "$claudeMd debe mencionar metricas.ps1"
    Afirmar ($txtClaude -match 'lead time' -and $txtClaude -match 'cycle time' -and $txtClaude -match 'throughput' -and $txtClaude -match 'tiempo por columna' -and $txtClaude -match 'trabajo en curso') "$claudeMd debe nombrar las 5 métricas"
    Afirmar ($txtClaude -match [regex]::Escape('metricas.md')) "$claudeMd debe incluir metricas.md en la estructura del vault"

    $workflowMd = "$repoRoot/docs/workflow.md"
    Afirmar (Test-Path $workflowMd) "Debe existir $workflowMd"
    $txtWorkflow = Get-Content -Path $workflowMd -Raw -Encoding UTF8

    Afirmar ($txtWorkflow -match '### Métricas de flujo') "$workflowMd debe contener '### Métricas de flujo'"
    Afirmar ($txtWorkflow -match [regex]::Escape('metricas.ps1')) "$workflowMd debe mencionar metricas.ps1"
    Afirmar ($txtWorkflow -match 'lead time' -and $txtWorkflow -match 'cycle time' -and $txtWorkflow -match 'throughput' -and $txtWorkflow -match 'tiempo por columna' -and $txtWorkflow -match 'trabajo en curso') "$workflowMd debe nombrar las 5 métricas"
}
