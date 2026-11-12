# Design

## Context

Motivación en `proposal.md` (Why). Estado actual, comprobado en el repo:

- `templates/fuente/fragmentos/reglas-ejecucion.md` tiene las 8 reglas en segunda persona. `.claude/CLAUDE.md` las repite a mano en tercera persona, bajo `### Reglas de ejecución del Agente`.
- `scripts/generar-plantillas.ps1 -Comprobar` compara solo los títulos de las reglas (bloque "Comparar títulos de reglas con .claude/CLAUDE.md").
- `tests/clasificacion-odd.Tests.ps1` (test S20) exige que la regla 7 termine con una oración distinta en el `CLAUDE.md` y en el fragmento.
- `scripts/instalar.ps1` copia `.claude/CLAUDE.md` completo a `<Destino>/.claude/CLAUDE.md` y después escribe el espejo del vault a partir del archivo instalado, sin compararlo antes (paso "8. Espejo del vault").
- `scripts/comun.ps1` ya tiene `Normalizar-Texto`, `Obtener-HashNormalizado`, `Test-EsVersionGitHistorica`, `Respaldar-Archivos` y `Escribir-ArchivoUtf8SinBom`.
- En las sesiones de Claude Code `OBSIDIAN_VAULT` puede no estar en el proceso (shell sin perfil); está definida como variable de usuario.
- No está verificado que el import `@` de Claude Code acepte una ruta absoluta de Windows fuera de `~/.claude`.

## Goals / Non-Goals

**Goals:**

- Que el texto de las 8 reglas exista en un solo archivo editable y que el CI falle si la copia del `CLAUDE.md` difiere en cualquier carácter.
- Que Claude y el Agente lean las reglas del mismo archivo del vault.
- Que ninguna copia (espejo, `~/.claude/CLAUDE.md`) se pueda pisar o desviar en silencio.
- Que Claude nunca quede sin reglas: sin vault, la instalación funciona como hoy.

**Non-Goals:**

- Los de `proposal.md` (Non-goals).
- Que `instalar.ps1` haga `git pull` del vault o del repo: solo detecta y avisa.
- Detectar un vault desactualizado en otra máquina sin correr `instalar.ps1 -Comprobar`.

## Decisions

### D1. Bloque entre marcas en `.claude/CLAUDE.md`

Las marcas son dos líneas completas: `<!-- inicio: reglas-ejecucion -->` y `<!-- fin: reglas-ejecucion -->`. Entre ellas va el fragmento sin su salto de línea final. `generar-plantillas.ps1` reemplaza solo lo que hay entre las marcas.

- Alternativa descartada: generar todo el `CLAUDE.md` desde un esqueleto. Obliga a mover el archivo entero a `templates/fuente/` por 8 líneas compartidas.
- Alternativa descartada: redactar el fragmento en infinitivo neutral. Obliga a reescribir las cuatro plantillas y sus tests; con la segunda persona solo cambia la copia del `CLAUDE.md`.

### D2. Validar todo antes de escribir

`generar-plantillas.ps1` valida las marcas en memoria junto con las plantillas y los comandos. Si falta una marca, hay más de una de cada tipo o la de fin está antes que la de inicio, muestra `Error: .claude/CLAUDE.md no tiene la marca '<marca>'` (o el problema que corresponda) y termina con código 1 sin escribir ningún archivo.

### D3. `-Comprobar` compara texto completo

Se quita la comparación de títulos. `-Comprobar` extrae el bloque de `.claude/CLAUDE.md`, lo normaliza con `Normalizar-Texto` y lo compara con el fragmento normalizado, ambos sin saltos de línea finales. Si difieren o faltan las marcas, muestra `Error: El bloque de reglas de .claude/CLAUDE.md difiere de templates/fuente/fragmentos/reglas-ejecucion.md` y termina con código 1. El mensaje final de éxito pasa a ser `OK: Todas las plantillas, comandos y el bloque de reglas están sincronizados.`

### D4. Archivo de carga en `~/.claude/CLAUDE.md`

