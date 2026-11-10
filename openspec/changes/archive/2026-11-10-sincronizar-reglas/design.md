## Context

- Motivación en `proposal.md` (Why). Issue #35. Decisión del usuario del 10/11/2026: hacer este change antes de `clasificacion-odd-sdd` (#32), que queda en pausa.
- Hoy las cuatro plantillas de reglas del Agente (`templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`) se editan a mano. Revisadas el 10/11/2026:
  - las cuatro tienen idéntica la sección `## Reglas de ejecución (obligatorias)` (8 reglas);
  - `AGENTS.md`, Copilot y Cursor tienen idénticos el aviso del vault (`## Reglas globales (fuente de verdad)`), las tres viñetas comunes de `## Tu rol: CONSTRUCTOR`, `## Git` y `## Memoria del proyecto`;
  - lo propio de cada una: el encabezado (y el frontmatter de Cursor), la nota de `AGENTS.md` sobre el estándar, las dos viñetas y `## Comandos permitidos` de Cursor, y en `GEMINI.md` su aviso del vault con el párrafo de qué define el archivo, `## Memoria por proyecto` y `## Reglas mínimas`.
- `.github/copilot-instructions.md` de este repo no coincide con su plantilla: le falta `## Reglas de ejecución (obligatorias)` completa y la viñeta de `[x]` está recortada.
- `.claude/CLAUDE.md` tiene las mismas 8 reglas en `### Reglas de ejecución del Agente`, en tercera persona.
- `.github/workflows/pr-check.yml` valida branch, título, `Spec-ID` y archivos sensibles. Es el mismo archivo que se usa en los proyectos (hay que copiarlo).
- Instalación de hoy: los pasos del README (`cp`), y en cada change las tareas de comparar con `git show master:<ruta>`, copiar, tabla de hashes y espejo del vault (por ejemplo, tareas 5.1 a 5.3 y 7.6 de `rol-arquitecto-software`).
- `openspec/config.yaml`: `project_type: tooling`, `## Tests` con `comando: ninguno`, `## Arquitectura` con `skills/` y `templates/`. No declara `## Alcance`, `## Datos`, `## Stack` ni `## Calidad`.
- El repo no tiene `docs/adr/` ni `docs/arquitectura/vision.md`. La visión inicial que se escribió en `clasificacion-odd-sdd` no está mergeada: la de este change la reemplaza, y `clasificacion-odd-sdd` se ajusta al retomarlo.
- PowerShell 7.6 está instalado en la máquina y es el shell del workflow (perfil con `OBSIDIAN_VAULT` y `SDD_CONFIG_REPO`). Los runners `ubuntu-latest` de GitHub traen `pwsh`.

## Goals / Non-Goals

**Goals:**
- Que una regla del Agente se edite en un solo lugar y las cuatro plantillas salgan de ahí.
- Que una plantilla desincronizada haga fallar el PR, en vez de descubrirse meses después.
- Que instalar en una máquina sea un comando, con el mismo control de cambios locales que hoy se hace a mano.
- Que actualizar las reglas de un proyecto sea un comando que no pisa lo que el proyecto agregó.

**Non-Goals:**
- Generar el `CLAUDE.md` o los comandos de `.claude/commands/` (ver proposal).
- Soportar otro shell que PowerShell 7.
- Distribuir los scripts fuera del repo (los proyectos los corren desde `$env:SDD_CONFIG_REPO`).

## Decisions

**D1. Fuente única.** Carpeta `templates/fuente/` con dos subcarpetas:
- `fragmentos/`: un archivo por parte compartida, sin título de sección (el título lo pone el esqueleto):
  - `aviso-vault.md`: el texto de `## Reglas globales (fuente de verdad)` de `AGENTS.md`, Copilot y Cursor;
  - `rol-constructor.md`: las tres viñetas comunes de `## Tu rol: CONSTRUCTOR`;
  - `reglas-ejecucion.md`: las 8 reglas;
  - `git.md`: las cuatro viñetas de `## Git`;
  - `memoria-proyecto.md`: el párrafo de `## Memoria del proyecto`.
- `esqueletos/`: un archivo por plantilla (`AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc`, `GEMINI.md`) con su parte propia y, donde va un fragmento, una línea que contiene solo `<!-- incluir: <fragmento> -->` (nombre sin `.md`).

El texto de los fragmentos y de los esqueletos sale de las plantillas actuales, sin cambiar una palabra (C01).

