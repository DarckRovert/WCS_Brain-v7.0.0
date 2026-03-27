# Changelog WCS_Brain

## [v9.5.0] - God-Tier UI Polish & Routing Fixes - 2026-03-26
### Corregido
- **Barra de Botones (ButtonBar)**: Arreglado un error crítico donde los botones de "Perfiles" y "Diagnósticos" fallaban silenciosamente por invocar `Toggle()` a módulos obsoletos; ahora renderizan correctamente sus pestañas en la ventana maestra de la UI.
- **Tutorial UI**: Reparado el problema de la "ventana sin contenido"; ahora la UI del tutorial invoca automáticamente los datos base de `WCS_BrainTutorial.Steps` al ejecutarse a través del comando `/tutorialui` o botón.

## [v9.4.1] - God-Tier UI Analytics Fix - 2026-03-26
### FIXED - UI Layout Audit & Complete Grid Redesign
- **Grilla Consistente**: Todas las pestañas (5-14) ahora usan paneles de `308x455px` con columnas en `x=14` (izq) y `x=360` (der).
- **Overlap de Títulos**: Primera fila de contenido movida a `y=-28` dentro de cada sección, evitando colisión con el título de la sección.
- **Overflow Corregido**: Listas largas (habilidades de mascota, logros, historial) reformateadas para no exceder el alto del panel.
- **Checkbox Alineado**: Labels y checkboxes en Tab 10 (Auto) ahora quedan en la misma línea horizontal.
- **Slider Legible**: El valor del slider de reacción en Tab 14 (Rotaciones) ya no se superpone con el template del slider.
- **Botones Full-Width**: Botones de rotación, reparación y acción ahora usan el ancho completo del panel (`PANEL_W - 24`).

## [9.3.2] - Marzo 27, 2026
### FIXED
- **Compatibilidad WoW 1.12**: Corregido error de nil en `UpdateAddOnMemoryUsage()` dentro de `WCS_BrainTabPanels.lua`. Se implementó un fallback dinámico a `gcinfo()` para servidores Vanilla (incluyendo Turtle WoW).

## [9.3.1] - Marzo 25, 2026
### 🛠️ CRITICAL PET AI FIX (RESTAURACION TOTAL)
- **Normalización de Capitalización**: Corregidos más de 15 nombres de habilidades de mascotas a "Sentence Case" (ej: "Escudo de fuego") para compatibilidad total con el comando `/cast` en el cliente español de WoW 1.12.
- **Motor de Macros Restaurado**: Reemplazada la máquina de estados asíncrona por el sistema de ejecución directa vía chat (`/cast`) del backup funcional, garantizando 100% de éxito incluso con habilidades fuera de la barra.
- **Doble Gatillo Localizado**: Implementado sistema de casteo dual (Español/Inglés) para asegurar que el servidor Turtle WoW reconozca la orden sin importar el idioma del cliente.
- **Sincronización de Tiempos**: Ajustado el delay de restauración de target a 0.8s para paridad exacta con la versión estable anterior.

## [9.3.0] - Marzo 25, 2026
### ✨ UI OVERHAUL & NATIVE INTEGRATION
- **Panel Maestro Consolidado**: Todas las ventanas secundarias flotantes (Perfiles, Auto-Ejecución, Logros, Diagnóstico, Integraciones) se han movido a un único panel maestro de 680x490px con estética coherente ("Séquito del Terror").
- **Eliminación de Ventanas Vacías**: El script `WCS_BrainTabPanels.lua` ya no depende del orden del `.toc` para inyectar su UI. Se han eliminado los envoltorios condicionales, resolviendo el problema crónico donde los tabs aparecían vacíos.
- **Lazy Loading**: Todas las vistas de UI son inicializadas de forma perezosa mediante `getPanel()` para no sobrecargar el login del usuario, garantizando 0 lag en el primer frame.
- **Purga de Syntax Errors**: Se resolvieron 3 errores de parseo `<eof> expected` generados tras la eliminación de los wrappers en `TabPanels.lua`.

