# tests/tablero-segun-dueno.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptTablero = "$repoRoot/scripts/tablero.ps1"
$scriptMetricas = "$repoRoot/scripts/metricas.ps1"

function Ejecutar-Tablero {
    param(
        [string]$Columna = $null,
        [string]$Issue = $null,
        [switch]$Wip,
        [switch]$Simular,
        [string]$Config = $null,
        [string]$Entrada = $null,
        [hashtable]$EnvExtra = @{},
        [string]$CarpetaTrabajo = $null
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptTablero`"")
    if ($Columna) { $argumentos += @('-Columna', "`"$Columna`"") }
    if ($Issue) { $argumentos += @('-Issue', "`"$Issue`"") }
    if ($Wip) { $argumentos += '-Wip' }
    if ($Simular) { $argumentos += '-Simular' }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
    if ($Entrada) { $argumentos += @('-Entrada', "`"$Entrada`"") }

    $psi.Arguments = $argumentos -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    if ($CarpetaTrabajo) {
        $psi.WorkingDirectory = $CarpetaTrabajo
    }

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

function Obtener-JsonBase {
    return @{
        proyecto = @{
            id = 'PVT_test_123'
        }
        campos = @{
            fields = @(
                @{
                    id = 'PVTF_status_field'
                    name = 'Status'
                    options = @(
                        @{ id = 'OPT_BACKLOG'; name = 'Backlog' },
                        @{ id = 'OPT_LISTO'; name = 'Listo' },
                        @{ id = 'OPT_DISENO'; name = 'Diseño' },
                        @{ id = 'OPT_CONSTRUCCION'; name = 'Construcción' },
                        @{ id = 'OPT_REVISION'; name = 'Revisión' },
                        @{ id = 'OPT_HECHO'; name = 'Hecho' }
                    )
                }
            )
        }
        tarjetas = @{
            items = @()
        }
    }
}

# test-plan: tablero-segun-dueno/S01
Probar "S01 Configuración del tablero en el vault / Configuración con un tablero por dueño" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $jsonPath = Join-Path $tmp "entrada.json"
        Obtener-JsonBase | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $resOrgB = Ejecutar-Tablero -Columna backlog -Issue "https://github.com/Org-B/repo/issues/7" -Simular -Config $tablero -Entrada $jsonPath
        Afirmar ($resOrgB.ExitCode -eq 0) "S01 Org-B debe devolver 0"
        Afirmar ($resOrgB.Stdout -match 'gh project item-add 2 --owner cuenta-c') "Debe usar Project 2 de cuenta-c, salida: $($resOrgB.Stdout)"

        $resOtro = Ejecutar-Tablero -Columna backlog -Issue "https://github.com/otra-org/repo/issues/8" -Simular -Config $tablero -Entrada $jsonPath
        Afirmar ($resOtro.ExitCode -eq 0) "S01 otra-org debe devolver 0"
        Afirmar ($resOtro.Stdout -match 'gh project item-add 4 --owner cuenta-a') "Debe usar Project 4 de cuenta-a, salida: $($resOtro.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S02
Probar "S02 Configuración del tablero en el vault / Formato anterior" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
wip-diseno: 1
cadencia-retro: 7
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $jsonPath = Join-Path $tmp "entrada.json"
        Obtener-JsonBase | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna backlog -Issue "https://github.com/org-b/repo/issues/7" -Simular -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S02 debe devolver 0"
        Afirmar ($res.Stdout -match 'gh project item-add 4 --owner cuenta-a') "Sin claves dueno- debe usar Project 4 de cuenta-a, salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S03
Probar "S03 Configuración del tablero en el vault / Dato inválido: tablero de un dueño mal escrito" {
    Con-CarpetaTemporal {
        param($tmp)
        $casos = @(
            @{ Clave = 'dueno-org-b'; Contenido = "owner: cuenta-a`nnumero: 4`ndueno-org-b: cuenta-c" },
            @{ Clave = 'dueno-org-b'; Contenido = "owner: cuenta-a`nnumero: 4`ndueno-org-b: cuenta-c/0" },
            @{ Clave = 'dueno-org-b'; Contenido = "owner: cuenta-a`nnumero: 4`ndueno-org-b: cuenta-c/x" },
            @{ Clave = 'dueno-org-b'; Contenido = "owner: cuenta-a`nnumero: 4`ndueno-org-b: /2" },
            @{ Clave = 'dueno-';      Contenido = "owner: cuenta-a`nnumero: 4`ndueno-: cuenta-c/2" }
        )

        foreach ($c in $casos) {
            $tablero = Join-Path $tmp "tablero-$([System.Guid]::NewGuid().ToString('N')).md"
            "---`n$($c.Contenido)`n---" | Set-Content -Path $tablero -Encoding utf8NoBOM

            $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero
            Afirmar ($res.ExitCode -eq 0) "Dato inválido debe devolver 0"
            Afirmar ($res.Stdout -match "tablero\.md inválido: $([regex]::Escape($c.Clave))(\r?\n|$)") "Debe indicar 'tablero.md inválido: $($c.Clave)' pero dio: $($res.Stdout)"
        }
    }
}

# test-plan: tablero-segun-dueno/S04
Probar "S04 Mover la tarjeta de un issue / Issue de un dueño con tablero propio" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $jsonPath = Join-Path $tmp "entrada.json"
        Obtener-JsonBase | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna diseno -Issue "https://github.com/Org-B/repo/issues/7" -Simular -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S04 debe devolver 0"
        Afirmar ($res.Stdout -match 'gh project item-add 2 --owner cuenta-c --url https://github\.com/Org-B/repo/issues/7') "Debe usar Project 2 de cuenta-c, salida: $($res.Stdout)"
        Afirmar ($res.Stdout -notmatch 'item-add 4 --owner cuenta-a') "No debe usar Project 4 de cuenta-a"
        Afirmar ($res.Stdout -match 'OPT_DISENO') "Debe usar opción OPT_DISENO"
    }
}

# test-plan: tablero-segun-dueno/S05
Probar "S05 Mover la tarjeta de un issue / Issue por número de un dueño con tablero propio" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $jsonPath = Join-Path $tmp "entrada.json"
        Obtener-JsonBase | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $repoDir = Join-Path $tmp "repo-org-b"
        New-Item -ItemType Directory -Path $repoDir -Force | Out-Null
        git -C $repoDir init --quiet
        git -C $repoDir remote add origin "git@github.com:org-b/repo.git"

        $res = Ejecutar-Tablero -Columna diseno -Issue "7" -Simular -Config $tablero -Entrada $jsonPath -CarpetaTrabajo $repoDir
        Afirmar ($res.ExitCode -eq 0) "S05 debe devolver 0"
        Afirmar ($res.Stdout -match 'gh project item-add 2 --owner cuenta-c --url https://github\.com/org-b/repo/issues/7') "Debe usar Project 2 de cuenta-c con la URL armada, salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S06
Probar "S06 Mover la tarjeta de un issue / Issue de un dueño sin tablero propio" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $jsonPath = Join-Path $tmp "entrada.json"
        Obtener-JsonBase | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna diseno -Issue "https://github.com/otra-org/repo/issues/9" -Simular -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S06 debe devolver 0"
        Afirmar ($res.Stdout -match 'gh project item-add 4 --owner cuenta-a --url https://github\.com/otra-org/repo/issues/9') "Debe usar Project 4 de cuenta-a, salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S07
Probar "S07 Control de WIP de una columna / Columna llena sumando dos tableros" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
wip-diseno: 1
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{
                    tarjetas = @{ items = @() }
                }
                'cuenta-c/2' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Diseño'; content = @{ number = 7; title = 'Tarea en org-b'; url = 'https://github.com/org-b/repo/issues/7' } }
                        )
                    }
                }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 2) "S07 debe devolver código 2, dio $($res.ExitCode)"
        Afirmar ($res.Stdout -match 'Diseño: 1 de 1') "Debe mostrar 'Diseño: 1 de 1', salida: $($res.Stdout)"
        Afirmar ($res.Stdout -match '#7 Tarea en org-b \(cuenta-c/2\)') "Debe mostrar tarjeta con (cuenta-c/2), salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S08
