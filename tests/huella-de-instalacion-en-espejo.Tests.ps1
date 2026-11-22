# tests/huella-de-instalacion-en-espejo.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptInstalar = "$repoRoot/scripts/instalar.ps1"
$scriptComun = "$repoRoot/scripts/comun.ps1"

function Ejecutar-Pwsh {
    param(
        [string]$ScriptPath,
        [string]$Argumentos = "",
        [string]$WorkingDir = ""
    )
    $psi = [System.Diagnostics.ProcessStartInfo]::new()
    $psi.FileName = "pwsh"
    $psi.Arguments = "-NoProfile -File `"$ScriptPath`" $Argumentos"
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    if ($WorkingDir) {
        $psi.WorkingDirectory = $WorkingDir
    }
    $proc = [System.Diagnostics.Process]::Start($psi)
    $stdout = $proc.StandardOutput.ReadToEnd()
    $stderr = $proc.StandardError.ReadToEnd()
    $proc.WaitForExit()
    return @{
        ExitCode = $proc.ExitCode
        Output = $stdout + $stderr
        Stdout = $stdout
        Stderr = $stderr
    }
}

function Inicializar-VaultGit {
    param([string]$VaultPath, [string]$RemoteBarePath = "")
    New-Item -ItemType Directory -Path $VaultPath -Force | Out-Null
    git -C $VaultPath init 2>$null | Out-Null
    git -C $VaultPath config user.name "Tester"
    git -C $VaultPath config user.email "tester@example.com"
    git -C $VaultPath commit --allow-empty -m "initial commit" 2>$null | Out-Null
    if ($RemoteBarePath) {
        git init --bare $RemoteBarePath 2>$null | Out-Null
        git -C $VaultPath remote add origin $RemoteBarePath 2>$null | Out-Null
        git -C $VaultPath push -u origin master 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            git -C $VaultPath push -u origin main 2>$null | Out-Null
        }
    }
}

# test-plan: huella-de-instalacion-en-espejo/S01
Probar "S01 huella de lo instalado en el encabezado del espejo" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        $espejoPath = "$vault/_global/reglas-globales.md"
        Afirmar (Test-Path $espejoPath) "No existe el espejo en el vault"

        $txtEspejo = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejo -match "(?m)^commit:\s*[a-fA-F0-9]+\r?\ninstalacion:\s*[0-9a-f]{12}\r?\nupdated:") "El espejo debe tener 'instalacion: <12 hex>' entre commit y updated: $txtEspejo"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S02
Probar "S02 misma huella con otro destino" {
    Con-CarpetaTemporal { param($dir)
        $destGemini = "$dir/dest-gemini"
        $vaultGemini = "$dir/vault-gemini"
        New-Item -ItemType Directory -Path "$destGemini/.gemini/antigravity-cli" -Force | Out-Null
        Inicializar-VaultGit -VaultPath $vaultGemini

        $res1 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$destGemini`" -Vault `"$vaultGemini`""
        Afirmar ($res1.ExitCode -eq 0) "instalar.ps1 con destino gemini falló: $($res1.Output)"

        $destVacio = "$dir/dest-vacio"
        $vaultVacio = "$dir/vault-vacio"
        New-Item -ItemType Directory -Path $destVacio -Force | Out-Null
        Inicializar-VaultGit -VaultPath $vaultVacio

        $res2 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$destVacio`" -Vault `"$vaultVacio`""
        Afirmar ($res2.ExitCode -eq 0) "instalar.ps1 con destino vacío falló: $($res2.Output)"

        $txt1 = Get-Content -Path "$vaultGemini/_global/reglas-globales.md" -Raw -Encoding UTF8
        $txt2 = Get-Content -Path "$vaultVacio/_global/reglas-globales.md" -Raw -Encoding UTF8

        $m1 = [regex]::Match($txt1, "(?m)^instalacion:\s*([0-9a-f]{12})\s*$")
        $m2 = [regex]::Match($txt2, "(?m)^instalacion:\s*([0-9a-f]{12})\s*$")

        Afirmar ($m1.Success) "El espejo de dest-gemini debe tener línea de instalación"
        Afirmar ($m2.Success) "El espejo de dest-vacio debe tener línea de instalación"
        Afirmar ($m1.Groups[1].Value -eq $m2.Groups[1].Value) "Ambos espejos deben tener la misma huella: $($m1.Groups[1].Value) vs $($m2.Groups[1].Value)"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S03
Probar "S03 skill nueva cambia la huella y actualiza espejo atrasado" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $headCommit = (git -C $repoRoot rev-parse --short HEAD).Trim()
        $cuerpoRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8)
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null

        $espejoViejo = "---`ntype: reglas-globales`nsource: sdd-global-config/.claude/CLAUDE.md`ncommit: $headCommit`ninstalacion: 000000000000`nupdated: 2026-11-21`n---`n`n> [!info] Espejo de solo lectura. Fuente: ``.claude/CLAUDE.md`` del repo ``sdd-global-config``. Lo escribe solo ``scripts/instalar.ps1``. No editar acá.`n`n" + $cuerpoRepo
        $espejoPath = "$globalDir/reglas-globales.md"
        Set-Content -Path $espejoPath -Value $espejoViejo -Encoding UTF8
        git -C $vault add _global/reglas-globales.md 2>$null | Out-Null
        git -C $vault commit -m "espejo con huella vieja" 2>$null | Out-Null
        $commitCountAntes = [int]((git -C $vault rev-list --count HEAD).Trim())

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió tener éxito: $($res.Output)"
        Afirmar ($res.Output -match "atrasado") "Debe figurar como atrasado: $($res.Output)"

        $txtEspejoDespues = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        $mHuella = [regex]::Match($txtEspejoDespues, "(?m)^instalacion:\s*([0-9a-f]{12})\s*$")
        Afirmar ($mHuella.Success) "El espejo debe tener la nueva huella de 12 caracteres"
        Afirmar ($mHuella.Groups[1].Value -ne "000000000000") "La huella debe haberse actualizado y no ser 000000000000"

        $commitCountDespues = [int]((git -C $vault rev-list --count HEAD).Trim())
        Afirmar ($commitCountDespues -eq ($commitCountAntes + 1)) "El vault debe tener exactamente un commit nuevo"
        $logVault = git -C $vault log -1 --format="%s"
        Afirmar ($logVault -match "chore: sdd-global-config — sync reglas") "El commit debe ser sync de reglas: $logVault"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S04
Probar "S04 espejo anterior sin huella figura atrasado y se actualiza" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $headCommit = (git -C $repoRoot rev-parse --short HEAD).Trim()
        $cuerpoRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8)
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null

        $espejoSinHuella = "---`ntype: reglas-globales`nsource: sdd-global-config/.claude/CLAUDE.md`ncommit: $headCommit`nupdated: 2026-11-21`n---`n`n> [!info] Espejo de solo lectura. Fuente: ``.claude/CLAUDE.md`` del repo ``sdd-global-config``. Lo escribe solo ``scripts/instalar.ps1``. No editar acá.`n`n" + $cuerpoRepo
        $espejoPath = "$globalDir/reglas-globales.md"
        Set-Content -Path $espejoPath -Value $espejoSinHuella -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió tener éxito: $($res.Output)"
        Afirmar ($res.Output -match "atrasado") "Debe figurar como atrasado: $($res.Output)"
        Afirmar ($res.Output -notmatch "con cambios locales") "No debe figurar con cambios locales: $($res.Output)"

        $txtEspejoDespues = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejoDespues -match "(?m)^instalacion:\s*[0-9a-f]{12}\s*$") "El espejo debe quedar reescrito con la línea instalacion"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S05
