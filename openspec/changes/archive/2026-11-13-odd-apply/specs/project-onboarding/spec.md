# Spec Delta

## ADDED Requirements

### Requirement: Instalación del comando odd-apply
`scripts/instalar.ps1` SHALL instalar la skill `odd-apply` en `<Destino>/.gemini/skills/odd-apply/SKILL.md` solo si existe `<Destino>/.gemini`, con el mismo control de cambios locales y manifiesto que `GEMINI.md`. `scripts/sincronizar-proyecto.ps1` SHALL copiar el comando a `.cursor/commands/odd-apply.md` si sincroniza Cursor y a `.github/prompts/odd-apply.prompt.md` si sincroniza Copilot, sin tocar otros archivos de esas carpetas. `-Comprobar` SHALL incluirlos.

#### Scenario: Máquina con Antigravity
- **WHEN** se corre `pwsh scripts/instalar.ps1 -Destino <tmp>` con `<tmp>/.gemini` existente
- **THEN** existe `<tmp>/.gemini/skills/odd-apply/SKILL.md` igual a `templates/antigravity/skills/odd-apply/SKILL.md`
- **AND** el manifiesto lo registra

#### Scenario: Máquina sin Antigravity
- **WHEN** se corre `pwsh scripts/instalar.ps1 -Destino <tmp>` sin `<tmp>/.gemini`
- **THEN** no se crea ninguna carpeta `.gemini`

#### Scenario: Proyecto con Copilot y prompts de OpenSpec
- **WHEN** se sincroniza con `-Agentes copilot` un proyecto que ya tiene `.github/prompts/opsx-apply.prompt.md`
- **THEN** existe `.github/prompts/odd-apply.prompt.md` igual a la plantilla
- **AND** `opsx-apply.prompt.md` no cambia

#### Scenario: Proyecto con Cursor
- **WHEN** se sincroniza con `-Agentes cursor`
- **THEN** existe `.cursor/commands/odd-apply.md` igual a la plantilla

#### Scenario: Comprobar con el comando atrasado
- **WHEN** el proyecto tiene una versión vieja de `.cursor/commands/odd-apply.md` y se corre la sincronización con `-Comprobar`
- **THEN** termina con código distinto de 0 y nombra ese archivo
