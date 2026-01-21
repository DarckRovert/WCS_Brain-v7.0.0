# 📖 Guía de Usuario - WCS_Brain v7.0.0

## 🚀 Inicio Rápido

### Instalación
1. El addon ya está instalado en `E:\TurtleWow\Interface\AddOns\WCS_Brain`
2. Asegúrate de que esté activado en el menú de addons del juego
3. Haz `/reload` para cargar

### Comandos Principales
```
/sequito    - Abrir panel principal
/clan       - Alias corto
/terror     - Alias temático
```

### Accesos Directos a Módulos
```
/clanbank   - Banco del Clan
/rm         - Raid Manager
/summon     - Panel de Summon
/wstats     - Estadísticas
/grim       - Grimorio
/pvpt       - PvP Tracker
```

---

## 📋 Módulos Disponibles

### 1. 🏦 Banco del Clan (/clanbank)

**Funcionalidad:**
- Sistema de tracking de oro del clan
- Inventario compartido
- Sistema de préstamos
- Sincronización entre miembros en raid/party

**Botones:**
- **Depositar Oro**: Registra depósito (debes transferir oro manualmente al banker)
- **Retirar Oro**: Registra retiro (el banker te transfiere manualmente)
- **Ver Inventario**: Muestra items del banco con colores por calidad
- **Solicitar Préstamo**: Sistema de tracking de préstamos
- **Lista Materiales**: Materiales necesarios para crafteos
- **Sincronizar**: Comparte datos del banco con el raid
- **Solicitar Sync**: Pide datos actualizados

**⚠️ IMPORTANTE:**
El addon NO transfiere oro automáticamente (limitación de WoW API).
Hace TRACKING de transacciones. Debes transferir oro manualmente.

**Persistencia:**
Los datos se guardan automáticamente y persisten entre sesiones.

---

### 2. 👥 Raid Manager (/rm)

**Funcionalidad REAL:**
- Detecta quién tiene Healthstone/Soulstone (usando UnitBuff)
- Distribución inteligente de Healthstones
- Asignación de Soulstones con prioridades (Tank > Healer > DPS)
- Auto-asignación de Curses a warlocks
- Whispers automáticos a miembros
- Anuncios en raid chat

**Botones:**
- **Distribuir HS**: Detecta quién necesita healthstone y whisper
- **Asignar SS**: Asigna soulstones por prioridad y notifica
- **Auto Curses**: Asigna curses y anuncia en raid
- **Crear Macro HS**: Macro para usar healthstone
- **Crear Macro SS**: Macro para crear soulstone
- **Crear Macro Curse**: Macro inteligente con modificadores

**Macros Creadas:**
1. **WCS_UseHS**: Usa healthstone desde cualquier bolsa
2. **WCS_CreateSS**: Crea soulstone en el objetivo
3. **WCS_SmartCurse**: 
   - Normal: Curse of Agony
   - Shift: Curse of Shadow
   - Ctrl: Curse of Elements
   - Alt: Curse of Recklessness

---

### 3. 🔮 Summon Panel (/summon)

**Funcionalidad:**
- Cola de summon con prioridades
- Sistema de turnos automático
- Whispers automáticos a jugadores en cola
- Macro de Ritual of Summoning

**Botones:**
- **Agregar a Cola**: Añade jugador con prioridad
- **Siguiente**: Procesa siguiente en cola
- **Limpiar Cola**: Resetea la cola
- **Crear Macro Summon**: Macro para iniciar ritual


---

### 4. 🐾 Control Inteligente de Mascotas (/petai) - v6.7.1

**Estado:** ✅ MEJORADO - Confiabilidad 60% → 95%

**Funcionalidad:**
Sistema de IA avanzado para control automático de mascotas con múltiples modos de operación.

**Comandos Principales:**
```lua
/petai status       -- Ver estado y versión (v6.7.1)
/petai debug        -- Activar debug detallado
/petai mode <modo>  -- Cambiar modo (aggressive/defensive/passive/guardian)
/petai toggle       -- Activar/desactivar IA
```

**Modos de Operación:**

1. **Aggressive** - Ataque agresivo
   - Usa todas las habilidades de daño disponibles
   - Prioriza objetivos con más HP
   - Ideal para: Leveling, dungeons, DPS máximo

2. **Defensive** - Protección del jugador
   - Prioriza habilidades defensivas
   - Ataca solo si el jugador está en combate
   - Ideal para: Solo farming, PvP

3. **Passive** - Control manual
   - La mascota no ataca automáticamente
   - Solo ejecuta órdenes directas
   - Ideal para: Situaciones delicadas, CC

