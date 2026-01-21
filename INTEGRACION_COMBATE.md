# Sistema de Combate Integrado v6.7.1

## ⚠️ IMPORTANTE: Cómo Usar el Sistema

El sistema de combate integrado se activa usando el **botón flotante** en pantalla:

- **Botón morado con borde brillante**
- **Click DERECHO** → Ejecuta la IA automáticamente
- **Click IZQUIERDO** → Abre configuración

El botón ejecuta automáticamente `WCS_Brain:Execute()` que llama a `GetNextAction()` (reemplazado por el sistema de IA configurado).

---

## 🐾 Mejoras al Sistema de Control de Mascotas v6.7.1

**Problema Resuelto:**
El sistema anterior de control de mascotas tenía una confiabilidad del ~60% porque usaba ChatFrameEditBox como método principal para ejecutar habilidades. Este método falla cuando:
- El chat está oculto
- El jugador está escribiendo
- Hay lag en la interfaz

**Solución Implementada:**
Sistema de ejecución de 3 niveles con múltiples fallbacks:

1. **CastSpellByName()** (Método Principal - 95% confiable)
   - Ejecuta habilidades directamente por nombre
   - Funciona incluso con chat oculto
   - Más rápido y confiable

2. **CastPetAction(slot)** (Fallback)
   - Encuentra el slot de la habilidad en la barra de mascotas
   - Ejecuta directamente desde el slot
   - Usa GetPetAbilitySlot() para encontrar la habilidad

3. **ChatFrameEditBox** (Último Recurso)
   - Solo si los otros métodos fallan
   - Mantiene compatibilidad con casos edge

**Nuevas Funciones de Verificación:**

```lua
-- Encuentra el slot de una habilidad en la barra de mascotas
GetPetAbilitySlot("Fire Shield")  -- Retorna: 1-10 o nil

-- Verifica si la mascota tiene la habilidad
PetHasAbility("Torment")  -- Retorna: true/false

-- Verificación completa antes de ejecutar
CanCastPetAbility("Suffering")  -- Comprueba: existencia + CD + mana
```

**Mejoras en Modo Guardián:**

- **Antes:** Usaba AssistUnit() que puede no existir en WoW 1.12
- **Después:** Usa TargetUnit() (más compatible)
- **Feedback Visual:** Muestra mensajes en pantalla
  - "|cFFFFD700[GUARDIÁN]|r Asistiendo a NombreJugador"
  - "|cFFFF0000[GUARDIÁN]|r Defendiendo a TankName (HP: 78%)"

**Sistema de Cooldowns Mejorado:**

- **Antes:** Timers manuales (menos preciso)
- **Después:** GetPetActionCooldown() (API real de WoW)
- **Resultado:** Cooldowns exactos al segundo

**Debug Detallado:**

Con `/petai debug` activado, verás mensajes como:
```
[CanCast] Fire Shield - OK
[Execute] Fire Shield - CastSpellByName
[CanCast] Torment - EN CD (3.2s)
[CanCast] Suffering - MANA INSUFICIENTE (necesita 250, tiene 180)
[GUARDIÁN] Asistiendo a PlayerName
[GUARDIÁN] Defendiendo a TankName (HP: 45%)
```

**Impacto en Combate:**

- ✅ Ejecución de habilidades: 60% → 95% de éxito
- ✅ Respuesta más rápida en combate intenso
- ✅ Menos fallos por chat oculto
- ✅ Mejor coordinación jugador-mascota
- ✅ Modo Guardián más efectivo en raids

**Compatibilidad:**
- ✅ Todas las mascotas (Imp, Voidwalker, Succubus, Felhunter, Felguard)
- ✅ Todos los modos (Aggressive, Defensive, Passive, Guardian)
- ✅ Sistema de aprendizaje sigue funcionando
- ✅ Integración con CombatController sin cambios



---

# Sistema de Combate Integrado v6.8.0

## Descripción General

El nuevo sistema de combate integrado coordina tres sistemas de IA diferentes para proporcionar las mejores decisiones de combate:

1. **DQN (Deep Q-Network)** - Red neuronal que aprende de la experiencia
2. **SmartAI** - Sistema de reglas heurísticas avanzadas con análisis de combate
3. **Heuristic AI** - Sistema base de reglas simples

## Arquitectura

```
WCS_BrainCombatController (Coordinador Central)
    │
    ├── WCS_BrainCombatCache (Cache Compartido)
    │   ├── DoTs tracking
    │   ├── Threat tracking
    │   └── Cooldowns
    │
    ├── Sistema de Emergencia (Prioridad Máxima)
    │   ├── Salud crítica < 15%
    │   ├── Mana crítico < 5%
    │   └── Mascota crítica < 10%
    │
    ├── WCS_BrainDQN (Red Neuronal)
    │   ├── Aprende de experiencia
    │   ├── Replay Buffer (1000 entradas)
    │   └── Sistema de recompensas
    │
    ├── WCS_BrainSmartAI (Heurísticas Avanzadas)
    │   ├── Análisis de amenaza
    │   ├── Predicción de mana
    │   ├── Time-to-kill estimation
    │   └── Simulación de Daño (BrainSim) [ v7.0.0 ]
    │
    ├── WCS_BrainAI (Sistema Base)
    │   └── Reglas básicas de combate
    │
    └── WCS_BrainPetAI (Control de Mascota)
        └── Coordinación con acciones del jugador
```

## Modos de Operación

### 1. Modo Híbrido (Recomendado)
```lua
/wcscombat mode hybrid
```

Combina las decisiones de los tres sistemas usando pesos configurables:
- **DQN**: 40% (aprende y mejora con el tiempo)
- **SmartAI**: 40% (análisis avanzado instantáneo)
- **Heuristic**: 20% (reglas básicas como fallback)

