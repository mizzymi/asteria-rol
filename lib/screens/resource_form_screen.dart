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

  bool get editing => widget.resource != null;

  // ===========================================================================
  // COLORES
  // ===========================================================================

  static const availableColors = [
    Color(0xFF8B5CF6),
    Color(0xFF4D8FE8),
    Color(0xFFE84A8A),
    Color(0xFFF29E4C),
    Color(0xFF55B96B),
    Color(0xFF42B8C8),
    Color(0xFFE45AA7),
    Color(0xFFE85D5D),
  ];

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

    colorValue = resource?.colorValue ?? availableColors.first.value;

    selectedIcon = resource?.icon ?? availableIcons.first;

    visible = resource?.visible ?? true;
  }

  // ===========================================================================
  // GUARDAR
  // ===========================================================================

  void saveResource() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final max = int.tryParse(maxController.text) ?? 1;

    final safeMax = max < 1 ? 1 : max;

    final safeCurrent = currentValue.clamp(0, safeMax);

    final resource = CharacterResource(
      id:
          widget.resource?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),

      name: nameController.text.trim(),

      currentValue: safeCurrent,

      maxValue: safeMax,

      icon: selectedIcon,

      colorValue: colorValue,

      visible: visible,
    );

    resource.normalize();

    Navigator.pop(context, resource);
  }

  // ===========================================================================
  // ACTUALIZAR MÁXIMO
  // ===========================================================================

  void changeMax(int delta) {
    final currentMax = int.tryParse(maxController.text) ?? 1;

    final newValue = (currentMax + delta).clamp(1, 999);

    setState(() {
      maxController.text = '$newValue';

      if (currentValue > newValue) {
        currentValue = newValue;
      }
    });
  }

  // ===========================================================================
  // ACTUALIZAR ACTUAL
  // ===========================================================================

  void changeCurrent(int delta) {
    final max = int.tryParse(maxController.text) ?? 1;

    setState(() {
      currentValue = (currentValue + delta).clamp(0, max < 1 ? 1 : max);
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

    final color = Color(colorValue);

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
                          '$currentValue/$max',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                      ],
                    ),

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
                ),
              ),

              const SizedBox(height: 26),

              // ===============================================================
              // VALOR MÁXIMO
              // ===============================================================
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
                        setState(() {
                          final currentMax =
                              int.tryParse(maxController.text) ?? 1;

                          if (currentValue > currentMax) {
                            currentValue = currentMax;
                          }
                        });
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
                    onPressed: currentValue < max
                        ? () {
                            changeCurrent(1);
                          }
                        : null,
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
                children: availableColors.map((option) {
                  final selected = option.value == colorValue;

                  return InkWell(
                    borderRadius: BorderRadius.circular(50),
                    onTap: () {
                      setState(() {
                        colorValue = option.value;
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
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded, color: Colors.white)
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
                          color: selected ? color : Colors.transparent,
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
