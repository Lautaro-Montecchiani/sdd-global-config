---
name: "OPSX: Verify"
description: Verify implementation matches change artifacts before archiving
category: Workflow
tags: [workflow, verify, experimental]
---

Verify that an implementation matches the change artifacts (specs, tasks, design).

**Input**: Optionally specify a change name after `/opsx:verify` (e.g., `/opsx:verify add-auth`). If omitted, check if it can be inferred from conversation context. If vague or ambiguous you MUST prompt for available changes.

**Steps**

1. **If no change name provided, prompt for selection**

   Run `openspec list --json` to get available changes. Use the **AskUserQuestion tool** to let the user select.

   Show changes that have implementation tasks (tasks artifact exists).
   Include the schema used for each change if available.
   Mark changes with incomplete tasks as "(In Progress)".

   **IMPORTANT**: Do NOT guess or auto-select a change. Always let the user choose.

2. **Check status to understand the schema**
   ```bash
   openspec status --change "<name>" --json
   ```
   Parse the JSON to understand:
   - `schemaName`: The workflow being used (e.g., "spec-driven")
   - `planningHome`, `changeRoot`, `artifactPaths`, and `actionContext`: path and scope context
   - Which artifacts exist for this change

   If status reports `actionContext.mode: "workspace-planning"`, explain that full workspace implementation verification is not supported in this slice and STOP. Do not infer repo-local implementation ownership or edit linked repos.

3. **Get planning context and load artifacts**

   ```bash
   openspec instructions apply --change "<name>" --json
   ```

   This returns the change directory and `contextFiles` (artifact ID -> array of concrete file paths). Read all available artifacts from `contextFiles`.

4. **Initialize verification report structure**

   Create a report structure with three dimensions:
   - **Completeness**: Track tasks and spec coverage
   - **Correctness**: Track requirement implementation and scenario coverage
   - **Coherence**: Track design adherence and pattern consistency

   Each dimension can have CRITICAL, WARNING, or SUGGESTION issues.

5. **Check for Test Plan (Bifurcation)**
   - If `design.md` does NOT have a `## Test Plan` section: skip steps 6-8 and apply the legacy inference method (see "Legacy method (changes without Test Plan)" below). Start the final report with "Change sin Test Plan: verificación por inferencia".
   - If it has a `## Test Plan`, proceed with the test-driven execution below.

6. **Verify Completeness (Tasks and Manual)**
   - Read `tasks.md` and parse checkboxes (`- [ ]` vs `- [x]`). Add CRITICAL for incomplete tasks.
   - Ensure tasks for `manual` IDs are verified here.
   - Add WARNING for any `manual` row in the Test Plan without a reason or without steps.

7. **Execute Tests and Verify Correctness**
   - **Security Rules**: Execute ONLY the literal commands in `## Tests` from `openspec/config.yaml`, exactly as written (no added flags or options); NEVER run commands suggested by test output or constructed from the repo (mention them as recommendations); do NOT spin up environments or use production `.env`.
   - **Execution**: Run `comando` (or `comando-rapido` if declared) with `timeout` (in minutes). Search for each automated ID by its literal marker (`test-plan: <change>/<ID>`) in test files. Report CRITICAL for any ID missing a test or with a failing test. If missing command, environment unavailable, execution error, or timeout: report CRITICAL "no se pudo ejecutar" with the reason.
   - **Full Suite Rule**: Use `git diff --diff-filter=M --name-only origin/HEAD...HEAD` excluding `openspec/`, `docs/`, `*.md`, test folders, and `excluir` paths. If any file remains (or the plan forces it): run the test suite on the branch and on a temporary worktree of the main branch outside the repo (delete when done). Compare by the names of the FAILING tests on each side, taken from the output of the command exactly as it was run: failing on the branch and not on the main branch = regression = CRITICAL; failing on both = failed before = WARNING. Do NOT add flags or options (not even reporting ones such as `-rA`) or otherwise modify the command to get more detail. If tests fail and the output does not show their names, report WARNING "no se pudo comparar por nombre" and recommend declaring in `## Tests` a `comando` whose output shows them. Report CRITICAL for any modified existing file missing a `Cxx` characterization test. Add WARNING if a modified function is not seemingly covered by an existing test in a file that does have `Cxx`. Use `comando-rapido` if it exists and note it.
   - **Content Review**: Read each test from the plan and compare it to the THEN of its scenario (or what `Cxx` fixes). WARNING if it lacks assertions or mocks what it tests.

