# Design

## Context

- **Cómo decide hoy `scripts/sincronizar-proyecto.ps1`** el estado de cada archivo del Agente:
  - si es igual a la plantilla actual (o, con `## Propio del proyecto`, igual a lo generado más lo propio), está **al día**;
  - si es igual a una versión anterior de la plantilla en la historia de git de `sdd-global-config` (`Test-EsVersionGitHistorica`), está **atrasado** y se reemplaza;
  - si no coincide con ninguna, es **contenido propio** y queda bloqueado.
  `-Comprobar` muestra la tabla y termina con 1 si algo cambiaría. Ese criterio necesita la historia de git del repo, por eso solo puede correr en una máquina con el clon local.
- **Detección de agentes:** sin `-Agentes`, el script suma siempre `comun` (`AGENTS.md`) y agrega `copilot` o `cursor` según los archivos que existen. Para un aviso, eso daría falsos "falta `AGENTS.md`" en proyectos que solo usan Copilot (por ejemplo, `scrapingExodo`).
- **La salida actual** incluye la ruta absoluta del proyecto ("Sincronización en proyecto: <ruta>") y una tabla de varias líneas: sirve para una corrida manual, no para un aviso al iniciar sesión.
- **El inicio de sesión de Claude** ya corre `instalar.ps1 -Comprobar` desde `$env:SDD_CONFIG_REPO` y avisa si la máquina está atrasada. Este change suma el control del proyecto en la misma sección.
- Relevamiento del 13/11/2026: los 16 proyectos de esta PC con reglas del Agente están atrasados (11) o bloqueados (5), repartidos en tres carpetas distintas (ver proposal). Por eso el aviso corre en el proyecto que se abre, sin depender de una lista de proyectos.

## Goals / Non-Goals

**Goals:**
- Que Claude avise, al abrir un proyecto, si sus reglas o comandos del Agente están atrasados o editados a mano, con el comando para arreglarlo.
- Reusar el criterio de estado de la sincronización, sin una segunda forma de comparar.

**Non-Goals:**
- Control en el CI de los proyectos (change aparte).
- Sincronizar o editar los proyectos desde el aviso.
- Detectar que el clon local de `sdd-global-config` está atrás de GitHub.

## Decisions

### D1. Modo `-Aviso` en `sincronizar-proyecto.ps1`

- **Parámetro nuevo** `-Aviso` (switch). No se combina con `-Comprobar`, `-Simular`, `-Forzar`, `-Agentes` ni `-PrCheck`: si viene junto con alguno, el script termina con código distinto de 0 y un mensaje que lo dice, sin controlar nada.
- **Destinos:** solo los archivos que existen en el proyecto, de esta lista: `AGENTS.md`, `.github/copilot-instructions.md`, `.github/prompts/odd-apply.prompt.md`, `.cursor/rules/sdd-workflow.mdc`, `.cursor/commands/odd-apply.md` y `.github/workflows/pr-check.yml`. Un archivo que no existe no se controla ni se informa.
- **Estado:** el mismo cálculo que hoy usa la sincronización para cada destino (al día, atrasado, bloqueado). No se escribe una segunda comparación: el Agente reutiliza el cálculo existente, extrayéndolo a una función si hace falta.
- **Archivo vacío o ilegible:** se trata como contenido que no coincide con ninguna versión, o sea `bloqueado`, sin excepción.
- **Salida:** en modo `-Aviso` no se muestra la tabla ni la línea "Sincronización en proyecto". Se escribe una sola línea, con rutas relativas al proyecto:
  - todo al día: `Reglas del Agente al día en este proyecto.`
  - sin archivos del Agente: `Este proyecto no tiene archivos del Agente.`
  - con atrasados y/o bloqueados: `Aviso: reglas del Agente desactualizadas en este proyecto.` seguido, en la misma línea, de `Atrasados: <lista>. Para actualizarlos: pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .` y/o `Bloqueados por contenido propio: <lista>; pasá ese contenido debajo de "## Propio del proyecto" y volvé a sincronizar.` La lista separa los archivos con coma.
