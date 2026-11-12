# Proposal

## Why

La skill `/arquitectura` solo se corre si alguien se acuerda. En este repo, que `## Arquitectura` no declarara `nivel` quedó como deuda en la hoja de ruta hasta que el usuario lo trajo a mano. Hoy ninguna operación del workflow sugiere correrla: el propose recomienda un nivel solo cuando el change cruza una señal, y el verify no dice nada si falta el `nivel` o si un archivo pasa el umbral de advertencia de `tamaño`.

## What Changes

- Claude **sugiere** correr `/arquitectura` en una línea con el motivo, sin correrla, en cuatro momentos:
  - **Al iniciar sesión:** si `## Arquitectura` no declara `nivel` o declara un valor que no es una receta.
  - **En `/opsx:propose`:** por el mismo motivo, en el resumen final.
  - **En `/opsx:verify`:** si algún archivo del diff supera el umbral de advertencia de `tamaño`.
  - **En la fase del vault de `/opsx:archive`:** si `arquitectura.md` del vault queda con `## Nivel` en "sin evaluar".
- La sugerencia nunca bloquea, nunca es un desvío del verify y no se repite dentro de la misma operación.
- Se actualiza la sección "Al iniciar cada sesión" del `.claude/CLAUDE.md` y la línea de responsabilidades de `/arquitectura`.
- Este repo declara `nivel: 0` y `tamaño: 500, 1000` en `## Arquitectura` de `openspec/config.yaml`, como resultado del diagnóstico con `/arquitectura` que adoptó el usuario. Se registra en el ADR 0003 y sale de la hoja de ruta de `docs/arquitectura/vision.md`.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `architecture-advisor`: se suma el requirement "Claude sugiere la skill arquitectura", con los momentos en que se sugiere y los casos en que no.

## Non-goals

- Correr `/arquitectura` automáticamente o escribir `## Arquitectura` sin aprobación.
- Detectar señales de las recetas en el verify, fuera del tamaño. Las demás señales las sigue detectando el propose con su `## Recomendación de arquitectura`.
- Cambiar los controles de arquitectura del verify (`project-architecture`): el tamaño se sigue reportando igual, y la sugerencia se suma al final del reporte.
- Mover código de `scripts/`: el nivel 0 no pide reglas ni carpetas nuevas.

## Impact

- Archivos globales modificados:
  - `.claude/CLAUDE.md`: inicio de sesión y responsabilidades de `/arquitectura`. Se distribuye con `scripts/instalar.ps1` después del merge.
  - Skills `openspec-propose`, `openspec-verify-change` y `openspec-archive-change`, más sus comandos generados.
- Archivos de este repo: `openspec/config.yaml` (`nivel` y `tamaño`), `docs/adr/0003-…md` (nuevo) y `docs/arquitectura/vision.md`.
- Proyectos existentes: los que no declaran `nivel` van a ver la sugerencia al iniciar sesión y en cada propose hasta que corran `/arquitectura`. No bloquea nada.
- Sin dependencias nuevas.
