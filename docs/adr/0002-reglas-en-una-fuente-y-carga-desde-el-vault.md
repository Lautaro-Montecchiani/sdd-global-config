# 0002. Reglas en una sola fuente y carga de Claude desde el vault

Estado: aceptada
Fecha: 2026-11-12
Change: reglas-fuente-unica-y-carga-desde-vault
Reemplaza a: 0001

## Contexto

El ADR 0001 dejó las plantillas del Agente generadas desde `templates/fuente/` con PowerShell 7, pero decidió no generar el `CLAUDE.md`: sus 8 reglas de ejecución quedaron escritas a mano en tercera persona y el CI solo comparaba los títulos. Los dos textos ya diferían en la redacción y nada avisaba si divergían en el fondo. Además, Claude leía las reglas desde `~/.claude/CLAUDE.md` y el Agente desde el espejo del vault, y `instalar.ps1` pisaba el espejo sin compararlo.

## Alternativas

- **Dejar las dos redacciones y comparar solo títulos:** es lo que había; no detecta un cambio de fondo en una sola copia.
- **Redactar el fragmento en infinitivo neutral:** obliga a reescribir las cuatro plantillas y sus tests; la segunda persona ya sirve para el Agente y Claude la entiende igual.
- **Generar el `CLAUDE.md` entero desde un esqueleto:** mueve todo el archivo a `templates/fuente/` por 8 líneas compartidas.
- **Editar las reglas en el vault:** el vault se pushea directo, sin PR ni CI, y el generador y sus tests viven en el repo.
- **Que Claude siga leyendo de `~/.claude/CLAUDE.md`:** mantiene dos caminos para el mismo texto y obliga a instalar en cada máquina para ver reglas nuevas.
- **Acceso directo (junction) de `~/.claude` al vault:** suma un objeto que el manifiesto no ve y que los tests no pueden crear sin permisos.

## Decisión

Se mantiene del ADR 0001: las partes compartidas viven en `templates/fuente/`, `scripts/generar-plantillas.ps1` (PowerShell 7, sin librerías externas) genera las plantillas y los comandos, `-Comprobar` hace fallar el CI ante diferencias, y la instalación por máquina y la sincronización por proyecto son scripts con chequeo de cambios locales.

Cambia: las 8 reglas de ejecución del Agente se escriben solo en `templates/fuente/fragmentos/reglas-ejecucion.md`. El generador las pega en `.claude/CLAUDE.md` dentro de un bloque entre marcas y `-Comprobar` compara el texto completo. El repo `sdd-global-config` es la única fuente de las reglas. Con vault, `instalar.ps1` deja en `~/.claude/CLAUDE.md` un archivo que importa el espejo del vault, y Claude y el Agente leen el mismo archivo. `instalar.ps1` es el único que escribe el espejo: lo compara antes, frena si fue editado a mano o si el repo local está atrasado, y tiene un modo `-Comprobar`. Sin vault instala la copia completa.

## Consecuencias

- Positivas: una regla del Agente se edita en un solo archivo; cualquier diferencia de texto falla en el PR; Claude y el Agente leen el mismo archivo; las reglas llegan a otra máquina con el pull del vault; el espejo no se pisa ni se desvía en silencio.
- Negativas: el bloque del `CLAUDE.md` no se edita a mano; Claude depende del vault para cargar las reglas (se mitiga con la instrucción del archivo de carga y con la copia completa sin vault); la ruta del vault queda escrita en `~/.claude/CLAUDE.md` de cada máquina; las skills siguen llegando solo con `instalar.ps1` y pueden quedar desparejas con las reglas; el import `@` es un mecanismo de Claude Code que puede cambiar.