- **Código de salida:** 0 al día o sin archivos; 1 con algo atrasado o bloqueado; distinto de 0 si se combinan parámetros incompatibles.
- **Alternativas descartadas:**
  - *Que Claude interprete la tabla de `-Comprobar`:* deja la decisión al modelo y arrastra el falso "falta `AGENTS.md`" y la ruta absoluta.
  - *Opción `-Detectar` combinable con `-Comprobar`:* más combinaciones para probar y la tabla sigue sin servir como aviso de una línea.
  - *Script nuevo `avisar-proyecto.ps1`:* duplicaría la carga de destinos y el criterio de estado.

### D2. Paso en el inicio de sesión (`.claude/CLAUDE.md`)

En "Al iniciar cada sesión", paso 3, después de "Comprobar las reglas" (`instalar.ps1 -Comprobar`), se suma un ítem:

- "Comprobar el proyecto: si la carpeta actual no es `sdd-global-config` y tiene alguno de `AGENTS.md`, `.github/copilot-instructions.md`, `.github/prompts/odd-apply.prompt.md`, `.cursor/rules/sdd-workflow.mdc`, `.cursor/commands/odd-apply.md` o `.github/workflows/pr-check.yml`, correr `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto . -Aviso`. Si termina con código distinto de 0, mostrar la línea al usuario. No sincronizar ni editar esos archivos por cuenta propia. Si `$env:SDD_CONFIG_REPO` no está definida, avisar que no se pudo controlar el proyecto y continuar."

No se toca el bloque generado de reglas del Agente. El cambio va en un commit que solo toca `.claude/CLAUDE.md`.

### D3. Documentación

- `README.md`, sección "Sumar un proyecto al workflow": un párrafo sobre `-Aviso` (qué controla, que no escribe, que Claude lo corre al iniciar sesión y qué hacer con un bloqueado).
- `docs/modo-de-uso.md` y `docs/workflow.md`: la misma explicación donde ya se documenta `sincronizar-proyecto.ps1`, con el comando de ejemplo `-Proyecto . -Aviso`.
- `docs/arquitectura/vision.md`, `## Hoja de ruta`: "- [media] el CI de los proyectos no detecta reglas del Agente atrasadas ni editadas a mano — origen: aviso-proyecto-atrasado — propuesta: huella (versión y hash) en los archivos generados, controlada por `pr-check.yml`, en un change aparte".

## Impacto en proyectos existentes

- Ningún archivo de los proyectos cambia.
- En la próxima sesión de Claude, cada proyecto con reglas atrasadas muestra el aviso. Según el relevamiento, eso incluye a los 16 proyectos de esta PC con reglas del Agente. `scrapingExodo`, sus dos copias y `normalizacionRTF-python` van a aparecer como bloqueados hasta que su contenido propio pase debajo de `## Propio del proyecto` (en `normalizacionRTF-python` también está editado a mano el `pr-check.yml`).
- Las máquinas reciben el paso nuevo con `instalar.ps1` (espejo del vault y `~/.claude/CLAUDE.md`).
- Los modos actuales de `sincronizar-proyecto.ps1` no cambian.

## Impacto en el sistema

**Componentes afectados:** el inicio de sesión de Claude en todos los proyectos (un comando más, solo lectura) y los archivos del Agente de cada proyecto, que se leen pero no se escriben. El espejo del vault recibe el `CLAUDE.md` nuevo al instalar.

**Atributos de calidad:**
- mantenibilidad (alta): `-Aviso` reusa el criterio de estado de la sincronización, sin una segunda comparación; la lista de archivos del Agente vive en un solo lugar del script — Verificación: S02 y S03 (mismo resultado que la sincronización para un archivo atrasado y uno bloqueado) y revisión del diff: ninguna comparación de hashes nueva fuera de la que ya usa la sincronización.

