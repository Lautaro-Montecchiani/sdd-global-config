---
tipo: odd
nombre: deuda-k2
creado: 2026-11-10
estado: abierto
branch: odd/deuda-k2
---

## Objetivo
Que la hoja de ruta de `docs/arquitectura/vision.md` registre la deuda de aclarar el criterio K2.

## Problema
En las pruebas del change `clasificacion-odd-sdd`, Claude razonó K2 de dos maneras distintas para el mismo saludo con el nombre del lead (S01 dijo que no aplica; S02, que aplica por las dudas). La mejora quedó anotada solo en el vault, no en el repo.

## Alcance
- Incluye: una línea nueva en `## Hoja de ruta` de `docs/arquitectura/vision.md`.
- No incluye: cambiar el texto de K2 en las reglas (eso va por SDD: modifica dos capabilities y el `CLAUDE.md` global).
- Cambio de spec: ninguno.
- Archivos permitidos: `docs/arquitectura/vision.md`.

## Clasificación
ODD: solo documentación. K1 no (no toca specs), K2 y K3 no (no toca datos ni seguridad), K4 a K8 no (sin dependencias, contratos ni arquitectura; 1 archivo de documentación; el qué está definido), K9 no, K10 no (no es una decisión de arquitectura: registra una deuda).

## Checklist
- [ ] 1. En `docs/arquitectura/vision.md`, agregar al final de `## Hoja de ruta`: `- [baja] el criterio K2 no dice si usar un dato personal sin cambiar cómo se lee, valida, guarda o expone cuenta como "tocarlo", y Claude lo razona distinto según el pedido — origen: clasificacion-odd-sdd (pruebas S01 y S02) — propuesta: aclarar en K2 que solo cuenta si cambia la lectura, validación, almacenamiento o exposición del dato, en un change SDD que actualice work-classification y el CLAUDE.md global`.

## Criterios de aceptación
- CA1: `## Hoja de ruta` tiene la línea nueva con el formato `- [prioridad] deuda — origen — propuesta` — Evidencia esperada: diff de `docs/arquitectura/vision.md`.
- CA2: el diff contra `master` solo toca `docs/arquitectura/vision.md` y este documento — Evidencia esperada: `git diff --stat master...HEAD`.

## Evidencia

## Progreso
2026-11-10: documento redactado — Claude

## Próximo paso
Implementar la tarea 1.
