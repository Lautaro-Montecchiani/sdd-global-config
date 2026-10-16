# Software Requirements Specification

| Campo | Valor |
|---|---|
| Proyecto | sdd-global-config |
| Fecha de generación | 16/10/2026 |
| Estado | completo |
| Generado por | skill `srs-generate` (modo agrupado: 112 casos de uso, umbral ~40) |

## Tabla de contenidos

- [1. Introducción](#1-introducción)
  - [1.1 Alcance](#11-alcance)
  - [1.2 Objetivos](#12-objetivos)
- [2. Información del Dominio del Problema](#2-información-del-dominio-del-problema)
  - [2.1 Introducción al dominio](#21-introducción-al-dominio)
  - [2.2 Glosario de Términos](#22-glosario-de-términos)
- [3. Necesidades de Negocio](#3-necesidades-de-negocio)
  - [3.1 Objetivos de negocio de clientes/usuarios](#31-objetivos-de-negocio-de-clientesusuarios)
  - [3.2 Objetivos de Negocio](#32-objetivos-de-negocio)
  - [3.3 Actores y Procesos de Negocio](#33-actores-y-procesos-de-negocio)
  - [3.4 Casos de Uso](#34-casos-de-uso)
    - [Casos de uso de agent-cli-permissions [3.5.1]](#casos-de-uso-de-agent-cli-permissions-351)
    - [Casos de uso de doc-folder-structure [3.5.2]](#casos-de-uso-de-doc-folder-structure-352)
    - [Casos de uso de docs-portable-paths [3.5.3]](#casos-de-uso-de-docs-portable-paths-353)
    - [Casos de uso de project-claude-md [3.5.4]](#casos-de-uso-de-project-claude-md-354)
    - [Casos de uso de project-context-schema [3.5.5]](#casos-de-uso-de-project-context-schema-355)
    - [Casos de uso de project-onboarding [3.5.6]](#casos-de-uso-de-project-onboarding-356)
    - [Casos de uso de srs-generation [3.5.7]](#casos-de-uso-de-srs-generation-357)
    - [Casos de uso de test-driven-verification [3.5.8]](#casos-de-uso-de-test-driven-verification-358)
    - [Casos de uso de security-layer-matrix [3.6.1]](#casos-de-uso-de-security-layer-matrix-361)
  - [3.5 Requisitos Funcionales](#35-requisitos-funcionales)
    - [3.5.1 agent-cli-permissions](#351-agent-cli-permissions)
    - [3.5.2 doc-folder-structure](#352-doc-folder-structure)
    - [3.5.3 docs-portable-paths](#353-docs-portable-paths)
    - [3.5.4 project-claude-md](#354-project-claude-md)
    - [3.5.5 project-context-schema](#355-project-context-schema)
    - [3.5.6 project-onboarding](#356-project-onboarding)
    - [3.5.7 srs-generation](#357-srs-generation)
    - [3.5.8 test-driven-verification](#358-test-driven-verification)
  - [3.6 Requisitos No Funcionales](#36-requisitos-no-funcionales)
    - [3.6.1 security-layer-matrix](#361-security-layer-matrix)
  - [3.7 Matriz de Trazabilidad](#37-matriz-de-trazabilidad)
- [Cobertura](#cobertura)

## 1. Introducción

### 1.1 Alcance

`sdd-global-config` gestiona la configuración global del workflow SDD Híbrido, en el que Claude actúa como arquitecto y un Agente como constructor. Los artefactos que administra son:

- `~/.claude/CLAUDE.md`: reglas globales para Claude.
- `~/.claude/skills/` y `~/.claude/commands/opsx/`: comportamiento de explore, propose, apply, verify y archive en Claude.
- `openspec/config.yaml` de cada proyecto: contexto e inyección por proyecto.
- Plantillas para el Agente (`templates/`) y el espejo de las reglas en el vault de Obsidian.

Este documento cubre las 9 capabilities vigentes en `openspec/specs/` (52 requirements y 112 escenarios). Los changes sin archivar no están incluidos.

### 1.2 Objetivos

Que todo cambio en los proyectos pase por una spec aprobada, que el diseño y la implementación queden separados con un handoff explícito, que la verificación se base en evidencia ejecutable y que las reglas se puedan replicar entre máquinas y personas. El detalle está en 3.1 y 3.2.

## 2. Información del Dominio del Problema

### 2.1 Introducción al dominio

El dominio es el desarrollo guiado por especificaciones (SDD) con OpenSpec. Cada cambio es un *change* con cuatro artefactos (proposal, design, specs y tasks) que avanza por el ciclo explore → propose → apply → verify → archive. Claude propone, verifica y archiva; el Agente implementa. Al archivar, las delta specs se sincronizan con las specs vigentes. El estado de cada proyecto se comparte entre máquinas y agentes mediante un vault de Obsidian versionado en git.

### 2.2 Glosario de Términos

| Término | Definición |
|---|---|
| Change | unidad de trabajo de OpenSpec, con proposal, design, specs y tasks |
| Capability | área funcional con su spec vigente en openspec/specs/<capability>/spec.md |
| Delta spec | cambios de un change sobre una spec (ADDED / MODIFIED / REMOVED / RENAMED) |
| Handoff | aviso de Claude al Agente para que implemente un change |
| Test Plan | sección del design.md con un ID por escenario (Sxx) y su verificación |
| Caracterización (Cxx) | test que fija el comportamiento actual de código que se modifica |
| Spec-ID | trailer de commit que vincula el commit con su change |
| Vault | repo Obsidian compartido con el contexto de los proyectos (context.md, notas) |
| Espejo | copia de solo lectura del CLAUDE.md global en el vault |

Origen: Entrevista guiada.

## 3. Necesidades de Negocio

### 3.1 Objetivos de negocio de clientes/usuarios

| Campo | Valor |
|---|---|
| ID | U-01 |
| Descripción | arrancar un proyecto nuevo con el workflow sin configurar a mano |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | U-02 |
| Descripción | saber en todo momento qué change está activo y en qué estado (context.md del vault) |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | U-03 |
| Descripción | que el verify diga con evidencia si un change está listo para archivar |
| Origen | Entrevista guiada |

### 3.2 Objetivos de Negocio

| Campo | Valor |
|---|---|
| ID | OBJ-01 |
| Descripción | todo cambio de código pasa por una spec aprobada antes de implementarse |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | OBJ-02 |
| Descripción | separar diseño (Claude) de implementación (Agente) con un handoff explícito |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | OBJ-03 |
| Descripción | verificar con tests ejecutados, no por inferencia, antes de archivar |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | OBJ-04 |
| Descripción | reglas replicables entre máquinas y personas (repo + vault compartido) |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| ID | OBJ-05 |
| Descripción | documentación de requisitos generada desde las specs, sin redactarla a mano |
| Origen | Entrevista guiada |

### 3.3 Actores y Procesos de Negocio

**Actores**

| Campo | Valor |
|---|---|
| Nombre | Usuario del workflow |
| Descripción | colaborador que trabaja en los proyectos con Claude Code y el Agente |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Claude (arquitecto) |
| Descripción | explora, propone, verifica y archiva changes; no escribe código de producción |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Agente (constructor) |
| Descripción | implementa los changes con /openspec-apply-change (Cursor, Antigravity, Copilot u otro) |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Mantenedor de sdd-global-config |
| Descripción | edita reglas globales, skills y comandos y los distribuye |
| Origen | Entrevista guiada |

**Procesos**

| Campo | Valor |
|---|---|
| Nombre | Ciclo de un change |
| Descripción | explore, propose, apply, verify y archive, con PR y merge antes del archive |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Onboarding de proyecto |
| Descripción | openspec init --tools <agente>, config.yaml y plantillas del Agente |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Setup de máquina |
| Descripción | clonar el repo y el vault, copiar CLAUDE.md, skills y comandos a ~/.claude |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Sincronización de reglas |
| Descripción | CLAUDE.md global, espejo del vault y copia en el repo |
| Origen | Entrevista guiada |

| Campo | Valor |
|---|---|
| Nombre | Generación del SRS |
| Descripción | srs-generate a partir de las specs vigentes |
| Origen | Entrevista guiada |

### 3.4 Casos de Uso

Modo agrupado: un diagrama PlantUML de casos de uso por capability y sin diagramas Mermaid por escenario. Los actores se infieren de la cláusula WHEN de cada escenario.

#### Casos de uso de agent-cli-permissions [3.5.1]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
rectangle "agent-cli-permissions" {
  usecase "CU-001 `.gemini/` fuera de git" as CU001
  usecase "CU-002 Los archivos locales se conservan" as CU002
  usecase "CU-003 Permisos replicados desde la plantilla" as CU003
  usecase "CU-004 Allowlist genérica" as CU004
  usecase "CU-005 Cada máquina declara los suyos" as CU005
  usecase "CU-006 Línea con datos completos" as CU006
  usecase "CU-007 Selección de la cuota" as CU007
  usecase "CU-008 Entrada inválida" as CU008
  usecase "CU-009 Pasos de instalación visibles" as CU009
  usecase "CU-010 Prompt para generar la barra de estado" as CU010
}
A1 --> CU001
A1 --> CU002
A1 --> CU003
A1 --> CU004
A1 --> CU005
A1 --> CU006
A1 --> CU007
A1 --> CU008
A1 --> CU009
A1 --> CU010
@enduml
```

**CU-001 [3.5.1.1] `.gemini/` fuera de git** — Actor: Claude (arquitecto)

- **WHEN** se ejecuta `git ls-files .gemini`
- **THEN** no devuelve ningún archivo
- **AND** `.gitignore` contiene `.gemini/`

**CU-002 [3.5.1.1] Los archivos locales se conservan** — Actor: Claude (arquitecto)

- **WHEN** se deja de versionar `.gemini/`
- **THEN** los archivos de `.gemini/` siguen existiendo en el disco
- **AND** la configuración real del CLI en `~/.gemini/antigravity-cli/` no se modifica

**CU-003 [3.5.1.2] Permisos replicados desde la plantilla** — Actor: Claude (arquitecto)

- **WHEN** se instala `templates/antigravity-settings.json` en una máquina nueva
- **THEN** el `settings.json` resultante contiene los tres valores de permisos anteriores

**CU-004 [3.5.1.3] Allowlist genérica** — Actor: Claude (arquitecto)

- **WHEN** se lee `permissions.allow` de `templates/antigravity-settings.json`
- **THEN** contiene esos siete comandos
- **AND** no contiene rutas de sesión ni comandos específicos de un proyecto

**CU-005 [3.5.1.4] Cada máquina declara los suyos** — Actor: Claude (arquitecto)

- **WHEN** se instala la plantilla en una máquina nueva
- **THEN** la persona reemplaza el placeholder por las carpetas de sus propios proyectos
- **AND** la plantilla versionada no contiene rutas reales ni el nombre de usuario

**CU-006 [3.5.1.5] Línea con datos completos** — Actor: Claude (arquitecto)

- **WHEN** la entrada es `{"workspace":{"project_dir":"C:/x/mi-proyecto"},"context_window":{"used_percentage":42.4},"quota":{"gemini-5h":{"remaining_fraction":0.75,"reset_in_seconds":5400}},"model":{"display_name":"Modelo Ejemplo"}}`
- **THEN** la línea, sin secuencias ANSI, empieza con `mi-proyecto   42%   25% 1h30m`
- **AND** termina con `Modelo Ejemplo`

**CU-007 [3.5.1.5] Selección de la cuota** — Actor: Claude (arquitecto)

- **WHEN** la entrada trae `3p-5h` con `remaining_fraction` 1 y `gemini-5h` con `remaining_fraction` 0.75
- **THEN** la cuota mostrada es `25%`, tomada de `gemini-5h`

**CU-008 [3.5.1.5] Entrada inválida** — Actor: Claude (arquitecto)

- **WHEN** la entrada estándar no es un JSON válido
- **THEN** la barra usa el nombre del directorio actual como proyecto, `0%` de contexto y `0%` de cuota
- **AND** no produce ningún error

**CU-009 [3.5.1.6] Pasos de instalación visibles** — Actor: Claude (arquitecto)

- **WHEN** se lee la sección de setup por máquina del `README.md` y de `docs/modo-de-uso.md`
- **THEN** describen dónde copiar `templates/antigravity-settings.json`
- **AND** indican reemplazar los placeholders de `trustedWorkspaces` y de `statusLine`

**CU-010 [3.5.1.6] Prompt para generar la barra de estado** — Actor: Claude (arquitecto)

- **WHEN** se lee `templates/README.md`
- **THEN** incluye el prompt que se ejecuta en el CLI del Agente para generar `statusline.bat` y `statusline_new.ps1` a partir de esta spec

#### Casos de uso de doc-folder-structure [3.5.2]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
rectangle "doc-folder-structure" {
  usecase "CU-011 Directorio creado" as CU011
  usecase "CU-012 Workflow accesible desde `docs/`" as CU012
  usecase "CU-013 Archivo raíz eliminado" as CU013
  usecase "CU-014 Guía accesible desde `docs/`" as CU014
  usecase "CU-015 Carpeta origen eliminada" as CU015
  usecase "CU-016 README actualizado" as CU016
}
A1 --> CU011
A1 --> CU012
A1 --> CU013
A1 --> CU014
A1 --> CU015
A1 --> CU016
@enduml
```

**CU-011 [3.5.2.1] Directorio creado** — Actor: Claude (arquitecto)

- **WHEN** se inspecciona la raíz del repositorio
- **THEN** existe el directorio `docs/`

**CU-012 [3.5.2.2] Workflow accesible desde `docs/`** — Actor: Claude (arquitecto)

- **WHEN** se navega a `docs/workflow.md`
- **THEN** el archivo contiene el contenido completo del workflow SDD Híbrido (roles, onboarding, flujo por change, capa de seguridad)

**CU-013 [3.5.2.2] Archivo raíz eliminado** — Actor: Claude (arquitecto)

- **WHEN** se inspecciona la raíz del repositorio
- **THEN** no existe `WORKFLOW.md` en la raíz

**CU-014 [3.5.2.3] Guía accesible desde `docs/`** — Actor: Claude (arquitecto)

- **WHEN** se navega a `docs/modo-de-uso.md` y a `docs/modo-de-uso.docx`
- **THEN** ambos archivos existen y son los originales de la guía de uso del workflow

**CU-015 [3.5.2.3] Carpeta origen eliminada** — Actor: Claude (arquitecto)

- **WHEN** se inspecciona la raíz del repositorio
- **THEN** no existe el directorio `Modo de Uso/`

**CU-016 [3.5.2.4] README actualizado** — Actor: Claude (arquitecto)

- **WHEN** se lee `README.md`
- **THEN** contiene referencias a `docs/workflow.md` y a `docs/modo-de-uso.md`
- **AND** no quedan referencias a `WORKFLOW.md` ni a `Modo de Uso/` fuera de `docs/`

#### Casos de uso de docs-portable-paths [3.5.3]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
rectangle "docs-portable-paths" {
  usecase "CU-017 Guía de uso sin ruta local" as CU017
  usecase "CU-018 Workflow sin ruta local" as CU018
  usecase "CU-019 Docx regenerado sin ruta local" as CU019
}
A1 --> CU017
A1 --> CU018
A1 --> CU019
@enduml
```

**CU-017 [3.5.3.1] Guía de uso sin ruta local** — Actor: Claude (arquitecto)

- **WHEN** se lee `docs/modo-de-uso.md`
- **THEN** el comando `cd` del Paso 1 usa el placeholder `{ruta-del-proyecto}`
- **AND** el documento no contiene `C:\Users`

**CU-018 [3.5.3.1] Workflow sin ruta local** — Actor: Claude (arquitecto)

- **WHEN** se lee `docs/workflow.md`
- **THEN** la ruta del `config.json` del perfil global de OpenSpec se expresa como `$env:APPDATA\openspec\config.json`
- **AND** el documento no contiene `C:\Users`

**CU-019 [3.5.3.2] Docx regenerado sin ruta local** — Actor: Claude (arquitecto)

- **WHEN** se inspecciona el contenido de `docs/modo-de-uso.docx`
- **THEN** contiene el placeholder `{ruta-del-proyecto}`
- **AND** no contiene `C:\Users`

#### Casos de uso de project-claude-md [3.5.4]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
actor "Usuario del workflow" as A2
rectangle "project-claude-md" {
  usecase "CU-020 Sección de workflow presente" as CU020
  usecase "CU-021 Sin reglas globales duplicadas" as CU021
  usecase "CU-022 Sin términos del flujo manual" as CU022
  usecase "CU-023 Specs legacy solo como referencia" as CU023
  usecase "CU-024 Constructor sin herramienta concreta" as CU024
  usecase "CU-025 Contratos y watchlist intactos" as CU025
  usecase "CU-026 Sin ruta con usuario local" as CU026
  usecase "CU-027 Ruta que es dependencia funcional" as CU027
  usecase "CU-028 Rutas de archivos del repo existentes" as CU028
}
A1 --> CU020
A1 --> CU021
A1 --> CU022
A1 --> CU023
A1 --> CU024
A1 --> CU025
A1 --> CU026
A2 --> CU027
A1 --> CU028
@enduml
```

**CU-020 [3.5.4.1] Sección de workflow presente** — Actor: Claude (arquitecto)

- **WHEN** se lee el `CLAUDE.md` de un proyecto alineado
- **THEN** existe una sección "Workflow SDD / OpenSpec"
- **AND** la sección menciona `~/.claude/CLAUDE.md` y `/opsx:propose`

**CU-021 [3.5.4.1] Sin reglas globales duplicadas** — Actor: Claude (arquitecto)

- **WHEN** se lee el `CLAUDE.md` de un proyecto alineado
- **THEN** no contiene secciones de roles Claude/Agente, de flujo por change, de reglas de Git ni de seguridad universal copiadas de las reglas globales

**CU-022 [3.5.4.2] Sin términos del flujo manual** — Actor: Claude (arquitecto)

- **WHEN** se busca en el `CLAUDE.md` de un proyecto alineado "prompt para Copilot", "Bash Headless", "Fase 0 — LEER" y "OPCX"
- **THEN** no hay coincidencias

**CU-023 [3.5.4.2] Specs legacy solo como referencia** — Actor: Claude (arquitecto)

- **WHEN** el proyecto conserva `specs/` con features anteriores a OpenSpec
- **THEN** el `CLAUDE.md` los presenta como referencia legacy
- **AND** indica que los changes nuevos se crean en `openspec/changes/`

**CU-024 [3.5.4.3] Constructor sin herramienta concreta** — Actor: Claude (arquitecto)

- **WHEN** el `CLAUDE.md` de un proyecto alineado se refiere a quien implementa
- **THEN** usa "el Agente"
- **AND** no usa "Copilot" ni "Gemini" como rol

**CU-025 [3.5.4.4] Contratos y watchlist intactos** — Actor: Claude (arquitecto)

- **WHEN** se compara el `CLAUDE.md` alineado con la versión de la rama principal
- **THEN** las secciones de contratos de comportamiento, reglas de arquitectura y watchlist tienen el mismo contenido
- **AND** las únicas diferencias son rutas con usuario local reemplazadas por placeholders

**CU-026 [3.5.4.4] Sin ruta con usuario local** — Actor: Claude (arquitecto)

- **WHEN** se busca `C:\Users` en el `CLAUDE.md` alineado
- **THEN** no hay coincidencias

**CU-027 [3.5.4.4] Ruta que es dependencia funcional** — Actor: Usuario del workflow

- **WHEN** una regla depende de una ruta absoluta del escritorio del usuario
- **THEN** el `CLAUDE.md` alineado la expresa con un placeholder como `{escritorio}\<carpeta>`
- **AND** la regla aclara que es el escritorio del usuario de cada equipo

**CU-028 [3.5.4.4] Rutas de archivos del repo existentes** — Actor: Claude (arquitecto)

- **WHEN** el `CLAUDE.md` alineado cita un archivo del repo
- **THEN** el archivo existe en la rama principal del proyecto en la ruta citada

#### Casos de uso de project-context-schema [3.5.5]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
actor "Usuario del workflow" as A2
rectangle "project-context-schema" {
  usecase "CU-029 Proyecto sin subsecciones previas" as CU029
  usecase "CU-030 Proyecto con subsecciones ya presentes" as CU030
  usecase "CU-031 Proyecto sin config.yaml" as CU031
  usecase "CU-032 config.yaml sin context activo ni project_type" as CU032
  usecase "CU-033 Usuario que no sabe el tipo de proyecto" as CU033
  usecase "CU-034 Usuario que no sabe cómo se corren los tests" as CU034
  usecase "CU-035 Formato consistente" as CU035
  usecase "CU-036 Subsección Tests con las claves fijas" as CU036
  usecase "CU-037 Claves opcionales no declaradas" as CU037
  usecase "CU-038 Proyecto sin tests automáticos" as CU038
  usecase "CU-039 Tamaño dentro del umbral" as CU039
  usecase "CU-040 Tamaño cerca del límite" as CU040
}
A1 --> CU029
A1 --> CU030
A1 --> CU031
A1 --> CU032
A2 --> CU033
A2 --> CU034
A1 --> CU035
A1 --> CU036
A2 --> CU037
A2 --> CU038
A1 --> CU039
A1 --> CU040
@enduml
```

**CU-029 [3.5.5.1] Proyecto sin subsecciones previas** — Actor: Claude (arquitecto)

- **WHEN** una skill agrega una subsección por primera vez a un `context:` que no tiene ninguna
- **THEN** la subsección se appendea al final del texto existente, separada por una línea en blanco
- **AND** el contenido previo de `context:` queda intacto

**CU-030 [3.5.5.1] Proyecto con subsecciones ya presentes** — Actor: Claude (arquitecto)

- **WHEN** una skill actualiza una subsección que ya existe (por ejemplo, agrega un término al Glosario)
- **THEN** solo se reemplaza el bloque entre su encabezado y el siguiente `##` (o el final del texto)
- **AND** las demás subsecciones y el contenido previo a ellas no cambian

**CU-031 [3.5.5.1] Proyecto sin config.yaml** — Actor: Claude (arquitecto)

- **WHEN** una skill necesita escribir una subsección y el proyecto no tiene `openspec/config.yaml` (por ejemplo, tras `openspec init` en OpenSpec 1.4.1)
- **THEN** crea el archivo con `schema: spec-driven`, el `project_type` que indique el usuario y un `context:` con la descripción del proyecto
- **AND** recién después appendea la subsección al final del `context:`

**CU-032 [3.5.5.1] config.yaml sin context activo ni project_type** — Actor: Claude (arquitecto)

- **WHEN** una skill necesita escribir una subsección y `openspec/config.yaml` no tiene `context:` activo (por ejemplo, el que genera `openspec init` en OpenSpec 1.14.x, con el `context:` solo comentado) o no tiene `project_type`
- **THEN** agrega las claves que faltan, preguntando `project_type` en la misma pregunta que la subsección `## Tests`
- **AND** el resto del archivo, incluidos los comentarios, queda intacto

**CU-033 [3.5.5.1] Usuario que no sabe el tipo de proyecto** — Actor: Usuario del workflow

- **WHEN** se pregunta `project_type` y el usuario responde que no sabe
- **THEN** la skill lo deduce del repo, lo escribe con el comentario `# inferido — revisar` en la misma línea
- **AND** lo menciona en el resumen final para que se revise

**CU-034 [3.5.5.1] Usuario que no sabe cómo se corren los tests** — Actor: Usuario del workflow

- **WHEN** se pregunta `## Tests` y el usuario responde que no sabe
- **THEN** si el repo muestra cómo se corren (por ejemplo, pytest con archivos `test_*.py`, o `scripts.test` en `package.json`), la skill escribe ese `comando` junto con `- timeout: 5` por defecto, y menciona los dos en el resumen final como inferidos
- **AND** si el repo no lo muestra, no escribe `## Tests` (tampoco `comando: ninguno`), deja el comando como pendiente en el Test Plan y lo vuelve a preguntar en el próximo propose

**CU-035 [3.5.5.2] Formato consistente** — Actor: Claude (arquitecto)

- **WHEN** se genera o actualiza cualquiera de las cuatro subsecciones
- **THEN** cada ítem sigue el formato `- <clave>: <descripción>`
- **AND** "Actores y Procesos de Negocio" separa actores de procesos bajo sus propios sub-encabezados

**CU-036 [3.5.5.2] Subsección Tests con las claves fijas** — Actor: Claude (arquitecto)

- **WHEN** se genera la subsección `## Tests` de un proyecto con tests automáticos
- **THEN** incluye al menos `- comando: <comando>` y `- timeout: <minutos>`
- **AND** no incluye claves distintas de `comando`, `comando-rapido`, `timeout`, `entorno` y `excluir`

**CU-037 [3.5.5.2] Claves opcionales no declaradas** — Actor: Usuario del workflow

- **WHEN** el usuario no declara `comando-rapido`, `entorno` o `excluir`
- **THEN** esas claves no aparecen en `## Tests`
- **AND** la pregunta muestra el timeout como `<n> min`

**CU-038 [3.5.5.2] Proyecto sin tests automáticos** — Actor: Usuario del workflow

- **WHEN** el usuario indica que el proyecto no tiene forma de correr tests automáticos
- **THEN** la subsección `## Tests` queda con `- comando: ninguno`
- **AND** no se pregunta de nuevo en los proposes siguientes

**CU-039 [3.5.5.3] Tamaño dentro del umbral** — Actor: Claude (arquitecto)

- **WHEN** el `context:` resultante después de escribir queda por debajo de 40KB
- **THEN** la skill escribe sin advertencias

**CU-040 [3.5.5.3] Tamaño cerca del límite** — Actor: Claude (arquitecto)

- **WHEN** el `context:` resultante después de escribir superaría 40KB
- **THEN** la skill advierte antes de escribir, mostrando el tamaño estimado, y deja la decisión de qué recortar al usuario

#### Casos de uso de project-onboarding [3.5.6]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
actor "Agente (constructor)" as A2
rectangle "project-onboarding" {
  usecase "CU-041 Skills y comandos instalados" as CU041
  usecase "CU-042 Comando de init sin claude" as CU042
  usecase "CU-043 Un proyecto iniciado solo con el Agente no tiene copias de Claude" as CU043
  usecase "CU-044 Procedimiento de limpieza documentado" as CU044
  usecase "CU-045 La limpieza es duradera" as CU045
}
A1 --> CU041
A1 --> CU042
A2 --> CU043
A1 --> CU044
A1 --> CU045
@enduml
```

**CU-041 [3.5.6.1] Skills y comandos instalados** — Actor: Claude (arquitecto)

- **WHEN** se lee el setup por máquina del `README.md` y de `docs/workflow.md`
- **THEN** describen copiar todas las skills de `skills/` a `~/.claude/skills/`
- **AND** describen copiar los comandos de `.claude/commands/opsx/` a `~/.claude/commands/opsx/`

**CU-042 [3.5.6.2] Comando de init sin claude** — Actor: Claude (arquitecto)

- **WHEN** se leen `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`
- **THEN** ningún comando `openspec init` incluye `claude` en `--tools`
- **AND** ninguna guía contiene el paso de "liberar el slot de apply"

**CU-043 [3.5.6.2] Un proyecto iniciado solo con el Agente no tiene copias de Claude** — Actor: Agente (constructor)

- **WHEN** se ejecuta `openspec init --tools <agente>` en un directorio nuevo y luego `openspec update`
- **THEN** existen las skills del Agente (por ejemplo `.agent/skills/openspec-apply-change/`)
- **AND** no existe la carpeta `.claude/` en el proyecto

**CU-044 [3.5.6.3] Procedimiento de limpieza documentado** — Actor: Claude (arquitecto)

- **WHEN** se lee la sección de proyecto existente con OpenSpec de `docs/workflow.md` y de `docs/modo-de-uso.md`
- **THEN** indica eliminar `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`
- **AND** indica commitear la eliminación aparte, desde la rama principal

**CU-045 [3.5.6.3] La limpieza es duradera** — Actor: Claude (arquitecto)

- **WHEN** se eliminan las copias locales de Claude de un proyecto y se ejecuta `openspec update`
- **THEN** las copias no se vuelven a generar

#### Casos de uso de srs-generation [3.5.7]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
actor "Usuario del workflow" as A2
rectangle "srs-generation" {
  usecase "CU-046 Misma estructura en cualquier proyecto" as CU046
  usecase "CU-047 Sección sin contenido disponible" as CU047
  usecase "CU-048 Numeración sin duplicados" as CU048
  usecase "CU-049 Encabezado y estado del documento" as CU049
  usecase "CU-050 Secciones en formato de tabla" as CU050
  usecase "CU-051 Primera asignación de IDs" as CU051
  usecase "CU-052 Regeneración con requirements nuevos" as CU052
  usecase "CU-053 Caso de Uso cita su requirement" as CU053
  usecase "CU-054 Valores por defecto aplicados" as CU054
  usecase "CU-055 Excepción marcada en la entrevista" as CU055
  usecase "CU-056 Corrección manual respetada" as CU056
  usecase "CU-057 Proyecto con specs vigentes" as CU057
  usecase "CU-058 Clasificación visible y corregible" as CU058
  usecase "CU-059 Requisito no funcional sin prioridad todavía" as CU059
  usecase "CU-060 Caso de uso simple" as CU060
  usecase "CU-061 Caso de uso con varios pasos de un solo actor" as CU061
  usecase "CU-062 Caso de uso con interacción entre actores" as CU062
  usecase "CU-063 Proyecto por debajo del umbral" as CU063
  usecase "CU-064 Proyecto por encima del umbral" as CU064
  usecase "CU-065 Alcance acotado a capabilities" as CU065
  usecase "CU-066 Desglose de cobertura al final" as CU066
  usecase "CU-067 Matriz generada automáticamente" as CU067
  usecase "CU-068 Primera generación" as CU068
  usecase "CU-069 Regeneración sin gaps nuevos" as CU069
  usecase "CU-070 Regeneración con un gap nuevo" as CU070
  usecase "CU-071 Migración de datos existentes en `docs/srs.meta.yaml`" as CU071
  usecase "CU-072 Proyecto sin ninguna spec" as CU072
  usecase "CU-073 Proyecto con specs parciales" as CU073
  usecase "CU-074 Regenerar un SRS existente" as CU074
  usecase "CU-075 El usuario cancela la regeneración" as CU075
  usecase "CU-076 Archive en un proyecto que ya usa SRS" as CU076
  usecase "CU-077 Archive en un proyecto sin SRS" as CU077
  usecase "CU-078 Requirement basado en spec" as CU078
  usecase "CU-079 Requirement inferido" as CU079
  usecase "CU-080 Archivo de secretos ignorado" as CU080
  usecase "CU-081 Ruta absoluta con usuario local" as CU081
}
A1 --> CU046
A1 --> CU047
A1 --> CU048
A1 --> CU049
A1 --> CU050
A1 --> CU051
A1 --> CU052
A1 --> CU053
A1 --> CU054
A1 --> CU055
A1 --> CU056
A1 --> CU057
A1 --> CU058
A1 --> CU059
A1 --> CU060
A1 --> CU061
A1 --> CU062
A1 --> CU063
A1 --> CU064
A1 --> CU065
A1 --> CU066
A1 --> CU067
A1 --> CU068
A1 --> CU069
A1 --> CU070
A1 --> CU071
A1 --> CU072
A1 --> CU073
A1 --> CU074
A2 --> CU075
A1 --> CU076
A1 --> CU077
A1 --> CU078
A1 --> CU079
A1 --> CU080
A2 --> CU081
@enduml
```

**CU-046 [3.5.7.1] Misma estructura en cualquier proyecto** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en dos proyectos distintos
- **THEN** `docs/srs.md` de ambos tiene las mismas secciones y la misma numeración
- **AND** solo difiere el contenido de cada subsección, tomado del proyecto destino

**CU-047 [3.5.7.1] Sección sin contenido disponible** — Actor: Claude (arquitecto)

- **WHEN** una sección de la estructura fija no tiene información disponible en specs, código ni entrevista todavía
- **THEN** la sección igual aparece en `docs/srs.md`, marcada como pendiente, en vez de omitirse

**CU-048 [3.5.7.1] Numeración sin duplicados** — Actor: Claude (arquitecto)

- **WHEN** se genera `docs/srs.md`
- **THEN** ningún número de sección se usa para dos secciones distintas, aunque el documento de referencia lo haga

**CU-049 [3.5.7.2] Encabezado y estado del documento** — Actor: Claude (arquitecto)

- **WHEN** se genera `docs/srs.md` y quedan secciones marcadas como pendientes o inferidas
- **THEN** el encabezado indica estado "borrador"
- **AND** cuando no queda ninguna, indica "completo"

**CU-050 [3.5.7.2] Secciones en formato de tabla** — Actor: Claude (arquitecto)

- **WHEN** se generan 3.1/3.2, 3.3 y 3.6
- **THEN** cada objetivo de negocio, cada actor, cada proceso de negocio y cada requisito no funcional aparece como una fila o tabla individual, no como párrafo

**CU-051 [3.5.7.3] Primera asignación de IDs** — Actor: Claude (arquitecto)

- **WHEN** se genera el SRS por primera vez en un proyecto con capabilities
- **THEN** cada requirement de 3.5/3.6 recibe un ID jerárquico
- **AND** el mapeo queda guardado en `docs/srs.meta.yaml`

**CU-052 [3.5.7.3] Regeneración con requirements nuevos** — Actor: Claude (arquitecto)

- **WHEN** se agrega una capability o un requirement nuevo y se regenera el SRS
- **THEN** los IDs ya asignados no cambian
- **AND** lo nuevo recibe el siguiente número libre

**CU-053 [3.5.7.3] Caso de Uso cita su requirement** — Actor: Claude (arquitecto)

- **WHEN** un Caso de Uso de 3.4 proviene del escenario de un requirement de 3.5
- **THEN** el título del Caso de Uso cita el ID de ese requirement

**CU-054 [3.5.7.4] Valores por defecto aplicados** — Actor: Claude (arquitecto)

- **WHEN** se genera el SRS y nadie marcó excepciones
- **THEN** cada requirement muestra Riesgo: Bajo, Dependencia: Ninguna identificada y Dificultad: Nominal

**CU-055 [3.5.7.4] Excepción marcada en la entrevista** — Actor: Claude (arquitecto)

- **WHEN** en la entrevista se indica que un requirement tiene riesgo alto
- **THEN** ese requirement muestra el valor indicado y el resto conserva el default

**CU-056 [3.5.7.4] Corrección manual respetada** — Actor: Claude (arquitecto)

- **WHEN** alguien edita el atributo de un requirement en `docs/srs.meta.yaml` y se regenera el SRS
- **THEN** el documento generado usa el valor editado, no el default

**CU-057 [3.5.7.5] Proyecto con specs vigentes** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en un proyecto que tiene una o más capabilities en `openspec/specs/`
- **THEN** cada capability aparece en 3.5 o 3.6 según su clasificación, con sus requirements y escenarios
- **AND** cada requirement de 3.6 muestra una prioridad

**CU-058 [3.5.7.5] Clasificación visible y corregible** — Actor: Claude (arquitecto)

- **WHEN** se genera el SRS de un proyecto con capabilities de distinto tipo
- **THEN** el documento deja explícita la clasificación aplicada a cada capability para que se pueda corregir a mano

**CU-059 [3.5.7.5] Requisito no funcional sin prioridad todavía** — Actor: Claude (arquitecto)

- **WHEN** una capability se clasifica en 3.6 y no tiene prioridad asignada en `docs/srs.meta.yaml`
- **THEN** queda marcada como pendiente hasta que la entrevista guiada la complete

**CU-060 [3.5.7.6] Caso de uso simple** — Actor: Claude (arquitecto)

- **WHEN** un escenario de una spec tiene un único actor y un solo paso en el `WHEN`
- **THEN** el Caso de Uso correspondiente en 3.4 incluye su diagrama UML de caso de uso en PlantUML
- **AND** no se agrega diagrama Mermaid

**CU-061 [3.5.7.6] Caso de uso con varios pasos de un solo actor** — Actor: Claude (arquitecto)

- **WHEN** un escenario tiene varios pasos secuenciales de un mismo actor
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en PlantUML, un flowchart en Mermaid con esos pasos

**CU-062 [3.5.7.6] Caso de uso con interacción entre actores** — Actor: Claude (arquitecto)

- **WHEN** un escenario involucra a dos o más actores interactuando
- **THEN** el Caso de Uso incluye, además del diagrama de caso de uso en PlantUML, un sequence diagram en Mermaid con esa interacción

**CU-063 [3.5.7.7] Proyecto por debajo del umbral** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` sin acotar el alcance en un proyecto con pocos escenarios
- **THEN** la skill genera un diagrama de caso de uso por escenario (D7) sin pedir acotar

**CU-064 [3.5.7.7] Proyecto por encima del umbral** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en un proyecto cuyo total de escenarios en alcance supera el umbral
- **THEN** la skill muestra el conteo y una estimación de tamaño y pide confirmación u ofrece acotar
- **AND** si se continúa, genera un solo diagrama de casos de uso por capability en vez de uno por escenario

**CU-065 [3.5.7.7] Alcance acotado a capabilities** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` con un alcance que limita las capabilities a incluir
- **THEN** el SRS generado solo cubre esas capabilities
- **AND** si el subconjunto queda por debajo del umbral, vuelven los diagramas por escenario

**CU-066 [3.5.7.8] Desglose de cobertura al final** — Actor: Claude (arquitecto)

- **WHEN** se genera `docs/srs.md`
- **THEN** su última sección muestra el desglose por origen (specs / inferido / entrevista / pendiente)

**CU-067 [3.5.7.9] Matriz generada automáticamente** — Actor: Claude (arquitecto)

- **WHEN** 3.4 y 3.5 ya están completas
- **THEN** 3.7 muestra una tabla con cada Caso de Uso y los Requisitos Funcionales que le corresponden, sin que nadie la arme a mano

**CU-068 [3.5.7.10] Primera generación** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` por primera vez en un proyecto y las subsecciones de Glosario/Objetivos/Actores-Procesos no existen todavía en `context:`
- **THEN** la skill hace la entrevista guiada completa antes de escribir `docs/srs.md`
- **AND** persiste las respuestas en las subsecciones correspondientes de `context:` en `openspec/config.yaml`

**CU-069 [3.5.7.10] Regeneración sin gaps nuevos** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` de nuevo y no hay actores, procesos, términos ni objetivos nuevos desde la última corrida
- **THEN** la skill no repite ninguna pregunta de la entrevista y usa las subsecciones de `context:` tal cual están

**CU-070 [3.5.7.10] Regeneración con un gap nuevo** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` de nuevo y apareció una capability nueva en 3.6 sin prioridad asignada
- **THEN** la skill pregunta solo por esa prioridad y la guarda en `docs/srs.meta.yaml`
- **AND** no vuelve a preguntar por el resto de las secciones

**CU-071 [3.5.7.10] Migración de datos existentes en `docs/srs.meta.yaml`** — Actor: Claude (arquitecto)

- **WHEN** `docs/srs.meta.yaml` de un proyecto ya tiene glosario, actores, procesos u objetivos de una corrida anterior a este change
- **THEN** la skill los migra a las subsecciones correspondientes de `context:` en la primera corrida siguiente
- **AND** los quita de `docs/srs.meta.yaml`
- **AND** no vuelve a preguntar por ellos en la entrevista

**CU-072 [3.5.7.11] Proyecto sin ninguna spec** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en un proyecto cuyo `openspec/specs/` no existe o está vacío
- **THEN** la skill ofrece el modo bootstrap antes de generar un SRS con 3.5/3.6 vacías
- **AND**, si el usuario acepta, cada sección de 3.5/3.6 que no venga de una spec queda marcada como "inferido del código, sin spec formal — revisar"

**CU-073 [3.5.7.11] Proyecto con specs parciales** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en un proyecto que tiene algunas capabilities documentadas y zonas de código sin spec asociada
- **THEN** la skill combina en el mismo SRS las secciones basadas en spec (sin marca) con las inferidas por bootstrap (marcadas), sin mezclarlas sin distinción

**CU-074 [3.5.7.12] Regenerar un SRS existente** — Actor: Claude (arquitecto)

- **WHEN** se invoca `srs-generate` en un proyecto que ya tiene `docs/srs.md`
- **THEN** la skill muestra qué secciones cambiarían respecto del contenido actual antes de escribir
- **AND** solo sobrescribe el archivo si el usuario confirma

**CU-075 [3.5.7.12] El usuario cancela la regeneración** — Actor: Usuario del workflow

- **WHEN** se muestra el resumen de cambios y el usuario no confirma
- **THEN** `docs/srs.md` queda intacto

**CU-076 [3.5.7.13] Archive en un proyecto que ya usa SRS** — Actor: Claude (arquitecto)

- **WHEN** se completa `/opsx:archive` en un proyecto que tiene `docs/srs.md`
- **THEN** el resumen final del archive ofrece regenerar el SRS
- **AND** el archive se considera completo independientemente de si el usuario acepta o no

**CU-077 [3.5.7.13] Archive en un proyecto sin SRS** — Actor: Claude (arquitecto)

- **WHEN** se completa `/opsx:archive` en un proyecto que no tiene `docs/srs.md`
- **THEN** el resumen final del archive no menciona ni ofrece generar un SRS

**CU-078 [3.5.7.14] Requirement basado en spec** — Actor: Claude (arquitecto)

- **WHEN** un requirement del SRS proviene de `openspec/specs/<capability>/spec.md`
- **THEN** el SRS cita esa capability como fuente del requirement

**CU-079 [3.5.7.14] Requirement inferido** — Actor: Claude (arquitecto)

- **WHEN** un requirement del SRS proviene del modo bootstrap
- **THEN** el SRS lo marca como inferido en vez de citar una spec inexistente

**CU-080 [3.5.7.15] Archivo de secretos ignorado** — Actor: Claude (arquitecto)

- **WHEN** el modo bootstrap recorre el código de un proyecto que tiene `.env` o `secrets/` en su `.gitignore`
- **THEN** el contenido de esos archivos no aparece en `docs/srs.md`

**CU-081 [3.5.7.15] Ruta absoluta con usuario local** — Actor: Usuario del workflow

- **WHEN** el bootstrap encuentra en el código una ruta absoluta con el nombre de usuario de la máquina
- **THEN** el SRS generado reemplaza esa parte de la ruta por un placeholder en vez de copiarla literal

#### Casos de uso de test-driven-verification [3.5.8]

```plantuml
@startuml
left to right direction
actor "Claude (arquitecto)" as A1
actor "Agente (constructor)" as A2
rectangle "test-driven-verification" {
  usecase "CU-082 Change con escenarios testeables" as CU082
  usecase "CU-083 Escenario sin forma de testearse automáticamente" as CU083
  usecase "CU-084 Proyecto sin subsección Tests" as CU084
  usecase "CU-085 Test movido o renombrado" as CU085
  usecase "CU-086 Test sin marcador" as CU086
  usecase "CU-087 Orden de las tareas" as CU087
  usecase "CU-088 Proyecto sin infraestructura de tests" as CU088
  usecase "CU-089 Change que mueve funciones existentes" as CU089
  usecase "CU-090 Cambio de comportamiento intencional" as CU090
  usecase "CU-091 Todos los tests del plan pasan" as CU091
  usecase "CU-092 Un test del plan falla" as CU092
  usecase "CU-093 Entorno de test no disponible" as CU093
  usecase "CU-094 Change que solo agrega archivos" as CU094
  usecase "CU-095 Regresión fuera del diff" as CU095
  usecase "CU-096 Test que ya fallaba" as CU096
  usecase "CU-097 Archivo existente modificado sin caracterización" as CU097
  usecase "CU-098 Salida sin nombres de los tests que fallan" as CU098
  usecase "CU-099 Suite lenta" as CU099
  usecase "CU-100 Test que no prueba el escenario" as CU100
  usecase "CU-101 Revisión de diseño sobre el diff" as CU101
  usecase "CU-102 Escenario manual sin motivo" as CU102
  usecase "CU-103 Demasiados escenarios manuales" as CU103
  usecase "CU-104 Proyecto sin tests automáticos" as CU104
  usecase "CU-105 Salida de tests con un comando sugerido" as CU105
  usecase "CU-106 Reporte sin logs" as CU106
  usecase "CU-107 Change creado antes de la regla" as CU107
  usecase "CU-108 Test en rojo al terminar la tarea" as CU108
}
A1 --> CU082
A1 --> CU083
A1 --> CU084
A2 --> CU085
A1 --> CU086
A1 --> CU087
A1 --> CU088
A1 --> CU089
A1 --> CU090
A1 --> CU091
A1 --> CU092
A1 --> CU093
A1 --> CU094
A1 --> CU095
A1 --> CU096
A1 --> CU097
A1 --> CU098
A1 --> CU099
A1 --> CU100
A1 --> CU101
A1 --> CU102
A1 --> CU103
A1 --> CU104
A1 --> CU105
A1 --> CU106
A1 --> CU107
A2 --> CU108
@enduml
```

**CU-082 [3.5.8.1] Change con escenarios testeables** — Actor: Claude (arquitecto)

- **WHEN** se hace propose de un change cuyas delta specs tienen escenarios y el proyecto declara un comando de tests
- **THEN** `design.md` contiene `## Test Plan` con una fila por escenario, cada una con su ID `Sxx` y un test automático
- **AND** la sección indica el comando de tests del proyecto

**CU-083 [3.5.8.1] Escenario sin forma de testearse automáticamente** — Actor: Claude (arquitecto)

- **WHEN** un escenario no se puede cubrir con un test automático (por ejemplo, UI sin framework de test o Power Query)
- **THEN** su fila del Test Plan dice `manual`, con el motivo y los pasos para verificarlo a mano

**CU-084 [3.5.8.1] Proyecto sin subsección Tests** — Actor: Claude (arquitecto)

- **WHEN** se hace propose en un proyecto cuyo `context:` no tiene `## Tests`
- **THEN** la skill pregunta una sola vez el comando, el tiempo máximo y los requisitos de entorno
- **AND** los guarda en la subsección `## Tests` del `context:` (capability `project-context-schema`) antes de escribir el Test Plan

**CU-085 [3.5.8.2] Test movido o renombrado** — Actor: Agente (constructor)

- **WHEN** el Agente implementa el test de `S03` en un archivo o con un nombre distinto del previsto en el Test Plan, pero con el marcador correcto
- **THEN** el verify lo encuentra por el marcador y no reporta el escenario como faltante

**CU-086 [3.5.8.2] Test sin marcador** — Actor: Claude (arquitecto)

- **WHEN** ningún test del repo contiene el marcador de un ID automático del Test Plan
- **THEN** el verify reporta CRITICAL "Escenario <ID> sin test"

**CU-087 [3.5.8.3] Orden de las tareas** — Actor: Claude (arquitecto)

- **WHEN** se genera `tasks.md` de un change con Test Plan automático
- **THEN** las tareas que escriben los tests de `Sxx` aparecen antes que las tareas que implementan esos escenarios
- **AND** cada tarea de test nombra sus IDs y el comando para correrla

**CU-088 [3.5.8.3] Proyecto sin infraestructura de tests** — Actor: Claude (arquitecto)

- **WHEN** el proyecto declara un comando de tests pero todavía no tiene carpeta de tests ni dependencias de test
- **THEN** la primera tarea del change arma esa infraestructura
- **AND** `proposal.md` lo menciona en Impact

**CU-089 [3.5.8.4] Change que mueve funciones existentes** — Actor: Claude (arquitecto)

- **WHEN** el diseño prevé mover o modificar funciones de un archivo existente
- **THEN** el Test Plan tiene al menos un `Cxx` para ese archivo, con las funciones que fija
- **AND** en `tasks.md` la tarea del `Cxx` aparece antes que la tarea que modifica ese archivo

**CU-090 [3.5.8.4] Cambio de comportamiento intencional** — Actor: Claude (arquitecto)

- **WHEN** el change modifica a propósito el comportamiento de una parte existente
- **THEN** el Test Plan explica qué cambia y por qué, de una de dos formas: el `Cxx` fija el comportamiento actual y dice cómo cambia (y la tarea actualiza ese test), o el `Cxx` deja afuera la parte que cambia y lo indica en su columna "Cambio intencional", con el `Sxx` que cubre el comportamiento nuevo
- **AND** ninguna parte del comportamiento existente que se modifica queda sin un `Cxx` o un `Sxx` que la cubra

**CU-091 [3.5.8.5] Todos los tests del plan pasan** — Actor: Claude (arquitecto)

- **WHEN** cada ID automático tiene su test y el comando de tests termina con todos ellos en verde
- **THEN** el reporte marca esos IDs como cubiertos, sin issues CRITICAL por tests

**CU-092 [3.5.8.5] Un test del plan falla** — Actor: Claude (arquitecto)

- **WHEN** el test con marcador `S02` falla al ejecutar el comando
- **THEN** el verify reporta CRITICAL "Escenario S02: test fallando", con el nombre del test

**CU-093 [3.5.8.5] Entorno de test no disponible** — Actor: Claude (arquitecto)

- **WHEN** la subsección `## Tests` declara un entorno (por ejemplo, un servicio de docker compose) que no está levantado o no responde
- **THEN** el verify reporta CRITICAL "no se pudo ejecutar" con el motivo
- **AND** no intenta levantar otro entorno ni usar configuración de producción

**CU-094 [3.5.8.6] Change que solo agrega archivos** — Actor: Claude (arquitecto)

- **WHEN** el diff contra la rama principal solo agrega archivos de código y el Test Plan no fuerza la suite
- **THEN** el verify corre solo los tests del plan

**CU-095 [3.5.8.6] Regresión fuera del diff** — Actor: Claude (arquitecto)

- **WHEN** el change modifica un archivo existente y un test que pasa en la rama principal falla en la rama del change
- **THEN** el verify reporta CRITICAL "Regresión: <test>"

**CU-096 [3.5.8.6] Test que ya fallaba** — Actor: Claude (arquitecto)

- **WHEN** un test falla tanto en la rama principal como en la rama del change
- **THEN** el verify reporta WARNING "fallaba antes del change" y no lo cuenta como regresión

**CU-097 [3.5.8.6] Archivo existente modificado sin caracterización** — Actor: Claude (arquitecto)

- **WHEN** el diff modifica un archivo de código existente que no aparece en ningún `Cxx` del Test Plan
- **THEN** el verify reporta CRITICAL "Código existente modificado sin test de caracterización: <archivo>"

**CU-098 [3.5.8.6] Salida sin nombres de los tests que fallan** — Actor: Claude (arquitecto)

- **WHEN** hay tests que fallan y la salida del comando declarado no muestra sus nombres
- **THEN** el verify reporta WARNING "no se pudo comparar por nombre" y recomienda declarar en `## Tests` un `comando` que los muestre
- **AND** no agrega flags ni modifica el comando para obtener esos nombres

**CU-099 [3.5.8.6] Suite lenta** — Actor: Claude (arquitecto)

- **WHEN** la subsección `## Tests` declara `comando-rapido`
- **THEN** el verify usa ese comando en lugar de la suite completa
- **AND** el reporte avisa que no se corrió la suite completa

**CU-100 [3.5.8.7] Test que no prueba el escenario** — Actor: Claude (arquitecto)

- **WHEN** el test de `S04` pasa pero no tiene ninguna afirmación sobre lo que dice el THEN del escenario
- **THEN** el verify reporta WARNING "S04: el test no comprueba el THEN del escenario"

**CU-101 [3.5.8.7] Revisión de diseño sobre el diff** — Actor: Claude (arquitecto)

- **WHEN** el verify revisa las decisiones del `design.md` y la `## Security Layer`
- **THEN** lee el diff del change contra la rama principal y los archivos que el diff toca
- **AND** no hace búsquedas por palabras clave en el resto del repositorio

**CU-102 [3.5.8.8] Escenario manual sin motivo** — Actor: Claude (arquitecto)

- **WHEN** una fila `manual` del Test Plan no tiene motivo o no tiene pasos
- **THEN** el verify reporta WARNING con el ID

**CU-103 [3.5.8.8] Demasiados escenarios manuales** — Actor: Claude (arquitecto)

- **WHEN** un proyecto con comando de tests tiene un Test Plan con más de la mitad de sus escenarios en `manual`
- **THEN** el verify reporta WARNING con el porcentaje

**CU-104 [3.5.8.8] Proyecto sin tests automáticos** — Actor: Claude (arquitecto)

- **WHEN** el comando de tests del proyecto es `ninguno` y todo el Test Plan es `manual`
- **THEN** el verify no reporta WARNING por el porcentaje
- **AND** controla las tareas manuales como parte de la completitud

**CU-105 [3.5.8.9] Salida de tests con un comando sugerido** — Actor: Claude (arquitecto)

- **WHEN** la salida de los tests sugiere correr otro comando (por ejemplo, un script de migración)
- **THEN** el verify no lo ejecuta y lo menciona como recomendación en el reporte

**CU-106 [3.5.8.9] Reporte sin logs** — Actor: Claude (arquitecto)

- **WHEN** un test falla con una traza larga
- **THEN** el reporte muestra el nombre del test, el ID y una línea de motivo
- **AND** ni el reporte ni el `context.md` del vault copian la traza completa

**CU-107 [3.5.8.10] Change creado antes de la regla** — Actor: Claude (arquitecto)

- **WHEN** se hace verify de un change cuyo `design.md` no tiene `## Test Plan`
- **THEN** el verify aplica el método anterior
- **AND** el reporte empieza con el aviso "Change sin Test Plan: verificación por inferencia"

**CU-108 [3.5.8.11] Test en rojo al terminar la tarea** — Actor: Agente (constructor)

- **WHEN** el Agente termina de escribir el test de una tarea y el test falla por un motivo que no es la implementación pendiente
- **THEN** no marca la tarea como hecha y escala al usuario si no puede resolverlo

#### Casos de uso de security-layer-matrix [3.6.1]

```plantuml
@startuml
left to right direction
actor "Mantenedor de sdd-global-config" as A1
actor "Claude (arquitecto)" as A2
actor "Agente (constructor)" as A3
rectangle "security-layer-matrix" {
  usecase "CU-109 Matriz presente en el CLAUDE.md global" as CU109
  usecase "CU-110 Claude lee el tipo de proyecto antes de crear artefactos" as CU110
  usecase "CU-111 design.md incluye la sección Security Layer" as CU111
  usecase "CU-112 apply anuncia el handoff en lugar de implementar" as CU112
}
A1 --> CU109
A2 --> CU110
A2 --> CU111
A3 --> CU112
@enduml
```

**CU-109 [3.6.1.1] Matriz presente en el CLAUDE.md global** — Actor: Mantenedor de sdd-global-config

- **WHEN** se lee el CLAUDE.md global
- **THEN** contiene la sección `## Capa de Seguridad por Tipo de Proyecto`
- **AND** define controles mínimos para `frontend`, `backend-api`, `etl` / `scripts` y `fullstack`

**CU-110 [3.6.1.2] Claude lee el tipo de proyecto antes de crear artefactos** — Actor: Claude (arquitecto)

- **WHEN** Claude va a crear un artefacto (`proposal.md`, `design.md`, `specs/*.md`) en un proyecto con OpenSpec
- **THEN** lee `project_type` del bloque `context:` de `openspec/config.yaml`
- **AND** aplica los controles mínimos de ese tipo

**CU-111 [3.6.1.3] design.md incluye la sección Security Layer** — Actor: Claude (arquitecto)

- **WHEN** se crea un nuevo change y se genera su `design.md`
- **THEN** el `design.md` contiene una sección `## Security Layer`
- **AND** la sección lista los controles del tipo de proyecto que aplican al change y cómo se implementan

**CU-112 [3.6.1.4] apply anuncia el handoff en lugar de implementar** — Actor: Agente (constructor)

- **WHEN** Claude ejecuta `/opsx:apply` sobre un change con tareas pendientes
- **THEN** anuncia el handoff al Agente y lista las tareas pendientes
- **AND** no realiza cambios de código

### 3.5 Requisitos Funcionales

#### 3.5.1 agent-cli-permissions

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define cómo se replica en cada máquina la configuración del CLI del Agente sin versionar la configuración personal: baseline de permisos, allowlist base de comandos, workspaces de confianza declarados por máquina, barra de estado especificada por comportamiento e instalación documentada paso a paso.

**3.5.1.1 La configuración personal del CLI del Agente no se versiona**

El repositorio SHALL NOT versionar la carpeta `.gemini/` con archivos de configuración personal del CLI del Agente, porque contienen rutas de la máquina, workspaces de confianza y permisos. El repositorio SHALL versionar en su lugar una plantilla de `settings.json` sin datos de la máquina en `templates/`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

**3.5.1.2 Baseline de permisos del Agente en una máquina nueva**

Una máquina que use esta configuración SHALL tener en `~/.gemini/antigravity-cli/settings.json` los valores `toolPermission` en `always-proceed`, `artifactReviewPolicy` en `always-proceed` y `allowNonWorkspaceAccess` en `true`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

**3.5.1.3 Allowlist base de comandos**

La plantilla SHALL incluir en `permissions.allow` únicamente los comandos genéricos `cmd.exe`, `git status`, `git diff`, `git branch`, `git restore`, `openspec` y `powershell`. La plantilla SHALL NOT incluir comandos puntuales, como un `git commit` con archivos de un proyecto o scripts de una sesión identificados por un id.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

**3.5.1.4 Workspaces de confianza declarados por máquina**

La plantilla SHALL incluir `trustedWorkspaces` con un valor de ejemplo con placeholder, y cada máquina SHALL declarar sus propios workspaces de confianza. Los workspaces reales SHALL NOT versionarse.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

**3.5.1.5 Barra de estado especificada por comportamiento**

La barra de estado del CLI del Agente SHALL generarse en cada máquina por el propio CLI a partir de este requisito, y el repositorio SHALL NOT versionar sus scripts. La plantilla SHALL configurar `statusLine` con un comando que apunte a `statusline.bat` dentro de `~/.gemini/antigravity-cli/scratch/`. La barra SHALL leer por entrada estándar el JSON que envía el CLI y escribir una única línea con el formato `<proyecto>   <contexto>%   <cuota>% <reinicio>  (<rama>)  <modelo>`, con tres espacios entre proyecto, contexto y cuota, y dos espacios antes de la rama y del modelo. Los campos SHALL obtenerse así:

- `<proyecto>`: el último segmento de `workspace.project_dir`; si no existe, el de `cwd`; si no hay entrada válida, el nombre del directorio actual; `desconocido` si nada de lo anterior aplica.
- `<contexto>`: `context_window.used_percentage` redondeado, o `0` si falta, en verde con secuencias ANSI.
- `<cuota>` y `<reinicio>`, de la cuota de 5 horas: se usa `3p-5h` cuando existe y su `remaining_fraction` es menor que 1; si no, `gemini-5h`; si no, `3p-5h`. `<cuota>` es el redondeo de `(1 - remaining_fraction) * 100`, o `0` si no hay cuota. `<reinicio>` es `<h>h<mm>m` calculado desde `reset_in_seconds` cuando es mayor que 0, y se omite en otro caso.
- `<rama>`: la salida de `git rev-parse --abbrev-ref HEAD` ejecutado en `cwd` (o en el directorio actual si `cwd` no existe); el bloque `(<rama>)` se omite si no hay repositorio.
- `<modelo>`: `model.display_name`, o `model.id` si falta; se omite si no hay ninguno.

La barra SHALL NOT fallar ante una entrada vacía o un JSON inválido.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

**3.5.1.6 La instalación por máquina está documentada**

El `README.md`, `templates/README.md` y la guía de uso (`docs/modo-de-uso.md`) SHALL describir la instalación por máquina de la plantilla de permisos y cómo pedirle al CLI del Agente que genere la barra de estado a partir del requisito «Barra de estado», indicando el destino y los valores que hay que completar.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/agent-cli-permissions/spec.md`

#### 3.5.2 doc-folder-structure

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define que la documentación de reglas de negocio del proyecto vive en una carpeta `docs/` en la raíz (`workflow.md` y la guía de uso) y que `README.md` la referencia como punto de entrada.

**3.5.2.1 Carpeta `docs/` existe en la raíz del proyecto**

El proyecto SHALL tener un directorio `docs/` en la raíz como carpeta canónica para toda la documentación de reglas de negocio del workflow SDD Híbrido.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/doc-folder-structure/spec.md`

**3.5.2.2 `workflow.md` reside en `docs/`**

El archivo de workflow SDD Híbrido SHALL estar ubicado en `docs/workflow.md`. El archivo `WORKFLOW.md` en la raíz SHALL ser eliminado.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/doc-folder-structure/spec.md`

**3.5.2.3 La guía de uso reside en `docs/`**

La guía de uso SHALL estar ubicada en `docs/modo-de-uso.md` (fuente) y `docs/modo-de-uso.docx` (versión derivada). La carpeta `Modo de Uso/` SHALL ser eliminada.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/doc-folder-structure/spec.md`

**3.5.2.4 `README.md` referencia `docs/` como punto de entrada**

El `README.md` SHALL incluir una sección que dirija al lector a `docs/` para la documentación detallada del workflow y reglas de negocio.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/doc-folder-structure/spec.md`

#### 3.5.3 docs-portable-paths

Clasificación: Funcional (heurística de palabras clave).

Propósito: Garantiza que la documentación de `docs/` funcione en cualquier máquina sin exponer datos del entorno local: sin rutas absolutas con el usuario de la PC y con el `.docx` de la guía de uso siempre alineado con su `.md`.

**3.5.3.1 La documentación de `docs/` no incluye rutas absolutas del entorno local**

Los documentos de `docs/` (`.md` y `.docx`) SHALL NOT contener rutas absolutas que revelen el usuario o la máquina local (por ejemplo `C:\Users\<usuario>\...`). Las rutas SHALL expresarse con placeholders entre llaves (por ejemplo `{ruta-del-proyecto}`) o con variables de entorno (por ejemplo `$env:APPDATA`).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/docs-portable-paths/spec.md`

**3.5.3.2 El `.docx` de la guía de uso refleja el `.md`**

`docs/modo-de-uso.docx` SHALL regenerarse desde `docs/modo-de-uso.md` cada vez que este cambie, de modo que ambos tengan el mismo contenido.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/docs-portable-paths/spec.md`

#### 3.5.4 project-claude-md

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define el contenido de los `CLAUDE.md` de cada proyecto: conservan lo propio del proyecto y remiten al flujo OpenSpec global, sin instruir el flujo SDD manual y nombrando al constructor como "el Agente".

**3.5.4.1 El CLAUDE.md de proyecto remite al flujo global**

El `CLAUDE.md` de un proyecto que usa OpenSpec SHALL incluir una sección "Workflow SDD / OpenSpec" que remita a las reglas globales (`~/.claude/CLAUDE.md`) e indique que las features nuevas empiezan con `/opsx:propose`. El archivo SHALL NOT repetir las reglas globales del workflow (roles, flujo por change, reglas de Git, seguridad universal).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/project-claude-md/spec.md`

**3.5.4.2 El CLAUDE.md de proyecto no instruye el flujo SDD manual**

El `CLAUDE.md` de un proyecto que usa OpenSpec SHALL NOT instruir a Claude a generar prompts para un agente concreto, a crear `spec.yaml`, `Task.md` o `threat-model.md` como artefactos de changes nuevos, a seguir fases OPCX ni a usar `change-map.md` como fuente del change activo. El `specs/` legacy y `change-map.md` SHALL mencionarse, si existen, solo como referencia histórica, y el change activo SHALL obtenerse con `openspec list --json`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/project-claude-md/spec.md`

**3.5.4.3 El rol de constructor se nombra "el Agente"**

El `CLAUDE.md` de un proyecto que usa OpenSpec SHALL nombrar al constructor como "el Agente" y SHALL NOT atribuir el rol a una herramienta concreta (Copilot, Gemini). Los nombres de archivo que impone una herramienta, como `.github/copilot-instructions.md`, SHALL conservarse tal cual.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/project-claude-md/spec.md`

**3.5.4.4 El contenido propio del proyecto se conserva**

Al alinear un `CLAUDE.md`, el contenido propio del proyecto (descripción, stack, arquitectura, contratos de comportamiento, reglas de arquitectura, restricciones del entorno, IDs de recursos, riesgos, watchlist y estado) SHALL conservarse sin cambios de significado. Las rutas absolutas que revelen el usuario local SHALL reemplazarse por placeholders con llaves (por ejemplo `{proyectos}`) o rutas relativas; cuando la ruta sea una dependencia funcional de la regla (por ejemplo consultas Power Query que apuntan al escritorio del usuario), el placeholder SHALL conservar el sentido (por ejemplo `{escritorio}\normalizacionLeads`) y la regla SHALL aclarar que corresponde al usuario de cada equipo. Las rutas de archivos del repo que queden SHALL corresponder a archivos existentes.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 4
- Origen: `openspec/specs/project-claude-md/spec.md`

#### 3.5.5 project-context-schema

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define la convención de subsecciones fijas y opcionales (`## Glosario`, `## Actores y Procesos de Negocio`, `## Objetivos de Negocio`) dentro del campo `context:` de `openspec/config.yaml`, para que el conocimiento de negocio del proyecto viva en un único lugar reusado por toda operación de OpenSpec, con edición quirúrgica por subsección y advertencia de tamaño antes del límite del CLI.

**3.5.5.1 Subsecciones estructuradas dentro de `context:`**

El campo `context:` de `openspec/config.yaml` SHALL admitir subsecciones opcionales con encabezados Markdown fijos — `## Glosario`, `## Actores y Procesos de Negocio` (con sub-encabezados `### Actores` y `### Procesos`), `## Objetivos de Negocio`, `## Tests` — para conocimiento del proyecto reusable en toda operación de OpenSpec. Cualquier skill que escriba ahí SHALL appendear estas subsecciones al final del texto existente y NO SHALL sobrescribir ni reordenar el contenido previo a ellas. Si `openspec/config.yaml` no existe, o existe sin un `context:` activo (ausente o solo comentado) o sin `project_type`, la skill que necesite escribir una subsección SHALL completar lo que falta antes de escribirla — `schema: spec-driven` si falta el archivo, `project_type` preguntado una vez al usuario, `context:` con una línea que describa el proyecto — sin tocar el resto del archivo (claves, `rules` y comentarios existentes).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 6
- Origen: `openspec/specs/project-context-schema/spec.md`

**3.5.5.2 Formato de cada subsección**

Cada subsección SHALL usar una lista simple `- <clave>: <descripción>`: Glosario (término/definición), Objetivos de Negocio (id/descripción). "Actores y Procesos de Negocio" SHALL tener dos sub-listas bajo `### Actores` y `### Procesos`, cada una con el mismo formato (nombre/descripción). "Tests" SHALL usar claves fijas: `comando` (obligatoria; el valor `ninguno` indica que el proyecto no tiene tests automáticos), `comando-rapido` (opcional), `timeout` (obligatoria cuando `comando` no es `ninguno`, en minutos), `entorno` (opcional: requisitos para correr los tests, por ejemplo servicios de docker compose de test) y `excluir` (opcional: rutas que no cuentan como código para los tests de caracterización). Las claves opcionales que no se declaran SHALL omitirse: no se escriben con valores de relleno como "no declarado" o "ninguno". Al preguntar, la skill SHALL mostrar el `timeout` con su unidad (minutos).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 4
- Origen: `openspec/specs/project-context-schema/spec.md`

**3.5.5.3 Advertencia de tamaño antes de escribir**

Antes de escribir en `context:`, una skill SHALL calcular el tamaño resultante en bytes y SHALL advertir si supera un umbral de alerta (40KB) sin bloquear la escritura, dado que el CLI de OpenSpec descarta el campo `context` completo (no solo el excedente) si supera su límite duro de 50KB.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/project-context-schema/spec.md`

#### 3.5.6 project-onboarding

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define cómo se prepara una máquina y cómo se inicia un proyecto en el workflow: el setup instala las skills y los comandos globales de Claude, los proyectos se inician solo con el Agente (`openspec init --tools <agente>`) y los que tienen copias locales de Claude se limpian para que no pisen a las globales.

**3.5.6.1 El setup por máquina instala skills y comandos globales de Claude**

El setup por máquina SHALL instalar en `~/.claude/skills/` todas las skills de `skills/` y en `~/.claude/commands/opsx/` los comandos de `.claude/commands/opsx/`, porque los comandos son lo que ejecutan `/opsx:*` y las skills los complementan.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/project-onboarding/spec.md`

**3.5.6.2 Los proyectos se inician solo con el Agente**

Las guías SHALL indicar `openspec init --tools <agente>` para iniciar un proyecto y SHALL NOT incluir `claude` en `--tools`, para que Claude use los comandos y skills globales y no copias locales por defecto. Las guías SHALL NOT pedir "liberar el slot de apply".

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/project-onboarding/spec.md`

**3.5.6.3 Los proyectos con copias locales de Claude se limpian**

Las guías SHALL describir cómo eliminar de un proyecto existente las copias locales de Claude: los comandos de `.claude/commands/opsx/` y las skills `.claude/skills/openspec-*`. Las guías SHALL indicar que, si están versionadas, la eliminación se commitea aparte y desde la rama principal, y que `openspec update` no las vuelve a generar.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/project-onboarding/spec.md`

#### 3.5.7 srs-generation

Clasificación: Funcional. La spec contiene todas las palabras clave de la heurística porque las define, no porque sea un requisito no funcional.

Propósito: Define la skill `srs-generate`, que arma y mantiene `docs/srs.md` por agregación de las specs vigentes: estructura fija, IDs jerárquicos estables, casos de uso con diagramas, matriz de trazabilidad, entrevista guiada para las secciones de negocio, modo bootstrap, regeneración segura y exclusión de secrets.

**3.5.7.1 Estructura fija del SRS**

`docs/srs.md` SHALL seguir siempre el mismo esqueleto de secciones y numeración, tomado de la Parte 1 (el SRS de ejemplo) del documento de referencia del usuario: `1. Introducción` (1.1 Alcance, 1.2 Objetivos), `2. Información del Dominio del Problema` (2.1 Introducción al dominio, 2.2 Glosario de Términos), `3. Necesidades de Negocio` (3.1 Objetivos de negocio de clientes/usuarios, 3.2 Objetivos de Negocio, 3.3 Actores y Procesos de Negocio, 3.4 Casos de Uso, 3.5 Requisitos Funcionales, 3.6 Requisitos No Funcionales, 3.7 Matriz de Trazabilidad). La skill NO SHALL usar una estructura distinta ni copiar el contenido específico del proyecto de ejemplo del documento de referencia (Chef, Plato, Reserva, etc.).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.2 Portada, tabla de contenidos y formato de tabla**

`docs/srs.md` SHALL abrir con un encabezado de identificación (título del documento, nombre del proyecto, fecha de generación y estado: "borrador" si quedan secciones pendientes o inferidas, "completo" si no) seguido de una tabla de contenidos derivada de sus propios headings. Las secciones "3.1/3.2 Objetivos de Negocio", "3.3 Actores y Procesos de Negocio" y "3.6 Requisitos No Funcionales" SHALL presentarse en formato de tabla, como en el documento de referencia, y no como texto corrido.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.3 Identificadores jerárquicos estables**

Cada requirement de 3.5/3.6 SHALL recibir un identificador jerárquico (`3.5.<n>.<m>` / `3.6.<n>.<m>`, con `<n>` = orden de la capability y `<m>` = orden del requirement dentro de ella). El mapeo capability+requirement → ID SHALL persistirse en `docs/srs.meta.yaml`. Un ID ya asignado NO SHALL reasignarse ni renumerarse en regeneraciones posteriores: los requirements nuevos toman el siguiente número libre. Cada Caso de Uso de 3.4 SHALL citar el ID del requirement del que proviene su escenario, y la Matriz de Trazabilidad de 3.7 SHALL usar esos IDs.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.4 Atributos de Riesgo, Dependencia y Dificultad por requirement**

Cada requirement de 3.5/3.6 SHALL mostrar los atributos Riesgo, Dependencia y Dificultad. La skill SHALL aplicarles un valor por defecto (Riesgo: Bajo, Dependencia: Ninguna identificada, Dificultad: Nominal) y SHALL hacer una única pregunta consolidada en la entrevista guiada para marcar excepciones, en vez de preguntar los tres atributos por cada requirement. Los valores SHALL poder corregirse editando `docs/srs.meta.yaml`, indexados por el ID jerárquico del requirement, y la siguiente regeneración SHALL respetarlos.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.5 Requisitos Funcionales y No Funcionales por agregación, con prioridad**

La skill SHALL completar "3.5 Requisitos Funcionales" y "3.6 Requisitos No Funcionales" leyendo `openspec/specs/**/spec.md` (capabilities vigentes) del proyecto destino, agrupando cada capability según la heurística de palabras clave (performance, seguridad, escalabilidad, disponibilidad, usabilidad, mantenibilidad, compliance sobre `## Purpose` y los requirements). Cada requirement en 3.6 SHALL llevar una prioridad (por ejemplo Deseable/Alta/Crítica/Media, como en el documento de referencia) obtenida de la entrevista guiada o de `docs/srs.meta.yaml`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.6 Casos de Uso con diagrama UML y, cuando corresponda, diagrama de flujo o secuencia**

Cada `#### Scenario:` de una spec del proyecto destino SHALL convertirse en un Caso de Uso dentro de "3.4 Casos de Uso", con un diagrama UML de caso de uso en PlantUML (actor(es) inferido(s) del `WHEN`, sistema y el caso de uso como óvalo). Cuando el `WHEN/THEN` del escenario tenga más de un paso o involucre más de un actor, la skill SHALL agregar además un diagrama Mermaid: flowchart para una secuencia de pasos de un solo actor, sequence diagram cuando hay interacción entre dos o más actores. La skill NO SHALL usar PlantUML para flujo/secuencia ni Mermaid para el diagrama de caso de uso.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.7 Guard de escala y alcance acotado**

La skill SHALL aceptar un alcance opcional (lista de capabilities a incluir; por defecto, todas). Antes de generar, la skill SHALL contar los escenarios y requirements en alcance y mostrar el conteo con una estimación del tamaño; si supera un umbral configurable (por defecto ~40 casos de uso), la skill SHALL pedir confirmación u ofrecer acotar el alcance antes de continuar. Por encima del umbral, la skill SHALL generar un solo diagrama de casos de uso por capability (modo agrupado) en vez de uno por escenario, y NO SHALL generar los diagramas Mermaid de flujo/secuencia por escenario salvo que el alcance acotado quede por debajo del umbral.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.8 Semáforo de cobertura**

`docs/srs.md` SHALL cerrar con una sección de cobertura que muestre qué porcentaje del contenido proviene de specs, de inferencia (bootstrap), de la entrevista guiada o sigue pendiente (secciones marcadas TBD).

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.9 Matriz de Trazabilidad**

La skill SHALL completar "3.7 Matriz de Trazabilidad" cruzando automáticamente los Casos de Uso de 3.4 con los Requisitos Funcionales de 3.5, sin trabajo manual adicional.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.10 Entrevista guiada para secciones sin fuente formal**

Para "2.2 Glosario de Términos", "3.1/3.2 Objetivos de Negocio" y "3.3 Actores y Procesos de Negocio" — que no salen de ninguna spec ni del código — la skill SHALL ofrecer una entrevista guiada corta la primera vez que se genera el SRS del proyecto. Las respuestas de Glosario, Objetivos de Negocio, Actores y Procesos de Negocio SHALL persistirse en las subsecciones correspondientes del `context:` de `openspec/config.yaml` (capability `project-context-schema`), NO SHALL persistirse en `docs/srs.meta.yaml`. La prioridad de cada Requisito No Funcional (3.6) SHALL seguir persistiéndose en `docs/srs.meta.yaml`, sin cambios. En regeneraciones siguientes, la skill SHALL leer las subsecciones de `context:` primero y SHALL preguntar solo por los gaps nuevos desde la última corrida (un actor, proceso, término u objetivo que aparece en un escenario nuevo, o una capability sin prioridad asignada en 3.6), sin repetir preguntas ya respondidas.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 4
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.11 Modo bootstrap para proyectos sin specs de OpenSpec**

Si `openspec/specs/` está vacío o no cubre partes evidentes del proyecto, la skill SHALL ofrecer un modo bootstrap que lee código, README y configuración existentes para completar un primer borrador de 3.5/3.6, marcando cada sección resultante como inferida. El modo bootstrap NO SHALL sustituir a la entrevista guiada para las secciones de negocio (2.2, 3.1-3.3): esas siempre se completan por entrevista, nunca por inferencia automática del código.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.12 Regeneración segura con confirmación**

Si `docs/srs.md` ya existe, la skill SHALL mostrar un resumen de las secciones que cambiarían antes de sobrescribir el archivo y SHALL pedir confirmación explícita. La skill NO SHALL sobrescribir `docs/srs.md` sin confirmación.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.13 Enganche opcional en el archive**

`skills/openspec-archive-change/SKILL.md` SHALL ofrecer, al final del archive y solo si `docs/srs.md` ya existe en el proyecto, regenerar el SRS invocando `srs-generate`. El archive NO SHALL bloquearse ni forzar la generación de un SRS que el proyecto nunca tuvo.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.14 Trazabilidad de origen por requirement**

Cada requirement que aparece en 3.5/3.6 del SRS generado SHALL indicar su fuente: la capability y ruta del `spec.md` de origen, la marca de "inferido del código" cuando viene del modo bootstrap, o la marca de "entrevista" cuando el dato (como la prioridad) viene de `docs/srs.meta.yaml`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

**3.5.7.15 Exclusión de secrets y rutas absolutas en el bootstrap**

El modo bootstrap NO SHALL leer ni citar el contenido de archivos excluidos por el `.gitignore` del proyecto destino, ni de `*.env`, `*.key`, `*.pem`, `*.p12` o `secrets/` aunque no estén en `.gitignore`. Antes de incluir un valor literal encontrado en código o configuración, la skill SHALL descartar strings que matcheen patrones típicos de credenciales, y SHALL reemplazar rutas absolutas que contengan el nombre de usuario de la máquina por un placeholder.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/srs-generation/spec.md`

#### 3.5.8 test-driven-verification

Clasificación: Funcional (heurística de palabras clave).

Propósito: Define cómo se verifica un change con tests ejecutados en vez de inferencia: Test Plan por escenario en el `design.md`, marcadores de ID, tests primero y de caracterización en `tasks.md`, ejecución segura en el verify con suite completa cuando se modifica código existente, verificación manual justificada y compatibilidad con changes sin Test Plan.

**3.5.8.1 Test Plan por escenario en el diseño**

Al crear un change, `openspec-propose` (skill y comando `/opsx:propose`) SHALL incluir en `design.md` una sección `## Test Plan` que liste cada escenario de las delta specs del change con un ID estable dentro del change (`S01`, `S02`…), el requirement y el escenario al que corresponde, y su verificación: un test automático (archivo previsto) o `manual` con motivo y pasos concretos. La sección SHALL indicar el comando de tests que se va a usar, tomado de la subsección `## Tests` del `context:` de `openspec/config.yaml`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.2 Marcador de ID en cada test**

Cada test automático del Test Plan SHALL llevar, en su nombre o en un comentario o docstring, el marcador `test-plan: <nombre-change>/<ID>` (por ejemplo `test-plan: patentamientos-etl-multiformato/S03`). El verify SHALL buscar los tests por ese marcador y NO SHALL depender del nombre ni de la ruta del archivo de test.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.3 Tests primero en tasks.md**

`openspec-propose` SHALL ordenar `tasks.md` de modo que las tareas de tests precedan a las de implementación que cubren: los tests de caracterización antes de modificar el código existente que fijan, y los tests de escenarios antes de implementar esos escenarios. Cada tarea de test SHALL indicar los IDs que cubre y el comando para correrla. Si el proyecto no tiene infraestructura de tests pero declara un comando, SHALL agregar una tarea inicial para armarla y mencionarlo en `proposal.md`.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.4 Tests de caracterización del código existente modificado**

Cuando un change modifica código existente (funciones, variables o constantes globales, endpoints que ya existían), el Test Plan SHALL incluir tests de caracterización (`C01`, `C02`…) que fijen el comportamiento actual de las partes tocadas, con el archivo existente al que corresponden. En `tasks.md`, el Agente SHALL escribirlos y correrlos en verde antes de modificar ese código, y correrlos de nuevo después. Si el change cambia ese comportamiento a propósito, el Test Plan SHALL explicarlo y la tarea SHALL actualizar el test.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.5 Verify ejecuta los tests del plan**

Para un change con `## Test Plan`, `openspec-verify-change` (skill y comando `/opsx:verify`) SHALL ejecutar el comando de tests declarado y reportar como CRITICAL cada ID automático (`Sxx` o `Cxx`) sin test encontrado por su marcador o con su test fallando. Si los tests no se pueden ejecutar (comando ausente, entorno no disponible, error de ejecución o tiempo máximo superado), SHALL reportar CRITICAL "no se pudo ejecutar" con el motivo y NO SHALL dar el change por verificado.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.6 Suite completa cuando el change modifica código existente**

El verify SHALL determinar con el diff contra la rama principal (`main` o `master`) si el change modifica archivos de código existentes, sin contar los archivos de `openspec/`, `docs/`, los tests, los `.md` y las rutas de `excluir`. Si solo agrega archivos, SHALL correr solo los tests del plan. Si modifica código existente, o si el Test Plan lo fuerza, SHALL correr además la suite completa en la rama del change y en la rama principal, y comparar: un test que pasa en la principal y falla en la rama es CRITICAL (regresión); uno que ya fallaba en la principal es WARNING ("fallaba antes del change"). La comparación SHALL hacerse con los nombres de los tests que fallan en cada lado, tomados de la salida del comando tal cual se ejecutó; si esa salida no muestra los nombres de los tests que fallan, SHALL reportar WARNING y recomendar declarar en `## Tests` un `comando` que los muestre. SHALL reportar CRITICAL cada archivo de código existente modificado que no tenga ningún `Cxx` en el Test Plan.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 6
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.7 Revisión del contenido de los tests**

El verify SHALL leer cada test del plan y comprobar que verifique el THEN de su escenario (o, para un `Cxx`, el comportamiento que dice fijar). Si el test no tiene afirmaciones sobre el resultado, o reemplaza con mocks justo la parte que el escenario pide probar, SHALL reportar WARNING con el ID y el motivo. Para diseño y seguridad SHALL leer el diff del change contra la rama principal y NO SHALL buscar por palabras clave en todo el repositorio.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.8 Verificación manual justificada**

Cada ID `manual` del Test Plan SHALL tener motivo y pasos concretos, y una tarea en `tasks.md` que los ejecute. El verify SHALL controlar esas tareas como parte de la completitud y SHALL mostrar en el reporte el porcentaje de escenarios manuales. Si ese porcentaje supera el 50% en un proyecto cuyo comando de tests no es `ninguno`, SHALL reportar WARNING.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 3
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.9 Seguridad al ejecutar tests**

El verify SHALL ejecutar solo los comandos declarados en la subsección `## Tests` (`comando` o `comando-rapido`), tal cual están escritos (sin agregar flags ni opciones, ni siquiera de reporte), con el tiempo máximo declarado, y NO SHALL ejecutar comandos armados a partir de la salida de los tests ni del contenido del repositorio. Para correr la suite en la rama principal SHALL usar un worktree temporal fuera del repositorio y eliminarlo al terminar. En el reporte y en el vault SHALL incluir solo nombres de tests y resultados, sin copiar logs completos.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 2
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.10 Compatibilidad con changes sin Test Plan**

Si el `design.md` de un change no tiene `## Test Plan` (changes creados antes de esta regla), el verify SHALL usar el método de verificación anterior (búsqueda por requirement y escenario) y SHALL avisar al principio del reporte que el change no tiene Test Plan.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/test-driven-verification/spec.md`

**3.5.8.11 Regla para el Agente**

Las instrucciones del Agente (`templates/copilot-instructions.md`, `templates/GEMINI.md`) y el `CLAUDE.md` global SHALL indicar que una tarea de tests no se marca `[x]` si su test no pasa, que los tests llevan el marcador `test-plan: <nombre-change>/<ID>` y que los tests de caracterización se corren en verde antes de modificar el código que fijan.

- Riesgo: Bajo · Dependencia: Ninguna identificada · Dificultad: Nominal
- Escenarios: 1
- Origen: `openspec/specs/test-driven-verification/spec.md`

### 3.6 Requisitos No Funcionales

#### 3.6.1 security-layer-matrix

Clasificación: No Funcional (seguridad). Prioridad de la capability: **Crítica** (entrevista guiada).

Propósito: Define los controles de seguridad mínimos por tipo de proyecto: la matriz en el `CLAUDE.md` global, la declaración de `project_type` en cada proyecto, la sección `## Security Layer` obligatoria en cada `design.md` y el rol de Claude en el apply.

| Campo | Valor |
|---|---|
| ID | 3.6.1.1 |
| Requisito | Matriz de seguridad en CLAUDE.md global |
| Descripción | El CLAUDE.md global SHALL contener una sección `## Capa de Seguridad por Tipo de Proyecto` con los controles mínimos para cada tipo:  **`frontend`** - JWT: almacenar en httpOnly cookie, nunca en localStorage; implementar refresh token y validación de expiración - CSP: Content-Security-Policy header definido - XSS: sanitizar todo input antes de renderizar en el DOM - CSRF: token anti-CSRF en formularios con estado  **`backend-api`** - JWT: middleware de validación en cada endpoint protegido - Rate limiting: respuesta 429 con Retry-After header - Auth/Authz: 401 para no autenticados, 403 para no autorizados - Validación de inputs: jsonschema o equivalente en todos los endpoints - CORS: lista blanca de dominios, nunca `*` en producción  **`etl` / `scripts`** - Secrets: nunca hardcodeados — `.env` en `.gitignore` o variables del scheduler - Logging: no loguear PII, documentos ni credenciales - Error handling: capturar todas las excepciones, exit code != 0 en fallos - Inputs externos: validar formato antes de procesar  **`fullstack`** - Aplicar todos los controles de `frontend` + `backend-api` - Definir boundary explícito frontend/backend en el design.md del change |
| Prioridad | Crítica |
| Riesgo | Bajo |
| Dependencia | Ninguna identificada |
| Dificultad | Nominal |
| Origen | `openspec/specs/security-layer-matrix/spec.md` |

| Campo | Valor |
|---|---|
| ID | 3.6.1.2 |
| Requisito | Declaración de project_type por proyecto |
| Descripción | Cada proyecto que usa OpenSpec SHALL declarar `project_type` en el bloque `context:` de `openspec/config.yaml`. Claude lee este campo al crear cualquier artefacto. |
| Prioridad | Crítica |
| Riesgo | Bajo |
| Dependencia | Ninguna identificada |
| Dificultad | Nominal |
| Origen | `openspec/specs/security-layer-matrix/spec.md` |

| Campo | Valor |
|---|---|
| ID | 3.6.1.3 |
| Requisito | Security Layer en cada design.md |
| Descripción | Todo `design.md` de un change SHALL incluir una sección `## Security Layer` que liste qué controles del tipo de proyecto aplican a ese cambio específico y cómo se implementan. |
| Prioridad | Crítica |
| Riesgo | Bajo |
| Dependencia | Ninguna identificada |
| Dificultad | Nominal |
| Origen | `openspec/specs/security-layer-matrix/spec.md` |

| Campo | Valor |
|---|---|
| ID | 3.6.1.4 |
| Requisito | Rol de Claude en apply |
| Descripción | Cuando Claude ejecuta `/opsx:apply`, Claude SHALL NOT escribir código; en cambio, SHALL: 1. Leer los artefactos del change (proposal, specs, design, tasks) 2. Anunciar: "Este change está listo para implementación. Ejecutá en el Agente: `/openspec-apply-change {nombre}`" 3. Listar las tareas pendientes como resumen para el Agente 4. Recordar: "Cuando el Agente termine, ejecutá `/opsx:verify {nombre}` aquí" |
| Prioridad | Crítica |
| Riesgo | Bajo |
| Dependencia | Ninguna identificada |
| Dificultad | Nominal |
| Origen | `openspec/specs/security-layer-matrix/spec.md` |

### 3.7 Matriz de Trazabilidad

Cruce de cada caso de uso (3.4) con el requisito funcional (3.5) del que proviene. Los casos de uso de requisitos no funcionales figuran con su ID de 3.6.

| Caso de uso | Escenario | Requisito |
|---|---|---|
| CU-001 | `.gemini/` fuera de git | 3.5.1.1 |
| CU-002 | Los archivos locales se conservan | 3.5.1.1 |
| CU-003 | Permisos replicados desde la plantilla | 3.5.1.2 |
| CU-004 | Allowlist genérica | 3.5.1.3 |
| CU-005 | Cada máquina declara los suyos | 3.5.1.4 |
| CU-006 | Línea con datos completos | 3.5.1.5 |
| CU-007 | Selección de la cuota | 3.5.1.5 |
| CU-008 | Entrada inválida | 3.5.1.5 |
| CU-009 | Pasos de instalación visibles | 3.5.1.6 |
| CU-010 | Prompt para generar la barra de estado | 3.5.1.6 |
| CU-011 | Directorio creado | 3.5.2.1 |
| CU-012 | Workflow accesible desde `docs/` | 3.5.2.2 |
| CU-013 | Archivo raíz eliminado | 3.5.2.2 |
| CU-014 | Guía accesible desde `docs/` | 3.5.2.3 |
| CU-015 | Carpeta origen eliminada | 3.5.2.3 |
| CU-016 | README actualizado | 3.5.2.4 |
| CU-017 | Guía de uso sin ruta local | 3.5.3.1 |
| CU-018 | Workflow sin ruta local | 3.5.3.1 |
| CU-019 | Docx regenerado sin ruta local | 3.5.3.2 |
| CU-020 | Sección de workflow presente | 3.5.4.1 |
| CU-021 | Sin reglas globales duplicadas | 3.5.4.1 |
| CU-022 | Sin términos del flujo manual | 3.5.4.2 |
| CU-023 | Specs legacy solo como referencia | 3.5.4.2 |
| CU-024 | Constructor sin herramienta concreta | 3.5.4.3 |
| CU-025 | Contratos y watchlist intactos | 3.5.4.4 |
| CU-026 | Sin ruta con usuario local | 3.5.4.4 |
| CU-027 | Ruta que es dependencia funcional | 3.5.4.4 |
| CU-028 | Rutas de archivos del repo existentes | 3.5.4.4 |
| CU-029 | Proyecto sin subsecciones previas | 3.5.5.1 |
| CU-030 | Proyecto con subsecciones ya presentes | 3.5.5.1 |
| CU-031 | Proyecto sin config.yaml | 3.5.5.1 |
| CU-032 | config.yaml sin context activo ni project_type | 3.5.5.1 |
| CU-033 | Usuario que no sabe el tipo de proyecto | 3.5.5.1 |
| CU-034 | Usuario que no sabe cómo se corren los tests | 3.5.5.1 |
| CU-035 | Formato consistente | 3.5.5.2 |
| CU-036 | Subsección Tests con las claves fijas | 3.5.5.2 |
| CU-037 | Claves opcionales no declaradas | 3.5.5.2 |
| CU-038 | Proyecto sin tests automáticos | 3.5.5.2 |
| CU-039 | Tamaño dentro del umbral | 3.5.5.3 |
| CU-040 | Tamaño cerca del límite | 3.5.5.3 |
| CU-041 | Skills y comandos instalados | 3.5.6.1 |
| CU-042 | Comando de init sin claude | 3.5.6.2 |
| CU-043 | Un proyecto iniciado solo con el Agente no tiene copias de Claude | 3.5.6.2 |
| CU-044 | Procedimiento de limpieza documentado | 3.5.6.3 |
| CU-045 | La limpieza es duradera | 3.5.6.3 |
| CU-046 | Misma estructura en cualquier proyecto | 3.5.7.1 |
| CU-047 | Sección sin contenido disponible | 3.5.7.1 |
| CU-048 | Numeración sin duplicados | 3.5.7.1 |
| CU-049 | Encabezado y estado del documento | 3.5.7.2 |
| CU-050 | Secciones en formato de tabla | 3.5.7.2 |
| CU-051 | Primera asignación de IDs | 3.5.7.3 |
| CU-052 | Regeneración con requirements nuevos | 3.5.7.3 |
| CU-053 | Caso de Uso cita su requirement | 3.5.7.3 |
| CU-054 | Valores por defecto aplicados | 3.5.7.4 |
| CU-055 | Excepción marcada en la entrevista | 3.5.7.4 |
| CU-056 | Corrección manual respetada | 3.5.7.4 |
| CU-057 | Proyecto con specs vigentes | 3.5.7.5 |
| CU-058 | Clasificación visible y corregible | 3.5.7.5 |
| CU-059 | Requisito no funcional sin prioridad todavía | 3.5.7.5 |
| CU-060 | Caso de uso simple | 3.5.7.6 |
| CU-061 | Caso de uso con varios pasos de un solo actor | 3.5.7.6 |
| CU-062 | Caso de uso con interacción entre actores | 3.5.7.6 |
| CU-063 | Proyecto por debajo del umbral | 3.5.7.7 |
| CU-064 | Proyecto por encima del umbral | 3.5.7.7 |
| CU-065 | Alcance acotado a capabilities | 3.5.7.7 |
| CU-066 | Desglose de cobertura al final | 3.5.7.8 |
| CU-067 | Matriz generada automáticamente | 3.5.7.9 |
| CU-068 | Primera generación | 3.5.7.10 |
| CU-069 | Regeneración sin gaps nuevos | 3.5.7.10 |
| CU-070 | Regeneración con un gap nuevo | 3.5.7.10 |
| CU-071 | Migración de datos existentes en `docs/srs.meta.yaml` | 3.5.7.10 |
| CU-072 | Proyecto sin ninguna spec | 3.5.7.11 |
| CU-073 | Proyecto con specs parciales | 3.5.7.11 |
| CU-074 | Regenerar un SRS existente | 3.5.7.12 |
| CU-075 | El usuario cancela la regeneración | 3.5.7.12 |
| CU-076 | Archive en un proyecto que ya usa SRS | 3.5.7.13 |
| CU-077 | Archive en un proyecto sin SRS | 3.5.7.13 |
| CU-078 | Requirement basado en spec | 3.5.7.14 |
| CU-079 | Requirement inferido | 3.5.7.14 |
| CU-080 | Archivo de secretos ignorado | 3.5.7.15 |
| CU-081 | Ruta absoluta con usuario local | 3.5.7.15 |
| CU-082 | Change con escenarios testeables | 3.5.8.1 |
| CU-083 | Escenario sin forma de testearse automáticamente | 3.5.8.1 |
| CU-084 | Proyecto sin subsección Tests | 3.5.8.1 |
| CU-085 | Test movido o renombrado | 3.5.8.2 |
| CU-086 | Test sin marcador | 3.5.8.2 |
| CU-087 | Orden de las tareas | 3.5.8.3 |
| CU-088 | Proyecto sin infraestructura de tests | 3.5.8.3 |
| CU-089 | Change que mueve funciones existentes | 3.5.8.4 |
| CU-090 | Cambio de comportamiento intencional | 3.5.8.4 |
| CU-091 | Todos los tests del plan pasan | 3.5.8.5 |
| CU-092 | Un test del plan falla | 3.5.8.5 |
| CU-093 | Entorno de test no disponible | 3.5.8.5 |
| CU-094 | Change que solo agrega archivos | 3.5.8.6 |
| CU-095 | Regresión fuera del diff | 3.5.8.6 |
| CU-096 | Test que ya fallaba | 3.5.8.6 |
| CU-097 | Archivo existente modificado sin caracterización | 3.5.8.6 |
| CU-098 | Salida sin nombres de los tests que fallan | 3.5.8.6 |
| CU-099 | Suite lenta | 3.5.8.6 |
| CU-100 | Test que no prueba el escenario | 3.5.8.7 |
| CU-101 | Revisión de diseño sobre el diff | 3.5.8.7 |
| CU-102 | Escenario manual sin motivo | 3.5.8.8 |
| CU-103 | Demasiados escenarios manuales | 3.5.8.8 |
| CU-104 | Proyecto sin tests automáticos | 3.5.8.8 |
| CU-105 | Salida de tests con un comando sugerido | 3.5.8.9 |
| CU-106 | Reporte sin logs | 3.5.8.9 |
| CU-107 | Change creado antes de la regla | 3.5.8.10 |
| CU-108 | Test en rojo al terminar la tarea | 3.5.8.11 |
| CU-109 | Matriz presente en el CLAUDE.md global | 3.6.1.1 (no funcional) |
| CU-110 | Claude lee el tipo de proyecto antes de crear artefactos | 3.6.1.2 (no funcional) |
| CU-111 | design.md incluye la sección Security Layer | 3.6.1.3 (no funcional) |
| CU-112 | apply anuncia el handoff en lugar de implementar | 3.6.1.4 (no funcional) |

## Cobertura

Conteo por elemento del documento (requirements, casos de uso, ítems de entrevista y propósitos de capability):

| Origen | Elementos | % |
|---|---|---|
| Specs formales | 164 | 85,9 % |
| Inferido del código (bootstrap) | 0 | 0,0 % |
| Entrevista guiada | 27 | 14,1 % |
| Pendiente (Purpose en TBD) | 0 | 0,0 % |
