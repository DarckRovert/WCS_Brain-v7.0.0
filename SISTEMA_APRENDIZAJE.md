# 🧠 Sistema de Aprendizaje WCS_Brain - Documentación Completa

## 🔍 Resumen Ejecutivo

**Estado:** ✅ COMPLETAMENTE FUNCIONAL

**Problema Original:** El sistema de aprendizaje mostraba 0 patrones y no capturaba datos de combate.

**Solución:** Creación de WCS_BrainCombatLogger.lua - Sistema completo de captura de eventos de combate.

**Resultado:** Sistema capturando hechizos correctamente. Necesita 10+ combates para generar patrones.

---

## 🛠️ Archivos del Sistema

### Archivos Principales

1. **WCS_BrainLearning.lua** - Sistema de aprendizaje y comandos
2. **WCS_BrainMetrics.lua** - Almacenamiento de métricas de combate
3. **WCS_BrainCombatLogger.lua** - Captura de eventos de combate (NUEVO)

### Orden de Carga (WCS_Brain.toc)

```
WCS_BrainMetrics.lua          # Línea 64 - Almacenamiento de datos
WCS_BrainCombatLogger.lua     # Línea 65 - Captura de eventos (NUEVO)
WCS_BrainLearning.lua         # Línea 67 - Sistema de aprendizaje
```

---

## 🐛 Problemas Encontrados y Soluciones

### Problema 1: WCS_BrainLearning.lua no cargaba

**Síntoma:** Comandos `/brainlearn` no funcionaban

**Causa:** El archivo existía pero NO estaba listado en WCS_Brain.toc

**Solución:** ✅ Agregado WCS_BrainLearning.lua al .toc (línea 67)

---

### Problema 2: Sistema no capturaba hechizos

**Síntoma:** `/brainlearn debug` mostraba 0 hechizos usados

**Causa:** WCS_BrainMetrics tenía la función `RecordSpellDamage()` pero NADIE la llamaba

**Solución:** ✅ Creado WCS_BrainCombatLogger.lua (400+ líneas)

**Funcionalidad:**
- Captura eventos CHAT_MSG_SPELL_SELF_DAMAGE (daño directo)
- Captura eventos CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE (DoTs)
- Parsea mensajes del combat log
- Envía datos a WCS_BrainMetrics:RecordSpellDamage()
- Trackea uso de mana
- Hooks en CastSpell y CastSpellByName

---

### Problema 3: WCS_BrainMetrics.Combat.active siempre false

**Síntoma:** RecordSpellDamage() salía inmediatamente sin registrar

**Causa:** Nadie llamaba a StartCombat()/EndCombat() de WCS_BrainMetrics

**Solución:** ✅ Modificado WCS_BrainCombatLogger.lua

```lua
function Logger.OnCombatStart()
    WCS_BrainMetrics:StartCombat()  -- AGREGADO
    -- resto del código...
end

function Logger.OnCombatEnd()
    local won = not UnitIsDead("player")
    WCS_BrainMetrics:EndCombat(won)  -- AGREGADO
    -- resto del código...
end
```

---

### Problema 4: Error al cargar - Config nil

**Síntoma:** Error "attempt to index field 'Config' (a nil value)" línea 427

**Causa:** Faltaba inicializar Logger.Config

**Solución:** ✅ Agregada tabla de configuración

```lua
Logger.Config = {
    debugMode = false
}
```

---

### Problema 5: Error en WCS_BrainMetrics.CopyTable

**Síntoma:** Addon crasheaba al finalizar combates

**Causa:** `for key, value in original do` - faltaba pairs()

**Solución:** ✅ Corregido en WCS_BrainMetrics.lua línea 448

```lua
-- ANTES (INCORRECTO)
for key, value in original do

-- DESPUÉS (CORRECTO)
for key, value in pairs(original) do
```

---

### Problema 6-10: Auditoría de Código - 5 Bugs Críticos Adicionales

**Fecha:** Enero 7, 2026

Durante una auditoría completa del código, se encontraron **5 bugs adicionales** del mismo tipo (falta de pairs/ipairs en loops).

#### Bug 6: WCS_BrainCombatLogger.lua L457
**Código:** `self.debugMode` → `self.Config.debugMode`
**Impacto:** /combatlogger status mostraba siempre "OFF" para debug mode
**Severidad:** BAJA ✅ CORREGIDO

#### Bug 7: WCS_BrainMetrics.lua L203 - UpdateSpellMetrics
**Código:** `for spell, data in self.Combat.spellsCast do`
**Correcto:** `for spell, data in pairs(self.Combat.spellsCast) do`
**Impacto:** CRÍTICO - No actualizaría métricas de hechizos al finalizar combate
**Severidad:** CRÍTICA ✅ CORREGIDO