Probar "S08 Control de WIP de una columna / Suma con lugar" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
wip-construccion: 3
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Construcción'; content = @{ number = 1; title = 'Uno'; url = 'https://github.com/cuenta-a/r/issues/1' } }
                        )
                    }
                }
                'cuenta-c/2' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Construcción'; content = @{ number = 2; title = 'Dos'; url = 'https://github.com/org-b/r/issues/2' } }
                        )
                    }
                }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna construccion -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S08 debe devolver código 0, dio $($res.ExitCode)"
        Afirmar ($res.Stdout -match 'Construcción: 2 de 3') "Debe mostrar 'Construcción: 2 de 3', salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S09
Probar "S09 Control de WIP de una columna / Dato inválido: el mismo issue en dos tableros" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
wip-diseno: 2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $urlRepetida = 'https://github.com/org-b/repo/issues/7'
        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Diseño'; content = @{ number = 7; title = 'Repetida'; url = $urlRepetida } }
                        )
                    }
                }
                'cuenta-c/2' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Diseño'; content = @{ number = 7; title = 'Repetida'; url = $urlRepetida } }
                        )
                    }
                }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S09 debe devolver código 0, dio $($res.ExitCode)"
        Afirmar ($res.Stdout -match 'Diseño: 1 de 2') "Debe contar 1 sola vez ('Diseño: 1 de 2'), salida: $($res.Stdout)"
    }
}

