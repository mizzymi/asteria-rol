import 'package:flutter/material.dart';

import '../../models/skill.dart';
import '../../models/character.dart';
import '../../models/knowledge_definition.dart';
import '../../models/spell_definition.dart';
import '../../models/action_dice_mode.dart';
import '../../services/knowledge_service.dart';

Future<StudyRollResult?> showStudyDialog(
  BuildContext context, {
  required Character character,
  required KnowledgeDefinition definition,
  List<SpellDefinition> spellCatalog = const [],
}) {
  return showDialog<StudyRollResult>(
    context: context,
    builder: (dialogContext) => _StudyDialogContent(
      character: character,
      definition: definition,
      spellCatalog: spellCatalog,
    ),
  );
}

class _StudyDialogContent extends StatefulWidget {
  final Character character;
  final KnowledgeDefinition definition;
  final List<SpellDefinition> spellCatalog;

  const _StudyDialogContent({
    required this.character,
    required this.definition,
    required this.spellCatalog,
  });

  @override
  State<_StudyDialogContent> createState() => _StudyDialogContentState();
}

class _StudyDialogContentState extends State<_StudyDialogContent> {
  RestStudyType restType = RestStudyType.shortRest;
  ActionDiceMode diceMode = ActionDiceMode.physical;

  late TextEditingController dcController;
  final TextEditingController roll1Controller = TextEditingController();
  final TextEditingController roll2Controller = TextEditingController();

  final physicalValues = <int>[];

  @override
  void initState() {
    super.initState();
    dcController = TextEditingController(text: '${widget.definition.studyDc}');
  }

  @override
  void dispose() {
    dcController.dispose();
    roll1Controller.dispose();
    roll2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.character.getKnowledge(widget.definition.id);
    final currentSuccesses = entry?.currentProgress ?? 0;
    final totalNeeded = widget.definition.requiredProgress;
    final intModifier = widget.character.abilityModifier(
      AbilityType.intelligence,
    );
    final intModText = intModifier >= 0 ? '+$intModifier' : '$intModifier';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_stories_rounded),
          const SizedBox(width: 8),
          Expanded(child: Text('Estudiar: ${widget.definition.name}')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progreso: $currentSuccesses / $totalNeeded éxitos',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: totalNeeded > 0
                  ? (currentSuccesses / totalNeeded).clamp(0.0, 1.0)
                  : 0,
            ),
            const SizedBox(height: 16),

            const Text(
              'Modo de tirada:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SegmentedButton<ActionDiceMode>(
              segments: const [
                ButtonSegment(
                  value: ActionDiceMode.physical,
                  icon: Icon(Icons.front_hand_rounded),
                  label: Text('Físico'),
                ),
                ButtonSegment(
                  value: ActionDiceMode.digital,
                  icon: Icon(Icons.casino_rounded),
                  label: Text('Digital'),
                ),
              ],
              selected: {diceMode},
              onSelectionChanged: (val) => setState(() => diceMode = val.first),
            ),
            const SizedBox(height: 14),

            const Text(
              'Tipo de descanso:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            SegmentedButton<RestStudyType>(
              segments: const [
                ButtonSegment(
                  value: RestStudyType.shortRest,
                  label: Text('Corto (1 d20)'),
                ),
                ButtonSegment(
                  value: RestStudyType.longRest,
                  label: Text('Largo (2 d20)'),
                ),
              ],
              selected: {restType},
              onSelectionChanged: (val) => setState(() => restType = val.first),
            ),
            const SizedBox(height: 14),

            TextFormField(
              controller: dcController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Dificultad (CD decidida por el Máster)',
                prefixIcon: const Icon(Icons.security_rounded),
                helperText: 'Modificador de Inteligencia: $intModText',
              ),
            ),

            if (diceMode == ActionDiceMode.physical) ...[
              const SizedBox(height: 14),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Resultado del d20 en mesa (1-20):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: roll1Controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Tirada d20 (intento 1)',
                  prefixIcon: Icon(Icons.casino_outlined),
                ),
              ),
              if (restType == RestStudyType.longRest) ...[
                const SizedBox(height: 10),
                TextFormField(
                  controller: roll2Controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Tirada d20 (intento 2)',
                    prefixIcon: Icon(Icons.casino_outlined),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          icon: Icon(
            diceMode == ActionDiceMode.physical
                ? Icons.check_circle_rounded
                : Icons.casino_rounded,
          ),
          label: Text(
            diceMode == ActionDiceMode.physical
                ? 'Registrar Tirada'
                : 'Tirar Estudio',
          ),
          onPressed: () async {
            // Recogemos la CD personalizada introducida
            final customDc = int.tryParse(dcController.text.trim());

            // Si estamos en modo físico, leemos los valores de los campos de texto
            final rolls = <int>[];
            if (diceMode == ActionDiceMode.physical) {
              final r1 = int.tryParse(roll1Controller.text.trim());
              if (r1 != null) {
                rolls.add(r1);
              }
              if (restType == RestStudyType.longRest) {
                final r2 = int.tryParse(roll2Controller.text.trim());
                if (r2 != null) {
                  rolls.add(r2);
                }
              }
            }

            // Ejecutamos el servicio pasándole los dados físicos y la CD
            final result = await const KnowledgeService().performStudyRoll(
              character: widget.character,
              definition: widget.definition,
              restType: restType,
              customDc: customDc,
              physicalRolls: rolls.isNotEmpty ? rolls : null,
            );

            if (!context.mounted) return;
            Navigator.pop(context, result);
          },
        ),
      ],
    );
  }
}
