# tests/instalar.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptInstalar = "$repoRoot/scripts/instalar.ps1"

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

# test-plan: sincronizar-reglas/S06
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S24
Probar "S06 destino vacío instala archivos y crea manifiesto" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló con código $($res.ExitCode): $($res.Output)"

        Afirmar (Test-Path "$dest/.claude/CLAUDE.md") "No existe CLAUDE.md en destino"
        Afirmar (Test-Path "$dest/.claude/.sdd-global-config.json") "No existe el manifiesto"
        Afirmar ($res.Output -match "CLAUDE\.md") "La salida debe listar CLAUDE.md"
        Afirmar ($res.Output -match "igual|creado|instalado") "La salida debe incluir estado en la tabla"
    }
}

# test-plan: sincronizar-reglas/S07
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S25
Probar "S07 cambio local bloquea la instalación sin tocar archivos" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path "$dest/.claude" -Force | Out-Null
        Set-Content -Path "$dest/.claude/CLAUDE.md" -Value "Línea local modificada a mano" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -ne 0) "instalar.ps1 debió fallar por cambio local"
        Afirmar ($res.Output -match "con cambios locales") "La salida debe indicar 'con cambios locales': $($res.Output)"

        $txt = Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8
        Afirmar ($txt -match "Línea local modificada a mano") "El archivo local no debió modificarse"
    }
}

# test-plan: sincronizar-reglas/S08
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S26
Probar "S08 forzar respalda y sobreescribe cambios locales" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path "$dest/.claude" -Force | Out-Null
        Set-Content -Path "$dest/.claude/CLAUDE.md" -Value "Línea local modificada a mano" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault -Forzar"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 -Forzar falló: $($res.Output)"
        Afirmar ($res.Output -match "sdd-respaldo-") "La salida debe mostrar la carpeta de respaldo: $($res.Output)"

        $txt = Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8
        Afirmar ($txt -notmatch "Línea local modificada a mano") "El archivo instalado debió sobreescribirse"
    }
}

# test-plan: sincronizar-reglas/S09
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S27
Probar "S09 simular muestra tabla sin modificar destino ni manifiesto" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault -Simular"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 -Simular falló: $($res.Output)"
        Afirmar (-not (Test-Path "$dest/.claude/CLAUDE.md")) "CLAUDE.md no debió escribirse con -Simular"
        Afirmar (-not (Test-Path "$dest/.claude/.sdd-global-config.json")) "El manifiesto no debió escribirse con -Simular"
    }
}

# test-plan: sincronizar-reglas/S10
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S28
Probar "S10 GEMINI.md instalado conserva contenido propio" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path "$dest/.gemini" -Force | Out-Null
        
        $contenidoViejo = @"
# Reglas Antigravity Viejas

## Propio del proyecto
<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->
- Mi configuración propia antigravity
"@
        Set-Content -Path "$dest/.gemini/GEMINI.md" -Value $contenidoViejo -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló con GEMINI.md: $($res.Output)"

        $txt = Get-Content -Path "$dest/.gemini/GEMINI.md" -Raw -Encoding UTF8
        Afirmar ($txt -match "Mi configuración propia antigravity") "Debe conservar la línea propia"
        Afirmar ($txt -match "Workflow SDD Híbrido") "Debe incluir la versión generada de la plantilla"
    }
}

