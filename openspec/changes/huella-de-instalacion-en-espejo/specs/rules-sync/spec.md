## ADDED Requirements

### Requirement: Huella de lo instalado en el espejo
`instalar.ps1` SHALL calcular una huella de las skills, los comandos y los archivos de Antigravity que distribuye a cada máquina, a partir solo de la ruta y el contenido normalizado de sus fuentes en el repo (no del destino ni del vault), y SHALL escribirla como `instalacion: <12 caracteres hexadecimales>` en el encabezado del espejo.

#### Scenario: Fuentes de la huella
- **WHEN** cambia el contenido de un archivo de `skills/`, de un `.md` de `.claude/commands/` o de `templates/antigravity/GEMINI.md`, `templates/antigravity/skills/odd-apply/SKILL.md`, `templates/antigravity/statusline.bat` o `templates/antigravity/statusline_new.ps1`
- **THEN** la huella cambia
- **AND** un cambio en `.claude/statusline.sh` o en `.claude/CLAUDE.md` no cambia la huella

#### Scenario: Huella en el encabezado
- **WHEN** se corre `instalar.ps1` con un destino y un vault de prueba
- **THEN** el encabezado de `_global/reglas-globales.md` tiene una línea `instalacion:` con 12 caracteres hexadecimales

#### Scenario: Misma huella con otro destino
- **WHEN** se corre `instalar.ps1` con un destino que tiene `.gemini/antigravity-cli` y, con otro vault de prueba, con un destino vacío, desde el mismo commit del repo
- **THEN** la línea `instalacion:` de los dos espejos es la misma

#### Scenario: Skill nueva cambia la huella
- **WHEN** el espejo del vault de prueba tiene el cuerpo de `.claude/CLAUDE.md` del repo, un `commit:` que existe en el repo y una línea `instalacion:` distinta de la huella actual, y se corre `instalar.ps1`
- **THEN** el espejo figura como `atrasado` y queda reescrito sin `-Forzar`, con la huella actual y el commit corto del repo
- **AND** el vault tiene un commit nuevo `chore: sdd-global-config — sync reglas`

#### Scenario: Espejo anterior sin huella
- **WHEN** el espejo del vault de prueba tiene el cuerpo de `.claude/CLAUDE.md` del repo y un encabezado sin línea `instalacion:`, y se corre `instalar.ps1`
- **THEN** el espejo figura como `atrasado`, no como `con cambios locales`
- **AND** queda reescrito con la línea `instalacion:`

#### Scenario: Dato inválido: línea de huella mal formada
- **WHEN** el espejo del vault de prueba tiene `instalacion: no-es-un-hash`, el cuerpo de `.claude/CLAUDE.md` del repo y un `commit:` que existe en el repo, y se corre `instalar.ps1`
- **THEN** el espejo figura como `atrasado`, sin error de ejecución
- **AND** queda reescrito con la huella actual

### Requirement: Aviso de skills y comandos nuevos en las reglas
`.claude/CLAUDE.md`, en "Al iniciar cada sesión", SHALL decir que un `repo atrasado` en `instalar.ps1 -Comprobar` significa que otra máquina instaló reglas, skills o comandos nuevos, y que Claude le pide al usuario `git pull` en el repo y `instalar.ps1`, sin correrlos por su cuenta. `README.md` y `docs/modo-de-uso.md` SHALL explicar que el espejo lleva la huella de skills y comandos y qué hacer ante `repo atrasado`.

#### Scenario: Texto del inicio de sesión
- **WHEN** se lee "Al iniciar cada sesión" en `.claude/CLAUDE.md`
- **THEN** nombra `repo atrasado`, dice que hay reglas, skills o comandos nuevos de otra máquina y pide `git pull` e `instalar.ps1` al usuario

#### Scenario: Texto de las guías
- **WHEN** se buscan `instalacion:` y `repo atrasado` en `README.md` y en `docs/modo-de-uso.md`
- **THEN** los dos explican que la huella cubre skills y comandos y que `repo atrasado` se resuelve con `git pull` en el repo e `instalar.ps1`

## MODIFIED Requirements

### Requirement: Espejo del vault al instalar
Salvo `-SinVault`, `instalar.ps1` SHALL escribir `_global/reglas-globales.md` en el vault de `-Vault` (por defecto `OBSIDIAN_VAULT`) con un encabezado que nombra como fuente a `.claude/CLAUDE.md` del repo `sdd-global-config`, el `commit` corto del repo, la huella `instalacion:` del requirement "Huella de lo instalado en el espejo", la fecha y el aviso de solo lectura, seguido del contenido de `.claude/CLAUDE.md` del repo. SHALL escribirlo antes que los archivos del destino, agregar solo ese archivo al índice, commitear con `chore: sdd-global-config — sync reglas` si hubo cambios y pushear. Si el push falla, SHALL avisar y terminar con código 0. Si el vault no está definido o no existe, SHALL avisar y seguir sin él.

#### Scenario: Espejo sincronizado
- **WHEN** se corre `instalar.ps1` con un vault de prueba que tiene un remote bare
- **THEN** `_global/reglas-globales.md` contiene el `CLAUDE.md` del repo, el aviso de solo lectura que nombra al repo como fuente, una línea `commit:` con el commit corto del repo y una línea `instalacion:`
- **AND** el último commit del remote bare es `chore: sdd-global-config — sync reglas`
- **AND** ningún otro archivo del vault quedó en ese commit

