import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/campaign_mission.dart';
import '../models/character.dart';
import '../services/campaign_storage_service.dart';
import '../services/character_storage_service.dart';
import 'campaign_mission_form_screen.dart';

class CampaignMissionDetailScreen extends StatefulWidget {
  final Campaign campaign;
  final CampaignMission mission;
  const CampaignMissionDetailScreen({super.key, required this.campaign, required this.mission});
  @override
  State<CampaignMissionDetailScreen> createState() => _CampaignMissionDetailScreenState();
}

class _CampaignMissionDetailScreenState extends State<CampaignMissionDetailScreen> {
  late Campaign campaign;
  late CampaignMission mission;
  late List<Character> characters;
  @override
  void initState() { super.initState(); campaign = widget.campaign; mission = widget.mission; _reload(); }
  void _reload() {
    campaign = CampaignStorageService.getCampaign(campaign.id) ?? campaign;
    mission = campaign.missions.firstWhere((m) => m.id == mission.id, orElse: () => mission);
    characters = CharacterStorageService.getCharacters().where((c) => c.campaignId == campaign.id).toList();
    if (mounted) setState(() {});
  }
  Future<void> _save() async { await CampaignStorageService.saveCampaign(campaign); if (mounted) _reload(); }
  Future<void> _edit() async {
    final edited = await Navigator.push<CampaignMission>(context, MaterialPageRoute(builder: (_) => CampaignMissionFormScreen(mission: mission)));
    if (edited == null) return;
    final i = campaign.missions.indexWhere((m) => m.id == mission.id);
    if (i >= 0) campaign.missions[i] = edited;
    mission = edited;
    await _save();
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(mission.title), actions: [IconButton(onPressed: _edit, icon: const Icon(Icons.edit_rounded))]),
    body: ListView(padding: const EdgeInsets.all(18), children: [
      if (mission.description.isNotEmpty) Card(child: Padding(padding: const EdgeInsets.all(18), child: Text(mission.description))),
      SwitchListTile(
        title: const Text('Misión completada'),
        value: mission.completed,
        onChanged: (v) { setState(() => mission.completed = v); _save(); },
      ),
      const SizedBox(height: 18),
      Text('Personajes de esta campaña', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6),
      ...characters.map((c) => CheckboxListTile(
        value: mission.acceptedCharacterIds.contains(c.id),
        title: Text(c.name),
        subtitle: Text(mission.acceptedCharacterIds.contains(c.id) ? 'Misión aceptada' : 'No aceptada'),
        onChanged: (value) {
          setState(() {
            if (value == true) { if (!mission.acceptedCharacterIds.contains(c.id)) mission.acceptedCharacterIds.add(c.id); }
            else { mission.acceptedCharacterIds.remove(c.id); }
          });
          _save();
        },
      )),
    ]),
  );
}