# test-plan: sincronizar-reglas/S11
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S29
Probar "S11 espejo del vault sincronizado con remote bare" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        $remoteBare = "$dir/vault-remote.git"

        New-Item -ItemType Directory -Path $dest -Force | Out-Null
        New-Item -ItemType Directory -Path $vault -Force | Out-Null

        git init --bare $remoteBare 2>$null | Out-Null
        git -C $vault init 2>$null | Out-Null
        git -C $vault -c user.name="Tester" -c user.email="tester@example.com" commit --allow-empty -m "initial commit" 2>$null | Out-Null
        git -C $vault remote add origin $remoteBare 2>$null | Out-Null
        git -C $vault push -u origin master 2>$null | Out-Null
        if ($LASTEXITCODE -ne 0) {
            git -C $vault push -u origin main 2>$null | Out-Null
        }

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 con vault falló: $($res.Output)"

        $espejo = "$vault/_global/reglas-globales.md"
        Afirmar (Test-Path $espejo) "No existe _global/reglas-globales.md en el vault"

        $txtEspejo = Get-Content -Path $espejo -Raw -Encoding UTF8
        Afirmar ($txtEspejo -match "CLAUDE\.md") "El espejo debe incluir el aviso de fuente"
        Afirmar ($txtEspejo.Contains("source: sdd-global-config/.claude/CLAUDE.md")) "El espejo debe nombrar al repo como fuente"
        Afirmar ($txtEspejo -match "(?m)^commit:\s*[a-fA-F0-9]+") "El espejo debe tener una línea commit: con el commit corto"

        $archivosCommit = (git -C $vault show --name-only --format="" HEAD).Trim() -split "\r?\n"
        Afirmar ($archivosCommit.Count -eq 1 -and $archivosCommit[0] -match "_global/reglas-globales\.md") "El commit del vault debe incluir solo _global/reglas-globales.md"

        $logVault = git -C $vault log -1 --format="%s"
        Afirmar ($logVault -match "chore: sdd-global-config — sync reglas") "El commit debe ser 'chore: sdd-global-config — sync reglas': $logVault"
    }
}

# test-plan: sincronizar-reglas/S12
# test-plan: reglas-fuente-unica-y-carga-desde-vault/S30
Probar "S12 aviso cuando el vault no existe y continúa" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vaultFalso = "$dir/vault-no-existe"

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vaultFalso`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió terminar con código 0 aun sin vault: $($res.Output)"
        Afirmar ($res.Output -match "vault|Vault") "La salida debe avisar sobre el vault: $($res.Output)"
        Afirmar (Test-Path "$dest/.claude/CLAUDE.md") "La instalación en destino debió completarse"

        $txtInstalado = (Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $txtRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        Afirmar ($txtInstalado -eq $txtRepo) "El CLAUDE.md instalado debe ser la copia completa cuando no hay vault"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S04
Probar "reglas-fuente-unica/S04 archivo de carga con vault" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        $claudeInstaladoPath = "$dest/.claude/CLAUDE.md"
        Afirmar (Test-Path $claudeInstaladoPath) "No existe CLAUDE.md en destino"

        $txt = (Get-Content -Path $claudeInstaladoPath -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $vaultAbs = (Resolve-Path $vault).Path -replace "\\", "/"
        $lineaEsperada = "@$vaultAbs/_global/reglas-globales.md"

        $lineas = $txt -split "\n"
        $lineasImport = @($lineas | Where-Object { $_.StartsWith("@") })
        Afirmar ($lineasImport.Count -eq 1) "Debe tener exactamente una línea que empiece con @"
        Afirmar ($lineasImport[0] -eq $lineaEsperada) "La línea @ debe ser '$lineaEsperada', pero fue '$($lineasImport[0])'"

        Afirmar (-not $txt.Contains("### Reglas de ejecución del Agente")) "No debe contener el texto de las reglas"
        Afirmar ($txt.Contains("<!-- Generado por scripts/instalar.ps1 de sdd-global-config. No editar a mano: las reglas se editan en el repo. -->")) "Debe tener el aviso de archivo generado"
        Afirmar ($txt.Contains("Si después de esa línea no ves la sección `"Roles Claude / Agente (OpenSpec)`", el vault no cargó: avisá al usuario")) "Debe tener la instrucción de avisar si las reglas no cargaron"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S05