Con vault, el contenido esperado de `<Destino>/.claude/CLAUDE.md` es este (la última línea usa la ruta absoluta del vault con `/`):

```text
<!-- Generado por scripts/instalar.ps1 de sdd-global-config. No editar a mano: las reglas se editan en el repo. -->

# Reglas globales del workflow SDD

Las reglas se cargan desde el vault con la línea de abajo. Si después de esa línea no ves la sección "Roles Claude / Agente (OpenSpec)", el vault no cargó: avisá al usuario antes de seguir y pedile que corra `scripts/instalar.ps1` del repo `sdd-global-config`.

@<ruta absoluta del vault>/_global/reglas-globales.md
```

- La ruta se obtiene con `Resolve-Path` sobre `-Vault` y se pasa a `/`.
- Sin vault (`-SinVault`, valor vacío o carpeta inexistente) el contenido esperado es la copia completa, como hoy.
- Si la ruta del vault tiene espacios, se instala la copia completa y se avisa: `Aviso: La ruta del vault tiene espacios; se instala la copia completa del CLAUDE.md en lugar del archivo de carga.` El espejo se escribe igual.
- La clasificación de `<Destino>/.claude/CLAUDE.md` compara el hash instalado contra el contenido esperado (archivo de carga o copia completa). Para decidir `atrasado` se sigue usando el manifiesto y `Test-EsVersionGitHistorica` sobre `.claude/CLAUDE.md`, así una copia completa vieja se reemplaza sin `-Forzar`.
- Alternativa descartada: un acceso directo (junction) desde `~/.claude` al vault. Suma un objeto del sistema de archivos que los tests no pueden crear sin permisos y que no se ve en el manifiesto.
- Alternativa descartada: quitar la copia completa del todo. Sin vault, Claude quedaría sin reglas.

### D5. Espejo armado desde el repo, con commit

El espejo se arma con `.claude/CLAUDE.md` del repo, no con el archivo instalado. Encabezado nuevo:

```text
---
type: reglas-globales
source: sdd-global-config/.claude/CLAUDE.md
commit: <commit corto>
updated: <AAAA-MM-DD>
---

> [!info] Espejo de solo lectura. Fuente: `.claude/CLAUDE.md` del repo `sdd-global-config`. Lo escribe solo `scripts/instalar.ps1`. No editar acá.

```

El cuerpo del espejo es todo lo que sigue a la línea que empieza con `> [!info]` y a la línea en blanco siguiente. Sirve igual para el encabezado viejo y el nuevo.

### D6. Clasificación del espejo antes de escribir

Se evalúa junto con los demás archivos, antes de cualquier escritura, y se muestra en la tabla como `vault: _global/reglas-globales.md`. Orden de evaluación:

1. No existe el archivo: `creado`.
2. El espejo es igual al que se generaría, sin contar las líneas `commit:` y `updated:`: `igual`. No se reescribe ni se commitea.
3. El cuerpo es igual a `.claude/CLAUDE.md` del repo (solo cambia el encabezado): `atrasado`.
4. El encabezado tiene `commit:` y `git -C <repo> cat-file -e "<commit>^{commit}"` falla: `repo atrasado`. Mensaje: `Error: El espejo del vault viene de un commit que este repo no tiene (<commit>). Corré git pull en el repo y volvé a instalar.` Termina con código 1, también con `-Forzar`.
5. El cuerpo es una versión anterior según `Test-EsVersionGitHistorica -RutaRelativa ".claude/CLAUDE.md"`: `atrasado`.
6. Cualquier otro caso, incluido un archivo sin la línea `> [!info]`: `con cambios locales`. Sin `-Forzar` entra en la lista de cambios locales existente y el script termina con código 1. Con `-Forzar` se respalda con `Respaldar-Archivos` junto con los demás.

Alternativa descartada: guardar el hash del espejo en el manifiesto de `~/.claude`. El vault se comparte entre máquinas y el manifiesto es local: otra máquina lo vería siempre como editado.

