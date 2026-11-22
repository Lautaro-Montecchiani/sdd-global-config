# Design

## Context

Ver proposal.md (Why). Estado actual:

- **Carga de las reglas:** `~/.claude/CLAUDE.md` es el archivo de carga que escribe `instalar.ps1` e importa con `@` el espejo `_global/reglas-globales.md` del vault (tipo *User*). En este repo, Claude Code además carga `.claude/CLAUDE.md` como instrucciones del proyecto (tipo *Project*). Son el mismo texto cuando el repo está al día con el espejo, y textos distintos en una rama que edita las reglas.
- **`.claude/` del repo:** tiene `CLAUDE.md`, `commands/`, `statusline.sh` y `settings.local.json` (no versionado; permisos locales). No tiene `settings.json`.
- **Claude Code 2.1.330** (instalado en esta máquina) soporta `claudeMdExcludes` en los settings. Según la descripción del propio binario: "Glob patterns or absolute paths of CLAUDE.md files to exclude from loading. Patterns are matched against absolute file paths using picomatch. Only applies to User, Project, and Local memory types". Los patrones relativos no se resuelven contra la raíz del proyecto: se comparan con la ruta absoluta (con `\` pasado a `/`). En Windows la letra de la unidad no distingue mayúsculas.
- **`README.md`**, "Setup (una sola vez por máquina)", paso 1: ya clona con `git clone <url> sdd-global-config`.

## Goals / Non-Goals

**Goals:** que en este repo las reglas se carguen una sola vez (las instaladas), sin tocar la carga en los demás proyectos ni el `~/.claude/CLAUDE.md` global.

**Non-Goals:** ver proposal.

## Decisions

### D1. `.claude/settings.json` con `claudeMdExcludes`

Archivo nuevo, UTF-8 sin BOM y fin de línea LF, con este contenido exacto (dos espacios de sangría):

```json
{
  "claudeMdExcludes": [
    "**/sdd-global-config/.claude/CLAUDE.md"
  ]
}
```

- Se excluye la copia del repo y no la global: así este repo se comporta como cualquier otro proyecto (reglas instaladas) y una rama a medio editar no le cambia las reglas a Claude mientras trabaja.
- El patrón nombra la carpeta del repo porque `**/.claude/CLAUDE.md` también coincidiría con `~/.claude/CLAUDE.md` y dejaría a Claude sin reglas.
- No lleva permisos ni otras claves: los permisos locales siguen en `settings.local.json` (no versionado).
- **Alternativas descartadas** (elegidas por el usuario en el propose):
  - *Mover la fuente fuera de `.claude/`:* toca unos 34 archivos (scripts, tests, specs y docs), y `instalar.ps1` reconoce las copias viejas buscando versiones en la historia de git de `.claude/CLAUDE.md`, que habría que seguir por las dos rutas.
  - *Excluir el global en este repo:* necesita la ruta absoluta del home en `settings.local.json` de cada máquina, escrita por `instalar.ps1`; agrega una escritura por máquina para un caso de un solo repo.
  - *Dejarlo así:* contexto duplicado e instrucciones contradictorias en las ramas que editan reglas.

### D2. `README.md`

En "## Setup (una sola vez por máquina)", "### 1. Pasos comunes (Claude y herramientas)", después del bloque de código del paso 1 y antes del párrafo "Java 11+ es opcional…", se agrega:

"**Reglas en este repo.** `.claude/settings.json` excluye `.claude/CLAUDE.md` con `claudeMdExcludes`, así Claude Code carga las reglas una sola vez: las instaladas por `instalar.ps1` (el espejo del vault). Por eso el clon tiene que estar en una carpeta `sdd-global-config`; con otro nombre el patrón no coincide y las reglas se cargan dos veces. Para probar con Claude reglas editadas en una rama, corré `pwsh scripts\instalar.ps1` desde esa rama."

## Risks / Trade-offs

- [Riesgo] Una máquina sin `instalar.ps1` queda sin reglas en este repo. → Mitigación: el setup del README lo pide en el paso 3; el archivo de carga avisa si el vault no cargó.
- [Riesgo] Un clon en una carpeta con otro nombre no excluye nada. → Aceptado: vuelve al comportamiento actual (carga doble), sin romper nada; lo documenta D2.
- [Riesgo] Una versión de Claude Code sin `claudeMdExcludes` ignora la clave. → Aceptado: vuelve al comportamiento actual.
- [Trade-off] En una rama que edita las reglas, Claude trabaja con las instaladas hasta correr `instalar.ps1` desde la rama, que también actualiza el espejo compartido. Se documenta en D2.

## Migration Plan

Nada que migrar: el archivo actúa en cuanto está en el árbol de trabajo. Rollback: borrar `.claude/settings.json`.

## Impacto en proyectos existentes

Ninguno: `.claude/settings.json` es configuración de proyecto de este repo, `instalar.ps1` no lo copia y `sincronizar-proyecto.ps1` no lo distribuye.

## Impacto en el sistema

**Componentes afectados:** las sesiones de Claude Code abiertas en este repo (dejan de cargar `.claude/CLAUDE.md`). Ninguno fuera de este repo.

**Atributos de calidad:**
- mantenibilidad (alta): una sola versión de las reglas en el contexto de Claude, sin texto duplicado; la exclusión se controla con un test — Verificación: S01 y S02.

**Decisiones de arquitectura:** ninguna. No cambia el stack, el nivel ni las integraciones, no adopta un patrón transversal y no resuelve un compromiso entre atributos de calidad.

**Deuda técnica:**
- paga: en este repo `.claude/CLAUDE.md` se carga dos veces en Claude (#54).
- descubre: ninguna (la dependencia del nombre de la carpeta queda documentada en el README).

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `.claude/settings.json` | `.claude/` (implícita: carpeta que empieza con `.`) |
| `tests/carga-unica-de-reglas.Tests.ps1` | `tests/` |

## Security Layer

Tipo de proyecto: `tooling`.

- El archivo nuevo cambia qué instrucciones carga la IA: no expone secretos ni rutas absolutas personales — Verificación: S03.
- No suma permisos a Claude Code: `.claude/settings.json` no tiene `permissions` ni otras claves — Verificación: S01.
- No deja a Claude sin las reglas globales: el patrón no coincide con `~/.claude/CLAUDE.md` — Verificación: S02 y M01.
- El cambio de configuración de la IA va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/settings.json`, con una línea "Impacto:".

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). No hace falta forzar la suite por código modificado (solo cambian `README.md` y `docs/`), pero se corre completa porque varios tests leen `README.md`. Cada test lleva `# test-plan: carga-unica-de-reglas/<ID>` arriba del `Probar`, usa `. "$PSScriptRoot/apoyo.ps1"` y lee los archivos del repo (sin escribir nada).

