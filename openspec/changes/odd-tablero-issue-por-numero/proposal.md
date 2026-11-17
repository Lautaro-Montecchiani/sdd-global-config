## Why

`scripts/tablero.ps1 -Issue` solo reconoce la URL completa del issue; con el número (`-Issue 75`) falla al agregar la tarjeta. Detalle en `docs/odd/tablero-issue-por-numero.md`.

## What Changes

- `scrumban-board` — «Mover la tarjeta de un issue»: `-Issue` acepta la URL o el número del issue; con el número, la URL se arma con el remoto `origin` de la carpeta actual. Un valor que no es URL ni número, o un número sin remoto de GitHub, termina con 1. Suma dos escenarios.

## Impact

- `scripts/tablero.ps1` y `tests/tablero-scrumban.Tests.ps1`. Compatible hacia atrás: las skills siguen pasando la URL.
