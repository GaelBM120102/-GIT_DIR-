# Brújula en tu iPhone desde Windows — $0, sin suscripciones

La ruta preparada compila la app en GitHub Actions y la firma e instala desde Windows con Sideloadly y tu cuenta gratuita de Apple. No requiere una cuenta Apple Developer de pago ni TestFlight.

## 1. Generar el instalador

GitHub documenta que sus máquinas estándar, incluidas las de macOS, son gratuitas en repositorios públicos. El proceso preparado usa `macos-15` y se omite si el repositorio es privado para no consumir minutos facturables.

Esta ruta requiere subir **el código y los recursos visuales** a un repositorio público, con tu autorización. Los pensamientos y tareas que escribas después se guardan dentro de la app en tu iPhone, no en GitHub. Los ejemplos incluidos en el código son ficticios y opcionales.

La rama preparada se llama `codex/brujula-iphone-gratis`. Agrega la app en la carpeta `Brujula` y el proceso de compilación en `.github/workflows/brujula-iphone.yml`, conservando los ejercicios existentes del repositorio conectado.

Cuando la compilación finalice correctamente, el artefacto de GitHub Actions `Brujula-iPhone-sin-firmar` contendrá un ZIP con **`Brujula-sin-firmar.ipa`**. El IPA todavía debe firmarse en Windows: no se instala tocándolo directamente en Safari. El script que lo construye es `checks/build_ipa.sh`.

**Estado al preparar esta guía:** todavía no se ha ejecutado la compilación de Xcode ni se ha generado un IPA real. La publicación del código está pendiente de autorización. La validación sintáctica realizada no sustituye la compilación.

## 2. Preparar Windows

1. Descarga **Sideloadly para Windows** desde [su página oficial](https://sideloadly.io/). Su descarga y la instalación con una cuenta gratuita de Apple no requieren pago.
2. Sigue los requisitos actuales de Sideloadly para los componentes de iTunes e iCloud de Apple. Indica usar sus versiones web; consulta esas instrucciones antes de cambiar instalaciones existentes.
3. Conecta el iPhone desbloqueado a la PC con un cable USB y acepta «Confiar en esta computadora» en el iPhone.
4. Abre Sideloadly y comprueba que detecta tu iPhone.

## 3. Instalar Brújula

1. Arrastra `Brujula-sin-firmar.ipa` a Sideloadly.
2. Selecciona el iPhone y escribe tu cuenta gratuita de Apple **en Sideloadly**. Completa ahí la autenticación que pida Apple. No compartas contraseñas ni códigos de verificación en el chat.
3. Pulsa **Start**. Sideloadly firma la app para tu iPhone y la instala.
4. Si iOS lo solicita, confía en la firma en **Ajustes → General → VPN y gestión de dispositivos**.
5. Si iOS lo solicita, activa **Ajustes → Privacidad y seguridad → Modo de desarrollador**, reinicia y confirma la activación.
6. Abre **Brújula** desde su icono en el iPhone.

El proyecto requiere iOS 17 o posterior. Los nombres de los ajustes pueden variar según tu versión de iOS.

## 4. Usarla gratis después de instalarla

La firma de una cuenta gratuita dura **7 días**. Renovarla también es gratuito. Sideloadly puede renovarla automáticamente cuando su programa auxiliar está funcionando y detecta el iPhone por USB o por Wi-Fi configurado. Si la PC está apagada o no puede comunicarse con el iPhone, la renovación automática no está garantizada.

Mantén la misma cuenta de Apple y el mismo identificador al renovar o actualizar. No borres Brújula para renovar la firma: eliminar la app borra sus datos locales. Exporta periódicamente tus datos desde «Mi espacio». Esta primera versión exporta JSON, pero aún no permite importarlo desde la interfaz.

Si la firma vence, la app deja de abrir hasta volver a firmarla. No implica una obligación de pago.

## Fuentes oficiales

- [GitHub: máquinas estándar gratuitas en repositorios públicos](https://docs.github.com/en/actions/reference/runners/github-hosted-runners)
- [Sideloadly: Windows, descarga gratuita y cuentas gratuitas de Apple](https://sideloadly.io/)
- [Sideloadly: renovación y duración de la firma](https://sideloadly.io/faq.html)
- [Apple: las cuentas personales permiten probar apps en dispositivos](https://help.apple.com/xcode/mac/current/en.lproj/devaf282080a.html)
