# ✨ Asteria Rol

**Asteria Rol** es una aplicación de rol desarrollada con **Flutter** para organizar partidas, crear personajes y gestionar campañas desde una ficha digital. Combina herramientas para **jugadores** y **Másters**, con reglas configurables y contenido personalizado.

**Versión del proyecto:** `1.1.31+49` · **Estado:** desarrollo activo

> Las fichas, los datos de campaña y los archivos compartidos forman parte de la experiencia de juego. Antes de cambios importantes, recomendamos exportar una copia de seguridad de tu contenido.

## 📑 Índice

1. [Qué puedes hacer](#-qué-puedes-hacer)
2. [Primeros pasos como jugador](#-primeros-pasos-como-jugador)
3. [Herramientas del Máster](#-herramientas-del-máster)
4. [Clases personalizadas y progresión](#-clases-personalizadas-y-progresión)
5. [Criaturas, mascotas y NPC](#-criaturas-mascotas-y-npc)
6. [Combate, habilidades y reglas](#-combate-habilidades-y-reglas)
7. [Importación y exportación](#-importación-y-exportación)
8. [Instalación y desarrollo](#-instalación-y-desarrollo)
9. [Organización del código](#-organización-del-código)
10. [Problemas frecuentes](#-problemas-frecuentes)

## 🎲 Qué puedes hacer

| Área | Funcionalidades |
| --- | --- |
| **Personajes** | Atributos, clases y multiclase, nivel, competencias, salvaciones, vida, recursos, notas y contadores |
| **Combate** | Ataques, daño, curación, mitigación, tiradas digitales o físicas, efectos y críticos |
| **Contenido** | Habilidades, pasivas, armas, armaduras, consumibles, objetos, saberes y carpetas |
| **Progresión** | Clases personalizadas, recompensas por nivel, elecciones múltiples y bonos acumulables |
| **Campañas** | Administración desde el Máster, tiendas, economía, misiones, NPC y criaturas |
| **Compañeros** | Mascotas con atributos, ataques, habilidades, pasivas y efectos |
| **Portabilidad** | Compartir fichas y contenido mediante archivos de importación/exportación |

## 👤 Primeros pasos como jugador

1. Crea una ficha de personaje y selecciona su campaña cuando corresponda.
2. Completa nombre, raza, clase, nivel y atributos.
3. Configura tus habilidades, pasivas, ataques y equipo.
4. Registra recursos, contadores, salud y notas conforme avanza la partida.
5. Utiliza la ficha para realizar tiradas y resolver acciones.
6. Exporta tu personaje cuando necesites compartirlo o trasladarlo a otro dispositivo.

### Fichas de personaje

Una ficha puede incluir atributos, modificadores, competencias, salvaciones, armas, inventario, habilidades, pasivas, efectos, saberes, mascotas, notas y datos de progresión. Las opciones disponibles dependen de su clase y del contenido configurado.

### Organización de contenido

Las carpetas y bibliotecas ayudan a ordenar habilidades, pasivas y objetos. Los objetos personalizados pueden incluir mecánicas propias y utilizarse en las campañas.

## 🏰 Herramientas del Máster

Desde las pantallas de Máster se pueden administrar campañas, misiones, tiendas, clases personalizadas, NPC y criaturas.

### Gestión de campañas

- Crear y gestionar campañas.
- Administrar tiendas, misiones y contenido relacionado.
- Trabajar con personajes jugadores, NPC y criaturas.
- Exportar la campaña completa o por secciones.

**Importante:** la exportación completa **excluye las fichas de personajes jugadores por defecto**. Si quieres compartir un PJ, exporta su ficha por separado. La exportación por secciones ofrece una opción explícita para jugadores cuando sea necesaria.

### NPC

En **Campaña → NPC → Añadir NPC**:

- **Crear NPC:** abre una ficha nueva.
- **Importar NPC:** admite archivos compatibles `.asteria` y `.json`.

En el menú de cada NPC:

- **Exportar NPC** para compartirlo como personaje no jugador.
- **Exportar como jugador** para generar una ficha con rol de jugador sin modificar el NPC original.
- **Eliminar NPC** con confirmación previa.

Las importaciones generan una copia y asignan el NPC a la campaña seleccionada.

## 🧬 Clases personalizadas y progresión

El Máster puede definir clases con recompensas en niveles concretos.

### Recompensas y elecciones

- Recompensas que se conceden automáticamente.
- Elecciones entre habilidades y pasivas.
- Varias elecciones dentro de una misma recompensa.
- Opciones únicas, que no pueden aprenderse repetidamente.
- Opciones acumulables, que permiten obtener una mejora varias veces.
- Vista previa del contenido antes de elegirlo.
- Registro de decisiones y recuperación de elecciones pendientes.

**Ejemplo:** una recompensa de nivel puede permitir elegir **3 opciones** de una misma lista de habilidades y pasivas. Las opciones configuradas como únicas no se repiten; las acumulables pueden volver a seleccionarse.

### Bonificaciones acumulables

Una pasiva que otorga `+2` al daño y `+2` al golpeo puede acumularse así:

| Adquisiciones | Daño adicional | Golpeo adicional |
| ---: | ---: | ---: |
| 1 | +2 | +2 |
| 2 | +4 | +4 |
| 3 | +6 | +6 |

La acumulación depende de que la recompensa esté configurada para permitirla.

## 🐉 Criaturas, mascotas y NPC

### Criaturas del Máster

Desde **Campaña → Criaturas → Añadir criatura** se puede:

- **Crear criatura** mediante un formulario específico para el Máster.
- **Importar criatura** desde un archivo compatible.

El menú individual de una criatura incluye:

- **Exportar como criatura del Máster:** para reutilizarla en otra campaña.
- **Exportar como mascota:** para utilizarla como compañero de un jugador o NPC.
- **Eliminar criatura:** con confirmación.

En el formulario de criaturas, los modificadores de atributos se actualizan **mientras escribes**, sin tener que pulsar Enter.

### Mascotas y compañeros

Desde la sección **Mascotas y compañeros** de un personaje:

- Crea una nueva mascota.
- Importa una criatura o mascota previamente exportada.
- Consulta y modifica los atributos, puntos de vida, defensa, ataques, habilidades, pasivas y efectos.
- Exporta una mascota existente mediante pulsación prolongada sobre su tarjeta.

**Una criatura y una mascota comparten el modelo de datos de compañero**, pero el formulario del Máster emplea títulos y etiquetas propios de criaturas.

## ⚔️ Combate, habilidades y reglas

### Resolución de acciones

- Tiradas de ataque, daño, curación y otros efectos.
- Modo de tiradas digitales o físicas, configurable por separado para ataque y daño/efectos.
- Salvaciones y aplicación de condiciones o efectos.
- Habilidades, pasivas y críticos configurables.
- Fórmulas con atributos, competencias y otros modificadores disponibles.

### Tipos de daño y resistencias

Cada componente de daño puede usar un tipo como `cortante`, `fuego`, `frío`, `veneno` o un **tipo personalizado**. Cuando corresponde, las resistencias se aplican según el tipo del daño.

| Resistencia | Puntos | Daño recibido |
| --- | ---: | ---: |
| Menor | 1 | 75 % |
| Normal | 2 | 50 % |
| Mayor | 4 | 25 % |
| Inmunidad | 8 | 0 % |

Equivalencias: **2 menores = 1 normal**, **2 normales = 1 mayor** y **2 mayores = inmunidad**.

La mitigación de daño puede ser general o limitarse a tipos concretos; no necesita tratarse como un activador de pasiva.

### Tiradas de salvación

Las pasivas pueden conceder bonos y ventaja o desventaja en determinadas salvaciones. Si coinciden ventaja y desventaja para una misma salvación, se cancelan entre sí.

## 📦 Importación y exportación

Asteria dispone de varios flujos de exportación para compartir contenido y reutilizarlo sin volver a crearlo manualmente.

| Contenido | Formato / flujo | Consideraciones |
| --- | --- | --- |
| **Personaje o NPC** | `.asteria`; importación compatible con determinados `.json` | Un NPC también se puede exportar con rol de jugador |
| **Criatura o mascota** | `.asteria-creature` | Puede importarse como criatura del Máster o mascota |
| **Campaña** | `.asteria-campaign` | Exportación completa o dividida en secciones |
| **Clases personalizadas** | Exportación/importación de definiciones o sección de clases | Existe la opción **Solo clases personalizadas** |
| **Tiendas y objetos** | Sus herramientas de importación/exportación | Permiten reutilizar contenido |

### Exportar una campaña por partes

Las secciones disponibles incluyen:

1. Datos generales de campaña.
2. Tiendas.
3. Criaturas.
4. NPC.
5. Misiones.
6. Clases personalizadas.

Las fichas de personajes jugadores se gestionan por separado por defecto y existe una exportación explícita para ellas. El asistente de exportación comparte las secciones sucesivamente, evitando generar un archivo enorme de una sola vez.

### Imágenes y almacenamiento

Los formatos portables pueden incluir imágenes locales disponibles, para que no dependan únicamente de las rutas del dispositivo de origen. Los avatares seleccionados se guardan en el almacenamiento persistente de la aplicación.

**Consejo:** tras importar un archivo en otro dispositivo, revisa la ficha y sus imágenes antes de eliminar la copia original.

## 🛠️ Instalación y desarrollo

### Requisitos

- Flutter instalado y configurado.
- SDK de Dart compatible con `^3.12.1` (consulta `pubspec.yaml` para el requisito vigente).
- Android Studio, VS Code u otro editor compatible.
- Dispositivo o emulador compatible con Flutter.

### Obtener el proyecto

```bash
git clone https://github.com/mizzymi/asteria-rol.git
cd asteria-rol
flutter pub get
```

### Ejecutar en modo desarrollo

```bash
flutter doctor
flutter devices
flutter run
```

### Compilar para Android

```bash
flutter build apk --release
```

La ubicación exacta del APK se muestra en la salida de Flutter.

### Comprobaciones de calidad

```bash
dart format lib test
flutter analyze
flutter test
```

> Estos son los comandos recomendados para validar cambios. Su presencia en el README no significa que se hayan ejecutado automáticamente en cada actualización.

### Flujo de colaboración

1. Crea una rama para la mejora o corrección.
2. Implementa el cambio y comprueba sus efectos en personajes y campañas existentes.
3. Ejecuta el formateador, el analizador y las pruebas que correspondan.
4. Abre una Pull Request hacia `main` y describe las modificaciones.
5. Revisa especialmente las migraciones de datos y la compatibilidad de importaciones/exportaciones.

## 🗂️ Organización del código

```text
lib/
├── models/       # Modelos y datos del dominio
├── services/     # Almacenamiento, reglas y portabilidad
├── screens/      # Pantallas del jugador y del Máster
├── widgets/      # Componentes, editores y formularios
└── theme/        # Tema y estilos de la aplicación
```

Entre los servicios relevantes están los de almacenamiento de personajes, importación/exportación de campañas, fichas de personaje, criaturas y progresión de clases. Las pantallas separan la navegación de jugador y Máster.

## 🩺 Problemas frecuentes

**La imagen de un avatar no aparece.** Comprueba que la imagen original siga disponible al seleccionarla. Si la aplicación muestra un error, vuelve a elegirla y guarda la ficha. Tras importar un archivo, comprueba que se hayan restaurado las imágenes incluidas.

**No aparecen los PJ al exportar la campaña.** Es el comportamiento predeterminado: se excluyen las fichas de jugadores. Exporta los personajes por separado o selecciona explícitamente la sección de jugadores si la necesitas.

**Quiero trasladar una criatura a un jugador.** En la ficha de criatura del Máster, elige **Exportar como mascota**. Después entra en **Mascotas y compañeros** del personaje e importa ese archivo.

**Los cambios de Flutter no aparecen tras actualizar el código.** Ejecuta `flutter pub get` y recompila la aplicación. Algunos cambios nativos requieren una reinstalación completa y no se aplican mediante hot reload.

**`flutter analyze` muestra avisos.** Revisa la ruta y línea indicadas por el analizador. También se puede ejecutar `dart format lib test` para mantener un formato consistente.

## 📝 Novedades de la versión 1.1.31+49

Respecto a `1.1.30+48`:

- Gestión individual de NPC: importar, exportar como NPC o jugador y eliminar.
- Gestión individual de criaturas: importar, exportar como criatura o mascota y eliminar.
- Importación de criaturas como compañeros de jugadores y NPC.
- Formularios específicos para criaturas con modificación inmediata de atributos.
- Mejoras del almacenamiento persistente de avatares.
- Exportaciones de campaña sin fichas de PJ por defecto.
- Acceso a **Solo clases personalizadas** desde las opciones de exportación.
- Ajustes de mantenimiento y estilo señalados por el analizador Dart.

## 🤝 Contribuciones y estado del proyecto

El proyecto continúa en **desarrollo activo**. Las funciones y formatos pueden evolucionar, procurando mantener la compatibilidad con datos anteriores siempre que sea posible.

Si encuentras un fallo o tienes una propuesta, utiliza [GitHub Issues](https://github.com/mizzymi/asteria-rol/issues) e incluye pasos para reproducir el problema, versión utilizada y mensajes de error cuando existan.

---

**Asteria Rol** · *Crea personajes, dirige campañas y construye tus propias aventuras.*
