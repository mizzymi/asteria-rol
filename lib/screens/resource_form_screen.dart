import 'package:flutter/material.dart';

import '../models/character_resource.dart';

class ResourceFormScreen extends StatefulWidget {
  final CharacterResource? resource;

  const ResourceFormScreen({super.key, this.resource});

  @override
  State<ResourceFormScreen> createState() => _ResourceFormScreenState();
}

class _ResourceFormScreenState extends State<ResourceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController nameController;

  late final TextEditingController maxController;

  late int currentValue;

  late int colorValue;

  late IconData selectedIcon;

  bool visible = true;

  bool hasMaximum = true;

  bool restoreOnLongRest = false;

  bool get editing => widget.resource != null;

  // ===========================================================================
  // COLORES
  // ===========================================================================

  List<Color> get availableColors {
    final scheme = Theme.of(context).colorScheme;
    return [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      scheme.primaryContainer,
      scheme.secondaryContainer,
      scheme.tertiaryContainer,
      scheme.onSurfaceVariant,
    ];
  }

  // ===========================================================================
  // ICONOS
  // ===========================================================================

  static const availableIcons = [
    Icons.bolt_rounded,
    Icons.water_drop_rounded,
    Icons.local_fire_department_rounded,
    Icons.auto_awesome_rounded,
    Icons.favorite_rounded,
    Icons.psychology_rounded,
    Icons.shield_rounded,
    Icons.sports_martial_arts_rounded,
    Icons.star_rounded,
    Icons.dark_mode_rounded,
    Icons.wb_sunny_rounded,
    Icons.battery_charging_full_rounded,
  ];

  // ===========================================================================
  // INIT
  // ===========================================================================

  @override
  void initState() {
    super.initState();

    final resource = widget.resource;

    nameController = TextEditingController(text: resource?.name ?? '');

    maxController = TextEditingController(text: '${resource?.maxValue ?? 1}');

    currentValue = resource?.currentValue ?? 1;

    colorValue = resource?.colorValue ?? 0;

    selectedIcon = resource?.icon ?? availableIcons.first;

    visible = resource?.visible ?? true;

    hasMaximum = resource?.hasMaximum ?? true;

    restoreOnLongRest = resource?.restoreOnLongRest ?? false;
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveResource() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final parsedMax = int.tryParse(maxController.text) ?? 1;

    final safeMax = hasMaximum ? (parsedMax < 1 ? 1 : parsedMax) : 0;

    final safeCurrent = currentValue < 0 ? 0 : currentValue;

    final resource = CharacterResource(
      id:
          widget.resource?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      currentValue: safeCurrent,

      maxValue: safeMax,

      hasMaximum: hasMaximum,

      icon: selectedIcon,

      colorValue: colorValue,

      visible: visible,

      restoreOnLongRest: hasMaximum && restoreOnLongRest,
    );

    resource.normalize();

    Navigator.pop(context, resource);
  }

  // ===========================================================================
  // ACTUALIZAR MÁXIMO
  // ===========================================================================

  void changeMax(int delta) {
    final currentMax = int.tryParse(maxController.text) ?? 1;

    var newValue = currentMax + delta;

    if (newValue < 1) {
      newValue = 1;
    }

    setState(() {
      maxController.text = '$newValue';
    });
  }

  // ===========================================================================
  // ACTUALIZAR ACTUAL
  // ===========================================================================

  void changeCurrent(int delta) {
    setState(() {
      final next = currentValue + delta;

      currentValue = next < 0 ? 0 : next;
    });
  }

  // ===========================================================================
  // DISPOSE
  // ===========================================================================

  @override
  void dispose() {
    nameController.dispose();
    maxController.dispose();

    super.dispose();
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = availableColors[colorValue.abs() % availableColors.length];

    final max = int.tryParse(maxController.text) ?? 1;

    final progress = max <= 0 ? 0.0 : (currentValue / max).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(editing ? 'Editar recurso' : 'Nuevo recurso'),
        actions: [
          IconButton(
            onPressed: saveResource,
            icon: const Icon(Icons.check_rounded),
          ),
        ],
      ),

      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              // ===============================================================
              // NOMBRE
              // ===============================================================
              TextFormField(
                controller: nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: 'Nombre',
                  hintText: 'Maná, Ki, Energía...',
                  prefixIcon: Icon(selectedIcon, color: color),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Introduce un nombre';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              // ===============================================================
              // PREVIEW
              // ===============================================================
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(selectedIcon, color: color),
                        ),

                        const SizedBox(width: 12),

                        Expanded(
                          child: Text(
                            nameController.text.trim().isEmpty
                                ? 'Recurso'
                                : nameController.text.trim(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),

                        Text(
                          hasMaximum ? '$currentValue/$max' : '$currentValue',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),

                    if (hasMaximum) ...[
                      const SizedBox(height: 14),

                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 9,
                          color: color,
                          backgroundColor: color.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 26),

              // ===============================================================
              // VALOR MÁXIMO
              // ===============================================================
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: !hasMaximum,
                title: const Text('Sin máximo'),
                subtitle: const Text(
                  'El recurso puede aumentar indefinidamente.',
                ),
                secondary: const Icon(Icons.all_inclusive_rounded),
                onChanged: (value) {
                  setState(() {
                    hasMaximum = !value;

                    if (!hasMaximum) {
                      restoreOnLongRest = false;
                    }

                    if (hasMaximum) {
                      var max = int.tryParse(maxController.text) ?? 1;

                      if (max < 1) {
                        max = 1;
                        maxController.text = '1';
                      }
                    }
                  });
                },
              ),

              if (hasMaximum) ...[
                const SizedBox(height: 12),

                Text(
                  'Valor máximo',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () {
                        changeMax(-1);
                      },
                      icon: const Icon(Icons.remove_rounded),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: TextFormField(
                        controller: maxController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                        decoration: const InputDecoration(labelText: 'Máximo'),
                        onChanged: (_) {
                          setState(() {});
                        },
                      ),
                    ),

                    const SizedBox(width: 12),

                    IconButton.filledTonal(
                      onPressed: () {
                        changeMax(1);
                      },
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ],
                ),
              ],

              if (hasMaximum) ...[
                const SizedBox(height: 18),

                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: restoreOnLongRest,
                  title: const Text('Recuperar al máximo en descanso largo'),
                  subtitle: const Text(
                    'Si está activado, este recurso se rellenará al completar un descanso largo. Por defecto no se recupera.',
                  ),
                  secondary: const Icon(Icons.bedtime_rounded),
                  onChanged: (value) {
                    setState(() {
                      restoreOnLongRest = value;
                    });
                  },
                ),
              ],

              const SizedBox(height: 26),

              // ===============================================================
              // VALOR ACTUAL
              // ===============================================================
              Text(
                'Valor actual',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: currentValue > 0
                        ? () {
                            changeCurrent(-1);
                          }
                        : null,
                    icon: const Icon(Icons.remove_rounded),
                  ),

                  Expanded(
                    child: Text(
                      '$currentValue',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ),

                  IconButton.filledTonal(
                    onPressed: () {
                      changeCurrent(1);
                    },
                    icon: const Icon(Icons.add_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // COLOR
              // ===============================================================
              Text(
                'Color',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableColors.asMap().entries.map((entry) {
                  final index = entry.key;
                  final option = entry.value;
                  final selected = index == colorValue.abs() % availableColors.length;

                  return InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      setState(() {
                        colorValue = index;
                      });
                    },
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: option,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.onSurface
                              : Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onInverseSurface)
                          : null,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 28),

              // ===============================================================
              // ICONO
              // ===============================================================
              Text(
                'Icono',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: availableIcons.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 6,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemBuilder: (context, index) {
                  final icon = availableIcons[index];

                  final selected = icon.codePoint == selectedIcon.codePoint;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      setState(() {
                        selectedIcon = icon;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: selected
                            ? color.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHighest
                                  .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected ? color : Theme.of(context).colorScheme.surface.withValues(alpha: 0),
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: selected
                            ? color
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ===============================================================
              // VISIBLE
              // ===============================================================
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: visible,
                title: const Text('Mostrar recurso'),
                subtitle: const Text(
                  'Si está desactivado seguirá guardado, pero no aparecerá en la lista.',
                ),
                onChanged: (value) {
                  setState(() {
                    visible = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // ===============================================================
              // GUARDAR
              // ===============================================================
              FilledButton.icon(
                onPressed: saveResource,
                icon: const Icon(Icons.save_rounded),
                label: Text(editing ? 'Guardar cambios' : 'Crear recurso'),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