### D7. Orden de escritura

Primero el espejo y después los archivos del destino. Así el archivo de carga nunca apunta a un espejo que no existe. El commit y el push del vault siguen como hoy (solo `_global/reglas-globales.md`, aviso si el push falla).

### D8. `-Comprobar` en `instalar.ps1`

Parámetro nuevo `[switch]$Comprobar`. Muestra la tabla y no escribe nada (ni destino, ni manifiesto, ni vault, ni respaldo). Termina con código 0 solo si todos los archivos del destino y el espejo (cuando hay vault) están `igual`. Si no, lista los que difieren con su estado y termina con código 1. `-Simular` no cambia: sigue terminando con código 0.

### D9. Resolución del vault

Si no se pasa `-Vault` y `$env:OBSIDIAN_VAULT` está vacía, `instalar.ps1` usa `[Environment]::GetEnvironmentVariable("OBSIDIAN_VAULT", "User")`. Evita que `-Comprobar` crea que no hay vault cuando Claude lo corre desde un shell sin perfil. Los tests pasan siempre `-Vault` o `-SinVault`, así que no leen la variable real.

### D10. Texto nuevo de `.claude/CLAUDE.md`

Cambios exactos, además del bloque de D1. Todo lo que no se nombra queda igual.

**a) `### Reglas de ejecución del Agente`.** La línea de introducción pasa a ser:

```text
Aplican a cualquier agente constructor (Antigravity, Copilot, Codex, Cursor u otro), no solo a uno. Están redactadas para el Agente. El bloque de abajo se genera desde `templates/fuente/fragmentos/reglas-ejecucion.md` con `scripts/generar-plantillas.ps1` y no se edita a mano:
```

Debajo van la marca de inicio, las 8 reglas generadas y la marca de fin. El párrafo "En `/opsx:verify`, Claude lee la copia del resumen…" queda igual, fuera del bloque. En el párrafo "Distribución a agentes no-Claude", la última oración pasa a ser:

```text
Las cuatro plantillas y el bloque de reglas de este archivo se generan desde `templates/fuente/` con `scripts/generar-plantillas.ps1`; un cambio a estas reglas se edita solo en `templates/fuente/fragmentos/reglas-ejecucion.md` y se regenera, y el CI controla que el texto sea idéntico.
```

**b) `## Al iniciar cada sesión`, paso 3.** Se agrega al final de la lista:

```text
   - Comprobar las reglas: `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1 -Comprobar`. Si termina con error, avisar al usuario qué archivo difiere y pedirle `git pull` en el repo y `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1`. No corregir las copias a mano.
```

**c) `### Cuándo actuar`.** La fila "Cambio al CLAUDE.md global" pasa a ser:

```text
| Cambio de reglas (merge en `sdd-global-config`) | — | `scripts/instalar.ps1` reescribe `_global\reglas-globales.md` y `~/.claude/CLAUDE.md` |
```

**d) `### Estructura del vault`.** El comentario de `reglas-globales.md` pasa a ser `← espejo del CLAUDE.md del repo (lo leen Claude y el Agente)`.

**e) `### Reglas globales en el vault (`_global\`)`.** El párrafo inicial y las tres primeras viñetas se reemplazan por:

```text
Las reglas globales se espejan en `$vault\_global\reglas-globales.md`. Es el archivo que leen Claude y el Agente: cualquier agente con acceso al filesystem lee las mismas reglas sin depender de `~/.claude/`.

- **Fuente única:** `.claude/CLAUDE.md` del repo `sdd-global-config`. Ninguna copia se edita a mano: ni el espejo ni `~/.claude/CLAUDE.md`.
- **Carga en Claude:** con vault, `scripts/instalar.ps1` deja en `~/.claude/CLAUDE.md` un archivo mínimo que importa el espejo con `@` y la ruta del vault de esa máquina. Sin vault, instala la copia completa.
- **Escritura del espejo:** solo `scripts/instalar.ps1`. Compara antes de escribir: si el espejo fue editado a mano, frena sin tocar nada; con `-Forzar` lo respalda y lo restaura. Si el espejo viene de un commit que el repo local no tiene, frena y pide `git pull`.
- Si al iniciar sesión `instalar.ps1 -Comprobar` termina con error → avisar al usuario; no re-sincronizar a mano.
```

