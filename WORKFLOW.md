# Workflow SDD Híbrido — Claude (Arquitecto) + Copilot (Constructor)

Guía de referencia para iniciar o incorporar cualquier proyecto al workflow SDD con OpenSpec.

---

## Roles

| Herramienta | Rol | Skills que usa |
|---|---|---|
| **Claude Code** | Arquitecto — planifica, especifica, verifica | `explore`, `propose`, `verify`, `archive` |
| **Copilot** | Constructor — implementa, commitea | `apply` |

---

## Setup inicial (una sola vez por máquina)

Estos cambios ya están aplicados. No repetir.

- `~/.claude/CLAUDE.md` — roles, flujo OpenSpec y matriz de seguridad por tipo de proyecto
- `~/.claude/skills/openspec-apply-change/SKILL.md` — skill de apply modificado: Claude anuncia handoff, no escribe código

---

## Onboarding: proyecto nuevo

```bash
# 1. Crear repo
mkdir mi-proyecto && cd mi-proyecto && git init

# 2. Inicializar OpenSpec con Claude y Copilot
openspec init --tools claude,copilot

# 3. Eliminar skill de apply a nivel proyecto (usa el global)
del .claude\skills\openspec-apply-change\SKILL.md

# 4. Completar openspec/config.yaml
```

En `openspec/config.yaml` declarar:

```yaml
schema: spec-driven

context: |
  project_type: frontend | backend-api | etl | fullstack
  Stack: [describir tecnologías]
  Dominio: [describir el negocio]
  Convenciones: [nombrar archivos, variables, etc.]

rules:
  proposal:
    - Incluir sección "Non-goals"
  tasks:
    - Referenciar ruta exacta del archivo a modificar
  design:
    - Incluir sección "## Security Layer"
```

---

## Onboarding: proyecto existente con OpenSpec

```bash
# 1. Eliminar skill de apply a nivel proyecto (usa el global)
del .claude\skills\openspec-apply-change\SKILL.md

# 2. Completar openspec/config.yaml con project_type + stack real
```

---

## Nota importante

**Nunca eliminar** `.agent\skills\openspec-apply-change\SKILL.md` — Copilot lo necesita para implementar.

---

## Flujo por change

```
Claude   /opsx:propose <nombre>          → crea proposal + design + specs + tasks
Copilot  /openspec-apply-change <nombre> → implementa, marca [x], commitea
Claude   /opsx:verify <nombre>           → audita implementación vs specs
Claude   /opsx:archive <nombre>          → sincroniza specs y archiva
```

---

## Capa de seguridad por tipo de proyecto

Al crear specs, Claude aplica automáticamente los controles según el `project_type` declarado en `openspec/config.yaml`:

| Tipo | Controles mínimos |
|---|---|
| `frontend` | JWT en httpOnly cookie, CSP, XSS prevention, CSRF |
| `backend-api` | JWT middleware, rate limiting (429), auth (401/403), jsonschema, CORS whitelist |
| `etl` / `scripts` | Secrets en `.env`, sin PII en logs, exit codes, validación de inputs externos |
| `fullstack` | Todo frontend + todo backend-api |

---

## Archivos gestionados por este repo

| Archivo | Propósito |
|---|---|
| `~/.claude/CLAUDE.md` | Reglas globales de Claude para todos los proyectos |
| `~/.claude/skills/openspec-apply-change/SKILL.md` | Comportamiento de apply en Claude (handoff a Copilot) |
