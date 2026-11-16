# tests/tablero-scrumban.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptTablero = "$repoRoot/scripts/tablero.ps1"

function Ejecutar-Tablero {
    param(
        [string]$Columna = $null,
        [string]$Issue = $null,
        [switch]$Wip,
        [switch]$Comprobar,
        [switch]$Simular,
        [string]$Config = $null,
        [string]$Entrada = $null,
        [hashtable]$EnvExtra = @{}
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptTablero`"")
    if ($Columna) { $argumentos += @('-Columna', "`"$Columna`"") }
    if ($Issue) { $argumentos += @('-Issue', "`"$Issue`"") }
    if ($Wip) { $argumentos += '-Wip' }
    if ($Comprobar) { $argumentos += '-Comprobar' }
    if ($Simular) { $argumentos += '-Simular' }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
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

# test-plan: tablero-scrumban/S01
Probar "S01 Configuración del tablero en el vault / Configuración válida" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
wip-diseno: 1
wip-construccion: 2
wip-revision: 2
---
Texto libre debajo
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.tarjetas.items = @(
            @{ id = 'ITEM_1'; status = 'Diseño'; content = @{ number = 10; title = 'Tarea diseno'; url = 'https://github.com/org/repo/issues/10' } },
            @{ id = 'ITEM_2'; status = 'Construcción'; content = @{ number = 11; title = 'Tarea const 1'; url = 'https://github.com/org/repo/issues/11' } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $resDiseno = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($resDiseno.ExitCode -eq 2) "Diseño debe estar al límite (código 2, límite 1)"
        Afirmar ($resDiseno.Stdout -match 'Diseño: 1 de 1') "Debe mostrar 'Diseño: 1 de 1'"

        $resConst = Ejecutar-Tablero -Columna construccion -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($resConst.ExitCode -eq 0) "Construcción debe tener lugar (código 0, límite 2)"
        Afirmar ($resConst.Stdout -match 'Construcción: 1 de 2') "Debe mostrar 'Construcción: 1 de 2'"
    }
}

# test-plan: tablero-scrumban/S02
Probar "S02 Configuración del tablero en el vault / Sin tablero configurado" {
    Con-CarpetaTemporal {
        param($tmp)
        $inexistente = Join-Path $tmp "no-existe.md"
        $resInexistente = Ejecutar-Tablero -Columna diseno -Wip -Config $inexistente
        Afirmar ($resInexistente.ExitCode -eq 0) "Sin tablero debe devolver código 0"
        Afirmar ($resInexistente.Stdout -match '^Tablero no configurado') "Debe empezar con 'Tablero no configurado'"

        $resSinVault = Ejecutar-Tablero -Columna diseno -Wip -EnvExtra @{ OBSIDIAN_VAULT = "" }
        Afirmar ($resSinVault.ExitCode -eq 0) "Sin OBSIDIAN_VAULT debe devolver código 0"
        Afirmar ($resSinVault.Stdout -match '^Tablero no configurado') "Debe empezar con 'Tablero no configurado'"
    }
}

# test-plan: tablero-scrumban/S03
Probar "S03 Configuración del tablero en el vault / Dato inválido: número o límite mal escrito" {
    Con-CarpetaTemporal {
        param($tmp)
        $casos = @(
            @{ Clave = 'numero'; Contenido = "owner: usr`nnumero: tres" },
            @{ Clave = 'wip-construccion'; Contenido = "owner: usr`nnumero: 1`nwip-construccion: 0" },
            @{ Clave = 'wip-construccion'; Contenido = "owner: usr`nnumero: 1`nwip-construccion: -1" },
            @{ Clave = 'wip-revision'; Contenido = "owner: usr`nnumero: 1`nwip-revision: dos" }
        )

        foreach ($c in $casos) {
            $tablero = Join-Path $tmp "tablero-$($c.Clave)-$([System.Guid]::NewGuid().ToString('N')).md"
            "---`n$($c.Contenido)`n---" | Set-Content -Path $tablero -Encoding UTF8

            $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero
            Afirmar ($res.ExitCode -eq 0) "Dato inválido debe devolver código 0"
            Afirmar ($res.Stdout -match "tablero\.md inválido: $($c.Clave)") "Debe indicar 'tablero.md inválido: $($c.Clave)' pero dio: $($res.Stdout)"
        }
    }
}

# test-plan: tablero-scrumban/S04
Probar "S04 Mover la tarjeta de un issue / Issue nuevo en el tablero" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $issueUrl = "https://github.com/org/repo/issues/10"
        $res = Ejecutar-Tablero -Columna backlog -Issue $issueUrl -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "Mover debe devolver código 0"
        Afirmar ($res.Stdout -match "item-add.*$([regex]::Escape($issueUrl))") "Debe imprimir item-add con la URL"
        Afirmar ($res.Stdout -match "item-edit.*OPT_BACKLOG") "Debe imprimir item-edit con el id de la opción Backlog"
        Afirmar ($res.Stdout -match '#10 → Backlog') "Debe mostrar '#10 → Backlog'"
    }
}

