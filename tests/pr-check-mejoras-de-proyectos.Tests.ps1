# tests/pr-check-mejoras-de-proyectos.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$scriptSincronizar = "$repoRoot/scripts/sincronizar-proyecto.ps1"
$prCheckWorkflow = "$repoRoot/.github/workflows/pr-check.yml"
$claudeMd = "$repoRoot/.claude/CLAUDE.md"
$readmeMd = "$repoRoot/README.md"

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

# test-plan: pr-check-mejoras-de-proyectos/S01
Probar "S01 Permisos de solo lectura en pr-check.yml" {
    $contenido = Get-Content -Path $prCheckWorkflow -Raw
    Afirmar ($contenido -match "(?m)^permissions:\s*\r?\n\s+contents:\s*read\s*\r?\n\s+pull-requests:\s*read") "Debe declarar permissions con contents: read y pull-requests: read a nivel raíz"
}

# test-plan: pr-check-mejoras-de-proyectos/S02
Probar "S02 Patrones sensibles y plantillas de ejemplo en pr-check.yml" {
    $contenido = Get-Content -Path $prCheckWorkflow -Raw
    Afirmar ($contenido.Contains("const sensitivePatterns = ['.env', '.key', '.pem', '.p12', 'secrets/', 'credentials.json', 'token.json'];")) "Debe incluir sensitivePatterns con los 7 patrones de D1"
    Afirmar ($contenido.Contains("const safeSuffixes = ['.example', '.sample', '.template'];")) "Debe incluir safeSuffixes con los 3 sufijos de D1"
    Afirmar ($contenido -match "\.filter\(name\s*=>\s*!safeSuffixes\.some\(s\s*=>\s*name\.endsWith\(s\)\)\)") "Debe filtrar safeSuffixes antes del filtro de patrones sensibles"
    Afirmar ($contenido.Contains("Verificá que .env, credentials.json, token.json y demás credenciales estén en .gitignore.")) "El mensaje debe advertir sobre credentials.json y token.json"
}

# test-plan: pr-check-mejoras-de-proyectos/S03
Probar "S03 Comentario de origen en pr-check.yml" {
    $lineas = Get-Content -Path $prCheckWorkflow
    Afirmar ($lineas.Count -ge 3) "El archivo debe tener al menos 3 líneas"
    Afirmar ($lineas[0] -eq "# Generado desde .github/workflows/pr-check.yml de sdd-global-config con scripts/sincronizar-proyecto.ps1. No editar en los proyectos:") "Línea 1 incorrecta: $($lineas[0])"
    Afirmar ($lineas[1] -eq "# - si la mejora sirve para todos los proyectos, abrí un issue en sdd-global-config;") "Línea 2 incorrecta: $($lineas[1])"
    Afirmar ($lineas[2] -eq "# - si es propia del proyecto, ponela en otro workflow (por ejemplo, .github/workflows/proyecto.yml).") "Línea 3 incorrecta: $($lineas[2])"
}

# test-plan: pr-check-mejoras-de-proyectos/S04
Probar "S04 Aviso con solo pr-check bloqueado" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github/workflows" -Force | Out-Null
        Set-Content -Path "$dir/.github/workflows/pr-check.yml" -Value "name: Custom PR Check`n# modificado a mano" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -ne 0) "Aviso debe salir con código distinto de 0"
        Afirmar ($res.Output.Contains(".github/workflows/pr-check.yml editado a mano: si la mejora sirve para todos, abrí un issue en sdd-global-config; si es propia del proyecto, pasala a otro workflow y sincronizá con -Forzar.")) "Debe contener el texto de D2 para pr-check.yml: $($res.Output)"
        Afirmar (-not $res.Output.Contains("## Propio del proyecto")) "No debe mencionar ## Propio del proyecto si el único bloqueado es pr-check: $($res.Output)"
        Afirmar (-not $res.Output.Contains("Bloqueados por contenido propio:")) "No debe mencionar 'Bloqueados por contenido propio:' si el único bloqueado es pr-check: $($res.Output)"
    }
}

# test-plan: pr-check-mejoras-de-proyectos/S05
Probar "S05 Aviso con pr-check y AGENTS.md bloqueados" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github/workflows" -Force | Out-Null
        Set-Content -Path "$dir/.github/workflows/pr-check.yml" -Value "name: Custom PR Check`n# modificado a mano" -Encoding UTF8
        Set-Content -Path "$dir/AGENTS.md" -Value "Texto arbitrario sin seccion propia" -Encoding UTF8

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`" -Aviso"
        Afirmar ($res.ExitCode -ne 0) "Aviso debe salir con código distinto de 0"
        Afirmar ($res.Output -match "Bloqueados por contenido propio:\s*AGENTS\.md;\s*pasá ese contenido debajo de `"## Propio del proyecto`" y volvé a sincronizar\.") "Debe indicar Bloqueados por contenido propio: AGENTS.md: $($res.Output)"
        Afirmar ($res.Output.Contains(".github/workflows/pr-check.yml editado a mano: si la mejora sirve para todos, abrí un issue en sdd-global-config; si es propia del proyecto, pasala a otro workflow y sincronizá con -Forzar.")) "Debe contener el texto de D2 para pr-check.yml: $($res.Output)"
    }
}

