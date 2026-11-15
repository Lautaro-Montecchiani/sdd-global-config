# 0005. instalar.ps1 escribe la barra de estado de cada CLI

Estado: aceptada
Fecha: 2026-11-14
Change: statusline-instalable

## Contexto

La barra de estado de Claude Code vivía en `.claude/settings.json` del repo y solo aparecía dentro de `sdd-global-config`. La de Antigravity CLI se instalaba a mano desde una plantilla con placeholder, y sus scripts los generaba el CLI en cada máquina a partir de un prompt; la spec prohibía versionarlos. Copilot CLI acepta una barra en `~/.copilot/settings.json` y el workflow no la instalaba. Cursor CLI no documenta oficialmente su `statusLine`. `scripts/instalar.ps1` ya era el único camino para dejar una máquina igual a otra (reglas, skills y comandos), pero no escribía en la configuración de ningún CLI.

## Alternativas

- **Seguir con la instalación a mano y el prompt de generación:** descartada. Cada máquina queda distinta, la barra de Antigravity se apagó sola en una máquina sin que nada lo detectara, y la de Claude no aparecía fuera del repo.
- **Instalar la barra en el `settings.json` de cada proyecto (con `sincronizar-proyecto.ps1`):** descartada. La barra es de la persona y no del proyecto, y sumaría un archivo más a cada uno de los 19 proyectos.
- **Que `instalar.ps1` reemplace siempre el `statusLine`:** descartada. Pisa la barra propia de quien ya tiene una.
- **Sumar Cursor CLI ahora:** descartada. Sin claves documentadas oficialmente ni un CLI instalado para probar, habría que inventar el formato (issue #63).

## Decisión

`scripts/instalar.ps1` escribe la clave `statusLine` en el `settings.json` de usuario de cada CLI presente en la máquina (Claude Code siempre; Antigravity CLI y Copilot CLI si existe su carpeta), y solo esa clave. Claude y Copilot apuntan, con la ruta absoluta del repo en esa máquina, al mismo `.claude/statusline.sh`. Los scripts de Antigravity se versionan en `templates/antigravity/` y se instalan como el resto de los archivos, con manifiesto y control de cambios locales. Una barra que no es la del repo se respeta y se avisa; un `settings.json` que no es JSON válido no se escribe. `-Comprobar` falla si una barra falta o quedó vieja.

## Consecuencias

- Positivas: la barra aparece en todos los proyectos y en los tres CLI con un solo `instalar.ps1`; una barra apagada o vieja se detecta al iniciar sesión; hay un único script para Claude y Copilot; la configuración propia de la persona (permisos, modelo, barra propia) no se pierde.
- Negativas: `instalar.ps1` pasa a escribir archivos de configuración de herramientas de terceros, cuyo formato puede cambiar (en especial el de Copilot, documentado solo en parte); la barra depende de que el repo no se mueva de carpeta (si se mueve, `-Comprobar` la marca `atrasado` y se arregla con `instalar.ps1`); Cursor queda sin barra hasta #63.