# test-plan: tablero-scrumban/S05
Probar "S05 Mover la tarjeta de un issue / Issue que cambia de columna" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $issueUrl = "https://github.com/org/repo/issues/15"
        $datos.tarjetas.items = @(
            @{ id = 'ITEM_15'; status = 'Diseño'; content = @{ number = 15; title = 'Cambio columna'; url = $issueUrl } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        # Mover a revision
        $res = Ejecutar-Tablero -Columna revision -Issue $issueUrl -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "Mover debe devolver código 0"
        Afirmar ($res.Stdout -match "item-edit.*ITEM_15.*OPT_REVISION") "Debe imprimir item-edit con ITEM_15 y OPT_REVISION"
        Afirmar ($res.Stdout -notmatch "item-add") "No debe duplicar ni llamar item-add si ya existe"
        Afirmar ($res.Stdout -match '#15 → Revisión') "Debe mostrar '#15 → Revisión'"

        # Mover a REVISION (insensible a mayúsculas)
        $resUpper = Ejecutar-Tablero -Columna REVISION -Issue $issueUrl -Config $tablero -Entrada $jsonPath
        Afirmar ($resUpper.ExitCode -eq 0) "Mover con REVISION en mayúsculas debe devolver código 0"
        Afirmar ($resUpper.Stdout -match "item-edit.*ITEM_15.*OPT_REVISION") "Debe resolver a OPT_REVISION"
        Afirmar ($resUpper.Stdout -match '#15 → Revisión') "Debe mostrar '#15 → Revisión'"
    }
}

# test-plan: tablero-scrumban/S06
Probar "S06 Mover la tarjeta de un issue / Columna desconocida" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $res = Ejecutar-Tablero -Columna testing -Issue "https://github.com/org/repo/issues/1" -Config $tablero
        Afirmar ($res.ExitCode -eq 1) "Columna desconocida debe salir con código 1"
        Afirmar ($res.Stdout -match 'Columna desconocida: testing\. Válidas: backlog, listo, diseno, construccion, revision, hecho') "Debe mostrar el mensaje con las 6 columnas válidas"
    }
}

