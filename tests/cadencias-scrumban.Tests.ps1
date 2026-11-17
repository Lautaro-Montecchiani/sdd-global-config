# tests/cadencias-scrumban.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptRetro = "$repoRoot/scripts/retro.ps1"
$scriptTablero = "$repoRoot/scripts/tablero.ps1"
$scriptInstalar = "$repoRoot/scripts/instalar.ps1"
$scriptGenerarPlantillas = "$repoRoot/scripts/generar-plantillas.ps1"

function Ejecutar-Retro {
    param(
        [switch]$Aviso,
        [switch]$Periodo,
        [string]$Vault = $null,
        [string]$Config = $null,
        [string]$Ahora = $null,
        [hashtable]$EnvExtra = @{}
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptRetro`"")
    if ($Aviso) { $argumentos += '-Aviso' }
    if ($Periodo) { $argumentos += '-Periodo' }
    if ($Vault) { $argumentos += @('-Vault', "`"$Vault`"") }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
    if ($Ahora) { $argumentos += @('-Ahora', "`"$Ahora`"") }

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

function Ejecutar-Tablero {
    param(
        [string]$Columna = $null,
        [string]$Issue = $null,
        [switch]$Wip,
        [string]$Config = $null,
        [string]$Entrada = $null
    )

    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = 'pwsh'
    $argumentos = @('-NoProfile', '-File', "`"$scriptTablero`"")
    if ($Columna) { $argumentos += @('-Columna', "`"$Columna`"") }
    if ($Issue) { $argumentos += @('-Issue', "`"$Issue`"") }
    if ($Wip) { $argumentos += '-Wip' }
    if ($Config) { $argumentos += @('-Config', "`"$Config`"") }
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

function Crear-ConfigTablero {
    param(
        [string]$Ruta,
        [string]$Owner = "dueno-prueba",
        [int]$Numero = 7,
        $Cadencia = $null,
        $WipDiseno = 1
    )
    $lineas = @(
        "---",
        "owner: $Owner",
        "numero: $Numero"
    )
    if ($null -ne $WipDiseno) {
        $lineas += "wip-diseno: $WipDiseno"
    }
    if ($null -ne $Cadencia) {
        $lineas += "cadencia-retro: $Cadencia"
    }
    $lineas += "---"
    $lineas += "# Tablero de prueba"
    $contenido = $lineas -join "`n"
    [System.IO.File]::WriteAllText($Ruta, $contenido, [System.Text.UTF8Encoding]::new($false))
}

function Crear-EntradaTarjetasDummy {
    param([string]$Ruta)
    $obj = @{
        tarjetas = @{
            items = @()
        }
    }
    $json = $obj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($Ruta, $json, [System.Text.UTF8Encoding]::new($false))
}

# test-plan: cadencias-scrumban/S02
Probar "S02 Configuración del tablero en el vault / Dato inválido: cadencia mal escrita" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        $entrada = Join-Path $dir "entrada.json"
        Crear-EntradaTarjetasDummy -Ruta $entrada

        $valoresInvalidos = @('0', '-3', 'abc')
        foreach ($val in $valoresInvalidos) {
            Crear-ConfigTablero -Ruta $tablero -Cadencia $val
            $res = Ejecutar-Tablero -Wip -Columna diseno -Config $tablero -Entrada $entrada
            Afirmar ($res.ExitCode -eq 0) "Con cadencia-retro: $val debe terminar con 0"
            Afirmar ($res.Stdout -match 'tablero\.md inválido: cadencia-retro') "Con cadencia-retro: $val debe imprimir 'tablero.md inválido: cadencia-retro'"
        }
    }
}

# test-plan: cadencias-scrumban/S03
Probar "S03 Aviso de retro vencida / Retro vencida" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null
        $retroFile = Join-Path $retrosDir "2026-11-09.md"
        [System.IO.File]::WriteAllText($retroFile, "# Retro anterior", [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res.ExitCode -eq 1) "Retro vencida debe salir con código 1"
        $lineas = @(($res.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineas.Count -eq 1) "Debe imprimir una sola línea de aviso"
        Afirmar ($lineas[0] -match [regex]::Escape('Retro vencida: pasaron 8 días desde la última (2026-11-09): corré /retro')) "El mensaje debe indicar 8 días y fecha 2026-11-09"
    }
}

# test-plan: cadencias-scrumban/S04
Probar "S04 Aviso de retro vencida / Retro al día" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null

        # Caso 1: retro hace 3 días (al día)
        $retro1 = Join-Path $retrosDir "2026-11-14.md"
        [System.IO.File]::WriteAllText($retro1, "# Retro", [System.Text.UTF8Encoding]::new($false))

        $res1 = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res1.ExitCode -eq 0) "Retro al día debe salir con código 0"
        Afirmar ([string]::IsNullOrWhiteSpace($res1.Stdout)) "Retro al día no debe tener salida"

        # Caso 2: retro hace 7 días justos (vencida)
        Remove-Item $retro1 -Force
        $retro2 = Join-Path $retrosDir "2026-11-10.md"
        [System.IO.File]::WriteAllText($retro2, "# Retro", [System.Text.UTF8Encoding]::new($false))

        $res2 = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res2.ExitCode -eq 1) "Retro con 7 días justos debe salir con código 1"
        $lineas2 = @(($res2.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineas2.Count -eq 1) "Debe imprimir una sola línea"
        Afirmar ($lineas2[0] -match [regex]::Escape('Retro vencida: pasaron 7 días desde la última (2026-11-10): corré /retro')) "Debe indicar 7 días y fecha 2026-11-10"
    }
}

# test-plan: cadencias-scrumban/S05
Probar "S05 Aviso de retro vencida / Sin ninguna retro" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7

        # Caso 1: sin carpeta retros/
        $res1 = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res1.ExitCode -eq 1) "Sin retros debe salir con código 1"
        $lineas1 = @(($res1.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineas1.Count -eq 1) "Debe ser una sola línea"
        Afirmar ($lineas1[0] -eq 'Todavía no hay retros en el vault: corré /retro') "Mensaje sin carpeta retros"

        # Caso 2: con retros/ vacía
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null
        $res2 = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res2.ExitCode -eq 1) "Con retros vacía debe salir con código 1"
        $lineas2 = @(($res2.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineas2[0] -eq 'Todavía no hay retros en el vault: corré /retro') "Mensaje con carpeta retros vacía"
    }
}