# test-plan: tablero-segun-dueno/S10
Probar "S10 Control de WIP de una columna / Dato inválido: un tablero que no se puede leer" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
wip-construccion: 2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{
                    tarjetas = @{
                        items = @(
                            @{ status = 'Construcción'; content = @{ number = 10; title = 'Activa'; url = 'https://github.com/cuenta-a/r/issues/10' } }
                        )
                    }
                }
                'cuenta-c/2' = @{
                    error = 'C:\Users\prueba\gh.exe: failed to authenticate'
                }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding utf8NoBOM

        $res = Ejecutar-Tablero -Columna construccion -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "S10 debe devolver código 0, dio $($res.ExitCode)"
        Afirmar ($res.Stdout -match 'cuenta-c/2') "Debe nombrar cuenta-c/2 en el aviso, salida: $($res.Stdout)"
        Afirmar ($res.Stdout -notmatch ':\\') "No debe contener rutas absolutas (:\), salida: $($res.Stdout)"
        Afirmar ($res.Stdout -match 'Construcción: 1 de 2') "Debe mostrar 'Construcción: 1 de 2', salida: $($res.Stdout)"
    }
}

function Ejecutar-Metricas {
    param(
        [string]$Ahora = $null,
        [string]$Config = $null,
        [string]$Salida = $null,
        [string]$Entrada = $null
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptMetricas`"")
    if ($Ahora) { $argumentos += @('-Ahora', "`"$Ahora`"") }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
    if ($Salida) { $argumentos += @('-Salida', "`"$Salida`"") }
    if ($Entrada) { $argumentos += @('-Entrada', "`"$Entrada`"") }

    $psi.Arguments = $argumentos -join ' '
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false

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

function Crear-PaginaMetricas {
    param([array]$Items = @())
    return @{
        data = @{
            repositoryOwner = @{
                projectV2 = @{
                    items = @{
                        pageInfo = @{
                            hasNextPage = $false
                            endCursor   = $null
                        }
                        nodes = $Items
                    }
                }
            }
        }
    }
}

function Crear-ItemMetricas {
    param(
        [int]$Numero,
        [string]$Titulo,
        [string]$Repo,
        [string]$CreatedAt,
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

    return @{
        content = @{
            number     = $Numero
            title      = $Titulo
            createdAt  = $CreatedAt
            closedAt   = $ClosedAt
            repository = @{ nameWithOwner = $Repo }
            timelineItems = @{ nodes = $eventNodes }
        }
    }
}

# test-plan: tablero-segun-dueno/S13
Probar "S13 Historial del tablero para las métricas / Métricas de dos tableros" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $item1 = Crear-ItemMetricas -Numero 1 -Titulo "Issue uno" -Repo "cuenta-a/repo-a" -CreatedAt "2026-11-01T10:00:00Z" -ClosedAt "2026-11-03T10:00:00Z" -Eventos @(
            @{ createdAt = "2026-11-02T10:00:00Z"; status = "Construcción"; projectNumber = 4; projectOwner = "cuenta-a" }
        )
        $item2 = Crear-ItemMetricas -Numero 2 -Titulo "Issue dos" -Repo "org-b/repo-b" -CreatedAt "2026-11-04T10:00:00Z" -ClosedAt "2026-11-06T10:00:00Z" -Eventos @(
            @{ createdAt = "2026-11-05T10:00:00Z"; status = "Diseño"; projectNumber = 2; projectOwner = "cuenta-c" }
        )

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{ paginas = @( (Crear-PaginaMetricas -Items @($item1)) ) }
                'cuenta-c/2' = @{ paginas = @( (Crear-PaginaMetricas -Items @($item2)) ) }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 20 | Set-Content -Path $jsonPath -Encoding utf8NoBOM
        $salidaPath = Join-Path $tmp "metricas.md"

        $res = Ejecutar-Metricas -Ahora "2026-11-10T12:00:00Z" -Config $tablero -Entrada $jsonPath -Salida $salidaPath
        Afirmar ($res.ExitCode -eq 0) "S13 debe devolver 0"
        Afirmar (Test-Path $salidaPath) "Debe escribir metricas.md"
        $md = Get-Content -LiteralPath $salidaPath -Raw -Encoding UTF8
        Afirmar ($md -match 'Tableros: cuenta-a/4, cuenta-c/2\.') "Encabezado debe listar ambos tableros"
        Afirmar ($md -match 'Cerrados en el período: 2\.') "Debe contar 2 cerrados"
        Afirmar ($md -match 'cuenta-a/repo-a#1') "Debe listar cuenta-a/repo-a#1"
        Afirmar ($md -match 'org-b/repo-b#2') "Debe listar org-b/repo-b#2"
    }
}

# test-plan: tablero-segun-dueno/S14
Probar "S14 Historial del tablero para las métricas / Dato inválido: el mismo issue en dos tableros" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $itemEnA = Crear-ItemMetricas -Numero 7 -Titulo "Duplicado" -Repo "org-b/repo-b" -CreatedAt "2026-11-01T10:00:00Z" -ClosedAt "2026-11-05T10:00:00Z" -Eventos @(
            @{ createdAt = "2026-11-02T10:00:00Z"; status = "Backlog"; projectNumber = 4; projectOwner = "cuenta-a" }
        )
        $itemEnC = Crear-ItemMetricas -Numero 7 -Titulo "Duplicado" -Repo "org-b/repo-b" -CreatedAt "2026-11-01T10:00:00Z" -ClosedAt "2026-11-05T10:00:00Z" -Eventos @(
            @{ createdAt = "2026-11-03T10:00:00Z"; status = "Diseño"; projectNumber = 2; projectOwner = "cuenta-c" }
        )

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{ paginas = @( (Crear-PaginaMetricas -Items @($itemEnA)) ) }
                'cuenta-c/2' = @{ paginas = @( (Crear-PaginaMetricas -Items @($itemEnC)) ) }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 20 | Set-Content -Path $jsonPath -Encoding utf8NoBOM
        $salidaPath = Join-Path $tmp "metricas.md"

        $res = Ejecutar-Metricas -Ahora "2026-11-10T12:00:00Z" -Config $tablero -Entrada $jsonPath -Salida $salidaPath
        Afirmar ($res.ExitCode -eq 0) "S14 debe devolver 0"
        Afirmar (Test-Path $salidaPath) "Debe escribir metricas.md"
        $md = Get-Content -LiteralPath $salidaPath -Raw -Encoding UTF8
        Afirmar ($md -match 'Cerrados en el período: 1\.') "Debe contar 1 cerrado, no 2"
        Afirmar ($md -match '\| Backlog \| 1,0 \| 1 \|') "Debe tener evento Backlog de cuenta-a/4"
        Afirmar ($md -match '\| Diseño \| 2,0 \| 1 \|') "Debe tener evento Diseño de cuenta-c/2"
    }
}

# test-plan: tablero-segun-dueno/S15
Probar "S15 Archivo de métricas en el vault / Dato inválido: un tablero que no se puede leer" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: cuenta-a
numero: 4
dueno-org-b: cuenta-c/2
---
'@ | Set-Content -Path $tablero -Encoding utf8NoBOM

        $item1 = Crear-ItemMetricas -Numero 1 -Titulo "Issue uno" -Repo "cuenta-a/repo-a" -CreatedAt "2026-11-01T10:00:00Z" -ClosedAt "2026-11-03T10:00:00Z" -Eventos @(
            @{ createdAt = "2026-11-02T10:00:00Z"; status = "Construcción"; projectNumber = 4; projectOwner = "cuenta-a" }
        )

        $datos = @{
            tableros = @{
                'cuenta-a/4' = @{ paginas = @( (Crear-PaginaMetricas -Items @($item1)) ) }
                'cuenta-c/2' = @{ error = 'C:\Users\prueba\gh.exe: forbidden' }
            }
        }
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 20 | Set-Content -Path $jsonPath -Encoding utf8NoBOM
        $salidaPath = Join-Path $tmp "metricas.md"

        $res = Ejecutar-Metricas -Ahora "2026-11-10T12:00:00Z" -Config $tablero -Entrada $jsonPath -Salida $salidaPath
        Afirmar ($res.ExitCode -eq 0) "S15 debe devolver 0"
        Afirmar ($res.Stdout -match 'cuenta-c/2') "La consola debe nombrar cuenta-c/2"
        Afirmar ($res.Stdout -notmatch ':\\') "La consola no debe tener rutas absolutas (:\)"
        Afirmar (Test-Path $salidaPath) "Debe escribir metricas.md con el otro tablero"
        $md = Get-Content -LiteralPath $salidaPath -Raw -Encoding UTF8
        Afirmar ($md -match 'Sin leer: cuenta-c/2\.') "El encabezado debe incluir 'Sin leer: cuenta-c/2.'"
        Afirmar ($md -match 'Cerrados en el período: 1\.') "Debe calcular con los datos de cuenta-a/4"
    }
}