4. **Guardian** - Protección de aliados
   - Asiste al objetivo del jugador
   - Defiende aliados con HP bajo
   - Feedback visual: "[GUARDIÁN] Defendiendo a X (HP: 45%)"
   - Ideal para: Raids, dungeons como tank

**Mejoras v6.7.1:**

✅ **Sistema de Ejecución Mejorado:**
- Método 1: CastSpellByName() - 95% confiable
- Método 2: CastPetAction(slot) - Fallback
- Método 3: ChatFrameEditBox - Último recurso

✅ **Verificación Completa:**
- Comprueba si la mascota tiene la habilidad
- Verifica cooldown usando API real (GetPetActionCooldown)
- Verifica mana suficiente antes de ejecutar

✅ **Debug Detallado:**
```
[CanCast] Fire Shield - OK
[Execute] Fire Shield - CastSpellByName
[CanCast] Torment - EN CD (3.2s)
[CanCast] Suffering - MANA INSUFICIENTE (necesita 250, tiene 180)
[GUARDIÁN] Asistiendo a NombreJugador
[GUARDIÁN] Defendiendo a TankName (HP: 78%)
```

**Habilidades por Mascota:**

- **Imp:** Fire Shield, Firebolt, Phase Shift
- **Voidwalker:** Torment, Suffering, Consume Shadows, Sacrifice
- **Succubus:** Lash of Pain, Soothing Kiss, Seduction
- **Felhunter:** Devour Magic, Spell Lock, Paranoia
- **Felguard:** Cleave, Intercept, Anguish

**Troubleshooting:**

*"Las habilidades no se ejecutan"*
- Activa debug: `/petai debug`
- Verifica mensajes: Si dice "EN CD" o "MANA INSUFICIENTE" es normal
- Si dice "NO ENCONTRADA" la mascota no tiene esa habilidad

*"Modo Guardián no funciona"*
- Asegúrate de tener un objetivo seleccionado
- El objetivo debe estar en combate
- Verifica mensajes de debug

*"Muestra versión antigua"*
- Haz `/reload` para recargar el addon
- Verifica que WCS_BrainPetAI.lua esté actualizado

**Compatibilidad:**
- ✅ Todas las mascotas de Warlock
- ✅ WoW 1.12 (Turtle WoW)
- ✅ Cliente en español e inglés


**Prioridades:**
- Alta: Tanks, Healers principales
- Media: DPS, Healers secundarios
- Baja: Resto

---

### 4. 📊 Statistics (/wstats)

**Funcionalidad REAL:**
- Tracking de DPS en tiempo real
- Breakdown de daño por DoT
- Contador de consumibles usados
- Anuncios en raid chat

**Botones:**
- **Resetear Stats**: Limpia estadísticas
- **Anunciar DPS**: Anuncia tu DPS en raid chat

**Tracking Automático:**
- Se actualiza durante combate
- Detecta inicio/fin de combate
- Cuenta Shadow Bolt, DoTs, consumibles

---

### 5. 📚 Grimoire (/grim)

**Contenido:**
- Rotaciones predefinidas por spec (Affliction, Destruction, Demonology)
- Macros útiles para warlock
- Guía de BiS gear
- Calculadora de stats

**Uso:**
Navega por las tabs para ver información.

---

### 6. ⚔️ PvP Tracker (/pvpt)

**Funcionalidad:**
- Contador de kills/deaths
- Sistema de llamadas de objetivos
- Escaneo de área para detectar enemigos
- Macros PvP con mouseover

**Botones:**
- **Resetear Stats**: Limpia contador
- **Escanear Área**: Busca enemigos cercanos
- **Crear Macros PvP**: Crea 3 macros

**Macros PvP:**
1. **WCS_Fear**: Fear con mouseover
2. **WCS_Coil**: Death Coil con mouseover
3. **WCS_Howl**: Howl of Terror

---

### 7. 👥 Clan Panel

**Funcionalidad:**
- Lista de miembros del guild
- Actualización automática
- Colores por clase
- Estado online/offline

---

## ❓ FAQ - Preguntas Frecuentes

### ¿El banco transfiere oro automáticamente?
**No.** El addon hace TRACKING de transacciones. Debes transferir oro manualmente al banker del clan. El sistema registra y sincroniza los datos.

### ¿Las macros se crean automáticamente?
**Sí.** Al hacer clic en los botones "Crear Macro", el addon crea/actualiza las macros automáticamente. Límite: 18 macros globales.

