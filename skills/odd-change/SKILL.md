---
name: odd-change
description: Flujo ODD (Organic Driven Development) para cambios chicos que no tocan specs, datos, seguridad ni contratos. Incluye /odd, /odd:verify y /odd:close.
---

# Flujo ODD (Organic Driven Development)

Protocolo liviano para cambios acotados en proyectos con workflow SDD. Cada cambio ODD se gestiona con un único documento en `docs/odd/<nombre>.md`, preservando la puerta de integración y el cierre en el vault de Obsidian.

## Inicio (`/odd`)

**Objetivo:** Iniciar un cambio ODD, validar la clasificación, redactar el documento único, crear la rama `odd/<nombre>` y anunciar el handoff al Agente.

### Pasos de ejecución

1. **Lectura de contexto y visión:**
   Resolver rutas del vault y del proyecto:
   ```powershell
   $vault = $env:OBSIDIAN_VAULT
   $p = Split-Path (Get-Location) -Leaf
   ```
   Leer `$vault\projects\$p\context.md` si existe.
   Leer `docs/arquitectura/vision.md` si existe en el proyecto. Si el pedido paga una deuda técnica listada en `## Hoja de ruta` (por ejemplo, un refactor sin cambio de comportamiento), la checklist debe incluir la tarea de quitarla de la visión y "Archivos permitidos" debe incluir `docs/arquitectura/vision.md`.
   Un cambio ODD nunca genera un ADR (criterio K10: cualquier decisión de arquitectura va por SDD).

2. **Clasificación del pedido:**
   Evaluar los criterios de clasificación K1 a K10 (ver sección Escalado).
   - Si se cumple algún criterio SDD: anunciar la clasificación con los criterios cumplidos y ofrecer `/opsx:propose <nombre>`.
   - Si no se cumple ningún criterio SDD: anunciar la clasificación ODD en una línea indicando los motivos.
   - Si el usuario solicita pasar un SDD a ODD: solo se permite si ninguno de los criterios cumplidos es K2, K3 o K10. En tal caso, dejar constancia explícita en la sección `## Clasificación` del documento.

3. **Redacción del documento ODD:**
   Crear la carpeta `docs/odd/` si no existe.
   Escribir el documento `docs/odd/<nombre>.md` con `estado: abierto`:

```markdown
---
tipo: odd
nombre: <nombre>
creado: AAAA-MM-DD
estado: abierto
branch: odd/<nombre>
---

## Objetivo
<una o dos líneas: qué tiene que ser cierto al terminar>

## Problema
<qué pasa hoy y por qué hay que cambiarlo>

## Alcance
- Incluye: <...>
- No incluye: <...>
- Archivos permitidos: <rutas o carpetas>

## Clasificación
ODD: <criterios evaluados y por qué ninguno se cumple>
<si hubo cambio de clasificación: qué criterio se pasó por alto y por pedido de quién>

## Checklist
- [ ] 1. <tarea con la ruta del archivo>

## Criterios de aceptación
- CA1: <estado verificable> — Evidencia esperada: <salida de test | diff | captura | salida de consola>

## Evidencia
<la completa el Agente: por tarea y por criterio>

## Progreso
<AAAA-MM-DD: qué se hizo — quién>

## Próximo paso
<un paso concreto>
```

4. **Aprobación del usuario:**
   Presentar el documento al usuario y solicitar confirmación mediante `AskUserQuestion` ("Aprobar y pasar al Agente" / "Cambiar algo").

5. **Creación de rama y commit inicial:**
   Una vez aprobado:
   ```powershell
   git checkout -b odd/<nombre>
   git add docs/odd/<nombre>.md
   git commit -m "docs: documento ODD <nombre>" -m "Spec-ID: odd-<nombre>"
   ```

6. **Actualización del vault:**
   En `$vault\projects\$p\context.md`, actualizar `## Estado actual` con "ODD activo: `<nombre>`".
   Commitear y pushear el vault:
   ```powershell
   git -C $vault add "projects/$p/context.md"
   git -C $vault commit -m "chore: $p — odd $nombre"
   git -C $vault push
   ```
   Si el push falla, continuar y advertir al usuario.

7. **Anuncio de handoff:**
   Anunciar al usuario:
   "Ejecutá en el Agente: implementá el ODD `docs/odd/<nombre>.md`."

## Verify (`/odd:verify`)

**Objetivo:** Verificar la implementación del cambio ODD en la rama `odd/<nombre>` antes del merge.

### Controles de verificación

Evaluar el diff contra la rama principal (`main` o `master`) según la siguiente tabla:

| Control | Falla si | Severidad |
|---|---|---|
| Checklist | Alguna tarea sin `[x]` o con `[x]` sin evidencia en `## Evidencia` | CRITICAL |
| Criterios de aceptación | Algún CA sin la evidencia esperada o con evidencia que no lo demuestra | CRITICAL |
| Alcance | El diff contra la rama principal toca archivos fuera de "Archivos permitidos" (el documento `docs/odd/<nombre>.md` siempre está permitido) | CRITICAL |
| Re-clasificación | Algún criterio SDD (K1 a K10) se cumple sobre el diff real (ej. cambio en specs, dependencias nuevas o datos) | CRITICAL "escalar a SDD" |
| Tests | Si `## Tests` en `openspec/config.yaml` declara comando distinto de `ninguno`: falla algún test en la rama que no falla en la principal | CRITICAL |
| Puerta de integración | Seguridad o explicabilidad resultan en `no` o `pendiente` | CRITICAL |
| Visión | El documento pedía actualizar `docs/arquitectura/vision.md` (por saldar una deuda) y el diff no lo toca | WARNING |

### Reglas específicas

