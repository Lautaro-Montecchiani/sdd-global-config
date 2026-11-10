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

# test-plan: sincronizar-reglas/S06
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

        $logVault = git -C $vault log -1 --format="%s"
        Afirmar ($logVault -match "chore: sdd-global-config — sync reglas") "El commit debe ser 'chore: sdd-global-config — sync reglas': $logVault"
    }
}

# test-plan: sincronizar-reglas/S12
Probar "S12 aviso cuando el vault no existe y continúa" {
    Con-CarpetaTemporal { param($dir)
        $dest = "$dir/destino"
        $vaultFalso = "$dir/vault-no-existe"

        $res = Ejecutar-Pwsh -ScriptPath $scriptInstalar -Argumentos "-Destino `"$dest`" -Vault `"$vaultFalso`""
        Afirmar ($res.ExitCode -eq 0) "instalar.ps1 debió terminar con código 0 aun sin vault: $($res.Output)"
        Afirmar ($res.Output -match "vault|Vault") "La salida debe avisar sobre el vault: $($res.Output)"
        Afirmar (Test-Path "$dest/.claude/CLAUDE.md") "La instalación en destino debió completarse"
    }
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