# test-plan: tablero-scrumban/S07
Probar "S07 Mover la tarjeta de un issue / Sin permiso o sin gh" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        # Ejecución sin gh en PATH y sin -Entrada
        $emptyPathDir = Join-Path $tmp "empty_path"
        New-Item -ItemType Directory -Path $emptyPathDir -Force | Out-Null
        $res = Ejecutar-Tablero -Columna backlog -Issue "https://github.com/org/repo/issues/1" -Config $tablero -EnvExtra @{ PATH = $emptyPathDir }
        Afirmar ($res.ExitCode -eq 0) "Sin gh debe salir con código 0"
        Afirmar ($res.Stdout -match '^Tablero no disponible:') "Debe indicar 'Tablero no disponible:'"
        Afirmar (-not $res.Stdout.Contains($tmp)) "No debe contener rutas absolutas del tablero temporal"

        # Comprobación de la función que arma el mensaje con scope
        Afirmar (Test-Path $scriptTablero) "Debe existir $scriptTablero"
        . "$scriptTablero"
        Afirmar ($null -ne (Get-Command Formatear-ErrorGh -ErrorAction SilentlyContinue)) "Debe existir la función Formatear-ErrorGh"
        $msgScope = Formatear-ErrorGh "HTTP 403: Missing required scope: project"
        Afirmar ($msgScope -match [regex]::Escape('corré gh auth refresh -s project')) "Debe agregar la sugerencia de gh auth refresh"
    }
}

# test-plan: tablero-scrumban/S08
Probar "S08 Mover la tarjeta de un issue / Dato inválido: Project sin la opción de la columna" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        # Caso 1: campos sin la opción Diseño
        $datosSinDiseno = Obtener-JsonBase
        $statusField = $datosSinDiseno.campos.fields[0]
        $statusField.options = @($statusField.options | Where-Object { $_.name -ne 'Diseño' })
        $jsonSinDiseno = Join-Path $tmp "sin-diseno.json"
        $datosSinDiseno | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonSinDiseno -Encoding UTF8

        $res1 = Ejecutar-Tablero -Columna diseno -Issue "https://github.com/org/repo/issues/1" -Config $tablero -Entrada $jsonSinDiseno
        Afirmar ($res1.ExitCode -eq 0) "Opción faltante debe devolver código 0"
        Afirmar ($res1.Stdout -match 'el tablero no tiene la columna Diseño') "Debe indicar que falta la columna Diseño"
        Afirmar ($res1.Stdout -notmatch 'item-edit') "No debe ejecutar item-edit"

        # Caso 2: campos sin campo Status
        $datosSinStatus = Obtener-JsonBase
        $datosSinStatus.campos.fields = @()
        $jsonSinStatus = Join-Path $tmp "sin-status.json"
        $datosSinStatus | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonSinStatus -Encoding UTF8

        $res2 = Ejecutar-Tablero -Columna diseno -Issue "https://github.com/org/repo/issues/1" -Config $tablero -Entrada $jsonSinStatus
        Afirmar ($res2.ExitCode -eq 0) "Campo Status faltante debe devolver código 0"
        Afirmar ($res2.Stdout -match 'el tablero no tiene la columna Diseño') "Debe indicar que falta la columna Diseño"
        Afirmar ($res2.Stdout -notmatch 'item-edit') "No debe ejecutar item-edit"
    }
}

# test-plan: tablero-scrumban/S09
Probar "S09 Control de WIP de una columna / Columna llena" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
wip-diseno: 1
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.tarjetas.items = @(
            @{ id = 'ITEM_12'; status = 'Diseño'; content = @{ number = 12; title = 'Tarjeta doce'; url = 'https://github.com/org/repo/issues/12' } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 2) "Columna llena debe salir con código 2"
        Afirmar ($res.Stdout -match 'Diseño: 1 de 1') "Debe mostrar 'Diseño: 1 de 1'"
        Afirmar ($res.Stdout -match '\s+#12 Tarjeta doce') "Debe listar la tarjeta con número y título"
    }
}

# test-plan: tablero-scrumban/S10
Probar "S10 Control de WIP de una columna / Columna con lugar" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
wip-construccion: 2
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.tarjetas.items = @(
            @{ id = 'ITEM_1'; status = 'Construcción'; content = @{ number = 5; title = 'Tarjeta cinco'; url = 'https://github.com/org/repo/issues/5' } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Columna construccion -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "Columna con lugar debe salir con código 0"
        Afirmar ($res.Stdout -match 'Construcción: 1 de 2') "Debe mostrar 'Construcción: 1 de 2'"
    }
}

