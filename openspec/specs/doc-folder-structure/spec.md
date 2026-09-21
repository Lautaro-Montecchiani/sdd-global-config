# doc-folder-structure Specification

## Purpose
TBD - created by archiving change doc-folder-business-rules. Update Purpose after archive.
## Requirements
### Requirement: Carpeta `docs/` existe en la raíz del proyecto
El proyecto SHALL tener un directorio `docs/` en la raíz como carpeta canónica para toda la documentación de reglas de negocio del workflow SDD Híbrido.

#### Scenario: Directorio creado
- **WHEN** se inspecciona la raíz del repositorio
- **THEN** existe el directorio `docs/`

### Requirement: `workflow.md` reside en `docs/`
El archivo de workflow SDD Híbrido SHALL estar ubicado en `docs/workflow.md`. El archivo `WORKFLOW.md` en la raíz SHALL ser eliminado.

#### Scenario: Workflow accesible desde `docs/`
- **WHEN** se navega a `docs/workflow.md`
- **THEN** el archivo contiene el contenido completo del workflow SDD Híbrido (roles, onboarding, flujo por change, capa de seguridad)

#### Scenario: Archivo raíz eliminado
- **WHEN** se inspecciona la raíz del repositorio
- **THEN** no existe `WORKFLOW.md` en la raíz

### Requirement: La guía de uso reside en `docs/`
La guía de uso SHALL estar ubicada en `docs/modo-de-uso.md` (fuente) y `docs/modo-de-uso.docx` (versión derivada). La carpeta `Modo de Uso/` SHALL ser eliminada.

#### Scenario: Guía accesible desde `docs/`
- **WHEN** se navega a `docs/modo-de-uso.md` y a `docs/modo-de-uso.docx`
- **THEN** ambos archivos existen y son los originales de la guía de uso del workflow

#### Scenario: Carpeta origen eliminada
- **WHEN** se inspecciona la raíz del repositorio
- **THEN** no existe el directorio `Modo de Uso/`

### Requirement: `README.md` referencia `docs/` como punto de entrada
El `README.md` SHALL incluir una sección que dirija al lector a `docs/` para la documentación detallada del workflow y reglas de negocio.

#### Scenario: README actualizado
- **WHEN** se lee `README.md`
- **THEN** contiene referencias a `docs/workflow.md` y a `docs/modo-de-uso.md`
- **AND** no quedan referencias a `WORKFLOW.md` ni a `Modo de Uso/` fuera de `docs/`