#### Scenario: Sin vault
- **WHEN** se corre `instalar.ps1` con `-Vault` apuntando a una carpeta que no existe
- **THEN** la salida avisa que no hay vault
- **AND** la instalación en `~/.claude` se completa con la copia completa del `CLAUDE.md` y el código de salida es 0

### Requirement: Protección del espejo ante ediciones a mano
Antes de escribir cualquier archivo, `instalar.ps1` SHALL clasificar el espejo como `igual`, `atrasado`, `con cambios locales` o `repo atrasado`, y mostrarlo en la tabla. Para `igual` SHALL ignorar solo las líneas `commit:` y `updated:`; una línea `instalacion:` distinta o ausente no es `igual`. Si el espejo no es `igual` y su `commit:` no existe en el repo local, SHALL clasificarlo `repo atrasado` antes de comparar el cuerpo. Con `con cambios locales` SHALL terminar con código distinto de 0 sin escribir nada, salvo con `-Forzar`, que primero lo respalda. Con `repo atrasado` SHALL terminar con código distinto de 0 también con `-Forzar` y pedir actualizar el repo.

#### Scenario: Espejo ya igual
- **WHEN** se corre `instalar.ps1` dos veces seguidas con el mismo vault de prueba
- **THEN** la segunda corrida muestra el espejo como `igual`
- **AND** no agrega ningún commit al vault

#### Scenario: Espejo editado a mano
- **WHEN** se agrega una línea a `_global/reglas-globales.md` del vault de prueba y se corre `instalar.ps1`
- **THEN** termina con código distinto de 0 y lista el espejo como `con cambios locales`
- **AND** no cambian el espejo ni ningún archivo del destino

#### Scenario: Forzar con respaldo del espejo
- **WHEN** se repite el caso anterior con `-Forzar`
- **THEN** la salida muestra la carpeta de respaldo, que contiene el espejo con la línea agregada
- **AND** el espejo queda con el contenido de `.claude/CLAUDE.md` del repo, sin la línea agregada

#### Scenario: Espejo atrasado
- **WHEN** el espejo tiene el contenido de una versión anterior de `.claude/CLAUDE.md` presente en la historia de git y se corre `instalar.ps1`
- **THEN** el espejo figura como `atrasado` y queda actualizado sin usar `-Forzar`

#### Scenario: Repo atrasado
- **WHEN** el encabezado del espejo tiene un `commit` que no existe en el repo local, su contenido difiere del repo y se corre `instalar.ps1 -Forzar`
- **THEN** termina con código distinto de 0, muestra `repo atrasado` y pide correr `git pull` en el repo
- **AND** no cambian el espejo ni ningún archivo del destino

#### Scenario: Repo atrasado con las mismas reglas
- **WHEN** el espejo tiene el cuerpo de `.claude/CLAUDE.md` del repo, un `commit` que no existe en el repo local y una línea `instalacion:` distinta de la huella actual, y se corre `instalar.ps1`
- **THEN** termina con código distinto de 0 y muestra `repo atrasado`, no `atrasado`
- **AND** el espejo conserva su `commit` y su línea `instalacion:` y el vault no tiene commits nuevos

### Requirement: Comprobación de la instalación
`instalar.ps1 -Comprobar` NO SHALL escribir en el destino, en el manifiesto ni en el vault. SHALL mostrar la tabla de estados y terminar con código 0 solo si todos los archivos del destino y el espejo (cuando hay vault) están `igual`; en cualquier otro caso SHALL terminar con código distinto de 0 y listar los que difieren. Si el espejo es `repo atrasado`, SHALL agregar una línea que diga que otra máquina instaló reglas, skills o comandos nuevos y pida `git pull` en el repo y `instalar.ps1`. Si `-Vault` no se pasa y `OBSIDIAN_VAULT` no está en el proceso, SHALL usar el valor de la variable de usuario del sistema.

#### Scenario: Instalación al día
- **WHEN** se corre `instalar.ps1` con un destino y un vault de prueba, y después `instalar.ps1 -Comprobar` con los mismos parámetros
- **THEN** la comprobación termina con código 0

#### Scenario: Espejo distinto
- **WHEN** después de instalar se agrega una línea al espejo del vault de prueba y se corre `instalar.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y nombra `_global/reglas-globales.md`
- **AND** el espejo conserva la línea agregada y el vault no tiene commits nuevos

#### Scenario: Destino atrasado
- **WHEN** se corre `instalar.ps1 -Comprobar` sobre un destino vacío
- **THEN** termina con código distinto de 0
- **AND** el destino sigue vacío

#### Scenario: Comprobar con skills nuevas en otra máquina
- **WHEN** después de instalar se cambia el `commit:` del espejo del vault de prueba por uno que no existe en el repo y su línea `instalacion:` por otra huella, y se corre `instalar.ps1 -Comprobar`
- **THEN** termina con código distinto de 0 y muestra `repo atrasado`
- **AND** la salida tiene una línea que menciona skills o comandos nuevos, `git pull` e `instalar.ps1`
- **AND** el espejo no cambia y el vault no tiene commits nuevos
