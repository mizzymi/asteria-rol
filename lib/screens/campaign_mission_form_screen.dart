import 'package:flutter/material.dart';
import '../models/campaign_mission.dart';

class CampaignMissionFormScreen extends StatefulWidget {
  final CampaignMission? mission;
  const CampaignMissionFormScreen({super.key, this.mission});
  @override
  State<CampaignMissionFormScreen> createState() =>
      _CampaignMissionFormScreenState();
}

class _CampaignMissionFormScreenState extends State<CampaignMissionFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.mission?.title ?? '');
    _description = TextEditingController(
      text: widget.mission?.description ?? '',
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    if (_title.text.trim().isEmpty) return;
    Navigator.pop(
      context,
      CampaignMission(
        id:
            widget.mission?.id ??
            'mission_${DateTime.now().microsecondsSinceEpoch}',
        title: _title.text.trim(),
        description: _description.text.trim(),
        completed: widget.mission?.completed ?? false,
        acceptedCharacterIds: List<String>.from(
          widget.mission?.acceptedCharacterIds ?? const [],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.mission == null ? 'Nueva misión' : 'Editar misión'),
      actions: [
        IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.all(18),
      children: [
        TextField(
          controller: _title,
          decoration: const InputDecoration(labelText: 'Nombre de la misión'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _description,
          maxLines: 6,
          decoration: const InputDecoration(labelText: 'Descripción'),
        ),
        const SizedBox(height: 24),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.check_rounded),
          label: const Text('Guardar misión'),
        ),
      ],
    ),
  );
}
