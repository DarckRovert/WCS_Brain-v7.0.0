# 🛠️ Wiki: Guía de API — WCS_Brain [The Neural Core]

El núcleo neuronal de **El Séquito del Terror** expone métodos globales para la integración de telemetría y control táctico.

## 📡 Funciones de Telemetría (Global API)

### `WCS_Brain.GetTacticalStatus()`
Retorna el estado de inferencia actual del motor de la mascota.
- **Valores**: `"Aggressive"`, `"Defensive"`, `"Safety_Mode"`, `"Idle"`.

### `WCS_Brain.GetMLMetrics()`
Obtiene las métricas de precisión del motor de aprendizaje en la sesión actual.
- **Retorno**: Tabla con `hits`, `misses`, `precision_index`.

## 📎 Integración con Combat Log
Si desarrollas AddOns de métricas como **TerrorMeter**, puedes suscribirte a los eventos personalizados de `WCS_Brain`:

- `WCS_BRAIN_DECISION_MADE`: Se dispara cada vez que el motor toma una decisión de hechizo.
- `WCS_BRAIN_RESOURCE_LOW`: Alerta de fragmentos de alma por debajo del umbral de seguridad.

## ⚙️ Hooks de Interfaz
Puedes añadir botones al Neural HUD usando:
`WCS_Brain.RegisterHUDButton(name, icon, func)`

---
© 2026 **DarckRovert** — El Séquito del Terror.
*Ingeniería de software para la élite de Azeroth.*