# test-plan: cadencias-scrumban/S06
Probar "S06 Aviso de retro vencida / Sin cadencia o sin tablero" {
    Con-CarpetaTemporal { param($dir)
        # Caso 1: tablero.md sin cadencia-retro
        $tab1 = Join-Path $dir "tablero1.md"
        Crear-ConfigTablero -Ruta $tab1 # sin cadencia
        $res1 = Ejecutar-Retro -Aviso -Vault $dir -Config $tab1 -Ahora "2026-11-17"
        Afirmar ($res1.ExitCode -eq 0) "Sin cadencia-retro debe salir con código 0"
        Afirmar ([string]::IsNullOrWhiteSpace($res1.Stdout)) "Sin cadencia-retro no debe haber salida"

        # Caso 2: vault sin tablero.md
        $dirSinTablero = Join-Path $dir "sin-tablero"
        New-Item -ItemType Directory -Path $dirSinTablero -Force | Out-Null
        $res2 = Ejecutar-Retro -Aviso -Vault $dirSinTablero -Ahora "2026-11-17"
        Afirmar ($res2.ExitCode -eq 0) "Sin tablero.md en vault debe salir con código 0"
        Afirmar ([string]::IsNullOrWhiteSpace($res2.Stdout)) "Sin tablero.md no debe haber salida"

        # Caso 3: sin -Vault con OBSIDIAN_VAULT vacía
        $res3 = Ejecutar-Retro -Aviso -Ahora "2026-11-17" -EnvExtra @{ OBSIDIAN_VAULT = "" }
        Afirmar ($res3.ExitCode -eq 0) "Sin vault ni variable debe salir con código 0"
        Afirmar ([string]::IsNullOrWhiteSpace($res3.Stdout)) "Sin vault ni variable no debe haber salida"
    }
}