**D2. Generación.** `scripts/generar-plantillas.ps1`:
- Tabla fija esqueleto → destino: `AGENTS.md` → `templates/comun/AGENTS.md`; `copilot-instructions.md` → `templates/copilot/copilot-instructions.md`; `sdd-workflow.mdc` → `templates/cursor/sdd-workflow.mdc`; `GEMINI.md` → `templates/antigravity/GEMINI.md`.
- Reemplaza cada línea `<!-- incluir: x -->` por el contenido de `fragmentos/x.md` sin el salto de línea final. Si el fragmento no existe, termina con código 1 nombrando esqueleto y fragmento, sin escribir ningún archivo.
- Agrega el aviso de archivo generado como primera línea (en `.mdc`, después del cierre del frontmatter): `<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: el contenido propio va debajo de "## Propio del proyecto". -->`, seguido de una línea en blanco.
- Agrega al final de las cuatro: una línea en blanco, `## Propio del proyecto` y `<!-- Lo que agregues debajo de este título se conserva al sincronizar. -->`.
- Escribe UTF-8 sin BOM con fin de línea LF. Toda comparación de los scripts normaliza CRLF a LF y quita el BOM.
- `-Comprobar`: no escribe. Compara lo generado con cada plantilla y termina con código 1 listando las que difieren. Además extrae los títulos de las reglas numeradas (líneas `N. **<título>:**`) de `fragmentos/reglas-ejecucion.md` y de `### Reglas de ejecución del Agente` de `.claude/CLAUDE.md`, y termina con código 1 si las listas no son iguales en orden y texto, mostrando las dos.

**D3. Instalación por máquina.** `scripts/instalar.ps1`, con parámetros `-Destino` (por defecto `$HOME`), `-Vault` (por defecto `$env:OBSIDIAN_VAULT`), `-SinVault`, `-Simular` y `-Forzar`:
- **Qué instala:** `.claude/CLAUDE.md` → `<Destino>/.claude/CLAUDE.md`; cada archivo de `skills/` → `<Destino>/.claude/skills/` con la misma ruta relativa; cada `.md` de `.claude/commands/` → `<Destino>/.claude/commands/` con la misma ruta relativa; y `templates/antigravity/GEMINI.md` → `<Destino>/.gemini/GEMINI.md` solo si existe la carpeta `<Destino>/.gemini`. No instala `templates/antigravity/settings.json` ni `.claude/statusline.sh`.
- **Manifiesto:** `<Destino>/.claude/.sdd-global-config.json` con el commit del repo (`git rev-parse --short HEAD`), la fecha y el hash SHA-256 normalizado de cada archivo instalado (ruta relativa a `<Destino>`).
- **Chequeo previo** de cada destino que existe, antes de copiar nada:
  - igual al archivo del repo → `igual`;
  - con entrada en el manifiesto y mismo hash → `atrasado` (se reemplaza);
  - sin entrada en el manifiesto e igual a alguna versión de su fuente en la historia de git (`git log --format=%H -- <ruta>` y `git show <commit>:<ruta>`) → `atrasado`;
  - cualquier otro caso → `con cambios locales`.
  - Si hay al menos uno `con cambios locales`, lista esos archivos y termina con código 1 **sin copiar ninguno**. Con `-Forzar`, primero copia cada uno a una carpeta de respaldo `sdd-respaldo-AAAAMMDD-HHmmss` dentro de la carpeta temporal del sistema, muestra la ruta y sigue.
  - `GEMINI.md` instalado con `## Propio del proyecto`: se compara y se reemplaza solo la parte generada, y se conserva lo que está debajo del título (D5).
- **Sobrantes:** un archivo de `<Destino>/.claude/skills/` o `commands/` que figura en el manifiesto pero ya no está en el repo se informa como `sobrante` y no se borra.
- **Salida:** tabla `Archivo | Estado previo | Hash repo | Hash instalado | Igual` con los 12 primeros caracteres de cada hash, y un aviso si el repo tiene cambios sin commitear en las rutas instaladas.
- **Espejo del vault**, salvo `-SinVault`: si `-Vault` está vacío o no existe, avisa y sigue. Si existe, escribe `_global/reglas-globales.md` con el mismo encabezado que el comando "Sincronizar reglas globales al vault" del `CLAUDE.md` (fuente `~/.claude/CLAUDE.md`, fecha del día, aviso de solo lectura) y el `CLAUDE.md` instalado. Después: `git add` solo de ese archivo, commit `chore: sdd-global-config — sync reglas` si hay diferencias, y `git push`. Si el push falla, avisa y termina con código 0. No toca otros archivos del vault ni la cuenta de `gh`.
- **`-Simular`:** muestra la tabla y lo que haría, sin escribir en el destino, el manifiesto ni el vault.

