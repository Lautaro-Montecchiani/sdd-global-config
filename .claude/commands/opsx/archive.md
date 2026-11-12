---
name: "OPSX: Archive"
description: Archive a completed change and export a summary note to the Obsidian vault
category: Workflow
tags: [workflow, archive, experimental]
---

<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->

Archive a completed change in the hybrid SDD workflow.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

---

### Detección de fase

La skill decide la fase según la ubicación del change y el estado de su PR. Consultar el estado del PR con `gh pr list --state merged --head change/<nombre>` (y también `--head change/<nombre>-archive`). Si `gh` no puede responder (sin conexión o sin cuenta), preguntar al usuario si el PR está mergeado en vez de suponerlo.

| Estado | Acción / Fase |
|---|---|
| `openspec/changes/<nombre>/` existe y el PR no está mergeado | **Fase de la rama** (pasos abajo) |
| `openspec/changes/<nombre>/` existe y el PR está mergeado | **Change del flujo anterior** (crear `change/<nombre>-archive` y aplicar fase de la rama) |
| `openspec/changes/archive/*-<nombre>/` existe en la rama principal y el PR está mergeado | **Fase del vault** (pasos abajo) |
| Archivado en la rama y PR abierto | Frenar: "falta el merge". Indicar al usuario que debe mergear el PR antes del cierre en el vault. |
| No aparece en ningún lado | Frenar: change inexistente. |

---

### Fase de la rama

Se ejecuta en la rama del change, después del verify aprobado y antes del merge del PR.

1. **Control de rama:**
   La rama actual tiene que ser `change/<nombre>`, o `change/<nombre>-archive` si se llega desde "Change del flujo anterior". Si la rama actual es distinta, frena (escenario "Fuera de la rama del change"): indicar en qué rama hay que estar y no mover ni commitear nada.

2. **Confirmación de verify aprobado:**
   Revisar si `$vault\projects\$p\context.md` registra el verify aprobado para `<nombre>`. Si no lo registra, preguntar al usuario con la herramienta **AskUserQuestion**:
   "¿El verify de `<nombre>` está aprobado sin observaciones CRITICAL?"
   Opciones: "Sí, continuar con el archive", "No, cancelar".
   Si el usuario no lo confirma, frena sin mover ni commitear nada.

3. **Verificación de artefactos y tareas:**
   - Correr `openspec status --change "<nombre>" --json`. Si algún artefacto no está `done`, advertir y pedir confirmación.
   - Si status reporta `actionContext.mode: "workspace-planning"`, explicar que workspace archive no está soportado en este slice y STOP.
   - Leer `tasks.md` y contar `- [ ]` vs `- [x]`. Si hay tareas pendientes, mostrar advertencia y pedir confirmación antes de continuar.

4. **Sincronización de specs y movimiento a archive:**
   - **Control de carpeta existente:** Antes del sync, controlar que no exista `openspec/changes/archive/YYYY-MM-DD-<nombre>/` con la fecha del día. Si ya existe, frenar antes de sincronizar o mover nada, mostrar error ("Target archive directory already exists") indicando la carpeta existente y sugerir renombrarla o esperar otra fecha (ver salida de error abajo).
   - Evaluar delta specs con `artifactPaths.specs.existingOutputPaths`. Si existen, comparar con `openspec/specs/<capability>/spec.md` y ofrecer sincronizar: "Sync now (recommended)", "Archive without syncing". Si el usuario elige sync, invocar `openspec-sync-specs`.
   - Crear la carpeta `openspec/changes/archive/` si no existe.
   - Mover el change:
     ```bash
     mv "openspec/changes/<nombre>" "openspec/changes/archive/YYYY-MM-DD-<nombre>"
     ```
   - **Completar `## Purpose` para nuevas capabilities:**
     Revisar "New Capabilities" en `proposal.md` del change archivado. Para cada capability nueva con `TBD - created by archiving change` en `openspec/specs/<capability>/spec.md`, reemplazar esa línea con 1-2 frases descriptivas derivadas de `proposal.md`. No tocar specs que ya tienen `## Purpose` redactado.

5. **Commit del archive en la rama:**
   Ejecutar `git add openspec/` y revisar con `git diff --staged` que no haya archivos sensibles ni inesperados.
   Commitear en la rama del change:
   ```bash
   git commit -m "chore: archive <nombre>" -m "Spec-ID: <nombre>"
   ```
   Este commit incluye únicamente archivos bajo `openspec/`, respetando la regla de commits separados.