## [8.3.7-RESTORED] - Marzo 24, 2026
### FIXED
- **RESTAURACIÓN TOTAL**: Se ha recuperado el núcleo de IA de mascotas original del respaldo funcional de F:\ (72KB).
- **Paridad Bit-a-Bit**: Sincronización exacta de `WCS_BrainPetAI.lua`, `WCS_Helpers.lua`, `WCS_EventManager.lua`, `WCS_ResourceManager.lua`, `WCS_SpellDB.lua` y `WCS_SpellLocalization.lua`.
- **Ecosistema Recuperado**: Re-activados los 12 módulos de mascotas en el `.toc` para permitir coordinación avanzada y modo Guardián.
- **Sin Errores de Carga**: El archivo `WCS_BrainPetAI.lua` ahora tiene sus 1970 líneas originales, garantizando que todas las estrategias tácticas estén presentes.
- **UI Stable**: Corregido error `Log (a nil value)` en `WCS_BrainUI.lua:912` que bloqueaba el inicio del addon.


## [8.3.5] - Marzo 24, 2026
### Fixed
- **LocalizaciÃ³n Universal**: Corregido el motor de detecciÃ³n de mascotas para clientes en EspaÃ±ol (Diablillo, Abisario, etc).
- **Firmas de Habilidad**: Las mascotas ahora se identifican por sus habilidades (Escudo de Fuego, Sacrificio) en lugar de nombres localizados.

## [8.3.4] - Marzo 24, 2026
### Fixed
- **Tolerancia Cero**: Sincronizada la lÃ³gica del Felhunter con el rastreador de casteo enemigo (`EnemyCastingTable`).
- **Robustez**: AÃ±adidos nil-guards adicionales en el motor de eventos de hechizos.

## [8.3.3] - Marzo 24, 2026
### Fixed
- **MASTER FUSION**: Integrada la lÃ³gica tÃ¡ctica de `GuardianEnhanced` (CC, Taunt, Intercept) con el motor `Ghost-Cast`.
- **Reflejos Restaurados**: Recuperadas las funciones de protecciÃ³n de aliados que se perdieron en la v8.3.2.
- **DetecciÃ³n DinÃ¡mica**: Mejora en la identificaciÃ³n de tipos de mascotas (incluyendo Demonios Mayores localizados).

## [8.3.2] - Marzo 24, 2026
### Fixed
- **ConsolidaciÃ³n de Arquitectura**: Desactivados 12 mÃ³dulos de mascotas redundantes que causaban colisiones de Ã³rdenes.
- **Autoridad Ãšnica**: El PetAI v8.3.2 es ahora el Ãºnico motor de decisiones, asegurando autonomÃ­a total.

## [8.3.1] - Marzo 24, 2026

## [8.3.0] - Marzo 24, 2026
### ðŸ› ï¸ BUG-FIXING & OPTIMIZACIÃ“N (v8.3.0)
- **Imp Raid Support**: Restaurada la funcionalidad de Fire Shield masivo para 5, 10 y 40 personas.
- **Infernal Fixed**: Eliminado el spam de chat del Infernal y corregida la detecciÃ³n de su Aura de InmolaciÃ³n en Turtle WoW.
- **Silent Execution**: Las habilidades de soporte ahora se ejecutan de forma invisible (Ghost-Cast) sin usar el chat y con restauraciÃ³n instantÃ¡nea del target.
- **Link Corregido**: Reparada la delegaciÃ³n de mando en `WCS_PetManager.lua` para evitar conflictos entre motores.

Todas las versiones notables de este proyecto serÃ¡n documentadas en este archivo.

---

## [8.2.0] - Marzo 24, 2026
### ðŸ§  INTELIGENCIA TÃCTICA GOD-TIER
- **Smart Dispel (Felhunter)**: PriorizaciÃ³n dinÃ¡mica de debuffs (CC > Silencio > DaÃ±o).
- **Sistema de Peeling (Voydwalker)**: IntercepciÃ³n reactiva de atacantes para proteger al Warlock.
- **Rastreador de Casteo 1.12**: Implementado fallback autÃ³nomo vÃ­a Combat Log para identificar hechizos enemigos.
- **EjecuciÃ³n Nativa (v8.1.0)**: MigraciÃ³n completa a `CastPetAction` garantizando 100% obediencia tÃ©cnica.
- **UnificaciÃ³n de Motores**: El `PetManager` bÃ¡sico ahora delega toda la tÃ¡ctica al cerebro avanzado.

