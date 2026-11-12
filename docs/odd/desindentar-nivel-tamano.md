---
tipo: odd
nombre: desindentar-nivel-tamano
creado: 2026-11-12
estado: verificado
branch: odd/desindentar-nivel-tamano
---

## Objetivo
En la sección "Legacy method" de la skill de verify, **Nivel** y **Tamaño** quedan al mismo nivel de lista que **Files**, **Imports** y **Tool**, igual que en el flujo con Test Plan.

## Problema
En `skills/openspec-verify-change/SKILL.md`, dentro de "Legacy method", **Files**, **Imports** y **Tool** tienen 3 espacios de sangría, pero **Nivel** y **Tamaño** tienen 5. Por eso se leen como sub-ítems de **Tool**, cuando son controles hermanos. El mismo texto llega a `.claude/commands/opsx/verify.md`, que se genera desde la skill.

## Alcance
- Incluye: quitar 2 espacios de sangría a la línea de **Nivel**, a la de **Tamaño** y a sus tres sub-ítems (Code extensions, Exclusions y Severities) en la sección "Legacy method", y regenerar el comando.
- No incluye: cambios de texto, la sección del flujo con Test Plan (ya está bien) ni otras skills.
- Cambio de spec: ninguno.
- Archivos permitidos: `skills/openspec-verify-change/SKILL.md`, `.claude/commands/opsx/verify.md`, `docs/odd/desindentar-nivel-tamano.md`.

## Clasificación
ODD. Se evaluaron los criterios de K1 a K10 y no se cumple ninguno:
- No cambia el comportamiento descrito en una spec, porque es solo formato (K1).
- No toca datos (K2) ni seguridad (K3).
- No cambia dependencias (K4), contratos (K5) ni arquitectura (K6).
- Toca 2 archivos, y uno se genera del otro (K7).
- El "qué" está claro (K8).
- No cumple ningún criterio de ADR (K10).

## Checklist
- [x] 1. En `skills/openspec-verify-change/SKILL.md`, sección "Legacy method", quitar 2 espacios de sangría a las líneas que empiezan con `- **Nivel**:` y `- **Tamaño**:` y a sus sub-ítems `- Code extensions:`, `- Exclusions:` y `- Severities:`. No cambiar ninguna palabra.
- [x] 2. Regenerar con `pwsh scripts/generar-plantillas.ps1`. Solo tiene que cambiar `.claude/commands/opsx/verify.md`.
- [x] 3. Correr `pwsh scripts/generar-plantillas.ps1 -Comprobar` y la suite `pwsh -NoProfile -File tests/ejecutar.ps1`.

## Criterios de aceptación
- CA1: en la sección "Legacy method" de la skill y del comando, **Files**, **Imports**, **Tool**, **Nivel** y **Tamaño** tienen la misma sangría, y los sub-ítems de **Tamaño** tienen 2 espacios más. — Evidencia esperada: salida de `Select-String` con la sangría de esas líneas, antes y después.
- CA2: el diff solo cambia espacios al comienzo de esas líneas. — Evidencia esperada: salida de `git diff --stat` y de `git diff -w` (vacío para los dos archivos).
- CA3: la generación y los tests siguen en verde. — Evidencia esperada: salida de `-Comprobar` con código 0 y salida de la suite con código 0.

## Evidencia

### Por tarea
- **Tarea 1:** Se desindentaron 2 espacios en `skills/openspec-verify-change/SKILL.md` (líneas 254 a 258). La sección Test Plan (líneas 82 a 86) se mantuvo intacta.
- **Tarea 2:** Ejecutado `pwsh scripts/generar-plantillas.ps1`. Solo cambió `.claude/commands/opsx/verify.md` y `skills/openspec-verify-change/SKILL.md`.
- **Tarea 3:** `pwsh scripts/generar-plantillas.ps1 -Comprobar` OK (código 0) y suite completa `pwsh -NoProfile -File tests/ejecutar.ps1` con 78 tests OK (código 0).