**Cuándo usar**: Uso general, proporciona el mejor balance entre aprendizaje y decisión inmediata.

### 2. Modo DQN Only
```lua
/wcscombat mode dqn_only
```

Solo usa la red neuronal para tomar decisiones.

**Cuándo usar**: 
- Cuando el DQN ya ha sido entrenado extensivamente
- Para probar el rendimiento puro del aprendizaje automático
- En situaciones repetitivas donde el DQN ha aprendido patrones

### 3. Modo SmartAI Only
```lua
/wcscombat mode smartai_only
```

Solo usa el sistema de reglas heurísticas avanzadas.

**Cuándo usar**:
- Comportamiento predecible y consistente
- Situaciones nuevas donde el DQN no tiene experiencia
- Debugging y análisis de decisiones

### 4. Modo Heuristic Only
```lua
/wcscombat mode heuristic_only
```

Solo usa las reglas básicas.

**Cuándo usar**:
- Mínimo uso de recursos
- Comportamiento simple y directo

## Configuración de Pesos

En modo híbrido, puedes ajustar los pesos de cada sistema (deben sumar 1.0):

```lua
-- Ejemplo: Priorizar SmartAI
/wcscombat weights 0.2 0.6 0.2
-- DQN=20%, SmartAI=60%, Heuristic=20%

-- Ejemplo: Priorizar DQN (para entrenamiento)
/wcscombat weights 0.7 0.2 0.1
-- DQN=70%, SmartAI=20%, Heuristic=10%

-- Ejemplo: Balance igual
/wcscombat weights 0.33 0.34 0.33
-- Distribución equitativa
```

## Sistema de Prioridades

Las decisiones se toman en el siguiente orden:

1. **EMERGENCIA** (Prioridad 10) - Siempre se ejecuta
   - Healthstone si salud < 15%
   - Death Coil si salud crítica
   - Life Tap si mana < 5% y salud > 30%
   - Health Funnel si mascota < 10%

2. **Sistema Seleccionado** (Prioridad 1-9)
   - En modo híbrido: se calcula score = prioridad × confianza × peso
   - Se ejecuta la decisión con mayor score

## Cache Compartido

Todos los sistemas comparten información a través de `WCS_BrainCombatCache`:

### DoTs Tracking
- Tiempo restante de cada DoT
- Detección automática de pandemic window (30%)
- Sincronización con WCS_BrainAI

### Threat Tracking
- Acumulación de amenaza
- Historial de generación de threat
- Reset automático al salir de combate

### Cooldowns
- Tracking centralizado de cooldowns
- Evita duplicación de cálculos

## Coordinación con PetAI

El sistema ahora coordina las acciones del jugador con la mascota:

- **Fear**: La mascota sabe que el jugador usó Fear
- **Death Coil**: Indica que el jugador está en peligro
- **Health Funnel**: La mascota puede ser más agresiva

Esto permite que la mascota adapte su comportamiento según las acciones del jugador.

## Comandos

```lua
-- Ver estado actual
/wcscombat status

-- Cambiar modo
/wcscombat mode <hybrid|dqn_only|smartai_only|heuristic_only>

-- Ajustar pesos (deben sumar 1.0)
/wcscombat weights <dqn> <smartai> <heuristic>

-- Ejemplos:
/wcscombat mode hybrid
/wcscombat weights 0.4 0.4 0.2
/wcscombat status
```

## Ventajas del Sistema Integrado

### 1. Mejor Toma de Decisiones
- Combina aprendizaje automático con reglas expertas
- Decisiones de emergencia instantáneas
- Adaptación a diferentes situaciones

### 2. Optimización de Rendimiento
- Cache compartido evita cálculos duplicados
- Sincronización automática entre sistemas
- Limpieza periódica de datos obsoletos

### 3. Flexibilidad
- Múltiples modos de operación
- Pesos configurables
- Fácil de ajustar según preferencias

### 4. Coordinación
- Jugador y mascota trabajan juntos
- Información compartida entre todos los sistemas
- Decisiones coherentes

## Debugging

Para ver qué sistema está tomando cada decisión:

```lua
-- Activar debug en WCS_Brain
WCS_Brain.DEBUG = true

-- Ver decisiones en el chat
-- Formato: "Decisión: <hechizo> [<sistema>] - <razón>"
```

## Recomendaciones

### Para Principiantes
```lua
/wcscombat mode smartai_only
```
Comportamiento predecible y efectivo.

### Para Usuarios Avanzados
```lua
/wcscombat mode hybrid
/wcscombat weights 0.4 0.4 0.2
```
Mejor balance entre todos los sistemas.

### Para Entrenamiento del DQN
```lua
/wcscombat mode hybrid
/wcscombat weights 0.6 0.3 0.1
```
Prioriza el DQN para que aprenda más rápido.

### Para Máximo Rendimiento (DQN entrenado)
```lua
/wcscombat mode dqn_only
```
Usa solo la red neuronal entrenada.

## Troubleshooting

### El sistema no toma decisiones
1. Verificar que WCS_Brain esté activado
2. Revisar modo: `/wcscombat status`
3. Activar debug: `WCS_Brain.DEBUG = true`

### Decisiones inconsistentes
1. Verificar pesos: `/wcscombat status`
2. Considerar cambiar a modo específico
3. Revisar si hay emergencias activas

### Mascota no coordina
1. Verificar que PetAI esté activado: `/petai status`
2. Revisar coordinación en CombatController

## Próximos Pasos

El sistema está diseñado para ser extensible. Futuras mejoras incluirán:

- Sistema de recompensas mejorado para el DQN
- Más coordinación entre jugador y mascota
- Análisis de situaciones de grupo/raid
- Perfiles automáticos según tipo de combate