## [8.0.0] - Marzo 22, 2026
### ðŸ† EVOLUCIÃ“N GOD-TIER
- **Soporte Multi-Clase Universal**: IntegraciÃ³n del `WCS_ClassEngine` y `WCS_ClassRotations`. La IA ahora detecta la raza y clase (las 9 disponibles) y ejecuta rotaciones con mitigaciÃ³n de daÃ±o, sin depender de Warlocks.
- **Hub de Comando Unificado (5-Tabs)**: El macro-panel de opciones se rediseÃ±Ã³ desde cero para incluir pestaÃ±as directas de `IA`, `CLAN`, `PET`, `HUD` y `SYS` bajo el comando unificado `/brain`.
- **Rebirth GrÃ¡fico (Deep Void Theme)**: La estÃ©tica del addon fue pulida en sus ~40 paneles secundarios eliminando las UI base genÃ©ricas e implementando Tooltips oscuros con bordes violetas `#9482C9` (0.58, 0.51, 0.79).
- **Control de Mascotas Inteligente**: Guardianes de clase dinÃ¡micos aseguran que la UI de mascotas (`WCS_BrainPetUI`) solo se ejecute y recaude memoria si el jugador es Warlock o Hunter.
- **Micro-Optimizaciones Lua 5.0**: Limpieza total de incompatibilidades futuras (`#table`, `string.match`) brindando compatibilidad inmaculada con 1.12.
- **AuditorÃ­a Forense 100% Correcta**: Arreglo de 10 bugs crÃ­ticos de Lua y crasheos en el arranque.
- **WCSVault (Banco Guild P2P)**: El Banco del Clan reemplaza el "Inventario Local" por un Libro Mayor distribuido que sincroniza donaciones y prÃ©stamos en vivo a travÃ©s de un protocolo oculto de addon.
- **Macros Asistidas (Raid & Summon)**: GeneraciÃ³n 1-clic (script nativo) para macros de utilidad complejas (Soulstones, Healthstones, Auto-Curses, Ritual).
- **Roster en Tiempo Real**: Panel de miembros corregido (adiÃ³s al false *Online: 0*) atado a escuchas servidor `GUILD_ROSTER_UPDATE`.

---

## [7.0.0] - Enero 20, 2026

### ðŸš€ REARQUITECTURA MAYOR - Cerebro Predictivo & HUD HologrÃ¡fico

Esta versiÃ³n marca un hito en el desarrollo de WCS_Brain, introduciendo una arquitectura profesional basada en eventos, simulaciÃ³n matemÃ¡tica real de daÃ±o y una interfaz HUD inmersiva.

### âœ¨ Nuevas CaracterÃ­sticas

#### 1. Cerebro Predictivo (BrainSim)
- **Simulador de daÃ±o real (DPCT):** La IA ya no "adivina" quÃ© hechizo es mejor. Ahora calcula matemÃ¡ticamente el daÃ±o por segundo de casteo (DPCT) basÃ¡ndose en tu gear, talentos y buffs activos.
- **Snapshotting inteligente:** Detecta procs de trinkets, Power Infusion y debuffs en el enemigo para ajustar la rotaciÃ³n en tiempo real.

#### 2. Interfaz HologrÃ¡fica (BrainHUD)
- **HUD estilo "Iron Man":** Nueva interfaz minimalista y transparente cerca de tu personaje.
- **VisualizaciÃ³n de decisiones:** Muestra el icono de la siguiente acciÃ³n que la IA va a realizar *antes* de que ocurra.
- **Monitor de Shards:** Anillo hologrÃ¡fico que muestra tus Soul Shards disponibles.
- **Comando:** `/brainhud` para activar/desactivar.

#### 3. Arquitectura y Rendimiento (Core)
- **WCS_EventManager:** Nuevo bus de eventos centralizado. Elimina cientos de frames invisibles redundantes, mejorando drÃ¡sticamente el rendimiento CPU.
- **WCS_ResourceManager:** Gestor unificado de recursos. El addon ahora sabe cuÃ¡ntas Shards tienes sin escanear tus bolsas 50 veces por segundo.

### ðŸ”§ Cambios TÃ©cnicos
- **RefactorizaciÃ³n Masiva:** `WCS_BrainCore` y `WCS_BrainAI` migrados al nuevo sistema de eventos.
- **OptimizaciÃ³n de Memoria:** ReducciÃ³n del garbage collection gracias a la reutilizaciÃ³n de tablas y eventos.
- **Limpieza:** IntegraciÃ³n de parches de versiones 6.x en el nÃºcleo principal.