# test-plan: tablero-scrumban/S11
Probar "S11 Control de WIP de una columna / Columna sin límite" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.tarjetas.items = @(
            @{ id = 'I1'; status = 'Backlog'; content = @{ number = 1; title = 'T1'; url = 'u1' } },
            @{ id = 'I2'; status = 'Backlog'; content = @{ number = 2; title = 'T2'; url = 'u2' } },
            @{ id = 'I3'; status = 'Backlog'; content = @{ number = 3; title = 'T3'; url = 'u3' } },
            @{ id = 'I4'; status = 'Backlog'; content = @{ number = 4; title = 'T4'; url = 'u4' } },
            @{ id = 'I5'; status = 'Backlog'; content = @{ number = 5; title = 'T5'; url = 'u5' } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Columna backlog -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "Columna sin límite debe salir con código 0"
        Afirmar ($res.Stdout -match 'Backlog: 5 \(sin límite\)') "Debe mostrar 'Backlog: 5 (sin límite)'"
    }
}

# test-plan: tablero-scrumban/S12
Probar "S12 Control de WIP de una columna / Dato inválido: tarjetas sin Status o sin título" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
wip-diseno: 1
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.tarjetas.items = @(
            # Tarjeta sin status (no debe contarse)
            @{ id = 'I1'; content = @{ number = 99; title = 'Sin status' } },
            # Tarjeta en diseño sin título (debe mostrarse solo como #15)
            @{ id = 'I2'; status = 'Diseño'; content = @{ number = 15; url = 'u15' } }
        )
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Columna diseno -Wip -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 2) "Debe contar 1 tarjeta en diseño y dar código 2"
        Afirmar ($res.Stdout -match 'Diseño: 1 de 1') "Solo debe contar la tarjeta que tiene status Diseño"
        Afirmar ($res.Stdout -match '(?m)^\s+#15\s*$') "La tarjeta sin título debe mostrarse solo con su número (#15)"
    }
}

# test-plan: tablero-scrumban/S18
Probar "S18 Aviso de permiso en cada máquina / Máquina sin el permiso" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.estadoGh = @"
github.com
  ✓ Logged in to github.com account testuser (keyring)
  - Active account: true
  - Git operations protocol: https
  - Token: token_dummy
  - Token scopes: 'gist', 'repo'
"@
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Comprobar -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 1) "Máquina sin permiso project debe devolver código 1"
        $esperado = 'Falta el permiso project en gh de esta máquina: corré ! gh auth refresh -h github.com -s project'
        Afirmar ($res.Stdout -match [regex]::Escape($esperado)) "Debe mostrar el mensaje exacto de D7b"
    }
}

# test-plan: tablero-scrumban/S19
Probar "S19 Aviso de permiso en cada máquina / Máquina con el permiso o sin tablero" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        # Caso con permiso project
        $datos = Obtener-JsonBase
        $datos.estadoGh = @"
github.com
  ✓ Logged in to github.com account testuser (keyring)
  - Active account: true
  - Token scopes: 'gist', 'project', 'repo'
"@
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $resConPermiso = Ejecutar-Tablero -Comprobar -Config $tablero -Entrada $jsonPath
        Afirmar ($resConPermiso.ExitCode -eq 0) "Máquina con permiso project debe salir con 0"
        Afirmar ([string]::IsNullOrWhiteSpace($resConPermiso.Stdout)) "Máquina con permiso no debe tener salida"

        # Caso sin tablero configurado
        $inexistente = Join-Path $tmp "no-existe.md"
        $resSinTablero = Ejecutar-Tablero -Comprobar -Config $inexistente -Entrada $jsonPath
        Afirmar ($resSinTablero.ExitCode -eq 0) "Sin tablero debe salir con 0"
        Afirmar ([string]::IsNullOrWhiteSpace($resSinTablero.Stdout)) "Sin tablero no debe tener salida"
    }
}

