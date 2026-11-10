---
name: "ODD: Start"
description: Iniciar un cambio ODD, redactar el documento único y pasar el handoff al Agente
category: Workflow
---

## Inicio (/odd)

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
   - Si el pedido modifica requirements existentes de una sola capability (texto, valores, escenarios) y no cumple ningún otro criterio: no cumple K1 y va por ODD con cambio mínimo de spec. Agregar o quitar comportamiento, crear una capability nueva o tocar más de una es K1 y va por SDD sin excepción.
   - Si el usuario solicita pasar un SDD a ODD: solo se permite si ninguno de los criterios cumplidos es K1, K2, K3 o K10. En tal caso, dejar constancia explícita en la sección `## Clasificación` del documento.

3. **Redacción del documento ODD y change mínimo:**
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
- Cambio de spec: <capability> — <requirement> (o "ninguno")
- Archivos permitidos: <rutas o carpetas>

## Clasificación
ODD: <criterios evaluados y por qué ninguno se cumple>
<si hubo cambio de clasificación: qué criterio se pasó por alto y por pedido de quién>

## Checklist
- [ ] 1. <tarea con la ruta del archivo; si modifica spec, tarea de ajustar el test del requirement>

## Criterios de aceptación
- CA1: <estado verificable> — Evidencia esperada: <salida de test en rojo y en verde | diff | captura | salida de consola>

## Evidencia
<la completa el Agente: por tarea y por criterio>

## Progreso
<AAAA-MM-DD: qué se hizo — quién>

## Próximo paso
<un paso concreto>
```

   Si el pedido modifica requirements de una sola capability, además del documento redactar un change mínimo `openspec/changes/odd-<nombre>/` con `proposal.md` corto (`## Why`, `## What Changes`, `## Impact`, que remiten al documento ODD) y `specs/<capability>/spec.md` con solo `## MODIFIED Requirements` (cada requirement completo, como lo exige OpenSpec). Correr `openspec validate odd-<nombre> --strict` antes de pedir aprobación. Sin `design.md`, `tasks.md` ni Test Plan.

4. **Aprobación del usuario:**
   Presentar el documento (y el change mínimo de spec si existe) al usuario y solicitar confirmación mediante `AskUserQuestion` ("Aprobar y pasar al Agente" / "Cambiar algo").

5. **Creación de rama y commit inicial:**
   Una vez aprobado:
   ```powershell
   git checkout -b odd/<nombre>
   git add docs/odd/<nombre>.md
   # Si existe change mínimo de spec:
   git add openspec/changes/odd-<nombre>/
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

## Escalado

### Criterios de clasificación ODD / SDD

Todo pedido que implique modificar archivos del proyecto se clasifica según la siguiente tabla:

| ID | Criterio | ¿El usuario puede pasarlo a ODD? |
|---|---|---|
| K1 | Agrega o quita un comportamiento descrito en una spec vigente de `openspec/specs/`, crea una capability nueva, o modifica requirements de más de una capability. Modificar requirements existentes de una sola capability no cumple K1: va por ODD con cambio mínimo de spec | **no** |
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
- Si se cumplen K1, K2, K3 o K10, no se permite pasar a ODD bajo ninguna circunstancia.

### Protocolo de escalado

Si durante la implementación por parte del Agente o durante `/odd:verify` se detecta que el cambio cumple un criterio SDD:
1. En el documento `docs/odd/<nombre>.md`, establecer `estado: escalado` y anotar en `## Progreso` el criterio detectado y el motivo.
2. Detener el flujo ODD. La rama `odd/<nombre>` no se mergea.
3. Actualizar `$vault\projects\$p\context.md` con `## Estado actual`: "ODD `<nombre>` escalado a SDD".
4. Ofrecer al usuario iniciar `/opsx:propose <nombre>` reutilizando los objetivos, alcance y avances documentados en el ODD.