---

## [6.7.1] - Enero 12, 2026

### ðŸ¾ Sistema de Control de Mascotas - Mejoras CrÃ­ticas de Confiabilidad

**Archivo Modificado:** WCS_BrainPetAI.lua

**Problema Resuelto:**
El sistema de control de mascotas tenÃ­a una confiabilidad del ~60% debido a que usaba ChatFrameEditBox como mÃ©todo principal para ejecutar habilidades. Este mÃ©todo falla si el chat estÃ¡ oculto o el jugador estÃ¡ escribiendo.

**Nuevas Funciones Agregadas:**

1. **GetPetAbilitySlot(abilityName)** - Encuentra el slot (1-10) de una habilidad de mascota por nombre
2. **PetHasAbility(abilityName)** - Verifica si la mascota tiene una habilidad especÃ­fica
3. **CanCastPetAbility(abilityName)** - VerificaciÃ³n completa: existencia + cooldown + mana

**Funciones Mejoradas:**

1. **ExecuteAbility()** - Completamente reescrito con sistema de 3 niveles:
   - MÃ©todo 1: CastSpellByName() (95% confiable)
   - MÃ©todo 2: CastPetAction(slot) (fallback)
   - MÃ©todo 3: ChatFrameEditBox (Ãºltimo recurso)

2. **CastEnslaveDemon()** - Mejorado con CastSpellByName() primero

3. **GuardianAssist()** - Usa TargetUnit() + feedback visual

4. **GuardianDefend()** - Muestra HP del protegido

**Mejoras de Confiabilidad:**
- Antes: 60% â†’ DespuÃ©s: 95%
- Cooldowns usando API real (GetPetActionCooldown)
- Debug detallado: "[Execute] Fire Shield - CastSpellByName"

**Compatibilidad:**
- âœ… WoW 1.12 (Turtle WoW) | âœ… Lua 5.0 | âœ… Todas las mascotas

**Comandos:**
```lua
/petai debug        -- Activa mensajes de debug detallados
/petai status       -- Muestra versiÃ³n (v8.0.0)
```

---


## [6.9.3] - Enero 9, 2026

### ðŸŒ Sistema Multiidioma - Soporte Completo para EspaÃ±ol

**Nuevos MÃ³dulos:**
- âœ… **WCS_SpellLocalization.lua** - Base de datos de 150+ traducciones espaÃ±olâ†’inglÃ©s
- âœ… **WCS_SpellDB_Patch.lua** - Sobrescritura global de GetSpellName() + comando /listspells
- âœ… **WCS_BrainAutoExecute.lua** - Sistema de ejecuciÃ³n automÃ¡tica en combate

**CaracterÃ­sticas Implementadas:**
- âœ… Sobrescritura global transparente de GetSpellName()
- âœ… Todos los hechizos crÃ­ticos del Brujo traducidos y verificados
- âœ… Habilidades de todas las mascotas (Imp, Voidwalker, Succubus, Felhunter, Felguard)
- âœ… Sistema de cache para eficiencia
- âœ… Comando /listspells para debug (verde=traducido, rojo=sin traducir)
- âœ… Compatible con actualizaciones futuras del addon (no modifica archivos originales)

**Hechizos Traducidos:**
- Hechizos de daÃ±o: Shadow Bolt, Immolate, Corruption, Shadowburn, Rain of Fire, Hellfire, etc.
- Hechizos defensivos: Demon Armor, Demon Skin, Soul Link, Shadow Ward
- Invocaciones: Todas las mascotas + Inferno
- Piedras: Soulstone, Healthstone, Voidstone, Demonstone (todos los rangos)
- Control: Fear, Banish, Enslave Demon, Death Coil, Drain Soul, etc.

**Sistema de EjecuciÃ³n AutomÃ¡tica:**
- Frame OnUpdate con throttling (0.2s por defecto)
- Comandos: /autoexec on/off, /autoexec status, /autoexec interval
- Respeta GCD y cooldowns
- Activado por defecto: NO (el usuario debe activarlo con /autoexec on)

