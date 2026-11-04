---
name: arquitectura
description: Diagnostica la arquitectura de un proyecto existente y recomienda un nivel sin crear un change.
license: MIT
metadata:
  version: "1.0"
---

Diagnostica la arquitectura de un proyecto existente y recomienda un nivel sin crear un change.

**Restricciones de ejecución:**
- Esta skill es de **solo lectura**, excepto el paso 6 (edición quirúrgica de `openspec/config.yaml` solo con aprobación explícita del usuario).
- No crea changes, ramas ni commits.
- No escribe en el Obsidian vault.
- **Security Layer:**
  - Solo lee código; no ejecuta código.
  - No lee archivos ni directorios ignorados por `.gitignore`, ni archivos sensibles: `*.env`, `*.key`, `*.pem`, `*.p12`, ni la carpeta `secrets/`.
  - No pega contenido de archivos en el informe: cita rutas relativas, cantidad de líneas y nombres de funciones o responsabilidades.
  - La única escritura permitida es `## Arquitectura` en `openspec/config.yaml` en el paso 6 tras confirmación del usuario.

Las recetas de referencia y pautas por nivel se encuentran en `references/recetas.md` (o `~/.claude/skills/arquitectura/references/recetas.md` cuando está instalada).

---

## Pasos

1. **Lectura de configuración y recetas**
   - Lee `openspec/config.yaml` (`project_type`, `## Arquitectura`) y las recetas de `references/recetas.md`.
   - Sin `openspec/config.yaml`: diagnostica igual y avisa que para guardar el resultado hace falta `openspec init`.

2. **Inventario**
   - Releva carpetas de primer nivel y de `src/`.
   - Releva archivos de código con su cantidad de líneas, aplicando las extensiones de código y exclusiones de D6:
     - Extensiones de código: `.py`, `.ts`, `.tsx`, `.js`, `.jsx`, `.mjs`, `.cjs`, `.vue`, `.svelte`, `.ps1`, `.psm1`, `.cs`, `.java`, `.go`, `.rb`, `.php` y `.sql`.
     - Exclusiones: rutas con un segmento `test/`, `tests/`, `__tests__/`, `spec/`, `migrations/`, `fixtures/` o `data/`; nombres `test_*`, `*_test.*`, `*.test.*`, `*.spec.*`, `*.generated.*`, `*.min.*` y `*.lock`; archivos cuyas primeras 5 líneas contienen "generated" o "do not edit" (sin distinguir mayúsculas); y las rutas de `tamaño-excluir`.
     - Aplica las restricciones de seguridad: no lee lo ignorado por `.gitignore`, `*.env`, `*.key`, `*.pem`, `*.p12` ni `secrets/`.

3. **Nivel actual**
   - Evalúa el nivel actual: el declarado en `## Arquitectura` controlando su coherencia (mínimo de reglas `no importa:` según la receta, o si el nivel es desconocido).
   - Si no hay `nivel` declarado: determina el inferido con la evidencia observada.

4. **Señales**
   - Contrasta el código con las señales de las recetas de `references/recetas.md` que aparecen.
   - Lee los archivos más grandes y los que concentran I/O (archivos, red, bases de datos, APIs, logs), sin pegar su contenido en el informe.
   - Registra cada señal con archivo, líneas y funciones o responsabilidades que mezcla.

5. **Informe en el chat**
   - Presenta en el chat: nivel actual, señales detectadas, recomendación con las partes de D4 (sin **Decisión**) y plan de migración como lista ordenada de changes (una responsabilidad por change, cada uno con sus tests de caracterización `Cxx`).
   - Las partes de la recomendación:
     - **Qué vi**: archivos, líneas y funciones concretas.
     - **Qué problema trae**: problemas de diseño o mantenimiento detectados.
     - **Qué propongo**: nivel, carpetas y reglas de la receta adaptadas al repo.
     - **Cuánto cuesta**: archivos que se mueven y si se puede hacer por partes.
     - **Qué descarté**: otra receta o no hacer nada, con el motivo.
     - **Pautas para el Agente**: las de la receta correspondiente.
   - Sin señales: informa que "el nivel actual alcanza" y termina.

6. **Adopción de la recomendación**
   - Consulta al usuario mediante `AskUserQuestion`: "Adoptar la recomendación" / "No por ahora".
   - Si se adopta: escribe en `## Arquitectura` de `openspec/config.yaml` (creándola si falta) el `nivel`, las carpetas, las reglas y `tamaño: 500, 1000`, con edición quirúrgica y el aviso de 40 KB, y sugiere `/issue-creation` para el primer change del plan.
   - Si no: no escribe nada.