**D4. Sincronización por proyecto.** `scripts/sincronizar-proyecto.ps1 -Proyecto <ruta>`, con `-Agentes` (lista de `comun`, `copilot`, `cursor`), `-PrCheck`, `-Comprobar`, `-Simular` y `-Forzar`:
- **Destinos:** `comun` → `AGENTS.md`; `copilot` → `.github/copilot-instructions.md`; `cursor` → `.cursor/rules/sdd-workflow.mdc`; `-PrCheck` → `.github/workflows/pr-check.yml` (fuente: el `pr-check.yml` de este repo).
- **Por defecto**, sin `-Agentes`: `comun`, más `copilot` si existe `.github/copilot-instructions.md` y `cursor` si existe la carpeta `.cursor/`. Sin `-PrCheck` explícito, se sincroniza si el proyecto ya tiene `.github/workflows/pr-check.yml`.
- **Por cada destino:**
  - no existe → `creado` (con las carpetas que falten);
  - existe con `## Propio del proyecto` → se reemplaza todo lo anterior al título por lo generado y se conserva lo que está debajo (D5): `igual` o `actualizado`;
  - existe sin el título e igual a una versión de su plantilla en la historia de git de este repo → `actualizado`;
  - cualquier otro caso → `bloqueado: contenido propio`. No se escribe ese archivo. El mensaje pide pasar el contenido propio debajo de `## Propio del proyecto` del archivo generado (o correr con `-Forzar`).
  - `pr-check.yml` no tiene sección propia: igual, igual a una versión de la historia (`actualizado`) o `bloqueado`.
- **`-Forzar`:** respalda cada archivo bloqueado en la carpeta temporal del sistema (como D3) y lo reemplaza.
- **Salida:** tabla `Archivo | Estado` y código 1 si quedó algún `bloqueado`.
- **`-Comprobar`:** no escribe y termina con código 1 si algún destino quedaría distinto o bloqueado.
- **No commitea, no crea ramas y no corre `openspec`** en el proyecto: los cambios quedan en el árbol de trabajo para commitearlos en la rama que corresponda.

**D5. Conservar `## Propio del proyecto`.** Lo propio es todo lo que sigue a la primera línea `## Propio del proyecto` del archivo existente, sin la línea de comentario generada si es la primera. El resultado es el archivo generado (que termina en el título y el comentario) seguido de lo propio, sin cambios.

**D6. Código compartido.** `scripts/comun.ps1` (se carga con dot-source) con las funciones: normalizar texto, hash normalizado, versiones de un archivo en la historia de git, separar y combinar `## Propio del proyecto`, escribir UTF-8 sin BOM con LF, respaldar en la carpeta temporal y raíz del repo (`$PSScriptRoot/..`). Los scripts no usan `$env:SDD_CONFIG_REPO` (se ubican solos) ni rutas absolutas escritas en el código.

**D7. Tests.** Sin librerías: `tests/apoyo.ps1` define `Probar '<nombre>' { ... }` y `Afirmar <condición> '<mensaje>'`. `tests/ejecutar.ps1` corre cada `tests/*.Tests.ps1` en un proceso `pwsh -NoProfile` aparte, imprime `OK <nombre>` o `FALLA <nombre>: <mensaje>` por test y termina con código 1 si alguno falla.
- Cada test arma sus fixtures en una carpeta nueva dentro de la carpeta temporal del sistema y la borra al terminar: repos git de prueba (con `-c user.name` y `-c user.email` de prueba), un `Destino` falso y un vault falso con remote bare.
- Los tests siempre pasan `-Destino` y `-Vault` explícitos. `tests/ejecutar.ps1` pone `OBSIDIAN_VAULT` y `HOME` en carpetas temporales vacías para que un error no toque la máquina real.
- Archivos: `tests/generar-plantillas.Tests.ps1`, `tests/instalar.Tests.ps1` y `tests/sincronizar-proyecto.Tests.ps1`, más `tests/datos/plantillas-antes/` con la copia de las cuatro plantillas antes del change (C01).
- `## Tests` de `openspec/config.yaml` pasa a `- comando: pwsh -NoProfile -File tests/ejecutar.ps1` y `- timeout: 5`.