La viñeta "Onboarding de agentes no-Claude" queda igual.

**f) `### Copia versionada en el repo `sdd-global-config``.** El título pasa a ser `### Fuente de las reglas: repo `sdd-global-config`` y el contenido completo de la sección a:

```text
Las reglas globales se editan solo en el repo `sdd-global-config`, en `.claude/CLAUDE.md` (ruta del repo en `$env:SDD_CONFIG_REPO`, configurada en el perfil de PowerShell igual que `OBSIDIAN_VAULT`). Las 8 reglas de ejecución del Agente se editan en `templates/fuente/fragmentos/reglas-ejecucion.md` y se regeneran.

- Todo cambio de reglas pasa por un change, su PR y el CI (regla de `tooling/config`).
- Si `$env:SDD_CONFIG_REPO` no está definida → pedir la ruta al usuario, no adivinarla.
- En una máquina nueva: clonar el repo y el vault y correr `pwsh scripts\instalar.ps1` (ver setup del README).

Orden completo ante un cambio de reglas: editar en el repo → PR y merge → `git pull` y `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1` en cada máquina, que actualiza el espejo del vault y `~/.claude`.
```

**g) `### Comandos PowerShell`.** El apartado "Sincronizar reglas globales al vault (tras modificar el CLAUDE.md global)", con su bloque de código y la línea final sobre `scripts/instalar.ps1`, se reemplaza por:

````text
**Sincronizar reglas globales al vault (tras un merge de reglas):**
```powershell
pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1
```
El espejo no se arma a mano. Para saber si está al día: `pwsh $env:SDD_CONFIG_REPO\scripts\instalar.ps1 -Comprobar`.
````

### D11. Guías

- `README.md`, párrafo "Sincronización continua": pasa a decir que la fuente de las reglas es `.claude/CLAUDE.md` de este repo, que los cambios pasan por PR y que después del merge se corre `pwsh scripts/instalar.ps1`, que actualiza el espejo del vault y `~/.claude`.
- `README.md`, párrafo de `generar-plantillas.ps1` ("El script valida que los títulos…"): pasa a decir que el script también genera el bloque de reglas de `.claude/CLAUDE.md` y que `-Comprobar` controla que su texto sea igual al fragmento.
- `docs/workflow.md` (árbol del vault, la línea larga que describe la sincronización de reglas y la tabla de archivos) y `docs/modo-de-uso.md` (árbol del vault): el espejo es "del `CLAUDE.md` del repo" y "lo leen Claude y el Agente". Donde digan que la fuente canónica es `~/.claude/CLAUDE.md` o que Claude re-sincroniza el espejo, se reemplaza por el flujo de D10 f.

## Impacto en proyectos existentes

- **Proyectos que usan el workflow:** ningún archivo de los proyectos cambia. `AGENTS.md`, `copilot-instructions.md`, `sdd-workflow.mdc` y `GEMINI.md` no cambian de texto, así que `sincronizar-proyecto.ps1 -Comprobar` sigue dando lo mismo.
- **`CLAUDE.md` de cada proyecto:** siguen remitiendo a `~/.claude/CLAUDE.md`, que sigue existiendo (como archivo de carga o como copia completa).
- **Máquinas ya instaladas:** siguen funcionando con la copia completa hasta que corran `instalar.ps1`. La primera corrida reconoce la copia vieja como `atrasado` y el espejo viejo como `atrasado`, sin pedir `-Forzar`.
- **Máquinas sin vault:** sin cambios de comportamiento.
- **Agentes no-Claude:** leen el mismo espejo; solo cambia su encabezado.
- **Este repo:** `.claude/CLAUDE.md` se carga también como instrucciones de proyecto, así que acá Claude ve las reglas dos veces (ya pasaba antes del change).

