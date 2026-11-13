---
description: Implementa las tareas de un documento ODD (Organic Driven Development).
agent: 'agent'
---

<!-- Generado desde templates/fuente/ de sdd-global-config con scripts/generar-plantillas.ps1. No editar a mano. -->

# Implementar un cambio ODD

Implementá las tareas de un documento ODD (`docs/odd/<nombre>.md`).

## 1. Entrada

- Nombre del ODD: si no se especifica como argumento, listá los archivos `docs/odd/*.md` que tengan `estado: abierto` en su frontmatter y preguntale al usuario cuál implementar.

## 2. Control de arranque

Antes de modificar cualquier archivo, verificá:
1. Que exista el archivo `docs/odd/<nombre>.md`. Si no existe, frená y avisá.
2. Que la rama actual sea `odd/<nombre>`. Si no estás en esa rama, frená y avisá.
3. Que el frontmatter tenga `estado: abierto`. Si no está en `estado: abierto`, frená y avisá.

Si alguno de estos controles falla, frená inmediatamente y explicá qué falta.

## 3. Implementación

Seguí las pautas de handoff ODD:

- Leé `docs/odd/<nombre>.md` y trabajá solo en el branch `odd/<nombre>` y en los archivos permitidos de "Alcance".
- No edites `openspec/` en un ODD: el cambio de spec, si lo hay, lo escribe y lo aplica Claude.
- Implementá tarea por tarea con las reglas de ejecución que ya tenés (evidencia antes de `[x]`, test primero = falla primero, no debilitar tests).
- Pegá la evidencia en `## Evidencia` del documento ODD: no escribas la nota `apply\` del vault, que es del flujo SDD.
- Si al implementar se cumple un criterio SDD (por ejemplo, necesitás una dependencia nueva o cambiar una spec vigente), **frená**, anotalo en `## Progreso` y avisá "escalar a SDD".
- Si necesitás tocar un archivo que no está en "Archivos permitidos" y no se cumple ningún criterio SDD (por ejemplo, un test o un dato de prueba), **frená**, anotalo en `## Progreso` y avisá "falta en el alcance": Claude amplía el documento y seguís.
- Commiteá con `{type}: {desc}` y el trailer `Spec-ID: odd-<nombre>`, y dejá `estado: listo-para-verify`.

Implementá tarea por tarea siguiendo las 8 reglas de ejecución (evidencia antes de `[x]`, test primero = falla primero, no debilitar tests, no inventar, commits separados, sin comentarios de razonamiento, resumen final con evidencia, respetar la arquitectura).

### Frenos durante la implementación

- Si se cumple un criterio SDD de K1 a K10 (por ejemplo, una dependencia nueva o cambiar una spec vigente), **frená**, anotalo en `## Progreso` y avisá "escalar a SDD".
- Si necesitás tocar un archivo que no está en "Archivos permitidos" y no se cumple ningún criterio SDD (por ejemplo, un test o un dato de prueba), **frená**, anotalo en `## Progreso` y avisá "falta en el alcance": Claude amplía el documento y seguís.
- En ambos casos, anotalo en `## Progreso` y NO commitees a medias.

## 4. Cierre obligatorio

Al completar todas las tareas del checklist:
1. Verificá que cada tarea esté marcada `[x]` con su evidencia correspondiente.
2. Pegá la evidencia por criterio de aceptación en la sección `## Evidencia`.
3. Hacé el commit con `{type}: {desc}` (usando solo tipos permitidos: `feat`, `fix`, `chore`, `refactor`, `docs`, `test`) y el trailer `Spec-ID: odd-<nombre>`.
4. Dejá `estado: listo-para-verify` en el frontmatter del documento y anotá la línea correspondiente en `## Progreso`.

## 5. Resumen final

Presentá un resumen final que incluya:
- Tareas marcadas con su evidencia.
- Commits realizados con su hash y mensaje.
- El próximo paso: "Claude corre `/odd:verify <nombre>`".