Probar "S05 dato inválido: línea de huella mal formada" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $headCommit = (git -C $repoRoot rev-parse --short HEAD).Trim()
        $cuerpoRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8)
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null

        $espejoMalFormado = "---`ntype: reglas-globales`nsource: sdd-global-config/.claude/CLAUDE.md`ncommit: $headCommit`ninstalacion: no-es-un-hash`nupdated: 2026-11-21`n---`n`n> [!info] Espejo de solo lectura. Fuente: ``.claude/CLAUDE.md`` del repo ``sdd-global-config``. Lo escribe solo ``scripts/instalar.ps1``. No editar acá.`n`n" + $cuerpoRepo
        $espejoPath = "$globalDir/reglas-globales.md"
        Set-Content -Path $espejoPath -Value $espejoMalFormado -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió tener éxito: $($res.Output)"
        Afirmar ($res.Output -match "atrasado") "Debe figurar como atrasado: $($res.Output)"
        Afirmar ($res.Output -notmatch "Exception|ErrorRecord|StackTrace") "No debe haber excepciones en la salida: $($res.Output)"

        $txtEspejoDespues = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejoDespues -match "(?m)^instalacion:\s*[0-9a-f]{12}\s*$") "El espejo debe quedar reescrito con la huella válida"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S06
