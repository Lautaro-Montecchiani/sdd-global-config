# tests/generar-plantillas.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path
$antesDir = "$PSScriptRoot/datos/plantillas-antes"

function Limpiar-PlantillaParaC01 {
    param([string]$Texto)
    $t = $Texto -replace "\r\n", "`n"
    $aviso = '<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->'
    
    if ($t.StartsWith($aviso + "`n`n")) {
        $t = $t.Substring(($aviso + "`n`n").Length)
    } elseif ($t.StartsWith($aviso + "`n")) {
        $t = $t.Substring(($aviso + "`n").Length)
    } elseif ($t -match "(?s)^(---\n.*?\n---\n\n)$([regex]::Escape($aviso))\n\n(.*)$") {
        $t = $matches[1] + $matches[3]
    }
    
    $idxPropio = $t.IndexOf("`n## Propio del proyecto")
    if ($idxPropio -ge 0) {
        $t = $t.Substring(0, $idxPropio)
    } elseif ($t.StartsWith("## Propio del proyecto")) {
        $t = ""
    }
    
    return $t.TrimEnd("`n", "`r", " ")
}

# test-plan: sincronizar-reglas/C01
Probar "C01 plantillas sin cambios de texto" {
    $plantillas = @(
        @{ Actual = "$repoRoot/templates/comun/AGENTS.md"; Antes = "$antesDir/AGENTS.md" },
        @{ Actual = "$repoRoot/templates/copilot/copilot-instructions.md"; Antes = "$antesDir/copilot-instructions.md" },
        @{ Actual = "$repoRoot/templates/cursor/sdd-workflow.mdc"; Antes = "$antesDir/sdd-workflow.mdc" },
        @{ Actual = "$repoRoot/templates/antigravity/GEMINI.md"; Antes = "$antesDir/GEMINI.md" }
    )

    foreach ($p in $plantillas) {
        Afirmar (Test-Path $p.Actual) "No existe la plantilla actual $($p.Actual)"
        Afirmar (Test-Path $p.Antes) "No existe la copia de referencia $($p.Antes)"

        $txtActual = Get-Content -Path $p.Actual -Raw -Encoding UTF8
        $txtAntes = Get-Content -Path $p.Antes -Raw -Encoding UTF8

        $limpioActual = Limpiar-PlantillaParaC01 $txtActual
        $limpioAntes = Limpiar-PlantillaParaC01 $txtAntes

        Afirmar ($limpioActual -eq $limpioAntes) "El texto de $($p.Actual) difiere de $($p.Antes)"
    }
}

if ($script:HayFallas) { exit 1 }
