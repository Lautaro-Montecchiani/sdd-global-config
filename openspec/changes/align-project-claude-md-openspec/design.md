## Context

Las reglas globales (`~/.claude/CLAUDE.md`) y los comandos `/opsx` aplican en cualquier proyecto sin configuración local. Tres proyectos tienen además un `CLAUDE.md` propio con el flujo SDD manual con Copilot:

- `seguimiento-Suscripciones` (455 líneas): unas 120 son del proyecto (descripción, arquitectura, contratos del ETL y de las hojas, reglas de arquitectura, watchlist, estado) y el resto es un manual SDD genérico copiado (roles, fases OPCX, plantillas de `spec.yaml`/`CLAUDE.md`/`threat-model.md`/ADR, prompts para Copilot, estrategia de modelos, migración, roadmap). Además tiene rutas absolutas con el usuario local.
- `interfaz-formulario-licitación` (36 líneas): mezcla contenido propio (stack, restricciones de GAS, IDs, riesgos) con "Rol de Claude" que pide producir `spec.yaml` y "el prompt para Copilot", y reglas del flujo manual (`spec_lint`, `verify_spec_parity`, PR con etiqueta `spec:{id}`).
- `normalizacionLeads-contactacion` (123 líneas): repo en la carpeta de proyectos del disco D. Mezcla contenido propio (arquitectura de extracción y Power Query, contratos de teléfonos y filtros de Salesforce, reglas de arquitectura, watchlist) con "Reglas de Comunicación" y un "Sistema SDD — Modo Híbrido" con Copilot (roles, `spec.yaml`, plantillas de sesión, prompt para Copilot, checklist) y una tabla de features SDD. Tiene `specs/` pero no `spec_lint.py` ni CI; su `openspec/config.yaml` es la plantilla por defecto, sin `project_type`. Tiene rutas absolutas con el usuario local, una de ellas como dependencia funcional de las consultas Power Query.

Los tres proyectos ya usan OpenSpec (`openspec/config.yaml` con `project_type: fullstack` en los dos revisados) y conservan `specs/`, `scripts/` y, en `interfaz-formulario-licitación`, el workflow `spec-check.yml` del flujo manual. `automation-server` es la referencia: describe el proyecto y remite a las reglas globales en una sección de cuatro líneas.

Estado de los repos al proponer: `interfaz-formulario-licitación` está en la rama `change/fix-legajo-column-detection` con cambios sin commitear ajenos a este change; `seguimiento-Suscripciones` está en `change/pull-newcon-y-sync-siac-completo`; `normalizacionLeads-contactacion` está en `master`, con un commit local de limpieza, un archivo modificado y una carpeta sin versionar. `{proyectos}` denota la carpeta que contiene los repos; en esta PC hay dos: la hermana de `sdd-global-config` y la del disco D, donde está `normalizacionLeads-contactacion`.

## Goals / Non-Goals

**Goals:**
- Que el `CLAUDE.md` de cada proyecto no contradiga el modo OpenSpec global.
- Conservar todo el contenido propio del proyecto.
- Dejar el criterio escrito como spec para poder aplicarlo a proyectos nuevos.

**Non-Goals:**
- No modificar reglas, skills ni comandos globales.
- No tocar código, CI, `specs/` legacy, `change-map.md`, `.github/copilot-instructions.md` ni `openspec/config.yaml` de los proyectos.
- No actualizar el contenido propio (estado, contratos) ni crear una plantilla de `CLAUDE.md`.

## Decisions

### D1: El CLAUDE.md de proyecto conserva lo propio y remite a lo global

Se elimina todo lo que replica o contradice las reglas globales y se agrega la sección "Workflow SDD / OpenSpec", como en `automation-server`: indica que el proyecto usa OpenSpec, remite a `~/.claude/CLAUDE.md` e indica empezar con `/opsx:propose`.

