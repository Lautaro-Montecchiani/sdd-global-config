# Tasks

Sin tests automáticos (`comando: ninguno`). La evidencia de cada tarea es la salida de consola pegada en el resumen del apply.

## 1. Skill arquitectura y recetas

- [ ] 1.1 Crear `skills/arquitectura/references/recetas.md` con la tabla de design D1 al principio, la línea de que los nombres de carpeta son sugerencias y las cinco recetas de design D2 (`1-nucleo-funcional`, `2-tuberias`, `2-capas`, `3-hexagonal`, `3-modular`), cada una con las siete partes en el orden de D2. Evidencia: `Select-String -Path skills/arquitectura/references/recetas.md -Pattern "^\*\*Señales\*\*","^\*\*Cuándo no aplicarla\*\*"` (o el encabezado que se use para cada parte), con 5 coincidencias de cada una.
- [ ] 1.2 Crear `skills/arquitectura/SKILL.md` con frontmatter `name: arquitectura` y una `description` que diga que diagnostica la arquitectura de un proyecto existente y recomienda un nivel sin crear un change. Cuerpo con los pasos 1 a 6 de design D5, que remiten a `references/recetas.md`, con las restricciones de D5 (solo lectura salvo el paso 6, sin changes, ramas, commits ni vault) y las de la Security Layer (no leer lo ignorado ni `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`; no pegar contenido de archivos; no ejecutar código). Evidencia: el frontmatter y la lista de pasos pegados en el resumen.
- [ ] 1.3 Verificar con un script en archivo que `skills/arquitectura/` no contiene `C:\Users` ni rutas absolutas, y pegar la salida.

## 2. Propose y verify (skill y comando)

- [ ] 2.1 En `skills/openspec-propose/SKILL.md` **y** `.claude/commands/opsx/propose.md`:
  - paso 0: escribir `- tamaño: 500, 1000` cuando se escribe `## Arquitectura` por primera vez en un repo sin archivos de código fuera de las carpetas implícitas (design D4.1);
  - en "Artifact Creation Guidelines", para `design.md`: detección de señales con las recetas instaladas, sección `## Recomendación de arquitectura` antes de `## Ubicación de archivos` con sus subsecciones, la pregunta de tres opciones y qué hace cada una (design D4.2 a D4.4), y el aviso si las recetas no están instaladas;
  - paso 7: el commit de artefactos incluye `openspec/config.yaml` cuando el propose lo modificó (D4.5).

  El texto agregado tiene que ser idéntico en los dos archivos. Evidencia: `diff` de las secciones agregadas entre los dos archivos, sin diferencias.
- [ ] 2.2 En `skills/openspec-verify-change/SKILL.md` **y** `.claude/commands/opsx/verify.md`, dentro de "Architecture Verification" de los dos flujos (con Test Plan y legacy), después de "Tool", agregar **Nivel** y **Tamaño** con las extensiones, exclusiones y severidades de design D6. Sumar las dos filas a la tabla `Arquitectura | Resultado` y la WARNING y las dos SUGGESTION a "Issues by Priority". Texto idéntico en los dos archivos. Evidencia: igual que en 2.1.
- [ ] 2.3 Commit aparte con `skills/arquitectura/`, las skills y los comandos de 2.1 y 2.2: `feat: asesor de arquitectura en propose, verify y skill /arquitectura`, con un único bloque final de trailers que incluya `Spec-ID: asesor-de-arquitectura`.

## 3. CLAUDE.md global

- [ ] 3.1 En `.claude/CLAUDE.md`, sección `## Arquitectura del proyecto`, aplicar design D7: claves reservadas `nivel`, `tamaño` y `tamaño-excluir`; subsección `### Escalera de niveles` antes de "Responsabilidades por actor", con la tabla y las dos líneas de referencia; las líneas nuevas de "Responsabilidades por actor". Evidencia: el bloque de la sección pegado en el resumen.
- [ ] 3.2 En `.claude/CLAUDE.md`, agregar al final de la regla 8 la oración literal de design D7. Evidencia: `Select-String -Path .claude/CLAUDE.md -SimpleMatch -Pattern "aplicá sus pautas para el Agente aunque el verify no pueda controlarlas"`.
- [ ] 3.3 Verificar con un script en archivo que `.claude/CLAUDE.md` no contiene `C:\Users`, y pegar la salida.
- [ ] 3.4 Commit aparte, solo con `.claude/CLAUDE.md`: `feat: escalera de niveles y señal de tamaño en CLAUDE.md`. El cuerpo describe el impacto: aplica a todos los proyectos, sin `nivel` ni `tamaño` no se reporta nada nuevo, y la regla 8 suma las pautas de la recomendación. Un único bloque final de trailers con `Spec-ID: asesor-de-arquitectura`.

