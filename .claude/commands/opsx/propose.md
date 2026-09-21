---
name: "OPSX: Propose"
description: Propose a new change - create it, generate all artifacts, persist context to the vault and hand off to the Agent
category: Workflow
tags: [workflow, artifacts, experimental]
---

Propose a new change - create the change and generate all artifacts in one step.

I'll create a change with artifacts:
- proposal.md (what & why)
- specs (requirements, delta format)
- design.md (how, including `## Security Layer`)
- tasks.md (implementation steps)

When ready to implement, the Agent runs `/openspec-apply-change <name>`. Claude does NOT implement.

---

**Input**: The argument after `/opsx:propose` is the change name (kebab-case), OR a description of what the user wants to build.

**Steps**

0. **Read context (before starting)**

   Resolve vault and project name:
   ```powershell
   $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
   $p = Split-Path (Get-Location) -Leaf
   ```

   Read `$vault\projects\$p\context.md` if it exists and use it to inform the proposal — prior decisions, active changes, domain knowledge. If it doesn't exist, proceed without it.

   Read `project_type` from `openspec/config.yaml` and apply the minimum security controls for that type (see the global CLAUDE.md). `design.md` MUST include a `## Security Layer` section.

1. **If no input provided, ask what they want to build**

   Use the **AskUserQuestion tool** (open-ended, no preset options) to ask:
   > "What change do you want to work on? Describe what you want to build or fix."

   From their description, derive a kebab-case name (e.g., "add user authentication" → `add-user-auth`).

   **IMPORTANT**: Do NOT proceed without understanding what the user wants to build.

2. **Create the change directory**
   ```bash
   openspec new change "<name>"
   ```
   This creates a scaffolded change in the planning home resolved by the CLI with `.openspec.yaml`.

3. **Get the artifact build order**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to get:
   - `applyRequires`: array of artifact IDs needed before implementation (e.g., `["tasks"]`)
   - `artifacts`: list of all artifacts with their status and dependencies
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context. Use these instead of assuming repo-local paths.

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
        - `resolvedOutputPath`: Resolved path or pattern to write the artifact
        - `dependencies`: Completed artifacts to read for context
      - Read any completed dependency files for context
      - Create the artifact file using `template` as the structure and write it to `resolvedOutputPath`
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
   Also run `openspec validate "<name>"` and fix any error before continuing.

6. **Write to the Obsidian vault**

   If `$vault` does not exist: skip silently and note it in the output. Never block the propose flow on the vault.

   Otherwise, use the Write tool (create the folders if missing) for:

   a. **Decisions note** at `$vault\projects\$p\decisions\YYYY-MM-DD-<name>.md`, with frontmatter (`project`, `change`, `date`, `status: activo`, `tags: [openspec, proposal]`) and sections `## Qué se propone` (summary of proposal.md), `## Decisiones de diseño` (key points of design.md) and `## Links` (`[[<project>/context]]`).

   b. **context.md** at `$vault\projects\$p\context.md`: read the existing file first and rewrite it in the standard format (frontmatter `project` + `updated`; sections `## Estado actual`, `## Último change`, `## Decisiones recientes`, `## Contexto activo`). Keep the last 2-3 relevant decisions already there and add this change's. Set `Estado actual` to the active change and `Contexto activo` to: "Change listo para implementar. Ejecutar en el Agente: /openspec-apply-change <name>". Do NOT discard existing useful context.

   c. **Vault sync**: `git -C $vault add -A`, commit `chore: <project> — propose <name>` and push. If the push fails (no network, no remote, wrong GitHub account), continue and warn at the end.

   Show: `Obsidian: $vault\projects\<project>\decisions\YYYY-MM-DD-<name>.md`

7. **Create the branch and commit the artifacts**

   ```bash
   git checkout -b change/<name>
   ```

   Then commit only the change artifacts (spec changes go in their own commit, per the global rules):
   ```bash
   git add openspec/changes/<name>
   git commit -m "docs: propose <name>" -m "Spec-ID: <name>"
   ```
   Run `git diff --staged` first and make sure nothing sensitive is staged. Do NOT push.

**Output**

After completing all artifacts, summarize:
- Change name and location
- List of artifacts created with brief descriptions
- Obsidian note path (or skip notice)
- Branch created: `change/<name>` and artifacts commit
- What's ready: "All artifacts created! Ready for implementation."
- Prompt: "Ejecutá en el Agente: `/openspec-apply-change <name>`"
- "Cuando el Agente termine: `/opsx:verify <name>`"

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
- NEVER write production code — Claude is the architect, the Agent implements
- Vault write: if the vault doesn't exist or the push fails, don't block the propose flow
- Branch creation: always create `change/<name>` after artifacts are ready; never work on main/master for a change with spec