## Impacto en el sistema

**Componentes afectados:** el espejo del vault (`_global/reglas-globales.md`, que pasa a ser lo que lee Claude), `~/.claude/CLAUDE.md` de cada máquina (pasa a ser un archivo de carga), el workflow `.github/workflows/plantillas.yml` (no cambia de texto, pero su control pasa a ser más estricto) y las sesiones de Claude en todos los proyectos (cargan las reglas por otro camino).

**Atributos de calidad:**
- mantenibilidad (alta): mejora; el texto de las reglas del Agente deja de estar duplicado a mano y el espejo deja de pisarse sin comparar — Verificación: S01, S21, S09 y S14.
- disponibilidad (no declarada): si el vault falta o no cargó, Claude puede iniciar sin reglas; se cubre con la copia completa sin vault (S05, S30) y con la instrucción del archivo de carga (S04).

**Decisiones de arquitectura:** ADR nuevo: 0002. Reemplaza a: 0001.

**Deuda técnica:**
- paga: "las reglas del Agente siguen escritas dos veces; el CI solo compara los títulos".
- agrega: las reglas llegan a otra máquina con el pull del vault, pero las skills y los comandos solo con `instalar.ps1`; pueden quedar desparejos.
- descubre: en este repo `.claude/CLAUDE.md` se carga dos veces (global y de proyecto).

## ADR

```markdown
# 0002. Reglas en una sola fuente y carga de Claude desde el vault

Estado: aceptada
Fecha: 2026-11-12
Change: reglas-fuente-unica-y-carga-desde-vault
Reemplaza a: 0001

## Contexto

El ADR 0001 dejó las plantillas del Agente generadas desde `templates/fuente/` con PowerShell 7, pero decidió no generar el `CLAUDE.md`: sus 8 reglas de ejecución quedaron escritas a mano en tercera persona y el CI solo comparaba los títulos. Los dos textos ya diferían en la redacción y nada avisaba si divergían en el fondo. Además, Claude leía las reglas desde `~/.claude/CLAUDE.md` y el Agente desde el espejo del vault, y `instalar.ps1` pisaba el espejo sin compararlo.

## Alternativas

- **Dejar las dos redacciones y comparar solo títulos:** es lo que había; no detecta un cambio de fondo en una sola copia.
- **Redactar el fragmento en infinitivo neutral:** obliga a reescribir las cuatro plantillas y sus tests; la segunda persona ya sirve para el Agente y Claude la entiende igual.
- **Generar el `CLAUDE.md` entero desde un esqueleto:** mueve todo el archivo a `templates/fuente/` por 8 líneas compartidas.
- **Editar las reglas en el vault:** el vault se pushea directo, sin PR ni CI, y el generador y sus tests viven en el repo.
- **Que Claude siga leyendo de `~/.claude/CLAUDE.md`:** mantiene dos caminos para el mismo texto y obliga a instalar en cada máquina para ver reglas nuevas.
- **Acceso directo (junction) de `~/.claude` al vault:** suma un objeto que el manifiesto no ve y que los tests no pueden crear sin permisos.

## Decisión

Se mantiene del ADR 0001: las partes compartidas viven en `templates/fuente/`, `scripts/generar-plantillas.ps1` (PowerShell 7, sin librerías externas) genera las plantillas y los comandos, `-Comprobar` hace fallar el CI ante diferencias, y la instalación por máquina y la sincronización por proyecto son scripts con chequeo de cambios locales.

Cambia: las 8 reglas de ejecución del Agente se escriben solo en `templates/fuente/fragmentos/reglas-ejecucion.md`. El generador las pega en `.claude/CLAUDE.md` dentro de un bloque entre marcas y `-Comprobar` compara el texto completo. El repo `sdd-global-config` es la única fuente de las reglas. Con vault, `instalar.ps1` deja en `~/.claude/CLAUDE.md` un archivo que importa el espejo del vault, y Claude y el Agente leen el mismo archivo. `instalar.ps1` es el único que escribe el espejo: lo compara antes, frena si fue editado a mano o si el repo local está atrasado, y tiene un modo `-Comprobar`. Sin vault instala la copia completa.

## Consecuencias

- Positivas: una regla del Agente se edita en un solo archivo; cualquier diferencia de texto falla en el PR; Claude y el Agente leen el mismo archivo; las reglas llegan a otra máquina con el pull del vault; el espejo no se pisa ni se desvía en silencio.
- Negativas: el bloque del `CLAUDE.md` no se edita a mano; Claude depende del vault para cargar las reglas (se mitiga con la instrucción del archivo de carga y con la copia completa sin vault); la ruta del vault queda escrita en `~/.claude/CLAUDE.md` de cada máquina; las skills siguen llegando solo con `instalar.ps1` y pueden quedar desparejas con las reglas; el import `@` es un mecanismo de Claude Code que puede cambiar.
```