# test-plan: tablero-scrumban/S20
Probar "S20 Aviso de permiso en cada máquina / Dato inválido: permisos ilegibles" {
    Con-CarpetaTemporal {
        param($tmp)
        $tablero = Join-Path $tmp "tablero.md"
        @'
---
owner: usuario-test
numero: 42
---
'@ | Set-Content -Path $tablero -Encoding UTF8

        $datos = Obtener-JsonBase
        $datos.estadoGh = @"
github.com
  ✓ Logged in to github.com account testuser
  (sin línea de scopes)
"@
        $jsonPath = Join-Path $tmp "entrada.json"
        $datos | ConvertTo-Json -Depth 10 | Set-Content -Path $jsonPath -Encoding UTF8

        $res = Ejecutar-Tablero -Comprobar -Config $tablero -Entrada $jsonPath
        Afirmar ($res.ExitCode -eq 0) "Permisos ilegibles debe salir con 0"
        Afirmar ($res.Stdout -match 'No se pudo leer el permiso de gh') "Debe mostrar 'No se pudo leer el permiso de gh'"
    }
}

# test-plan: tablero-scrumban/S13
Probar "S13 Movimientos del flujo / Pasos que mueven la tarjeta" {
    $skills = @(
        @{ Archivo = "$repoRoot/skills/issue-creation/SKILL.md"; Columnas = @('backlog') },
        @{ Archivo = "$repoRoot/skills/openspec-propose/SKILL.md"; Columnas = @('diseno', 'construccion') },
        @{ Archivo = "$repoRoot/skills/odd-change/SKILL.md"; Columnas = @('construccion', 'hecho') },
        @{ Archivo = "$repoRoot/skills/branch-pr/SKILL.md"; Columnas = @('revision') },
        @{ Archivo = "$repoRoot/skills/openspec-archive-change/SKILL.md"; Columnas = @('hecho') }
    )

    $textoComun = 'Si no hay issue (`Issue: pendiente` o un ODD sin issue) o `SDD_CONFIG_REPO` no está definida, saltear este paso y decirlo en el resumen. Un aviso del script no frena el flujo.'

    foreach ($s in $skills) {
        Afirmar (Test-Path $s.Archivo) "Debe existir $($s.Archivo)"
        $txt = Get-Content -Path $s.Archivo -Raw -Encoding UTF8
        Afirmar ($txt -match [regex]::Escape($textoComun)) "$($s.Archivo) debe contener el texto común de D4"
        Afirmar ($txt -match 'tablero\.ps1') "$($s.Archivo) debe contener llamada a tablero.ps1"
        foreach ($col in $s.Columnas) {
            Afirmar ($txt -match "-Columna $col\b") "$($s.Archivo) debe contener -Columna $col"
        }
    }
}