# test-plan: pr-check-mejoras-de-proyectos/S06
Probar "S06 Sincronización con pr-check bloqueado" {
    Con-CarpetaTemporal { param($dir)
        New-Item -ItemType Directory -Path "$dir/.github/workflows" -Force | Out-Null
        $rutaPr = "$dir/.github/workflows/pr-check.yml"
        Set-Content -Path $rutaPr -Value "name: Custom PR Check`n# modificado a mano" -Encoding UTF8
        $hashAntes = (Get-FileHash $rutaPr).Hash

        $res = Ejecutar-Pwsh -ScriptPath $scriptSincronizar -Argumentos "-Proyecto `"$dir`""
        Afirmar ($res.ExitCode -ne 0) "Sincronización debe salir con código distinto de 0"
        Afirmar ($res.Output.Contains("Para .github/workflows/pr-check.yml: si la mejora sirve para todos, abrí un issue en sdd-global-config; si es propia del proyecto, pasala a otro workflow y sincronizá con -Forzar.")) "Debe contener la línea de D2 para pr-check.yml: $($res.Output)"
        $hashDespues = (Get-FileHash $rutaPr).Hash
        Afirmar ($hashAntes -eq $hashDespues) "El archivo pr-check.yml no debió modificarse"
    }
}

# test-plan: pr-check-mejoras-de-proyectos/S07
Probar "S07 Regla de mejoras de archivos generados documentada" {
    $claudeTexto = Get-Content -Path $claudeMd -Raw
    $vineta = @'
- **Mejoras a archivos generados:** `AGENTS.md`, las instrucciones de Copilot y Cursor, los comandos `/odd-apply` y `.github/workflows/pr-check.yml` de cada proyecto se generan desde `sdd-global-config` y no se mejoran en el proyecto. Si la mejora sirve para todos, se abre un issue en `sdd-global-config` (`/issue-creation`). Si es propia del proyecto, va debajo de `## Propio del proyecto` en los `.md`, o en otro workflow en el caso de `pr-check.yml`. Cuando `-Aviso` o la sincronización muestran un archivo bloqueado, Claude le explica al usuario estas dos salidas y no sincroniza con `-Forzar` por su cuenta.
'@
    Afirmar ($claudeTexto.Contains($vineta.Trim())) "CLAUDE.md debe contener la viñeta de D3"

    $readmeTexto = Get-Content -Path $readmeMd -Raw
    $parrafoReadme = @'
**Mejoras a archivos generados.** Los archivos que copia `sincronizar-proyecto.ps1` no se mejoran en el proyecto. Si la mejora sirve para todos, abrí un issue en `sdd-global-config`. Si es propia del proyecto, ponela debajo de `## Propio del proyecto` en los `.md`, o en otro workflow en el caso de `pr-check.yml` (por ejemplo, `.github/workflows/proyecto.yml`), y sincronizá con `-Forzar`.
'@
    Afirmar ($readmeTexto.Contains($parrafoReadme.Trim())) "README.md debe contener el párrafo 'Mejoras a archivos generados' de D4"
}

# test-plan: pr-check-mejoras-de-proyectos/S08
Probar "S08 Procedimiento para sincronizar varios proyectos documentado" {
    $readmeTexto = Get-Content -Path $readmeMd -Raw
    $parrafoProcedimiento = @'
**Sincronizar varios proyectos.** Para poner al día varios proyectos: (1) detectá los atrasados corriendo `-Aviso` en cada uno; (2) en cada atrasado, corré primero con `-Simular`; (3) pasá en `-Agentes` solo los agentes que el proyecto ya usa (`comun` si tiene `AGENTS.md`, `copilot` si tiene `.github/copilot-instructions.md`, `cursor` si tiene `.cursor/`), así no se crean archivos que el proyecto no usa; (4) no sincronices si alguno de los archivos a reemplazar tiene cambios sin commitear; (5) el script no commitea: los cambios quedan en el árbol de trabajo y se commitean en la rama que corresponda.
'@
    Afirmar ($readmeTexto.Contains($parrafoProcedimiento.Trim())) "README.md debe contener el párrafo 'Sincronizar varios proyectos' de D4"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