### ¿La detección de Healthstone/Soulstone es real?
**Sí.** Usa UnitBuff() para escanear los 40 miembros del raid y detectar quién tiene los buffs.

### ¿Los datos se guardan entre sesiones?
**Sí.** Los datos del banco, préstamos y configuración se guardan automáticamente usando SavedVariables.

### ¿Funciona la sincronización en party/raid?
**Sí.** Usa SendAddonMessage() para sincronizar datos del banco entre jugadores que tengan el addon.

### ¿Los whispers son automáticos?
**Sí.** El addon envía whispers automáticamente cuando asignas soulstones, detectas quién necesita healthstone, o procesas la cola de summon.

---

## 🔧 Troubleshooting

### "Comando no encontrado"
**Solución:** Haz `/reload` para recargar el addon.

### "El panel no se abre"
**Solución:** Verifica que WCS_Brain esté activado en el menú de addons.

### "Las macros no se crean"
**Causa:** Límite de 18 macros globales alcanzado.
**Solución:** Elimina macros que no uses y vuelve a intentar.

### "No detecta Healthstones"
**Causa:** No estás en un raid o los miembros no tienen el buff.
**Solución:** Asegúrate de estar en raid y que los jugadores tengan healthstone en inventario (buff activo).

### "La sincronización no funciona"
**Causa:** No estás en party/raid.
**Solución:** SendAddonMessage() solo funciona en grupo. Únete a un party o raid.

### "Los datos del banco se perdieron"
**Causa:** Archivo WTF corrupto o eliminado.

### "Los comandos /wcswarlock no funcionan"
**Causa:** No eres Warlock o las dependencias no están cargadas.
**Solución:** Ejecuta `/wcswarlock status` para ver qué falta. Haz `/reload` si es necesario.

### "Detecta falsos positivos en buffs"
**Causa:** Bug corregido en v6.9.1.
**Solución:** Asegúrate de tener la versión 6.9.1 o superior.

## 🧠 Sistema de Aprendizaje

**¿Qué es?**
Sistema que aprende de tus combates para mejorar las sugerencias de la IA.

**Comandos:**
```lua
/brainlearn status      -- Ver estado (combates, patrones)
/brainlearn debug       -- Ver hechizos capturados
/brainlearn patterns    -- Ver patrones aprendidos
/combatlogger status    -- Ver estado del logger
/combatlogger debug     -- Activar debug (ver capturas en tiempo real)
```

**Cómo funciona:**
1. Entra en combate normalmente
2. El sistema captura automáticamente:
   - Hechizos que usas
   - Daño de cada hechizo
   - Uso de mana
   - Duración del combate
3. Después de 10 combates, empieza a generar patrones
4. Los patrones mejoran con más combates

**Ejemplo:**
```
Combates: 4/10  ❌ Aún no genera patrones
Combates: 10/10 ✅ Empieza a aprender
Combates: 50/10 ✅ Patrones muy precisos
```

**Hechizos capturados:**
- Death Coil: 4 casts, 544 dmg
- Immolate: 4 casts, 336 dmg
- Hellfire Effect: 13 casts, 2946 dmg

**Troubleshooting:**

*"No captura hechizos"*
- Verifica: `/combatlogger status` debe mostrar "Enabled: YES"
- Activa debug: `/combatlogger debug`
- Entra en combate y verifica mensajes

*"Muestra 0 patrones"*
- Normal si tienes menos de 10 combates
- Usa `/brainlearn debug` para ver progreso
- Necesitas más combates

**Documentación completa:** Ver SISTEMA_APRENDIZAJE.md en la carpeta del addon

---

## 🆕 Sistemas Nuevos v6.9.1

### 8. 🔔 Notificaciones de Warlock (/wcswarlock o /wcslock)

**Funcionalidad:** Sistema inteligente de alertas específico para Warlocks con detección automática de buffs y recursos.

**Comandos:**
- `/wcswarlock status` - Ver estado completo
- `/wcswarlock test` - Probar notificaciones
- `/wcswarlock toggle` - Activar/desactivar
- `/wcslock` - Alias corto

**Notificaciones:** Demon Armor, Soul Shards (crítico ≤1, bajo ≤3), Healthstone disponible, Alerta de combate.

**💡 Soul Shards:** Fragmentos de alma de Drain Soul. Necesarios para invocar demonios, crear Healthstones/Soulstones, Soul Fire y Ritual of Summoning (1 shard c/u). Mantén 10-15.

---

### 9. 📢 Sistema de Notificaciones (/wcsnotif)

**Funcionalidad:** Sistema base de notificaciones visuales en pantalla (UIErrorsFrame).