Probar "reglas-fuente-unica/S05 copia completa sin vault" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault"
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 -SinVault falló: $($res.Output)"

        $txtInstalado = (Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $txtRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        Afirmar ($txtInstalado -eq $txtRepo) "CLAUDE.md instalado debe tener el mismo contenido que el repo"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S06
Probar "reglas-fuente-unica/S06 ruta del vault con espacios" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vaultEspacios = "$dir/vault con espacios"
        Inicializar-VaultGit -VaultPath $vaultEspacios

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vaultEspacios`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 falló: $($res.Output)"

        $txtInstalado = (Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        $txtRepo = (Get-Content -Path "$repoRoot/.claude/CLAUDE.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
        Afirmar ($txtInstalado -eq $txtRepo) "Con espacios en la ruta del vault debe instalar la copia completa"

        Afirmar ($res.Output -match "Aviso: La ruta del vault tiene espacios; se instala la copia completa del CLAUDE\.md en lugar del archivo de carga\.") "La salida debe avisar que se instala copia completa por espacios: $($res.Output)"
        Afirmar (Test-Path "$vaultEspacios/_global/reglas-globales.md") "El espejo debe escribirse igual en el vault con espacios"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S07
Probar "reglas-fuente-unica/S07 copia completa anterior pasa a archivo de carga" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        New-Item -ItemType Directory -Path "$dest/.claude" -Force | Out-Null
        $versionVieja = git -C $repoRoot show HEAD~1:.claude/CLAUDE.md
        Afirmar (-not [string]::IsNullOrWhiteSpace($versionVieja)) "Debe obtenerse una versión anterior de CLAUDE.md"
        Set-Content -Path "$dest/.claude/CLAUDE.md" -Value $versionVieja -Encoding UTF8

        # Al correr instalar.ps1 sin -Forzar, debe reconocerlo como atrasado y reemplazarlo por archivo de carga
        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió tener éxito sin -Forzar: $($res.Output)"
        Afirmar ($res.Output -notmatch "con cambios locales") "No debe figurar como con cambios locales: $($res.Output)"
        Afirmar ($res.Output -match "atrasado") "Debe figurar como atrasado: $($res.Output)"

        $txtInstalado = Get-Content -Path "$dest/.claude/CLAUDE.md" -Raw -Encoding UTF8
        $vaultAbs = (Resolve-Path $vault).Path -replace "\\", "/"
        Afirmar ($txtInstalado.Contains("@$vaultAbs/_global/reglas-globales.md")) "Debe quedar reemplazado por el archivo de carga"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S08
Probar "reglas-fuente-unica/S08 espejo ya igual" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Primera instalación
        $res1 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res1.ExitCode -eq 0) "Primera instalación falló: $($res1.Output)"

        $commitCount1 = (git -C $vault rev-list --count HEAD).Trim()

        # Segunda instalación
        $res2 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res2.ExitCode -eq 0) "Segunda instalación falló: $($res2.Output)"

        $commitCount2 = (git -C $vault rev-list --count HEAD).Trim()
        Afirmar ($commitCount1 -eq $commitCount2) "No debió agregar ningún commit al vault en segunda corrida ($commitCount1 vs $commitCount2)"
        Afirmar ($res2.Output -match "vault:\s+_global/reglas-globales\.md\s+igual|reglas-globales\.md.*?igual") "La tabla debe mostrar el espejo como igual: $($res2.Output)"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S09
Probar "reglas-fuente-unica/S09 espejo editado a mano" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Instalar primero
        $res1 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res1.ExitCode -eq 0) "Instalación inicial falló"

        # Editar el espejo a mano agregando una línea
        $espejoPath = "$vault/_global/reglas-globales.md"
        Add-Content -Path $espejoPath -Value "`n<!-- línea editada a mano en el espejo -->" -Encoding UTF8
        $hashEspejoMod = (Get-FileHash $espejoPath).Hash
        $hashDestAntes = (Get-FileHash "$dest/.claude/CLAUDE.md").Hash

        # Intentar instalar sin -Forzar
        $res2 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res2.ExitCode -ne 0) "instalar.ps1 debió fallar por espejo editado a mano: $($res2.Output)"
        Afirmar ($res2.Output -match "con cambios locales") "Debe listar el espejo como 'con cambios locales': $($res2.Output)"
        Afirmar ($res2.Output -match "reglas-globales\.md") "Debe nombrar el archivo del espejo: $($res2.Output)"

        # Ni el espejo ni el destino debieron cambiar
        $hashEspejoDespues = (Get-FileHash $espejoPath).Hash
        $hashDestDespues = (Get-FileHash "$dest/.claude/CLAUDE.md").Hash
        Afirmar ($hashEspejoMod -eq $hashEspejoDespues) "El espejo no debió cambiar ante error"
        Afirmar ($hashDestAntes -eq $hashDestDespues) "El destino no debió cambiar ante error"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S10
