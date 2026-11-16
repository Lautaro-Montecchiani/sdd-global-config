# 0006. Tablero Scrumban en un GitHub Project de usuario

Estado: aceptada
Fecha: 2026-11-16
Change: tablero-scrumban

## Contexto

El workflow adopta Scrumban: un tablero con las etapas del flujo (Backlog, Listo, Diseño, Construcción, Revisión y Hecho) y límites de trabajo en curso. El ADR 0004 dejó los issues de GitHub como fuente única del backlog y descartó GitHub Projects por la configuración que pedía en cada repo. El usuario trabaja solo con Claude y el Agente, en varios proyectos a la vez y con un vault personal y uno del trabajo, así que el WIP es de la persona y no de cada repo.

## Alternativas

- **Trello:** simple y conocido, pero las tarjetas son una copia de los issues que hay que mantener a mano o con un Power-Up. Se descartó por duplicar la fuente del backlog.
- **Jira:** completo (sprints, reportes), pero es una segunda fuente del backlog y es pesado para una persona. Se descartó.
- **Tablero generado en el vault (Markdown):** sin dependencias nuevas, pero es de solo lectura, no se puede mover una tarjeta a mano y no se ve desde el celular. Se descartó.
- **App propia en otro repo:** sería un producto nuevo para mantener (pantallas, datos, acceso). Se descartó.
- **Un Project por repo:** repite la configuración en cada repo (el motivo del descarte del ADR 0004) y parte el WIP por proyecto. Se descartó.

## Decisión

El tablero es un GitHub Project de usuario con el campo `Status` en 6 opciones. Las tarjetas son los mismos issues, así que el ADR 0004 sigue vigente: el tablero es una vista, no una fuente. La configuración (dueño, número y límites de WIP) vive en `tablero.md` de cada vault. `scripts/tablero.ps1` mueve las tarjetas y cuenta el WIP con `gh project`, y las skills lo llaman en cada paso del flujo. Sin configuración, sin `gh` o sin el permiso `project`, el flujo avisa y sigue.

## Consecuencias

- Positivas: un tablero que junta todos los proyectos del vault, se actualiza solo y se ve en la web, en el celular y como app de escritorio; WIP controlado antes de empezar trabajo nuevo; sin datos duplicados.
- Negativas: el token de `gh` necesita el permiso `project` en cada máquina y cada cuenta; el Project se crea a mano una vez; los issues de repos de otra cuenta solo se pueden agregar si la cuenta del Project tiene acceso a ellos; cada paso del flujo suma hasta cuatro llamadas a `gh`.