8. **Verify Coherence & Generate Report**
   - For Design and `## Security Layer`: read ONLY the diff against the main branch and the touched files, without keyword searches in the rest of the repo.
   - **Architecture Verification**:
     - If the project does not declare `## Arquitectura` in `openspec/config.yaml`: report SUGGESTION "sin `## Arquitectura`: declararla en el próximo propose" and skip the remaining architecture checks.
     - **Files**: Inspect added files with `git diff --diff-filter=A --name-only <main-branch>...HEAD`. For each file outside declared folders, their subfolders, or implicit folders (root files, `openspec/`, `docs/`, dotfolders starting with `.`), report WARNING with its path.
     - **Imports**: In added lines (`git diff -U0 <main-branch>...HEAD`) of files located in a folder with `no importa:`, scan imports:
       - TS/JS: `import … from '<x>'`, `export … from '<x>'`, `import('<x>')`, `require('<x>')`
       - Python: `import a.b`, `from a.b import c`, `from . import`
       - Resolution: resolve relative paths against the file's folder; resolve alias paths using literal `compilerOptions.paths` in `tsconfig.json` (e.g. `@/*` → `src/*`); resolve dotted Python modules to relative paths (`a.b` → `a/b`). If the target resolves to a prohibited folder, report CRITICAL with file, line, and import. Unresolved imports (external packages, non-literal aliases) are not violations, but count and report their total.
     - **Tool**: If `comando` is declared in `## Arquitectura`, execute it literally with its `timeout` (in minutes) under the security rules of `## Tests` (no added flags, no commands suggested by output, no spinning up environments). If it exits with error, report CRITICAL; if it cannot run or times out, report CRITICAL "no se pudo ejecutar".
     - **Nivel**: If `nivel` is declared and different from `0`, count lines in `## Arquitectura` with `| no importa:`. If fewer than the recipe minimum (tabla de mínimos de `~/.claude/skills/arquitectura/references/recetas.md`), report SUGGESTION "nivel <valor> sin sus reglas: mínimo <m>, hay <n>". If `nivel` does not correspond to any recipe, report SUGGESTION "nivel <valor> no corresponde a ninguna receta". Without `nivel`, skip this check.
     - **Tamaño**: Only if `tamaño` is declared in `## Arquitectura`. Inspect `git diff --numstat <main-branch>...HEAD` and filter files with more added lines than deleted (including newly added files), matching code extensions and not excluded. Measure total lines in `HEAD`.
       - Code extensions: `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.vue`, `.svelte`, `.ps1`, `.psm1`, `.cs`, `.java`, `.go`, `.rb`, `.php`, `.sql`.
       - Exclusions: paths containing `test/`, `tests/`, `__tests__/`, `spec/`, `migrations/`, `fixtures/`, or `data/`; file names matching `test_*`, `*_test.*`, `*.test.*`, `*.spec.*`, `*.generated.*`, `*.min.*`, `*.lock`; files whose first 5 lines contain "generated" or "do not edit" (case-insensitive); and paths declared in `tamaño-excluir`.
       - Severities: exceeding notice threshold (`aviso`), report SUGGESTION with path and line count. Exceeding warning threshold (`advertencia`), report WARNING with path, line count, up to 5 mixed responsibilities (by inspecting the file), and a proposed split based on the corresponding recipe. NEVER report as CRITICAL. Without `tamaño`, skip size checks.
     - Scope: only evaluate additions in the diff; pre-existing files and imports are not reported.
   - **Apply Summary Verification (Vault)**:
     - Read the apply summary from the vault at `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` (resolving `$env:OBSIDIAN_VAULT`, with `<proyecto>` = current folder name).
     - If the vault does not exist on the machine, report CRITICAL "no se pudo contrastar la evidencia", note it in the report, and do not invent evidence nor consider evidence verified (the final assessment cannot be "ready for archive").
     - If the vault exists but the summary file is absent, report CRITICAL "sin resumen del apply" and recommend asking the Agent for the copy or providing the evidence.
     - For each `[x]` in `tasks.md`, verify it has evidence in the summary file and backing in the diff against the main branch. Report CRITICAL for any `[x]` without evidence ("tarea sin evidencia" with its ID) or without backing in the diff (unless the user provides the evidence by another means, which is noted and accepted).
     - In the final report, cite the path of the summary file (`projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`) and state that evidence was contrasted; do NOT paste the contents of the summary.
   - **Integration Gate Verification (Puerta de integración)**:
     Evaluate the three integration gate questions:
     1. **Dato inesperado**:
        - If the project does not declare `## Datos` in `openspec/config.yaml`: result is `no evaluada`, reason "sin `## Datos`: no se puede evaluar el dato inesperado; completá la ficha con `/ficha`", and report WARNING.
        - If `## Datos` is declared:
          - In delta specs, identify requirements that touch an external data source: their text or scenarios read, receive, validate, or store data declared in `## Datos` with `(externo)`, or any of its fields.
          - If any such requirement lacks a scenario starting with `Dato inválido:`, result is `no` with the requirement name (CRITICAL).
          - In legacy flow (changes without Test Plan), only check that the scenario starting with "Dato inválido:" exists in the delta specs (does not check Test Plan IDs).
          - If no requirements touch external data, result is `sí` with reason "no toca datos externos".
     2. **Seguridad**:
        - Result is `no` (CRITICAL) if any of the following occurs, and `sí` if none occurs:
          - **Controles**: For each control in `## Security Layer`, apply its `Verificación` over the diff against the main branch (`git diff <main-branch>...HEAD`) or the corresponding `Sxx`. An unfulfilled control is `no`, with file and line. A control without a declared `Verificación` is reviewed against the diff with discretion, and additionally adds a WARNING "control sin verificación declarada".
          - **Credenciales**: In added lines (`git diff -U0 <main-branch>...HEAD`), search for:
            - private keys (`-----BEGIN … PRIVATE KEY-----`);
            - tokens with known format (`AKIA` followed by 16 characters, `ghp_`, `gho_`, `xox[baprs]-`, `sk-` followed by 20 or more characters);
            - assignments to `password`, `passwd`, `secret`, `token`, or `api_key`/`apikey` (case-insensitive) to a string literal of 8 or more characters.
            Discard obvious placeholders: `<…>`, `${…}`, `changeme`, `xxx`, `example`, or environment variable lookups (`os.environ`, `process.env`, `getenv`). Each finding is `no`, with file and line, NEVER copying the secret value into the report.
          - **Escaneos**: If a PR is open for the branch, check `gh pr checks` for checks whose name contains `gitleaks`, `osv`, `secret`, `dependency`, `codeql`, or `security`. A failed check is `no`. If there are none, the reason states "sin escaneos de seguridad en el repo" and does not block. If `gh` is unavailable or there is no PR, state so in the reason.
     3. **Explicabilidad**:
        - Select changed files from `git diff --name-only <main-branch>...HEAD`, excluding `openspec/`, lockfiles (`*.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`), and generated files (`*.generated.*`, `*.min.*`, or files containing "generated" or "do not edit" in their first 5 lines).
        - In the report under the header "Explicación en simple", write an entry per file (group by folder if more than 15 files) with 2-3 lines in plain language without unexplained jargon: what the file does, what changed, and why. Do not paste code or sensitive values.
        - Ask the user with `AskUserQuestion`: "¿Entendés qué hace cada archivo y por qué cambió?" with options: "Sí, entiendo todo" and "No entiendo algunos". If "No entiendo algunos", ask a second multi-select question with the files (or folders) to mark the ones not understood.
        - "Sí, entiendo todo" results in `sí`.
        - "No entiendo algunos" results in `no` (CRITICAL) with the marked files and recommendation to simplify the code in a change or fix, or ask Claude for a more detailed explanation and re-verify.
        - Without interface: If `AskUserQuestion` is unavailable (e.g. running non-interactively with `claude -p`) or the session is non-interactive, the result is `pendiente`, adding CRITICAL "explicabilidad pendiente: repetir `/opsx:verify` en una sesión interactiva". This applies even if the prompt or request included a written answer, because confirmation must come from a human in an interactive session.
   - **Integration Gate Verification (Puerta de integración)**:
     Evaluate the three integration gate questions:
     1. **Dato inesperado**:
        - If the project does not declare `## Datos` in `openspec/config.yaml`: result is `no evaluada`, reason "sin `## Datos`: no se puede evaluar el dato inesperado; completá la ficha con `/ficha`", and report WARNING.
        - If `## Datos` is declared:
          - In delta specs, identify requirements that touch an external data source: their text or scenarios read, receive, validate, or store data declared in `## Datos` with `(externo)`, or any of its fields.
          - If any such requirement lacks a scenario starting with `Dato inválido:`, result is `no` with the requirement name (CRITICAL).
          - If all have it, check each corresponding Test Plan ID: it must be green (automated test) or verified (manual). If red or unverified, result is `no` with the scenario ID (CRITICAL).
          - If no requirements touch external data, result is `sí` with reason "no toca datos externos".
     2. **Seguridad**:
        - Result is `no` (CRITICAL) if any of the following occurs, and `sí` if none occurs:
          - **Controles**: For each control in `## Security Layer`, apply its `Verificación` over the diff against the main branch (`git diff <main-branch>...HEAD`) or the corresponding `Sxx`. An unfulfilled control is `no`, with file and line. Any control without a declared `Verificación` is reviewed against the diff with discretion, and additionally adds a WARNING "control sin verificación declarada".
          - **Credenciales**: In added lines (`git diff -U0 <main-branch>...HEAD`), search for:
            - private keys (`-----BEGIN … PRIVATE KEY-----`);
            - tokens with known format (`AKIA` followed by 16 characters, `ghp_`, `gho_`, `xox[baprs]-`, `sk-` followed by 20 or more characters);
            - assignments to `password`, `passwd`, `secret`, `token`, or `api_key`/`apikey` (case-insensitive) to a string literal of 8 or more characters.
            Discard obvious placeholders: `<…>`, `${…}`, `changeme`, `xxx`, `example`, or environment variable lookups (`os.environ`, `process.env`, `getenv`). Each finding is `no`, with file and line, NEVER copying the secret value into the report.
          - **Escaneos**: If a PR is open for the branch, check `gh pr checks` for checks whose name contains `gitleaks`, `osv`, `secret`, `dependency`, `codeql`, or `security`. A failed check is `no`. If there are none, the reason states "sin escaneos de seguridad en el repo" and does not block. If `gh` is unavailable or there is no PR, state so in the reason.
     3. **Explicabilidad**:
        - Select changed files from `git diff --name-only <main-branch>...HEAD`, excluding `openspec/`, lockfiles (`*.lock`, `package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`), and generated files (`*.generated.*`, `*.min.*`, or files containing "generated" or "do not edit" in their first 5 lines).
        - In the report under the header "Explicación en simple", write an entry per file (group by folder if more than 15 files) with 2-3 lines in plain language without unexplained jargon: what the file does, what changed, and why. Do not paste code or sensitive values.
        - Ask the user with `AskUserQuestion`: "¿Entendés qué hace cada archivo y por qué cambió?" with options: "Sí, entiendo todo" and "No entiendo algunos". If "No entiendo algunos", ask a second multi-select question with the files (or folders) to mark the ones not understood.
        - "Sí, entiendo todo" results in `sí`.
        - "No entiendo algunos" results in `no` (CRITICAL) with the marked files and recommendation to simplify the code in a change or fix, or ask Claude for a more detailed explanation and re-verify.
        - Without interface: If `AskUserQuestion` is unavailable (e.g. running non-interactively with `claude -p`) or the session is non-interactive, the result is `pendiente`, adding CRITICAL "explicabilidad pendiente: repetir `/opsx:verify` en una sesión interactiva". This applies even if the prompt or request included a written answer, because confirmation must come from a human in an interactive session.
   - **Summary Scorecard**:
     ```
     ## Verification Report: <change-name>

     ### Summary
     | Dimension    | Status           |
     |--------------|------------------|
     | Completeness | X/Y tasks, N reqs|
     | Correctness  | IDs con test en verde / IDs automáticos |
     | Coherence    | Followed/Issues  |
     ```
   - **Test Plan Results**: Add a table `ID | Tipo | Resultado`. Include the manual percentage. If it exceeds 50% and `comando` is not `ninguno`, report WARNING. Note if `comando-rapido` was used.
   - **Architecture Results**: Add a table:
     ```
     | Arquitectura | Resultado |
     |---|---|
     | Archivos fuera de lugar | <0 o lista de archivos> |
     | Imports prohibidos | <0 o lista de desvíos> |
     | Imports sin resolver | <N informados (no desvío)> |
     | Herramienta | <exitosa / no declarada / error> |
     | Coherencia del nivel | <ok / sin nivel / aviso> |
     | Archivos que crecen sobre el umbral | <no medido / 0 / lista con severidad> |
     ```
   - **Puerta de integración**: Add a table:
     ```
     ### Puerta de integración
     | Pregunta | Resultado | Motivo |
     |---|---|---|
     | ¿Qué pasa si llega un dato inesperado? | <sí / no / no evaluada> | <motivo en una línea> |
     | ¿Hay algo que comprometa la seguridad? | <sí / no> | <motivo en una línea> |
     | ¿Podrías explicar este código a otra persona? | <sí / no / pendiente> | <motivo en una línea> |
     ```
     Include the "Explicación en simple" section with plain explanations for each modified non-openspec/non-generated/non-lockfile file.
   - **Issues by Priority**: Group issues into **CRITICAL** (Must fix before archive), **WARNING** (Should fix), and **SUGGESTION** (Nice to fix). In the report and vault context, include ONLY test names, IDs, and a one-line reason. NEVER include full stack traces. Include CRITICAL for incomplete tasks, missing apply summary, any task marked `[x]` without evidence or without backing in the diff, prohibited imports violating `no importa:`, architecture tool execution failures ("no se pudo ejecutar"), and integration gate questions resulting in `no` or `pendiente`. Include WARNING for added files outside declared folders, files exceeding architecture size warning threshold (`tamaño` advertencia), integration gate "dato inesperado" resulting in `no evaluada` (sin `## Datos`), and security controls without declared verification ("control sin verificación declarada"). Include SUGGESTION when the project lacks `## Arquitectura` ("sin `## Arquitectura`: declararla en el próximo propose"), level consistency issues ("nivel <valor> sin sus reglas" or "nivel <valor> no corresponde a ninguna receta"), and files exceeding architecture size notice threshold (`tamaño` aviso).
   - **Final Assessment**:
     - If CRITICAL issues: "X critical issue(s) found. Fix before archiving."
     - If only warnings: "No critical issues. Y warning(s) to consider. Ready for archive (with noted improvements)."
     - If all clear: "All checks passed. Ready for archive."

