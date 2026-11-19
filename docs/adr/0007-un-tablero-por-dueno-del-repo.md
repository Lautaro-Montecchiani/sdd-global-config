# 0007. Un tablero por dueño del repo con WIP y métricas globales

Estado: aceptada
Fecha: 2026-11-19
Change: tablero-segun-dueno

## Contexto

El ADR 0006 dejó un GitHub Project de usuario por vault, configurado en `tablero.md`, con el WIP de la persona y no de cada repo. En la práctica, los repos de la empresa se siguen en un Project de la cuenta del trabajo, y los personales en otro, pero desde el mismo vault: las tarjetas de los repos de la empresa caían en el tablero personal. Un solo `owner`/`numero` no alcanza, y partir el WIP por tablero contradice el motivo del ADR 0006.

## Alternativas

- **Un `tablero.md` por dueño (varios archivos):** reparte los límites de WIP y la cadencia entre archivos y obliga a sumar a mano. Descartada.
- **Tabla en el cuerpo de `tablero.md`:** más legible en Obsidian, pero necesita un segundo lector y se rompe con ediciones a mano. Descartada.
- **Elegir el tablero por repo:** más configuración sin un caso que lo necesite; el dueño ya separa trabajo y personal. Descartada.
- **WIP por tablero:** dos capacidades para una sola persona; vuelve al problema que el ADR 0006 evitaba. Descartada.
- **Pasarle el tablero a `tablero.ps1` desde cada skill:** cambia todas las skills y sus comandos, y cada skill tendría que saber de tableros. Descartada.

## Decisión

`tablero.md` mantiene `owner` y `numero` como tablero por defecto y suma líneas `dueno-<dueño del repo>: <cuenta>/<número>`. Los scripts eligen el tablero por el dueño del repo del issue (de la URL o del remoto `origin`), sin parámetros nuevos para las skills. Los límites de WIP siguen siendo uno por columna y se comparan con la suma de todos los tableros. Las métricas y la retro siguen siendo globales: `metricas.ps1` junta todos los tableros en un solo `metricas.md`. Un issue que está en dos tableros cuenta una vez. Complementa al ADR 0006, que sigue vigente.

## Consecuencias

- Positivas: cada tarjeta cae en el tablero de su dueño sin tocar las skills; una sola capacidad de WIP y un solo `metricas.md`; un `tablero.md` viejo sigue funcionando.
- Negativas: el control de WIP y las métricas hacen una lectura de `gh` por tablero; si un tablero no se puede leer, el WIP es parcial (se avisa); la cuenta activa de `gh` necesita acceso a todos los Projects configurados.