**D8. CI.** Workflow nuevo `.github/workflows/plantillas.yml`, solo para este repo, en `pull_request`: `actions/checkout@v4` con `fetch-depth: 0` (la historia hace falta para reconocer versiones viejas) y tres pasos con `pwsh`: `tests/ejecutar.ps1`, `scripts/generar-plantillas.ps1 -Comprobar` y `scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar`. `pr-check.yml` no cambia: sigue siendo el que se copia a los proyectos, y en los proyectos no hay `scripts/`.

**D9. `CLAUDE.md` global.**
- "Distribución a agentes no-Claude" (después de la regla 8 del Agente): suma "Las cuatro plantillas se generan desde `templates/fuente/` con `scripts/generar-plantillas.ps1`; un cambio a estas reglas se edita en `templates/fuente/fragmentos/reglas-ejecucion.md` y acá, y el CI controla que tengan los mismos títulos."
- "Onboarding de agentes no-Claude": las copias a mano se reemplazan por `pwsh $env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1 -Proyecto .` (y `-Agentes` si hace falta), que conserva `## Propio del proyecto` y frena ante contenido propio sin marcar. `GEMINI.md` se instala con `scripts/instalar.ps1`.
- "Orden completo ante un cambio de reglas": suma "Si el cambio viene de un change de `sdd-global-config`, el orden es: editar en el repo, mergear y correr `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1`, que instala y sincroniza el espejo del vault."
- "Sincronizar reglas globales al vault" (Comandos PowerShell): sigue el bloque actual y suma una línea: "`scripts/instalar.ps1` hace lo mismo como parte de la instalación."
- Ninguna regla cambia de sentido.

**D10. Documentación.**
- `README.md`: "Setup" pasa los pasos 3 y 4 (copias a `~/.claude`) y el `GEMINI.md` de Antigravity a `pwsh scripts/instalar.ps1` (con `-Simular` para ver antes); "Sumar un proyecto al workflow" reemplaza las copias de Cursor, Copilot y `AGENTS.md` por `sincronizar-proyecto.ps1`; una sección "Plantillas del Agente" explica que se editan en `templates/fuente/` y se regeneran; la tabla "Qué contiene" suma `scripts/`, `tests/` y `templates/fuente/`; el párrafo "Al actualizar un proyecto existente... hay que volver a copiar" pasa a "correr `sincronizar-proyecto.ps1`".
- `docs/workflow.md` y `docs/modo-de-uso.md`: los mismos cambios en sus secciones equivalentes.
- `templates/README.md` y los `README.md` de `comun/`, `copilot/`, `cursor/` y `antigravity/`: dicen que el archivo de reglas se genera desde `templates/fuente/` y cómo se instala con los scripts.

**D11. Este repo.** Después de generar, se corre `scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot`. Como la copia actual no coincide con ninguna versión de la plantilla, se espera `bloqueado`: se revisa con `git diff --no-index` que lo único propio sea el recorte (sin contenido que conservar) y se corre con `-Forzar`.

**D12. Commits.** Separados de `openspec/`, cada uno con un único bloque final de trailers con `Spec-ID: sincronizar-reglas`:
1. `test: caracterización de las plantillas actuales` (C01 y `tests/apoyo.ps1`, `tests/ejecutar.ps1`);
2. `feat: fuente única y generación de las plantillas del Agente` (`templates/fuente/`, `scripts/comun.ps1`, `scripts/generar-plantillas.ps1`, las cuatro plantillas generadas y sus tests);
3. `feat: scripts de instalación y sincronización` (`scripts/instalar.ps1`, `scripts/sincronizar-proyecto.ps1` y sus tests);
4. `ci: tests y control de plantillas` (`.github/workflows/plantillas.yml`);
5. `feat: instalación con scripts en las reglas globales` (`.claude/CLAUDE.md` y `openspec/config.yaml`, con el impacto en el cuerpo);
6. `docs: scripts de instalación y sincronización en las guías, ADR y visión` (README, guías, READMEs de `templates/`, `docs/adr/` y `docs/arquitectura/vision.md`);
7. `chore: sincronizar copilot-instructions del repo` (`.github/copilot-instructions.md`).

