---
name: branch-pr
description: Open a Pull Request after the Agent finishes implementing. Validates branch name, commit format, Spec-ID, and that OpenSpec artifacts exist before creating the PR.
license: MIT
metadata:
  version: "1.0"
---

Open a Pull Request following the conventions of the SDD hybrid workflow.

**When to use:** After `/opsx:apply` completes (el Agente terminó de implementar) and before `/opsx:verify`.

---

**Input**: Change name (kebab-case). If omitted, infer from current branch or ask.

**Steps**

1. **Detect change name and branch**

   ```bash
   git branch --show-current
   ```

   Expected format: `change/{nombre}`. If the branch doesn't match, warn and ask for confirmation before continuing.

2. **Validate commits on the branch**

   ```bash
   git log main..HEAD --oneline
   ```

   For each commit, verify:
   - Format: `{type}: {descripción}` (feat, fix, chore, refactor, docs, test)
   - Trailer present: `Spec-ID: {nombre-change}`

   If any commit is missing the trailer or has wrong format, list them and warn — do NOT block the PR, but report.

3. **Verify OpenSpec artifacts exist**

   Check that `openspec/changes/{nombre}/` exists and contains at minimum:
   - `proposal.md`
   - `tasks.md`

   If artifacts are missing, stop and instruct: "Ejecutá `/opsx:propose {nombre}` primero."

4. **Check for secrets before pushing**

   ```bash
   git diff main..HEAD --name-only
   ```

   Warn if any of these appear in the diff: `.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`.
   Ask for confirmation if found.

5. **Push branch**

   ```bash
   git push origin change/{nombre}
   ```

6. **Create PR**

   ```bash
   gh pr create \
     --title "[{nombre}] {descripción del change}" \
     --body "$(cat <<'EOF'
   ## Descripción
   {resumen extraído de proposal.md}

   ## Change
   Spec-ID: {nombre}

   ## Artefactos
   - `openspec/changes/{nombre}/proposal.md`
   - `openspec/changes/{nombre}/design.md`
   - `openspec/changes/{nombre}/tasks.md`

   ## Checklist
   - [ ] El Agente completó todas las tareas en `tasks.md`
   - [ ] No hay secrets en el diff
   - [ ] Commits con formato `type: descripción` + `Spec-ID:`
   - [ ] `/opsx:verify` pendiente de ejecutar

   ## Próximo paso
   Ejecutar `/opsx:verify {nombre}` en Claude para validar la implementación.
   EOF
   )" \
     --base main
   ```

7. **Confirm and instruct**

   Show PR URL and next steps:

   ```
   PR creada: #{número} — [{nombre}] {descripción}
   Branch: change/{nombre} → main

   Próximo paso: ejecutá /opsx:verify {nombre} aquí en Claude.
   Merge solo después de que verify no reporte desvíos.
   ```

**Guardrails**
- Nunca crear PR desde main o master directamente
- Si `.env` o credenciales aparecen en el diff → pedir confirmación explícita antes de continuar
- El `Spec-ID:` en el body de la PR es obligatorio — el GitHub Action lo valida
- No hacer merge antes de que `/opsx:verify` esté aprobado
