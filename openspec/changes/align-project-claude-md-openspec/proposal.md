## Why

Tres proyectos (`normalizacionLeads-contactacion`, `interfaz-formulario-licitación`, `seguimiento-Suscripciones`) tienen un `CLAUDE.md` propio que describe el flujo SDD manual con Copilot: crear `spec.yaml` y `Task.md` en `specs/`, seguir las fases OPCX y "generar el prompt para Copilot". Esos archivos se cargan junto con las reglas globales en cada sesión y las contradicen: en modo OpenSpec el flujo es `/opsx:propose` en `openspec/changes/` y handoff con `/openspec-apply-change`, sin prompts manuales. Con las copias locales de comandos y skills ya limpiadas, estos `CLAUDE.md` son lo último que puede desviar a Claude del workflow global.

## What Changes

- `seguimiento-Suscripciones/CLAUDE.md` (455 líneas): se conserva solo lo propio del proyecto (descripción, arquitectura, contratos de comportamiento, reglas de arquitectura, watchlist y estado) y se agrega una sección corta "Workflow SDD / OpenSpec" que remite a `~/.claude/CLAUDE.md`. Se elimina el manual SDD copiado dentro del archivo (roles, fases OPCX, plantillas, prompts para Copilot, estrategia de modelos, migración, roadmap) y las rutas con el usuario local.
- `interfaz-formulario-licitación/CLAUDE.md` (36 líneas): se reemplaza la sección "Rol de Claude en este proyecto" y las "Reglas globales" del flujo manual por la sección "Workflow SDD / OpenSpec". Se conservan el stack, las restricciones de GAS, los IDs de recursos y los riesgos pendientes; la tabla de features pasa a presentarse como specs legacy de referencia.
- `normalizacionLeads-contactacion/CLAUDE.md`: mismo criterio, en la máquina donde el repo esté disponible.
- Nueva spec `project-claude-md` que define qué contiene y qué no contiene el `CLAUDE.md` de un proyecto que usa OpenSpec.
- Cada cambio se hace en una rama `change/align-project-claude-md-openspec` del repo del proyecto, con un commit aislado que incluye solo `CLAUDE.md` y el trailer `Spec-ID`. No se pushea.

**Archivo global:** no se modifica ninguno (`~/.claude/CLAUDE.md`, skills, comandos ni el espejo del vault). El desvío está en los `CLAUDE.md` de proyecto, que son los que contradicen a las reglas globales; las reglas globales ya son correctas.

## Capabilities

### New Capabilities
- `project-claude-md`: contenido mínimo y prohibido del `CLAUDE.md` de un proyecto que usa OpenSpec, para que no contradiga las reglas globales.

### Modified Capabilities
<!-- Ninguna: no cambian requisitos de specs existentes. -->

## Non-goals

- No modificar `~/.claude/CLAUDE.md`, skills, comandos `/opsx` ni el espejo `_global` del vault.
- No modificar `automation-server`: su `CLAUDE.md` ya remite a las reglas globales.
- No tocar código, CI (`.github/workflows/`), `specs/` legacy, `change-map.md`, `.github/copilot-instructions.md` ni `openspec/config.yaml` de los proyectos.
- No revisar la vigencia del contenido propio de cada proyecto (contratos, IDs, estado): se conserva tal cual.
- No crear una plantilla de `CLAUDE.md` de proyecto ni scripts versionados; el chequeo se hace con un script temporal fuera del repo.
- No pushear, abrir PRs ni limpiar el trabajo en curso de los proyectos.

## Impact

- Archivos modificados fuera de este repo: `CLAUDE.md` de `seguimiento-Suscripciones`, `interfaz-formulario-licitación` y, si está disponible, `normalizacionLeads-contactacion`.
- En este repo: solo artefactos del change; al archivar, la spec `project-claude-md` se sincroniza a `openspec/specs/`.
- `normalizacionLeads-contactacion` no está en la carpeta de proyectos de la máquina donde se propone este change: su parte queda condicionada a que el repo esté disponible.
- Las sesiones de Claude ya abiertas en esos proyectos siguen con el `CLAUDE.md` viejo hasta reiniciarlas.