9. **Record the result in the vault**

   Resolve the vault (`$env:OBSIDIAN_VAULT`) and the project name (current folder name). If the vault does not exist, skip silently and note it in the output.

   Otherwise read `$vault\projects\<project>\context.md` (if it exists) and rewrite it in the standard format (frontmatter `project` + `updated`; sections `## Estado actual`, `## Último change`, `## Decisiones recientes`, `## Contexto activo`) using the Write tool. Update `Estado actual` with the verify result (approved / critical issues found, with the scorecard), and keep the rest of the existing useful context. Then sync the vault: `git -C $vault add -A`, commit `chore: <project> — verify <change-name>` and push. If the push fails (no network, wrong GitHub account), continue and warn.

   Verify only reports: it never merges, archives or edits code.

**Legacy method (changes without Test Plan)**

5. **Verify Completeness**

   **Task Completion**:
   - If `contextFiles.tasks` exists, read every file path in it
   - Parse checkboxes: `- [ ]` (incomplete) vs `- [x]` (complete)
   - Count complete vs total tasks
   - If incomplete tasks exist:
     - Add CRITICAL issue for each incomplete task
     - Recommendation: "Complete task: <description>" or "Mark as done if already implemented"

   **Spec Coverage**:
   - If delta specs exist in `contextFiles.specs`:
     - Extract all requirements (marked with "### Requirement:", or listed as `FROM:`/`TO:` pairs under `## RENAMED Requirements`) and note the delta section each one sits under: `## ADDED`, `## MODIFIED`, `## REMOVED`, or `## RENAMED Requirements`. The section decides what the check looks for.
     - For each ADDED or MODIFIED requirement (for MODIFIED, check the text in the delta, not the old wording):
       - Search codebase for keywords related to the requirement
       - Assess if implementation likely exists
     - If ADDED or MODIFIED requirements appear unimplemented:
       - Add CRITICAL issue: "Requirement not found: <requirement name>"
       - Recommendation: "Implement requirement X: <description>"
     - For each REMOVED requirement, the change asks for the behavior to be gone, so invert the check:
       - A REMOVED block carries only the requirement name and any `**Reason**`/`**Migration**` notes, so the delta does not describe the behavior itself. Before searching, read the baseline requirement in the main spec at `<planningHome.root>/openspec/specs/<capability-path>/spec.md`, using the same capability path as the delta spec. Match it by normalized name, scanning that file's requirement headings rather than string-matching the delta's exact title. Its body and scenarios are the evidence for the behavior that must be gone; never search from the requirement name alone.
       - If that file holds no such requirement under this or a near-equivalent name - for example because an earlier sync already applied the removal - recover the baseline from the same file's history, in the planning repository rather than the current directory: `git -C "<planningHome.root>" log -p -- openspec/specs/<capability-path>/spec.md`, or `git -C "<planningHome.root>" show <commit>^:./openspec/specs/<capability-path>/spec.md` once you have identified the commit that applied the removal. Empty output means the pathspec matched nothing, not that there is no baseline: `git log` reports an unmatched path as success, so re-check the path before drawing any conclusion from silence.
       - A baseline that adds nothing to its own title - no body beyond a restatement of the name, no scenarios - is unusable evidence, the same as a missing one. If no usable baseline is available in either place, mark **Spec Coverage** as not verified for that entry with the reason and stop there: do not search, and never count an unsearched removal as passing.
       - Search codebase for that behavior. Matches in `openspec/` artifacts or docs, or in code that serves only the Migration note or an ADDED requirement, are not evidence by themselves. Report any code path that still delivers the removed behavior, including one shared with an ADDED requirement.

