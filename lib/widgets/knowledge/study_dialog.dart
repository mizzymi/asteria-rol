import 'package:flutter/material.dart';

import '../../models/action_dice_mode.dart';
import '../../models/character.dart';
import '../../models/knowledge_definition.dart';
import '../../services/knowledge_service.dart';

Future<StudyRollResult?> showStudyDialog(
  BuildContext context, {
  required Character character,
  required KnowledgeDefinition definition,
}) {
  return showDialog<StudyRollResult>(
    context: context,
    builder: (dialogContext) => _StudyDialogContent(
      character: character,
      definition: definition,
    ),
  );
}

class _StudyDialogContent extends StatefulWidget {
  final Character character;
  final KnowledgeDefinition definition;

  const _StudyDialogContent({
    required this.character,
    required this.definition,
  });

  @override
  State<_StudyDialogContent> createState() => _StudyDialogContentState();
}

class _StudyDialogContentState extends State<_StudyDialogContent> {
  RestStudyType restType = RestStudyType.shortRest;
  ActionDiceMode diceMode = ActionDiceMode.physical;

  late KnowledgeCheckOption selectedCheck;
  final TextEditingController roll1Controller = TextEditingController();
  final TextEditingController roll2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    selectedCheck = widget.definition.effectiveCheckOptions.first;
  }

  @override
  void dispose() {
    roll1Controller.dispose();
    roll2Controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.character.getKnowledge(widget.definition.id);
    final current = entry?.currentProgress ?? 0;
    final total = widget.definition.effectiveRequiredProgress;
    final currentCircle = widget.definition.circleAtProgress(current);
    final currentDc = widget.definition.dcForProgress(current);
    final modifier = const KnowledgeService().modifierForCheck(
      widget.character,
      selectedCheck,
    );
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_stories_rounded),
          const SizedBox(width: 8),
          Expanded(child: Text('Estudiar: ${widget.definition.name}')),
        ],
      ),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.definition.rarity.isNotEmpty ||
                  widget.definition.difficulty.isNotEmpty ||
                  widget.definition.levelLabel.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (widget.definition.rarity.isNotEmpty)
                      Chip(label: Text(widget.definition.rarity)),
                    if (widget.definition.difficulty.isNotEmpty)
                      Chip(label: Text(widget.definition.difficulty)),
                    if (widget.definition.levelLabel.isNotEmpty)
                      Chip(label: Text(widget.definition.levelLabel)),
                  ],
                ),
              Text(
                'Progreso: $current / $total',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: total > 0 ? (current / total).clamp(0.0, 1.0) : 0,
              ),
              if (currentCircle != null) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Círculo ${current + 1} · ${currentCircle.title}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('CD $currentDc'),
                        if (currentCircle.description.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(currentCircle.description),
                        ],
                        if (currentCircle.rewardDescription.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Al superarlo: ${currentCircle.rewardDescription}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              if (widget.definition.studyRequirement.isNotEmpty) ...[
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.rule_rounded),
                  title: const Text('Requisito de estudio'),
                  subtitle: Text(widget.definition.studyRequirement),
                ),
              ],
              const SizedBox(height: 14),
              Text(
                'Tirada de aprendizaje',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<KnowledgeCheckOption>(
                initialValue: selectedCheck,
                decoration: InputDecoration(
                  labelText: 'Usar',
                  helperText: 'Modificador actual: $modifierText',
                ),
                items: widget.definition.effectiveCheckOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => selectedCheck = value);
                },
              ),
              const SizedBox(height: 14),
              const Text('Modo de tirada:', style: TextStyle(fontWeight: FontWeight.bold)),
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
                onSelectionChanged: (value) => setState(() => diceMode = value.first),
              ),
              const SizedBox(height: 14),
              const Text('Tipo de descanso:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              SegmentedButton<RestStudyType>(
                segments: const [
                  ButtonSegment(value: RestStudyType.shortRest, label: Text('Corto (1 d20)')),
                  ButtonSegment(value: RestStudyType.longRest, label: Text('Largo (2 d20)')),
                ],
                selected: {restType},
                onSelectionChanged: (value) => setState(() => restType = value.first),
              ),
              if (diceMode == ActionDiceMode.physical) ...[
                const SizedBox(height: 14),
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
            diceMode == ActionDiceMode.physical ? 'Registrar tirada' : 'Tirar estudio',
          ),
          onPressed: () async {
            final rolls = <int>[];
            if (diceMode == ActionDiceMode.physical) {
              final r1 = int.tryParse(roll1Controller.text.trim());
              if (r1 != null) rolls.add(r1);
              if (restType == RestStudyType.longRest) {
                final r2 = int.tryParse(roll2Controller.text.trim());
                if (r2 != null) rolls.add(r2);
              }
            }

            final result = await const KnowledgeService().performStudyRoll(
              character: widget.character,
              definition: widget.definition,
              restType: restType,
              physicalRolls: rolls.isNotEmpty ? rolls : null,
              checkOption: selectedCheck,
            );

            if (!context.mounted) return;
            Navigator.pop(context, result);
          },
        ),
      ],
    );
  }
}
