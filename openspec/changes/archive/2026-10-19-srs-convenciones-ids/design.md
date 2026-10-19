## Context

El SRS de `sdd-global-config` se regeneró varias veces con un script auxiliar fuera del repo que aplica dos convenciones (orden de capabilities por ID y casos de uso `CU-<ID del requirement>.<n>`) que la spec `srs-generation` y la skill `srs-generate` no mencionan. La spec solo exige que el título del caso de uso cite el ID del requirement. Quien regenere el SRS solo con la skill no tiene cómo conocer esas reglas.

## Goals / Non-Goals

**Goals:**
- Dejar escritas en la spec y en la skill las dos convenciones, con escenarios verificables.
- Que los IDs de casos de uso no cambien al agregar capabilities o requirements.

**Non-Goals:**
- Persistir los IDs de casos de uso en `docs/srs.meta.yaml`: derivan del ID del requirement, que sí está persistido.
- Cambiar el SRS ya generado: ya cumple las reglas.
- Versionar el script auxiliar.

## Decisions

**D1. El ID del caso de uso se deriva, no se guarda.** `CU-<ID del requirement>.<n>` con `<n>` = posición del escenario dentro de su requirement. Como el ID del requirement es estable (ya persistido), el del caso de uso también lo es frente a capabilities y requirements nuevos. Alternativa descartada: numeración correlativa global, que se desplaza cada vez que se agrega algo antes.

**D2. Las capabilities se ordenan por ID jerárquico.** Una capability nueva toma el siguiente número libre y va al final, aunque su nombre sea alfabéticamente anterior. Alternativa descartada: orden alfabético, que haría que el orden y los IDs divergieran.

**D3. Límite conocido: insertar un escenario en el medio de un requirement desplaza `<n>` de los siguientes de ese requirement.** Se acepta: es poco frecuente y queda acotado a un requirement. Se documenta en la skill para que quien agregue escenarios los ponga al final.

**D4. La Matriz de Trazabilidad cita los dos IDs** (`CU-…` y requirement), como ya hace el SRS actual.

**D5. Cambios en la skill:** secciones 3.3 (orden por ID), 4.1/4.3 (ID y título del caso de uso) y 4.4 (matriz), con el mismo texto que la spec.

## Security Layer

Proyecto `tooling`: los artefactos modificados son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en la spec ni en la skill.
- El cambio a la skill se commitea aparte, con la descripción del impacto (regla de `tooling/config`).
- No se modifica ningún archivo fuera del repo salvo la copia instalada de la skill en `~/.claude/skills/srs-generate/`.

## Risks / Trade-offs

- Una sesión con la skill vieja instalada sigue sin las reglas hasta que se copie la nueva: la tarea de instalación lo cubre en esta máquina y el README ya indica copiar `skills\*` en las otras.
- D3: insertar escenarios en el medio de un requirement cambia IDs de casos de uso de ese requirement.

## Migration Plan

No hay migración: el SRS existente ya sigue las reglas. Reinstalar la skill en `~/.claude/skills/srs-generate/`.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Identificadores jerárquicos estables / Orden de las capabilities por ID | manual: requiere un repo descartable fuera de este. Pasos: crear dos specs (`beta`, `gamma`), generar el SRS con la skill, agregar una spec `alfa` y regenerar; confirmar que `alfa` queda después de `beta` y `gamma` y que sus IDs no cambiaron | `skills/srs-generate/SKILL.md` |
| S02 | Identificadores jerárquicos estables / ID de caso de uso derivado del requirement | manual: mismo repo. Pasos: en el SRS generado, confirmar que un requirement con dos escenarios tiene `CU-<ID>.1` y `CU-<ID>.2` | `skills/srs-generate/SKILL.md` |
| S03 | Identificadores jerárquicos estables / Los IDs de casos de uso no cambian al agregar capabilities | manual: mismo repo. Pasos: comparar los `CU-…` de `beta` y `gamma` antes y después de agregar `alfa` | `skills/srs-generate/SKILL.md` |
| S04 | Matriz de Trazabilidad / La matriz cita los IDs de caso de uso y de requirement | manual: mismo repo. Pasos: leer 3.7 y confirmar `CU-…` y el ID del requirement en cada fila | `skills/srs-generate/SKILL.md` |
| S05 | Identificadores jerárquicos estables / Caso de Uso cita su requirement | manual: revisión de contenido. Pasos: buscar en la skill instalada la regla del título del caso de uso con ID `CU-` y el ID del requirement | `skills/srs-generate/SKILL.md` |

## Open Questions

Sin preguntas abiertas.
