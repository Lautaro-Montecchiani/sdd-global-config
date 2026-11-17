---
name: retro
description: Guía la retro global semanal con sus fases (Preparar, Review, Start / Stop / Continue, Analizar, Decidir acciones y Cerrar) y crea un issue por acción acordada.
license: MIT
metadata:
  version: "1.0"
---

Guía la retro global semanal (Preparar, Review, Start / Stop / Continue, Analizar, Decidir acciones y Cerrar) y crea un issue por acción acordada.

## Restricciones

- Esta skill no crea changes, ramas ni commits en el repo, no escribe código; escribe solo la nota de `retros/` del vault y los issues.
- Mira el proceso y no evalúa personas; no escribe nombres de personas, rutas absolutas ni datos personales en la nota ni en los issues.
- Si no está `OBSIDIAN_VAULT`, avisa "Sin vault no hay retro: definí OBSIDIAN_VAULT" y termina.
- Si falta `SDD_CONFIG_REPO`, pide la ruta y no la adivina.
- Duración objetivo: 15 minutos; Claude lleva el tiempo con las fases cortas y el usuario facilita como Scrum Master.
- No cambia la cuenta activa de `gh` (`gh auth switch`) por cuenta propia.
- No agrega `status:approved` al crear issues (la aprobación es del usuario).

---

## Flujo de trabajo

### Fase 0: Inicialización técnica

1. Validar entorno:
   - Si no está definida la variable de entorno `OBSIDIAN_VAULT`, emitir el mensaje exacto: "Sin vault no hay retro: definí OBSIDIAN_VAULT" y finalizar.
   - Si falta `SDD_CONFIG_REPO`, pedir la ruta al usuario sin adivinarla.
2. Sincronizar vault antes de empezar:
   - Ejecutar `git -C $vault pull --rebase`. Si falla por conflicto, avisar al usuario y no forzar.
3. Consultar período y notas archivadas:
   - Ejecutar:
     ```powershell
     pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\retro.ps1" -Periodo
     ```
   - Guardar las fechas desde, hasta, semanas, retro anterior y lo terminado en el período.

---

### Fase 1: Preparar

1. Leer la directiva primaria de Kerth en una frase:
   > "Más allá de lo que descubramos, entendemos y creemos que todos hicieron el mejor trabajo que pudieron con lo que sabían, sus habilidades, los recursos disponibles y la situación."
2. Si hay retro anterior:
   - Leer su sección `## Acciones`.
   - Consultar cada issue con:
     ```bash
     gh issue view <n> --repo <repo> --json state,title
     ```
   - Mostrar acciones abiertas y cerradas.
   - Una acción cuyo issue `gh` no encuentra se marca `no encontrado`.
   - Una acción sin issue creado previamente se marca como `sin issue` (`issue: pendiente`).
   - Se continúa con la retro sin detenerse.

---

### Fase 2: Review

1. Consultar métricas del período:
   - Ejecutar:
     ```powershell
     pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\metricas.ps1" -Semanas <semanas>
     ```
   - Leer `metricas.md` del vault. Si `metricas.ps1` avisa (sin `gh`, sin tablero o sin datos), seguir sin métricas y avisarlo en la salida.
2. Leer las notas de archive listadas por `retro.ps1 -Periodo` (solo su sección `## Qué se hizo` o el resumen equivalente).
3. Presentar resumen por proyecto:
   - Lo terminado: changes y ODD completados en el período.
   - Issues cerrados.
   - Métricas de flujo: lead time, cycle time y throughput, y el trabajo en curso (WIP actual).
4. Preguntar con `AskUserQuestion` la opinión de quien usa el sistema:
   - Pregunta: "¿Qué te pareció lo entregado? ¿Falta algo?" (opciones con recomendada, incluyendo "Nada que agregar").
   - Lo que el usuario pida o señale es candidato a acción.

---

### Fase 3: Start / Stop / Continue

