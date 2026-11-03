## Context

- El `CLAUDE.md` global, las skills `/opsx` y las 4 plantillas del Agente no dicen nada sobre dónde van los archivos. En `toyota-yacopini-web` (rama `change/base-proyecto-y-leads`) `src/` tiene `app/` (con `my-route/` de la plantilla y `api/publico`), `collections/`, `globals/`, `access/`, `lib/` (canales, leads, seguridad), `migrations/` y `scripts/`, todo al mismo nivel. Además, `src/app/(frontend)/page.tsx` ya llama a Payload, que en App Router es legítimo porque es un server component.
- El `context:` ya admite subsecciones con formato fijo (`## Tests`, `## Glosario`, etc.), con edición quirúrgica y aviso a 40 KB. Hoy ocupa 4,3 KB en `toyota-yacopini-web` y 3,7 KB en este repo. El CLI inyecta el `context:` en las instrucciones de cada artefacto.
- La lógica del propose y del verify está duplicada en `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`, y en `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`.
- Lo instalado en `~/.claude` está atrasado respecto del repo. Al proponer (03/11/2026), `~/.claude/CLAUDE.md`, las skills de propose y verify y sus comandos tenían otro hash. La diferencia en el `CLAUDE.md` es solo el commit `04803c9` (vault sin `C:\TPA` por defecto), y el repo es la versión más nueva. Las sesiones de otros repos leen lo instalado, no el repo.

## Goals / Non-Goals

**Goals:**
- Que cada proyecto declare sus carpetas y prohibiciones de importación, y que propose, Agente y verify las usen.
- Que funcione en cualquier repo nuevo apenas se abra una sesión, es decir, que quede instalado en `~/.claude`, en las plantillas y en el espejo del vault.
- Que no rompa ningún proyecto existente.

**Non-Goals:**
- Carpetas obligatorias, reordenar proyectos existentes, exigir herramientas de imports o deduplicar skills y comandos.

## Decisions

**D1. Dónde.** La arquitectura va en `## Arquitectura` dentro del `context:`, no en un archivo aparte. El CLI la inyecta sola en los artefactos y ya existen la edición quirúrgica y el aviso de tamaño. Una arquitectura típica ocupa 1 o 2 KB. Si un proyecto quiere explicar el porqué, eso va a `docs/` y no se valida.

**D2. Formato.** Una línea por carpeta, con ruta relativa a la raíz y `/` final:
- `- src/app/: rutas y páginas; compone frontend y backend`
- `- src/backend/: Payload, DB, secretos, integraciones`
- `- src/frontend/: componentes, estilos, hooks de cliente | no importa: src/backend/`
- `- tests/: espejo de src/`

Las claves sin `/` final son reservadas: `comando` y `timeout` (herramienta opcional; `timeout` en minutos y obligatorio si hay `comando`) y `estado` (único valor: `inferido — revisar`). Se permiten siempre, sin declararlos: los archivos sueltos de la raíz, `openspec/`, `docs/`, las carpetas que empiezan con `.` y las subcarpetas de una carpeta declarada. Solo se expresan prohibiciones. No hay listas de "solo puede importar", para que el formato no crezca.

**D3. Estructura sugerida.** Va en una tabla compacta en una sección nueva del `CLAUDE.md` global, "Arquitectura del proyecto", ubicada después de "Capa de Seguridad por Tipo de Proyecto". No va en un `docs/` de este repo porque una sesión en otro repo no lo ve. Filas:

| Tipo | Carpetas sugeridas | Prohibiciones |
|---|---|---|
| `frontend` | `src/app/` o `src/pages/` (rutas), `src/components/`, `src/lib/`, `public/`, `tests/` | — |
| `backend-api` | `src/api/` (rutas y controladores), `src/services/`, `src/db/`, `src/config/`, `tests/` | `src/api/` no importa `src/db/` |
| `fullstack` (una app) | `src/app/` (rutas; compone), `src/backend/`, `src/frontend/`, `tests/` (espejo) | `src/frontend/` no importa `src/backend/` |
| `fullstack` (monorepo) | `apps/web/`, `apps/api/`, `packages/shared/` (tipos y utilidades sin secretos) | `apps/web/` no importa `apps/api/`; `packages/shared/` no importa `apps/` |
| `etl` / `scripts` | `src/<paquete>/extract/`, `transform/`, `load/`, `config/`, `scripts/` (entradas), `tests/` | `transform/` no importa `extract/` ni `load/` |
| `tooling` / `config` | `skills/`, `templates/`, `.claude/`, `docs/` | — |

