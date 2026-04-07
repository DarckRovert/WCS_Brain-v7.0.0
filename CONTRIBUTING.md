# Contributing to WCS_Brain [The Neural Core] 🧬🧠

¡Gracias por contribuir a la evolución del núcleo neuronal de **El Séquito del Terror**! Para mantener el estándar **Diamond Tier** de **DarckRovert**, todas las mejoras deben priorizar la precisión táctica y la eficiencia de inferencia.

---

## 🛡️ Estándares Técnicos (Neural Core)

Este AddOn está optimizado para **Turtle WoW** (WoW v1.12.1). Las contribuciones DEBEN cumplir con:

1.  **Safety First**: No alteres el motor de `WCS_BrainSafety` sin validación previa. La gestión de Soul Shards es crítica.
2.  **No Lua 5.1+**: El motor es Lua 5.0. Prohibido el operador `#` (usa `table.getn`).
3.  **Inference Throttling**: Todo nuevo proceso de decisión DEBE implementar un throttle. El motor de inferencia táctica no debe saturar el hilo principal.
4.  **Modular Logic**: Mantén la lógica ML separada del motor de renderizado de UI.

## 📐 Arquetipo de Desarrollo

Si eres desarrollador y deseas contribuir:
- **`WCS_BrainPetAI.lua`**: Es el centro de mando. Cualquier cambio aquí requiere una auditoría de rendimiento exhaustiva en combate masivo.
- **`WCS_BrainML.lua`**: Optimiza los algoritmos de reconocimiento de patrones. Evita el uso excesivo de tablas dinámicas.
- **`WCS_BrainLearning.lua`**: El entrenamiento debe ser persistente pero con un footprint de memoria mínimo.

## 💎 Proceso de Pull Request

1.  **Fork & Branch**: Trabaja en ramas descriptivas (`fix/inference-pet`, `feature/ml-pattern`).
2.  **Documentación**: Actualiza `CHANGELOG.md` antes de enviar el PR.
3.  **Branding**: Mantén los enlaces institucionales oficiales de **DarckRovert**.

---
© 2026 **DarckRovert** — El Séquito del Terror.
*Dotando de inteligencia a las sombras de Azeroth.*