# test-plan: cadencias-scrumban/S07
Probar "S07 Aviso de retro vencida / Dato inválido: archivos que no son retros" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null

        [System.IO.File]::WriteAllText((Join-Path $retrosDir "notas.md"), "x", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText((Join-Path $retrosDir "2026-13-40.md"), "x", [System.Text.UTF8Encoding]::new($false))

        # Caso 2: solo archivos inválidos
        $resInval = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($resInval.ExitCode -eq 1) "Solo con archivos inválidos debe salir con código 1"
        $lineasInval = @(($resInval.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineasInval[0] -eq 'Todavía no hay retros en el vault: corré /retro') "Debe tratar los archivos no fechados como sin retros"

        # Caso 1: con archivo válido al día
        [System.IO.File]::WriteAllText((Join-Path $retrosDir "2026-11-14.md"), "x", [System.Text.UTF8Encoding]::new($false))
        $resVal = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($resVal.ExitCode -eq 0) "Con archivo válido al día debe salir con código 0"
        Afirmar ([string]::IsNullOrWhiteSpace($resVal.Stdout)) "Con archivo válido al día no debe haber salida"
    }
}

# test-plan: cadencias-scrumban/S08
Probar "S08 Aviso de retro vencida / Dato inválido: cadencia mal escrita en el aviso" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia "abc"

        $res = Ejecutar-Retro -Aviso -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res.ExitCode -eq 0) "Cadencia inválida en aviso debe salir con código 0"
        $lineas = @(($res.Stdout.Trim() -split "`r?`n") | Where-Object { $_ })
        Afirmar ($lineas.Count -eq 1) "Debe haber una sola línea"
        Afirmar ($lineas[0] -eq 'tablero.md inválido: cadencia-retro') "Debe mostrar el mensaje de tablero.md inválido: cadencia-retro"
    }
}

# test-plan: cadencias-scrumban/S09
Probar "S09 Período de la retro / Notas del período" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7

        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $retrosDir "2026-11-10.md"), "retro", [System.Text.UTF8Encoding]::new($false))

        $alfaArchive = Join-Path $dir "projects/alfa/archive"
        New-Item -ItemType Directory -Path $alfaArchive -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $alfaArchive "2026-11-08-viejo.md"), "viejo", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText((Join-Path $alfaArchive "2026-11-12-nuevo.md"), "nuevo", [System.Text.UTF8Encoding]::new($false))

        $betaArchive = Join-Path $dir "projects/beta/archive"
        New-Item -ItemType Directory -Path $betaArchive -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $betaArchive "2026-11-15-odd-texto.md"), "odd", [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-Retro -Periodo -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res.ExitCode -eq 0) "Periodo debe salir con código 0"
        $txt = $res.Stdout

        Afirmar ($txt -match '(?m)^Desde:\s*2026-11-10\s*$') "Debe contener Desde: 2026-11-10"
        Afirmar ($txt -match '(?m)^Hasta:\s*2026-11-17\s*$') "Debe contener Hasta: 2026-11-17"
        Afirmar ($txt -match '(?m)^Semanas:\s*1\s*$') "Debe contener Semanas: 1"
        Afirmar ($txt -match '(?m)^Retro anterior:\s*retros/2026-11-10\.md\s*$') "Debe contener Retro anterior: retros/2026-11-10.md"
        Afirmar ($txt -match '(?m)^Terminado:\s*$') "Debe contener encabezado Terminado:"
        Afirmar ($txt -match '(?m)^-\s*alfa:\s*nuevo\s*\(2026-11-12,\s*SDD\)\s*$') "Debe listar alfa nuevo como SDD"
        Afirmar ($txt -match '(?m)^-\s*beta:\s*texto\s*\(2026-11-15,\s*ODD\)\s*$') "Debe listar beta texto como ODD"
        Afirmar ($txt -notmatch 'viejo') "No debe listar viejo (anterior al período)"
    }
}

