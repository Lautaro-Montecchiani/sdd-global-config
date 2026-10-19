# Spec Delta

## MODIFIED Requirements

### Requirement: Identificadores jerárquicos estables
Cada requirement de 3.5/3.6 SHALL recibir un identificador jerárquico (`3.5.<n>.<m>` / `3.6.<n>.<m>`, con `<n>` = orden de la capability y `<m>` = orden del requirement dentro de ella). El mapeo capability+requirement → ID SHALL persistirse en `docs/srs.meta.yaml`. Un ID ya asignado NO SHALL reasignarse ni renumerarse en regeneraciones posteriores: los requirements nuevos toman el siguiente número libre. Las capabilities SHALL presentarse en 3.5/3.6 ordenadas por su ID jerárquico y NO por nombre de carpeta, de modo que una capability nueva con nombre alfabéticamente anterior quede al final y no desplace a las existentes. Cada Caso de Uso de 3.4 SHALL tener el ID `CU-<ID del requirement>.<n>`, con `<n>` = posición del escenario dentro de su requirement (1, 2, …) y NO un número correlativo global, y su título SHALL citar además el ID del requirement del que proviene. Agregar capabilities o requirements NO SHALL cambiar el ID de los casos de uso existentes. La Matriz de Trazabilidad de 3.7 SHALL usar esos IDs.

#### Scenario: Primera asignación de IDs
- **WHEN** se genera el SRS por primera vez en un proyecto con capabilities
- **THEN** cada requirement de 3.5/3.6 recibe un ID jerárquico
- **AND** el mapeo queda guardado en `docs/srs.meta.yaml`

#### Scenario: Regeneración con requirements nuevos
- **WHEN** se agrega una capability o un requirement nuevo y se regenera el SRS
- **THEN** los IDs ya asignados no cambian
- **AND** lo nuevo recibe el siguiente número libre

#### Scenario: Caso de Uso cita su requirement
- **WHEN** un Caso de Uso de 3.4 proviene del escenario de un requirement de 3.5
- **THEN** el título del Caso de Uso cita el ID de ese requirement

#### Scenario: Orden de las capabilities por ID
- **WHEN** se agrega una capability cuyo nombre es alfabéticamente anterior a las existentes y se regenera el SRS
- **THEN** en 3.5 o 3.6 la capability nueva aparece después de las existentes, ordenadas por su ID jerárquico
- **AND** los IDs de las capabilities existentes no cambian

#### Scenario: ID de caso de uso derivado del requirement
- **WHEN** un requirement con ID `3.5.2.3` tiene dos escenarios
- **THEN** sus casos de uso se llaman `CU-3.5.2.3.1` y `CU-3.5.2.3.2`, en el orden de los escenarios

#### Scenario: Los IDs de casos de uso no cambian al agregar capabilities
- **WHEN** se agrega una capability nueva y se regenera el SRS
- **THEN** cada caso de uso existente conserva su ID `CU-<ID del requirement>.<n>`
- **AND** los casos de uso nuevos usan los IDs de sus propios requirements

### Requirement: Matriz de Trazabilidad
La skill SHALL completar "3.7 Matriz de Trazabilidad" cruzando automáticamente los Casos de Uso de 3.4 con los Requisitos Funcionales de 3.5, sin trabajo manual adicional. Cada fila SHALL citar el ID del caso de uso (`CU-…`) y el ID del requirement funcional del que proviene.

#### Scenario: Matriz generada automáticamente
- **WHEN** 3.4 y 3.5 ya están completas
- **THEN** 3.7 muestra una tabla con cada Caso de Uso y los Requisitos Funcionales que le corresponden, sin que nadie la arme a mano

#### Scenario: La matriz cita los IDs de caso de uso y de requirement
- **WHEN** se genera 3.7
- **THEN** cada fila muestra el ID `CU-…` y el ID jerárquico del requirement funcional correspondiente
