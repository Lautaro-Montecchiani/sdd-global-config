# Design

## Context

Lo que hay hoy (observado en el repo y en esta máquina el 14/11/2026):

- `.claude/settings.json` del repo tiene solo `statusLine` con `bash "$(git rev-parse --show-toplevel)/.claude/statusline.sh"`. Funciona dentro de `sdd-global-config` y en ningún otro proyecto.
- `.claude/statusline.sh` (bash que llama a `python3`) arma dos líneas: carpeta, barra de contexto (`█`/`░`, 12 posiciones), barra de cuota de 5 h con `↺<h>h<mm>m`, rama y modelo. `█` y `↺` son de ancho ambiguo (East Asian Width `A`). En la terminal del usuario se dibujan más anchos y la barra se desborda (captura del 14/11/2026).
- `scripts/instalar.ps1` (515 líneas) instala `CLAUDE.md`, skills, comandos, `GEMINI.md` y la skill `odd-apply` de Antigravity, con clasificación `igual`/`atrasado`/`con cambios locales`, manifiesto, `-Forzar`, `-Simular` y `-Comprobar`. No toca ningún `settings.json`.
- Antigravity CLI: `~/.gemini/antigravity-cli/settings.json` tiene `statusLine` con `command` a `.../scratch/statusline.bat` y `"enabled": false`. Los scripts `statusline.bat` y `statusline_new.ps1` existen en `scratch/` (los generó el CLI). La spec `agent-cli-permissions` prohíbe versionarlos.
- El usuario agregó a mano en `~/.claude/settings.json` el `statusLine` con `bash "$SDD_CONFIG_REPO/.claude/statusline.sh"` y la regla `permissions.allow` `PowerShell(agy -p *)`.
- Copilot CLI está instalado (`copilot` en el PATH, `~/.copilot` existe). Según docs.github.com (referencia de la carpeta de configuración), `~/.copilot/settings.json` es la configuración de usuario y admite `statusLine` con `type: "command"`, `command`, `padding` y `refreshInterval`. `config.json` es estado interno y sus valores de usuario se ignoran. Los blogs de la comunidad (mayo 2026) dicen que la entrada trae los mismos nombres que Claude Code (`workspace.current_dir`, `model.display_name`, `context_window.used_percentage`) más `context_window.current_context_used_percentage`, que es el que muestra `/context`. No trae rama ni cuota. Los mismos blogs dicen que hacía falta `/experimental on`; las notas de versión hasta la 1.0.112 ya no lo marcan como experimental.
- Cursor CLI: la documentación oficial no documenta `statusLine` (ver Non-Goals). No está instalado acá.

## Goals / Non-Goals

**Goals:**
- `instalar.ps1` deja la barra de Claude Code, Antigravity CLI y Copilot CLI instalada en cada máquina donde el CLI está presente.
- Una barra propia de la persona nunca se pisa; solo se cambia la clave `statusLine`.
- `-Comprobar` detecta una barra que falta o quedó vieja.
- La barra de Claude y Copilot no se desborda en ninguna terminal.

