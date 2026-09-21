# Spec: Security Layer Matrix

## Requirements

### Requirement: Matriz de seguridad en CLAUDE.md global

El CLAUDE.md global DEBE contener una sección `## Capa de Seguridad por Tipo de Proyecto` con los controles mínimos para cada tipo:

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

### Requirement: Declaración de project_type por proyecto

Cada proyecto que usa OpenSpec DEBE declarar `project_type` en el bloque `context:` de `openspec/config.yaml`. Claude lee este campo al crear cualquier artefacto.

### Requirement: Security Layer en cada design.md

Todo `design.md` de un change DEBE incluir una sección `## Security Layer` que liste qué controles del tipo de proyecto aplican a ese cambio específico y cómo se implementan.

### Requirement: Rol de Claude en apply

Cuando Claude ejecuta `/opsx:apply`, NO escribe código. En cambio:
1. Lee los artefactos del change (proposal, specs, design, tasks)
2. Anuncia: "Este change está listo para implementación. Ejecutá en el Agente: `/openspec-apply-change {nombre}`"
3. Lista las tareas pendientes como resumen para el Agente
4. Recuerda: "Cuando el Agente termine, ejecutá `/opsx:verify {nombre}` aquí"