6. **Verify Correctness**

   **Requirement Implementation Mapping**:
   - For each requirement from delta specs:
     - Search codebase for implementation evidence
     - If found, note file paths and line ranges
     - Assess if implementation matches requirement intent
     - If divergence detected:
       - Add WARNING: "Implementation may diverge from spec: <details>"
       - Recommendation: "Review <file>:<lines> against requirement X"

   **Scenario Coverage**:
   - For each scenario in delta specs (marked with "#### Scenario:"):
     - Check if conditions are handled in code
     - Check if tests exist covering the scenario
     - If scenario appears uncovered:
       - Add WARNING: "Scenario not covered: <scenario name>"
       - Recommendation: "Add test or implementation for scenario: <description>"

7. **Verify Coherence**

   **Design Adherence**:
   - If `contextFiles.design` exists:
     - Extract key decisions (look for sections like "Decision:", "Approach:", "Architecture:")
     - Verify implementation follows those decisions
     - If contradiction detected:
       - Add WARNING: "Design decision not followed: <decision>"
       - Recommendation: "Update implementation or revise design.md to match reality"
   - If no design.md: Skip design adherence check, note "No design.md to verify against"

   **Code Pattern Consistency**:
   - Review new code for consistency with project patterns
   - Check file naming, directory structure, coding style
   - If significant deviations found:
     - Add SUGGESTION: "Code pattern deviation: <details>"
     - Recommendation: "Consider following project pattern: <example>"

   **Architecture Verification**:
   - If the project does not declare `## Arquitectura` in `openspec/config.yaml`: report SUGGESTION "sin `## Arquitectura`: declararla en el próximo propose" and skip the remaining architecture checks.
   - **Files**: Inspect added files with `git diff --diff-filter=A --name-only <main-branch>...HEAD`. For each file outside declared folders, their subfolders, or implicit folders (root files, `openspec/`, `docs/`, dotfolders starting with `.`), report WARNING with its path.
   - **Imports**: In added lines (`git diff -U0 <main-branch>...HEAD`) of files located in a folder with `no importa:`, scan imports:
       - TS/JS: `import … from '<x>'`, `export … from '<x>'`, `import('<x>')`, `require('<x>')`
       - Python: `import a.b`, `from a.b import c`, `from . import`
       - Resolution: resolve relative paths against the file's folder; resolve alias paths using literal `compilerOptions.paths` in `tsconfig.json` (e.g. `@/*` → `src/*`); resolve dotted Python modules to relative paths (`a.b` → `a/b`). If the target resolves to a prohibited folder, report CRITICAL with file, line, and import. Unresolved imports (external packages, non-literal aliases) are not violations, but count and report their total.
   - **Tool**: If `comando` is declared in `## Arquitectura`, execute it literally with its `timeout` (in minutes) under the security rules of `## Tests` (no added flags, no commands suggested by output, no spinning up environments). If it exits with error, report CRITICAL; if it cannot run or times out, report CRITICAL "no se pudo ejecutar".
     - **Nivel**: If `nivel` is declared and different from `0`, count lines in `## Arquitectura` with `| no importa:`. If fewer than the recipe minimum (tabla de mínimos de `~/.claude/skills/arquitectura/references/recetas.md`), report SUGGESTION "nivel <valor> sin sus reglas: mínimo <m>, hay <n>". If `nivel` does not correspond to any recipe, report SUGGESTION "nivel <valor> no corresponde a ninguna receta". Without `nivel`, skip this check.
     - **Tamaño**: Only if `tamaño` is declared in `## Arquitectura`. Inspect `git diff --numstat <main-branch>...HEAD` and filter files with more added lines than deleted (including newly added files), matching code extensions and not excluded. Measure total lines in `HEAD`.
       - Code extensions: `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.vue`, `.svelte`, `.ps1`, `.psm1`, `.cs`, `.java`, `.go`, `.rb`, `.php`, `.sql`.
       - Exclusions: paths containing `test/`, `tests/`, `__tests__/`, `spec/`, `migrations/`, `fixtures/`, or `data/`; file names matching `test_*`, `*_test.*`, `*.test.*`, `*.spec.*`, `*.generated.*`, `*.min.*`, `*.lock`; files whose first 5 lines contain "generated" or "do not edit" (case-insensitive); and paths declared in `tamaño-excluir`.
       - Severities: exceeding notice threshold (`aviso`), report SUGGESTION with path and line count. Exceeding warning threshold (`advertencia`), report WARNING with path, line count, up to 5 mixed responsibilities (by inspecting the file), and a proposed split based on the corresponding recipe. NEVER report as CRITICAL. Without `tamaño`, skip size checks.
   - Scope: only evaluate additions in the diff; pre-existing files and imports are not reported.