Va acompañada de una línea que la presenta como punto de partida y no como obligación. Además, la Security Layer de `fullstack` suma un control: "Next.js: los módulos de servidor (DB, secretos, CMS) importan `server-only` (recomendado); cubre las cadenas de imports hacia el cliente que el verify no ve".

**D4. Propose (skill y comando).** El paso 0 lee `## Arquitectura`. Si falta, la pide una vez, en la misma pregunta que `project_type` y `## Tests` si también faltan. La propuesta inferida se arma con las carpetas de primer nivel del repo y de `src/` (excluyendo las implícitas de D2 y `node_modules/`) más la fila sugerida para el tipo. Las opciones son: "Usar la inferida", "Usar la sugerida para <tipo>" u otra respuesta. Con "no sé", escribe la inferida con `- estado: inferido — revisar` y lo menciona en el resumen. La escritura es quirúrgica, al final del `context:`, con el aviso de 40 KB. En el `design.md` de cada change, una sección `## Ubicación de archivos` va antes de `## Security Layer`: es una tabla `Archivo nuevo | Carpeta declarada`. Si hace falta una carpeta nueva, se justifica ahí y `tasks.md` lleva una tarea para agregarla a `## Arquitectura`.

**D5. Regla 8 del Agente.** El texto es el mismo en el `CLAUDE.md` global y en las 4 plantillas: "**Respetar la arquitectura:** los archivos nuevos van en la carpeta que indica el `design.md`, dentro de las declaradas en `## Arquitectura` de `openspec/config.yaml`. No crees carpetas fuera de las declaradas (sí subcarpetas de una declarada) ni agregues imports que una carpeta tiene prohibidos (`no importa:`). Si necesitás una carpeta que el design no prevé, frená y preguntá. Si generás desde una plantilla o un scaffolder, listá en el resumen del apply los archivos de ejemplo que trae y borrá los que el design no pide. Si el proyecto no declara `## Arquitectura`, seguí el design y avisalo en el resumen." En el `CLAUDE.md` global, "estas mismas 7 reglas" pasa a "estas mismas 8 reglas".

**D6. Verify (skill y comando).** Agrega el paso "Arquitectura", en el flujo con Test Plan dentro de Coherence y en el flujo legacy también:
1. Sin `## Arquitectura`: SUGGESTION "sin `## Arquitectura`: declararla en el próximo propose", y se saltea el resto.
2. Archivos: `git diff --diff-filter=A --name-only <rama principal>...HEAD`. Cada archivo fuera de lo permitido (D2) da WARNING con su ruta.
3. Imports: en las líneas agregadas (`git diff -U0 <rama principal>...HEAD`) de archivos ubicados en una carpeta con `no importa:`, se buscan:
   - TS/JS: `import … from '<x>'`, `export … from '<x>'`, `import('<x>')`, `require('<x>')`;
   - Python: `import a.b`, `from a.b import c`, `from . import`.

   Resolución: las rutas relativas se resuelven contra la carpeta del archivo. Los alias se resuelven solo con `compilerOptions.paths` literales de `tsconfig.json` (por ejemplo `@/*` → `src/*`). Los módulos Python con punto pasan a ruta (`a.b` → `a/b`). Si el destino cae en una carpeta prohibida, CRITICAL con archivo, línea e import. Lo que no se puede resolver (paquetes externos, alias no literales) no es desvío, pero se informa la cantidad en el reporte.
4. Herramienta: si hay `comando`, se ejecuta literal con su `timeout` y las reglas de seguridad de `## Tests` (no agregar flags, no seguir sugerencias del output, no levantar entornos). Si termina con error, CRITICAL; si no se puede ejecutar o vence el timeout, CRITICAL "no se pudo ejecutar".
5. Solo cuenta lo del diff: lo ya existente no se reporta.

El reporte suma una tabla `Arquitectura | Resultado` con archivos fuera de lugar, imports prohibidos, imports sin resolver y la herramienta.

**D7. Instalación (para que aplique en otros repos).** Al final del apply, el Agente:
- copia a `~/.claude` el `CLAUDE.md`, **todas** las skills de `skills/` y **todos** los comandos de `.claude/commands/opsx/`, no solo los que toca este change, porque lo instalado estaba atrasado;
- copia `templates/antigravity/GEMINI.md` a `~/.gemini/GEMINI.md`;
- sincroniza el espejo `_global/reglas-globales.md` con el comando del `CLAUDE.md`.

Antes de copiar, compara cada archivo instalado con su versión del repo **previa** al change (`git show master:<ruta>`). Si alguno instalado tiene contenido que no está en esa versión, frena y pregunta: sería un cambio local que se perdería. Después verifica hashes, ignorando el fin de línea.