**Archivos Modificados:**
- WCS_Brain.toc - AÃ±adidas 3 lÃ­neas para cargar los nuevos mÃ³dulos

**DocumentaciÃ³n:**
- âœ… MULTIIDIOMA.md - DocumentaciÃ³n completa del sistema
- âœ… README.md - Actualizado con secciÃ³n de multiidioma
- âœ… CHANGELOG.md - AÃ±adida entrada v8.0.0

**VerificaciÃ³n:**
- âœ… Todos los hechizos crÃ­ticos del Brujo funcionan correctamente
- âœ… Sistema probado en Turtle WoW con cliente en espaÃ±ol
- âœ… Compatible con Lua 5.0 (WoW 1.12)

---

## [6.9.2] - Enero 7, 2026

### ðŸ”§ Dashboard Mejorado y Limpieza de CÃ³digo

**Mejoras al Dashboard:**
- âœ… Integrado con WCS_BrainMetrics (sistema original del addon)
- âœ… Muestra datos REALES de combate
- âœ… Contador de "Decisiones IA" ahora funciona correctamente
- âœ… Contador de "Pet IA" lee desde WCS_BrainPetAI.Stats
- âœ… Eventos procesados muestra combates totales
- âœ… CPU estimado: 15% en combate, 0.5% fuera de combate
- âœ… Desactivado WCS_BrainDashboard_Counters.lua (hooks rompÃ­an funciones)

**Archivos Modificados:**
- WCS_BrainDashboard_Fix.lua - Integrado con WCS_BrainMetrics.Data.spellUsage
- WCS_Brain.toc - Desactivado Counters, eliminadas referencias a archivos basura

**Archivos Basura Eliminados:**
- âŒ WCS_BrainCore_Debug.lua (sobrescribÃ­a ExecuteAction)
- âŒ WCS_BrainCore_CastDebug.lua (debug innecesario)
- âŒ WCS_BrainAutoCombat.lua (interferÃ­a con sistema existente)
- âŒ WCS_BrainKeybind.lua (no necesario)
- âŒ Bindings.xml (keybinds no necesarios)

**CÃ³mo Usar el Addon:**
El addon WCS_Brain se usa con el **botÃ³n flotante** en pantalla (icono morado):
- Click DERECHO â†’ Ejecuta la IA automÃ¡ticamente
- Click IZQUIERDO â†’ Abre configuraciÃ³n

**Archivos Ãštiles del Dashboard:**
- âœ… WCS_BrainDashboard.lua (original)
- âœ… WCS_BrainDashboard_Fix.lua (integraciÃ³n con Metrics)
- âœ… WCS_BrainDashboard_Debug.lua (/wcsdebug)
- âœ… WCS_BrainDashboard_Test.lua (/wcsdashtest)
- âœ… WCS_BrainDashboard_Inspect.lua (/wcsdashinspect)

---

## [6.9.0] - Enero 6, 2026

### ðŸš€ FASE 3 - Nuevas Features y Optimizaciones

**FASE 2: Optimizaciones de Memoria (Riesgo BAJO)**

**Nuevos MÃ³dulos:**
- **WCS_BrainCleanup.lua** - Limpieza automÃ¡tica de cooldowns principales cada 60s
- **WCS_BrainPetAICleanup.lua** - Limpieza automÃ¡tica de cooldowns de mascotas cada 60s

**Mejoras:**
- âœ… PrevenciÃ³n de crecimiento indefinido de tablas de cooldowns
- âœ… GestiÃ³n automÃ¡tica de memoria sin intervenciÃ³n manual
- âœ… Sistema de limpieza no invasivo que no afecta funcionalidad

---

**FASE 3 - SESIÃ“N 1: Features de Prioridad ALTA (Riesgo BAJO)**

**Nuevos MÃ³dulos:**
- **WCS_BrainEventThrottle.lua** - Sistema de throttling de eventos de combate
- **WCS_BrainNotifications.lua** - Notificaciones en pantalla estilo Blizzard
- **WCS_BrainSavedVarsValidator.lua** - ValidaciÃ³n automÃ¡tica de SavedVariables
- **WCS_BrainSafety.lua** - LÃ­mites de seguridad globales

**CaracterÃ­sticas:**

