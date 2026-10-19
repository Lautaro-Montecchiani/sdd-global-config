# Tasks

## 1. Skill

- [ ] 1.1 En `skills/srs-generate/SKILL.md`: en la sección 3.3 agregar que las capabilities se ordenan por ID jerárquico y no por nombre (una capability nueva va al final); en 4.1 y 4.3 definir el ID `CU-<ID del requirement>.<n>` con `<n>` = posición del escenario dentro de su requirement, que el título lo cita junto con el ID del requirement, y que insertar un escenario en el medio de un requirement desplaza los siguientes (conviene agregarlos al final); en 4.4 que la matriz cita el `CU-…` y el ID del requirement. Verificar con `grep -n "CU-" skills/srs-generate/SKILL.md` y pegar la salida.

## 2. Instalación

- [ ] 2.1 Copiar `skills/srs-generate` a `~/.claude/skills/srs-generate` y verificar con hash SHA-256, ignorando fin de línea, que la copia instalada coincide con el repo.

## 3. Verificación manual

- [ ] 3.1 S05 — Buscar en la skill instalada la regla del título del caso de uso y pegar las líneas.
- [ ] 3.2 S01, S02, S03, S04 — En un repo descartable fuera de este (`beta` y `gamma` con escenarios, luego `alfa`), generar el SRS con la skill, agregar `alfa`, regenerar y verificar orden, IDs `CU-…`, estabilidad de los IDs y matriz; pegar las líneas relevantes y borrar el repo.
- [ ] 3.3 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[srs-convenciones-ids] Convenciones de IDs y orden del SRS en la spec y la skill` desde `change/srs-convenciones-ids`.
- `/opsx:verify srs-convenciones-ids` en Claude antes del merge; `/opsx:archive srs-convenciones-ids` después.