#### Bug 8: WCS_BrainMetrics.lua L272 - GetTopSpellsByDPS
**Código:** `for spell, dps in self.Data.spellDPS do`
**Correcto:** `for spell, dps in pairs(self.Data.spellDPS) do`
**Impacto:** CRÍTICO - No podría generar reporte de top hechizos
**Severidad:** CRÍTICA ✅ CORREGIDO

#### Bug 9: WCS_BrainMetrics.lua L333 - GetEnemyTypeStats
**Código:** `for enemyType, data in self.Data.enemyTypes do`
**Correcto:** `for enemyType, data in pairs(self.Data.enemyTypes) do`
**Impacto:** CRÍTICO - No podría generar estadísticas por tipo de enemigo
**Severidad:** CRÍTICA ✅ CORREGIDO

#### Bug 10: WCS_BrainMetrics.lua L368 - ShowFullReport
**Código:** `for i, spellData in topSpells do`
**Correcto:** `for i, spellData in ipairs(topSpells) do`
**Impacto:** CRÍTICO - No podría mostrar reporte completo
**Severidad:** CRÍTICA ✅ CORREGIDO

**Nota Importante:** En Lua 5.0 (WoW 1.12), la sintaxis `for k,v in table do` NO es válida. SIEMPRE se debe usar `pairs()` para tablas hash o `ipairs()` para arrays numéricos.

---

## 📊 Cómo Funciona el Sistema

### Flujo de Captura de Datos

```
1. Jugador entra en combate
   ↓
2. PLAYER_REGEN_DISABLED evento
   ↓
3. WCS_BrainCombatLogger.OnCombatStart()
   ↓
4. WCS_BrainMetrics:StartCombat()
   ↓
5. Jugador castea hechizo (ej: Death Coil)
   ↓
6. CHAT_MSG_SPELL_SELF_DAMAGE evento
   ↓
7. WCS_BrainCombatLogger.ParseDamageMessage()
   ↓
8. WCS_BrainMetrics:RecordSpellDamage("Death Coil", 544)
   ↓
9. Jugador sale de combate
   ↓
10. PLAYER_REGEN_ENABLED evento
    ↓
11. WCS_BrainCombatLogger.OnCombatEnd()
    ↓
12. WCS_BrainMetrics:EndCombat(won)
    ↓
13. Datos guardados en WCS_BrainMetrics.CombatHistory
```

### Requisitos para Generar Patrones

**Mínimo de combates:** 10 (Config.minSampleSize)

**Mínimo de usos por hechizo:** 3 para generar un patrón

**Ejemplo:**
```
Combates: 4/10  ❌ No genera patrones aún
Combates: 10/10 ✅ Empieza a generar patrones
Combates: 50/10 ✅ Patrones más precisos
```

---

## 💻 Comandos Disponibles

### Sistema de Aprendizaje

```lua
/brainlearn status      -- Ver estado del sistema
/brainlearn patterns    -- Ver patrones aprendidos
/brainlearn analyze     -- Analizar ahora
/brainlearn debug       -- Ver información detallada
/brainlearn reset       -- Resetear aprendizaje
/brainlearn toggle      -- Activar/desactivar
/brainlearn autoadjust  -- Toggle auto-ajuste
```

### Combat Logger

```lua
/combatlogger status    -- Ver estado del logger
/combatlogger debug     -- Activar modo debug
/combatlogger toggle    -- Activar/desactivar
```

---

## 📝 Ejemplo de Salida

### /brainlearn status

```
=== ESTADO DEL APRENDIZAJE ===
Versión: 1.0.0
Estado: Activo
Auto-ajuste: ON
Patrones aprendidos: 0
Overrides manuales detectados: 0
Patrones del jugador: 0
```

### /brainlearn debug

```
=== DEBUG INFO ===
Combates registrados: 4
Mínimo requerido: 10
WCS_BrainMetrics: ACTIVO
Último combate: Humanoid
Hechizos únicos usados: 3
  * Death Coil: 4 casts, 544 dmg
  * Immolate: 4 casts, 336 dmg
  * Hellfire Effect: 13 casts, 2946 dmg
Learning enabled: SI
```

### /combatlogger status

```
=== Combat Logger Status ===
Version: 1.0.0
Enabled: YES
Debug Mode: ON
In Combat: NO
WCS_BrainMetrics: LOADED
```

---

## 🔧 Detalles Técnicos

### WCS_BrainCombatLogger.lua

**Líneas de código:** 431