# test-plan: cadencias-scrumban/S10
Probar "S10 Período de la retro / Primera retro" {
    Con-CarpetaTemporal { param($dir)
        # Caso 1: sin retros, cadencia 7
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $res1 = Ejecutar-Retro -Periodo -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res1.ExitCode -eq 0) "Primera retro debe salir con código 0"
        Afirmar ($res1.Stdout -match '(?m)^Desde:\s*2026-11-10\s*$') "Primera retro con cadencia 7 debe calcular Desde: 2026-11-10"
        Afirmar ($res1.Stdout -match '(?m)^Retro anterior:\s*ninguna\s*$') "Primera retro debe decir Retro anterior: ninguna"

        # Caso 2: sin tablero.md (cadencia por defecto 7)
        $dirSinTab = Join-Path $dir "sin-tab"
        New-Item -ItemType Directory -Path $dirSinTab -Force | Out-Null
        $res2 = Ejecutar-Retro -Periodo -Vault $dirSinTab -Ahora "2026-11-17"
        Afirmar ($res2.ExitCode -eq 0) "Sin tablero debe salir con código 0"
        Afirmar ($res2.Stdout -match '(?m)^Desde:\s*2026-11-10\s*$') "Sin tablero debe usar cadencia por defecto 7 (Desde: 2026-11-10)"
    }
}

# test-plan: cadencias-scrumban/S11
Probar "S11 Período de la retro / Período sin nada archivado" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $retrosDir "2026-11-10.md"), "retro", [System.Text.UTF8Encoding]::new($false))

        $res1 = Ejecutar-Retro -Periodo -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res1.ExitCode -eq 0) "Debe salir con código 0"
        Afirmar ($res1.Stdout -match 'Sin changes ni ODD archivados en el período\.') "Debe indicar sin changes ni ODD archivados"
        Afirmar ($res1.Stdout -notmatch [regex]::Escape($dir)) "Ninguna línea debe contener la ruta de la carpeta temporal"

        # Caso sin vault
        $res2 = Ejecutar-Retro -Periodo -Ahora "2026-11-17" -EnvExtra @{ OBSIDIAN_VAULT = "" }
        Afirmar ($res2.ExitCode -eq 0) "Sin vault debe salir con código 0"
        Afirmar ($res2.Stdout -match 'Sin vault: OBSIDIAN_VAULT no definida') "Debe avisar que OBSIDIAN_VAULT no está definida"
    }
}

# test-plan: cadencias-scrumban/S12
Probar "S12 Período de la retro / Dato inválido: nota de archive sin fecha" {
    Con-CarpetaTemporal { param($dir)
        $tablero = Join-Path $dir "tablero.md"
        Crear-ConfigTablero -Ruta $tablero -Cadencia 7
        $retrosDir = Join-Path $dir "retros"
        New-Item -ItemType Directory -Path $retrosDir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $retrosDir "2026-11-10.md"), "retro", [System.Text.UTF8Encoding]::new($false))

        $archiveDir = Join-Path $dir "projects/alfa/archive"
        New-Item -ItemType Directory -Path $archiveDir -Force | Out-Null
        [System.IO.File]::WriteAllText((Join-Path $archiveDir "notas-sueltas.md"), "x", [System.Text.UTF8Encoding]::new($false))
        [System.IO.File]::WriteAllText((Join-Path $archiveDir "2026-02-30-x.md"), "x", [System.Text.UTF8Encoding]::new($false))

        $res = Ejecutar-Retro -Periodo -Vault $dir -Config $tablero -Ahora "2026-11-17"
        Afirmar ($res.ExitCode -eq 0) "Debe salir con código 0"
        Afirmar ($res.Stdout -notmatch 'notas-sueltas') "No debe listar notas-sueltas"
        Afirmar ($res.Stdout -notmatch '2026-02-30') "No debe listar fecha imposible 2026-02-30"
    }
}

