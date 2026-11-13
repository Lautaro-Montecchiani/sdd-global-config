# 0004. Issues de GitHub como fuente única del backlog

Estado: aceptada
Fecha: 2026-11-13
Change: backlog-desde-issues

## Contexto

Lo pendiente de cada proyecto vivía en cinco lugares con formatos distintos: la hoja de ruta del `vision.md`, los "no incluye" de `## Alcance`, los changes activos, los issues de GitHub y los "Pendientes" del `context.md` del vault. La regla "no hay propose sin issue aprobado" no se cumplía y los issues estaban desactualizados. El SRS describe lo que el sistema ya hace, pero no había una vista de lo que falta. 16 de los 17 proyectos que usan el workflow están en GitHub.

## Alternativas

- **Vista generada desde todas las fuentes:** `docs/backlog.md` se arma leyendo las cinco fuentes. Se descartó porque hereda el desorden de las fuentes y no hay una prioridad común entre ellas.
- **Archivo de backlog como fuente:** `docs/backlog.md` reemplaza a la hoja de ruta y a los pendientes, y Claude lo mantiene desde las skills. Se descartó porque compite con el issue como puerta de entrada, no lo ve el equipo en GitHub y no sirve para lo operativo entre proyectos.
- **GitHub Projects o una herramienta externa:** se descartó por la configuración extra en cada repo, y porque los repos tienen tres dueños distintos.
- **Dejarlo como está:** se descartó porque la regla del issue seguiría sin cumplirse y lo pendiente seguiría disperso.

## Decisión

Los issues de GitHub son la fuente única de lo pendiente de cada proyecto, con etiquetas `prioridad:*` y `tipo:*`. El propose exige el issue (`Issue: #NN` en el proposal), el PR lo cierra con `Closes #NN`, el SRS anota el issue de origen de cada requirement y `scripts/generar-backlog.ps1` genera `docs/backlog.md` desde los issues abiertos, ofrecido en el archive. La hoja de ruta sigue en el `vision.md` y suma el número de issue. Sin `gh`, sin red o sin permiso, el flujo avisa y sigue. Lo operativo entre proyectos queda en el vault.

## Consecuencias

- Positivas: una lista priorizada por proyecto que el equipo ve en GitHub, traza completa de la idea al requirement, cierre automático de los issues al mergear y un backlog reproducible y testeable.
- Negativas: el flujo depende de `gh` y de tener la cuenta con permiso en cada repo (tres dueños). Los proyectos fuera de GitHub quedan con `Issue: pendiente`. Mantener las etiquetas al día depende de la disciplina de `/issue-creation`.