- **Puerta de integración en ODD:** La pregunta sobre datos externos queda en `no aplica (ODD)` porque K2 prohíbe que un ODD toque datos externos. Seguridad y explicabilidad deben evaluarse obligatoriamente con `sí`. La explicabilidad no evalúa el propio archivo `docs/odd/<nombre>.md`.
- **Re-clasificación:** Si el diff real activa algún criterio K1 a K10, se detiene la verificación con CRITICAL y se procede al escalado a SDD.

### Resultado aprobado

Si no hay observaciones CRITICAL:
1. Actualizar `estado: verificado` en el frontmatter de `docs/odd/<nombre>.md`.
2. Commitear en la rama:
   ```powershell
   git add docs/odd/<nombre>.md
   git commit -m "docs: verificar ODD <nombre>" -m "Spec-ID: odd-<nombre>"
   ```
3. En `$vault\projects\$p\context.md`, actualizar `## Estado actual` con "ODD `<nombre>` verificado, pendiente de merge".
4. Commitear y pushear el vault:
   ```powershell
   git -C $vault add "projects/$p/context.md"
   git -C $vault commit -m "chore: $p — verify odd $nombre"
   git -C $vault push
   ```
5. Indicar al usuario que el cambio está listo para mergear.

## Cierre (`/odd:close`)

**Objetivo:** Registrar el cierre del cambio ODD en el vault de Obsidian luego de que la rama `odd/<nombre>` fue mergeada en la rama principal.

### Pasos de cierre

1. **Control de merge:**
   Comprobar que la rama `odd/<nombre>` esté efectivamente mergeada en la rama principal (`git branch -r --merged` o `gh pr view`). Si la rama no está mergeada, detener la ejecución y avisar al usuario.

2. **Redacción de nota de archivo en el vault:**
   Crear la nota `$vault\projects\$p\archive\AAAA-MM-DD-odd-<nombre>.md` con el siguiente formato:

```markdown
---
tipo: odd
change: <nombre>
proyecto: <proyecto>
fecha: AAAA-MM-DD
status: cerrado
pr: <url del PR o "sin PR">
---

## Objetivo
<copiado del documento>

## Qué cambió
- <archivo>: <una línea>

## Evidencia
- CA1: <resumen en una línea>

## Clasificación
<copiada del documento, incluido cualquier criterio pasado por alto>

## Documento completo
`docs/odd/<nombre>.md` en el repo del proyecto
```
   *Nota de seguridad:* La nota no debe contener código completo ni credenciales o valores sensibles.

3. **Actualización del índice del vault:**
   Agregar el enlace a la nota en `$vault\projects\$p\_index.md`.

4. **Actualización de arquitectura en el vault:**
   Si el diff del ODD modificó `docs/arquitectura/vision.md`, reescribir `$vault\projects\$p\arquitectura.md` con el mismo formato y las mismas fuentes que el archive SDD: frontmatter (`project`, `updated`) y las secciones `## Nivel` (`nivel` de `## Arquitectura` de `openspec/config.yaml`, o "sin evaluar"), `## Atributos de calidad` (ítems de `## Calidad`, o "sin declarar"), `## Decisiones vigentes` (número y título de los ADRs con `Estado: aceptada` en `docs/adr/`, o "ninguna") y `## Deuda prioritaria` (hasta 3 ítems de `## Hoja de ruta` de `docs/arquitectura/vision.md`, primero los `alta`, o "ninguna"), seguidas de la línea `Documento completo: docs/arquitectura/vision.md en el repo`. Sin código, credenciales ni datos personales. Si no se modificó la visión, conservar `arquitectura.md` sin cambios.

5. **Actualización de `context.md`:**
   En `$vault\projects\$p\context.md`:
   - `## Estado actual`: "sin change activo" (o el change que continúe activo).
   - `## Último change`: "ODD `<nombre>` (AAAA-MM-DD)".
   - `## Decisiones recientes`: registrar entrada únicamente si el ODD documentó una decisión relevante.

6. **Commit y push del vault:**
   Commitear y pushear los cambios en el vault:
   ```powershell
   git -C $vault add .
   git -C $vault commit -m "chore: $p — odd-close $nombre"
   git -C $vault push
   ```
   Si el push falla, continuar e informar al usuario.

7. **Sin cambios en el repositorio del proyecto:**
   No realizar commits ni push en el repositorio del proyecto. El documento en el proyecto permanece con `estado: verificado`. El estado cerrado reside en el vault.
   No se ofrece generación de SRS (un cambio ODD no modifica especificaciones).

## Escalado

### Criterios de clasificación ODD / SDD

Todo pedido que implique modificar archivos del proyecto se clasifica según la siguiente tabla:

| ID | Criterio | ¿El usuario puede pasarlo a ODD? |
|---|---|---|
| K1 | Agrega, cambia o quita un comportamiento descrito en una spec vigente de `openspec/specs/`, o crea una capability nueva | sí |
| K2 | Toca un dato declarado en `## Datos` como `(externo)` o `personal` | **no** |
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
- Si se cumplen K2, K3 o K10, no se permite pasar a ODD bajo ninguna circunstancia.

### Protocolo de escalado

Si durante la implementación por parte del Agente o durante `/odd:verify` se detecta que el cambio cumple un criterio SDD:
1. En el documento `docs/odd/<nombre>.md`, establecer `estado: escalado` y anotar en `## Progreso` el criterio detectado y el motivo.
2. Detener el flujo ODD. La rama `odd/<nombre>` no se mergea.
3. Actualizar `$vault\projects\$p\context.md` con `## Estado actual`: "ODD `<nombre>` escalado a SDD".
4. Ofrecer al usuario iniciar `/opsx:propose <nombre>` reutilizando los objetivos, alcance y avances documentados en el ODD.