Alternativas consideradas:
- Copiar las reglas globales dentro de cada proyecto — descartada: es la causa del problema; las copias se desactualizan y contradicen.
- Vaciar el archivo y dejar solo la remisión — descartada: se perdería el contexto propio del proyecto (contratos, IDs, watchlist) que Claude necesita.
- Importar `~/.claude/CLAUDE.md` con `@` — descartada: las reglas globales ya se cargan en cada sesión; importarlas duplicaría el contenido.

**Decisión:** conservar lo propio, remitir a lo global.

### D2: Criterio de partición de secciones

| Se conserva | Se elimina |
|---|---|
| Descripción, stack, arquitectura | Roles Claude/Agente y "Rol de Claude en este proyecto" |
| Contratos de comportamiento y reglas de arquitectura | Fases OPCX, `spec.yaml`/`Task.md`/`threat-model.md` como artefactos a crear |
| Restricciones del entorno, IDs de recursos, riesgos, watchlist, estado | Prompts y plantillas para Copilot, patrón Bash Headless, estrategia de modelos |
| Specs legacy (como referencia) | Reglas de Git, CI y seguridad genéricas ya cubiertas por las reglas globales |

"Reglas de comunicación" de `seguimiento-Suscripciones` duplica las reglas globales y se elimina; "Output siempre a archivo" de "Reglas de arquitectura" se refiere al log del ETL y se conserva.

### D3: Specs legacy y CI como referencia

`specs/` y `change-map.md` no se tocan; el `CLAUDE.md` los presenta como referencia histórica y aclara que los changes nuevos van en `openspec/changes/` y que el change activo se obtiene con `openspec list --json`. En `interfaz-formulario-licitación`, el `CLAUDE.md` puede indicar que `spec-check.yml` sigue validando los `specs/` legacy, solo si el Agente lo confirma leyendo el workflow. Toda ruta que quede en el archivo se verifica contra el repo.

### D4: Ejecución en worktrees desde la rama principal

Dos proyectos tienen una rama `change/…` activa distinta a la principal, y los tres tienen trabajo sin commitear o commits locales sin pushear. Para no alterar ese trabajo ni mezclar el commit en el PR de otro change, el Agente usa `git worktree add` en una carpeta temporal fuera de los repos, con la rama nueva `change/align-project-claude-md-openspec` creada desde `origin/master`. Se parte de la versión de `CLAUDE.md` de la rama principal, no de la de la rama activa; si difieren, se avisa.

Alternativa descartada: commitear solo `CLAUDE.md` sobre la rama activa (como en la limpieza operativa anterior) — mezcla este change con el PR de otro y su commit no llevaría el `Spec-ID` correcto.

### D5: Verificación con script temporal y prueba de sesión

Un script en archivo, en el scratchpad del Agente y no versionado (las barras invertidas se pierden en comandos en línea), comprueba por proyecto: sección "Workflow SDD / OpenSpec" presente, ausencia de los términos del flujo manual y de `C:\Users`, y existencia de las rutas que quedan en el archivo. La prueba de comportamiento usa `claude -p` sin herramientas dentro del worktree para confirmar que Claude describe el flujo OpenSpec.

### D6: Un proyecto no disponible no bloquea a los otros

Si el repo de un proyecto no está en la máquina, el Agente no lo clona ni adivina su contenido: deja sus tareas sin marcar y el usuario decide si lo hace en otra máquina o en otro change. Al aplicar este change por primera vez `normalizacionLeads-contactacion` no se encontró en la carpeta hermana de `sdd-global-config`; después se localizó en el disco D y su grupo de tareas se completó con datos reales de su `CLAUDE.md`.

### D7: Las rutas que son dependencia funcional se expresan con un placeholder

`normalizacionLeads-contactacion/CLAUDE.md` tiene una regla que depende de una ruta absoluta con el usuario local: las consultas Power Query `.pq` apuntan al escritorio del usuario. Quitar la ruta sin más cambiaría el sentido de la regla, y dejarla expone el usuario. Se reemplaza el tramo del usuario por un placeholder que conserva el sentido (`{escritorio}\normalizacionLeads`) y se aclara que es el escritorio del usuario de cada equipo; el resto de la regla no cambia.