## ADR

```markdown
# 0001. Fuente única de las reglas del Agente, generada con PowerShell 7

Estado: aceptada
Fecha: 2026-11-10
Change: sincronizar-reglas

## Contexto

Las reglas del Agente estaban copiadas a mano en cuatro plantillas (`AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc` y `GEMINI.md`) y en el `CLAUDE.md` global, y la instalación en cada máquina y en cada proyecto se hacía copiando archivos con los comandos del README. Las copias se desincronizaron sin que nada lo detectara: la `.github/copilot-instructions.md` de este repo había perdido las 8 reglas de ejecución. Cada change de reglas repetía la misma edición cuatro veces y tareas manuales de comparar hashes.

## Alternativas

- **Seguir copiando a mano con un checklist:** no detecta la desincronización; es lo que falló.
- **Un solo archivo de reglas y que cada agente lea ese archivo:** Cursor exige `.mdc` con frontmatter, Copilot busca `.github/copilot-instructions.md` y Antigravity `~/.gemini/GEMINI.md`; cada uno tiene además partes propias (comandos permitidos, reglas mínimas). No hay un formato que lean los cuatro.
- **Generar con Python, Node o una herramienta de plantillas:** suma un runtime o una dependencia que el workflow no necesita hoy. PowerShell 7 ya es el shell del workflow (perfil con `OBSIDIAN_VAULT` y `SDD_CONFIG_REPO`) y está en los runners de GitHub.
- **Generar también el `CLAUDE.md`:** es la fuente canónica de Claude y del espejo del vault, y sus reglas están en tercera persona. Se controla que tenga los mismos títulos de reglas, sin generarlo.

## Decisión

Las partes compartidas de las plantillas viven en `templates/fuente/fragmentos/` y cada plantilla tiene un esqueleto en `templates/fuente/esqueletos/` con marcas de inclusión. `scripts/generar-plantillas.ps1` (PowerShell 7, sin librerías externas) genera las cuatro plantillas, y con `-Comprobar` hace fallar el CI si alguna difiere o si los títulos de las reglas del `CLAUDE.md` no coinciden. La instalación por máquina (`scripts/instalar.ps1`) y por proyecto (`scripts/sincronizar-proyecto.ps1`) también son scripts de PowerShell 7, con chequeo de cambios locales y una sección `## Propio del proyecto` que se conserva.

## Consecuencias

- Positivas: una regla del Agente se edita una vez; la desincronización falla en el PR; instalar y sincronizar es un comando con el mismo control que antes se hacía a mano; los changes de reglas pierden las tareas de copiar y comparar.
- Negativas: las plantillas no se editan directamente (hay que editar la fuente y regenerar); los scripts son código que hay que mantener y testear; el workflow queda atado a PowerShell 7; la primera sincronización de un proyecto con contenido propio sin marcar requiere una fusión a mano.
```

## Visión inicial

```markdown
# Visión de arquitectura: sdd-global-config

## Propósito
Configuración global del workflow SDD Híbrido (Claude arquitecto + Agente constructor). Ver la descripción y `## Objetivos de Negocio` (U-01 a U-03 y OBJ-01 a OBJ-06) en `openspec/config.yaml`.

## Contexto e integraciones
- Actores: usuario del workflow, Claude (arquitecto de software), Agente (constructor: Antigravity, Cursor, Copilot u otro) y mantenedor de este repositorio.
- Sistemas externos: OpenSpec CLI (artefactos y validación), GitHub (`gh`, PR y Actions), vault de Obsidian versionado en git (contexto, notas y espejo de reglas), y las carpetas de instalación `~/.claude/` y `~/.gemini/` de cada máquina.

## Componentes
- `.claude/CLAUDE.md`: reglas globales de Claude; se instala en `~/.claude/CLAUDE.md` y se espeja en el vault.
- `.claude/commands/`: comandos de Claude Code, con el mismo texto que su skill.
- `skills/`: skills de Claude que se instalan en `~/.claude/skills/`.
- `templates/`: plantillas de reglas y configuración para agentes no-Claude. Las de reglas se generan desde `templates/fuente/`.
- `scripts/`: generación de plantillas, instalación por máquina y sincronización por proyecto (PowerShell 7).
- `tests/`: tests de los scripts.
- `.github/workflows/`: `pr-check.yml` (convenciones de PR, se copia a los proyectos) y `plantillas.yml` (tests y control de plantillas de este repo).
- `openspec/`: specs vigentes del workflow y changes.
- `docs/`: guías, SRS, ADRs y esta visión.

