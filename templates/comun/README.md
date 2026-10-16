# Plantilla común multi-agente (`AGENTS.md`)

Instrucciones por proyecto en formato estándar **`AGENTS.md`**, leído por múltiples agentes constructores (**Codex**, **Cursor**, **Jules**, **Antigravity**, **Aider**, **Zed**, **Copilot coding agent** y otros).

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `AGENTS.md` | `{proyecto}\AGENTS.md` | por proyecto (en la raíz de cada repositorio que se suma al workflow) |

## Instalación

Desde la raíz del proyecto destino:

```powershell
cp "$env:SDD_CONFIG_REPO\templates\comun\AGENTS.md" AGENTS.md
```

Si se suma un agente que exija otro nombre de archivo en la raíz del proyecto, copiar `templates/comun/AGENTS.md` con el nombre que esa herramienta pida.
