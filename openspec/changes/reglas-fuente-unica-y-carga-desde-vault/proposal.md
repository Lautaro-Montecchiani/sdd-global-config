# Proposal

## Why

Las 8 reglas de ejecución del Agente están escritas dos veces en este repo: en `templates/fuente/fragmentos/reglas-ejecucion.md` (en segunda persona, de ahí salen las cuatro plantillas) y a mano en `.claude/CLAUDE.md` (en tercera persona). El control del CI solo compara los títulos, así que el texto ya difiere en la redacción y puede divergir en el fondo sin que nada avise: el Agente implementaría con una regla y Claude verificaría con otra.

Además, Claude y el Agente leen las mismas reglas por dos caminos distintos: Claude desde `~/.claude/CLAUDE.md` y el Agente desde el espejo del vault (`_global/reglas-globales.md`). Cada máquina necesita correr `instalar.ps1` para que Claude vea reglas nuevas, y `instalar.ps1` hoy pisa el espejo sin compararlo.

## What Changes

**Parte 1: una sola fuente para las 8 reglas**

- `.claude/CLAUDE.md` pasa a tener las 8 reglas dentro de un bloque entre dos marcas. El bloque lo escribe `scripts/generar-plantillas.ps1` desde `templates/fuente/fragmentos/reglas-ejecucion.md`. La redacción queda en segunda persona, igual que en las plantillas.
- `generar-plantillas.ps1 -Comprobar` compara el texto completo del bloque contra el fragmento. Reemplaza la comparación de títulos.
- **BREAKING** para quien edita reglas: el bloque de `.claude/CLAUDE.md` deja de editarse a mano. Se edita el fragmento y se regenera.

**Parte 2: Claude lee las reglas desde el vault**

- Con vault, `scripts/instalar.ps1` instala en `~/.claude/CLAUDE.md` un archivo de carga mínimo que importa con `@` el espejo del vault de esa máquina. Sin vault, instala la copia completa como hoy.
- El espejo se arma desde `.claude/CLAUDE.md` del repo (hoy sale del archivo instalado) y registra el commit del repo.
- `instalar.ps1` compara el espejo antes de escribirlo. Si fue editado a mano, frena sin tocar nada; con `-Forzar` lo respalda y lo restaura. Si el espejo viene de un commit que el repo local no tiene, frena y pide actualizar el repo.
- `instalar.ps1 -Comprobar` (nuevo): dice si `~/.claude` y el espejo coinciden con el repo, sin escribir nada.
- El texto de `.claude/CLAUDE.md` declara al repo `sdd-global-config` como única fuente de las reglas y cambia el chequeo de inicio de sesión por `instalar.ps1 -Comprobar`.

**Arquitectura y documentación**

- ADR 0002, que reemplaza al 0001 (el 0001 decidía no generar el `CLAUDE.md`).
- `docs/arquitectura/vision.md`, `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md` actualizados.

### Archivos globales que se modifican y por qué

- `.claude/CLAUDE.md` (reglas globales de Claude): recibe el bloque generado y el texto nuevo sobre la fuente única.
- `~/.claude/CLAUDE.md` de cada máquina: lo escribe `instalar.ps1`; con vault pasa a ser el archivo de carga.
- `_global/reglas-globales.md` del vault: lo escribe solo `instalar.ps1`; cambia su encabezado y pasa a ser lo que lee Claude.

## Non-goals

- Achicar el `CLAUDE.md` global.
- Distribuir las skills o los comandos por el vault: siguen llegando con `instalar.ps1`.
- Actualizar todos los proyectos con una sola orden (`sincronizar-proyecto.ps1` sigue siendo por proyecto).
- Cambiar el contenido de las 8 reglas: solo cambia la redacción de la copia del `CLAUDE.md`, que pasa a ser la del fragmento.
- Cambiar las cuatro plantillas del Agente o sus esqueletos.
- Regenerar `docs/modo-de-uso.docx`.
- Proteger el espejo con permisos de GitHub (no disponible en repos privados del plan gratuito).

## Capabilities

### New Capabilities

Ninguna.

### Modified Capabilities

- `rules-sync`: el control de desincronización compara el texto completo del bloque de reglas del `CLAUDE.md`; el `CLAUDE.md` tiene un bloque generado; la instalación por máquina instala un archivo de carga cuando hay vault; el espejo del vault se arma desde el repo y se compara antes de escribirse; se agrega la comprobación de la instalación y la declaración del repo como fuente única.

## Impact

- **Scripts:** `scripts/generar-plantillas.ps1`, `scripts/instalar.ps1` y, si hace falta una función compartida, `scripts/comun.ps1`.
- **Tests:** `tests/generar-plantillas.Tests.ps1`, `tests/instalar.Tests.ps1` y `tests/clasificacion-odd.Tests.ps1` (su test S20 exige hoy una oración distinta en el `CLAUDE.md` y en el fragmento).
- **Reglas:** `.claude/CLAUDE.md`.
- **Documentación:** `docs/adr/0001-…`, `docs/adr/0002-…` (nuevo), `docs/arquitectura/vision.md`, `README.md`, `docs/workflow.md`, `docs/modo-de-uso.md`.
- **Máquinas:** después del merge hay que correr `pwsh scripts/instalar.ps1` en cada una. La copia completa instalada se reconoce como versión anterior y se reemplaza sin `-Forzar`.
- **Otros proyectos:** no cambia ningún archivo de los proyectos. Las plantillas del Agente no cambian.
- **Dependencia no verificada:** que el import `@` de Claude Code acepte una ruta absoluta de Windows fuera de `~/.claude`. Es la primera tarea del change; si falla, el Agente frena.