6. **Oferta del SRS en la rama:**
   En todos los proyectos y en cada archive, revisar si `docs/srs.md` existe en la raíz del proyecto y consultar al usuario con **AskUserQuestion**:
   - **Si existe `docs/srs.md`:** preguntar "¿Regenerar el SRS ahora para incluir este change?" con las opciones:
     - `(Recommended) Regenerar ahora`
     - `Más tarde`
   - **Si no existe `docs/srs.md`:** preguntar "Este proyecto todavía no tiene SRS. ¿Generarlo ahora? La primera vez incluye una entrevista corta." con las opciones:
     - `(Recommended) Generar ahora`
     - `Más tarde`
   - Si todavía hay changes activos (según `openspec list --json`), aclarar que no se incluirán hasta que se archiven.
   - **Si el usuario acepta:** invocar la skill `srs-generate`. Tras su ejecución, commitear en la misma rama `change/<nombre>` los archivos generados (`docs/srs.md`, `docs/srs.meta.yaml`, `docs/diagramas/` y, si es la primera vez, `openspec/config.yaml`):
     ```bash
     git add docs/srs.md docs/srs.meta.yaml docs/diagramas/ openspec/config.yaml
     git commit -m "docs: regenerar SRS" -m "Spec-ID: <nombre>"
     # O si es la primera generación:
     # git commit -m "docs: generar SRS" -m "Spec-ID: <nombre>"
     ```
   - **Si el usuario posterga ("Más tarde"):** no bloquea el archive; el próximo archive volverá a ofrecer el SRS. Nunca bloquear ni revertir el archive por esta decisión.

7. **Actualización de context.md en el vault:**
   Resolver el vault: `$vault = $env:OBSIDIAN_VAULT`, `$p = Split-Path (Get-Location) -Leaf`.
   Si el vault existe, actualizar únicamente `## Estado actual` en `$vault\projects\$p\context.md`:
   "`<nombre>` archivado en la rama, pendiente de merge".
   Commitear y pushear el vault:
   ```powershell
   git -C $vault add "projects/$p/context.md"
   git -C $vault commit -m "chore: $p — archive en rama $nombre"
   git -C $vault push
   ```
   Si el push del vault falla o no hay vault, continuar y advertirlo al usuario.

8. **Push de la rama del change:**
   Preguntar al usuario confirmación antes de hacer push a GitHub:
   "¿Deseás pushear los commits a la rama `change/<nombre>`?"
   Si el usuario confirma, correr `git push origin change/<nombre>`. Si no, pedirle que lo haga manualmente.

9. **Resumen de la fase de la rama:**
   Informar:
   "Archive completado en la rama `change/<nombre>`. Mergeá el PR y volvé a correr `/opsx:archive <nombre>` para cerrar en el vault."

---

### Fase del vault

Se ejecuta **después del merge** del PR en la rama principal.

1. **Actualización de la rama principal:**
   Verificar que el árbol de trabajo esté limpio (`git status --porcelain`). Si no está limpio, frenar y avisar.
   Actualizar la rama principal:
   ```bash
   git checkout main
   git pull --ff-only
   ```
   (o `master` según corresponda).

2. **Cierre y notas en el Obsidian vault:**
   Esta fase **no crea commits en el repo** del proyecto: todo el cierre queda registrado en el vault. La fase del vault **no ofrece el SRS** (el SRS ya se gestionó en la fase de la rama).
   Resolver el vault: `$vault = $env:OBSIDIAN_VAULT`, `$p = Split-Path (Get-Location) -Leaf`.
   Si `$vault` no existe, omitir y avisar en el resumen. Si existe:

   a. **Nota de archive:** escribir `$vault\projects\$p\archive\YYYY-MM-DD-<nombre>.md` con frontmatter (`project`, `change`, `date`, `status: archivado`, `tags: [openspec, change]`) y secciones `## Qué resolvió`, `## Decisiones clave` y `## Links` (`[[<project>/_index]]`).
   
   b. **Nota de decisions:** si `$vault\projects\$p\decisions\*-<nombre>.md` existe, cambiar `status: activo` a `status: archivado`.

   c. **Actualizar `context.md`:** en `$vault\projects\$p\context.md`, actualizar:
      - `## Estado actual`: changes activos restantes (de `openspec list --json`) o "sin change activo".
      - `## Último change`: `<nombre> — archivado el YYYY-MM-DD`.
      - Conservar las últimas 2-3 decisiones relevantes y sumar las del change archivado.

   d. **Actualizar `_index.md`:** agregar enlace `- [[archive/YYYY-MM-DD-<nombre>]] — <descripción>`.

   e. **Actualizar `arquitectura.md`:** reescribir `$vault\projects\$p\arquitectura.md` con:
      - `## Nivel`: valor de `nivel` de `## Arquitectura` en `openspec/config.yaml`, o `"sin evaluar"` si falta.
      - `## Atributos de calidad`: ítems de `## Calidad` en `openspec/config.yaml`, o `"sin declarar"` si falta.
      - `## Decisiones vigentes`: ADRs con `Estado: aceptada` en `docs/adr/`, o `"ninguna"`.
      - `## Deuda prioritaria`: hasta 3 ítems de `## Hoja de ruta` de `docs/arquitectura/vision.md`, o `"ninguna"`.
      - Seguido de `Documento completo: docs/arquitectura/vision.md en el repo`. No copiar código, credenciales ni datos personales.
      - Si `## Nivel` quedó en `"sin evaluar"`, registrar para el resumen la línea de sugerencia D1: `Sugerencia: corré `/arquitectura` para evaluar la arquitectura del proyecto (`arquitectura.md` quedó en sin evaluar)`. Si `nivel` está declarado con una receta válida, no sugerir (no sugiere nada).

   f. **Sync del vault:**
      ```powershell
      git -C $vault add -A
      git -C $vault commit -m "chore: $p — archive $nombre"
      git -C $vault push
      ```
      Si el push falla, continuar y advertir al final.