## Ubicación de archivos

| Archivo nuevo | Carpeta declarada |
|---|---|
| `docs/adr/0002-reglas-en-una-fuente-y-carga-desde-el-vault.md` | `docs/` (permitida sin declarar) |

No se crean carpetas. Los tests nuevos van dentro de `tests/generar-plantillas.Tests.ps1` y `tests/instalar.Tests.ps1`, que ya existen. Si hace falta una función compartida, va en `scripts/comun.ps1`.

## Security Layer

Tipo de proyecto: `tooling`.

- Los artefactos modificados son instrucciones para IA y no exponen secrets ni rutas absolutas sensibles: la ruta del vault se escribe solo en `~/.claude/CLAUDE.md` de cada máquina al instalar, nunca en el repo — Verificación: revisión del diff: ninguna ruta `C:\Users`, `D:\` ni nombre de usuario en `scripts/`, `tests/`, `templates/`, `.claude/CLAUDE.md` ni `docs/`.
- Los scripts no ejecutan texto leído de archivos — Verificación: revisión del diff: sin `Invoke-Expression` ni `iex` en `scripts/` y `tests/`.
- Los tests no escriben en el `$HOME` real ni en el vault real — Verificación: revisión del diff: todo test de `instalar.ps1` pasa `-Destino` a una carpeta temporal y `-Vault` a una carpeta temporal o `-SinVault`.
- El espejo no se sobrescribe sin respaldo cuando tiene cambios — Verificación: S09 y S10.
- Cambio al `CLAUDE.md` global en commit separado con descripción del impacto — Verificación: revisión del diff: el commit de `.claude/CLAUDE.md` no incluye scripts ni `openspec/`.
- El commit del vault incluye solo `_global/reglas-globales.md` — Verificación: S29.
- Datos personales: no aplica; `## Datos` no declara ninguno.

## Test Plan

Comando: `pwsh -NoProfile -File tests/ejecutar.ps1` (timeout 5 min). Se corre la suite completa: el change toca `.claude/CLAUDE.md`, que leen tests de varios archivos.

