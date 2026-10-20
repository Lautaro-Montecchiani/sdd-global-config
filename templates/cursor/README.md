# Plantilla de Cursor

Instrucciones y reglas por proyecto para **Cursor** (`.cursor/rules/sdd-workflow.mdc`).

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `sdd-workflow.mdc` | `{proyecto}\.cursor\rules\sdd-workflow.mdc` | por proyecto (al sumar un proyecto al workflow o migrarlo) |

## Instalación

Desde la raíz del proyecto destino:

```powershell
New-Item -ItemType Directory -Force .cursor\rules | Out-Null
cp "$env:SDD_CONFIG_REPO\templates\cursor\sdd-workflow.mdc" .cursor\rules\sdd-workflow.mdc
```

La regla se aplica automáticamente a todas las sesiones (`alwaysApply: true`), define el rol de constructor, restringe la interacción a `/opsx-apply` y lee las reglas globales desde el vault.

## Permisos de ejecución automática (auto-run en Cursor)

Cursor administra los permisos de ejecución de comandos desde la configuración del propio IDE (Settings > Features > Terminal / Auto-run commands), por lo que no se versionan en un archivo de configuración.

Se recomienda configurar una allowlist con los comandos habituales del workflow:

- `git status`
- `git diff`
- `git branch`
- `git restore`
- `openspec`

> [!WARNING]
> **Advertencia sobre shells:** Agregar `powershell` o `cmd.exe` a la allowlist de auto-run equivale a permitir que el Agente ejecute cualquier comando sin confirmación humana. Por seguridad, no incluyas shells genéricos en la lista de comandos automáticos.

## Cómo agregar Cursor a un proyecto que ya usa Antigravity

Si un proyecto ya está iniciado en el workflow con Antigravity y querés comenzar a usar Cursor:

1. **Sumar la herramienta Cursor en OpenSpec:**  
   Ejecutá en la raíz del proyecto:
   ```bash
   openspec init --tools cursor
   ```
   Esto conserva la configuración existente en `openspec/config.yaml` y genera los comandos `/opsx-*` en `.cursor/commands/`.

2. **Copiar la regla del workflow:**
   ```powershell
   New-Item -ItemType Directory -Force .cursor\rules | Out-Null
   cp "$env:SDD_CONFIG_REPO\templates\cursor\sdd-workflow.mdc" .cursor\rules\sdd-workflow.mdc
   ```

3. **Limpieza opcional:**  
   Si el equipo deja de usar Antigravity por completo en ese proyecto, se pueden eliminar las carpetas `.agents/` (y la anterior `.agent/` si existía). Esta eliminación debe realizarse en un commit separado directamente en la rama principal (`main`/`master`). Si coexisten personas que usan Antigravity y personas que usan Cursor, ambas configuraciones deben conservarse en el repositorio.