1. Claude propone candidatos con evidencia objetiva del período:
   - Verifies con `CRITICAL` o `WARNING`.
   - Tareas reabiertas o correcciones posteriores.
   - ODD escalados a SDD.
   - WIP excedido que haya sido aceptado.
   - Changes con número elevado de tareas.
   - Errores repetidos del Agente documentados en las notas de `apply\`.
2. Presentar los candidatos con `AskUserQuestion` en tres preguntas con `multiSelect`:
   - **Start**: Qué cosas nuevas deberíamos empezar a hacer.
   - **Stop**: Qué prácticas o comportamientos deberíamos dejar de hacer.
   - **Continue**: Qué cosas funcionaron bien y deberíamos mantener.
3. El usuario selecciona los ítems relevantes y puede sumar los suyos mediante la opción libre.

---

### Fase 4: Analizar

1. El usuario elige con `AskUserQuestion` hasta 3 ítems priorizados para trabajar.
2. Para cada ítem seleccionado, formular una pregunta corta de indagación ("¿por qué pasa?") hasta identificar una causa raíz sobre la cual se pueda accionar y cambiar.

---

### Fase 5: Decidir acciones

1. Para cada ítem analizado, Claude redacta una acción SMART:
   - Específica: qué se hace exactamente.
   - Medible: cómo se verifica y mide que funcionó.
   - Asignable: quién la ejecuta (entre usuario, Claude y Agente).
   - Temporal: fecha límite (por defecto la fecha de la próxima retro).
2. El usuario confirma o corrige cada redacción.
3. Regla de foco: Máximo 3 acciones.
4. Por cada acción aprobada:
   - Preguntar con `AskUserQuestion` el repositorio destino (por defecto `sdd-global-config`), la prioridad (`alta`, `media`, `baja`) y el tipo (`feature`, `deuda`, `bug`).
   - Crear el issue en GitHub con:
     ```bash
     gh issue create --repo <dueño/repo> --title "[retro] <acción corta>" --label "prioridad:<p>" --label "tipo:<t>" --body "<cuerpo>"
     ```
     El cuerpo debe contener:
     - `## Descripción`: la acción SMART completa.
     - `## Criterios de aceptación`:
       - `- [ ] <medida acordada>`
       - `- [ ] Revisada en la retro siguiente`
     - `## Notas`: `Origen: retro AAAA-MM-DD` y el ítem de Start / Stop / Continue que la originó.
   - Aclaración importante: no agrega `status:approved` (la aprobación corresponde exclusivamente al usuario).
   - Vincular al tablero Scrumban:
     ```powershell
     pwsh -NoProfile -File "$env:SDD_CONFIG_REPO\scripts\tablero.ps1" -Columna backlog -Issue <url>
     ```
     Un aviso o fallo menor del script del tablero no detiene el flujo.
   - Si `gh` no está disponible, no hay conexión de red o la cuenta no posee permisos en el repositorio: registrar la acción en la nota con `issue: pendiente` y notificar en la salida. No cambiar de cuenta de `gh` por cuenta propia.

---

### Fase 6: Cerrar

1. Consultar con `AskUserQuestion`:
   - El ROTI (retorno del tiempo invertido, escala de 1 a 5).
   - Una cosa concreta a mejorar para la próxima retro.
2. Escribir la nota de la retro en el vault:
   - Archivo destino: `$vault/retros/AAAA-MM-DD.md` (fecha actual), codificado en UTF-8 sin BOM.
   - Si el archivo ya existe (segunda retro en el mismo día), no sobrescribir: agregar al final una sección `## Retro de las HH:MM` con las mismas subsecciones un nivel más abajo (`###`).
   - Estructura de la nota:
     ```markdown
     ---
     tipo: retro
     fecha: AAAA-MM-DD
     desde: AAAA-MM-DD
     hasta: AAAA-MM-DD
     roti: <1-5>
     ---

     ## Acciones anteriores

     (Lista de acciones de la retro anterior con estado: cerrado, abierto, no encontrado o sin issue, o "Primera retro")

     ## Review

     ### Terminado
     (Resumen por proyecto)

     ### Métricas
     (Lead time, cycle time, throughput y trabajo en curso de metricas.md, o "Sin métricas: <motivo>")

     ### Opinión de quien usa el sistema
     (Comentarios y feedback registrado)

     ## Start / Stop / Continue

     ### Start
     ### Stop
     ### Continue

     ## Análisis

     (Ítems trabajados y causas raíz identificadas)

     ## Acciones

     - [ ] <acción SMART> — issue: <repo>#<n> (o pendiente) — vence: AAAA-MM-DD

     ## Cierre

     - ROTI: <valor>/5
     - Mejora para la próxima retro: <mejora>
     ```
3. Sincronizar el repositorio del vault:
   - Ejecutar:
     ```bash
     git -C $vault add -A
     git -C $vault commit -m "chore: retro AAAA-MM-DD"
     git -C $vault push
     ```
   - Si el push falla por problemas de red o permisos, advertir en la salida sin detener el flujo.

---

## Salida de la retro

Informar al usuario:
- Ruta relativa de la nota en el vault (`retros/AAAA-MM-DD.md`).
- Issues creados con sus URLs correspondientes.
- Acciones pendientes de la retro anterior.
- Advertencias si el push falló o si alguna acción quedó registrada con `issue: pendiente`.
