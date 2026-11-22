# 0008. Huella de skills y comandos en el espejo del vault

Estado: aceptada
Fecha: 2026-11-21
Change: huella-de-instalacion-en-espejo

## Contexto

El ADR 0002 hizo que Claude y el Agente lean las reglas desde el espejo del vault, así que las reglas llegan a otra máquina con el pull del vault. Las skills, los comandos y los archivos de Antigravity se siguen copiando con `instalar.ps1` desde el repo local. Un change que toca solo skills o comandos no cambia el espejo: la otra máquina no recibe ningún aviso y trabaja con skills viejas y reglas nuevas. Además, una máquina con el repo atrasado y el mismo `CLAUDE.md` podía reescribir el espejo con un commit más viejo.

## Alternativas

- **Copiar skills y comandos al vault e instalarlos desde ahí:** duplica todo el contenido en el vault y sigue necesitando `instalar.ps1`, porque Claude Code no carga skills con `@`. Descartada.
- **Distribuir skills y comandos como plugin de Claude Code desde el repo:** suma una integración nueva, cambia los nombres de los comandos (`/opsx:propose` pasaría a llevar el prefijo del plugin) y no cubre las skills de Antigravity. Descartada.
- **Correr `git pull` e `instalar.ps1` automáticamente al iniciar sesión:** escribe en `~/.claude` sin que el usuario lo pida y choca con la regla de no corregir copias por cuenta propia. Descartada.
- **Huella por commit (`git log -1 -- skills .claude/commands`):** no ve cambios sin commitear y depende de la historia de git. Descartada.
- **No hacer nada y documentarlo:** deja el desparejo silencioso. Descartada.

## Decisión

`instalar.ps1` escribe en el encabezado del espejo una línea `instalacion:` con una huella de 12 caracteres calculada desde el contenido y la ruta de las skills, los comandos y los archivos de Antigravity que instala, sin depender del destino. Una huella distinta hace que el espejo deje de estar `igual`, así un change que toca solo skills también genera un commit en el vault con el commit nuevo del repo. La clasificación del espejo revisa primero si su `commit:` existe en el repo local: si no existe, es `repo atrasado` y `instalar.ps1` no lo escribe. `-Comprobar` explica que `repo atrasado` significa reglas, skills o comandos nuevos de otra máquina y pide `git pull` e `instalar.ps1`. La instalación sigue siendo a pedido del usuario.

## Consecuencias

- Positivas: cualquier cambio en lo que se instala llega a las otras máquinas como aviso por el mismo camino que las reglas; una máquina atrasada no pisa el espejo; no suma tecnologías ni integraciones.
- Negativas: la otra máquina recibe un aviso, no las skills (hay que correr `git pull` e `instalar.ps1`); cada máquina suma un commit al vault en la primera instalación; skills editadas sin commitear pueden reescribir el espejo hasta que otra máquina al día lo corrija.
