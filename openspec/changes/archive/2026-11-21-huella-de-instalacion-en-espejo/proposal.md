Issue: #53

## Why

Desde el ADR 0002, las reglas llegan a otra máquina con el pull del vault, pero las skills, los comandos y los archivos de Antigravity llegan solo con `git pull` del repo y `instalar.ps1`. Hoy `instalar.ps1 -Comprobar` avisa `repo atrasado` cuando el espejo del vault viene de un commit que el repo local no tiene, pero un change que toca **solo** skills o comandos no cambia el cuerpo del espejo: `instalar.ps1` lo deja `igual`, no hay commit en el vault y la otra máquina sigue con las skills viejas sin ningún aviso. Además, si el repo local está atrasado y el cuerpo del espejo coincide con su `CLAUDE.md`, el espejo se clasifica `atrasado` y `instalar.ps1` lo reescribe con un commit más viejo.

## What Changes

- **Huella de lo que se instala:** `instalar.ps1` calcula un hash de las fuentes que copia a cada máquina (`skills/`, `.claude/commands/` y los archivos de `templates/antigravity/` que instala) y lo escribe en el encabezado del espejo `_global/reglas-globales.md` como `instalacion: <hash>`. Si cambia una skill o un comando, el espejo deja de estar `igual` y se reescribe con el commit nuevo.
- **Orden de clasificación del espejo:** un espejo cuyo `commit:` no existe en el repo local pasa a ser `repo atrasado` antes de comparar el cuerpo, así una máquina atrasada nunca reescribe el espejo con un commit más viejo.
- **Mensaje de `-Comprobar`:** con `repo atrasado`, la salida dice que otra máquina instaló reglas, skills o comandos nuevos y pide `git pull` en el repo y `instalar.ps1`.
- **Texto de las reglas y las guías:** `.claude/CLAUDE.md` (inicio de sesión), `README.md` y `docs/modo-de-uso.md` explican qué significa `repo atrasado` y qué hacer.
- **ADR 0008** con la decisión y su efecto sobre la consecuencia negativa del ADR 0002; `docs/arquitectura/vision.md` suma el ADR y quita la deuda #53 de la hoja de ruta.

Archivos globales que se modifican y por qué: `scripts/instalar.ps1` y `scripts/comun.ps1` instalan y escriben el espejo del vault en cada máquina; `.claude/CLAUDE.md` tiene las reglas globales de Claude (paso de inicio de sesión).

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `rules-sync`: el espejo del vault lleva la huella de lo instalado; la clasificación del espejo prioriza `repo atrasado`; `-Comprobar` explica `repo atrasado`; las reglas y las guías documentan el aviso.

## Non-goals

- Instalar skills o comandos automáticamente al iniciar sesión o con el pull del vault: se sigue instalando con `instalar.ps1`, a pedido del usuario.
- Copiar skills o comandos al vault, o distribuirlos como plugin de Claude Code (alternativas descartadas en el ADR 0008).
- La huella en los archivos generados de cada proyecto y su control en `pr-check.yml`: es el issue #58.
- Que `.claude/CLAUDE.md` se cargue dos veces en este repo: es el issue #54.
- La barra de estado `.claude/statusline.sh`: se usa desde el repo, así que llega con `git pull` y no entra en la huella.

## Impact

- `scripts/instalar.ps1` (encabezado y clasificación del espejo, mensaje de `-Comprobar`) y `scripts/comun.ps1` (cálculo de la huella).
- La primera vez que cada máquina corre `instalar.ps1` después del merge, el espejo figura `atrasado` (le falta la línea `instalacion:`) y se reescribe sin `-Forzar`: un commit `chore: sdd-global-config — sync reglas` en el vault.
- Retrocompatible: los espejos sin línea `instalacion:` siguen reconociéndose; los tests existentes de `tests/instalar.Tests.ps1` no cambian.
- Las máquinas reciben el `CLAUDE.md` nuevo con `git pull` e `instalar.ps1`.
