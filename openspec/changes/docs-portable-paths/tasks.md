## 1. Reemplazar las rutas absolutas en los documentos fuente

- [ ] 1.1 Editar `docs\modo-de-uso.md` (línea 10): reemplazar el `cd` con la ruta absoluta local (`C:\Users\<usuario>\Desktop\Proyectos\{nombre-proyecto}`) por `cd "{ruta-del-proyecto}"`
- [ ] 1.2 Editar `docs\workflow.md` (línea 63): reemplazar la ruta absoluta local de `config.json` por `$env:APPDATA\openspec\config.json`

## 2. Regenerar la versión derivada

- [ ] 2.1 Regenerar `docs\modo-de-uso.docx` desde `docs\modo-de-uso.md` (`ConvertFrom-Markdown` + Word COM): generar primero a un archivo temporal, comparar cantidad de párrafos y tamaño con el `.docx` actual y recién entonces reemplazarlo

## 3. Verificación

- [ ] 3.1 Confirmar que `docs\modo-de-uso.md` y `docs\workflow.md` no contienen `C:\Users` (búsqueda de texto)
- [ ] 3.2 Confirmar que el contenido de `docs\modo-de-uso.docx` contiene `{ruta-del-proyecto}` y no contiene `C:\Users`
- [ ] 3.3 Confirmar con `git diff` que los únicos cambios son las 2 líneas de texto de los `.md` y el `.docx` regenerado
- [ ] 3.4 Verificar que el cambio aplica en un proyecto de prueba: siguiendo el Paso 1 de `docs\modo-de-uso.md` en una carpeta de prueba, reemplazar `{ruta-del-proyecto}` por esa ruta y confirmar que `openspec init` corre sin otros ajustes
