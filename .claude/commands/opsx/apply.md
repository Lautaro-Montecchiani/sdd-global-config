---
name: "OPSX: Apply"
description: Announce the handoff to the Agent to implement tasks from an OpenSpec change — Claude does not write code (hybrid workflow)
category: Workflow
tags: [workflow, artifacts, experimental]
---

Announce the handoff to the Agent for an OpenSpec change. Claude is the architect: it does NOT implement tasks.

**Input**: Optionally specify a change name (e.g., `/opsx:apply add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **Select the change**

   If a name is provided, use it. Otherwise:
   - Infer from conversation context if the user mentioned a change
   - Auto-select if only one active change exists
   - If ambiguous, run `openspec list --json` to get available changes and use the **AskUserQuestion tool** to let the user select

   Always announce: "Using change: <name>" and how to override (e.g., `/opsx:apply <other>`).

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - `planningHome`, `changeRoot`, and `actionContext`: planning scope and edit constraints
   - Which artifact contains the tasks (typically "tasks" for spec-driven, check status for others)

3. **Get apply instructions**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   This returns:
   - `contextFiles`: artifact ID -> array of concrete file paths (varies by schema)
   - Progress (total, complete, remaining)
   - Task list with status
   - Dynamic instruction based on current state

   **Handle states:**
   - If `state: "blocked"` (missing artifacts): show message, suggest using `/opsx:continue`
   - If `state: "all_done"`: congratulate, suggest `/opsx:verify` then `/opsx:archive`
   - Otherwise: proceed to handoff

   **Workspace guard:** If status JSON reports `actionContext.mode: "workspace-planning"` and `allowedEditRoots` is empty, explain that full workspace apply is not supported in this slice. Treat linked repos and folders as read-only context, ask the user to select an affected area through an explicit implementation workflow, and STOP before editing files.

4. **Read context files**

   Read every file path listed under `contextFiles` from the apply instructions output.
   The files depend on the schema being used:
   - **spec-driven**: proposal, specs, design, tasks
   - Other schemas: follow the contextFiles from CLI output

5. **Show current progress**

   Display:
   - Schema being used
   - Progress: "N/M tasks complete"
   - Remaining tasks overview
   - Dynamic instruction from CLI

6. **Announce handoff to the Agent — DO NOT write code**

   Claude is the architect. Claude does NOT implement tasks.
   Announce the handoff clearly and stop:

   ```
   ## Listo para implementar: <change-name>

   **Schema:** <schema-name>
   **Progreso actual:** N/M tareas completas

   ### Tareas pendientes para el Agente:
   - [ ] <tarea 1>
   - [ ] <tarea 2>

   ---
   Ejecutá en el Agente: `/openspec-apply-change <change-name>`
   Cuando termine, volvé aquí y ejecutá: `/opsx:verify <change-name>`
   ```

   **STOP — no hacer cambios de código. Esperar confirmación del usuario.**

7. **On completion or pause, show status**

   Display:
   - Overall progress: "N/M tasks complete"
   - If all done: suggest `/opsx:verify` then `/opsx:archive`
   - If paused: explain why and wait for guidance

**Output On Handoff**

```
## Listo para implementar: <change-name> (schema: <schema-name>)

Progreso actual: N/M tareas completas

Tareas pendientes:
- [ ] Tarea 1
- [ ] Tarea 2

---
Ejecutá en el Agente: `/openspec-apply-change <change-name>`
Cuando termine: `/opsx:verify <change-name>` aquí en Claude.
```

**Guardrails**
- NUNCA escribir código de producción — Claude es arquitecto, no constructor
- Always read context files before announcing handoff
- If task is ambiguous, pause and ask before announcing handoff
- Pause on errors, blockers, or unclear requirements - don't guess
- Use contextFiles from CLI output, don't assume specific file names

**Fluid Workflow Integration**

This command supports the "actions on a change" model:

- **Can be invoked anytime**: Before all artifacts are done (if tasks exist), after partial implementation, interleaved with other actions
- **Allows artifact updates**: If the Agent's work reveals design issues, suggest updating artifacts - not phase-locked, work fluidly
