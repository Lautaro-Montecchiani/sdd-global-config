# tests/aclarar-k2.Tests.ps1

. "$PSScriptRoot/apoyo.ps1"

$repoRoot = (Resolve-Path "$PSScriptRoot/..").Path

function Extraer-FilaK2 {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return "" }
    $txt = (Get-Content -Path $Path -Raw -Encoding UTF8) -replace "\r\n", "`n"
    $m = [regex]::Match($txt, "(?m)^\|[ \t]*K2[ \t]*\|(.*?)\|$")
    if ($m.Success) {
        return $m.Value.Trim()
    }
    return ""
}

# test-plan: aclarar-k2/S01
Probar "S01 texto de K2 en CLAUDE.md, skill y comandos" {
    $archivos = @(
        "$repoRoot/.claude/CLAUDE.md",
        "$repoRoot/skills/odd-change/SKILL.md",
        "$repoRoot/.claude/commands/odd.md",
        "$repoRoot/.claude/commands/odd/start.md",
        "$repoRoot/.claude/commands/odd/verify.md"
    )

    $filas = @()
    foreach ($a in $archivos) {
        Afirmar (Test-Path $a) "Debe existir $a"
        $fila = Extraer-FilaK2 $a
        Afirmar ($fila -ne "") "$a debe contener la fila K2 en la tabla"
        $filas += $fila

        Afirmar ($fila.Contains("lee, valida, transforma, guarda, registra, expone o envía")) "$a fila K2 debe contener 'lee, valida, transforma, guarda, registra, expone o envía'"
        Afirmar ($fila.Contains("agrega o quita campos")) "$a fila K2 debe contener 'agrega o quita campos'"
        Afirmar ($fila.Contains("Usarlo igual que antes no cumple K2")) "$a fila K2 debe contener 'Usarlo igual que antes no cumple K2'"
        Afirmar ($fila.EndsWith("**no** |")) "$a fila K2 debe terminar con '**no** |'"
    }

    for ($i = 1; $i -lt $filas.Count; $i++) {
        Afirmar ($filas[$i] -eq $filas[0]) "La fila K2 debe ser idéntica entre $($archivos[$i]) y $($archivos[0])"
    }
}

# test-plan: aclarar-k2/S04
Probar "S04 guías tienen versión corta de K2 y visión no contiene la deuda" {
    $guias = @(
        "$repoRoot/docs/workflow.md",
        "$repoRoot/docs/modo-de-uso.md"
    )

    foreach ($g in $guias) {
        Afirmar (Test-Path $g) "Debe existir $g"
        $fila = Extraer-FilaK2 $g
        Afirmar ($fila -ne "") "$g debe contener la fila K2"
        Afirmar ($fila.Contains('Cambia cómo se procesan datos externos o personales (`## Datos`); usarlos igual que antes no cuenta')) "$g debe tener la fila K2 de D2"
    }

    $visionPath = "$repoRoot/docs/arquitectura/vision.md"
    Afirmar (Test-Path $visionPath) "Debe existir docs/arquitectura/vision.md"
    $visionTxt = Get-Content -Path $visionPath -Raw -Encoding UTF8
    Afirmar (-not $visionTxt.Contains("el criterio K2 no dice")) "docs/arquitectura/vision.md no debe contener 'el criterio K2 no dice'"
}

if ($script:HayFallas) {
    exit 1
} else {
    exit 0
}