# test-plan: tablero-scrumban/S14
Probar "S14 Movimientos del flujo / Comandos regenerados" {
    $comandos = @(
        "$repoRoot/.claude/commands/opsx/propose.md",
        "$repoRoot/.claude/commands/opsx/archive.md",
        "$repoRoot/.claude/commands/odd.md",
        "$repoRoot/.claude/commands/odd/start.md",
        "$repoRoot/.claude/commands/odd/close.md"
    )

    foreach ($c in $comandos) {
        Afirmar (Test-Path $c) "Debe existir $c"
        $txt = Get-Content -Path $c -Raw -Encoding UTF8
        Afirmar ($txt -match 'tablero\.ps1') "$c debe contener tablero.ps1"
    }

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $psi.Arguments = "-NoProfile -File `"$repoRoot/scripts/generar-plantillas.ps1`" -Comprobar"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    Afirmar ($proc.ExitCode -eq 0) "generar-plantillas.ps1 -Comprobar debe salir con 0. Error: $stderr $stdout"
}

# test-plan: tablero-scrumban/S15
Probar "S15 Control de WIP antes de empezar trabajo / WIP lleno en el propose" {
    $proposeSkill = "$repoRoot/skills/openspec-propose/SKILL.md"
    $oddSkill = "$repoRoot/skills/odd-change/SKILL.md"

    foreach ($f in @($proposeSkill, $oddSkill)) {
        Afirmar (Test-Path $f) "Debe existir $f"
        $txt = Get-Content -Path $f -Raw -Encoding UTF8
        Afirmar ($txt -match 'tablero\.ps1\s+-Wip') "$f debe contener tablero.ps1 -Wip"
        Afirmar ($txt -match [regex]::Escape('Seguir igual')) "$f debe mencionar opción 'Seguir igual'"
        Afirmar ($txt -match [regex]::Escape('Frenar')) "$f debe mencionar opción 'Frenar'"
        Afirmar ($txt -match 'no crea archivos ni ramas') "$f debe aclarar que Frenar no crea archivos ni ramas"
    }
}

# test-plan: tablero-scrumban/S16
Probar "S16 Scrumban en las reglas globales / Sección Scrumban" {
    $claudeMd = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudeMd) "Debe existir $claudeMd"
    $txt = Get-Content -Path $claudeMd -Raw -Encoding UTF8

    Afirmar ($txt -match '## Scrumban') "$claudeMd debe contener '## Scrumban'"
    $columnas = @('Backlog', 'Listo', 'Diseño', 'Construcción', 'Revisión', 'Hecho')
    foreach ($col in $columnas) {
        Afirmar ($txt -match "\b$col\b") "$claudeMd debe mencionar la columna $col"
    }
    Afirmar ($txt -match 'Definition of Ready') "$claudeMd debe contener Definition of Ready"
    Afirmar ($txt -match 'Definition of Done') "$claudeMd debe contener Definition of Done"
    Afirmar ($txt -match 'tablero\.md.*configuración del tablero Scrumban') "$claudeMd debe incluir tablero.md en la estructura del vault"
}

# test-plan: tablero-scrumban/S17
Probar "S17 Guía de configuración del tablero / Guía completa" {
    $workflowMd = "$repoRoot/docs/workflow.md"
    Afirmar (Test-Path $workflowMd) "Debe existir $workflowMd"
    $txt = Get-Content -Path $workflowMd -Raw -Encoding UTF8

    Afirmar ($txt -match '## Tablero Scrumban') "$workflowMd debe contener '## Tablero Scrumban'"
    $columnas = @('Backlog', 'Listo', 'Diseño', 'Construcción', 'Revisión', 'Hecho')
    foreach ($col in $columnas) {
        Afirmar ($txt -match "\b$col\b") "$workflowMd debe mencionar la columna $col"
    }
    Afirmar ($txt -match [regex]::Escape('gh auth refresh -s project')) "$workflowMd debe mencionar gh auth refresh -s project"
    Afirmar ($txt -match [regex]::Escape('Instalar este sitio como aplicación')) "$workflowMd debe mencionar 'Instalar este sitio como aplicación'"
    Afirmar ($txt -match '\bowner\b' -and $txt -match '\bnumero\b') "$workflowMd debe mencionar claves owner y numero"

    # Verificar que no contenga rutas de unidad
    Afirmar ($txt -notmatch '[CD]:\\') "$workflowMd no debe contener rutas de unidad"
}

# test-plan: tablero-scrumban/S21
Probar "S21 Aviso de permiso en cada máquina / Control al iniciar sesión" {
    $claudeMd = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudeMd) "Debe existir $claudeMd"
    $txt = Get-Content -Path $claudeMd -Raw -Encoding UTF8

    Afirmar ($txt -match '## Al iniciar cada sesión') "$claudeMd debe tener '## Al iniciar cada sesión'"
    Afirmar ($txt -match [regex]::Escape('tablero.ps1 -Comprobar')) "$claudeMd debe contener 'tablero.ps1 -Comprobar'"
    Afirmar ($txt -match [regex]::Escape('!')) "$claudeMd debe indicar que el usuario da el permiso con !"
}