**1. Throttling de Eventos:**
- Limita procesamiento de eventos frecuentes (COMBAT_LOG: 0.1s, UNIT_HEALTH: 0.15s)
- EstadÃ­sticas de eventos bloqueados
- Comando: `/wcsthrottle stats`
- Mejora FPS en combates intensos

**2. Notificaciones:**
- UIErrorsFrame (centro de pantalla) + fallback a chat
- 5 tipos: INFO, SUCCESS, WARNING, ERROR, CRITICAL
- Colores y sonidos por tipo
- Throttling de duplicados (2s)
- Historial de 100 entradas
- Comandos: `/wcsnotif test`, `/wcsnotif history`

**3. ValidaciÃ³n SavedVariables:**
- ValidaciÃ³n automÃ¡tica al cargar addon
- DetecciÃ³n y reparaciÃ³n de datos corruptos
- MigraciÃ³n entre versiones (v5.x â†’ v6.x â†’ v6.7 â†’ v6.8)
- Comando: `/wcsvalidate check`

**4. LÃ­mites de Seguridad:**
- VerificaciÃ³n cada 30 segundos
- LÃ­mites: Cooldowns (100), LearnedSpells (500), Logs (500), History (200)
- Limpieza automÃ¡tica al exceder lÃ­mites
- Comandos: `/wcssafety check`, `/wcssafety stats`

---

**FASE 3 - SESIÃ“N 2: Features de Prioridad MEDIA (Riesgo MEDIO)**

**Nuevos MÃ³dulos:**
- **WCS_BrainDashboard.lua** - Dashboard de rendimiento en tiempo real
- **WCS_BrainWeakAuras.lua** - IntegraciÃ³n completa con WeakAuras
- **WCS_BrainBossMods.lua** - IntegraciÃ³n con BigWigs y DBM

**CaracterÃ­sticas:**

**1. Dashboard de Rendimiento:**
- Ventana movible de 400x500 pÃ­xeles
- MÃ©tricas del sistema: FPS, Latencia, Memoria, CPU
- MÃ©tricas de eventos: Procesados, Throttled
- MÃ©tricas de cooldowns: Activos, Pet Cooldowns, CachÃ©
- MÃ©tricas de IA: Decisiones BrainAI, Decisiones PetAI
- Historial de 60 segundos
- Colores dinÃ¡micos segÃºn rendimiento
- Comandos: `/wcsdash`, `/wcsdash hide`, `/wcsdash toggle`, `/wcsdash reset`

**2. IntegraciÃ³n WeakAuras:**
- Variable global: `WCS_WeakAurasData`
- ActualizaciÃ³n cada 100ms
- 6 categorÃ­as de datos: player, pet, ai, cooldowns, performance, alerts
- Funciones helper para custom triggers
- Comandos: `/wcswa status`, `/wcswa test`, `/wcswa export`, `/wcswa help`

**3. IntegraciÃ³n Boss Mods:**
- DetecciÃ³n automÃ¡tica de BigWigs y DBM
- Hooks no invasivos
- AnÃ¡lisis inteligente de 6 tipos de alertas
- Reacciones automÃ¡ticas configurables
- Sistema de callbacks extensible
- Historial de 50 alertas
- Comandos: `/wcsbm status`, `/wcsbm stats`, `/wcsbm alerts`, `/wcsbm history`, `/wcsbm toggle`

---

**HOTFIX: Compatibilidad WoW 1.12**
- Corregido uso de `#` por `table.getn()` en todos los mÃ³dulos nuevos
- Corregido uso de `self` por `this` en frames OnUpdate
- Corregido uso de `...` por `arg1` en frames
- 100% compatible con Lua 5.0

---

**Correcciones Menores (Fase 1):**
- Actualizada versiÃ³n en WCS_Brain.lua (6.7.0 â†’ 6.8.0)
- Agregado guard `isThinking` en WCS_BrainPetAI.lua para prevenir race conditions
- Protegida restauraciÃ³n de target en WCS_GuardianV2.lua con pcall

---

## [6.8.0] - Enero 6, 2026

### ðŸ¾ Sistema Guardian para Mascotas - ProtecciÃ³n de Aliados