## Decisiones vigentes
- [0001. Fuente única de las reglas del Agente, generada con PowerShell 7](../adr/0001-fuente-unica-de-reglas-con-powershell.md)

## Hoja de ruta
- [media] cada comando de `.claude/commands/` repite el texto de su skill y la paridad se controla a mano en cada apply — origen: changes anteriores — propuesta: generar los comandos desde las skills con el mismo mecanismo de `templates/fuente/`, o sumar su comparación a `-Comprobar`
- [baja] las reglas del Agente siguen escritas dos veces (plantillas en segunda persona y `CLAUDE.md` en tercera); el CI solo compara los títulos — origen: ADR 0001 — propuesta: evaluar una sola redacción si los textos empiezan a divergir
- [baja] el `CLAUDE.md` global supera las 4.000 palabras y crece con cada change — origen: rol-arquitecto-software — propuesta: mover el detalle operativo a las skills y dejar en el `CLAUDE.md` solo reglas y tablas
- [baja] la ficha de este repo no declara `## Alcance`, `## Datos`, `## Stack` ni `## Calidad`, y `## Arquitectura` no declara `nivel` — origen: ficha del proyecto — propuesta: correr `/ficha` y `/arquitectura`
```

## Impacto en el sistema

**Componentes afectados:**
- Todos los proyectos que usan el workflow: sus `AGENTS.md`, `.github/copilot-instructions.md` y `.cursor/rules/sdd-workflow.mdc` pasan a tener el aviso de archivo generado y `## Propio del proyecto` la próxima vez que se sincronicen. La primera sincronización frena en los que tienen contenido propio sin marcar.
- Cada máquina: `~/.claude/` suma el manifiesto `.sdd-global-config.json`; `~/.gemini/GEMINI.md` suma la sección propia.
- Vault: el espejo `_global/reglas-globales.md` lo escribe el script, con el mismo formato que el comando del `CLAUDE.md`.
- Changes futuros de este repo: las tareas de instalación pasan a ser correr `scripts/instalar.ps1` y pegar su salida. `clasificacion-odd-sdd` (en pausa) tiene que editar `templates/fuente/` en vez de las cuatro plantillas y reemplazar su `## Visión inicial` por una actualización de esta visión.
- Specs vigentes: `agent-templates` y `project-onboarding` (modificadas); `rules-sync` (nueva).
- Skills y comandos `/opsx:*`: sin cambios.

**Atributos de calidad:** sin `## Calidad` declarada en este repo. Mantenibilidad: mejora (una regla se edita una vez y la desincronización se detecta en el PR), a cambio de unas 600 líneas de scripts y tests para mantener.

**Decisiones de arquitectura:** ADR nuevo: 0001.

**Deuda técnica:**
- Paga: las cuatro plantillas del Agente copiadas a mano, y la instalación manual con comparación de hashes en cada change.
- Agrega: las reglas del Agente siguen en dos redacciones (plantillas y `CLAUDE.md`), controladas solo por títulos.
- Descubre: la paridad skill/comando sigue manual; el `CLAUDE.md` largo; la ficha incompleta. Las tres van a la hoja de ruta.

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `templates/fuente/fragmentos/*.md`, `templates/fuente/esqueletos/*` | `templates/` (subcarpeta) |
| `scripts/comun.ps1`, `scripts/generar-plantillas.ps1`, `scripts/instalar.ps1`, `scripts/sincronizar-proyecto.ps1` | `scripts/` (nueva) |
| `tests/apoyo.ps1`, `tests/ejecutar.ps1`, `tests/*.Tests.ps1`, `tests/datos/plantillas-antes/*` | `tests/` (nueva) |
| `.github/workflows/plantillas.yml` | `.github/` (implícita) |
| `docs/adr/0001-fuente-unica-de-reglas-con-powershell.md`, `docs/arquitectura/vision.md` | `docs/` (implícita) |

`scripts/` y `tests/` no están declaradas: los scripts no son skills ni plantillas, y los tests son de los scripts. La tarea 5.2 las agrega a `## Arquitectura`: `- scripts/: generación de plantillas, instalación y sincronización (PowerShell 7)` y `- tests/: tests de los scripts`.

