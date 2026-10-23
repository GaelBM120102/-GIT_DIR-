# Brújula ✦ — iPhone

App nativa SwiftUI para organizar tareas, planes y pensamientos, con estética de graffiti y datos guardados localmente en el iPhone. Requiere iOS 17 o posterior.

[Instalación desde Windows por $0, sin suscripciones](INSTALAR_EN_IPHONE_GRATIS.md).

## Compilación

El workflow de GitHub Actions utiliza una máquina estándar macOS en un repositorio público. No usa credenciales de Apple ni certificados de pago. Genera un IPA sin firmar que después se firma en Windows con Sideloadly y una cuenta gratuita de Apple.

Para compilar en macOS con Xcode instalado:

```bash
bash checks/build_ipa.sh
```

Para ejecutar en simulador, abre `Brujula.xcodeproj` y selecciona el esquema Brujula.

## Datos y límites de esta versión

Los datos se guardan en Documents/brujula.json con escritura atómica. No se envían a GitHub ni a un servidor propio. Hay exportación JSON; todavía no hay importación, sincronización, IA ni notificaciones. La firma gratuita requiere renovación cada 7 días.

Al preparar esta versión, se han validado la sintaxis Swift, la estructura del proyecto Xcode y el registro de fuentes. La compilación real de Xcode y las pruebas en un iPhone siguen pendientes.

Rubik Spray Paint y Permanent Marker proceden del repositorio oficial de Google Fonts. Sus archivos de licencia acompañan a las fuentes en Brujula/Fonts/.