---

### Change del flujo anterior

Si el PR del change ya está mergeado en la rama principal pero `openspec/changes/<nombre>/` todavía no fue archivado:
1. Verificar que el árbol de trabajo esté limpio (`git status --porcelain`). Si no está limpio, frenar y avisar. Con el árbol limpio, actualizar la rama principal con `git checkout main` (o rama principal correspondiente) y `git pull --ff-only`, y luego crear la rama con `git checkout -b change/<nombre>-archive`:
   ```bash
   git checkout main
   git pull --ff-only
   git checkout -b change/<nombre>-archive
   ```
2. Ejecutar la **Fase de la rama** completa, omitiendo únicamente el paso 2 (control de verify), ya que el verify fue realizado antes del merge previo.
3. Al finalizar, pedir abrir el PR con `/branch-pr`. El nombre de rama `change/<nombre>-archive` es aceptado por las convenciones y el Spec-ID esperado es `<nombre>`.
4. Una vez mergeado ese PR, volver a correr `/opsx:archive <nombre>` para completar la **Fase del vault**.

---

**Output On Success (Fase de la rama)**

```
## Archive en Rama Completo

**Change:** <change-name>
**Rama:** change/<change-name>
**Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs
**Commit repo:** chore: archive <change-name> (Spec-ID: <change-name>)
**SRS:** ✓ Regenerado en la rama / Generado en la rama / Postergado
**Obsidian:** context.md actualizado ("archivado en la rama, pendiente de merge")

Próximo paso: Mergeá el PR y volvé a correr `/opsx:archive <name>` para cerrar en el vault.
```

**Output On Success (Fase del vault)**

```
## Cierre en Vault Completo

**Change:** <change-name>
**Obsidian:**
- Archive: $vault\projects\<project>\archive\YYYY-MM-DD-<name>.md
- Decisions: status archivado
- Context: context.md actualizado
- Arquitectura: arquitectura.md reescrito
- Index: _index.md actualizado
**Vault commit:** chore: <project> — archive <name>
**Repo:** Sin commits nuevos en el repositorio del proyecto.

Sugerencia: corré `/arquitectura` para evaluar la arquitectura del proyecto (`arquitectura.md` quedó en sin evaluar)   # solo si arquitectura.md quedó en sin evaluar

Cierre del change finalizado exitosamente.
```

**Output On Error (Archive Exists)**

```
## Archive Failed

**Change:** <change-name>
**Target:** openspec/changes/archive/YYYY-MM-DD-<name>/

Target archive directory already exists.

**Options:**
1. Rename the existing archive
2. Delete the existing archive if it's a duplicate
3. Wait until a different date to archive
```

**Guardrails**
- Siempre preguntar al usuario qué change seleccionar si no se especificó.
- Fuera de la rama del change durante la fase de la rama: detener la ejecución.
- En la fase de la rama, verificar que el verify esté aprobado; si no está en context.md, pedir confirmación y frenar si no se confirma.
- Revisar siempre `git diff --staged` antes de commitear en la rama; nunca commitear `.env`, credenciales ni código.
- Pedir confirmación explícita al usuario antes de hacer `git push`.
- En la fase del vault, nunca crear commits en el repo del proyecto.
- No ofrecer el SRS en la fase del vault; el SRS se ofrece exclusivamente en la fase de la rama.
- Postergar el SRS nunca bloquea el archive; se ofrecerá nuevamente en el próximo archive.
