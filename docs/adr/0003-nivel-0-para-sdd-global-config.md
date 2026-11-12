# 0003. Nivel 0 para sdd-global-config

Estado: aceptada
Fecha: 2026-11-12
Change: sugerir-arquitectura

## Contexto

`## Arquitectura` de `openspec/config.yaml` declaraba carpetas (`scripts/`, `skills/`, `templates/`, `tests/`) pero no `nivel`, así que el proyecto figuraba "sin evaluar". El 12/11/2026 se corrió `/arquitectura`. El código está solo en `scripts/` (4 archivos de PowerShell: `instalar.ps1` con 500 líneas, `generar-plantillas.ps1` con 311, `sincronizar-proyecto.ps1` con 238 y `comun.ps1` con 212). `skills/` y `templates/` son Markdown. La única señal fue `scripts/instalar.ps1`: está en el umbral de aviso y mezcla la clasificación del espejo del vault (6 casos) con lecturas de archivos y llamadas a `git`. Por eso sus tests necesitan carpetas y repos de prueba.

## Alternativas

- `1-nucleo-funcional` (llevar la clasificación a funciones puras en `scripts/comun.ps1` o `scripts/nucleo/`): descartada por ahora. La receta indica que en `tooling` normalmente no aplica, hay una sola señal en el límite del aviso, y los tests ya cubren los casos y corren en el CI.
- `2-tuberias`, `2-capas`, `3-hexagonal` y `3-modular`: descartadas. No hay ETL, capas de presentación, integraciones intercambiables ni varios dominios de negocio.
- No declarar nivel: descartada. Deja el proyecto "sin evaluar" y la deuda abierta.

## Decisión

`nivel: 0` y `tamaño: 500, 1000` en `## Arquitectura`, sin reglas `no importa:` ni carpetas nuevas. Las funciones auxiliares que se usen en más de un script van a `scripts/comun.ps1`.

## Consecuencias

- Positivas: el proyecto queda evaluado, el verify mide el tamaño de los scripts que crecen y la decisión sobre `instalar.ps1` tiene un umbral claro (1000 líneas).
- Negativas: la clasificación del espejo sigue mezclada con I/O, y sus tests siguen necesitando carpetas y repos de prueba.
