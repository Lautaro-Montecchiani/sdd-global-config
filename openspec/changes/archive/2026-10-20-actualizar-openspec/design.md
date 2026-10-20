## Context

Este repo y los proyectos del equipo usan OpenSpec 1.4.1. La 1.14.3 (17/10/2026) cambia cosas que probé en carpetas temporales:

- `openspec init --tools antigravity` escribe en `.agents/skills/` y `.agents/workflows/` (antes `.agent/`); `openspec update` sobre un proyecto con `.agent/` crea `.agents/` y avisa "Left N files in .agent/ that differ… Nothing was overwritten".
- `openspec init --tools cursor` sigue generando `.cursor/commands/opsx-apply.md` y suma `.cursor/skills/openspec-*`.
- `validate --strict` falla con requirements de más de 500 caracteres (1.14.1). Medí 18 de 61 en este repo.
- La telemetría anónima está activa (`openspec config list` muestra `telemetry.anonymousId`).
- `openspec update` también informa limpiezas pendientes de prompts globales de Codex en `~/.codex/prompts`; no borró nada en la prueba.

Nuestros comandos `/opsx:*` y skills `openspec-*` son versiones propias, no se tocan con `openspec update` porque los proyectos se inician sin `claude` en `--tools`.

## Goals / Non-Goals

**Goals:**
- Dejar OpenSpec en 1.14.3 en esta máquina y las guías, specs y `config.yaml` consistentes con esa versión.
- Documentar cómo actualizar un proyecto existente sin perder archivos.
- Desactivar la telemetría por máquina.
- Portar solo las mejoras de 1.14.x que encajan con el flujo híbrido.

**Non-Goals:**
- Actualizar los otros proyectos del equipo (se hace de a uno con la guía nueva).
- Reescribir los 18 requirements de más de 500 caracteres.
- Adoptar `/opsx:update`, los workflows extra del perfil, las herramientas nuevas ni los stores.
- Cambiar el handoff: `/openspec-apply-change` (Antigravity) y `/opsx-apply` (Cursor) siguen igual.

## Decisions

**D1. Versión fija 1.14.3**, instalada con `npm install -g @fission-ai/openspec@1.14.3` y comprobada con `openspec --version`. No usar `latest` para que otra máquina no quede en otra versión.

**D2. `.agents/` para Antigravity.** Las guías, la spec `project-onboarding`, el `context:` de `openspec/config.yaml` y `templates/cursor/README.md` pasan a `.agents/skills/openspec-apply-change/`. Se menciona `.agent/` solo como carpeta anterior que puede quedar. En un proyecto migrado, `.agent/` se compara con `.agents/` y se elimina en un commit aparte desde la rama principal; nunca se borra sin comparar, porque `openspec update` no la borra cuando los archivos difieren.

**D3. `validate` sin `--strict` en el flujo propio.** Los comandos y skills ya usan `openspec validate "<nombre>"` sin `--strict`, así que no hay que cambiarlos; las guías no recomiendan `--strict`. Los requirements nuevos se escriben de hasta 500 caracteres cuando sea posible. Alternativa descartada: acortar los 18 requirements, porque obliga a reescribir specs vigentes (y sus textos en el SRS) sin cambiar el comportamiento.

**D4. El paso 5.2 del archive (completar `## Purpose`) se mantiene.** Solo reemplaza el texto TBD exacto que deja el CLI; si el CLI ya conserva el Purpose del delta, el paso no hace nada. No se toca la spec `spec-purpose`.

**D5. Mejoras de 1.14.x que se portan** (las demás no se adoptan):

| Mejora | Decisión | Motivo |
|---|---|---|
| Propuesta que lee código, tests y documentación antes de redactar (1.12.0) | Adoptar en `propose` | Mejora el contenido de los artefactos |
| Mensaje del apply cuando todas las tareas están marcadas: pide revisar antes de archivar (1.14.1) | Adoptar en `apply` | Evita decir "listo para archivar" antes del verify |
| Verify de requirements REMOVED: lee el texto original de la spec principal antes de buscar en el código (1.14.2) | Adoptar en `verify` | Cubre un hueco del verify actual |
| Tareas con criterio de hecho (1.10.0) | No adoptar | Las reglas de evidencia del Agente ya lo exigen |
| Explore pide permiso antes de escribir (1.11.0) | No adoptar | Nuestro explore no escribe archivos |
| Pre-aprobar el CLI de OpenSpec en skills y comandos (1.6.0) | No adoptar | Cambia permisos; se decide aparte |
| `/opsx:update` y workflows extra del perfil | No adoptar | Planificar revisiones lo cubre `propose`; sin necesidad hoy |

El Agente genera las skills de 1.14.3 en un directorio temporal con `openspec init --tools claude` para tomar el texto exacto de las tres mejoras, y no copia nada más. Los comandos y skills portados siguen idénticos entre sí donde hoy lo son.

**D6. Telemetría apagada por máquina** con `openspec config set telemetry.enabled false` y comprobación con `openspec config get telemetry.enabled`. Según las notas de 1.8.0, esa clave también apaga el chequeo de actualizaciones de `openspec update`; se revisa a mano con `openspec version --check`.

**D7. Handoff sin cambios.** En la prueba, Antigravity instala skills (`openspec-apply-change`) y workflows (`opsx-apply`). El anuncio actual sigue válido; si quien usa Antigravity ve que el comando correcto es otro, se abre un change aparte.

