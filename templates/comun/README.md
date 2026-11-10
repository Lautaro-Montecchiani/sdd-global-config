# Plantilla común multi-agente (`AGENTS.md`)

Instrucciones por proyecto en formato estándar **`AGENTS.md`**, leído por múltiples agentes constructores (**Codex**, **Cursor**, **Jules**, **Antigravity**, **Aider**, **Zed**, **Copilot coding agent** y otros).

El archivo `AGENTS.md` se genera desde la fuente única en `templates/fuente/` con `scripts/generar-plantillas.ps1`. No se edita a mano.

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `AGENTS.md` | `{proyecto}\AGENTS.md` | por proyecto (en la raíz de cada repositorio que se suma al workflow) |

## Instalación y sincronización

Para instalar o actualizar las reglas en el proyecto destino, ejecutar desde la raíz del proyecto:

```powershell
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes comun
```

El script conserva cualquier personalización debajo de `## Propio del proyecto`. Si se suma un agente que exija otro nombre de archivo en la raíz del proyecto, copiar `AGENTS.md` con el nombre que esa herramienta pida.