**Non-Goals:**
- Cursor CLI (issue #63).
- Activar funciones experimentales de Copilot CLI.
- Barra por proyecto.
- Cambiar el formato de la barra de Antigravity (ya está especificado y no usa caracteres de ancho ambiguo).

## Decisions

### D1. Las funciones de la barra van en `scripts/barra-estado.ps1`

`instalar.ps1` ya está en el umbral de aviso de tamaño (deuda #56). Las funciones nuevas van en `scripts/barra-estado.ps1`, que `instalar.ps1` carga con `. "$PSScriptRoot/barra-estado.ps1"` (igual que `comun.ps1`). `instalar.ps1` solo suma la llamada para armar la lista de barras, las filas de la tabla, su lugar en `-Comprobar` y la escritura. Funciones (nombres orientativos; el Agente puede ajustarlos):

- `Obtener-BarrasEsperadas -RepoRoot -Destino`: devuelve una entrada por barra que corresponde instalar, con `Nombre` (`barra Claude`, `barra Antigravity`, `barra Copilot`), `Ruta` del `settings.json`, `Esperada` (el objeto `statusLine`) y la regla para reconocer la barra del repo. Claude siempre; Antigravity si existe `<Destino>/.gemini/antigravity-cli`; Copilot si existe `<Destino>/.copilot`.
- `Clasificar-Barra`: lee el archivo y devuelve `falta` (no hay archivo o no hay `statusLine`), `json inválido`, `igual`, `atrasado` (es la del repo pero difiere de la esperada) o `propia`.
- `Escribir-Barra`: aplica la esperada sobre el `statusLine` existente (conserva las subclaves que no escribe), deja el resto del objeto igual y escribe con `Escribir-ArchivoUtf8SinBom` de `comun.ps1`.

Alternativa descartada: todo dentro de `instalar.ps1`. Lo lleva hacia las 600 líneas, mezclando más lectura de JSON con la clasificación.

### D2. Comandos esperados y cómo se reconoce la barra del repo

| CLI | `settings.json` | `statusLine` esperado | Es la del repo si |
|---|---|---|---|
| Claude Code | `<Destino>/.claude/settings.json` | `{"type":"command","command":"bash \"<repo>/.claude/statusline.sh\""}` | el comando es el esperado o `bash "$SDD_CONFIG_REPO/.claude/statusline.sh"` |
| Antigravity | `<Destino>/.gemini/antigravity-cli/settings.json` | `{"type":"command","command":"<Destino>/.gemini/antigravity-cli/scratch/statusline.bat","enabled":true}` | el comando termina en `/.gemini/antigravity-cli/scratch/statusline.bat` |
| Copilot | `<Destino>/.copilot/settings.json` | `{"type":"command","command":"bash \"<repo>/.claude/statusline.sh\""}` | el comando es el esperado o `bash "$SDD_CONFIG_REPO/.claude/statusline.sh"` |

`<repo>` y `<Destino>` se resuelven al instalar (repo desde `Obtener-RepoRoot`, destino desde `-Destino`) y se escriben con `/`. Las comparaciones de comandos ignoran mayúsculas y normalizan `\` a `/`. La plantilla de Antigravity con el placeholder `{RUTA-DE-TU-USUARIO}` termina en `scratch/statusline.bat`, así que se reconoce como del repo y queda con la ruta real.

Alternativas descartadas para el comando de Claude: copiar `statusline.sh` a `~/.claude/` (otro archivo más en el manifiesto y otra copia; el usuario eligió la ruta del repo) y usar `$SDD_CONFIG_REPO` (si la variable no está en el entorno del CLI, la barra no aparece).

### D3. Una sola barra para Claude Code y Copilot CLI

Copilot CLI manda los mismos campos que usa `statusline.sh`, así que los dos CLI usan el mismo script. El script suma una regla: si viene `context_window.current_context_used_percentage`, lo usa para el contexto. La rama la calcula el script con `git`, así que también sale en Copilot. La cuota solo aparece si viene `rate_limits.five_hour` (Claude).

Alternativa descartada: un script propio para Copilot. Duplica la lógica y va contra el atributo de mantenibilidad.

### D4. Barras solo con caracteres de ancho simple

En `statusline.sh`, `█` pasa a `#`, `░` a `-`, y el reinicio deja de llevar `↺` (queda `4h14m`). Todo es ASCII: ancho 1 en cualquier terminal y fuente. Se mantienen los colores ANSI y las 12 posiciones.

Alternativa descartada: `▰`/`▱` (ancho `N`, no ambiguo). Depende de que la fuente tenga el glifo; con una fuente sin ese glifo, el reemplazo de la terminal puede volver a desbordar.

### D5. Scripts de Antigravity versionados e instalados como archivos

`statusline.bat` y `statusline_new.ps1` se copian tal como están hoy en `~/.gemini/antigravity-cli/scratch/` (ya cumplen la spec y no tienen rutas de la máquina: el `.bat` usa `%USERPROFILE%`) a `templates/antigravity/`. `instalar.ps1` los agrega a su lista de archivos con destino `<Destino>/.gemini/antigravity-cli/scratch/<archivo>`, solo si existe `<Destino>/.gemini/antigravity-cli`, igual que hoy con `GEMINI.md`. Así tienen manifiesto, `atrasado`/`con cambios locales`, `-Forzar` con respaldo y control en `-Comprobar` sin código nuevo. Se agregan los dos a `$rutasRepo` del aviso de cambios sin commitear.

### D6. Estados y salida

- La tabla suma una fila por barra (`settings: barra Claude`, etc.) con `Estado previo` y `Igual` (`sí` solo con `igual`). Las columnas de hash muestran `-`.
- Sin `-Comprobar` ni `-Simular`: `falta` y `atrasado` se escriben después de copiar los archivos. `propia` y `json inválido` no se escriben y muestran `Aviso: <archivo>: barra propia, no se cambia` o `Aviso: <archivo>: json inválido, no se cambia`. Ninguno de los dos corta la instalación ni cambia el código de salida.
- `-Forzar` no afecta a las barras: una `propia` sigue sin tocarse.
- `-Comprobar`: `falta` y `atrasado` entran en la lista de error (código 1); `propia` y `json inválido` solo avisan.
- Los mensajes nombran el archivo con la ruta relativa al destino (por ejemplo `.claude/settings.json`) y no muestran el contenido del archivo.

### D7. Lectura y escritura del JSON

Se lee con `Get-Content -Raw -Encoding UTF8` y `ConvertFrom-Json -AsHashtable` dentro de `try`/`catch`: si falla, es `json inválido`. Un archivo vacío o con solo espacios cuenta como objeto vacío. Se escribe con `ConvertTo-Json -Depth 32` (PowerShell 7 conserva el orden de las claves con `-AsHashtable`), en UTF-8 sin BOM. El formato (sangría) puede cambiar; las claves y valores no.

### D8. Sin `statusLine` en el repo

Se borra `.claude/settings.json` (solo tenía `statusLine`). En `sdd-global-config` la barra sale de la instalación de usuario, como en el resto de los proyectos. Si no se borrara, la del proyecto le gana a la de usuario y habría dos configuraciones para lo mismo.

## Risks / Trade-offs

- **Copilot CLI ejecuta el comando con un shell no documentado.** Los ejemplos de la comunidad usan `bash C:/...` en Windows. → El Agente confirma `statusLine` con `copilot help config` antes de implementar (tarea 1.1) y M01 lo prueba en una sesión real. Si `bash` no anda en Copilot, se frena y se pregunta.
- **Copilot puede pedir `/experimental on`** en algunas versiones. → Queda documentado; `instalar.ps1` no lo activa.
- **`ConvertTo-Json` reformatea el `settings.json`** (sangría y escapes). → Se acepta: las claves y valores no cambian (S09). El archivo solo se escribe cuando la barra está `falta` o `atrasado`.
- **El CLI puede volver a apagar la barra de Antigravity** (por ejemplo, con `/statusline`). → El próximo `instalar.ps1` la prende. Si la persona la quiere apagada, tiene que poner otro comando (queda como `propia`).
- **`bash` o `python3` ausentes** en una máquina: la barra de Claude y de Copilot no aparece, como hoy. No se controla en `-Comprobar`.
- **Ruta del repo con espacios:** el comando va entre comillas dobles; S01 corre con la ruta real del repo.

## Impacto en proyectos existentes

- Ningún archivo de los proyectos cambia. Después de `instalar.ps1`, todos los proyectos muestran la barra de Claude (y la de Copilot y Antigravity si están instalados), porque es configuración de usuario.
- Un proyecto con su propio `statusLine` en `.claude/settings.json` sigue usando el suyo (la configuración de proyecto le gana a la de usuario).
- `~/.claude/settings.json` de cada máquina cambia solo en `statusLine`; los permisos (`permissions.allow`), el modelo y el resto quedan igual (S09).
- Al iniciar sesión, `instalar.ps1 -Comprobar` va a fallar en cada máquina hasta correr `instalar.ps1` (la barra está `falta` o `atrasado`), con el mismo aviso que ya se usa para archivos atrasados.

## Impacto en el sistema

**Componentes afectados:** `scripts/instalar.ps1` y `scripts/comun.ps1` (se reutiliza `Escribir-ArchivoUtf8SinBom`, sin cambios), configuración de usuario de tres CLI en cada máquina (`~/.claude/settings.json`, `~/.gemini/antigravity-cli/settings.json`, `~/.copilot/settings.json`) y la carpeta `~/.gemini/antigravity-cli/scratch/`. Integración nueva con Copilot CLI (escritura de su configuración). Ningún proyecto del workflow cambia sus archivos.

**Atributos de calidad:**
- mantenibilidad (alta): mejora. Un solo script de barra para Claude y Copilot, los scripts de Antigravity pasan a versionarse y a controlarse con `-Comprobar`, y la lógica nueva queda fuera de `instalar.ps1`. — Verificación: S11 y S18, y revisión del diff: un único `statusline.sh` referenciado por las dos barras, y `instalar.ps1` sin funciones de lectura de JSON propias.

**Decisiones de arquitectura:** ADR nuevo: 0005.

**Deuda técnica:**
- agrega: barra de Cursor CLI sin instalar (baja, issue #63).
- descubre: el comando de la barra de Copilot CLI y su posible requisito experimental no están documentados oficialmente (se documenta el riesgo; sin issue aparte, entra en #63 si cambia).
- `instalar.ps1` crece poco (las funciones van en `barra-estado.ps1`); la deuda #56 sigue igual.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `scripts/barra-estado.ps1` | `scripts/` |
| `templates/antigravity/statusline.bat` | `templates/` |
| `templates/antigravity/statusline_new.ps1` | `templates/` |
| `tests/statusline-instalable.Tests.ps1` | `tests/` |
| `docs/adr/0005-instalar-escribe-la-barra-de-estado-de-cada-cli.md` | `docs/` (implícita) |

Archivo borrado: `.claude/settings.json` (carpeta `.claude/`, implícita).

## Security Layer

`project_type: tooling`. Los artefactos modificados son instrucciones y configuración de herramientas de IA.

- No exponer secrets ni rutas personales en lo versionado: el comando con la ruta absoluta se arma al instalar y solo se escribe en la máquina; `statusline.bat`, `statusline_new.ps1`, `barra-estado.ps1` y los tests no contienen `C:\Users`, `C:/Users` ni nombres de usuario. — Verificación: S25 y revisión del diff: búsqueda de `C:\Users`, `C:/Users` y del nombre de la carpeta del usuario en `scripts/`, `templates/` y `tests/`.
- No ejecutar texto leído de archivos: la lectura del `settings.json` es solo `ConvertFrom-Json`, sin `Invoke-Expression` ni `iex`. — Verificación: revisión del diff: sin `Invoke-Expression` ni `iex` en `scripts/barra-estado.ps1`.
- No pisar ni perder configuración de la persona, que en Claude incluye sus permisos (`permissions.allow`): solo cambia `statusLine`, la barra propia se respeta y un JSON inválido no se toca. — Verificación: S08, S09 y S10.
- No mostrar el contenido de los `settings.json` en la salida (puede tener rutas, workspaces o permisos): los avisos nombran solo el archivo. — Verificación: revisión del diff: los `Write-Host` de `barra-estado.ps1` e `instalar.ps1` no imprimen el contenido leído.
- No activar funciones experimentales ni tocar `config.json` de Copilot CLI. — Verificación: S06.
- Los tests no escriben en el `$HOME` real ni en el vault real: usan `-Destino` en una carpeta temporal. — Verificación: revisión del diff: todo test de `statusline-instalable.Tests.ps1` usa `Con-CarpetaTemporal` y `-Destino`.
- Commit separado para los cambios a skills o configuración global: no aplica (no se tocan skills ni `CLAUDE.md`).

## ADR

```markdown
# 0005. instalar.ps1 escribe la barra de estado de cada CLI

Estado: aceptada
Fecha: 2026-11-14
Change: statusline-instalable

## Contexto

La barra de estado de Claude Code vivía en `.claude/settings.json` del repo y solo aparecía dentro de `sdd-global-config`. La de Antigravity CLI se instalaba a mano desde una plantilla con placeholder, y sus scripts los generaba el CLI en cada máquina a partir de un prompt; la spec prohibía versionarlos. Copilot CLI acepta una barra en `~/.copilot/settings.json` y el workflow no la instalaba. Cursor CLI no documenta oficialmente su `statusLine`. `scripts/instalar.ps1` ya era el único camino para dejar una máquina igual a otra (reglas, skills y comandos), pero no escribía en la configuración de ningún CLI.

## Alternativas

- **Seguir con la instalación a mano y el prompt de generación:** descartada. Cada máquina queda distinta, la barra de Antigravity se apagó sola en una máquina sin que nada lo detectara, y la de Claude no aparecía fuera del repo.
- **Instalar la barra en el `settings.json` de cada proyecto (con `sincronizar-proyecto.ps1`):** descartada. La barra es de la persona y no del proyecto, y sumaría un archivo más a cada uno de los 19 proyectos.
- **Que `instalar.ps1` reemplace siempre el `statusLine`:** descartada. Pisa la barra propia de quien ya tiene una.
- **Sumar Cursor CLI ahora:** descartada. Sin claves documentadas oficialmente ni un CLI instalado para probar, habría que inventar el formato (issue #63).

## Decisión

`scripts/instalar.ps1` escribe la clave `statusLine` en el `settings.json` de usuario de cada CLI presente en la máquina (Claude Code siempre; Antigravity CLI y Copilot CLI si existe su carpeta), y solo esa clave. Claude y Copilot apuntan, con la ruta absoluta del repo en esa máquina, al mismo `.claude/statusline.sh`. Los scripts de Antigravity se versionan en `templates/antigravity/` y se instalan como el resto de los archivos, con manifiesto y control de cambios locales. Una barra que no es la del repo se respeta y se avisa; un `settings.json` que no es JSON válido no se escribe. `-Comprobar` falla si una barra falta o quedó vieja.

## Consecuencias

- Positivas: la barra aparece en todos los proyectos y en los tres CLI con un solo `instalar.ps1`; una barra apagada o vieja se detecta al iniciar sesión; hay un único script para Claude y Copilot; la configuración propia de la persona (permisos, modelo, barra propia) no se pierde.
- Negativas: `instalar.ps1` pasa a escribir archivos de configuración de herramientas de terceros, cuyo formato puede cambiar (en especial el de Copilot, documentado solo en parte); la barra depende de que el repo no se mueva de carpeta (si se mueve, `-Comprobar` la marca `atrasado` y se arregla con `instalar.ps1`); Cursor queda sin barra hasta #63.
```

## Test Plan

**Comando:** `pwsh -NoProfile -File tests/ejecutar.ps1` (la suite completa: el change toca `instalar.ps1`, que tiene tests propios en `tests/instalar.Tests.ps1`, y hay que confirmar que no cambian). Cada test automático lleva el marcador `test-plan: statusline-instalable/<ID>` en un comentario. Los tests de instalación usan `Con-CarpetaTemporal` y `-Destino`; los de la barra le pasan la entrada a `bash .claude/statusline.sh` (o a `pwsh -File templates/antigravity/statusline_new.ps1`) y comparan la salida sin secuencias ANSI.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Barra de Claude Code instalada por máquina / Destino sin settings.json | auto | `tests/statusline-instalable.Tests.ps1` |
| S02 | Barra de Claude Code instalada por máquina / Forma anterior con variable de entorno | auto | `tests/statusline-instalable.Tests.ps1` |
| S03 | Barra de Antigravity CLI instalada por máquina / Barra apagada | auto | `tests/statusline-instalable.Tests.ps1` |
| S04 | Barra de Antigravity CLI instalada por máquina / Scripts instalados | auto | `tests/statusline-instalable.Tests.ps1` |
| S05 | Barra de Antigravity CLI instalada por máquina / Sin Antigravity | auto | `tests/statusline-instalable.Tests.ps1` |
| S06 | Barra de Copilot CLI instalada por máquina / Copilot instalado | auto | `tests/statusline-instalable.Tests.ps1` |
| S07 | Barra de Copilot CLI instalada por máquina / Sin Copilot | auto | `tests/statusline-instalable.Tests.ps1` |
| S08 | Convivencia con la configuración propia / Barra propia | auto | `tests/statusline-instalable.Tests.ps1` |
| S09 | Convivencia con la configuración propia / Otras claves intactas | auto | `tests/statusline-instalable.Tests.ps1` |
| S10 | Convivencia con la configuración propia / Dato inválido: settings.json que no es JSON | auto | `tests/statusline-instalable.Tests.ps1` |
| S11 | Comprobación de la barra / Barra al día | auto | `tests/statusline-instalable.Tests.ps1` |
| S12 | Comprobación de la barra / Barra que falta | auto | `tests/statusline-instalable.Tests.ps1` |
| S13 | Comprobación de la barra / Barra propia en la comprobación | auto | `tests/statusline-instalable.Tests.ps1` |
| S14 | Formato de la barra de Claude y Copilot / Entrada de Claude Code | auto | `tests/statusline-instalable.Tests.ps1` |
| S15 | Formato de la barra de Claude y Copilot / Entrada de Copilot CLI | auto | `tests/statusline-instalable.Tests.ps1` |
| S16 | Formato de la barra de Claude y Copilot / Solo caracteres de ancho simple | auto (todo carácter visible de la salida es ASCII imprimible) | `tests/statusline-instalable.Tests.ps1` |
| S17 | Formato de la barra de Claude y Copilot / Dato inválido: entrada que no es JSON | auto | `tests/statusline-instalable.Tests.ps1` |
| S18 | Una sola configuración de la barra en el repo / Sin barra de proyecto | auto | `tests/statusline-instalable.Tests.ps1` |
| S19 | Barra de estado documentada por agente / Matriz actualizada | auto (búsqueda de texto en la fila de Copilot y de Cursor) | `tests/statusline-instalable.Tests.ps1` |
| S20 | Barra de estado documentada por agente / Qué hacer si no aparece | auto (búsqueda de texto) | `tests/statusline-instalable.Tests.ps1` |
| S21 | Barra de estado especificada por comportamiento / Línea con datos completos | auto (`pwsh -File templates/antigravity/statusline_new.ps1`) | `tests/statusline-instalable.Tests.ps1` |
| S22 | Barra de estado especificada por comportamiento / Selección de la cuota | auto | `tests/statusline-instalable.Tests.ps1` |
| S23 | Barra de estado especificada por comportamiento / Entrada inválida | auto | `tests/statusline-instalable.Tests.ps1` |
| S24 | Barra de estado especificada por comportamiento / Barra prendida en la plantilla | auto | `tests/statusline-instalable.Tests.ps1` |
| S25 | Barra de estado especificada por comportamiento / Scripts versionados sin rutas de la máquina | auto | `tests/statusline-instalable.Tests.ps1` |
| S26 | La instalación por máquina está documentada / Pasos de instalación visibles | auto (búsqueda de texto) | `tests/statusline-instalable.Tests.ps1` |
| S27 | La instalación por máquina está documentada / Prompt para generar la barra de estado | auto (búsqueda de texto) | `tests/statusline-instalable.Tests.ps1` |
| M01 | Barra visible en sesiones reales de Claude Code, Antigravity CLI y Copilot CLI | manual (lo corre el usuario): `pwsh scripts/instalar.ps1`, abrir Claude Code en `D:\proyectos\gamma-installer`, `agy` y `copilot`, y confirmar que cada uno muestra su barra sin desbordes | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/instalar.ps1` | La suite actual de `tests/instalar.Tests.ps1` en verde (archivos, manifiesto, `-Forzar`, `-Simular`, `-Comprobar`, espejo del vault) | Ninguno sobre lo que ya hace; las filas nuevas de la tabla las cubren S01 a S13. Si un test actual compara la tabla completa y falla solo por las filas nuevas de la barra, se ajusta para ignorar las filas `settings: barra` y se deja escrito en la evidencia |
| C02 | `.claude/statusline.sh` | Con la entrada de S14, la salida trae el nombre de la carpeta, `50%`, `25%`, la rama entre paréntesis y el modelo en la segunda línea | Los caracteres de las barras y el símbolo del reinicio cambian (lo cubren S14 y S16), y el contexto toma `current_context_used_percentage` cuando viene (S15). C02 no compara los caracteres de las barras |

## Open Questions

- Si `copilot help config` en la máquina muestra otras claves para `statusLine`, o que el comando no pasa por un shell que encuentre `bash`, el Agente frena en la tarea 1.1 y Claude ajusta el design.
