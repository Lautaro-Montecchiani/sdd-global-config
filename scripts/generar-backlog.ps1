# scripts/generar-backlog.ps1
# Genera docs/backlog.md desde los issues abiertos de GitHub
# Uso: pwsh scripts/generar-backlog.ps1 -Proyecto <ruta> [-Entrada <archivo.json>]

param(
    [Parameter(Mandatory = $true)]
    [string]$Proyecto,
    [Parameter(Mandatory = $false)]
    [string]$Entrada
)

$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new($false)

function Formatear-Backlog {
    param(
        $issues,
        [string]$nombreProyecto,
        [string]$fecha
    )

    $grupos = @{
        'alta'          = [System.Collections.Generic.List[object]]::new()
        'media'         = [System.Collections.Generic.List[object]]::new()
        'baja'          = [System.Collections.Generic.List[object]]::new()
        'sin-prioridad' = [System.Collections.Generic.List[object]]::new()
    }

    $totalValidos = 0

    foreach ($item in ($issues | Sort-Object -Property number)) {
        $totalValidos++

        # Prioridad (gana la más alta si tiene varias)
        $prioridad = 'sin-prioridad'
        $labelNames = @($item.labels | ForEach-Object { if ($_ -is [string]) { $_ } else { $_.name } })

        if ($labelNames -contains 'prioridad:alta') {
            $prioridad = 'alta'
        } elseif ($labelNames -contains 'prioridad:media') {
            $prioridad = 'media'
        } elseif ($labelNames -contains 'prioridad:baja') {
            $prioridad = 'baja'
        }

        # Tipo
        $tipo = '—'
        if ($labelNames -contains 'tipo:feature') {
            $tipo = 'feature'
        } elseif ($labelNames -contains 'tipo:deuda') {
            $tipo = 'deuda'
        } elseif ($labelNames -contains 'tipo:bug') {
            $tipo = 'bug'
        }

        # Título formateado
        $titulo = [string]$item.title
        $titulo = $titulo -replace '\r?\n', ' '
        $titulo = $titulo -replace '\|', '\|'
        $titulo = $titulo.Trim()

        if ($labelNames -contains 'bloqueado') {
            $titulo = "$titulo (bloqueado)"
        }

        $obj = [PSCustomObject]@{
            number           = $item.number
            url              = if ($null -ne $item.url) { $item.url } else { "" }
            tituloFormateado = $titulo
            tipo             = $tipo
        }

        $grupos[$prioridad].Add($obj)
    }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine('<!-- Generado con scripts/generar-backlog.ps1 desde los issues abiertos de GitHub. No editar a mano. -->')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("# Backlog — $nombreProyecto")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine("Generado el $fecha. Fuente: issues abiertos del repositorio. Lo ya implementado está en docs/srs.md.")
    [void]$sb.AppendLine()

    $secciones = @(
        @{ Titulo = '## Prioridad alta'; Clave = 'alta' },
        @{ Titulo = '## Prioridad media'; Clave = 'media' },
        @{ Titulo = '## Prioridad baja'; Clave = 'baja' },
        @{ Titulo = '## Sin prioridad'; Clave = 'sin-prioridad' }
    )

    foreach ($sec in $secciones) {
        [void]$sb.AppendLine($sec.Titulo)
        [void]$sb.AppendLine()
        $items = $grupos[$sec.Clave]
        if ($null -eq $items -or $items.Count -eq 0) {
            [void]$sb.AppendLine('Ninguno.')
        } else {
            [void]$sb.AppendLine('| Issue | Título | Tipo |')
            [void]$sb.AppendLine('|---|---|---|')
            foreach ($it in $items) {
                [void]$sb.AppendLine("| [#$($it.number)]($($it.url)) | $($it.tituloFormateado) | $($it.tipo) |")
            }
        }
        [void]$sb.AppendLine()
    }

    [void]$sb.AppendLine("Total: $totalValidos issues abiertos.")
    return $sb.ToString()
}

# Validación y resolución de rutas
if (-not (Test-Path $Proyecto)) {
    Write-Host "No se pudo leer los issues del proyecto: la ruta especificada no existe."
    exit 1
}

$resolvedProject = (Resolve-Path $Proyecto).Path
$nombreProyecto = Split-Path $resolvedProject -Leaf

$rawIssues = $null

if ($null -ne $Entrada -and $Entrada -ne '') {
    if (-not (Test-Path $Entrada)) {
        Write-Host "No se pudo leer los issues del proyecto: el archivo de entrada no existe."
        exit 1
    }
    try {
        $jsonContent = [System.IO.File]::ReadAllText((Resolve-Path $Entrada).Path, [System.Text.UTF8Encoding]::new($false))
        $rawIssues = ConvertFrom-Json $jsonContent
    } catch {
        Write-Host "No se pudo leer los issues del proyecto: formato JSON inválido."
        exit 1
    }
} else {
    try {
        $psi = [System.Diagnostics.ProcessStartInfo]::new()
        $psi.FileName = 'gh'
        $psi.Arguments = 'issue list --state open --limit 500 --json number,title,labels,url'
        $psi.RedirectStandardOutput = $true
        $psi.RedirectStandardError = $true
        $psi.UseShellExecute = $false
        $psi.CreateNoWindow = $true
        $psi.WorkingDirectory = $resolvedProject

        $proc = [System.Diagnostics.Process]::Start($psi)
        $stdout = $proc.StandardOutput.ReadToEnd()
        $stderr = $proc.StandardError.ReadToEnd()
        $proc.WaitForExit()

        if ($proc.ExitCode -ne 0) {
            $motivo = $stderr.Trim()
            if ([string]::IsNullOrWhiteSpace($motivo)) {
                $motivo = "error al ejecutar gh (código $($proc.ExitCode))"
            }
            # Eliminar rutas absolutas
            $motivo = $motivo -replace [regex]::Escape($resolvedProject), '<proyecto>'
            $motivo = $motivo -replace '[A-Za-z]:[\\/][^ \r\n\t"''`]+', '<ruta>'
            Write-Host "No se pudo leer los issues del proyecto: $motivo."
            exit 1
        }

        $rawIssues = ConvertFrom-Json $stdout
    } catch {
        $motivo = $_.Exception.Message
        $motivo = $motivo -replace [regex]::Escape($resolvedProject), '<proyecto>'
        $motivo = $motivo -replace '[A-Za-z]:[\\/][^ \r\n\t"''`]+', '<ruta>'
        Write-Host "No se pudo leer los issues del proyecto: $motivo."
        exit 1
    }
}

# Filtrar y validar issues
$issuesValidos = [System.Collections.Generic.List[object]]::new()
$descartados = 0

foreach ($issue in @($rawIssues)) {
    if ($null -eq $issue.number -or $null -eq $issue.title -or [string]::IsNullOrWhiteSpace([string]$issue.title)) {
        $descartados++
        continue
    }
    $issuesValidos.Add($issue)
}

$fecha = (Get-Date).ToString("dd/MM/yyyy")
$contenidoMarkdown = Formatear-Backlog -issues $issuesValidos -nombreProyecto $nombreProyecto -fecha $fecha

$docsDir = Join-Path $resolvedProject "docs"
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir -Force | Out-Null
}

$backlogPath = Join-Path $docsDir "backlog.md"
[System.IO.File]::WriteAllText($backlogPath, $contenidoMarkdown, [System.Text.UTF8Encoding]::new($false))

if ($descartados -gt 0) {
    Write-Host "Issues descartados por datos incompletos: $descartados."
}

Write-Host "Backlog generado: docs/backlog.md ($($issuesValidos.Count) issues)."
exit 0
