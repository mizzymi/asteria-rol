# Asteria Rol

Asteria Rol es una aplicación Flutter para gestionar personajes, campañas y
combate de rol desde una única ficha digital. Está pensada para jugar tanto
como jugador como desde la vista de Máster, manteniendo reglas, recursos,
objetos, habilidades, pasivas y efectos dentro del propio personaje.

## Funciones principales

- Fichas de personaje con clases, atributos, habilidades, salvaciones, vida,
  recursos, contadores y notas.
- Armas, armaduras, consumibles y objetos personalizados.
- Biblioteca de objetos reutilizable entre personajes.
- Carpetas para organizar habilidades, pasivas y objetos.
- Habilidades con ataque, daño, curación, mitigación, salvaciones y efectos.
- Tiradas digitales o físicas, pudiendo elegir por separado el modo del ataque
  y el de daño/efectos.
- Pasivas con modificadores, triggers, cargas, recursos, críticos y efectos
  vinculados.
- Críticos potenciados configurables mediante fórmulas.
- Saberes y libros de aprendizaje por círculos.
- Campañas, tiendas y herramientas de Máster.
- Importación y exportación portable de personajes, campañas, tiendas y
  objetos.

## Reglas de daño y resistencias

Cada componente de daño puede indicar su tipo, por ejemplo `fuego`,
`frío`, `radiante`, `cortante` o cualquier tipo personalizado. Las
resistencias de las pasivas se aplican automáticamente cuando el tipo coincide.

Los niveles de resistencia se apilan por tipo:

| Nivel | Puntos | Daño recibido |
| --- | ---: | ---: |
| Menor | 1 | 75 % |
| Normal | 2 | 50 % |
| Mayor | 4 | 25 % |
| Inmunidad | 8 | 0 % |

Por equivalencia, **2 menores = 1 normal**, **2 normales = 1 mayor** y
**2 mayores = inmunidad**.

## Salvaciones

Las pasivas pueden añadir un bono numérico a una salvación y también conceder
**ventaja** o **desventaja** a una característica concreta. Si el personaje
recibe ventaja y desventaja a la vez para la misma salvación, ambas se
cancelan.

Las habilidades pueden pedir una salvación aunque no causen daño ni curación,
por ejemplo para aplicar un estado o un efecto vinculado.

## Desarrollo

Requisitos:

- Flutter compatible con Dart `^3.12.1`.
- Dependencias declaradas en `pubspec.yaml`.

Instalación:

```bash
flutter pub get
flutter run
```

Antes de subir cambios:

```bash
dart format lib test
flutter analyze
flutter test
```

## Estructura

- `lib/models/`: modelos y reglas de dominio.
- `lib/services/`: resolución de acciones, almacenamiento e
  importación/exportación.
- `lib/screens/`: pantallas principales.
- `lib/widgets/`: componentes y formularios reutilizables.
- `lib/theme/`: tema y utilidades de accesibilidad visual.

## Estado del proyecto

El proyecto está en desarrollo activo. Los formatos de importación/exportación
mantienen compatibilidad con datos anteriores siempre que sea posible.