Sin `## Recomendación de arquitectura`: el change no modifica ni agranda archivos de código existentes (el repo no tiene código fuera de `.claude/statusline.sh`).

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA y scripts que escriben en la máquina.
- Sin secrets ni rutas con el usuario local en scripts, fuente, plantillas generadas ni `CLAUDE.md`: las rutas salen de `$HOME`, `-Vault`/`OBSIDIAN_VAULT` y `$PSScriptRoot`. — Verificación: S20.
- Los scripts no pisan contenido propio sin avisar: chequeo de cambios locales y respaldo con `-Forzar`. — Verificación: S07, S08 y S16.
- Los tests nunca escriben en el `$HOME` real ni en el vault real. — Verificación: revisión del diff: todo test pasa `-Destino` y `-Vault` de una carpeta temporal, y `tests/ejecutar.ps1` redefine `HOME` y `OBSIDIAN_VAULT`.
- `instalar.ps1` solo agrega al índice del vault `_global/reglas-globales.md`, no cambia la cuenta de `gh` y no fuerza el push. — Verificación: S09 y revisión del diff: un único `git add` con esa ruta y ningún `gh auth`.
- Los scripts no ejecutan texto que venga de los archivos que leen (sin `Invoke-Expression` ni `iex`). — Verificación: revisión del diff: ninguna aparición de `Invoke-Expression` ni `iex` en `scripts/` y `tests/`.
- `sincronizar-proyecto.ps1` no commitea, no pushea ni crea ramas en el proyecto. — Verificación: S18.
- Commit aparte del `CLAUDE.md` con el impacto (D12). — Verificación: revisión del historial de la rama.

## Impacto en proyectos existentes

- **Proyectos con plantillas copiadas tal cual:** la primera sincronización las reconoce por la historia de git y las actualiza, sumando el aviso y `## Propio del proyecto`.
- **Proyectos con contenido propio en `AGENTS.md` o en las reglas de Copilot o Cursor:** la primera sincronización frena en ese archivo. Se mueve el contenido propio debajo de `## Propio del proyecto` del archivo generado (o se corre con `-Forzar` y se fusiona desde el respaldo), una sola vez.
- **Máquinas ya instaladas:** el primer `instalar.ps1` no tiene manifiesto; reconoce las copias viejas por la historia y frena solo ante cambios locales reales.
- **`GEMINI.md` en `~/.gemini`:** si se le agregó contenido a mano, el primer `instalar.ps1` lo reporta como cambio local y frena.
- El contenido de las reglas no cambia: los agentes leen lo mismo que hoy.

## Risks / Trade-offs

- [Alguien edita una plantilla generada a mano] → El CI lo detecta con `-Comprobar`, y el aviso de la primera línea dice dónde editar.
- [La historia de git no está disponible (clon superficial)] → Las versiones viejas no se reconocen y el script frena como `bloqueado` o `con cambios locales`: falla del lado seguro. El CI usa `fetch-depth: 0`.
- [Diferencias de fin de línea entre Windows y el CI] → Toda comparación normaliza CRLF y BOM, y los archivos se escriben con LF.
- [Atar el workflow a PowerShell 7] → Ya es requisito del workflow; queda registrado en el ADR 0001.
- [El `CLAUDE.md` y la fuente divergen en el texto de una regla con el mismo título] → El CI solo mira títulos; queda como deuda `[baja]` en la hoja de ruta.

## Migration Plan

Primero se crea la fuente con el texto actual (C01 en verde antes y después), se generan las plantillas y se prueban los scripts con fixtures. Después se corre `instalar.ps1 -Simular` y `instalar.ps1` en la máquina del apply (reemplaza la sección de instalación manual de los changes anteriores), y `sincronizar-proyecto.ps1` en este repo. En cada proyecto, la próxima vez que se toquen sus reglas se corre `sincronizar-proyecto.ps1`. Rollback: revertir el PR y volver a copiar a mano con los comandos del README anterior; los manifiestos y las secciones `## Propio del proyecto` que hayan quedado no rompen nada.

## Test Plan