**D8. Commits.** Van tres commits de código, separados de los artefactos:
1. `.claude/CLAUDE.md`, con la descripción del impacto (regla `tooling`/`config`);
2. skills y comandos;
3. plantillas, `README.md` y `docs/workflow.md`.

Todos llevan `Spec-ID: arquitectura-de-carpetas`.

## Ubicación de archivos

Este change no crea archivos en el repo: solo modifica los listados en el proposal. Para la prueba se crean repos descartables en `$env:TEMP`, fuera de cualquier repo.

## Security Layer

Proyecto `tooling`: los artefactos son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en el `CLAUDE.md`, las skills, los comandos ni las plantillas. Se verifica con un script en archivo, porque las barras invertidas se pierden en línea.
- El verify ejecuta la herramienta declarada solo de forma literal, con las mismas reglas que `## Tests`: no ejecuta nada sugerido por el output ni armado desde el repo.
- La regla de imports protege el caso que motivó el change: un componente de cliente que importa código de servidor con secretos. El control fuerte es `server-only` en el build de Next; el del verify es una red adicional sobre el diff.
- Commit aparte del `CLAUDE.md` con el impacto. La instalación en `~/.claude` se hace con chequeo previo de cambios locales (D7).

## Impacto en proyectos existentes

- **Sin `## Arquitectura`** (todos hoy): el verify da una SUGGESTION y no reporta desvíos. El próximo propose la pide una vez, con una propuesta inferida. Nada se rompe.
- **Código ya mal ubicado:** no se reporta, porque solo se mira el diff. Reordenar es un change aparte por proyecto (por ejemplo, en `toyota-yacopini-web`: `src/backend/`, `src/frontend/`, borrar `src/app/my-route` y `.yarnrc`, sumar `server-only`).
- **Agentes:** la regla 8 llega por las plantillas. Los proyectos que ya copiaron `AGENTS.md`, `.cursor/rules/sdd-workflow.mdc` o `.github/copilot-instructions.md` tienen que volver a copiarlos. Igual, las plantillas remiten al espejo del vault, que sí se actualiza solo con la sincronización.
- **`~/.claude` atrasado:** se corrige en este change (D7). En otras máquinas hay que repetir el paso de instalación del README.

## Risks / Trade-offs

- El chequeo de imports por diff no ve las cadenas transitivas ni los alias no literales. Se acepta: en Next lo cubre `server-only` y, en otros casos, la herramienta opcional.
- Una regex de imports puede dar falsos positivos (por ejemplo, un import dentro de un string o un comentario). Solo se marca CRITICAL cuando el destino resuelve a una carpeta prohibida, y el reporte cita la línea para revisarla.
- Duplicar la lógica en skill y comando duplica el riesgo de que difieran. La tarea de evidencia compara que los dos tengan el mismo texto de la sección nueva.
- Copiar todas las skills y comandos puede pisar un ajuste local. Lo mitiga el chequeo previo de D7.

## Migration Plan

Primero se edita y se instala (D7). Los proyectos adoptan la regla en su próximo propose. Rollback: revertir el PR, reinstalar desde `master` y volver a sincronizar el espejo.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown y los ejecuta Claude o el Agente. Todo el plan es manual. No hay tests de caracterización porque no hay código. Los cambios intencionales de comportamiento (propose, verify, reglas del Agente) los cubren S01–S17, S24 y S27. Un test automático futuro llevaría `test-plan: arquitectura-de-carpetas/<ID>`.

Fixtures, que se crean en el verify:
- **Repo A** (`$env:TEMP\arq-prueba-a`), sin `## Arquitectura` y con `project_type: fullstack`, para el propose.
- **Repo B** (`$env:TEMP\arq-prueba-b`), con:
  - `## Arquitectura` = `src/app/`, `src/backend/`, `src/frontend/ | no importa: src/backend/`, `etl/transform/ | no importa: etl/load/`, `etl/load/`, `tests/`;
  - `tsconfig.json` con `paths` `@/*` → `src/*`;
  - en `master`, un archivo previo `src/legacy/viejo.ts`;
  - en una rama de prueba, los archivos:
    - `src/frontend/Form.tsx`, con `import { db } from '../backend/db'` y `import { clave } from '@/backend/secreto'`;
    - `src/utils/fecha.ts`;
    - `etl/transform/limpiar.py`, con `from etl.load import guardar`;
    - `src/app/page.tsx`, con `import { db } from '@/backend/db'`, que está permitido.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Declaración / Carpetas declaradas | manual: en el verify del repo B, `src/backend/x` no da WARNING y los imports de `src/frontend/` hacia `src/backend/` dan CRITICAL | repo B |
