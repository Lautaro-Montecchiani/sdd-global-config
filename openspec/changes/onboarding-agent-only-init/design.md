## Context

`openspec init --tools claude,<agente>` deja en cada proyecto una copia local de los comandos `/opsx` y de las skills `openspec-*` en su versión por defecto. En Claude Code, lo que hay en el proyecto manda sobre lo global, así que esas copias pisan el workflow híbrido (handoff al Agente, lectura y escritura del vault, rama `change/<nombre>`). Un relevamiento en 12 proyectos mostró que todos las tenían, en dos versiones estándar de OpenSpec (1.3.1 y 1.4.1) y sin personalizaciones relevantes, salvo un `verify.md` viejo en un proyecto.

Pruebas en carpetas temporales:
- `openspec init --tools <agente>` crea solo las skills del Agente (`.agent/skills/`) y `openspec/`; no crea `.claude/` ni siquiera tras `openspec update`.
- `openspec init --tools none` crea solo `openspec/changes` y `openspec/specs`.
- Con `.claude/` borrado, `openspec update` no lo recrea.

El setup por máquina de las guías copia solo algunas skills a `~/.claude` y ningún comando `/opsx`, y omite `openspec-explore`.

## Goals / Non-Goals

**Goals:**
- Que ningún proyecto nuevo genere copias locales de Claude que pisen las globales.
- Que el setup por máquina deje instalado todo lo que hace falta en `~/.claude`.
- Documentar cómo limpiar los proyectos que ya tienen esas copias.

**Non-Goals:**
- No modificar skills, comandos ni `CLAUDE.md`.
- No ejecutar la limpieza ni crear scripts.
- No tocar los `CLAUDE.md` propios de los proyectos.

## Decisions

### D1: Iniciar con `--tools <agente>`, sin `claude`

Alternativas consideradas:
- `--tools claude,<agente>` y borrar las copias después (el procedimiento actual) — descartada: es frágil, ya falló en la práctica y obliga a recordar borrar varios archivos.
- `--tools none` — descartada: no genera las skills del Agente, que el Agente necesita para implementar.
- `--tools <agente>` — genera lo que el Agente necesita y nada de Claude.

**Decisión:** `--tools <agente>`.

### D2: El setup por máquina instala comandos y todas las skills

Se copia `skills/*` completo a `~/.claude/skills/` y `.claude/commands/opsx/*.md` a `~/.claude/commands/opsx/`. Alternativa descartada: seguir listando cada skill por separado, porque ya dejó afuera `openspec-explore`.

### D3: Limpieza documentada, no automatizada

Las guías describen eliminar `.claude/commands/opsx/` y `.claude/skills/openspec-*` en un commit aparte desde la rama principal. Meterla en una rama `change/…` mezclaría un commit sin el `Spec-ID` de ese change. No se crea un script: sería código y queda fuera de alcance.

## Risks / Trade-offs

- **[Riesgo] Un proyecto con una copia local personalizada la pierde al limpiarla** → El relevamiento mostró una sola diferencia (un `verify.md` viejo); la guía indica revisar el diff contra la versión estándar antes de borrar si hay dudas.
- **[Riesgo] Una versión futura de `openspec update` recrea las copias** → Se verificó con la versión actual; la spec incluye un escenario de prueba para repetir el chequeo cuando se actualice OpenSpec.
- **[Riesgo] Copiar `skills/*` con `cp -r` pisa skills locales con el mismo nombre** → Es el comportamiento buscado: el repo es la fuente canónica.
- **[Trade-off] Los proyectos ya iniciados con `claude` siguen con copias hasta que se limpien** → Se documenta el procedimiento y la limpieza se hace aparte, proyecto por proyecto.

## Security Layer

`project_type: tooling` — los artefactos gestionados son instrucciones y configuración para IA.

- No se versionan secrets ni credenciales ni paths con el usuario local; las guías usan variables de entorno y rutas relativas.
- Los comandos de limpieza documentados usan rutas explícitas y acotadas (`.claude/commands/opsx/` y `.claude/skills/openspec-*`) para no borrar otros archivos de `.claude/`, como `settings.local.json`.
- Verificación: buscar el nombre de usuario en las guías sin resultados y revisar `git diff --staged` antes de cada commit.

## Impacto en proyectos existentes

Solo cambia documentación de este repositorio. Los proyectos existentes no se ven afectados hasta que alguien siga el procedimiento de limpieza; la limpieza ya se aplicó, de forma operativa y fuera de este change, en los proyectos limpios y en ramas principales o con archivos sin versionar. Retrocompatibilidad: quien ya inició un proyecto con `claude` en `--tools` conserva sus copias locales hasta limpiarlas.

## Migration Plan

1. Actualizar el setup por máquina del `README.md` y de `docs/workflow.md`.
2. Cambiar los comandos de init y las secciones de onboarding de `docs/workflow.md` y `docs/modo-de-uso.md`.
3. Agregar el procedimiento de limpieza para proyectos existentes.
4. Regenerar `docs/modo-de-uso.docx`.
5. Verificar con un script y con una prueba en carpeta temporal.
6. Commit con `Spec-ID: onboarding-agent-only-init`.

Rollback: `git revert` del commit generado.

## Open Questions

Sin preguntas abiertas.
