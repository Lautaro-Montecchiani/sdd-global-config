# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply.

## 1. CLAUDE.md global

- [x] 1.1 En `.claude/CLAUDE.md`, sección "Reglas de ejecución del Agente": agregar la regla 8 con el texto literal de design D5 y cambiar "estas mismas 7 reglas" por "estas mismas 8 reglas". Evidencia: `Select-String -Path .claude/CLAUDE.md -Pattern "Respetar la arquitectura","estas mismas 8 reglas"`.
- [x] 1.2 En `.claude/CLAUDE.md`, agregar la sección `## Arquitectura del proyecto` después de "Capa de Seguridad por Tipo de Proyecto", con:
  - el formato de `## Arquitectura` de design D2: línea por carpeta, `| no importa:`, claves reservadas `comando`/`timeout`/`estado` y carpetas implícitas;
  - la tabla de 6 filas de design D3, presentada como punto de partida;
  - una línea por cada actor: propose pide o infiere (D4), regla 8 (D5) y verify controla el diff (D6, con las severidades WARNING/CRITICAL/SUGGESTION).

  Evidencia: el bloque de la sección pegado en el resumen.
- [x] 1.3 En `.claude/CLAUDE.md`, en `### fullstack` de la Security Layer, agregar el control de `server-only` de design D3. Evidencia: `Select-String -Path .claude/CLAUDE.md -Pattern "server-only"`.
- [x] 1.4 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users`, y pegar la salida.
- [x] 1.5 Commit aparte, solo con `.claude/CLAUDE.md`: `feat: regla global de arquitectura de carpetas en CLAUDE.md`. El cuerpo describe el impacto: la regla 8 del Agente, la sección nueva, que aplica a todos los proyectos y que los que no tienen `## Arquitectura` no se rompen. Un único bloque final de trailers con `Spec-ID: arquitectura-de-carpetas`.

## 2. Skills y comandos de propose y verify

- [x] 2.1 En `skills/openspec-propose/SKILL.md` **y** `.claude/commands/opsx/propose.md`, paso 0:
  - leer `## Arquitectura`; si falta, pedirla una vez, en la misma pregunta que `project_type` y `## Tests` si faltan;
  - armar la propuesta inferida y las opciones de design D4; con "no sé", escribir `- estado: inferido — revisar`;
  - escritura quirúrgica con el aviso de 40 KB.

  En "Artifact Creation Guidelines": `design.md` lleva `## Ubicación de archivos` antes de `## Security Layer` y, si hace falta una carpeta nueva, `tasks.md` lleva la tarea para agregarla (D4). El texto agregado tiene que ser idéntico en los dos archivos. Evidencia: `diff` de las secciones agregadas entre los dos archivos, sin diferencias.
- [x] 2.2 En `skills/openspec-verify-change/SKILL.md` **y** `.claude/commands/opsx/verify.md`, agregar el paso "Arquitectura" de design D6:
  - en el flujo con Test Plan, dentro de "Verify Coherence & Generate Report";
  - en el flujo legacy, dentro de "Verify Coherence";
  - la tabla `Arquitectura | Resultado` en el reporte;
  - las severidades en "Issues by Priority".

  Texto idéntico en los dos archivos. Evidencia: igual que en 2.1.
- [x] 2.3 Commit aparte: `feat: propose y verify usan la arquitectura declarada`, con trailer `Spec-ID: arquitectura-de-carpetas`.

## 3. Plantillas y documentación

- [x] 3.1 Agregar la regla 8 (texto literal de design D5) en `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`, y cambiar cualquier "7 reglas" por "8 reglas". Evidencia: `Select-String -Path templates/*/* -Pattern "Respetar la arquitectura"`, con 4 coincidencias, y `Select-String -Path templates/*/* -Pattern "7 reglas"` sin resultados.
- [x] 3.2 En `README.md` y `docs/workflow.md`, agregar una línea que explique que cada proyecto declara `## Arquitectura` en su `context:` y que la estructura sugerida está en el `CLAUDE.md` global. Evidencia: el diff.
- [x] 3.3 Commit aparte: `docs: regla 8 de arquitectura en plantillas y guías`, con trailer `Spec-ID: arquitectura-de-carpetas`.

## 4. Instalación (para que aplique en otros repos)

- [x] 4.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada `.claude/commands/opsx/*.md`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D7). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master" o "con cambios locales".
- [x] 4.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` y **todos** los comandos de `.claude/commands/opsx/`. Copiar `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales.
- [x] 4.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas arquitectura-de-carpetas`) y pushear. Verificar que el espejo contiene "Respetar la arquitectura". Si el push falla por la cuenta de GitHub, avisar sin forzar.

## 5. Verificación con Claude (no la ejecuta el Agente)

- [x] 5.1 S02, S04, S05, S09, S10–S12, S18–S23 y S25–S27 por revisión de los archivos y con los `grep` del Test Plan.
- [ ] 5.2 S06–S08, S15 y S24 en una sesión **nueva** de Claude Code en el repo descartable A (design, Test Plan).
- [x] 5.3 S01, S03, S13, S14, S16 y S17 con `/opsx:verify` en una sesión nueva en el repo descartable B.
- [ ] 5.4 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[arquitectura-de-carpetas] Regla global de arquitectura de carpetas por proyecto` desde `change/arquitectura-de-carpetas`, con `Closes #24`.
- `/opsx:verify arquitectura-de-carpetas` antes del merge y `/opsx:archive` después.
- Fuera de este repo: change en `toyota-yacopini-web` para declarar su `## Arquitectura` y reordenar `src/`.
