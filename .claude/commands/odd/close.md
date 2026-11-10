---
name: "ODD: Close"
description: Registrar el cierre del cambio ODD en el vault de Obsidian
category: Workflow
---

## Cierre (/odd:close)

**Objetivo:** Registrar el cierre del cambio ODD en el vault de Obsidian luego de que la rama `odd/<nombre>` fue mergeada en la rama principal.

### Pasos de cierre

1. **Control de merge:**
   Comprobar que la rama `odd/<nombre>` esté efectivamente mergeada en la rama principal (`git branch -r --merged` o `gh pr view`). Si la rama no está mergeada, detener la ejecución y avisar al usuario.

2. **Redacción de nota de archivo en el vault:**
   Crear la nota `$vault\projects\$p\archive\AAAA-MM-DD-odd-<nombre>.md` con el siguiente formato:

```markdown
---
tipo: odd
change: <nombre>
proyecto: <proyecto>
fecha: AAAA-MM-DD
status: cerrado
pr: <url del PR o "sin PR">
---

## Objetivo
<copiado del documento>

## Qué cambió
- <archivo>: <una línea>

## Spec
<capability> modificada — openspec/changes/archive/AAAA-MM-DD-odd-<nombre>/ (o "sin cambios de spec")

## Evidencia
- CA1: <resumen en una línea>

## Clasificación
<copiada del documento, incluido cualquier criterio pasado por alto>

## Documento completo
`docs/odd/<nombre>.md` en el repo del proyecto
```
   *Nota de seguridad:* La nota no debe contener código completo ni credenciales o valores sensibles.

3. **Actualización del índice del vault:**
   Agregar el enlace a la nota en `$vault\projects\$p\_index.md`.

4. **Actualización de arquitectura en el vault:**
   Si el diff del ODD modificó `docs/arquitectura/vision.md`, reescribir `$vault\projects\$p\arquitectura.md` con el mismo formato y las mismas fuentes que el archive SDD: frontmatter (`project`, `updated`) y las secciones `## Nivel` (`nivel` de `## Arquitectura` de `openspec/config.yaml`, o "sin evaluar"), `## Atributos de calidad` (ítems de `## Calidad`, o "sin declarar"), `## Decisiones vigentes` (número y título de los ADRs con `Estado: aceptada` en `docs/adr/`, o "ninguna") y `## Deuda prioritaria` (hasta 3 ítems de `## Hoja de ruta` de `docs/arquitectura/vision.md`, primero los `alta`, o "ninguna"), seguidas de la línea `Documento completo: docs/arquitectura/vision.md en el repo`. Sin código, credenciales ni datos personales. Si no se modificó la visión, conservar `arquitectura.md` sin cambios.

5. **Actualización de `context.md`:**
   En `$vault\projects\$p\context.md`:
   - `## Estado actual`: "sin change activo" (o el change que continúe activo).
   - `## Último change`: "ODD `<nombre>` (AAAA-MM-DD)".
   - `## Decisiones recientes`: registrar entrada únicamente si el ODD documentó una decisión relevante.

6. **Commit y push del vault:**
   Commitear y pushear los cambios en el vault:
   ```powershell
   git -C $vault add .
   git -C $vault commit -m "chore: $p — odd-close $nombre"
   git -C $vault push
   ```
   Si el push falla, continuar e informar al usuario.

7. **Sin cambios en el repositorio del proyecto:**
   No realizar commits ni push en el repositorio del proyecto. El documento en el proyecto permanece con `estado: verificado`. El estado cerrado reside en el vault.
   Si el ODD tuvo cambio de spec, recomendar al usuario correr `/srs-generate` (no ejecutarlo automáticamente). Si no tuvo cambio de spec, no se ofrece generación de SRS.