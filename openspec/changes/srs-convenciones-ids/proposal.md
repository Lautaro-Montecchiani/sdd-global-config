## Why

El SRS de este repo se regenera con dos convenciones que hoy no están escritas en la spec `srs-generation` ni en la skill `srs-generate`: las capabilities se ordenan por su ID jerárquico (no por nombre de carpeta) y cada caso de uso lleva un ID propio `CU-<ID del requirement>.<n.º de escenario>`. Solo viven en un script auxiliar y en el `context.md` del vault. Si otra sesión regenera el SRS siguiendo solo la skill, puede numerar los casos de uso de forma correlativa o reordenar las capabilities alfabéticamente, y los IDs ya publicados cambian, lo que rompe la promesa de IDs estables.

## What Changes

- La spec `srs-generation` define el orden de las capabilities en 3.5/3.6 (por ID jerárquico, no alfabético) y el ID de cada caso de uso (`CU-<ID del requirement>.<n>`, con `<n>` = posición del escenario dentro de su requirement), y exige que esos IDs no cambien al agregar capabilities o requirements.
- La Matriz de Trazabilidad (3.7) cita el ID del caso de uso junto con el ID del requirement.
- La skill `srs-generate` incorpora las mismas reglas (secciones 3.3, 4.1, 4.3 y 4.4).
- Sin cambios para quien ya regeneró el SRS con el script: el documento actual ya cumple estas reglas.

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `srs-generation`: requirement "Identificadores jerárquicos estables" (orden de capabilities e ID de casos de uso) y requirement "Matriz de Trazabilidad" (cita el ID del caso de uso).

## Impact

- `skills/srs-generate/SKILL.md` (y su copia instalada en `~/.claude/skills/srs-generate/`).
- Spec `openspec/specs/srs-generation/spec.md`, que se sincroniza al archivar.
- Afecta a todos los proyectos que generan SRS con la skill: la próxima regeneración usa las reglas nuevas. No cambia ningún SRS ya generado.