**Decisiones de arquitectura:** ninguna. No cambia el stack, el nivel ni las integraciones.

**Deuda técnica:**
- descubre: el CI de los proyectos no controla las reglas del Agente (va a la hoja de ruta como media, D3).
- descubre: sin `-Agentes`, la sincronización suma siempre `AGENTS.md`, aunque el proyecto no lo use. No se cambia en este change (el modo `-Aviso` no lo hace); queda como observación.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/aviso-proyecto-atrasado.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- La salida del aviso no expone rutas absolutas del proyecto, del repo ni del usuario — Verificación: S12.
- `-Aviso` no escribe en el proyecto ni en el repo — Verificación: S02 (ningún archivo cambia) y revisión del diff: el modo termina antes de cualquier escritura o respaldo.
- El script no ejecuta texto leído de los proyectos — Verificación: revisión del diff: sin `Invoke-Expression` ni ejecución de contenido leído.
- Las instrucciones nuevas del `CLAUDE.md` no exponen secrets ni rutas personales (usan `$env:SDD_CONFIG_REPO` y `-Proyecto .`) — Verificación: S13 y revisión del diff: ninguna ruta `C:\Users\…`.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/CLAUDE.md`.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Corre la suite completa y los controles del CI porque cambia un script existente. Cada test lleva `# test-plan: aviso-proyecto-atrasado/<ID>` arriba del `Probar`. Los tests usan carpetas temporales como proyectos de prueba, nunca proyectos reales; la versión vieja de una plantilla sale de la historia de git del repo, como en `tests/sincronizar-proyecto.Tests.ps1`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Aviso de proyecto atrasado / Proyecto al día | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S02 | Aviso de proyecto atrasado / Archivo atrasado | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S03 | Aviso de proyecto atrasado / Contenido propio sin marcar | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S04 | Aviso de proyecto atrasado / Solo archivos existentes | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S05 | Aviso de proyecto atrasado / Proyecto sin archivos del Agente | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S06 | Aviso de proyecto atrasado / Parámetros incompatibles | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S07 | Aviso de proyecto atrasado / Dato inválido: archivo del Agente vacío | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S08 | Salida del aviso de proyecto / Línea al día | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S09 | Salida del aviso de proyecto / Línea con atrasados | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S10 | Salida del aviso de proyecto / Línea con bloqueados | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S11 | Salida del aviso de proyecto / Línea sin archivos del Agente | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S12 | Salida del aviso de proyecto / Sin rutas absolutas en la salida | auto | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S13 | Aviso al iniciar sesión en un proyecto / Paso en el inicio de sesión | auto: `.claude/CLAUDE.md` tiene el comando con `-Aviso`, las dos condiciones y que no sincroniza por su cuenta | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S14 | Aviso al iniciar sesión en un proyecto / Sin variable del repo | auto: `.claude/CLAUDE.md` tiene la indicación para cuando falta `SDD_CONFIG_REPO` | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| S15 | Aviso al iniciar sesión en un proyecto / Documentación del modo aviso | auto: `README.md` y `docs/modo-de-uso.md` mencionan `-Aviso` | `tests/aviso-proyecto-atrasado.Tests.ps1` |
| M01 | El aviso en una sesión real | manual (lo corre el usuario): después de `pwsh scripts/instalar.ps1`, abrir Claude Code en un proyecto con reglas atrasadas (por ejemplo, `automation-server`) y ver la línea de aviso; abrirlo en `sdd-global-config` y ver que no aparece. Pegar las dos salidas | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/sincronizar-proyecto.ps1` (con `tests/sincronizar-proyecto.Tests.ps1` y S07 a S09 de `tests/odd-apply.Tests.ps1`) | Sincronización, `-Comprobar`, bloqueo de contenido propio y destinos de `/odd-apply` | Suma el modo `-Aviso` (S01 a S12). Los modos existentes no cambian y sus tests no se modifican |

## Open Questions

- Ninguna.