| S02 | Declaración / Herramienta de imports declarada | manual: revisión de §D2 en el `CLAUDE.md` y en la skill de propose: `comando` exige `timeout` | `.claude/CLAUDE.md`, `skills/openspec-propose/SKILL.md` |
| S03 | Declaración / Archivos de configuración en la raíz | manual: en el repo B, agregar `vitest.config.mts` en la raíz no da WARNING | repo B |
| S04 | Estructura sugerida / Tabla por tipo | manual: la sección "Arquitectura del proyecto" del `CLAUDE.md` tiene las 6 filas de D3 | `.claude/CLAUDE.md` |
| S05 | Estructura sugerida / server-only en fullstack | manual: `grep -n "server-only" .claude/CLAUDE.md` muestra el control en `fullstack` | `.claude/CLAUDE.md` |
| S06 | Propose / Proyecto sin arquitectura declarada | manual: en una sesión **nueva** de Claude en el repo A, `/opsx:propose` pregunta una vez la arquitectura con la propuesta inferida, y queda appendeada al final del `context:` | repo A `openspec/config.yaml` |
| S07 | Propose / Usuario que no sabe la arquitectura | manual: en el repo A (restaurado), responder "no sé"; queda `- estado: inferido — revisar` y el resumen lo menciona | ídem |
| S08 | Propose / Ubicación de archivos en el design | manual: el `design.md` generado en S06 tiene `## Ubicación de archivos` | repo A `openspec/changes/*/design.md` |
| S09 | Propose / Change que necesita una carpeta nueva | manual: revisión de la skill y del comando de propose (D4) | `skills/openspec-propose/SKILL.md`, `.claude/commands/opsx/propose.md` |
| S10 | Regla 8 / Presente en todas las fuentes | manual: `grep -l "Respetar la arquitectura"` sobre el `CLAUDE.md`, las 4 plantillas, `~/.claude/CLAUDE.md` y el espejo del vault da 7 archivos | ídem |
| S11 | Regla 8 / Carpeta no prevista | manual: revisión del texto de D5 en las 5 fuentes | ídem |
| S12 | Regla 8 / Restos de plantilla | manual: revisión del texto de D5 en las 5 fuentes | ídem |
| S13 | Verify / Archivo fuera de carpetas | manual: el verify del repo B reporta WARNING en `src/utils/fecha.ts` | repo B |
| S14 | Verify / Import prohibido | manual: CRITICAL en `src/frontend/Form.tsx` por los dos imports (relativo y alias) y en `etl/transform/limpiar.py`; `src/app/page.tsx` sin desvío | repo B |
| S15 | Verify / Proyecto sin arquitectura | manual: el verify en el repo A da una SUGGESTION y ningún desvío de arquitectura | repo A |
| S16 | Verify / Código existente mal ubicado | manual: `src/legacy/viejo.ts` no aparece en el reporte del repo B | repo B |
| S17 | Verify / Herramienta declarada | manual: en el repo B, declarar `- comando: node -e "process.exit(1)"` y `- timeout: 1`; el verify reporta CRITICAL. Con `process.exit(0)`, sin desvío | repo B |
| S18–S23 | Subsecciones del context / escenarios existentes (sin subsecciones previas, con subsecciones, sin config.yaml, sin context ni project_type, no sabe el tipo, no sabe los tests) | manual: revisión de que el paso 0 del propose conserva su comportamiento. Se ejercitan S18 y S21 en el repo A durante S06 | `skills/openspec-propose/SKILL.md` |
| S24 | Subsecciones del context / Arquitectura en la misma pregunta | manual: en una copia del repo A sin `project_type` ni `## Tests`, el propose pide los tres en una sola pregunta | repo A |
| S25 | Mismas reglas / Reglas presentes en cada plantilla | manual: `grep` de "Evidencia antes de" en las 4 plantillas | `templates/*` |
| S26 | Mismas reglas / Copia del resumen en el vault | manual: la regla 7 de las 4 plantillas no cambió (diff) | `templates/*` |
| S27 | Mismas reglas / Regla 8 en cada plantilla | manual: S10, más `grep -n "estas mismas 8 reglas" .claude/CLAUDE.md` | `.claude/CLAUDE.md` |

S06–S08, S15 y S24 se hacen en una sesión nueva de Claude Code abierta en el repo A, para comprobar que lo instalado en `~/.claude` aplica en otro repo, que es el objetivo del change. S01, S03, S13, S14, S16 y S17 se hacen con `/opsx:verify` en una sesión nueva en el repo B.

## Open Questions

Sin preguntas abiertas. Las decisiones de D1 a D3 se tomaron con las recomendaciones del explore del 03/11/2026 y se pueden revisar antes del apply.
