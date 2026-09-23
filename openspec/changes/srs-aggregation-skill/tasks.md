## 1. Skill `srs-generate`

- [ ] 1.1 Crear `skills/srs-generate/SKILL.md` con el frontmatter estándar (name, description, license, compatibility, metadata) y el flujo principal: detectar `openspec/specs/` del proyecto destino, agregar requirements por capability y escribir `docs/srs.md` con la estructura ISO/IEC/IEEE 29148 (Introduction/Scope, Stakeholder Requirements, System Requirements → Functional/Non-Functional)
- [ ] 1.2 En `skills/srs-generate/SKILL.md`, implementar la clasificación Functional/Non-Functional por heurística de palabras clave (performance, seguridad, escalabilidad, disponibilidad, usabilidad, mantenibilidad, compliance) sobre `## Purpose` y los requirements de cada capability, dejando la clasificación visible en el SRS generado
- [ ] 1.3 En `skills/srs-generate/SKILL.md`, implementar el modo bootstrap: cuando `openspec/specs/` está vacío o no cubre partes evidentes del proyecto, ofrecerlo, leer código/README/config existentes y marcar cada sección resultante como "inferido del código, sin spec formal — revisar"; el bootstrap no debe escribir nada en `openspec/specs/`
- [ ] 1.4 En `skills/srs-generate/SKILL.md`, implementar la exclusión de secrets y rutas absolutas del modo bootstrap: no leer/citar archivos excluidos por el `.gitignore` del proyecto destino ni `*.env`, `*.key`, `*.pem`, `*.p12`, `secrets/`; descartar strings que matcheen patrones de credenciales; reemplazar rutas absolutas con el usuario local por un placeholder
- [ ] 1.5 En `skills/srs-generate/SKILL.md`, implementar la regeneración segura: si `docs/srs.md` ya existe, mostrar un resumen de las secciones que cambiarían antes de escribir y pedir confirmación explícita; no sobrescribir si el usuario no confirma
- [ ] 1.6 En `skills/srs-generate/SKILL.md`, implementar la trazabilidad: cada requirement del SRS generado cita la capability/ruta del `spec.md` de origen, o la marca de "inferido" cuando viene del bootstrap

## 2. Enganche opcional en el archive

- [ ] 2.1 Editar `skills/openspec-archive-change/SKILL.md`: agregar un paso al final (después del resumen de archive) que, solo si `docs/srs.md` ya existe en el proyecto, ofrezca regenerarlo invocando `srs-generate`; si `docs/srs.md` no existe, el paso no debe aparecer ni bloquear el archive

## 3. Documentación del setup

- [ ] 3.1 Editar `README.md`: sumar `skills/srs-generate/` a la tabla "Qué contiene" y al paso 3 del setup por máquina (ya cubre "copiar todas las skills de `skills/`", solo falta que la tabla la liste)
- [ ] 3.2 Editar `docs/workflow.md`: sumar `srs-generate` a la lista de skills instaladas por el setup y agregar una descripción breve de su uso (invocación manual on-demand + oferta opcional al final de `/opsx:archive`)

## 4. Verificación

- [ ] 4.1 Verificar que el cambio aplica en un proyecto de prueba: instalar `skills/srs-generate/` en un proyecto con `openspec/specs/` pobladas, correr la skill y confirmar que `docs/srs.md` se genera con una sección por capability, la clasificación Functional/Non-Functional visible y trazabilidad a la spec de origen; si el tiempo lo permite, simular un proyecto sin `openspec/specs/` y confirmar el modo bootstrap con las secciones marcadas como inferidas; confirmar que `/opsx:archive` solo ofrece regenerar el SRS cuando `docs/srs.md` ya existe