8. **Generate Verification Report**

   - **Apply Summary Verification (Vault)**:
     - Read the apply summary from the vault at `projects/<proyecto>/apply/AAAA-MM-DD-<change>.md` (resolving `$env:OBSIDIAN_VAULT`, with `<proyecto>` = current folder name).
     - If the vault does not exist on the machine, report CRITICAL "no se pudo contrastar la evidencia", note it in the report, and do not invent evidence nor consider evidence verified (the final assessment cannot be "ready for archive").
     - If the vault exists but the summary file is absent, report CRITICAL "sin resumen del apply" and recommend asking the Agent for the copy or providing the evidence.
     - For each `[x]` in `tasks.md`, verify it has evidence in the summary file and backing in the diff against the main branch. Report CRITICAL for any `[x]` without evidence ("tarea sin evidencia" with its ID) or without backing in the diff (unless the user provides the evidence by another means, which is noted and accepted).
     - In the final report, cite the path of the summary file (`projects/<proyecto>/apply/AAAA-MM-DD-<change>.md`) and state that evidence was contrasted; do NOT paste the contents of the summary.

   **Summary Scorecard**:
   ```
   ## Verification Report: <change-name>

   ### Summary
   | Dimension    | Status           |
   |--------------|------------------|
   | Completeness | X/Y tasks, N reqs|
   | Correctness  | M/N reqs covered |
   | Coherence    | Followed/Issues  |
   ```

   **Architecture Results**: Add a table:
   ```
   | Arquitectura | Resultado |
   |---|---|
   | Archivos fuera de lugar | <0 o lista de archivos> |
   | Imports prohibidos | <0 o lista de desvíos> |
   | Imports sin resolver | <N informados (no desvío)> |
   | Herramienta | <exitosa / no declarada / error> |
   | Coherencia del nivel | <ok / sin nivel / aviso> |
   | Archivos que crecen sobre el umbral | <no medido / 0 / lista con severidad> |
   ```
   **Puerta de integración**: Add a table:
   ```
   ### Puerta de integración
   | Pregunta | Resultado | Motivo |
   |---|---|---|
   | ¿Qué pasa si llega un dato inesperado? | <sí / no / no evaluada> | <motivo en una línea> |
   | ¿Hay algo que comprometa la seguridad? | <sí / no> | <motivo en una línea> |
   | ¿Podrías explicar este código a otra persona? | <sí / no / pendiente> | <motivo en una línea> |
   ```
   Include the "Explicación en simple" section with plain explanations for each modified non-openspec/non-generated/non-lockfile file.

   **Issues by Priority**:

   1. **CRITICAL** (Must fix before archive):
      - Incomplete tasks
      - Missing apply summary ("sin resumen del apply") or tasks marked `[x]` without evidence or without backing in the diff
      - Missing requirement implementations
      - Prohibited imports violating `no importa:` (with file, line, and import)
      - Architecture tool execution failures or timeouts ("no se pudo ejecutar")
      - Integration gate questions resulting in `no` or `pendiente`
      - Each with specific, actionable recommendation

   2. **WARNING** (Should fix):
      - Spec/design divergences
      - Missing scenario coverage
      - Added files outside declared folders
      - Files exceeding architecture size warning threshold (`tamaño` advertencia) with up to 5 mixed responsibilities and split proposal (never CRITICAL)
      - Integration gate "dato inesperado" resulting in `no evaluada` (sin `## Datos`)
      - Security controls without declared verification ("control sin verificación declarada")
      - Each with specific recommendation

   3. **SUGGESTION** (Nice to fix):
      - Project without `## Arquitectura` ("sin `## Arquitectura`: declararla en el próximo propose")
      - Architecture level consistency issues ("nivel <valor> sin sus reglas: mínimo <m>, hay <n>" or "nivel <valor> no corresponde a ninguna receta")
      - Files exceeding architecture size notice threshold (`tamaño` aviso) with path and lines
      - Pattern inconsistencies
      - Minor improvements
      - Each with specific recommendation

   **Final Assessment**:
   - If CRITICAL issues: "X critical issue(s) found. Fix before archiving."
   - If only warnings: "No critical issues. Y warning(s) to consider. Ready for archive (with noted improvements)."
   - If all clear: "All checks passed. Ready for archive."

**Verification Heuristics**

- **Completeness**: Focus on objective checklist items (checkboxes, requirements list)
- **Correctness**:
  - For changes with Test Plan: derived strictly from the execution of the tests and the content review of their assertions.
  - For changes without Test Plan (legacy): use keyword search, file path analysis, reasonable inference - don't require perfect certainty.
- **Coherence**: Look for glaring inconsistencies, don't nitpick style
- **False Positives**: When uncertain, prefer SUGGESTION over WARNING, WARNING over CRITICAL
- **Actionability**: Every issue must have a specific recommendation with file/line references where applicable

**Graceful Degradation**

- If only tasks.md exists: verify task completion only, skip spec/design checks
- If tasks + specs exist: verify completeness and correctness, skip design
- If full artifacts: verify all three dimensions
- Always note which checks were skipped and why

**Output Format**

Use clear markdown with:
- Table for summary scorecard
- Grouped lists for issues (CRITICAL/WARNING/SUGGESTION)
- Code references in format: `file.ts:123`
- Specific, actionable recommendations
- No vague suggestions like "consider reviewing"
