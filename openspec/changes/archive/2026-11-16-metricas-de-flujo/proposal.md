Issue: #69

## Why

El tablero Scrumban (#66) ya muestra dónde está cada tarjeta y limita el trabajo en curso, pero no dice cuánto tarda el trabajo en pasar por el flujo ni dónde se traba. Sin esos números, la retro y la review (#70) se basan en impresiones. GitHub ya guarda el historial completo de cada tarjeta (cada cambio de columna con su fecha y su Project), así que las métricas se pueden calcular sin anotar nada a mano.

## What Changes

- Script nuevo `scripts/metricas.ps1` que lee el tablero configurado en `tablero.md` del vault con una consulta GraphQL paginada (`gh api graphql`): las tarjetas, sus fechas de creación y cierre, y sus eventos de cambio de columna, filtrados al Project del tablero (el historial de un issue incluye eventos de otros Projects).
- Calcula para un período (por defecto, las últimas 4 semanas):
  - **Lead time:** creación del issue → cierre.
  - **Cycle time:** primera entrada a Diseño o Construcción → cierre.
  - **Throughput:** issues cerrados por semana.
  - **Tiempo por columna:** promedio de días en cada columna de los issues cerrados en el período.
  - **Trabajo en curso:** tarjetas abiertas en Diseño, Construcción y Revisión con los días que llevan en su columna (envejecimiento).
- Escribe `metricas.md` generado en la raíz del vault (todo el tablero, todos los repos), junto a `tablero.md`. Sin tablero, sin `gh`, sin red o sin permiso, avisa en una línea, no toca el archivo y termina con 0.
- `openspec-archive-change` (fase del vault) y `/odd:close` recalculan las métricas antes de sincronizar el vault. Un aviso del script no frena el cierre.
- Las funciones de configuración y de llamada a `gh` de `scripts/tablero.ps1` pasan a `scripts/tablero-comun.ps1`, compartido por los dos scripts, sin cambiar el comportamiento de `tablero.ps1`.
- `.claude/CLAUDE.md` (sección `## Scrumban` y estructura del vault) y `docs/workflow.md` (guía del tablero) explican las métricas y cómo regenerarlas a mano.

## Capabilities

### New Capabilities
(ninguna)

### Modified Capabilities
- `scrumban-board`: suma requirements de cálculo de métricas de flujo, archivo `metricas.md` y recálculo en el cierre. Los requirements existentes no cambian.

## Non-goals

- Gráficos: el archivo es Markdown con tablas; los gráficos de Insights del Project siguen disponibles en GitHub.
- Métricas por proyecto en cada repo (`docs/metricas.md`): solo hay un archivo global en el vault.
- Pronósticos (Monte Carlo, fechas probables de entrega).
- Cadencias (`/retro` y review): issue #70, que va a usar este archivo.
- Corregir el historial de tarjetas movidas a mano o de Projects cerrados: se cuenta lo que GitHub registró en el tablero configurado.

## Impact

- Archivos globales modificados y por qué:
  - `.claude/CLAUDE.md`: métricas en `## Scrumban` y `metricas.md` en `### Estructura del vault`. Se espeja en el vault con `instalar.ps1`.
  - `skills/openspec-archive-change/SKILL.md` y `skills/odd-change/SKILL.md`: paso de recálculo de las métricas en el cierre. Se regeneran `.claude/commands/opsx/archive.md` y `.claude/commands/odd/close.md`.
- Código: `scripts/metricas.ps1` y `scripts/tablero-comun.ps1` nuevos; `scripts/tablero.ps1` usa el archivo común. Tests nuevos en `tests/metricas-de-flujo.Tests.ps1`; los de `tests/tablero-scrumban.Tests.ps1` siguen sin cambios.
- Documentación: `docs/workflow.md`, `docs/arquitectura/vision.md`.
- `openspec/config.yaml`: `## Datos` suma el historial de movimientos de las tarjetas.
- Vault: archivo nuevo `metricas.md` generado; no se edita a mano.
- Proyectos existentes: no cambian sus archivos; toman el recálculo al correr `instalar.ps1`.