**Eventos capturados:**
- PLAYER_REGEN_DISABLED (inicio combate)
- PLAYER_REGEN_ENABLED (fin combate)
- CHAT_MSG_SPELL_SELF_DAMAGE (daño directo)
- CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE (DoTs)
- UNIT_MANA (cambios de mana)

**Funciones principales:**
```lua
Logger.OnEvent(event, arg1, ...)           -- Manejador de eventos
Logger.OnCombatStart()                     -- Inicio de combate
Logger.OnCombatEnd()                       -- Fin de combate
Logger.ParseDamageMessage(msg)             -- Parseo de daño directo
Logger.ParsePeriodicDamageMessage(msg)     -- Parseo de DoTs
Logger.TrackManaChange()                   -- Tracking de mana
Logger.InstallHooks()                      -- Hooks de CastSpell
```

**Patrones de parseo:**
```lua
-- Daño directo: "Your Death Coil hits Target for 544."
local spell, damage = string.match(msg, "Your (.+) hits .+ for (%d+)")

-- DoT: "Target suffers 168 Shadow damage from your Corruption."
local damage, spell = string.match(msg, "suffers (%d+) .+ from your (.+)%.")
```

---

### WCS_BrainMetrics.lua

**Funciones clave:**
```lua
WCS_BrainMetrics:StartCombat()                    -- Inicia tracking
WCS_BrainMetrics:EndCombat(won)                   -- Finaliza y guarda
WCS_BrainMetrics:RecordSpellDamage(spell, dmg)   -- Registra hechizo
WCS_BrainMetrics:CopyTable(original)              -- Copia profunda
```

**Estructura de datos:**
```lua
WCS_BrainMetrics.Combat = {
    active = false,
    startTime = 0,
    spellsCast = {},  -- { ["Death Coil"] = {casts=4, damage=544}, ... }
    manaUsed = 0
}

WCS_BrainMetrics.CombatHistory = {
    -- Array de combates completados
}
```

---

## ✅ Verificación del Sistema

### Checklist de Funcionamiento

- [x] WCS_BrainLearning.lua en .toc
- [x] WCS_BrainCombatLogger.lua en .toc
- [x] Comandos /brainlearn funcionan
- [x] Comandos /combatlogger funcionan
- [x] Sistema captura hechizos (Death Coil, Immolate, Hellfire)
- [x] WCS_BrainMetrics.Combat.active se activa en combate
- [x] CopyTable() usa pairs() correctamente
- [x] Logger.Config inicializado
- [x] Debug mode funcional

### Cómo Verificar

1. **Cargar addon:**
   ```
   /reload
   ```

2. **Verificar comandos:**
   ```
   /brainlearn status
   /combatlogger status
   ```

3. **Activar debug:**
   ```
   /combatlogger debug
   ```

4. **Entrar en combate y verificar captura:**
   ```
   /brainlearn debug
   ```

5. **Esperar 10 combates y verificar patrones:**
   ```
   /brainlearn status
   /brainlearn patterns
   ```

---

## 📊 Estado Actual (Enero 7, 2026)

**Combates completados:** 4/10

**Hechizos capturados:**
- Death Coil: 4 casts, 544 dmg
- Immolate: 4 casts, 336 dmg
- Hellfire Effect: 13 casts, 2946 dmg

**Patrones generados:** 0 (necesita 6 combates más)

**Sistema:** ✅ FUNCIONANDO CORRECTAMENTE

**Próximo paso:** Completar 6 combates adicionales para alcanzar el mínimo de 10.

---

## 📚 Referencias

### Archivos Modificados en Esta Sesión

1. **WCS_Brain.toc**
   - Línea 65: Agregado WCS_BrainCombatLogger.lua

2. **WCS_BrainCombatLogger.lua** (CREADO)
   - 431 líneas de código
   - Sistema completo de captura

3. **WCS_BrainMetrics.lua**
   - Línea 448: Corregido `for key, value in pairs(original) do`

### Archivos de Documentación

- WCS_Brain_Fix.md - Historial de correcciones
- potential_issues.md - Problemas detectados
- SISTEMA_APRENDIZAJE.md - Este documento

---

## 👥 Créditos

**Desarrollador:** DarckRovert (ELnazzareno)

**Fecha de Corrección:** Enero 7, 2026

**Versión WCS_Brain:** 6.9.1

**Servidor:** Turtle WoW (1.12 / Lua 5.0)

---

## 🔗 Enlaces Útiles

- README.md - Documentación general del addon
- GUIA_USUARIO.md - Guía de usuario
- CHANGELOG.md - Historial de cambios

---

**¡El sistema de aprendizaje está completamente funcional!** 🎉

**Solo necesitas completar más combates para que empiece a generar patrones.**