Alternativa descartada: mantener la ruta literal — contradice la spec y expone el usuario local en un archivo versionado.

## Risks / Trade-offs

- **[Riesgo] Se elimina una regla útil que solo existía en el `CLAUDE.md` del proyecto** → El criterio de D2 solo elimina lo que replica las reglas globales; antes de escribir, el Agente compara sección por sección y conserva cualquier regla propia que no esté en `~/.claude/CLAUDE.md`.
- **[Riesgo] `spec-check.yml` de `interfaz-formulario-licitación` sigue exigiendo `spec_lint` sobre `specs/`** → El `CLAUDE.md` lo declara como validación de los specs legacy; el CI no se modifica.
- **[Riesgo] El `CLAUDE.md` de la rama activa difiere del de la rama principal** → Se trabaja desde la principal y se avisa la diferencia para que se resuelva al mergear.
- **[Riesgo] El placeholder `{escritorio}` no es una ruta ejecutable y alguien podría copiarlo a las consultas Power Query** → La regla aclara que es el escritorio del usuario de cada equipo y las consultas `.pq` no se modifican en este change.
- **[Trade-off] Las sesiones abiertas conservan el archivo viejo** → Hay que reiniciarlas; se documenta en el resultado.
- **[Trade-off] Un cambio en tres repos no cabe en un solo PR** → Cada proyecto lleva su rama y su commit con el mismo `Spec-ID`; el PR de este repo contiene solo los artefactos.

## Security Layer

`project_type: tooling` — los `CLAUDE.md` son instrucciones para IA.

- No se agregan secrets ni credenciales. La watchlist conserva las advertencias sobre `token_suscripciones.json` y `client_secret_*.json`.
- Se eliminan las rutas absolutas con el usuario local; se usan placeholders con llaves. Los IDs de hojas de cálculo ya existentes se conservan sin cambios.
- El commit de cada proyecto incluye solo `CLAUDE.md`: se revisa `git diff --staged` antes de commitear y se confirma que no entra ningún archivo del trabajo en curso.
- Los worktrees viven en una carpeta temporal y se eliminan al terminar.
- Observaciones fuera de alcance que se reportan al usuario: `interfaz-formulario-licitación` no tiene `.gitignore` en la raíz y `normalizacionLeads-contactacion` tiene el `openspec/config.yaml` por defecto, sin `project_type`, por lo que no puede aplicarse la capa de seguridad por tipo de proyecto.

## Impacto en proyectos existentes

- **Modificados (contenido de `CLAUDE.md`):** `seguimiento-Suscripciones`, `interfaz-formulario-licitación` y `normalizacionLeads-contactacion`.
- **Sin cambios:** `automation-server` y los demás proyectos (sin `CLAUDE.md` propio o ya alineados).
- **Retrocompatibilidad:** `specs/`, `change-map.md`, `scripts/` y CI siguen intactos y coexisten con OpenSpec; solo cambia lo que Claude lee como instrucción. Los changes en curso en esas ramas no se ven afectados hasta mergear la rama de este change.
- **Proyectos futuros:** hoy nada impide que un proyecto nuevo agregue un `CLAUDE.md` con el flujo manual; la spec `project-claude-md` fija el criterio para verificarlo.

## Migration Plan

1. Por proyecto: crear el worktree desde `origin/master`, reescribir `CLAUDE.md`, verificar con el script y commitear con `Spec-ID: align-project-claude-md-openspec`.
2. Verificar que el cambio aplica con una prueba de sesión (`claude -p`) en el worktree de un proyecto.
3. Eliminar los worktrees temporales; las ramas quedan locales para que el usuario decida el push y el PR de cada repo (`/branch-pr`).
4. `/opsx:verify` en este repo lee el `CLAUDE.md` de cada rama con `git show`.

Rollback: `git revert` del commit en cada repo, o descartar la rama local si no se mergeó.

## Open Questions

Sin preguntas abiertas.
