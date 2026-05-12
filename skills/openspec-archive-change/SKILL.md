---
name: openspec-archive-change
description: Archive a completed change and export a summary note to the Obsidian vault at C:\TPA\.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.1"
  generatedBy: "1.3.1"
  modified: "hybrid-workflow — exports change summary to Obsidian vault after archive"
---

Archive a completed change in the experimental workflow.

**Input**: Optionally specify a change name. If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show only active changes (not already archived).
   Include the schema used for each change if available.

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check artifact completion status**

   Run `openspec status --change "<name>" --json` to check artifact completion.

   Parse the JSON to understand:
   - `schemaName`: The workflow being used
   - `artifacts`: List of artifacts with their status (`done` or other)

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Use **AskUserQuestion tool** to confirm user wants to proceed
   - Proceed if user confirms

   **If no tasks file exists:** Proceed without task-related warning.

4. **Assess delta spec sync state**

   Check for delta specs at `openspec/changes/<name>/specs/`. If none exist, proceed without sync prompt.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `openspec/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

5. **Perform the archive**

   Create the archive directory if it doesn't exist:
   ```powershell
   New-Item -ItemType Directory -Force "openspec/changes/archive"
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move the change directory to archive

   ```powershell
   Move-Item "openspec/changes/<name>" "openspec/changes/archive/YYYY-MM-DD-<name>"
   ```

5.5. **Export to Obsidian vault**

   After the move succeeds, export a summary note to `C:\TPA\`.

   Determine project name and vault path:
   ```powershell
   $projectName = Split-Path (Get-Location) -Leaf
   $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
   ```

   Read from the archived change at `openspec/changes/archive/YYYY-MM-DD-<name>/`:
   - `proposal.md` — extract the problem statement and goals (first meaningful sections)
   - `design.md` — extract key decisions and the `## Security Layer` section if present

   Build frontmatter + body and write to vault:
   ```powershell
   $vaultDir = "$vault\projects\$projectName\archive"
   New-Item -ItemType Directory -Force $vaultDir | Out-Null

   $noteFile = "$vaultDir\<YYYY-MM-DD>-<change-name>.md"
   $content = @"
   ---
   project: $projectName
   change: <change-name>
   date: <YYYY-MM-DD>
   status: archivado
   tags: [openspec, change]
   ---

   ## Qué resolvió
   <resumen extraído de proposal.md>

   ## Decisiones clave
   <puntos clave extraídos de design.md>

   ## Links
   [[$projectName/_index]]
   "@
   $content | Out-File -FilePath $noteFile -Encoding utf8

   # Update context.md
   $contextFile = "$vault\projects\$projectName\context.md"
   $contextContent = @"
   ---
   project: $projectName
   updated: <YYYY-MM-DD>
   ---

   ## Estado actual
   Sin change activo

   ## Último change
   <change-name> — archivado el <YYYY-MM-DD>

   ## Decisiones recientes
   <resumen de las decisiones clave del change archivado>

   ## Contexto activo
   Change archivado correctamente. Vault actualizado.
   "@
   $contextContent | Out-File -FilePath $contextFile -Encoding utf8

   # Update project index
   $indexFile = "$vault\projects\$projectName\_index.md"
   if (-not (Test-Path $indexFile)) { "# $projectName`n" | Out-File $indexFile -Encoding utf8 }
   Add-Content $indexFile "- [[archive/<YYYY-MM-DD>-<change-name>]] — <descripción breve>"
   ```

   **If vault path does not exist:** skip silently, note it in the final summary.

   Show inline: `✅ Obsidian: $vault\projects\{proyecto}\archive\{fecha}-{change-name}.md`

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Whether specs were synced (if applicable)
   - Obsidian note path (or skip notice if vault not found)
   - Note about any warnings (incomplete artifacts/tasks)

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** openspec/changes/archive/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" or "Sync skipped")
**Obsidian:** ✓ C:\TPA\projects\<proyecto>\YYYY-MM-DD-<name>.md

All artifacts complete. All tasks complete.
```

**Guardrails**
- Always prompt for change selection if not provided
- Use artifact graph (openspec status --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use openspec-sync-specs approach (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting
- Obsidian export: if `C:\TPA\` does not exist, skip silently and note it in the summary
