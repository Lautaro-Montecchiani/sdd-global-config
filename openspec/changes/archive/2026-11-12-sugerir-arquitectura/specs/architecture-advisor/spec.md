# Spec Delta

## ADDED Requirements

### Requirement: Claude sugiere la skill arquitectura
Claude SHALL sugerir correr `/arquitectura`, en una línea con el motivo y sin correrla, al iniciar sesión y en el resumen de `/opsx:propose` si `## Arquitectura` no declara `nivel` o declara uno que no es receta; en `/opsx:verify` si un archivo del diff supera la advertencia de `tamaño`; y en la fase del vault de `/opsx:archive` si `arquitectura.md` queda en "sin evaluar". La sugerencia NO SHALL bloquear, ser un desvío ni repetirse en la misma operación.

#### Scenario: Inicio de sesión sin nivel
- **WHEN** se abre una sesión en un proyecto cuyo `## Arquitectura` declara carpetas pero no `nivel`
- **THEN** Claude dice en una línea que el proyecto no tiene nivel evaluado y sugiere correr `/arquitectura`
- **AND** no corre la skill ni escribe en `openspec/config.yaml`

#### Scenario: Propose sin nivel
- **WHEN** se corre `/opsx:propose` en un proyecto sin `nivel` en `## Arquitectura`
- **THEN** el resumen final sugiere correr `/arquitectura`
- **AND** el propose termina igual, con todos sus artefactos

#### Scenario: Verify con un archivo sobre la advertencia
- **WHEN** con `- tamaño: 500, 1000` el diff agranda un archivo de código que queda en 1.150 líneas
- **THEN** el reporte tiene el WARNING de tamaño de siempre y, al final, la sugerencia de correr `/arquitectura`
- **AND** la sugerencia no cuenta como desvío ni cambia la evaluación final

#### Scenario: Archive con nivel sin evaluar
- **WHEN** la fase del vault de `/opsx:archive` escribe `arquitectura.md` con `## Nivel` en "sin evaluar"
- **THEN** el resumen del cierre sugiere correr `/arquitectura`

#### Scenario: Proyecto con nivel declarado
- **WHEN** `## Arquitectura` declara `nivel: 0`, ningún archivo del diff supera la advertencia y `arquitectura.md` tiene nivel
- **THEN** ninguna operación sugiere correr `/arquitectura`

#### Scenario: Dato inválido: nivel desconocido
- **WHEN** se abre una sesión en un proyecto cuyo `## Arquitectura` declara `nivel: 7`
- **THEN** Claude dice que `7` no corresponde a ninguna receta y sugiere correr `/arquitectura`
- **AND** no corrige el valor por su cuenta