# test-plan: cadencias-scrumban/S13
Probar "S13 Skill de retro con review / Fases de la skill" {
    $skillRetro = "$repoRoot/skills/retro/SKILL.md"
    Afirmar (Test-Path $skillRetro) "Debe existir $skillRetro"
    $txt = Get-Content -Path $skillRetro -Raw -Encoding UTF8

    $fases = @('Preparar', 'Review', 'Start / Stop / Continue', 'Analizar', 'Decidir acciones', 'Cerrar')
    $lastIdx = -1
    foreach ($fase in $fases) {
        $idx = $txt.IndexOf($fase)
        Afirmar ($idx -gt $lastIdx) "La fase $fase debe estar en el orden esperado"
        $lastIdx = $idx
    }

    Afirmar ($txt -match 'directiva primaria') "Debe contener 'directiva primaria'"
    Afirmar ($txt -match '15 minutos') "Debe contener '15 minutos'"
    Afirmar ($txt -match [regex]::Escape('retro.ps1" -Periodo')) 'Debe contener retro.ps1 con -Periodo'
    Afirmar ($txt -match [regex]::Escape('metricas.ps1')) "Debe contener 'metricas.ps1'"
}

# test-plan: cadencias-scrumban/S14
Probar "S14 Skill de retro con review / Skill instalada" {
    Con-CarpetaTemporal { param($dir)
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = 'pwsh'
        $psi.Arguments = "-NoProfile -File `"$scriptInstalar`" -Destino `"$dir`" -SinVault -Simular"
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $proc.WaitForExit()

        Afirmar ($stdout -match [regex]::Escape('.claude/skills/retro/SKILL.md')) "instalar.ps1 -Simular debe listar .claude/skills/retro/SKILL.md"
    }
}

# test-plan: cadencias-scrumban/S15
Probar "S15 Skill de retro con review / Dato inválido: acción anterior sin issue" {
    $skillRetro = "$repoRoot/skills/retro/SKILL.md"
    Afirmar (Test-Path $skillRetro) "Debe existir $skillRetro"
    $txt = Get-Content -Path $skillRetro -Raw -Encoding UTF8

    Afirmar ($txt -match 'no encontrado') "Debe contener 'no encontrado'"
    Afirmar ($txt -match 'sin issue') "Debe contener 'sin issue'"
    Afirmar ($txt -match 'no evalúa personas') "Debe indicar 'no evalúa personas'"
    Afirmar ($txt -match 'nombres de personas') "Debe restringir nombres de personas"
    Afirmar ($txt -match 'rutas absolutas') "Debe restringir rutas absolutas"
}

# test-plan: cadencias-scrumban/S16
Probar "S16 Acciones de la retro como issues / Acción creada como issue y Sin gh" {
    $skillRetro = "$repoRoot/skills/retro/SKILL.md"
    Afirmar (Test-Path $skillRetro) "Debe existir $skillRetro"
    $txt = Get-Content -Path $skillRetro -Raw -Encoding UTF8

    Afirmar ($txt -match [regex]::Escape('gh issue create')) "Debe contener 'gh issue create'"
    Afirmar ($txt -match 'prioridad:') "Debe contener 'prioridad:'"
    Afirmar ($txt -match 'tipo:') "Debe contener 'tipo:'"
    Afirmar ($txt -match [regex]::Escape('Origen: retro')) "Debe contener 'Origen: retro'"
    Afirmar ($txt -match [regex]::Escape('-Columna backlog')) "Debe contener '-Columna backlog'"
    Afirmar ($txt -match [regex]::Escape('Máximo 3 acciones')) "Debe contener 'Máximo 3 acciones'"
    Afirmar ($txt -match [regex]::Escape('issue: pendiente')) "Debe contener 'issue: pendiente'"
    Afirmar ($txt -match [regex]::Escape('status:approved')) "Debe aclarar que no agrega status:approved"
}

