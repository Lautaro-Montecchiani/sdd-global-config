# Design

## Context

Ver proposal.md (Why). Estado actual en `scripts/instalar.ps1` (599 líneas):

- **Lista de archivos** (líneas 81 a 195): `.claude/CLAUDE.md`, todos los archivos de `skills/`, los `.md` de `.claude/commands/` y, solo si el destino tiene `.gemini` o `.gemini/antigravity-cli`, `templates/antigravity/GEMINI.md`, `templates/antigravity/skills/odd-apply/SKILL.md`, `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1`. La lista depende del destino.
- **Encabezado del espejo** (líneas 311 a 322): `type`, `source`, `commit: $shortCommit`, `updated: $hoy`, el aviso `> [!info]` y el cuerpo de `.claude/CLAUDE.md`.
- **Clasificación del espejo** (líneas 360 a 412): (1) no existe → `creado`; (2) igual sin contar `commit:` ni `updated:` (`Quitar-LineasDinamicasEspejo`) → `igual`; (3) el cuerpo es igual al `CLAUDE.md` del repo → `atrasado`; (4) el `commit:` no existe en el repo (`git cat-file -e`) → `repo atrasado`; (5) el cuerpo es una versión de la historia de git → `atrasado`; (6) si no, `con cambios locales`.
- **`-Comprobar`** (líneas 490 a 516): lista los que no están `igual` con su estado y termina con 1; no explica qué hacer con `repo atrasado`. Sin `-Comprobar`, `repo atrasado` frena con "Corré git pull en el repo y volvé a instalar." (línea 520).
- **El hueco:** un change que toca solo skills o comandos deja el espejo `igual` (paso 2): no hay commit en el vault y la otra máquina, con el repo atrasado, ve todo `igual` en `-Comprobar`. Y si el repo local está atrasado pero tiene el mismo `CLAUDE.md`, el paso 3 clasifica `atrasado` antes de mirar el commit y `instalar.ps1` reescribe el espejo con un commit más viejo.
- `.claude/statusline.sh` no se copia: las barras apuntan al archivo del repo (`scripts/barra-estado.ps1`), así que llega con `git pull`.

## Goals / Non-Goals

**Goals:** que un cambio de skills, comandos o archivos de Antigravity llegue a las otras máquinas como aviso por el mismo camino que las reglas (el pull del vault y `-Comprobar` al iniciar sesión), y que una máquina atrasada nunca reescriba el espejo con un commit más viejo.

**Non-Goals:** ver proposal. Además, no cambia la lista de archivos que se instalan, el manifiesto ni la clasificación de los archivos del destino.

## Decisions

### D1. Cálculo de la huella en `scripts/comun.ps1`

Función nueva `Obtener-HuellaInstalacion` con parámetro `-RepoRoot`, que no escribe nada:

1. Junta las fuentes que existan en el repo, sin mirar el destino: todos los archivos de `skills/` (recursivo), los `*.md` de `.claude/commands/` (recursivo) y, si existen, `templates/antigravity/GEMINI.md`, `templates/antigravity/skills/odd-apply/SKILL.md`, `templates/antigravity/statusline.bat` y `templates/antigravity/statusline_new.ps1`.
2. Para cada una arma la línea `<ruta relativa al repo con />` + tabulación + `Obtener-HashNormalizado` del contenido leído en UTF-8.
3. Ordena las líneas por ruta con comparación ordinal (`[System.StringComparer]::Ordinal`), las une con `\n` y devuelve los primeros 12 caracteres de `Obtener-HashNormalizado` de ese texto (minúsculas).

