## 1. Caracterización (antes de tocar nada)

- [x] 1.1 Copiar los nueve archivos actuales de `.claude/commands/` (`opsx/apply.md`, `opsx/archive.md`, `opsx/explore.md`, `opsx/propose.md`, `opsx/verify.md`, `odd/start.md`, `odd/verify.md`, `odd/close.md`, `odd.md`) a `tests/datos/comandos-antes/` con la misma ruta relativa, sin modificarlos.
- [x] 1.2 Escribir en `tests/generar-comandos.Tests.ps1` los tests C01 y C02 del Test Plan del design (marcadores `test-plan: generar-comandos-desde-skills/C01` y `/C02`), que comparan `tests/datos/comandos-antes/` con `.claude/commands/`. Correr `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar la salida en verde (todavía no hay generación: comparan los comandos de antes con ellos mismos).
- [x] 1.3 C03: correr `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar en verde los tests existentes de `tests/generar-plantillas.Tests.ps1`, `tests/clasificacion-odd.Tests.ps1` y `tests/aclarar-k2.Tests.ps1`.

## 2. Tests nuevos (test primero: tienen que fallar)

- [x] 2.1 Escribir en `tests/generar-comandos.Tests.ps1` los tests S01 a S10 del Test Plan del design, con su marcador `test-plan: generar-comandos-desde-skills/<ID>`. Los que generan trabajan sobre una copia del repo en una carpeta temporal (`Con-CarpetaTemporal` de `tests/apoyo.ps1`). Correr `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar la salida con S01 a S09 en rojo (S10 puede pasar de entrada porque fija una ausencia; anotarlo).

## 3. Reconciliación de las skills (commit separado)

- [x] 3.1 `skills/openspec-apply-change/SKILL.md`: reemplazar la primera línea del cuerpo según D5 del design.
- [x] 3.2 `skills/openspec-explore/SKILL.md`: agregar el bloque **Input** y la línea "If the user mentioned a specific change name, read its artifacts for context." según D5, en el mismo lugar que en `.claude/commands/opsx/explore.md`.
- [x] 3.3 `skills/openspec-verify-change/SKILL.md`: desindentar **Tool**, **Nivel**, **Tamaño** (con sus sub-viñetas) y **Scope** en `**Architecture Verification**` según D5.
- [x] 3.4 Commitear 3.1 a 3.3 solos, con un mensaje que diga qué cambia en cada máquina al reinstalar (`fix: reconciliar skills con sus comandos` y trailer `Spec-ID: generar-comandos-desde-skills`).

## 4. Generación

- [x] 4.1 `scripts/comun.ps1`: agregar una función que recibe el texto de una skill y devuelve el cuerpo sin frontmatter, y otra que recibe el texto y un título y devuelve la sección `## <título>` respetando bloques de código (D2, D3). Las dos solo reciben y devuelven texto.
- [x] 4.2 Crear `templates/fuente/comandos/opsx/apply.md`, `opsx/archive.md`, `opsx/explore.md`, `opsx/propose.md`, `opsx/verify.md`, `odd/start.md`, `odd/verify.md` y `odd/close.md` con el frontmatter actual de cada comando (copiado sin cambios) y sus marcas `incluir-skill` según la tabla del Context y D2 del design.
- [x] 4.3 `scripts/generar-plantillas.ps1`: agregar `$mapeoComandos` (incluye `odd/start.md` → `.claude/commands/odd/start.md` y `.claude/commands/odd.md`), la generación en memoria con el aviso del D4, el error sin escribir nada del D3 y la comparación de comandos en `-Comprobar`. Actualizar el comentario de cabecera del script.
- [x] 4.4 Correr `pwsh scripts/generar-plantillas.ps1`, que regenera los nueve archivos de `.claude/commands/`. Correr `pwsh -NoProfile -File tests/ejecutar.ps1` y pegar S01 a S10, C01 a C03 y el resto de la suite en verde.
- [x] 4.5 Correr `pwsh -NoProfile -File scripts/generar-plantillas.ps1 -Comprobar` y `pwsh -NoProfile -File scripts/sincronizar-proyecto.ps1 -Proyecto . -Agentes copilot -Comprobar` y pegar las dos salidas con código 0.

## 5. Documentación

- [x] 5.1 `docs/arquitectura/vision.md`: en `## Componentes`, cambiar la línea de `.claude/commands/` a "comandos de Claude Code (`opsx/` para SDD, `odd/` y `odd.md` para ODD), generados desde las skills con `scripts/generar-plantillas.ps1` (encabezados en `templates/fuente/comandos/`)"; en `templates/`, sumar que `templates/fuente/comandos/` tiene los encabezados de los comandos; en `## Hoja de ruta`, quitar la línea `[media] cada comando de .claude/commands/ repite el texto de su skill...`; y en la línea `[baja] la ficha de este repo no declara...`, dejar solo la parte de `nivel` (`## Arquitectura` no declara `nivel` — propuesta: correr `/arquitectura`), porque la ficha ya está completa.
- [x] 5.2 `README.md` (filas de `.claude/commands/opsx/` y `.claude/commands/odd/` de la tabla) y `docs/workflow.md` (línea "comandos `/opsx:*` con el mismo comportamiento que las skills"): decir que los comandos se generan desde las skills con `pwsh scripts/generar-plantillas.ps1` y no se editan a mano. Agregar en `CONTRIBUTING.md` que un cambio a una skill con comando se regenera con ese script antes del commit.

## 6. Prueba en un proyecto

- [x] 6.1 Verificar que el cambio aplica en un proyecto de prueba: correr `pwsh scripts/instalar.ps1 -Destino <carpeta temporal> -SinVault`, comprobar que `<carpeta temporal>/.claude/commands/opsx/apply.md` y `odd/start.md` tienen el aviso de archivo generado y el texto de la skill, y pegar la tabla de salida del script como evidencia.