### Por criterio de aceptación
- **CA1 (sangría antes y después):**
```powershell
# Antes:
C:\...\skills\openspec-verify-change\SKILL.md:248:   - **Files**: ...
C:\...\skills\openspec-verify-change\SKILL.md:249:   - **Imports**: ...
C:\...\skills\openspec-verify-change\SKILL.md:253:   - **Tool**: ...
C:\...\skills\openspec-verify-change\SKILL.md:254:     - **Nivel**: ...
C:\...\skills\openspec-verify-change\SKILL.md:255:     - **Tamaño**: ...
C:\...\skills\openspec-verify-change\SKILL.md:256:       - Code extensions: ...
C:\...\skills\openspec-verify-change\SKILL.md:257:       - Exclusions: ...
C:\...\skills\openspec-verify-change\SKILL.md:258:       - Severities: ...
C:\...\.claude\commands\opsx\verify.md:245:   - **Files**: ...
C:\...\.claude\commands\opsx\verify.md:246:   - **Imports**: ...
C:\...\.claude\commands\opsx\verify.md:250:   - **Tool**: ...
C:\...\.claude\commands\opsx\verify.md:251:     - **Nivel**: ...
C:\...\.claude\commands\opsx\verify.md:252:     - **Tamaño**: ...
C:\...\.claude\commands\opsx\verify.md:253:       - Code extensions: ...
C:\...\.claude\commands\opsx\verify.md:254:       - Exclusions: ...
C:\...\.claude\commands\opsx\verify.md:255:       - Severities: ...

# Después:
C:\...\skills\openspec-verify-change\SKILL.md:248:   - **Files**: ...
C:\...\skills\openspec-verify-change\SKILL.md:249:   - **Imports**: ...
C:\...\skills\openspec-verify-change\SKILL.md:253:   - **Tool**: ...
C:\...\skills\openspec-verify-change\SKILL.md:254:   - **Nivel**: ...
C:\...\skills\openspec-verify-change\SKILL.md:255:   - **Tamaño**: ...
C:\...\skills\openspec-verify-change\SKILL.md:256:     - Code extensions: ...
C:\...\skills\openspec-verify-change\SKILL.md:257:     - Exclusions: ...
C:\...\skills\openspec-verify-change\SKILL.md:258:     - Severities: ...
C:\...\.claude\commands\opsx\verify.md:245:   - **Files**: ...
C:\...\.claude\commands\opsx\verify.md:246:   - **Imports**: ...
C:\...\.claude\commands\opsx\verify.md:250:   - **Tool**: ...
C:\...\.claude\commands\opsx\verify.md:251:   - **Nivel**: ...
C:\...\.claude\commands\opsx\verify.md:252:   - **Tamaño**: ...
C:\...\.claude\commands\opsx\verify.md:253:     - Code extensions: ...
C:\...\.claude\commands\opsx\verify.md:254:     - Exclusions: ...
C:\...\.claude\commands\opsx\verify.md:255:     - Severities: ...
```

- **CA2 (diff solo espacios):**
```powershell
PS> git diff --stat
 .claude/commands/opsx/verify.md        | 10 +++++-----
 skills/openspec-verify-change/SKILL.md | 10 +++++-----
 2 files changed, 10 insertions(+), 10 deletions(-)

PS> git diff -w
(vacío)
```

- **CA3 (generación y tests en verde):**
```powershell
PS> pwsh scripts/generar-plantillas.ps1 -Comprobar
OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados. (código 0)

PS> pwsh -NoProfile -File tests/ejecutar.ps1
...
OK S19 Estado del archive del ODD en el vault y en el PR / PR de un ODD
78 tests OK (código 0)
```

## Progreso
2026-11-12: documento redactado — Claude.
2026-11-12: implementación completada con checklist y criterios en verde — Agente.
2026-11-12: /odd:verify sin CRITICAL; puerta: dato inesperado no aplica (ODD), seguridad sí, explicabilidad sí. WARNING: commit con tipo `style:` fuera de la lista permitida (no se reescribe porque la rama ya está pusheada) — Claude.

## Próximo paso
Merge del PR y después `/odd:close desindentar-nivel-tamano`.
