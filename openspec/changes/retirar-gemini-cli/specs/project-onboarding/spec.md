# Spec Delta

## MODIFIED Requirements

### Requirement: El setup por máquina se hace por agente
El setup por máquina de `README.md` y `docs/modo-de-uso.md` SHALL tener pasos separados para cada agente (Antigravity: `GEMINI.md` y `settings.json`; Cursor: ejecución automática) e indicar que cada persona sigue solo los del agente que usa. El paso de Antigravity SHALL copiar `templates\antigravity\GEMINI.md` a `~/.gemini/GEMINI.md`. El repositorio SHALL seguir versionando las plantillas de Antigravity.

#### Scenario: Pasos separados por agente
- **WHEN** se lee el setup por máquina de `README.md` y de `docs/modo-de-uso.md`
- **THEN** hay un bloque de pasos para Antigravity y otro para Cursor
- **AND** se indica seguir solo el del agente que se usa

#### Scenario: Plantillas de Antigravity presentes
- **WHEN** se listan los archivos de `templates/`
- **THEN** existen `templates/antigravity/GEMINI.md` y `templates/antigravity/settings.json`

#### Scenario: Ruta nueva en el setup
- **WHEN** se busca el paso que instala `GEMINI.md` en `README.md` y `docs/modo-de-uso.md`
- **THEN** copia `templates\antigravity\GEMINI.md` a `~/.gemini/GEMINI.md`
- **AND** ninguna guía menciona `templates\gemini\`
