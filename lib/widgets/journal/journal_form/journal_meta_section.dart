import 'package:flutter/material.dart';

import '../../common/app_card.dart';
import '../../common/section_header.dart';

class JournalMetaSection extends StatelessWidget {
  final TextEditingController dateController;

  final TextEditingController sessionController;

  final bool important;

  final ValueChanged<bool> onImportantChanged;

  const JournalMetaSection({
    super.key,
    required this.dateController,
    required this.sessionController,
    required this.important,
    required this.onImportantChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SectionHeader(
          icon: Icons.event_rounded,
          title: 'Contexto',
          subtitle: 'Fecha, sesión e importancia',
        ),

        const SizedBox(height: 12),

        AppCard(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: dateController,
                      decoration: const InputDecoration(
                        labelText: 'Fecha',
                        hintText: 'Día 12',
                        prefixIcon: Icon(Icons.calendar_today_rounded),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: TextFormField(
                      controller: sessionController,
                      decoration: const InputDecoration(
                        labelText: 'Sesión',
                        hintText: 'Sesión 4',
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: important,
                title: const Text('Entrada importante'),
                subtitle: const Text('Se destacará en el diario'),
                secondary: const Icon(Icons.star_rounded),
                onChanged: onImportantChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
