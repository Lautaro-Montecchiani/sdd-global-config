---
name: issue-creation
description: Create a GitHub issue before proposing a change. Use when the user wants to start a new feature, fix, or change. No change should be proposed without an approved issue.
license: MIT
metadata:
  version: "1.0"
---

Create a GitHub issue as the mandatory entry point for a new change.

**Rule:** No `/opsx:propose` without an approved issue. The issue is the "why" — the spec is the "how".

---

**Input**: Description of what the user wants to build or fix.

**Steps**

1. **Gather context**

   If the user hasn't described the change clearly, use **AskUserQuestion** to ask:
   - What problem does this solve or what feature does this add?
   - Which part of the system does it affect?
   - Is it a `feat`, `fix`, `chore`, `refactor`, or `docs`?

2. **Derive change name**

   From the description, derive a kebab-case slug (e.g., "agregar validación al formulario" → `form-validation`).
   This slug will be used for the branch (`change/form-validation`) and Spec-ID.

3. **Create the issue**

   ```bash
   gh issue create \
     --title "[{type}] {descripción corta}" \
     --body "$(cat <<'EOF'
   ## Descripción
   {qué se quiere hacer y por qué}

   ## Criterios de aceptación
   - [ ] {criterio 1}
   - [ ] {criterio 2}

   ## Change name (para Spec-ID)
   {kebab-case-slug}

   ## Notas
   {contexto adicional, links, restricciones}
   EOF
   )" \
     --label "status:needs-review"
   ```

4. **Confirm and instruct**

   Show the issue URL and explain next steps:

   ```
   Issue creado: #{número} — {título}
   Estado: status:needs-review (pendiente de aprobación)

   Próximos pasos:
   1. Un maintainer debe agregar el label "status:approved"
   2. Una vez aprobado, ejecutá: /opsx:propose {kebab-case-slug}
   ```

   **STOP — no ejecutar `/opsx:propose` hasta que el issue tenga `status:approved`.**

**Guardrails**
- Nunca crear branch ni ejecutar propose sin issue aprobado
- El change name del issue debe coincidir con el que se use en propose y en el Spec-ID
- Si ya existe un issue aprobado para este change, saltearse la creación y proceder a propose
