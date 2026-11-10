## Why

Cada comando de `.claude/commands/` (`opsx/*` y `odd*`) repite a mano el texto de su skill de `skills/`: son unas 1.300 líneas duplicadas y la paridad se controla a mano en cada apply. Las copias ya se separaron: `opsx/verify.md` tiene bien anidados los controles de arquitectura que la skill tiene mal, `opsx/explore.md` perdió los ejemplos de la skill y la skill perdió el bloque **Input** del comando, y `openspec-apply-change` dice "Implement tasks" mientras el comando anuncia el handoff. Es la deuda `[media]` de `docs/arquitectura/vision.md` y se paga con el mismo mecanismo que ya genera las plantillas (ADR 0001).

## What Changes

- Las skills de `skills/` pasan a ser la única fuente del texto de los comandos. Cada comando tiene en `templates/fuente/comandos/` solo su encabezado (frontmatter) y una marca que dice qué skill (o qué sección de la skill) incluir.
- `scripts/generar-plantillas.ps1` genera también los nueve archivos de `.claude/commands/` (`opsx/apply`, `opsx/archive`, `opsx/explore`, `opsx/propose`, `opsx/verify`, `odd/start`, `odd/verify`, `odd/close` y `odd.md`), y con `-Comprobar` falla si alguno difiere de lo generado. El CI ya corre `-Comprobar`, así que no cambia el workflow.
- Antes de la primera generación se reconcilian las diferencias actuales: lo que solo está en el comando y es correcto pasa a la skill (lista cerrada en el design).
- Los comandos generados llevan un aviso de "no editar a mano" después del frontmatter.
- Se actualiza `docs/arquitectura/vision.md` (componente `.claude/commands/` y se quita la deuda pagada), el README y `docs/workflow.md` donde dicen que los comandos repiten el texto de su skill.

## Non-goals

- No se generan las skills desde otra fuente ni se cambia su contenido más allá de la reconciliación listada en el design.
- No se cambia qué instala `scripts/instalar.ps1` ni `scripts/sincronizar-proyecto.ps1`: los comandos generados siguen commiteados en `.claude/commands/` y se instalan igual.
- No se generan los comandos de Cursor (`.cursor/commands/`) ni las skills de Antigravity: los genera `openspec init`/`openspec update`.
- No se unifica la redacción del `CLAUDE.md` con las plantillas (deuda `[baja]` aparte).
- No se cambia el comportamiento de ningún comando `/opsx:*` ni `/odd*` salvo las correcciones de la reconciliación.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `rules-sync`: suma la generación de los comandos de Claude desde las skills, y el control de desincronización pasa a cubrir también `.claude/commands/`.

## Impact

- Archivos globales modificados: `skills/openspec-apply-change/SKILL.md`, `skills/openspec-explore/SKILL.md` y `skills/openspec-verify-change/SKILL.md` (reconciliación), y los nueve archivos de `.claude/commands/` (pasan a ser generados). Se modifican porque son la fuente y la copia que se instalan en `~/.claude/` de cada máquina.
- Script: `scripts/generar-plantillas.ps1`. Fuente nueva: `templates/fuente/comandos/`.
- Tests: `tests/generar-comandos.Tests.ps1` nuevo; los tests existentes que leen `.claude/commands/` (`clasificacion-odd`, `aclarar-k2`) tienen que seguir en verde.
- Otros proyectos: reciben los comandos regenerados al correr `scripts/instalar.ps1`; el contenido de los comandos cambia levemente (texto de la skill en lugar de la copia vieja).
- `## Alcance` de `openspec/config.yaml`: el ítem "generación de .claude/commands/ desde las skills" pasa de `no incluye` a `incluye`.
- Sin dependencias nuevas.