Va en `comun.ps1`, no en `instalar.ps1`, porque es un cálculo puro (entra el repo, sale un texto) y `instalar.ps1` ya pasó el aviso de tamaño (deuda #56).

- **Alternativa descartada:** usar la lista `$items` de `instalar.ps1`. Depende del destino (`.gemini` puede no existir), así que dos máquinas con el mismo commit tendrían huellas distintas y el espejo cambiaría en cada una.
- **Alternativa descartada:** el commit del último cambio en `skills/` o `.claude/commands/` (`git log -1 -- <rutas>`). No ve cambios sin commitear y depende de la historia de git, que los tests no controlan.

### D2. Línea `instalacion:` en el encabezado del espejo

En `$espejoNuevo` (líneas 311 a 322 de `instalar.ps1`), después de `commit: $shortCommit` y antes de `updated: $hoy`, va la línea `instalacion: $huella`, con `$huella = Obtener-HuellaInstalacion -RepoRoot $repoRoot`. `Quitar-LineasDinamicasEspejo` **no** cambia: sigue quitando solo `commit:` y `updated:`, así una huella distinta o ausente hace que el espejo no sea `igual`. `Extraer-CuerpoEspejo` no cambia (el cuerpo empieza después del aviso `> [!info]`).

### D3. Orden de la clasificación del espejo

En las líneas 378 a 411 de `instalar.ps1`, la comprobación del `commit:` pasa a ir antes de comparar el cuerpo:

1. No existe → `creado`.
2. Igual sin contar `commit:` ni `updated:` → `igual`.
3. El encabezado tiene `commit:` y `git cat-file -e <commit>^{commit}` falla → `repo atrasado` (guarda `$commitDesconocido`).
4. El cuerpo es igual al `CLAUDE.md` del repo → `atrasado`.
5. El cuerpo es una versión de la historia de git → `atrasado`.
6. Si no, `con cambios locales`.

Una línea `instalacion:` mal formada o ausente no da error: solo hace que el paso 2 no coincida. El resto del flujo (respaldo con `-Forzar`, `repo atrasado` que frena siempre, commit y push del vault) no cambia.

- **Alternativa descartada:** dejar el orden y comparar la huella aparte. Una máquina con el repo atrasado y el mismo `CLAUDE.md` seguiría clasificando `atrasado` y pisaría el espejo con su huella vieja; después la otra máquina lo volvería a pisar.

### D4. Mensaje de `-Comprobar` con `repo atrasado`

En el bloque de `-Comprobar` (líneas 490 a 516), si hay vault y el espejo es `repo atrasado`, después de la lista de archivos que difieren y antes de `exit 1`, se imprime:

`Aviso: el espejo del vault viene de un commit que este repo no tiene (<commit>): otra máquina instaló reglas, skills o comandos nuevos. Corré git pull en el repo y pwsh scripts/instalar.ps1.`

El código de salida y la tabla no cambian.

### D5. Texto de `.claude/CLAUDE.md`

Commit separado que toca solo `.claude/CLAUDE.md`, sin tocar el bloque generado de reglas:

- En "## Al iniciar cada sesión", la viñeta que empieza "Comprobar las reglas:" pasa a: "Comprobar las reglas: `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1 -Comprobar`. Si termina con error, avisar al usuario qué archivo difiere y pedirle `git pull` en el repo y `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1`. Si el espejo figura `repo atrasado`, otra máquina instaló reglas, skills o comandos nuevos (el espejo lleva la huella `instalacion:` de lo instalado). No corregir las copias a mano ni correr `git pull` o `instalar.ps1` por cuenta propia."
- En "### Reglas globales en el vault (`_global\`)", al final de la viñeta "**Escritura del espejo:** …" se agrega: "El encabezado lleva el `commit:` del repo y la huella `instalacion:` de las skills, los comandos y los archivos de Antigravity que se instalan, así un change que toca solo skills o comandos también cambia el espejo y avisa a las otras máquinas."

### D6. Guías

- `README.md`: al final del párrafo "**Sincronización continua:** …" se agrega: "El encabezado del espejo lleva la huella `instalacion:` de las skills, los comandos y los archivos de Antigravity, así un change que toca solo skills también llega a las otras máquinas con el pull del vault. Si `instalar.ps1 -Comprobar` muestra `repo atrasado`, otra máquina instaló algo nuevo: corré `git pull` en el repo y `pwsh scripts/instalar.ps1`."
- `docs/modo-de-uso.md`: al final de "## Setup por máquina (una sola vez, no por proyecto)", antes del `---` que precede a "## Barra de estado", un párrafo "**Mantener la máquina al día.**" con el mismo contenido que el agregado de `README.md`.

## Risks / Trade-offs

- [Riesgo] Una máquina con skills editadas sin commitear reescribe el espejo con una huella que no corresponde a ningún commit, y otra máquina al día lo vuelve a reescribir. → Mitigación: `instalar.ps1` ya avisa "El repositorio tiene cambios sin commitear en las rutas instaladas"; la segunda máquina clasifica `atrasado` (commit conocido) y lo corrige sin `-Forzar`.
- [Riesgo] Un commit más en el vault en la primera instalación de cada máquina después del merge (falta la línea `instalacion:`). → Aceptado: es un único commit `chore: sdd-global-config — sync reglas`.
- [Trade-off] La otra máquina recibe un aviso, no las skills: hay que correr `git pull` e `instalar.ps1`. Se elige así para no escribir en `~/.claude` sin que el usuario lo pida.

## Migration Plan

Después del merge, en cada máquina: `git pull` y `pwsh scripts/instalar.ps1`. La primera corrida clasifica el espejo como `atrasado` y le suma la línea `instalacion:`. Rollback: revertir el merge; el espejo con línea `instalacion:` queda `atrasado` frente al código anterior (el cuerpo es igual al `CLAUDE.md` del repo) y se reescribe sin `-Forzar`.

## Impacto en proyectos existentes

Ninguno sobre los archivos de los proyectos: no cambian `AGENTS.md`, las plantillas ni `pr-check.yml`. Cambia el inicio de sesión de Claude en todos los proyectos: el aviso de `repo atrasado` ahora también aparece cuando otra máquina instaló skills o comandos nuevos.

## Impacto en el sistema

**Componentes afectados:** el vault compartido (`_global/reglas-globales.md` suma una línea y un commit por máquina al migrar) y el inicio de sesión de Claude en todas las máquinas y proyectos (`instalar.ps1 -Comprobar`).

**Atributos de calidad:**
- mantenibilidad (alta): la huella se calcula por script desde las fuentes del repo y se controla con `-Comprobar`, sin texto ni listas copiadas a mano; el cálculo va en `comun.ps1` para no hacer crecer `instalar.ps1` — Verificación: S01, S02 y revisión del diff: `instalar.ps1` no repite la lista de fuentes de D1 y crece menos de 30 líneas.

**Decisiones de arquitectura:** ADR nuevo: 0008 (complementa al 0002, no lo reemplaza).

**Deuda técnica:**
- paga: las reglas llegan a otra máquina con el pull del vault, pero las skills y los comandos solo con `instalar.ps1` y pueden quedar desparejos sin aviso (#53).
- descubre: ninguna nueva. `instalar.ps1` sigue en el aviso de tamaño (#56), con un crecimiento acotado por D1.

## ADR

```markdown
# 0008. Huella de skills y comandos en el espejo del vault

Estado: aceptada
Fecha: 2026-11-21
Change: huella-de-instalacion-en-espejo

## Contexto

El ADR 0002 hizo que Claude y el Agente lean las reglas desde el espejo del vault, así que las reglas llegan a otra máquina con el pull del vault. Las skills, los comandos y los archivos de Antigravity se siguen copiando con `instalar.ps1` desde el repo local. Un change que toca solo skills o comandos no cambia el espejo: la otra máquina no recibe ningún aviso y trabaja con skills viejas y reglas nuevas. Además, una máquina con el repo atrasado y el mismo `CLAUDE.md` podía reescribir el espejo con un commit más viejo.

## Alternativas

- **Copiar skills y comandos al vault e instalarlos desde ahí:** duplica todo el contenido en el vault y sigue necesitando `instalar.ps1`, porque Claude Code no carga skills con `@`. Descartada.
- **Distribuir skills y comandos como plugin de Claude Code desde el repo:** suma una integración nueva, cambia los nombres de los comandos (`/opsx:propose` pasaría a llevar el prefijo del plugin) y no cubre las skills de Antigravity. Descartada.
- **Correr `git pull` e `instalar.ps1` automáticamente al iniciar sesión:** escribe en `~/.claude` sin que el usuario lo pida y choca con la regla de no corregir copias por cuenta propia. Descartada.
- **Huella por commit (`git log -1 -- skills .claude/commands`):** no ve cambios sin commitear y depende de la historia de git. Descartada.
- **No hacer nada y documentarlo:** deja el desparejo silencioso. Descartada.

## Decisión

`instalar.ps1` escribe en el encabezado del espejo una línea `instalacion:` con una huella de 12 caracteres calculada desde el contenido y la ruta de las skills, los comandos y los archivos de Antigravity que instala, sin depender del destino. Una huella distinta hace que el espejo deje de estar `igual`, así un change que toca solo skills también genera un commit en el vault con el commit nuevo del repo. La clasificación del espejo revisa primero si su `commit:` existe en el repo local: si no existe, es `repo atrasado` y `instalar.ps1` no lo escribe. `-Comprobar` explica que `repo atrasado` significa reglas, skills o comandos nuevos de otra máquina y pide `git pull` e `instalar.ps1`. La instalación sigue siendo a pedido del usuario.

## Consecuencias

- Positivas: cualquier cambio en lo que se instala llega a las otras máquinas como aviso por el mismo camino que las reglas; una máquina atrasada no pisa el espejo; no suma tecnologías ni integraciones.
- Negativas: la otra máquina recibe un aviso, no las skills (hay que correr `git pull` e `instalar.ps1`); cada máquina suma un commit al vault en la primera instalación; skills editadas sin commitear pueden reescribir el espejo hasta que otra máquina al día lo corrija.
```

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `tests/huella-de-instalacion-en-espejo.Tests.ps1` | `tests/` |
| `docs/adr/0008-huella-de-skills-y-comandos-en-el-espejo.md` | `docs/` (implícita) |

## Security Layer

Tipo de proyecto: `tooling`.

- Los artefactos modificados (instrucciones para IA y scripts de instalación) no exponen secretos ni rutas absolutas personales; la huella es un hash de contenido del repo, sin rutas de la máquina — Verificación: S01 y revisión del diff: ningún `C:\Users`, nombre de usuario, token ni `Invoke-Expression` en las líneas agregadas fuera de `openspec/`.
- El cambio al `CLAUDE.md` global va en un commit separado con descripción del impacto — Verificación: revisión del diff: un commit que solo toca `.claude/CLAUDE.md`, con una línea "Impacto:".
- Los tests no escriben en el `$HOME` real ni en el vault real — Verificación: revisión del diff: todos los tests nuevos usan `Con-CarpetaTemporal` y pasan `-Destino` y `-Vault`.
- Una máquina atrasada no sobrescribe el espejo compartido con un contenido más viejo — Verificación: S06.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se fuerza la suite completa porque cambian `scripts/instalar.ps1`, `scripts/comun.ps1` y `.claude/CLAUDE.md`, que leen otros tests. Cada test nuevo lleva `# test-plan: huella-de-instalacion-en-espejo/<ID>` arriba del `Probar`, usa `. "$PSScriptRoot/apoyo.ps1"` y `Con-CarpetaTemporal`, define sus propias `Ejecutar-Pwsh` e `Inicializar-VaultGit` copiadas de `tests/instalar.Tests.ps1` (líneas 8 y 36; así lo hacen los demás archivos de tests), y arma los espejos de prueba con el encabezado de D2 y el cuerpo leído de `.claude/CLAUDE.md` del repo.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Huella de lo instalado en el espejo / Huella en el encabezado | auto: después de instalar, el espejo tiene `^instalacion: [0-9a-f]{12}$` entre `commit:` y `updated:` | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S02 | Huella de lo instalado en el espejo / Misma huella con otro destino | auto: un destino con `.gemini/antigravity-cli` y otro vacío, con dos vaults de prueba: la línea `instalacion:` es igual en los dos | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S03 | Huella de lo instalado en el espejo / Skill nueva cambia la huella | auto: espejo con cuerpo del repo, `commit:` = HEAD corto e `instalacion: 000000000000`: sale `atrasado`, código 0, la huella queda igual a la de S01 y el vault tiene un commit nuevo `chore: sdd-global-config — sync reglas` | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S04 | Huella de lo instalado en el espejo / Espejo anterior sin huella | auto: espejo con encabezado sin `instalacion:` y cuerpo del repo: sale `atrasado` (no `con cambios locales`), código 0, y después tiene la línea `instalacion:` | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S05 | Huella de lo instalado en el espejo / Dato inválido: línea de huella mal formada | auto: `instalacion: no-es-un-hash` con cuerpo del repo y `commit:` = HEAD corto: sale `atrasado`, código 0, sin texto de excepción en la salida, y queda la huella actual | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S06 | Protección del espejo ante ediciones a mano / Repo atrasado con las mismas reglas | auto: cuerpo del repo, `commit: 0000000` e `instalacion: 000000000000`: código distinto de 0, salida con `repo atrasado`, el espejo conserva `commit: 0000000` e `instalacion: 000000000000` y el vault no tiene commits nuevos | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S07 | Comprobación de la instalación / Comprobar con skills nuevas en otra máquina | auto: después de instalar, se cambian `commit:` por `0000000` e `instalacion:` por `000000000000`; `-Comprobar` termina con código distinto de 0, muestra `repo atrasado` y la línea de D4 (con "skills o comandos", `git pull` e `instalar.ps1`); el hash del espejo no cambia y el vault no tiene commits nuevos | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S08 | Espejo del vault al instalar / Espejo sincronizado | auto: con remote bare, el espejo tiene `commit:` e `instalacion:`, y el último commit del remote es `chore: sdd-global-config — sync reglas` con solo ese archivo | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S09 | Aviso de skills y comandos nuevos en las reglas / Texto del inicio de sesión | auto: "Al iniciar cada sesión" de `.claude/CLAUDE.md` tiene `repo atrasado`, "skills o comandos", `git pull` e `instalar.ps1` | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S10 | Aviso de skills y comandos nuevos en las reglas / Texto de las guías | auto: `README.md` y `docs/modo-de-uso.md` tienen `instalacion:`, `repo atrasado` y `git pull` | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| S11 | Huella de lo instalado en el espejo / Fuentes de la huella | auto: con dot-source de `scripts/comun.ps1`, `Obtener-HuellaInstalacion -RepoRoot <carpeta temporal>` sobre una copia inventada con `skills/a/SKILL.md`, `.claude/commands/x.md`, `templates/antigravity/GEMINI.md`, `.claude/statusline.sh` y `.claude/CLAUDE.md`: cambiar una línea de cada uno de los tres primeros cambia la huella; cambiar `.claude/statusline.sh` o `.claude/CLAUDE.md` no la cambia | `tests/huella-de-instalacion-en-espejo.Tests.ps1` |
| M01 | Aviso real entre dos máquinas | manual (lo corre el usuario): en la otra PC, sin hacer `git pull` del repo después del merge, hacer `git -C $vault pull --rebase` y abrir una sesión de Claude Code. El aviso de inicio de sesión tiene que mostrar `repo atrasado` con la línea de D4. Después, `git pull` e `instalar.ps1`, y `-Comprobar` termina con código 0 | — |

Los escenarios "Espejo ya igual", "Espejo editado a mano", "Forzar con respaldo del espejo", "Espejo atrasado", "Repo atrasado", "Sin vault", "Instalación al día", "Espejo distinto" y "Destino atrasado" no cambian y los cubre C01.

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `scripts/instalar.ps1` y `scripts/comun.ps1` (con `tests/instalar.Tests.ps1`, en especial `reglas-fuente-unica/S08` a `S15`, y `tests/statusline-instalable.Tests.ps1`) | Instalación, manifiesto, clasificación del espejo (`igual`, `atrasado`, `con cambios locales`, `repo atrasado`), `-Forzar`, `-Simular` y `-Comprobar` | Cambia el orden de la clasificación solo cuando el `commit:` no existe y el cuerpo es igual al repo: antes `atrasado`, ahora `repo atrasado` (S06). El encabezado suma `instalacion:` (S01, S08). Los tests existentes no se modifican |

## Open Questions

- Ninguna.
