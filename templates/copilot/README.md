# Plantilla de GitHub Copilot

Instrucciones por proyecto para **GitHub Copilot** (`.github/copilot-instructions.md`).

El archivo `copilot-instructions.md` se genera desde la fuente única en `templates/fuente/` con `scripts/generar-plantillas.ps1`. No se edita a mano.

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `copilot-instructions.md` | `{proyecto}\.github\copilot-instructions.md` | por proyecto (al sumar un proyecto al workflow) |

## Instalación y sincronización

Para instalar o actualizar las reglas en el proyecto destino, ejecutar desde la raíz del proyecto:

```powershell
pwsh "$env:SDD_CONFIG_REPO\scripts\sincronizar-proyecto.ps1" -Proyecto . -Agentes copilot
```

El script conserva cualquier personalización existente debajo de `## Propio del proyecto`. Si el archivo contenía cambios fuera de esa sección, el script frena para evitar sobrescrituras no deseadas.
