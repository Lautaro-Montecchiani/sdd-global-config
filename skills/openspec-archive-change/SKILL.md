---
name: openspec-archive-change
description: Archive a completed change and export a summary note to the Obsidian vault.
license: MIT
compatibility: Requires openspec CLI.
metadata:
  author: openspec
  version: "1.2"
  generatedBy: "1.4.1"
  modified: "hybrid-workflow — checks the PR was merged, exports change summary to the Obsidian vault after archive (archive note, decisions status, context.md, _index.md) and syncs the vault"
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
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context
   - `artifacts`: List of artifacts with their status (`done` or other)

   If status reports `actionContext.mode: "workspace-planning"`, explain that workspace archive is not supported in this slice and STOP. Do not move workspace changes into repo-local archives or edit linked repos.

   **If any artifacts are not `done`:**
   - Display warning listing incomplete artifacts
   - Prompt user for confirmation to continue
   - Proceed if user confirms

3. **Check task completion status**

   Read the tasks file (typically `tasks.md`) to check for incomplete tasks.

   Count tasks marked with `- [ ]` (incomplete) vs `- [x]` (complete).

   **If incomplete tasks found:**
   - Display warning showing count of incomplete tasks
   - Prompt user for confirmation to continue
   - Proceed if user confirms

   **If no tasks file exists:** Proceed without task-related warning.

3.5. **Check the change was merged**

   The global rules say the archive runs AFTER the merge, never before. Check whether the change's PR is merged, e.g. `gh pr list --state merged --head change/<name>` (or ask the user). If it is not merged or it cannot be determined: warn and ask for confirmation before continuing.

4. **Assess delta spec sync state**

   Use `artifactPaths.specs.existingOutputPaths` from status JSON to check for delta specs. If none exist, proceed without sync prompt.

   **If delta specs exist:**
   - Compare each delta spec with its corresponding main spec at `openspec/specs/<capability>/spec.md`
   - Determine what changes would be applied (adds, modifications, removals, renames)
   - Show a combined summary before prompting

   **Prompt options:**
   - If changes needed: "Sync now (recommended)", "Archive without syncing"
   - If already synced: "Archive now", "Sync anyway", "Cancel"

   If user chooses sync, use Task tool (subagent_type: "general-purpose", prompt: "Use Skill tool to invoke openspec-sync-specs for change '<name>'. Delta spec analysis: <include the analyzed delta spec summary>"). Proceed to archive regardless of choice.

5. **Perform the archive**

   Create an `archive` directory under `planningHome.changesDir` if it doesn't exist:
   ```bash
   mkdir -p "<planningHome.changesDir>/archive"
   ```

   Generate target name using current date: `YYYY-MM-DD-<change-name>`

   **Check if target already exists:**
   - If yes: Fail with error, suggest renaming existing archive or using different date
   - If no: Move `changeRoot` to the archive directory

   ```bash
   mv "<changeRoot>" "<planningHome.changesDir>/archive/YYYY-MM-DD-<name>"
   ```

5.5. **Export to the Obsidian vault**

   After the move succeeds, resolve the vault and project name:
   ```powershell
   $vault = if ($env:OBSIDIAN_VAULT) { $env:OBSIDIAN_VAULT } else { "C:\TPA" }
   $p = Split-Path (Get-Location) -Leaf
   ```

   **If `$vault` does not exist:** skip silently and note it in the final summary.

   Otherwise read from the archived change: `proposal.md` (problem and goals) and `design.md` (key decisions and the `## Security Layer` section if present). Then, using the Write tool (create folders if missing):

   a. **Archive note** at `$vault\projects\$p\archive\YYYY-MM-DD-<name>.md` with frontmatter (`project`, `change`, `date`, `status: archivado`, `tags: [openspec, change]`) and sections `## Qué resolvió`, `## Decisiones clave` and `## Links` (`[[<project>/_index]]`).

   b. **Decisions note**: if `$vault\projects\$p\decisions\*-<name>.md` exists, change `status: activo` to `status: archivado` in it.

   c. **context.md** at `$vault\projects\$p\context.md`: read the existing file first and rewrite it in the standard format (frontmatter `project` + `updated`; sections `## Estado actual`, `## Último change`, `## Decisiones recientes`, `## Contexto activo`). `Estado actual`: the remaining active changes (from `openspec list --json`) or "sin change activo". `Último change`: `<name> — archivado el YYYY-MM-DD`. Keep the last 2-3 relevant decisions and add the key ones of this change. Do NOT discard existing useful context.

   d. **_index.md** at `$vault\projects\$p\_index.md`: create it with a `# <project>` heading if missing, then append `- [[archive/YYYY-MM-DD-<name>]] — <short description>`.

   e. **Vault sync**: `git -C $vault add -A`, commit `chore: <project> — archive <name>` and push. If the push fails (no network, no remote, wrong GitHub account), continue and warn at the end.

   Show inline: `Obsidian: $vault\projects\<project>\archive\YYYY-MM-DD-<name>.md`

6. **Display summary**

   Show archive completion summary including:
   - Change name
   - Schema that was used
   - Archive location
   - Spec sync status (synced / sync skipped / no delta specs)
   - Obsidian note path (or skip notice if vault not found) and whether the vault push succeeded
   - Note about any warnings (incomplete artifacts/tasks, PR not confirmed as merged)
   - Reminder: the archive moved files in the repo; do not commit automatically — tell the user to commit them (`chore: archive <name>` with the `Spec-ID: <name>` trailer)

**Output On Success**

```
## Archive Complete

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/
**Specs:** ✓ Synced to main specs (or "No delta specs" or "Sync skipped")
**Obsidian:** ✓ <vault>\projects\<project>\archive\YYYY-MM-DD-<name>.md

All artifacts complete. All tasks complete.
```

**Output On Success With Warnings**

```
## Archive Complete (with warnings)

**Change:** <change-name>
**Schema:** <schema-name>
**Archived to:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/
**Specs:** Sync skipped (user chose to skip)

**Warnings:**
- Archived with 2 incomplete artifacts
- Archived with 3 incomplete tasks
- Delta spec sync was skipped (user chose to skip)
- PR not confirmed as merged

Review the archive if this was not intentional.
```

**Output On Error (Archive Exists)**

```
## Archive Failed

**Change:** <change-name>
**Target:** the archive path derived from `planningHome.changesDir`/YYYY-MM-DD-<name>/

Target archive directory already exists.

**Options:**
1. Rename the existing archive
2. Delete the existing archive if it's a duplicate
3. Wait until a different date to archive
```

**Guardrails**
- Always prompt for change selection if not provided
- Use artifact graph (openspec status --json) for completion checking
- Don't block archive on warnings - just inform and confirm
- Preserve .openspec.yaml when moving to archive (it moves with the directory)
- Show clear summary of what happened
- If sync is requested, use the Skill tool to invoke `openspec-sync-specs` (agent-driven)
- If delta specs exist, always run the sync assessment and show the combined summary before prompting
- Vault export: if the vault does not exist or the push fails, don't block the archive — note it in the summary
