## 1. Setup por máquina

- [x] 1.1 Editar `README.md` (setup, paso 3): copiar todas las skills de `skills\` a `~/.claude/skills/` y los comandos de `.claude\commands\opsx\` a `~/.claude/commands/opsx/`; sumar `skills/openspec-explore/` y `.claude/commands/opsx/` a la tabla "Qué contiene"
- [x] 1.2 Editar `docs\workflow.md` (Setup inicial, paso 1): el mismo cambio de instalación de skills y comandos, y actualizar la lista de skills del repo

## 2. Onboarding sin claude en `--tools`

- [x] 2.1 Editar `docs\workflow.md` (Onboarding: proyecto nuevo): `openspec init --tools <agente>`, eliminar el paso de "liberar el slot de apply" y renumerar
- [x] 2.2 Editar `docs\workflow.md` (Onboarding: proyecto existente sin OpenSpec): `openspec init --tools <agente>` y eliminar el paso de borrar la skill de apply
- [x] 2.3 Editar `docs\workflow.md` (Onboarding: proyecto existente con OpenSpec): reemplazar el paso por el procedimiento de limpieza de `.claude\commands\opsx\` y `.claude\skills\openspec-*`, con la indicación de commitear aparte desde la rama principal; ajustar la "Nota importante"
- [x] 2.4 Editar `docs\modo-de-uso.md` (Inicio de proyecto): `openspec init --tools <agente>`, reemplazar el Paso 2 por la sección de proyectos con copias locales, renumerar los pasos y corregir la referencia al "paso 5"
- [x] 2.5 Editar `docs\modo-de-uso.md` (Setup por máquina): instalación de skills y comandos globales
- [x] 2.6 Regenerar `docs\modo-de-uso.docx` desde `docs\modo-de-uso.md`, generando primero a un archivo temporal y comparando con el actual

## 3. Verificación

- [x] 3.1 Confirmar con un script en archivo que ningún `openspec init` de `README.md`, `docs\workflow.md` y `docs\modo-de-uso.md` incluye `claude` en `--tools` y que no queda el paso de "liberar el slot"
- [x] 3.2 Confirmar con un script en archivo que el setup de `README.md` y `docs\workflow.md` cubre todas las skills de `skills\` y los cinco comandos de `.claude\commands\opsx\`
- [x] 3.3 Confirmar que las guías y el `.docx` no contienen el nombre de usuario ni rutas de unidad reales
- [x] 3.4 Verificar que el cambio aplica en un proyecto de prueba: en una carpeta temporal ejecutar `openspec init --tools antigravity` y `openspec update`, y confirmar que existen las skills del Agente y que no existe `.claude\`; luego simular un proyecto con copias locales, eliminarlas y confirmar que `openspec update` no las recrea
