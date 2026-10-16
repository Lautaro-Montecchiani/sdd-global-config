# Plantilla de GitHub Copilot

Instrucciones por proyecto para **GitHub Copilot** (`.github/copilot-instructions.md`).

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `copilot-instructions.md` | `{proyecto}\.github\copilot-instructions.md` | por proyecto (al sumar un proyecto al workflow) |

## Instalación

Desde la raíz del proyecto destino:

```powershell
New-Item -ItemType Directory -Force .github | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\copilot\copilot-instructions.md" .github\copilot-instructions.md
```

Si el proyecto ya tiene un `.github/copilot-instructions.md` propio, fusionar la sección "Workflow SDD" al principio del archivo existente en lugar de reemplazarlo.