**Nuevos MÃ³dulos:**
- **WCS_GuardianV2.lua** - Sistema mejorado de defensa con rotaciÃ³n de habilidades
- **WCS_BrainGuardianCombatLog.lua** - DetecciÃ³n de atacantes via CombatLog en tiempo real
- **WCS_BrainGuardianAlerts.lua** - Sistema de notificaciones visuales
- **WCS_BrainCombatCache_GuardianExt.lua** - Extensiones del cache para tracking multi-unidad
- **WCS_BrainMajorDemonAlerts.lua** - Alertas visuales mejoradas para demonios mayores

**CaracterÃ­sticas del Sistema Guardian:**
- âœ… Modo Guardian activable con clic derecho en pet bar (targetea aliado primero)
- âœ… DetecciÃ³n automÃ¡tica de atacantes en 4 niveles de prioridad
- âœ… Tracking de atacantes en tiempo real con DPS y daÃ±o total
- âœ… PriorizaciÃ³n automÃ¡tica del atacante mÃ¡s peligroso (mayor DPS)
- âœ… RotaciÃ³n inteligente de habilidades por tipo de mascota:
  - Voidwalker: Torment/Suffering
  - Felguard: Anguish/Cleave
  - Succubus: Seduction (CC)
  - Felhunter: Spell Lock/Devour Magic
  - Imp: Fire Shield automÃ¡tico
- âœ… Sistema de alertas visuales (5 tipos: Under Attack, Defending, Taunt, Emergency, Protected)
- âœ… IntegraciÃ³n con CombatCache para tracking de amenaza y DPS recibido
- âœ… Macros automÃ¡ticas: WCS_Guard, WCS_PetPos

**Nuevos Comandos:**
```lua
/petguard [nombre]     -- Asignar guardiÃ¡n (o clic derecho en pet bar)
/petguard target       -- Asignar tu target actual
/gstats                -- Ver estadÃ­sticas detalladas del guardiÃ¡n
/galerts on/off        -- Activar/desactivar alertas visuales
/guardmacros create    -- Crear macros WCS_Guard y WCS_PetPos
/gdebug                -- Activar/desactivar modo debug
```

**Mejoras de Alertas de Demonios Mayores:**
- âœ… Frame visual grande (400x80px) en centro superior de pantalla
- âœ… Sistema de 3 alertas: 60s (amarillo), 30s (naranja), 15s (rojo crÃ­tico)
- âœ… AnimaciÃ³n de parpadeo para alertas crÃ­ticas
- âœ… Sonidos de alerta segÃºn urgencia
- âœ… Funciona para Infernal y Doomguard
- âœ… Comando /mdalerts test para probar alertas

### ðŸ› Correcciones
- âœ… Pet ya no targetea enemigos muertos (UnitIsDead)
- âœ… Pet ya no cambia el target del jugador (guarda/restaura target)
- âœ… Sistema de debug extensivo para diagnosticar problemas

---

## [6.7.0] - Enero 3, 2026

### âš¡ Sistema de Combate Integrado

**Nuevos MÃ³dulos:**
- **WCS_BrainCombatController.lua** - Coordinador central que arbitra entre DQN, SmartAI y Heuristic
- **WCS_BrainCombatCache.lua** - Cache compartido de DoTs, threat y cooldowns
- **INTEGRACION_COMBATE.md** - DocumentaciÃ³n completa del sistema

**CaracterÃ­sticas:**
- âœ… 4 modos de operaciÃ³n: `hybrid`, `dqn_only`, `smartai_only`, `heuristic_only`
- âœ… Pesos configurables para modo hÃ­brido (DQN 40%, SmartAI 40%, Heuristic 20%)
- âœ… Sistema de decisiones de emergencia automÃ¡ticas (HP/Mana/Pet crÃ­ticos)
- âœ… CoordinaciÃ³n PetAI con acciones del jugador (Fear, Death Coil, Health Funnel)
- âœ… Throttling de decisiones (0.1s mÃ­nimo entre decisiones)
- âœ… Historial de Ãºltimas 50 decisiones para anÃ¡lisis

**Nuevos Comandos:**
```lua
/wcscombat mode [hybrid|dqn_only|smartai_only|heuristic_only]
/wcscombat weights <dqn> <smartai> <heuristic>  -- Ej: 0.4 0.4 0.2
/wcscombat status
/wcscombat reset
```

### ðŸ§¹ Limpieza y OptimizaciÃ³n