Probar "reglas-fuente-unica/S10 forzar con respaldo del espejo" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Instalar primero
        $res1 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res1.ExitCode -eq 0) "Instalación inicial falló"

        # Editar el espejo a mano agregando una línea
        $espejoPath = "$vault/_global/reglas-globales.md"
        $lineaManual = "<!-- línea editada a mano en el espejo -->"
        Add-Content -Path $espejoPath -Value "`n$lineaManual" -Encoding UTF8

        # Correr con -Forzar
        $res2 = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`" -Forzar"
        Afirmar ($res2.ExitCode -eq 0) "instalar.ps1 -Forzar falló: $($res2.Output)"
        Afirmar ($res2.Output -match "sdd-respaldo-") "Debe mostrar la carpeta de respaldo: $($res2.Output)"

        # Extraer carpeta de respaldo de la salida
        $matchRespaldo = [regex]::Match($res2.Output, "sdd-respaldo-[a-zA-Z0-9]+")
        Afirmar ($matchRespaldo.Success) "Debe encontrarse el nombre de la carpeta de respaldo"

        # El espejo debe quedar sin la línea agregada
        $txtEspejo = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar (-not $txtEspejo.Contains($lineaManual)) "El espejo debe quedar restaurado sin la línea agregada"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S11
Probar "reglas-fuente-unica/S11 espejo atrasado" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Dejar en el espejo un contenido histórico de CLAUDE.md
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
        $versionVieja = (git -C $repoRoot show HEAD~1:.claude/CLAUDE.md) -join "`n"
        $headerViejo = "---`ntype: reglas-globales`nsource: ~/.claude/CLAUDE.md`nupdated: 2026-01-01`n---`n`n> [!info] Espejo de solo lectura. Fuente canónica: ``~/.claude/CLAUDE.md``. No editar acá.`n`n"
        Set-Content -Path "$globalDir/reglas-globales.md" -Value ($headerViejo + $versionVieja) -Encoding UTF8

        # Correr instalar.ps1 sin -Forzar
        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió actualizar el espejo atrasado sin -Forzar: $($res.Output)"
        Afirmar ($res.Output -match "atrasado") "Debe figurar como atrasado: $($res.Output)"

        $txtEspejo = Get-Content -Path "$globalDir/reglas-globales.md" -Raw -Encoding UTF8
        Afirmar ($txtEspejo.Contains("source: sdd-global-config/.claude/CLAUDE.md")) "Debe tener el nuevo encabezado"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S12
Probar "reglas-fuente-unica/S12 repo atrasado" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Armar espejo con commit desconocido que no existe en el repo y cuerpo distinto
        $globalDir = "$vault/_global"
        New-Item -ItemType Directory -Path $globalDir -Force | Out-Null
        $headerCommitFalso = "---`ntype: reglas-globales`nsource: sdd-global-config/.claude/CLAUDE.md`ncommit: 0000000`nupdated: 2026-11-12`n---`n`n> [!info] Espejo de solo lectura. Fuente: `.claude/CLAUDE.md` del repo `sdd-global-config`. Lo escribe solo `scripts/instalar.ps1`. No editar acá.`n`n"
        $cuerpoDistinto = "# Reglas de un commit futuro`nContenido diferente"
        $espejoPath = "$globalDir/reglas-globales.md"
        Set-Content -Path $espejoPath -Value ($headerCommitFalso + $cuerpoDistinto) -Encoding UTF8

        # Correr instalar.ps1 incluso con -Forzar
        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`" -Forzar"
        Afirmar ($res.ExitCode -ne 0) "instalar.ps1 debió fallar con repo atrasado aun con -Forzar"
        Afirmar ($res.Output -match "repo atrasado") "Debe mostrar 'repo atrasado': $($res.Output)"
        Afirmar ($res.Output -match "git pull") "Debe pedir correr git pull: $($res.Output)"

        $txtEspejoDespues = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejoDespues.Contains("commit: 0000000")) "El espejo no debió modificarse"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S13
Probar "reglas-fuente-unica/S13 comprobar con instalación al día" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Instalar primero
        $resInst = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($resInst.ExitCode -eq 0) "Instalación falló: $($resInst.Output)"

        # Comprobar
        $resComp = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`" -Comprobar"
        Afirmar ($resComp.ExitCode -eq 0) "Comprobar debió terminar con código 0: $($resComp.Output)"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S14
