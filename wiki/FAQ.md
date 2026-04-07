# ❓ Wiki: FAQ [The Neural Core] — WCS_Brain

Preguntas frecuentes y resolución de problemas técnicos para el núcleo v7.1+.

## 🛠️ Error: Mi mascota no usa hechizos automáticamente.
- **Causa**: El motor de inferencia táctica se desactiva si tu nivel de Soul Shards es inferior al umbral de seguridad (`WCS_BrainSafety`).
- **Solución**: Verifica tus fragmentos. O bien, desactiva temporalmente el **Safety Mode** en el panel de Brain.

## ⚙️ ¿Cómo funciona el aprendizaje?
- **Proceso**: El motor ML observa qué hechizos lanzas tú y qué hechizos lanza tu mascota. Si detecta un patrón de éxito (objetivo muerto rápido sin daño excesivo), aumenta el "peso" de esa secuencia en la caché de inferencia.

## ⚡ El juego da picos de lag al invocar a la mascota.
**Estado**: ✅ Optimizado en v7.1.0.
- El escaneo inicial de hechizos de la mascota ahora se ejecuta en ráfagas asíncronas para no bloquear la carga del mundo.

---
© 2026 **DarckRovert** — El Séquito del Terror.
*Ingeniería de software para la élite de Azeroth.*