## 4. Plantillas, guía y documentación

- [ ] 4.1 Agregar al final de la regla 8 la oración literal de design D7 en `templates/comun/AGENTS.md`, `templates/copilot/copilot-instructions.md`, `templates/cursor/sdd-workflow.mdc` y `templates/antigravity/GEMINI.md`. Evidencia: `Select-String -Path templates/*/* -SimpleMatch -Pattern "aplicá sus pautas para el Agente aunque el verify no pueda controlarlas"`, con 4 coincidencias.
- [ ] 4.2 Crear `docs/guia-arquitecturas.md` con las seis secciones de design D9. El catálogo tiene una subsección por cada uno de los 15 ítems, con **Qué es**, **Ejemplo tipo Yacopini** y **¿Te va a tocar?**. Evidencia: `Select-String -Path docs/guia-arquitecturas.md -Pattern "¿Te va a tocar\?"`, con 15 coincidencias, y la lista de encabezados `##`/`###` pegada en el resumen.
- [ ] 4.3 En `README.md` y `docs/workflow.md`, agregar una línea que explique la escalera de niveles, la skill `/arquitectura` y la guía `docs/guia-arquitecturas.md`. Evidencia: el diff.
- [ ] 4.4 Verificar con un script en archivo que `docs/guia-arquitecturas.md` y las 4 plantillas no contienen `C:\Users`, y pegar la salida.
- [ ] 4.5 Commit aparte: `docs: guía de arquitecturas y regla 8 con pautas de la recomendación`, con un único bloque final de trailers que incluya `Spec-ID: asesor-de-arquitectura`.

## 5. Instalación (para que aplique en otros repos)

- [ ] 5.1 Antes de copiar, para `CLAUDE.md`, cada `skills/*/SKILL.md` y cada `.claude/commands/opsx/*.md`, comparar la copia instalada en `~/.claude` con `git show master:<ruta>`, ignorando el fin de línea. Si alguna instalada tiene líneas que no están en la versión de `master`, **frenar y preguntar** (design D10). Evidencia: lista de archivos con "igual a master", "atrasado respecto de master" o "con cambios locales".
- [ ] 5.2 Copiar a `~/.claude` el `CLAUDE.md`, **todas** las carpetas de `skills/` (incluida `skills/arquitectura/` con `references/`) y **todos** los comandos de `.claude/commands/opsx/`. Copiar `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`. Evidencia: tabla con el hash de cada archivo del repo y del instalado, ignorando el fin de línea, todos iguales, incluido `~/.claude/skills/arquitectura/references/recetas.md`.
- [ ] 5.3 Re-sincronizar el espejo `$env:OBSIDIAN_VAULT\_global\reglas-globales.md` con el comando de la sección "Comandos PowerShell" del `CLAUDE.md`, commitear en el vault (`chore: sdd-global-config — sync reglas asesor-de-arquitectura`) y pushear. Verificar que el espejo contiene "Escalera de niveles". Si el push falla por la cuenta de GitHub, avisar sin forzar.

## 6. Verificación con Claude (no la ejecuta el Agente)

- [ ] 6.1 S03, S04, S16–S20, S23–S26 por revisión de los archivos y con los `grep` del Test Plan.
- [ ] 6.2 S01, S06 y S13 en una sesión **nueva** de Claude Code en el repo descartable E; S10 en una sesión nueva en el repo D (design, Test Plan).
- [ ] 6.3 S02, S05, S07–S09, S11, S12, S14 y S15 en sesiones **nuevas** de Claude Code en el repo descartable C, restaurándolo entre escenarios.
- [ ] 6.4 S21, S22 y S27–S36 con `/opsx:verify` en sesiones nuevas en el repo descartable F, con las variantes de `## Arquitectura` del Test Plan.
- [ ] 6.5 Verificar que el cambio aplica en un proyecto de prueba

## Workflow follow-up

- Abrir PR `[asesor-de-arquitectura] Asesor de arquitectura incremental: escalera de niveles y señal de tamaño` desde `change/asesor-de-arquitectura`, con `Closes #26`.
- `/opsx:verify asesor-de-arquitectura` antes del merge y `/opsx:archive` después.
- Fuera de este repo: correr `/arquitectura` en `PLANEAMIENTO` como primer caso real.
- Temas aparte, sin change: código duplicado entre los `scrapingExodo-*` y la señal de funciones largas.