## Security Layer

Proyecto `tooling`: los artefactos modificados son instrucciones para IA.
- Sin secrets ni rutas con el usuario local en guías, specs ni comandos; las verificaciones de rutas usan un script en archivo.
- La telemetría anónima de uso se apaga en máquinas de la empresa (D6).
- La actualización global usa un paquete publicado de la herramienta ya en uso, con versión fija (D1); si Sistemas controla las versiones de `npm`, se les avisa antes.
- Los cambios a comandos y skills se commitean aparte, con la descripción del impacto, y las copias instaladas en `~/.claude` se verifican con hash.
- `openspec update` toca prompts globales de Codex en `~/.codex` según su salida: no se ejecuta `update` en esta máquina fuera de directorios temporales sin revisar esa salida.

## Risks / Trade-offs

- Un proyecto actualizado con `openspec update` queda con `.agent/` y `.agents/` hasta que alguien compare y borre la anterior (D2).
- Con `--strict` fallando para 18 requirements, quien lo use por costumbre verá errores falsos; las guías lo desaconsejan (D3).
- Portar texto de las skills nuevas puede traer diferencias de tono o comportamiento; el verify compara el diff contra el texto de 1.14.3.
- Apagar los chequeos de actualización hace que nadie se entere de versiones nuevas sin mirar: queda `openspec version --check`.

## Migration Plan

1. Instalar 1.14.3 y apagar la telemetría en esta máquina.
2. Actualizar guías, specs, `config.yaml` y los tres comandos y skills.
3. Reinstalar comandos y skills en `~/.claude` y verificar con hash.
4. Cada proyecto del equipo se actualiza aparte con la guía nueva. Si algo sale mal, `npm install -g @fission-ai/openspec@1.4.1` vuelve a la versión anterior.

## Test Plan

Comando de tests: `ninguno` (declarado en `openspec/config.yaml`): los artefactos son Markdown. Todo el plan es manual. No hay tests de caracterización: no se modifica código.

| ID | Requirement / Escenario | Verificación | Archivo previsto |
|---|---|---|---|
| S01 | Los proyectos se inician solo con el Agente / Comando de init sin claude | manual: revisión de contenido. Pasos: buscar `openspec init` en `README.md`, `docs/workflow.md` y `docs/modo-de-uso.md`; confirmar `--tools antigravity` y `--tools cursor`, sin `claude` | guías |
| S02 | Los proyectos se inician solo con el Agente / Un proyecto iniciado solo con el Agente no tiene copias de Claude | manual: requiere un directorio temporal. Pasos: con 1.14.3, `openspec init --tools antigravity` y `openspec update`; confirmar `.agents/skills/openspec-apply-change/` y que no existe `.claude/`; repetir con `--tools cursor` y `.cursor/commands/opsx-apply.md`; borrar el directorio | — |
| S03 | Los proyectos se inician solo con el Agente / Comprobación de Antigravity con la carpeta nueva | manual: revisión de contenido. Pasos: buscar `.agent/skills` y `.agents/skills` en las guías y en `config.yaml`; confirmar que la ruta de comprobación es `.agents/skills/openspec-apply-change/` | guías, `openspec/config.yaml` |
| S04 | Agregar Cursor a proyectos existentes / Procedimiento documentado | manual: revisión de contenido. Pasos: leer la sección de proyecto existente de `docs/workflow.md` y `docs/modo-de-uso.md` y confirmar los dos pasos y el borrado opcional de `.agents/` y `.agent/` en commit aparte | `docs/workflow.md`, `docs/modo-de-uso.md` |
| S05 | Agregar Cursor a proyectos existentes / Proyecto con los dos agentes | manual: requiere un directorio temporal. Pasos: partir de `--tools antigravity`, correr `openspec init --tools cursor` e instalar la regla; confirmar los archivos de Cursor, las skills de Antigravity en `.agents/` y que no hay `.claude/`; borrar el directorio | — |
| S06 | Actualizar OpenSpec en un proyecto existente / Procedimiento de actualización documentado | manual: revisión de contenido. Pasos: leer la sección nueva de las dos guías y confirmar `openspec update`, revisión del diff y qué hacer con `.agent/` | `docs/workflow.md`, `docs/modo-de-uso.md` |
| S07 | Actualizar OpenSpec en un proyecto existente / Un proyecto con .agent/ se migra sin perder archivos | manual: requiere un directorio temporal. Pasos: `openspec init --tools antigravity` con 1.4.1, modificar un archivo de `.agent/`, correr `openspec update` con 1.14.3 y confirmar `.agents/skills/openspec-apply-change/` y que `.agent/` sigue con el archivo modificado; borrar el directorio | — |
| S08 | La telemetría de OpenSpec se desactiva por máquina / Paso de telemetría en el setup | manual: revisión de contenido. Pasos: buscar `telemetry.enabled` en `README.md` y `docs/modo-de-uso.md` | `README.md`, `docs/modo-de-uso.md` |
| S09 | La telemetría de OpenSpec se desactiva por máquina / Telemetría apagada en esta máquina | manual: requiere el CLI. Pasos: ejecutar `openspec config get telemetry.enabled` y pegar la salida | — |

## Open Questions

Sin preguntas abiertas.
