# 🏗️ WCS Brain - Arquitectura Técnica

## 💓 El Latido (Heartbeat System)
A diferencia de los addons tradicionales que usan múltiples frames de `OnUpdate`, WCS Brain utiliza un único latido central gestionado en `WCS_Core.lua`. Esto reduce el uso de CPU y garantiza que todos los módulos reciban la información sincronizada en el mismo ciclo (Tick).

## 📡 Bus de Eventos (Event Manager)
Toda la comunicación entre módulos se realiza a través de `WCS_EventManager.lua`. Este bus captura las variables globales de WoW 1.12 inmediatamente para evitar fugas de memoria y errores de nil-access en periodos de alto estrés (raids/PvP).

## 🧠 Motor de Decisión (Tactical Engine)
1. **State Capture**: Captura 50 puntos de datos del entorno (`WCS_BrainState.lua`).
2. **DQN Simulation**: Evalúa las recompensas teóricas de cada acción (`WCS_BrainDQN.lua`).
3. **Action Execution**: Ejecuta el hechizo óptimo a través de la capa de abstracción de `WCS_SpellManager.lua`.

## 🌌 Arquitectura Multi-Clase Universal
- **WCS_ClassEngine.lua**: Motor detector de raza, clase y recurso ejecutado en tiempo de carga (`PLAYER_LOGIN`). Esto transforma al addon de un bot de Warlock a una consola de mando de hermandad para el 100% de las clases de WoW Vainilla.
- **WCS_ClassRotations.lua**: Embebida con diccionarios de prioridades, buffs defensivos, fillers y desencadenadores de procs para las 9 clases disponibles (Warrior, Mage, Resto/Shadow Priest, Warlock, Rogue, Shaman, Hunter, Paladin, Druid).

## 🛡️ Hardening de Compatibilidad
- **Lua 5.0 Strict**: No se utiliza el operador de longitud `#`, `string.match` ni otras funciones introducidas en Lua 5.1+.
- **WoW 1.12 API**: Todas las firmas de `SetPoint` y `CreateFrame` son nativas del motor de Vanilla.
