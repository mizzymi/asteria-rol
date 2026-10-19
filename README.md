# ✨ Asteria Rol

**Asteria Rol** es una aplicación de rol desarrollada con **Flutter** para jugadores y Másters. Reúne fichas de personaje, campañas, combate, habilidades, pasivas, inventario y criaturas en un mismo lugar, con herramientas de creación y contenido personalizado.

**Versión actual:** `1.1.30+48`

## 🎲 Funciones principales

### 👤 Personajes y progresión
- Fichas con atributos, clases y multiclase, competencias, salvaciones, puntos de vida, recursos, contadores, notas e historial de tiradas.
- Clases personalizadas por campaña con recompensas automáticas y elecciones al subir de nivel.
- Elecciones múltiples sobre un mismo conjunto de habilidades y pasivas.
- Opciones únicas y mejoras acumulables (por ejemplo, bonos repetibles al daño y al golpeo).
- Vista previa de habilidades y pasivas antes de aprenderlas y recuperación de elecciones pendientes.

### ⚔️ Combate y reglas
- Armas, armaduras, consumibles y objetos personalizados.
- Habilidades con ataques, daño, curación, mitigación, salvaciones y efectos vinculados.
- Tiradas digitales o físicas, con elección independiente del modo de ataque y daño/efectos.
- Pasivas con bonificaciones, cargas, recursos, activadores, críticos y efectos.
- Críticos potenciados configurables mediante fórmulas.
- Tipos de daño incorporados y personalizados, resistencias acumulables y mitigación preventiva.

### 📚 Organización y contenido
- Biblioteca de objetos y contenido reutilizable.
- Carpetas para habilidades, pasivas y objetos.
- Saberes y libros de aprendizaje organizados por círculos.
- Tiendas, misiones, economía y herramientas de gestión de campañas.

### 🏰 Herramientas del Máster
- Gestión de campañas y personajes jugadores.
- **NPC:** crear, importar, exportar individualmente y eliminar con confirmación.
- **Criaturas:** crear, importar, exportar y eliminar con confirmación.
- Exportación de criaturas en dos modalidades: **criatura del Máster** o **mascota de jugador/NPC**.
- Formularios de criatura diferenciados de los de mascota, con actualización de modificadores de atributos al escribir.
- Exportación de campañas por secciones para compartir contenido de forma selectiva.

### 🐾 Mascotas y compañeros
- Fichas de mascotas con atributos, vida, defensa, ataques, habilidades, pasivas y efectos.
- Importación de criaturas exportadas desde la sección del Máster.
- Posibilidad de reutilizar una criatura como compañero de un jugador o NPC.

## 📦 Importación y exportación

Asteria dispone de formatos portables para compartir contenido entre dispositivos:

| Contenido | Operaciones |
| --- | --- |
| Personajes y NPC | Importar y exportar fichas `.asteria` |
| Criaturas y mascotas | Importar y exportar archivos `.asteria-creature` |
| Clases personalizadas | Importar y exportar definiciones de clase |
| Campañas | Importación/exportación completa o por secciones |
| Tiendas y objetos | Importación/exportación de contenido reutilizable |

Los archivos de criatura incluyen sus datos y las imágenes locales disponibles. Al importar una criatura o mascota se genera una copia con un identificador nuevo para evitar conflictos.

## 🛡️ Reglas de daño y resistencias

Cada componente de daño puede indicar un tipo, como `fuego`, `frío`, `radiante`, `cortante` o uno personalizado. Las resistencias de las pasivas se aplican cuando el tipo coincide.

| Resistencia | Puntos | Daño recibido |
| --- | ---: | ---: |
| Menor | 1 | 75 % |
| Normal | 2 | 50 % |
| Mayor | 4 | 25 % |
| Inmunidad | 8 | 0 % |

Equivalencias: **2 menores = 1 normal**, **2 normales = 1 mayor** y **2 mayores = inmunidad**.

Las pasivas también pueden añadir bonos a las tiradas de salvación y conceder ventaja o desventaja. Si coinciden ambas condiciones para la misma salvación, se cancelan.

## 🛠️ Desarrollo

**Requisitos**
- Flutter con una versión de Dart compatible con `^3.12.1`.
- Dependencias descritas en `pubspec.yaml`.

**Instalación y ejecución**

```bash
git clone https://github.com/mizzymi/asteria-rol.git
cd asteria-rol
flutter pub get
flutter run
```

**Comprobaciones recomendadas antes de una Pull Request**

```bash
dart format lib test
flutter analyze
flutter test
```

> Las comprobaciones anteriores son comandos recomendados; no implican que todas las pruebas se hayan ejecutado en cada cambio.

## 📁 Estructura del proyecto

| Ruta | Contenido |
| --- | --- |
| `lib/models/` | Modelos de personajes, criaturas, habilidades y reglas |
| `lib/services/` | Persistencia, cálculo y servicios de importación/exportación |
| `lib/screens/` | Pantallas de jugador y Máster |
| `lib/widgets/` | Componentes y formularios reutilizables |
| `lib/theme/` | Tema visual de la aplicación |

## 🚧 Estado del proyecto

Asteria Rol continúa en **desarrollo activo**. Las nuevas funciones procuran conservar la compatibilidad con los datos y formatos anteriores. Si encuentras un error o quieres proponer una mejora, puedes abrir una incidencia en [GitHub Issues](https://github.com/mizzymi/asteria-rol/issues).

---
*Hecho para construir aventuras, personajes y mundos propios.*
