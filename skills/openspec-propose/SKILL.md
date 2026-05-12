---
name: openspec-propose
description: Propose a new change with all artifacts generated in one step, and persist context to the Obsidian vault.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.1"
  generatedBy: "1.3.1"
  modified: "hybrid-workflow — reads context.md before propose, writes decisions note after, updates context.md"
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- design.md (how)
- tasks.md (implementation steps)

When ready to implement, run /opsx:apply

---

**Input**: The user's request should include a change name (kebab-case) OR a description of what they want to build.

**Steps**

0. **Read Obsidian context (before starting)**

   Resolve vault and project name:
   ```powershell
   $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
   $p = Split-Path (Get-Location) -Leaf
   ```

   Read current project context if it exists:
   ```powershell
   Get-Content "$vault\projects\$p\context.md" -ErrorAction SilentlyContinue
   ```

   Use this context to inform the proposal — prior decisions, active changes, and domain knowledge already captured there. If `context.md` doesn't exist, proceed without it.

1. **If no clear input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   openspec new change "<name>"
   ```
   This creates a scaffolded change at `openspec/changes/<name>/` with `.openspec.yaml`.

3. **Get the artifact build order**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies

4. **Create artifacts in sequence until apply-ready**

   Use the **TodoWrite tool** to track progress through the artifacts.

   Loop through artifacts in dependency order (artifacts with no pending dependencies first):

   a. **For each artifact that is `ready` (dependencies satisfied)**:
      - Get instructions:
        ```bash
        openspec instructions <artifact-id> --change "<name>" --json
        ```
      - The instructions JSON includes:
        - `context`: Project background (constraints for you - do NOT include in output)
        - `rules`: Artifact-specific rules (constraints for you - do NOT include in output)
        - `template`: The structure to use for your output file
        - `instruction`: Schema-specific guidance for this artifact type
        - `outputPath`: Where to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure
      - Apply `context` and `rules` as constraints - but do NOT copy them into the file
      - Show brief progress: "Created <artifact-id>"

   b. **Continue until all `applyRequires` artifacts are complete**
      - After creating each artifact, re-run `openspec status --change "<name>" --json`
      - Check if every artifact ID in `applyRequires` has `status: "done"` in the artifacts array
      - Stop when all `applyRequires` artifacts are done

   c. **If an artifact requires user input** (unclear context):
      - Use **AskUserQuestion tool** to clarify
      - Then continue with creation

5. **Show final status**
   ```bash
   openspec status --change "<name>"
   ```

6. **Write to Obsidian vault**

   After all artifacts are created, persist to vault:

   ```powershell
   $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
   $p = Split-Path (Get-Location) -Leaf
   $date = Get-Date -Format "yyyy-MM-dd"

   # Write decisions note
   $decisionsDir = "$vault\projects\$p\decisions"
   New-Item -ItemType Directory -Force $decisionsDir | Out-Null

   $decisionNote = @"
   ---
   project: $p
   change: <change-name>
   date: $date
   status: activo
   tags: [openspec, proposal]
   ---

   ## Qué se propone
   <resumen extraído de proposal.md>

   ## Decisiones de diseño
   <puntos clave extraídos de design.md>

   ## Links
   [[$p/context]]
   "@
   $decisionNote | Out-File -FilePath "$decisionsDir\$date-<change-name>.md" -Encoding utf8

   # Update context.md
   $contextContent = @"
   ---
   project: $p
   updated: $date
   ---

   ## Estado actual
   Change activo: <change-name>

   ## Último propose
   <change-name> — $date

   ## Decisiones recientes
   <resumen del proposal>

   ## Contexto activo
   Change listo para implementar. Ejecutar en Copilot: /openspec-apply-change <change-name>
   "@
   $contextContent | Out-File -FilePath "$vault\projects\$p\context.md" -Encoding utf8
   ```

   Show: `✅ Obsidian: $vault\projects\{proyecto}\decisions\{fecha}-{change}.md`

   **If vault path does not exist:** skip silently, continue with the standard output.

7. **Create branch**

   After artifacts and vault write:
   ```powershell
   git checkout -b change/<change-name>
   ```

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- Obsidian note path (or skip notice)
- Branch created: `change/<change-name>`
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Ejecutá en Copilot: `/openspec-apply-change <change-name>`"
- "Cuando Copilot termine: `/opsx:verify <change-name>`"

**Artifact Creation Guidelines**

- Follow the `instruction` field from `openspec instructions` for each artifact type
- The schema defines what each artifact should contain - follow it
- Read dependency artifacts for context before creating new ones
- Use `template` as the structure for your output file - fill in its sections
- **IMPORTANT**: `context` and `rules` are constraints for YOU, not content for the file
  - Do NOT copy `<context>`, `<rules>`, `<project_context>` blocks into the artifact
  - These guide what you write, but should never appear in the output

**Guardrails**
- Create ALL artifacts needed for implementation (as defined by schema's `apply.requires`)
- Always read dependency artifacts before creating a new one
- If context is critically unclear, ask the user - but prefer making reasonable decisions to keep momentum
- If a change with that name already exists, ask if user wants to continue it or create a new one
- Verify each artifact file exists after writing before proceeding to next
- Obsidian write: if vault doesn't exist, skip silently — don't block the propose flow
- Branch creation: always create `change/<name>` after artifacts are ready