Para S02, el test reproduce cómo compara picomatch un patrón que empieza con `**/` y no tiene más comodines: coincide si la ruta (con `/`) es igual al resto del patrón o termina en `/` + el resto. Antes, el test afirma que el patrón cumple esa forma, así la regla de comparación es válida.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Carga única de las reglas en este repo / Patrón de exclusión versionado | auto: `.claude/settings.json` se parsea con `ConvertFrom-Json`, su única propiedad es `claudeMdExcludes` y la lista tiene un solo elemento igual a `**/sdd-global-config/.claude/CLAUDE.md`; los primeros 3 bytes no son `EF BB BF` | `tests/carga-unica-de-reglas.Tests.ps1` |
| S02 | Carga única de las reglas en este repo / Excluye solo la copia del repo | auto: con la regla de comparación de arriba, el patrón coincide con las dos rutas inventadas de la copia del repo y no con las dos del `CLAUDE.md` global | `tests/carga-unica-de-reglas.Tests.ps1` |
| S03 | Carga única de las reglas en este repo / Sin rutas personales | auto: `.claude/settings.json` no contiene `C:`, `/Users/`, `/home/` ni `$env:USERNAME` | `tests/carga-unica-de-reglas.Tests.ps1` |
| S04 | Documentación de la carga única de las reglas / Documentación de la carga | auto: `README.md` tiene el párrafo "**Reglas en este repo.**" de D2 con `claudeMdExcludes`, `sdd-global-config` e `instalar.ps1` | `tests/carga-unica-de-reglas.Tests.ps1` |
| M01 | Carga real en una sesión | manual (lo corre el usuario): abrir Claude Code en este repo, en la rama del change, y correr `/memory`. La lista tiene `~/.claude/CLAUDE.md` (con el espejo del vault importado) y no tiene `.claude/CLAUDE.md` del proyecto. Pegar la lista que muestra | — |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `README.md` (con `reglas-fuente-unica/S17` de `tests/instalar.Tests.ps1`, S07 y S08 de `tests/pr-check-mejoras-de-proyectos.Tests.ps1` y S10 de `tests/huella-de-instalacion-en-espejo.Tests.ps1`) | Los textos del README que ya controlan otros changes | Solo se agrega el párrafo de D2 (S04). Esos tests no se modifican |

## Open Questions

- Ninguna.
