# security-layer-matrix Specification

## Purpose
Define los controles de seguridad mínimos por tipo de proyecto: la matriz en el `CLAUDE.md` global, la declaración de `project_type` en cada proyecto, la sección `## Security Layer` obligatoria en cada `design.md` y el rol de Claude en el apply.

## Requirements

### Requirement: Matriz de seguridad en CLAUDE.md global

El CLAUDE.md global SHALL contener una sección `## Capa de Seguridad por Tipo de Proyecto` con los controles mínimos para cada tipo:

**`frontend`**
- JWT: almacenar en httpOnly cookie, nunca en localStorage; implementar refresh token y validación de expiración
- CSP: Content-Security-Policy header definido
- XSS: sanitizar todo input antes de renderizar en el DOM
- CSRF: token anti-CSRF en formularios con estado

**`backend-api`**
- JWT: middleware de validación en cada endpoint protegido
- Rate limiting: respuesta 429 con Retry-After header
- Auth/Authz: 401 para no autenticados, 403 para no autorizados
- Validación de inputs: jsonschema o equivalente en todos los endpoints
- CORS: lista blanca de dominios, nunca `*` en producción

**`etl` / `scripts`**
- Secrets: nunca hardcodeados — `.env` en `.gitignore` o variables del scheduler
- Logging: no loguear PII, documentos ni credenciales
- Error handling: capturar todas las excepciones, exit code != 0 en fallos
- Inputs externos: validar formato antes de procesar

**`fullstack`**
- Aplicar todos los controles de `frontend` + `backend-api`
- Definir boundary explícito frontend/backend en el design.md del change

#### Scenario: Matriz presente en el CLAUDE.md global
- **WHEN** se lee el CLAUDE.md global
- **THEN** contiene la sección `## Capa de Seguridad por Tipo de Proyecto`
- **AND** define controles mínimos para `frontend`, `backend-api`, `etl` / `scripts` y `fullstack`

### Requirement: Declaración de project_type por proyecto

Cada proyecto que usa OpenSpec SHALL declarar `project_type` en el bloque `context:` de `openspec/config.yaml`. Claude lee este campo al crear cualquier artefacto.

#### Scenario: Claude lee el tipo de proyecto antes de crear artefactos
- **WHEN** Claude va a crear un artefacto (`proposal.md`, `design.md`, `specs/*.md`) en un proyecto con OpenSpec
- **THEN** lee `project_type` del bloque `context:` de `openspec/config.yaml`
- **AND** aplica los controles mínimos de ese tipo

### Requirement: Security Layer en cada design.md

Todo `design.md` de un change SHALL incluir una sección `## Security Layer` que liste qué controles del tipo de proyecto aplican a ese cambio específico y cómo se implementan.

#### Scenario: design.md incluye la sección Security Layer
- **WHEN** se crea un nuevo change y se genera su `design.md`
- **THEN** el `design.md` contiene una sección `## Security Layer`
- **AND** la sección lista los controles del tipo de proyecto que aplican al change y cómo se implementan

### Requirement: Rol de Claude en apply

Cuando Claude ejecuta `/opsx:apply`, Claude SHALL NOT escribir código; en cambio, SHALL:
1. Leer los artefactos del change (proposal, specs, design, tasks)
2. Anunciar: "Este change está listo para implementación. Ejecutá en el Agente: `/openspec-apply-change {nombre}` (Antigravity) o `/opsx-apply {nombre}` (Cursor)"
3. Listar las tareas pendientes como resumen para el Agente
4. Recordar: "Cuando el Agente termine, ejecutá `/opsx:verify {nombre}` aquí"

#### Scenario: apply anuncia el handoff en lugar de implementar
- **WHEN** Claude ejecuta `/opsx:apply` sobre un change con tareas pendientes
- **THEN** anuncia el handoff al Agente y lista las tareas pendientes
- **AND** no realiza cambios de código

#### Scenario: El handoff nombra el comando de cada agente
- **WHEN** Claude anuncia el handoff al terminar `/opsx:propose` o `/opsx:apply`
- **THEN** el anuncio incluye `/openspec-apply-change {nombre}` para Antigravity y `/opsx-apply {nombre}` para Cursor

### Requirement: Controles para datos personales
La Capa de Seguridad del `CLAUDE.md` global SHALL incluir controles mínimos para datos personales, válidos para cualquier `project_type`: no loguearlos, pedir solo los campos necesarios, enmascararlos en salidas no productivas, no usar datos reales en tests ni fixtures y no exponerlos en URLs. Si `## Datos` declara un dato `personal` y el change lo toca, la `## Security Layer` del `design.md` SHALL incluir estos controles.

#### Scenario: Change que toca datos personales
- **WHEN** `## Datos` declara `- leads (nombre, teléfono, email): formulario web (externo) | personal` y el change agrega un campo al formulario de leads
- **THEN** la `## Security Layer` del design incluye los controles para datos personales

#### Scenario: Change que no toca datos personales
- **WHEN** el change solo modifica estilos de la web
- **THEN** la `## Security Layer` no está obligada a incluir los controles para datos personales

#### Scenario: Controles en el CLAUDE.md global
- **WHEN** se lee la Capa de Seguridad del `CLAUDE.md` global
- **THEN** hay una subsección de datos personales con los cinco controles del requirement