Cada test automático lleva el marcador `# test-plan: reglas-fuente-unica-y-carga-desde-vault/<ID>` arriba del `Probar`. Los tests existentes que cubren un escenario suman este marcador sin perder los que ya tienen.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Bloque generado / Bloque generado desde el fragmento | auto | `tests/generar-plantillas.Tests.ps1` |
| S02 | Bloque generado / El resto del CLAUDE.md no cambia | auto | `tests/generar-plantillas.Tests.ps1` |
| S03 | Bloque generado / Marcas faltantes | auto | `tests/generar-plantillas.Tests.ps1` |
| S04 | Carga desde el vault / Archivo de carga con vault | auto | `tests/instalar.Tests.ps1` |
| S05 | Carga desde el vault / Copia completa sin vault | auto | `tests/instalar.Tests.ps1` |
| S06 | Carga desde el vault / Ruta del vault con espacios | auto | `tests/instalar.Tests.ps1` |
| S07 | Carga desde el vault / Copia completa anterior pasa a archivo de carga | auto | `tests/instalar.Tests.ps1` |
| S08 | Protección del espejo / Espejo ya igual | auto | `tests/instalar.Tests.ps1` |
| S09 | Protección del espejo / Espejo editado a mano | auto | `tests/instalar.Tests.ps1` |
| S10 | Protección del espejo / Forzar con respaldo del espejo | auto | `tests/instalar.Tests.ps1` |
| S11 | Protección del espejo / Espejo atrasado | auto | `tests/instalar.Tests.ps1` |
| S12 | Protección del espejo / Repo atrasado | auto | `tests/instalar.Tests.ps1` |
| S13 | Comprobación / Instalación al día | auto | `tests/instalar.Tests.ps1` |
| S14 | Comprobación / Espejo distinto | auto | `tests/instalar.Tests.ps1` |
| S15 | Comprobación / Destino atrasado | auto | `tests/instalar.Tests.ps1` |
| S16 | Fuente única / Texto de las reglas globales | auto | `tests/instalar.Tests.ps1` |
| S17 | Fuente única / Texto de las guías | auto | `tests/instalar.Tests.ps1` |
| S18 | Control de desincronización / Plantilla editada a mano | auto: test existente `sincronizar-reglas/S03` | `tests/generar-plantillas.Tests.ps1` |
| S19 | Control de desincronización / Comando editado a mano | auto: test existente "S07 comando editado a mano…" | `tests/generar-comandos.Tests.ps1` |
| S20 | Control de desincronización / Skill editada sin regenerar | auto: test existente "S08 skill editada sin regenerar…" | `tests/generar-comandos.Tests.ps1` |
| S21 | Control de desincronización / Bloque de reglas editado a mano | auto | `tests/generar-plantillas.Tests.ps1` |
| S31 | Control de desincronización / Reglas del CLAUDE.md con otro título | auto: se ajusta `sincronizar-reglas/S04` (la salida nombra `.claude/CLAUDE.md`) | `tests/generar-plantillas.Tests.ps1` |
| S22 | Control de desincronización / Todo sincronizado | auto: test existente `sincronizar-reglas/S05` | `tests/generar-plantillas.Tests.ps1` |
| S23 | Control de desincronización / Workflow de PR | manual: leer `.github/workflows/plantillas.yml` y confirmar que no cambió en el diff | — |
| S24 | Instalación por máquina / Destino vacío | auto: test existente `sincronizar-reglas/S06` | `tests/instalar.Tests.ps1` |
| S25 | Instalación por máquina / Cambio local | auto: test existente `sincronizar-reglas/S07` | `tests/instalar.Tests.ps1` |
| S26 | Instalación por máquina / Forzar con respaldo | auto: test existente `sincronizar-reglas/S08` | `tests/instalar.Tests.ps1` |
| S27 | Instalación por máquina / Simular | auto: test existente `sincronizar-reglas/S09` | `tests/instalar.Tests.ps1` |
| S28 | Instalación por máquina / GEMINI.md con contenido propio | auto: test existente `sincronizar-reglas/S10` | `tests/instalar.Tests.ps1` |
| S29 | Espejo del vault / Espejo sincronizado | auto: se amplía `sincronizar-reglas/S11` (fuente, `commit:` y archivos del commit) | `tests/instalar.Tests.ps1` |
| S30 | Espejo del vault / Sin vault | auto: se amplía `sincronizar-reglas/S12` (copia completa) | `tests/instalar.Tests.ps1` |

Verificaciones manuales fuera de las specs:

| ID | Qué verifica | Pasos |
|---|---|---|
| M01 | El import `@` acepta la ruta del vault | Crear en el vault real un archivo de prueba `_global/prueba-import.md` con una frase única; crear en una carpeta temporal un `CLAUDE.md` con la línea `@<ruta absoluta con />/_global/prueba-import.md`; abrir Claude Code en esa carpeta y preguntar por la frase. Pegar la respuesta como evidencia y borrar los dos archivos de prueba. Si Claude no ve la frase: frenar y avisar. |
| M02 | El cambio aplica en un proyecto de prueba | Después de instalar en la máquina real, abrir Claude Code en otro proyecto y pedirle que cite la regla 3 de ejecución del Agente y el título de la primera sección de las reglas. Pegar la respuesta. |