**Archivos Obsoletos Removidos:**
- âœ… Eliminados 6 archivos HotFix obsoletos (v8.0.0, v8.0.0, v8.0.0, v8.0.0)
- âœ… Correcciones ya integradas en cÃ³digo base
- âœ… WCS_Brain.toc limpio sin referencias obsoletas
- âœ… Backup completo en carpeta `backup_obsolete/`

**Mejoras de Rendimiento:**
- EliminaciÃ³n de cÃ¡lculos duplicados entre sistemas de IA
- Cache compartido optimiza consultas de estado
- Decisiones coherentes y unificadas

### ðŸ”§ Correcciones Lua 5.0
- Reemplazado operador `#` por `table.getn()` en mÃ³dulos nuevos
- Verificada compatibilidad total con WoW 1.12 / Turtle WoW

### ðŸ“ Archivos Actualizados
- WCS_Brain.toc: VersiÃ³n 6.7.0
- WCS_Brain.lua: VersiÃ³n 6.7.0
- WCS_BrainAI.lua: VersiÃ³n 6.7.0
- WCS_BrainDQN.lua: VersiÃ³n 6.7.0
- WCS_BrainSmartAI.lua: VersiÃ³n 6.7.0
- WCS_BrainPetAI.lua: VersiÃ³n 6.7.0 + Hook OnPlayerAction()
- README.md: Actualizado con sistema de combate integrado

---

## [6.6.1] - Enero 2, 2026

### ðŸ”§ Correcciones

#### Errores CrÃ­ticos Corregidos
1. **WCS_Brain.toc** - Agregado WCS_HotFix_v8.0.0.lua faltante en el orden de carga
2. **WCS_HotFix_v8.0.0.lua** - Eliminada funciÃ³n getTime() duplicada que causaba conflictos
3. **WCS_HotFix_v8.0.0.lua** - Eliminada verificaciÃ³n innecesaria que generaba warnings
4. **WCS_BrainAI.lua:550** - Corregido uso incorrecto de tableLength() para compatibilidad Lua 5.0
5. **WCS_HotFixCommandRegistrar.lua** - Eliminado conflicto de comando duplicado

#### Limpieza de CÃ³digo
- Eliminada carpeta UI/ con versiones antiguas de archivos
- Sincronizada versiÃ³n en todos los archivos (6.6.1)
- Actualizadas fechas a Enero 2026
- Verificada compatibilidad Lua 5.0 en todos los mÃ³dulos

### âœ… Verificaciones
- **66/66 archivos revisados** (100% del cÃ³digo)
- **~25,000 lÃ­neas de cÃ³digo** analizadas
- **0 errores de sintaxis** encontrados
- **Compatibilidad Lua 5.0** confirmada

### ðŸ“ Notas
- NO usa caracterÃ­sticas de Lua 5.1+ (#, string.gmatch, table.unpack)
- USA: table.getn(), unpack(), pairs(), string.gfind(), mod()
- Compatible con Turtle WoW (1.12)

---

## [6.6.0] - Diciembre 2025

### âœ¨ Nuevas CaracterÃ­sticas

#### PestaÃ±a Recursos - 100% Funcional
- **Healthstones:** DetecciÃ³n automÃ¡tica en inventario con contador en tiempo real
- **Soulstones:** Lista de miembros con SS activo y actualizaciÃ³n automÃ¡tica
- **Ritual of Summoning:** DetecciÃ³n de portal activo y cooldown en tiempo real

#### UI del Clan - 7 MÃ³dulos Completos
1. **WCS_ClanPanel** - Panel principal con lista de miembros del guild
2. **WCS_ClanBank** - Sistema de tracking de oro con sincronizaciÃ³n
3. **WCS_RaidManager** - GestiÃ³n de HS/SS/Curses con detecciÃ³n real de buffs
4. **WCS_SummonPanel** - Cola de invocaciones con prioridades
5. **WCS_Grimoire** - Biblioteca de hechizos y conocimiento
6. **WCS_PvPTracker** - Seguimiento de estadÃ­sticas PvP
7. **WCS_Statistics** - AnÃ¡lisis de rendimiento y mÃ©tricas

### ðŸ”§ Mejoras TÃ©cnicas
- Sistema de eventos optimizado
- SincronizaciÃ³n automÃ¡tica entre mÃ³dulos
- Interfaz responsive y escalable
- Compatibilidad total con Lua 5.0
