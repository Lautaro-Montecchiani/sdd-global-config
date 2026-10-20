# Spec Delta

## ADDED Requirements

### Requirement: El vault documenta la carpeta de resúmenes del apply
Las guías SHALL describir la carpeta `projects/<proyecto>/apply/` del vault (dónde el Agente deja la copia del resumen del apply) e indicar que `projects/*/apply/` está en el `.gitignore` del vault, por lo que no se sube a git y el verify solo se corre en la máquina del apply. El `CLAUDE.md` global SHALL incluir `apply/` en la estructura del vault.

#### Scenario: Carpeta documentada
- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** mencionan `projects/<proyecto>/apply/` y su exclusión de git

#### Scenario: Estructura del vault en el CLAUDE.md
- **WHEN** se lee la estructura del vault del `CLAUDE.md` global
- **THEN** incluye `apply\` bajo cada proyecto, marcada como local y no versionada