Caracterización (correr en verde antes de tocar el código):

| ID | Archivo existente | Qué fija | Cambio intencional |
|---|---|---|---|
| C01 | `tests/generar-plantillas.Tests.ps1` | Generación de las cuatro plantillas, fragmento inexistente, plantilla editada, todo sincronizado, aviso y sección propia | El test `sincronizar-reglas/S04` (títulos distintos) sigue esperando código distinto de 0, pero su afirmación sobre la salida pasa de la lista de títulos a que nombre `.claude/CLAUDE.md` (S31). S21 cubre el caso nuevo: cambia solo el cuerpo de una regla |
| C02 | `tests/instalar.Tests.ps1` | Destino vacío, cambio local, forzar, simular, GEMINI propio, espejo y sin vault (`sincronizar-reglas/S06` a `S12`) | `sincronizar-reglas/S11`: con vault, `<Destino>/.claude/CLAUDE.md` pasa a ser el archivo de carga y el espejo tiene encabezado nuevo; lo cubren S04 y S29 |
| C03 | `tests/clasificacion-odd.Tests.ps1` | Estructura del `CLAUDE.md` (filas K1 a K10, secciones, regla 7 con excepción ODD) | Test `clasificacion-odd-sdd/S20`: la regla 7 del `CLAUDE.md` pasa a terminar con la misma oración que el fragmento (`$oracionAgente`); se actualiza esa afirmación. Lo cubre S01 |
| C04 | `tests/aclarar-k2.Tests.ps1`, `tests/generar-comandos.Tests.ps1`, `tests/sincronizar-proyecto.Tests.ps1` | Texto de K2, generación de comandos y sincronización por proyecto | Ninguno en su lógica: tienen que seguir en verde; en `tests/generar-comandos.Tests.ps1` solo se agregan los comentarios marcadores de S19 y S20 |

## Risks / Trade-offs

- [El import `@` no acepta la ruta absoluta de Windows] → M01 es la primera tarea; si falla, el Agente frena y no se implementa la Parte 2.
- [Vault viejo o ausente al abrir Claude: reglas viejas o ninguna] → instrucción en el archivo de carga, `instalar.ps1 -Comprobar` al iniciar sesión y copia completa sin vault.
- [Una máquina con el repo atrasado pisa un espejo más nuevo] → estado `repo atrasado`, que frena también con `-Forzar`.
- [Falso `con cambios locales` si el espejo lo escribió una versión del repo de otra rama] → el mensaje nombra el archivo; `-Forzar` respalda antes de reemplazar.
- [Reglas nuevas con skills viejas en otra máquina] → queda como deuda en la hoja de ruta; `instalar.ps1 -Comprobar` lo muestra en la tabla.
- [Las reglas en segunda persona dentro del `CLAUDE.md` confunden a Claude] → la línea de introducción aclara que están redactadas para el Agente.
- [`Test-EsVersionGitHistorica` recorre toda la historia y suma tiempo] → ya se usa hoy para cada archivo; se agrega una sola llamada.

## Migration Plan

1. Merge del PR.
2. En cada máquina: `git pull` en el repo y `pwsh scripts/instalar.ps1`. No hace falta `-Forzar`.
3. Abrir una sesión nueva de Claude Code y confirmar que las reglas cargan (M02).

Rollback: revertir el merge y correr `pwsh scripts/instalar.ps1`. El archivo de carga instalado coincide con el manifiesto, así que se reemplaza por la copia completa sin `-Forzar`. El espejo con encabezado nuevo se reconoce por su cuerpo.

## Open Questions

- Si el import `@` sigue funcionando igual en versiones futuras de Claude Code. No cambia las specs ni las tareas: la copia completa sin vault es la salida.
