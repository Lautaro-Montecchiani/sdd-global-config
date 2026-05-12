# Contributing — SDD Híbrido (Claude + Copilot)

## Regla base

**Ningún cambio se implementa sin spec previa. Ninguna PR sin issue aprobado.**

El flujo completo es:

```
Issue aprobado → /opsx:propose → branch → Copilot implementa → PR → /opsx:verify → merge → /opsx:archive
```

---

## Paso 1 — Crear un issue

Antes de cualquier cambio, creá un issue con el skill:

```
/issue-creation
```

El issue queda con el label `status:needs-review`. Un maintainer debe agregar `status:approved` antes de que puedas continuar.

**No ejecutes `/opsx:propose` sin `status:approved` en el issue.**

---

## Paso 2 — Proponer el change

Con el issue aprobado:

```
/opsx:propose {nombre-del-change}
```

Claude crea los artefactos en `openspec/changes/{nombre}/` y el branch `change/{nombre}`.

---

## Paso 3 — Implementar

Abrís Copilot y ejecutás:

```
/openspec-apply-change {nombre-del-change}
```

Copilot implementa en el branch, commitea con el formato:

```
{type}: {descripción corta}

Spec-ID: {nombre-del-change}
```

**Types válidos:** `feat` `fix` `chore` `refactor` `docs` `test`

---

## Paso 4 — Abrir la PR

Con el branch listo:

```
/branch-pr {nombre-del-change}
```

El skill valida commits, verifica que no haya secrets, y crea la PR con el formato:

- **Título:** `[{nombre-del-change}] {descripción}`
- **Body:** debe incluir `Spec-ID: {nombre-del-change}`

El GitHub Action `pr-check.yml` valida automáticamente branch name, título y Spec-ID.

---

## Paso 5 — Verificar

```
/opsx:verify {nombre-del-change}
```

Claude lee `tasks.md`, el `git diff` y los specs. Merge **solo si verify no reporta desvíos**.

---

## Paso 6 — Merge y archivar

Merge a `main` con verify aprobado. Luego:

```
/opsx:archive {nombre-del-change}
```

Claude archiva el change y exporta la nota de resumen al vault de Obsidian.

---

## Convenciones de git

| Elemento | Convención |
|---|---|
| Branch | `change/{nombre-change}` |
| Commits | `{type}: {descripción}` + `Spec-ID: {nombre}` |
| PR título | `[{nombre-change}] {descripción}` |
| PR body | Debe incluir `Spec-ID: {nombre-change}` |
| Merge | Solo con `/opsx:verify` aprobado |

## Lo que nunca se hace

- Commitear `.env`, `*.key`, `*.pem` o credenciales
- Trabajar directo en `main`/`master`
- Abrir PR sin issue aprobado
- Hacer merge sin verify aprobado
- Pedirle a Copilot que planifique — solo ejecuta specs
