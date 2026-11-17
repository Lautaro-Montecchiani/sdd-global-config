## MODIFIED Requirements

### Requirement: Mover la tarjeta de un issue
`scripts/tablero.ps1 -Issue <url o número> -Columna <columna>` SHALL dejar el issue en el Project configurado con su campo `Status` en la opción de esa columna. Si el issue no está en el Project, SHALL agregarlo antes. `-Issue` SHALL aceptar la URL del issue o solo su número; con el número, SHALL armar la URL `https://github.com/<owner>/<repo>/issues/<número>` con el remoto `origin` de la carpeta actual (forma HTTPS o SSH de `github.com`). Si `-Issue` no es una URL de issue de GitHub ni un número, o es un número en una carpeta sin remoto `origin` de GitHub, el script SHALL avisar en una línea y terminar con 1 sin llamar a `gh`. `-Columna` SHALL aceptar `backlog`, `listo`, `diseno`, `construccion`, `revision` y `hecho` sin distinguir mayúsculas, que corresponden a las opciones `Backlog`, `Listo`, `Diseño`, `Construcción`, `Revisión` y `Hecho`. Una columna fuera de esa lista SHALL terminar con 1. Si `gh` no está, no hay red, el token no tiene el permiso `project` o `gh` falla, el script SHALL avisar en una línea sin rutas absolutas y terminar con 0. Con `-Simular` SHALL imprimir los comandos de `gh` que correría sin ejecutar los que modifican el Project.

#### Scenario: Issue nuevo en el tablero
- **WHEN** se mueve a `backlog` un issue que no está en el Project
- **THEN** el script lo agrega al Project y pone `Status` en `Backlog`

#### Scenario: Issue que cambia de columna
- **WHEN** se mueve a `revision` un issue que está en `Construcción`
- **THEN** el `Status` del issue pasa a `Revisión` y el resto de los issues no cambia

#### Scenario: Columna desconocida
- **WHEN** se pasa `-Columna testing`
- **THEN** el script termina con 1 y lista las columnas válidas

#### Scenario: Sin permiso o sin gh
- **WHEN** `gh` no está instalado o falla por falta del permiso `project`
- **THEN** el script imprime una línea con el motivo y `gh auth refresh -s project` si es el permiso, y termina con 0

#### Scenario: Dato inválido: Project sin la opción de la columna
- **WHEN** el campo `Status` del Project no existe o no tiene la opción `Diseño`
- **THEN** el script avisa `el tablero no tiene la columna Diseño`, no modifica el issue y termina con 0

#### Scenario: Issue por número
- **WHEN** se pasa `-Issue 10` en una carpeta cuyo remoto `origin` es `https://github.com/org/repo.git` o `git@github.com:org/repo.git`
- **THEN** el script usa la URL `https://github.com/org/repo/issues/10` y mueve la tarjeta igual que con esa URL

#### Scenario: Dato inválido: issue que no es URL ni número
- **WHEN** se pasa `-Issue abc`, o `-Issue 10` en una carpeta sin remoto `origin` de GitHub
- **THEN** el script avisa en una línea que nombra `-Issue`, termina con 1 y no llama a `gh`
