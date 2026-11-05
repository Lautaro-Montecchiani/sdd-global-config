## Why

Hoy un PR se mergea si `/opsx:verify` no reporta desvíos CRITICAL, pero el verify no controla tres preguntas que el usuario considera condición para integrar código: ¿qué pasa si llega un dato inesperado?, ¿hay algo que comprometa la seguridad? y ¿podría explicar este código a otra persona? Si alguna da "no", el código no se integra y se vuelve a revisar. La ficha del proyecto (`ficha-del-proyecto`, archivado el 05/11/2026) ya dice qué datos vienen de afuera, que es lo que necesita la primera pregunta. Issue [#29](https://github.com/Lautaro-Montecchiani/sdd-global-config/issues/29).

## What Changes

- **Puerta de integración en `/opsx:verify`:** una sección nueva del reporte con las tres preguntas y su resultado (sí, no o pendiente). Un "no" o un "pendiente" es CRITICAL: el change no queda listo para merge ni archive.
- **Dato inesperado:**
  - `/opsx:propose` agrega al menos un escenario "Dato inválido" (vacío, mal formado, duplicado o fuera de rango, según el caso) a cada requirement que toca un dato de origen externo declarado en `## Datos`, con su fila en el Test Plan;
  - el verify reporta "no" si falta el escenario o su verificación no pasa;
  - sin `## Datos`, la pregunta queda "no evaluada" con un WARNING que sugiere `/ficha`.
- **Seguridad:**
  - el propose escribe en la `## Security Layer`, para cada control, cómo se verifica;
  - el verify reporta "no" si un control no se cumple en el diff, si el diff agrega algo con forma de credencial o si falla un escaneo de seguridad del repo (cuando existe).
- **Explicabilidad:** el verify escribe en simple qué hace cada archivo cambiado y por qué, y pregunta al usuario si lo entiende. "No" bloquea hasta simplificar el código o la explicación. Si el verify corre sin interfaz, la pregunta queda "pendiente" y también bloquea, aunque el pedido traiga una respuesta escrita.
- **Reglas:** el `CLAUDE.md` global documenta la puerta y la condición de merge, y el checklist del PR (`branch-pr`) suma la puerta.
- Se instala todo en `~/.claude` y se sincroniza el espejo del vault.

## Non-goals

- Configurar escaneos de seguridad en CI (gitleaks, OSV-Scanner): queda para el change de seguridad de dependencias anotado en el vault. Acá solo se leen si existen.
- Bloquear técnicamente el merge en GitHub: la protección de rama no está disponible en repos privados del plan gratuito. La puerta es por convención, visible en el reporte y en el PR.
- Cambiar las reglas del Agente: la puerta la ejecuta Claude en el verify, y los escenarios de dato inválido llegan al Agente por el Test Plan, como cualquier otro.
- Sumar a las plantillas la regla de no cambiar la cuenta de `gh` (pendiente aparte en el vault).

## Capabilities

### New Capabilities
- `integration-gate`: puerta de integración del verify (dato inesperado, seguridad y explicabilidad), lo que el propose prepara para ella y la condición de merge.

### Modified Capabilities
_(ninguna: la puerta se agrega como capability propia; las reglas existentes del verify y la Security Layer no cambian de comportamiento)_

## Impact

- **Archivos globales modificados:**
  - `.claude/CLAUDE.md`: sección "Puerta de integración" y condición de merge en "Pull Requests".
  - `skills/openspec-propose/SKILL.md` y `.claude/commands/opsx/propose.md`: escenarios de dato inválido y cómo se verifica cada control de seguridad.
  - `skills/openspec-verify-change/SKILL.md` y `.claude/commands/opsx/verify.md`: la puerta, en los flujos con Test Plan y legacy.
  - `skills/branch-pr/SKILL.md`: línea de la puerta en el checklist del PR.
  - `README.md` y `docs/workflow.md`: una mención.
- **Instalación:** `~/.claude/CLAUDE.md`, `~/.claude/skills/`, `~/.claude/commands/opsx/` y el espejo `_global/reglas-globales.md` del vault. Las plantillas del Agente no cambian.
- **Proyectos:** desde la instalación, todo verify trae la puerta. Los changes ya propuestos sin escenarios de dato inválido darán "no" en la primera pregunta si tocan datos externos declarados; sin `## Datos`, solo un WARNING.