# test-plan: tablero-segun-dueno/S11
Probar "S11 Scrumban en las reglas globales / Varios tableros en las reglas" {
    $claudePath = Join-Path $repoRoot ".claude/CLAUDE.md"
    $txt = Get-Content -LiteralPath $claudePath -Raw -Encoding UTF8

    Afirmar ($txt -match '(?s)### Tablero(.*?)### WIP') "Debe existir ### Tablero antes de ### WIP"
    $secTablero = $matches[1]
    Afirmar ($secTablero -match 'dueno-') "### Tablero debe mencionar claves dueno-"
    Afirmar ($secTablero -match 'por defecto') "### Tablero debe mencionar el tablero por defecto"

    Afirmar ($txt -match '(?s)### WIP(.*?)### Métricas') "Debe existir ### WIP antes de ### Métricas"
    $secWip = $matches[1]
    Afirmar ($secWip -match 'suma entre todos los tableros') "### WIP debe decir que se suma entre todos los tableros"
}

# test-plan: tablero-segun-dueno/S12
Probar "S12 Guía de configuración del tablero / Guía con un tablero por dueño" {
    $wfPath = Join-Path $repoRoot "docs/workflow.md"
    $txt = Get-Content -LiteralPath $wfPath -Raw -Encoding UTF8

    Afirmar ($txt -match '(?s)## Tablero Scrumban(.*)') "Debe existir sección ## Tablero Scrumban"
    $secTablero = $matches[1]
    Afirmar ($secTablero -match 'dueno-') "La guía del tablero debe explicar las claves dueno-"
    Afirmar ($secTablero -match 'WIP y las métricas suman todos los tableros') "La guía debe decir que el WIP y las métricas suman todos los tableros"
    Afirmar ($secTablero -notmatch '(?i)Toyota-Yacopini|lmontecchiani|Lautaro-Montecchiani') "La guía no debe contener cuentas reales del usuario"
}

if ($script:HayFallas) { exit 1 }