Probar "S06 repo atrasado con las mismas reglas no sobreescribe espejo" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $cuerpoRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8)
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null

        $espejoFuturo = "---`ntype: reglas-globales`nsource: sdd-global-config/.claude/CLAUDE.md`ncommit: 0000000`ninstalacion: 000000000000`nupdated: 2026-11-21`n---`n`n> [!info] Espejo de solo lectura. Fuente: ``.claude/CLAUDE.md`` del repo ``sdd-global-config``. Lo escribe solo ``scripts/instalar.ps1``. No editar acá.`n`n" + $cuerpoRepo
        $espejoPath = "$globalDir/reglas-globales.md"
        Set-Content -Path $espejoPath -Value $espejoFuturo -Encoding UTF8
        git -C $vault add _global/reglas-globales.md 2>$null | Out-Null
        git -C $vault commit -m "espejo commit desconocido" 2>$null | Out-Null
        $commitCountAntes = [int]((git -C $vault rev-list --count HEAD).Trim())

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -ne 0) "instalar.ps1 debió fallar por repo atrasado: $($res.Output)"
        Afirmar ($res.Output -match "repo atrasado") "Debe figurar como 'repo atrasado': $($res.Output)"
        Afirmar ($res.Output -notmatch "atrasado\s+actualizado") "No debe actualizarse el espejo atrasado: $($res.Output)"

        $txtEspejoDespues = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejoDespues.Contains("commit: 0000000")) "El espejo debe conservar commit: 0000000"
        Afirmar ($txtEspejoDespues.Contains("instalacion: 000000000000")) "El espejo debe conservar instalacion: 000000000000"

        $commitCountDespues = [int]((git -C $vault rev-list --count HEAD).Trim())
        Afirmar ($commitCountDespues -eq $commitCountAntes) "El vault no debe tener commits nuevos"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S07