**Comandos:** `/wcsnotif` (estado), `/wcsnotif toggle`, `/wcsnotif test`, `/wcsnotif clear`

**Tipos:** INFO, SUCCESS, WARNING, ERROR, CRITICAL

---

### 10. ⏱️ Throttling de Eventos (/wcsthrottle)

**Funcionalidad:** Limita frecuencia de eventos de combate, mejora FPS.

**Comandos:** `/wcsthrottle` (config), `/wcsthrottle stats`, `/wcsthrottle reset`

---

### 11. 🛡️ Sistema de Seguridad (/wcssafety)

**Funcionalidad:** Límites de seguridad para prevenir loops infinitos.

**Comandos:** `/wcssafety` (ver límites), `/wcssafety reset`

---

### 12. ✅ Validador de Datos (/wcsvalidate)

**Funcionalidad:** Valida y repara SavedVariables automáticamente.

**Comandos:** `/wcsvalidate` (validar), `/wcsvalidate repair`, `/wcsvalidate backup`

---

### 13. 📊 Dashboard de Rendimiento (/wcsdash)

**Funcionalidad:** Panel con métricas en tiempo real (DPS, TPS, HPS, IA, eventos, memoria, FPS).

**Comandos:** `/wcsdash` (completo), `/wcsdash mini` (compacto), `/wcsdash reset`

---

### 14. 🔥 Integración WeakAuras (/wcswa)

**Funcionalidad:** Exporta datos del addon para WeakAuras (estado IA, cooldowns, sugerencias, mascota, recursos).

**Comandos:** `/wcswa` (estado), `/wcswa export`

---

### 15. 💀 Integración Boss Mods (/wcsbm)

**Funcionalidad:** Detecta alertas de BigWigs/DBM, ajusta estrategia IA según fase de boss.

**Comandos:** `/wcsbm` (estado), `/wcsbm toggle`

---

### 16. 🧹 Limpieza Automática

**WCS_BrainCleanup** y **WCS_BrainPetAICleanup** - Limpieza automática cada 60s, elimina cooldowns expirados, optimiza memoria. Sin comandos, funciona en background.

---

### 17. 🤖 BrainHUD (/brainhud) - v7.0.0

**Funcionalidad:** Interfaz holográfica (HUD) flotante cerca del personaje.
- **Visualización:** Muestra el icono de la siguiente decisión de la IA.
- **Recursos:** Muestra conteo de Soul Shards en tiempo real.
- **Estados:** Bordes de colores indican urgencia (Rojo=Emergencia, Azul=Filler).

**Comando:** `/brainhud` (activar/desactivar)

---


**Solución:** Los datos están en `WTF\Account\TU_CUENTA\SavedVariables\WCS_Brain.lua`. Haz backup regularmente.

---

## 💡 Consejos por Tipo de Jugador

### Para Guild Masters:
- Usa /clanbank para gestionar el banco del clan
- Sincroniza datos regularmente con oficiales
- Revisa préstamos pendientes

### Para Raid Leaders:
- Usa /rm para coordinar Healthstones/Soulstones
- Auto-asigna curses antes de pulls
- Anuncia DPS al final de bosses

### Para Warlocks en Raid:
- Crea las macros de HS/SS/Curse al inicio
- Usa /wstats para trackear tu DPS
- Distribuye Healthstones antes de pulls

### Para PvP:
- Crea las macros PvP (Fear/Coil con mouseover)
- Usa /pvpt para trackear kills
- Escanea área para detectar enemigos

---

## 📊 Resumen de Funcionalidad

### ✅ Funcionalidad 100% REAL:
- Detección de buffs (UnitBuff)
- Creación de macros (CreateMacro)
- Whispers automáticos (SendChatMessage)
- Anuncios en raid (SendChatMessage)
- Sincronización de datos (SendAddonMessage)
- Persistencia de datos (SavedVariables)
- Tracking de DPS/DoTs (eventos de combate)

### ⚠️ Funcionalidad de TRACKING (no automática):
- Banco del clan (tracking de oro, no transferencia)
- Préstamos (registro, no transferencia)
- Inventario (lista, no acceso real al banco)

---

## 📞 Soporte

Si encuentras bugs o tienes sugerencias:
1. Revisa esta guía primero
2. Verifica que estés usando la versión 6.9.1
3. Haz `/reload` y prueba de nuevo
4. Reporta el error con detalles

---

**Versión:** 7.0.0
**Fecha:** Enero 20, 2026
**Autor:** DarckRovert (El Séquito del Terror)
**Tema:** Brujo/Warlock - Oscura y Demoníaca
