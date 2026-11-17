## ADDED Requirements

### Requirement: Historial del tablero para las métricas
`scripts/metricas.ps1` SHALL leer la configuración del tablero igual que `scripts/tablero.ps1` (`tablero.md` del vault o `-Config`) y SHALL obtener, para cada tarjeta del Project configurado, el repo, el número, el título, la fecha de creación, la fecha de cierre y los eventos de cambio de columna con su fecha. SHALL considerar solo los eventos del Project configurado (mismo dueño y número). Con `-Entrada <archivo.json>` SHALL leer los datos de ese archivo en lugar de `gh`.

#### Scenario: Eventos de otros Projects
- **WHEN** un issue tiene eventos de cambio de columna en el Project configurado y en otro Project
- **THEN** solo se usan los del Project configurado

#### Scenario: Más de una página de tarjetas
- **WHEN** el Project tiene más tarjetas que las que devuelve una página
- **THEN** se leen todas las páginas antes de calcular

#### Scenario: Dato inválido: evento o fecha incompletos
- **WHEN** una tarjeta no tiene número o fecha de creación, o un evento no tiene columna o fecha, o la fecha de cierre es anterior a la de creación
- **THEN** la tarjeta o el evento se descarta y la consola informa cuántos se descartaron

### Requirement: Cálculo de las métricas de flujo
Para el período de `-Semanas <n>` semanas hasta `-Ahora` (por defecto 4 semanas hasta el momento de la corrida), `scripts/metricas.ps1` SHALL calcular sobre los issues cerrados en el período: el lead time (creación a cierre), el cycle time (primera entrada a Diseño o Construcción a cierre), el throughput (cerrados por semana) y el tiempo promedio en cada columna. SHALL listar las tarjetas abiertas en Diseño, Construcción y Revisión con los días que llevan en su columna actual. Los tiempos SHALL expresarse en días con un decimal; los promedios y las medianas SHALL calcularse solo con los valores disponibles.

#### Scenario: Lead time y cycle time
- **WHEN** un issue se creó el día 1, entró a Diseño el día 3 y se cerró el día 8
- **THEN** su lead time es 7,0 días y su cycle time es 5,0 días

#### Scenario: Issue cerrado sin pasar por el flujo
- **WHEN** un issue se cerró sin entrar nunca a Diseño ni a Construcción
- **THEN** cuenta para el lead time y el throughput, no para el cycle time, y el archivo dice cuántos quedaron sin cycle time

#### Scenario: Throughput por semana
- **WHEN** en un período de 2 semanas se cerraron 3 issues en la primera y ninguno en la segunda
- **THEN** el throughput muestra las dos semanas, con 3 y 0

#### Scenario: Trabajo en curso
- **WHEN** una tarjeta abierta está en Construcción desde hace 4 días
- **THEN** aparece en el trabajo en curso con 4,0 días en Construcción

### Requirement: Archivo de métricas en el vault
`scripts/metricas.ps1` SHALL escribir `metricas.md` en la raíz del vault (o en `-Salida <ruta>`) en UTF-8 sin BOM, con una primera línea de comentario que dice que es generado y no se edita a mano, la fecha de la corrida y el período, y las secciones de resumen, throughput, tiempo por columna, trabajo en curso e issues cerrados. NO SHALL contener rutas absolutas ni nombres de cuentas fuera de los nombres de repos. Si no puede leer el tablero (sin configuración, sin `gh`, sin red o sin permiso), SHALL avisar en una línea, NO SHALL tocar `metricas.md` y SHALL terminar con 0.

#### Scenario: Archivo generado
- **WHEN** se generan las métricas
- **THEN** `metricas.md` existe sin BOM, su primera línea es el comentario de archivo generado y tiene las cinco secciones en orden

#### Scenario: Período sin issues cerrados
- **WHEN** no se cerró ningún issue en el período
- **THEN** las secciones de resumen e issues cerrados dicen `Sin issues cerrados en el período.` y el throughput muestra las semanas con 0

#### Scenario: Sin tablero o sin gh
- **WHEN** no hay `tablero.md` o `gh` no está disponible
- **THEN** el script imprime una línea con el motivo, termina con 0 y `metricas.md` queda como estaba

### Requirement: Métricas recalculadas en el cierre
`openspec-archive-change` en la fase del vault y `odd-change` en `/odd:close` SHALL correr `scripts/metricas.ps1` desde `$env:SDD_CONFIG_REPO` antes de sincronizar el vault, para que `metricas.md` entre en el mismo commit del vault. Sin `SDD_CONFIG_REPO`, SHALL saltear el paso y decirlo en el resumen. Un aviso del script NO SHALL frenar el cierre.

#### Scenario: Paso en el cierre
- **WHEN** se leen `skills/openspec-archive-change/SKILL.md`, `skills/odd-change/SKILL.md`, `.claude/commands/opsx/archive.md` y `.claude/commands/odd/close.md`
- **THEN** tienen el paso de `metricas.ps1` antes del sync del vault y dicen que un aviso no frena el cierre

### Requirement: Métricas en las reglas y la guía
`.claude/CLAUDE.md` SHALL nombrar las métricas de flujo (lead time, cycle time, throughput, tiempo por columna y trabajo en curso) en la sección `## Scrumban`, con cuándo se recalculan y cómo regenerarlas a mano, y SHALL incluir `metricas.md` en `### Estructura del vault`. `docs/workflow.md` SHALL explicar en la guía del tablero qué mide cada métrica y el comando para regenerarlas.

#### Scenario: Reglas y guía
- **WHEN** se leen `.claude/CLAUDE.md` y `docs/workflow.md`
- **THEN** los dos nombran las cinco métricas y `metricas.ps1`, y la estructura del vault incluye `metricas.md`