Probar "S07 comprobar con skills nuevas en otra máquina muestra aviso" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Instalar primero
        $resInst = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($resInst.ExitCode -eq 0) "Instalación previa falló: $($resInst.Output)"

        $espejoPath = "$vault/_global/reglas-globales.md"
        $txtOriginal = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        $txtModificado = $txtOriginal -replace "(?m)^commit:\s*[a-fA-F0-9]+", "commit: 0000000" -replace "(?m)^instalacion:\s*[0-9a-f]{12}", "instalacion: 000000000000"
        Set-Content -Path $espejoPath -Value $txtModificado -Encoding UTF8
        $hashAntes = (Get-FileHash $espejoPath).Hash
        $commitCountAntes = [int]((git -C $vault rev-list --count HEAD).Trim())

        $resComp = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`" -Comprobar"
        Afirmar ($resComp.ExitCode -ne 0) "Comprobar debió fallar: $($resComp.Output)"
        Afirmar ($resComp.Output -match "repo atrasado") "Debe mostrar 'repo atrasado': $($resComp.Output)"
        Afirmar ($resComp.Output -match "skills o comandos") "Debe mencionar 'skills o comandos': $($resComp.Output)"
        Afirmar ($resComp.Output -match "git pull") "Debe mencionar 'git pull': $($resComp.Output)"
        Afirmar ($resComp.Output -match "instalar\.ps1") "Debe mencionar 'instalar.ps1': $($resComp.Output)"

        $hashDespues = (Get-FileHash $espejoPath).Hash
        Afirmar ($hashAntes -eq $hashDespues) "El espejo no debió modificarse"
        $commitCountDespues = [int]((git -C $vault rev-list --count HEAD).Trim())
        Afirmar ($commitCountAntes -eq $commitCountDespues) "El vault no debe tener commits nuevos"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S08
Probar "S08 espejo sincronizado con remote bare incluye huella e instalacion" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        $remoteBare = "$dir/vault-remote.git"
        Inicializar-VaultGit -VaultPath $vault -RemoteBarePath $remoteBare

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        $espejo = "$vault/_global/reglas-globales.md"
        Afirmar (Test-Path $espejo) "No existe _global/reglas-globales.md"

        $txtEspejo = Get-Content -Path $espejo -Raw -Encoding UTF8
        Afirmar ($txtEspejo -match "(?m)^commit:\s*[a-fA-F0-9]+") "Debe tener commit"
        Afirmar ($txtEspejo -match "(?m)^instalacion:\s*[0-9a-f]{12}") "Debe tener instalacion"

        $archivosCommit = (git -C $remoteBare show --name-only --format="" HEAD).Trim() -split "\r?\n"
        Afirmar ($archivosCommit.Count -eq 1 -and $archivosCommit[0] -match "_global/reglas-globales\.md") "El commit en el remote debe incluir solo el espejo"

        $logRemote = git -C $remoteBare log -1 --format="%s"
        Afirmar ($logRemote -match "chore: sdd-global-config — sync reglas") "El commit en el remote debe ser sync de reglas: $logRemote"
    }
}

# test-plan: huella-de-instalacion-en-espejo/S09
Probar "S09 aviso de skills y comandos nuevos en CLAUDE.md" {
    $claudeMd = Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8
    $seccionInicio = [regex]::Match($claudeMd, "(?s)## Al iniciar cada sesión.*?(?=\n## |\Z)").Value
    Afirmar ($seccionInicio -match "repo atrasado") "Debe mencionar repo atrasado en inicio de sesión: $seccionInicio"
    Afirmar ($seccionInicio -match "skills o comandos") "Debe mencionar skills o comandos en inicio de sesión: $seccionInicio"
    Afirmar ($seccionInicio -match "git pull") "Debe mencionar git pull en inicio de sesión: $seccionInicio"
    Afirmar ($seccionInicio -match "instalar\.ps1") "Debe mencionar instalar.ps1 en inicio de sesión: $seccionInicio"
}

# test-plan: huella-de-instalacion-en-espejo/S10
Probar "S10 aviso de skills y comandos nuevos en las guías" {
    $readme = Get-Content -Path "$repoRoot/README.md" -Raw -Encoding UTF8
    $modoUso = Get-Content -Path "$repoRoot/docs/modo-de-uso.md" -Raw -Encoding UTF8

    Afirmar ($readme -match "instalacion:") "README.md debe contener 'instalacion:'"
    Afirmar ($readme -match "repo atrasado") "README.md debe contener 'repo atrasado'"
    Afirmar ($readme -match "git pull") "README.md debe contener 'git pull'"

    Afirmar ($modoUso -match "instalacion:") "docs/modo-de-uso.md debe contener 'instalacion:'"
    Afirmar ($modoUso -match "repo atrasado") "docs/modo-de-uso.md debe contener 'repo atrasado'"
    Afirmar ($modoUso -match "git pull") "docs/modo-de-uso.md debe contener 'git pull'"
}

# test-plan: huella-de-instalacion-en-espejo/S11
Probar "S11 cálculo de huella en comun.ps1 y fuentes consideradas" {
    . $scriptComun

    Con-CarpetaTemporal { param($dir)
        $mock = "$dir/repo"
        New-Item -ItemType Directory -Path "$mock/skills/a" -Force | Out-Null
        New-Item -ItemType Directory -Path "$mock/.claude/commands" -Force | Out-Null
        New-Item -ItemType Directory -Path "$mock/templates/antigravity" -Force | Out-Null

        Set-Content -Path "$mock/skills/a/SKILL.md" -Value "skill content initial" -Encoding UTF8
        Set-Content -Path "$mock/.claude/commands/x.md" -Value "command x content initial" -Encoding UTF8
        Set-Content -Path "$mock/templates/antigravity/GEMINI.md" -Value "gemini template content initial" -Encoding UTF8
        Set-Content -Path "$mock/.claude/statusline.sh" -Value "#!/bin/sh`necho bar" -Encoding UTF8
        Set-Content -Path "$mock/.claude/CLAUDE.md" -Value "# CLAUDE rules" -Encoding UTF8

        $h0 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h0 -match "^[0-9a-f]{12}$") "La huella base debe ser de 12 caracteres hex: $h0"

        # 1. Cambiar una línea en skills/a/SKILL.md
        Set-Content -Path "$mock/skills/a/SKILL.md" -Value "skill content modified" -Encoding UTF8
        $h1 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h1 -ne $h0) "Modificar skill debe cambiar la huella ($h1 vs $h0)"
        Set-Content -Path "$mock/skills/a/SKILL.md" -Value "skill content initial" -Encoding UTF8

        # 2. Cambiar una línea en .claude/commands/x.md
        Set-Content -Path "$mock/.claude/commands/x.md" -Value "command x content modified" -Encoding UTF8
        $h2 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h2 -ne $h0) "Modificar comando debe cambiar la huella ($h2 vs $h0)"
        Set-Content -Path "$mock/.claude/commands/x.md" -Value "command x content initial" -Encoding UTF8

        # 3. Cambiar una línea en templates/antigravity/GEMINI.md
        Set-Content -Path "$mock/templates/antigravity/GEMINI.md" -Value "gemini template modified" -Encoding UTF8
        $h3 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h3 -ne $h0) "Modificar template GEMINI debe cambiar la huella ($h3 vs $h0)"
        Set-Content -Path "$mock/templates/antigravity/GEMINI.md" -Value "gemini template content initial" -Encoding UTF8

        # 4. Cambiar .claude/statusline.sh NO debe cambiar la huella
        Set-Content -Path "$mock/.claude/statusline.sh" -Value "#!/bin/sh`necho different" -Encoding UTF8
        $h4 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h4 -eq $h0) "Modificar statusline.sh no debe cambiar la huella ($h4 vs $h0)"

        # 5. Cambiar .claude/CLAUDE.md NO debe cambiar la huella
        Set-Content -Path "$mock/.claude/CLAUDE.md" -Value "# CLAUDE rules modified" -Encoding UTF8
        $h5 = Obtener-HuellaInstalacion -RepoRoot $mock
        Afirmar ($h5 -eq $h0) "Modificar CLAUDE.md no debe cambiar la huella ($h5 vs $h0)"
    }
}