Comando de tests: `pwsh -NoProfile -File tests/ejecutar.ps1` (nuevo; lo declara la tarea 5.2), timeout 5 minutos. Se fuerza la suite completa en el verify porque es la primera vez que el repo tiene tests. Cada test automático lleva en su nombre el ID (por ejemplo `S03 comprobar falla si una plantilla se editó a mano`) y el comentario `# test-plan: sincronizar-reglas/<ID>`.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Generación / Plantillas desde la fuente | auto | `tests/generar-plantillas.Tests.ps1` |
| S02 | Generación / Fragmento inexistente | auto | `tests/generar-plantillas.Tests.ps1` |
| S03 | Control / Plantilla editada a mano | auto | `tests/generar-plantillas.Tests.ps1` |
| S04 | Control / Títulos del `CLAUDE.md` distintos | auto | `tests/generar-plantillas.Tests.ps1` |
| S05 | Control / Todo sincronizado | auto | `tests/generar-plantillas.Tests.ps1` |
| S06 | Instalación / Destino vacío | auto | `tests/instalar.Tests.ps1` |
| S07 | Instalación / Cambio local | auto | `tests/instalar.Tests.ps1` |
| S08 | Instalación / Forzar con respaldo | auto | `tests/instalar.Tests.ps1` |
| S09 | Instalación / Espejo del vault | auto | `tests/instalar.Tests.ps1` |
| S10 | Instalación / Sin vault | auto | `tests/instalar.Tests.ps1` |
| S11 | Instalación / `GEMINI.md` con contenido propio | auto | `tests/instalar.Tests.ps1` |
| S12 | Instalación / Simular | auto | `tests/instalar.Tests.ps1` |
| S13 | Proyecto / Proyecto nuevo | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S14 | Proyecto / Conserva lo propio | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S15 | Proyecto / Copia vieja reconocida | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S16 | Proyecto / Contenido propio sin marcar | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S17 | Proyecto / Comprobar | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S18 | Proyecto / Sin commits en el proyecto | auto | `tests/sincronizar-proyecto.Tests.ps1` |
| S19 | CI / Workflow de plantillas | manual: revisar `.github/workflows/plantillas.yml` en el diff (checkout con `fetch-depth: 0` y los tres pasos de D8) y que el check corra en verde en el PR del change | `.github/workflows/plantillas.yml` |
| S20 | Seguridad / Sin rutas personales | manual: un script en archivo busca el nombre de la carpeta del usuario, `C:\Users`, `Invoke-Expression` e `iex` en `scripts/`, `tests/`, `templates/` y `.claude/CLAUDE.md`, sin resultados | `scripts/`, `tests/`, `templates/` |
| S21 | Plantillas / Aviso y sección propia | auto | `tests/generar-plantillas.Tests.ps1` |
| S22 | Onboarding / Setup con script | manual: `Select-String` de `scripts/instalar.ps1` en el setup de `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`, y ningún `cp skills` ni `cp .claude` en esas secciones | guías |
| S23 | Onboarding / Proyecto con script | manual: `Select-String` de `sincronizar-proyecto.ps1` en "Sumar un proyecto al workflow" de las tres guías, y ningún `cp` de plantillas de reglas | guías |
| S24 | Onboarding / `GEMINI.md` con script | manual: el paso de Antigravity de `README.md` y `docs/modo-de-uso.md` usa `scripts/instalar.ps1` y menciona `~/.gemini/GEMINI.md` | guías |
| S25 | Este repo sincronizado | manual: después de la tarea 6.3, `sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` termina con código 0 | `.github/copilot-instructions.md` |
| S26 | ADR y visión | manual: `docs/adr/0001-fuente-unica-de-reglas-con-powershell.md` y `docs/arquitectura/vision.md` son iguales al contenido de los bloques de `## ADR` y `## Visión inicial` del design | `docs/` |

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc`, `templates/antigravity/GEMINI.md` | Copia de las cuatro en `tests/datos/plantillas-antes/` antes de tocarlas. El test compara cada plantilla, sin la línea de aviso con su línea en blanco y sin el bloque final de `## Propio del proyecto`, con su copia: tienen que ser iguales | Se suman el aviso y `## Propio del proyecto` (S21); el resto del texto no cambia |

## Open Questions

Sin preguntas abiertas. Decisiones tomadas en el propose, para revisar al aprobar el change:
- PowerShell 7 sin librerías de tests (ADR 0001), y `## Tests` deja de ser `ninguno`.
- El `CLAUDE.md` no se genera; el CI compara los títulos de sus reglas con la fuente.
- `pr-check.yml` no cambia; el CI propio de este repo va en `plantillas.yml`.
