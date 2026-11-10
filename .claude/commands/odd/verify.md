---
name: "ODD: Verify"
description: Verificar la implementación de un cambio ODD antes del merge
category: Workflow
---

<!-- Generado desde skills/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano: editar la skill y regenerar. -->

## Verify (`/odd:verify`)

**Objetivo:** Verificar la implementación del cambio ODD en la rama `odd/<nombre>` antes del merge.

### Controles de verificación

Evaluar el diff contra la rama principal (`main` o `master`) según la siguiente tabla:

| Control | Falla si | Severidad |
|---|---|---|
| Checklist | Alguna tarea sin `[x]` o con `[x]` sin evidencia en `## Evidencia` | CRITICAL |
| Criterios de aceptación | Algún CA sin la evidencia esperada o con evidencia que no lo demuestra | CRITICAL |
| Alcance | El diff contra la rama principal toca archivos fuera de "Archivos permitidos" (el documento `docs/odd/<nombre>.md`, `openspec/changes/odd-<nombre>/`, `openspec/changes/archive/` y la spec declarada siempre están permitidos) | CRITICAL |
| Validación de spec | Si existe `openspec/changes/odd-<nombre>/`: `openspec validate odd-<nombre> --strict` falla | CRITICAL |
| Delta de spec | El delta de spec contiene secciones distintas de `## MODIFIED Requirements` (ej. `ADDED`, `REMOVED` o `RENAMED`) o toca más de una capability | CRITICAL "escalar a SDD" por K1 |
| Test de spec | Si existe change de spec y el proyecto declara `comando` en `## Tests`: el diff no toca el test del requirement modificado | CRITICAL |
| Re-clasificación | Algún criterio SDD (K1 a K10) no anotado en `## Clasificación` se cumple sobre el diff real (ej. cambio en specs, dependencias nuevas o datos) | CRITICAL "escalar a SDD" |
| Tests | Si `## Tests` en `openspec/config.yaml` declara comando distinto de `ninguno`: falla algún test en la rama que no falla en la principal | CRITICAL |
| Puerta de integración | Seguridad o explicabilidad resultan en `no` o `pendiente` | CRITICAL |
| Visión | El documento pedía actualizar `docs/arquitectura/vision.md` (por saldar una deuda) y el diff no lo toca | WARNING |

### Reglas específicas

- **Puerta de integración en ODD:** La pregunta sobre datos externos queda en `no aplica (ODD)` porque K2 prohíbe que un ODD toque datos externos. Seguridad y explicabilidad deben evaluarse obligatoriamente con `sí`. La explicabilidad no evalúa el propio archivo `docs/odd/<nombre>.md`.
- **Alcance permitido:** El control de alcance permite siempre `openspec/changes/odd-<nombre>/`, `openspec/changes/archive/` y la spec de la capability declarada en el documento, como ya permite el documento `docs/odd/<nombre>.md`. K7 no cuenta archivos de `openspec/`.
- **Re-clasificación:** El control de re-clasificación no da CRITICAL por los criterios que `## Clasificación` anota como pasados por alto a pedido del usuario (solo pueden ser K4 a K8). Sí da CRITICAL por cualquier criterio que aparezca en el diff y no esté anotado. Si el diff activa K1 a K10 no anotados, se detiene la verificación con CRITICAL y se procede al escalado a SDD.

### Resultado aprobado

Si no hay observaciones CRITICAL:
1. Si existe `openspec/changes/odd-<nombre>/`, correr `openspec archive odd-<nombre> -y` en el branch. Commitear la spec actualizada y el change archivado:
   ```powershell
   git add openspec/specs/ openspec/changes/archive/
   git commit -m "docs: aplicar cambio de spec odd-<nombre>" -m "Spec-ID: odd-<nombre>"
   ```
2. Actualizar `estado: verificado` en el frontmatter de `docs/odd/<nombre>.md`.
3. Commitear en la rama:
   ```powershell
   git add docs/odd/<nombre>.md
   git commit -m "docs: verificar ODD <nombre>" -m "Spec-ID: odd-<nombre>"
   ```
4. En `$vault\projects\$p\context.md`, actualizar `## Estado actual` con "ODD `<nombre>` verificado, pendiente de merge".
5. Commitear y pushear el vault:
   ```powershell
   git -C $vault add "projects/$p/context.md"
   git -C $vault commit -m "chore: $p — verify odd $nombre"
   git -C $vault push
   ```
6. Indicar al usuario que el cambio está listo para mergear.

## Escalado

### Criterios de clasificación ODD / SDD

Todo pedido que implique modificar archivos del proyecto se clasifica según la siguiente tabla:

| ID | Criterio | ¿El usuario puede pasarlo a ODD? |
|---|---|---|
| K1 | Agrega o quita un comportamiento descrito en una spec vigente de `openspec/specs/`, crea una capability nueva, o modifica requirements de más de una capability. Modificar requirements existentes de una sola capability no cumple K1: va por ODD con cambio mínimo de spec | **no** |
| K2 | Cambia cómo se lee, valida, transforma, guarda, registra, expone o envía un dato declarado en `## Datos` como `(externo)` o `personal`, o agrega o quita campos de ese dato. Usarlo igual que antes no cumple K2 (por ejemplo, cambiar el texto fijo de un saludo que incluye el nombre) | **no** |
| K3 | Toca autenticación, permisos, manejo de secretos o un control de la Security Layer del tipo de proyecto | **no** |
| K4 | Agrega, quita o actualiza dependencias | sí |
| K5 | Cambia un contrato hacia afuera: endpoints, formato de archivos de entrada o salida, flags de CLI o esquema de base de datos | sí |
| K6 | Cambia el nivel de arquitectura o mueve código entre capas o módulos | sí |
| K7 | Toca más de 5 archivos, sin contar tests ni documentación | sí |
| K8 | El "qué" no está claro: hay alternativas de diseño que el usuario tiene que elegir | sí |
| K9 | El usuario pide SDD | — |
| K10 | Cumple un criterio de ADR del rol de arquitecto: elige o cambia una tecnología de `## Stack`, cambia el `nivel` de `## Arquitectura`, suma o cambia una integración externa, adopta un patrón transversal (manejo de errores, logging, autenticación, acceso a datos) o resuelve un compromiso entre dos atributos de calidad | **no** |

- Si se cumple **al menos uno** de los criterios: el pedido va por **SDD**.
- Si no se cumple ninguno: el pedido va por **ODD** (typos, textos, ajustes de estilos, refactors cubiertos por tests, corrección de bugs contra specs existentes donde la spec no cambia).
- Ante la duda sobre un criterio, se considera cumplido.
- Si se cumplen K1, K2, K3 o K10, no se permite pasar a ODD bajo ninguna circunstancia.

### Protocolo de escalado

Si durante la implementación por parte del Agente o durante `/odd:verify` se detecta que el cambio cumple un criterio SDD:
1. En el documento `docs/odd/<nombre>.md`, establecer `estado: escalado` y anotar en `## Progreso` el criterio detectado y el motivo.
2. Detener el flujo ODD. La rama `odd/<nombre>` no se mergea.
3. Actualizar `$vault\projects\$p\context.md` con `## Estado actual`: "ODD `<nombre>` escalado a SDD".
4. Ofrecer al usuario iniciar `/opsx:propose <nombre>` reutilizando los objetivos, alcance y avances documentados en el ODD.
