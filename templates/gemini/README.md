# Plantilla de Gemini CLI (y reglas globales de Antigravity)

Reglas globales de ejecución del Agente para **Gemini CLI** y **Antigravity CLI**, que ambos cargan desde `~/.gemini/GEMINI.md`.

## Qué archivos trae

| Archivo | Destino | Alcance |
|---|---|---|
| `GEMINI.md` | `~/.gemini/GEMINI.md` | global por máquina (una sola vez; fusionar al principio si ya existe con contenido previo) |

## Instalación

```powershell
# Instalar el contexto global del Agente (una sola vez por máquina; fusionar si ya existe)
New-Item -ItemType Directory -Force "$env:USERPROFILE\.gemini" | Out-Null
cp templates\gemini\GEMINI.md "$env:USERPROFILE\.gemini\GEMINI.md"
```

## Carpetas de confianza en Gemini CLI

La documentación oficial de Gemini CLI confirma el soporte de carpetas de confianza mediante `security.folderTrust.enabled` en `~/.gemini/settings.json` (la lista de carpetas confiables se guarda en `~/.gemini/trustedFolders.json`):

```json
{
  "security": {
    "folderTrust": {
      "enabled": true
    }
  }
}
```

Referencias oficiales:
- Configuración: [geminicli.com/docs/reference/configuration.md](https://geminicli.com/docs/reference/configuration.md)
- Carpetas de confianza: [geminicli.com/docs/cli/trusted-folders/](https://geminicli.com/docs/cli/trusted-folders/)