# test-plan: cadencias-scrumban/S17
Probar "S17 Nota de la retro en el vault / Formato de la nota y Sin vault" {
    $skillRetro = "$repoRoot/skills/retro/SKILL.md"
    Afirmar (Test-Path $skillRetro) "Debe existir $skillRetro"
    $txt = Get-Content -Path $skillRetro -Raw -Encoding UTF8

    Afirmar ($txt -match [regex]::Escape('retros/AAAA-MM-DD.md')) "Debe contener 'retros/AAAA-MM-DD.md'"
    Afirmar ($txt -match [regex]::Escape('tipo: retro')) "Debe contener 'tipo: retro'"
    $secciones = @('## Acciones anteriores', '## Review', '## Start / Stop / Continue', '## Análisis', '## Acciones', '## Cierre')
    foreach ($sec in $secciones) {
        Afirmar ($txt -match [regex]::Escape($sec)) "Debe contener la sección $sec"
    }
    Afirmar ($txt -match [regex]::Escape('## Retro de las HH:MM')) "Debe contener '## Retro de las HH:MM'"
    Afirmar ($txt -match [regex]::Escape('chore: retro')) "Debe contener 'chore: retro'"
    Afirmar ($txt -match [regex]::Escape('Sin vault no hay retro')) "Debe contener 'Sin vault no hay retro'"
}

# test-plan: cadencias-scrumban/S18
Probar "S18 Cadencias en las reglas y la guía / Reglas y guía" {
    $claudeMd = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudeMd) "Debe existir $claudeMd"
    $txtClaude = Get-Content -Path $claudeMd -Raw -Encoding UTF8

    Afirmar ($txtClaude -match "retro\.ps1 -Aviso") "CLAUDE.md debe contener retro.ps1 -Aviso"
    Afirmar ($txtClaude -match "### Cadencias") "CLAUDE.md debe contener ### Cadencias"
    $patronRetros = "retros" + [char]92
    Afirmar ($txtClaude.Contains($patronRetros)) "CLAUDE.md debe contener retros con barra en estructura del vault"
    $filaRetro = ($txtClaude -match "(?m)\|\s*/retro\s*\|")
    Afirmar $filaRetro "CLAUDE.md debe contener la fila de retro en Cuando actuar"

    $workflowMd = "$repoRoot/docs/workflow.md"
    Afirmar (Test-Path $workflowMd) "Debe existir $workflowMd"
    $txtWorkflow = Get-Content -Path $workflowMd -Raw -Encoding UTF8

    Afirmar ($txtWorkflow -match [regex]::Escape('cadencia-retro')) "workflow.md debe contener 'cadencia-retro'"
    Afirmar ($txtWorkflow -match [regex]::Escape('/retro')) "workflow.md debe contener '/retro'"
    $patronUnidad = "[A-Za-z]:" + [char]92
    Afirmar ($txtWorkflow -notmatch $patronUnidad) "workflow.md no debe contener rutas con letra de unidad"
    Afirmar ($txtWorkflow -notmatch '/Users/') "workflow.md no debe contener /Users/"

    $resGen = & pwsh -NoProfile -File $scriptGenerarPlantillas -Comprobar
    Afirmar ($LASTEXITCODE -eq 0) "generar-plantillas.ps1 -Comprobar debe terminar con 0"
}
