---
name: branch-pr
description: Open a Pull Request after the Agent finishes implementing (SDD or ODD). Validates branch name, commit format, Spec-ID, and that required artifacts exist before creating the PR.
license: MIT
metadata:
  version: "1.1"
---

Open a Pull Request following the conventions of the SDD / ODD hybrid workflow.

**When to use:** After `/opsx:apply` completes (SDD) or ODD implementation completes (el Agente terminó de implementar), before `/opsx:verify` or `/odd:verify`.

---

**Input**: Change name (kebab-case). If omitted, infer from current branch or ask.

**Steps**

1. **Detect change name and branch**

   ```bash
   git branch --show-current
   ```

   Expected format: `change/{nombre}` (para SDD) or `odd/{nombre}` (para ODD). If the branch doesn't match either pattern, warn and ask for confirmation before continuing.

2. **Validate commits on the branch**

   ```bash
   git log main..HEAD --oneline
   ```

   For each commit, verify:
   - Format: `{type}: {descripción}` (feat, fix, chore, refactor, docs, test)
   - Trailer present: `Spec-ID: {nombre-change}` (para SDD) or `Spec-ID: odd-{nombre}` (para ODD)

   If any commit is missing the trailer or has wrong format, list them and warn — do NOT block the PR, but report.

3. **Verify artifacts exist**

   - **If SDD (`change/{nombre}`):** Check that `openspec/changes/{nombre}/` exists and contains at minimum `proposal.md` and `tasks.md`. También se acepta si el change ya fue archivado en la rama bajo `openspec/changes/archive/*-{nombre}/`. Para una rama `change/{nombre}-archive`, busca `openspec/changes/archive/*-{nombre}/` y el Spec-ID esperado es `{nombre}`. If artifacts are missing, stop and instruct: "Ejecutá `/opsx:propose {nombre}` primero."
   - **If ODD (`odd/{nombre}`):** Check that `docs/odd/{nombre}.md` exists. If missing, stop and instruct: "Ejecutá `/odd {nombre}` primero."

4. **Check for secrets before pushing**

   ```bash
   git diff main..HEAD --name-only
   ```

   Warn if any of these appear in the diff: `.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`.
   Ask for confirmation if found.

5. **Push branch**

   ```bash
   git push origin {branch}
   ```

6. **Create PR**

   **Caso SDD (`change/{nombre}`):**
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
   - [ ] Puerta de integración en sí (dato inesperado, seguridad, explicabilidad)
   - [ ] `/opsx:verify` pendiente de ejecutar
   - [ ] Archive hecho en la rama (specs sincronizadas y SRS si corresponde)

   ## Próximo paso
   Ejecutar `/opsx:verify {nombre}` en Claude para validar la implementación.
   EOF
   )" \
     --base main
   ```

   **Caso ODD (`odd/{nombre}`):**
   ```bash
   gh pr create \
     --title "[{nombre}] {descripción del cambio}" \
     --body "$(cat <<'EOF'
   ## Descripción
   {resumen extraído de docs/odd/{nombre}.md}

   ## Change
   Spec-ID: odd-{nombre}

   ## Artefactos
   - `docs/odd/{nombre}.md`

   ## Checklist
   - [ ] El Agente completó todas las tareas en `docs/odd/{nombre}.md`
   - [ ] No hay secrets en el diff
   - [ ] Commits con formato `type: descripción` + `Spec-ID: odd-{nombre}`
   - [ ] Puerta de integración en sí (seguridad, explicabilidad; dato inesperado no aplica en ODD)
   - [ ] `/odd:verify` pendiente de ejecutar
   - [ ] Archive del change mínimo en el branch (si hay cambio de spec)

   ## Próximo paso
   Ejecutar `/odd:verify {nombre}` en Claude para validar la implementación.
   EOF
   )" \
     --base main
   ```

7. **Confirm and instruct**

   Show PR URL and next steps:

   **Para SDD:**
   ```
   PR creada: #{número} — [{nombre}] {descripción}
   Branch: change/{nombre} → main

   Próximo paso: ejecutá /opsx:verify {nombre} aquí en Claude.
   Merge solo después de que verify no reporte desvíos y del archive en la rama.
   ```

   **Para ODD:**
   ```
   PR creada: #{número} — [{nombre}] {descripción}
   Branch: odd/{nombre} → main

   Próximo paso: ejecutá /odd:verify {nombre} aquí en Claude.
   Merge solo después de que verify no reporte desvíos y, si hay cambio de spec, del archive en el branch.
   ```

**Guardrails**
- Nunca crear PR desde main o master directamente
- Si `.env` o credenciales aparecen en el diff → pedir confirmación explícita antes de continuar
- El `Spec-ID:` en el body de la PR es obligatorio — el GitHub Action lo valida
- No hacer merge antes de que `/opsx:verify` o `/odd:verify` esté aprobado