Probar "reglas-fuente-unica/S14 comprobar con espejo distinto" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vault = "$dir/vault"
        Inicializar-VaultGit -VaultPath $vault

        # Instalar primero
        $resInst = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`""
        Afirmar ($resInst.ExitCode -eq 0) "Instalación falló"

        # Modificar espejo agregando una línea
        $espejoPath = "$vault/_global/reglas-globales.md"
        $lineaExtra = "<!-- línea extra para fallar comprobar -->"
        Add-Content -Path $espejoPath -Value "`n$lineaExtra" -Encoding UTF8

        $commitsAntes = (git -C $vault rev-list --count HEAD).Trim()

        # Comprobar
        $resComp = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vault`" -Comprobar"
        Afirmar ($resComp.ExitCode -ne 0) "Comprobar debió fallar por espejo distinto: $($resComp.Output)"
        Afirmar ($resComp.Output -match "_global/reglas-globales\.md") "Debe nombrar _global/reglas-globales.md: $($resComp.Output)"

        # Espejo conserva la línea agregada y vault no tiene commits nuevos
        $txtEspejo = Get-Content -Path $espejoPath -Raw -Encoding UTF8
        Afirmar ($txtEspejo.Contains($lineaExtra)) "El espejo debe conservar la línea agregada"
        $commitsDespues = (git -C $vault rev-list --count HEAD).Trim()
        Afirmar ($commitsAntes -eq $commitsDespues) "El vault no debe tener commits nuevos"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S15
Probar "reglas-fuente-unica/S15 comprobar con destino vacío" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        New-Item -ItemType Directory -Path $dest -Force | Out-Null

        $resComp = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -SinVault -Comprobar"
        Afirmar ($resComp.ExitCode -ne 0) "Comprobar debió fallar con destino vacío: $($resComp.Output)"

        $archivosDest = Get-ChildItem -Path $dest -Recurse
        Afirmar ($archivosDest.Count -eq 0) "El destino debe seguir vacío"
    }
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S16
Probar "reglas-fuente-unica/S16 texto de las reglas globales" {
    $claudePath = "$repoRoot/.claude/CLAUDE.md"
    Afirmar (Test-Path $claudePath) "Debe existir .claude/CLAUDE.md"
    $claudeTxt = (Get-Content -Path $claudePath -Raw -Encoding UTF8) -replace "\r\n", "`n"

    # Nombra al repo sdd-global-config como fuente de las reglas
    Afirmar ($claudeTxt.Contains("### Fuente de las reglas: repo ``sdd-global-config``") -or $claudeTxt -match "Fuente de las reglas:\s+repo\s+``?sdd-global-config``?") "CLAUDE.md debe nombrar al repo sdd-global-config como fuente"
    # Nombra a instalar.ps1 -Comprobar en el inicio de sesión
    Afirmar ($claudeTxt -match "instalar\.ps1\s+-Comprobar") "CLAUDE.md debe nombrar instalar.ps1 -Comprobar en el inicio de sesión"

    # NO contiene "Fuente canónica:** `~/.claude/CLAUDE.md`"
    Afirmar (-not ($claudeTxt -match "Fuente canónica:\*\*\s+``?~/\.claude/CLAUDE\.md``?")) "CLAUDE.md no debe decir que la fuente canónica es ~/.claude/CLAUDE.md"

    # NO contiene el comando que arma el espejo con Out-File
    Afirmar (-not ($claudeTxt -match "(?i)Out-File.*?reglas-globales")) "CLAUDE.md no debe contener comando que arma el espejo con Out-File"
}

# test-plan: reglas-fuente-unica-y-carga-desde-vault/S17
Probar "reglas-fuente-unica/S17 texto de las guías" {
    $guias = @(
        "$repoRoot/README.md",
        "$repoRoot/docs/workflow.md",
        "$repoRoot/docs/modo-de-uso.md"
    )

    foreach ($g in $guias) {
        Afirmar (Test-Path $g) "Debe existir $g"
        $gtxt = (Get-Content -Path $g -Raw -Encoding UTF8) -replace "\r\n", "`n"
        Afirmar (-not ($gtxt -match "fuente canónica.*~/\.claude/CLAUDE\.md")) "$g no debe decir que la fuente canónica es ~/.claude/CLAUDE.md"
    }

    $readmeTxt = (Get-Content -Path "$repoRoot/README.md" -Raw -Encoding UTF8) -replace "\r\n", "`n"
    Afirmar ($readmeTxt -match "generar-plantillas\.ps1.*bloque de reglas.*CLAUDE\.md|-Comprobar.*bloque de reglas.*CLAUDE\.md") "README.md debe decir que -Comprobar controla el texto del bloque de reglas del CLAUDE.md"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
