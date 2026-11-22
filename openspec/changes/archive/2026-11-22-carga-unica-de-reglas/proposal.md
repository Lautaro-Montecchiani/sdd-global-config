Issue: #54

## Why

Cuando Claude Code se abre en este repo carga las reglas globales dos veces: una desde `~/.claude/CLAUDE.md` (que importa el espejo del vault) y otra desde `.claude/CLAUDE.md` del repo, que Claude Code toma como instrucciones del proyecto. Son más de 4.000 palabras duplicadas en el contexto. Además, en una rama que edita las reglas, las dos copias difieren y Claude recibe dos versiones contradictorias de la misma regla.

## What Changes

- **`.claude/settings.json` nuevo y versionado** con `claudeMdExcludes: ["**/sdd-global-config/.claude/CLAUDE.md"]`. Claude Code deja de cargar la copia del repo y en este repo usa solo las reglas instaladas, igual que en cualquier otro proyecto. El patrón no coincide con `~/.claude/CLAUDE.md`, así que las reglas globales se siguen cargando.
- **`README.md`**: explica que en este repo Claude carga solo las reglas instaladas, que la carpeta del clon tiene que llamarse `sdd-global-config` y que para probar reglas editadas en una rama hay que correr `instalar.ps1` desde esa rama.
- **`docs/arquitectura/vision.md`**: suma `.claude/settings.json` a `## Componentes` y quita la deuda #54 de `## Hoja de ruta`.

Archivo global que se modifica y por qué: ninguno se instala en otras máquinas. `.claude/settings.json` es configuración de proyecto de Claude Code y solo actúa cuando Claude se abre en este repo.

## Capabilities

### New Capabilities
- (ninguna)

### Modified Capabilities
- `rules-sync`: requirements nuevos sobre la carga única de las reglas cuando Claude trabaja en este repo y su documentación en el README.

## Non-goals

- Mover o renombrar la fuente `.claude/CLAUDE.md` (alternativa descartada: toca unos 34 archivos y la detección de versiones viejas por historia de git).
- Excluir el `~/.claude/CLAUDE.md` global en este repo para cargar la copia de la rama.
- Reducir el tamaño del `CLAUDE.md` global: es el issue #55.
- Cambiar `instalar.ps1`, las plantillas o la sincronización por proyecto.

## Impact

- Solo cambia lo que Claude carga al abrirse en este repo; los demás proyectos y el Agente no cambian.
- Una máquina que no corrió `instalar.ps1` queda sin reglas en este repo (antes tenía la copia del repo). El setup del README ya pide `instalar.ps1`, y el inicio de sesión de las reglas lo controla con `-Comprobar`.
- Si el repo se clona en una carpeta con otro nombre, el patrón no coincide y vuelve la carga doble (no se rompe nada).
