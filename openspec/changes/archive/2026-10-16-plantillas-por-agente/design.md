## Context

`templates/` tiene hoy cuatro plantillas sueltas: `GEMINI.md` (reglas para Gemini y Antigravity, se instala en `~/.gemini/GEMINI.md`), `antigravity-settings.json` (permisos y barra de estado del CLI de Antigravity), `copilot-instructions.md` (va en `.github/` de cada proyecto) y `AGENTS.md` (estándar multi-agente, va en la raíz de cada proyecto), más un `README.md`. No queda claro qué es de cada agente ni qué soporta cada uno. En una máquina, la barra de Antigravity se apagó porque el CLI escribió `"enabled": false` en `statusLine`, y la plantilla no trae esa clave.

Lo que se averiguó el 16/10/2026 en la documentación oficial:
- **Antigravity CLI:** `statusLine` con `type: command`; el CLI pasa un JSON por stdin al script y muestra lo que el script escribe en stdout ([docs](https://www.antigravity.google/docs/cli/statusline)); también se configura con el comando `/statusline` ([docs](https://www.antigravity.google/docs/cli/commands/statusline)).
- **Gemini CLI:** configuración en `~/.gemini/settings.json` y `.gemini/settings.json` del proyecto ([docs](https://geminicli.com/docs/reference/configuration.md)); carpetas de confianza con `security.folderTrust.enabled` y `~/.gemini/trustedFolders.json` ([docs](https://geminicli.com/docs/cli/trusted-folders/)). La documentación oficial no confirma una barra de estado configurable ni el nombre de las claves de allowlist.
- **Cursor:** reglas en `.cursor/rules/*.mdc` o en `AGENTS.md` ([docs](https://docs.cursor.com/context/rules)); permisos del CLI en `~/.cursor/cli-config.json` (`permissions.allow`/`deny` con `Shell(<comando>)`) y por proyecto en `.cursor/cli.json` ([configuración](https://cursor.com/docs/cli/reference/configuration), [permisos](https://cursor.com/docs/cli/reference/permissions)). No se encontró documentación de una barra de estado configurable.

## Goals / Non-Goals

**Goals:**
- Que cada persona encuentre en una carpeta todo lo de su agente, con su instalación.
- Dejar escrito qué soporta cada agente, sin dar por hecho lo que no está documentado.
- Que la barra de Antigravity quede prendida desde la plantilla.

**Non-Goals:**
- Agregar Cursor (lo trae `agente-cursor`) o permisos y barra para Gemini CLI y Codex.
- Cambiar las 7 reglas de ejecución del Agente.

## Decisions

### D1. Estructura de `templates/`
Mover con `git mv` (para conservar el historial) y crear los README:

| Antes | Después |
|---|---|
| `templates/antigravity-settings.json` | `templates/antigravity/settings.json` |
| `templates/GEMINI.md` | `templates/gemini/GEMINI.md` |
| `templates/copilot-instructions.md` | `templates/copilot/copilot-instructions.md` |
| `templates/AGENTS.md` | `templates/comun/AGENTS.md` |
| — | `templates/antigravity/README.md`, `templates/gemini/README.md`, `templates/copilot/README.md`, `templates/comun/README.md` |
| `templates/README.md` | `templates/README.md` (reescrito como índice + matriz, D3) |

`GEMINI.md` queda una sola vez, en `gemini/`: Antigravity lee el mismo `~/.gemini/GEMINI.md`, y `templates/antigravity/README.md` lo indica en vez de duplicar el archivo. Alternativa descartada: copiar `GEMINI.md` en las dos carpetas, porque dos copias de las reglas se desincronizan.

### D2. Barra de estado de Antigravity prendida
En `templates/antigravity/settings.json`, la entrada `statusLine` queda así (el resto del archivo no cambia):

```json
"statusLine": {
  "type": "command",
  "command": "{RUTA-DE-TU-USUARIO}/.gemini/antigravity-cli/scratch/statusline.bat",
  "enabled": true
}
```

El contenido actual de la sección "Barra de estado" de `templates/README.md` (incluido el prompt para que el CLI genere los scripts) pasa a `templates/antigravity/README.md`, junto con los placeholders y la advertencia de baseline permisiva. Se agrega un párrafo "Si la barra no aparece": revisar que `statusLine.enabled` sea `true` en `~/.gemini/antigravity-cli/settings.json` y reiniciar el CLI.

### D3. Matriz de soporte en `templates/README.md`
`templates/README.md` queda con: una línea por carpeta (qué agente y qué trae) y esta tabla, exacta:

| Agente | Reglas | Permisos | Barra de estado |
|---|---|---|---|
| Antigravity | `gemini/GEMINI.md` → `~/.gemini/GEMINI.md` | `antigravity/settings.json` → `~/.gemini/antigravity-cli/settings.json` | `antigravity/settings.json` (`statusLine`) + scripts que genera el CLI |
| Gemini CLI | `gemini/GEMINI.md` → `~/.gemini/GEMINI.md` | no verificado (la documentación oficial solo confirma las carpetas de confianza) | no verificado |
| Copilot | `copilot/copilot-instructions.md` → `.github/copilot-instructions.md` del proyecto | no soportado | no soportado |
| Codex | `comun/AGENTS.md` → raíz del proyecto | no verificado | no verificado |
| Cursor | lo agrega `agente-cursor` en `templates/cursor/` (Cursor también lee `comun/AGENTS.md`) | lo agrega `agente-cursor` (`~/.cursor/cli-config.json`) | no verificado |

Debajo de la tabla, las fuentes de la sección Context y la regla: "una capacidad se marca cubierta solo si la documentación oficial del agente la confirma".

### D4. Contenido de cada README de carpeta
Cada `README.md` de carpeta tiene tres partes: para qué agente es, qué archivos trae y el comando de instalación de cada uno (los mismos comandos que hoy están en `README.md` y `docs/modo-de-uso.md`, con las rutas nuevas). `templates/gemini/README.md` agrega cómo activar las carpetas de confianza (`security.folderTrust.enabled` en `~/.gemini/settings.json`), con su enlace.

### D5. Referencias a actualizar
Reemplazar las rutas viejas por las nuevas en: `README.md`, `docs/modo-de-uso.md`, `docs/workflow.md`, `.claude/CLAUDE.md` y `~/.claude/CLAUDE.md` (secciones "Reglas de ejecución del Agente" y "Reglas globales en el vault"). Después: regenerar `docs/modo-de-uso.docx` con pandoc usando el `.docx` actual como `--reference-doc` (copia temporal fuera del repo), y re-sincronizar el espejo `$vault\_global\reglas-globales.md` con el comando de la sección "Sincronizar reglas globales al vault" del `CLAUDE.md` global. No se tocan los changes archivados ni `docs/srs.md` (se regenera aparte).

### D6. Coordinación con `agente-cursor`
Este change no crea `templates/cursor/`. Antes del apply de `agente-cursor`, su proposal y su design se ajustan para agregar `templates/cursor/` con la misma forma (reglas `.mdc`, permisos del CLI si se usan, `README.md`) y una fila de la matriz completa, sin retirar `templates/antigravity/` ni `templates/gemini/` ni los requisitos de Antigravity de `agent-cli-permissions`.

## Risks / Trade-offs

- [Alguien tiene guardados los comandos viejos de instalación] → Los README nuevos y la guía de uso muestran las rutas nuevas; los archivos ya instalados en cada máquina no cambian.
- [`agente-cursor` se implementa sin ajustarse a D6] → Queda anotado en el vault y en el proposal; el verify de ese change tiene que revisarlo.
- [La documentación de los agentes cambia] → La matriz marca "no verificado" en vez de suponer, y cita la fuente de lo que sí está confirmado.

## Impacto en proyectos existentes

- Los proyectos que ya tienen `.github/copilot-instructions.md` o `AGENTS.md` copiados no cambian.
- Las máquinas con `~/.gemini/GEMINI.md` o `~/.gemini/antigravity-cli/settings.json` instalados no cambian; quien quiera la barra prendida desde la plantilla puede reinstalar o poner `enabled` en `true` a mano.
- El onboarding de proyectos nuevos copia desde las rutas nuevas.

## Security Layer

Tipo `tooling`:
- Las plantillas son instrucciones y configuración para IA: no llevan secrets, tokens ni rutas con el usuario local; las rutas siguen como placeholders (`{RUTA-DE-TU-USUARIO}`, `{RUTA-A-TUS-PROYECTOS}`).
- La advertencia de baseline permisiva de Antigravity (`always-proceed`, `allowNonWorkspaceAccess`, `powershell`/`cmd.exe`) se conserva en `templates/antigravity/README.md`.
- Cambio al `CLAUDE.md` global → commit separado con descripción del impacto, espejo del vault re-sincronizado.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y JSON de plantilla, sin tests automáticos. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Una carpeta por agente / Estructura por agente | manual: sin tests automáticos. Pasos: listar `templates/` recursivamente y pegar la salida; confirmar los 4 archivos movidos, los 4 README de carpeta y que en la raíz solo queda `README.md` | `templates/**` |
| S02 | Una carpeta por agente / README de instalación por agente | manual: revisión de contenido. Pasos: leer los 4 README de carpeta y confirmar agente, archivos y destino de cada uno (D4) | `templates/*/README.md` |
| S03 | Matriz de soporte / Agente con soporte parcial | manual: revisión de contenido. Pasos: comparar la tabla de `templates/README.md` con la de D3 y pegar la fila de Gemini CLI | `templates/README.md` |
| S04 | Matriz de soporte / Agente pendiente | manual: revisión de contenido. Pasos: pegar la fila de Cursor de la matriz | `templates/README.md` |
| S05 | Mismas reglas / Reglas presentes en cada plantilla | manual: sin tests automáticos. Pasos: buscar las tres frases en `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md` y `templates/comun/AGENTS.md` y pegar el conteo | plantillas de reglas |
| S06 | Configuración personal no se versiona / `.gemini/` fuera de git | manual: sin tests automáticos. Pasos: `git ls-files .gemini` (vacío) y buscar `.gemini/` en `.gitignore` | `.gitignore` |
| S07 | Configuración personal no se versiona / Los archivos locales se conservan | manual: sin tests automáticos. Pasos: confirmar que `~/.gemini/antigravity-cli/settings.json` no cambió (hash antes y después del apply) | — |
| S08 | Baseline de permisos / Permisos replicados desde la plantilla | manual: sin tests automáticos. Pasos: leer `toolPermission`, `artifactReviewPolicy` y `allowNonWorkspaceAccess` de `templates/antigravity/settings.json` y pegar los valores | `templates/antigravity/settings.json` |
| S09 | Allowlist base / Allowlist genérica | manual: sin tests automáticos. Pasos: pegar `permissions.allow` de `templates/antigravity/settings.json` (7 comandos) | `templates/antigravity/settings.json` |
| S10 | Barra de estado / Línea con datos completos | manual: requiere los scripts generados en la máquina. Pasos: pasarle al `statusline.bat` instalado el JSON del escenario y pegar la línea sin ANSI | — |
| S11 | Barra de estado / Selección de la cuota | manual: igual que S10 con el JSON del escenario | — |
| S12 | Barra de estado / Entrada inválida | manual: igual que S10 con una entrada que no es JSON | — |
| S13 | Barra de estado / Barra prendida en la plantilla | manual: sin tests automáticos. Pasos: pegar `statusLine` de `templates/antigravity/settings.json` y confirmar `"enabled": true`; validar el JSON | `templates/antigravity/settings.json` |
| S14 | Instalación documentada / Pasos de instalación visibles | manual: revisión de contenido. Pasos: buscar `templates\antigravity\settings.json` en `README.md` y `docs/modo-de-uso.md`, y buscar que no queden rutas viejas (`templates\GEMINI.md`, `templates\antigravity-settings.json`, `templates\copilot-instructions.md`, `templates\AGENTS.md`) fuera de los changes archivados | `README.md`, `docs/modo-de-uso.md` |
| S15 | Instalación documentada / Prompt para generar la barra de estado | manual: revisión de contenido. Pasos: confirmar en `templates/antigravity/README.md` el prompt y el párrafo "Si la barra no aparece" | `templates/antigravity/README.md` |
| S16 | Regla para el Agente / Test en rojo al terminar la tarea | manual: revisión de contenido. Pasos: buscar la regla en `templates/gemini/GEMINI.md`, `templates/copilot/copilot-instructions.md`, `~/.claude/CLAUDE.md` y el espejo del vault | plantillas, `CLAUDE.md` |

## Open Questions

Sin preguntas abiertas.
