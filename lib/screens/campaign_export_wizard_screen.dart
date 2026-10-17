import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../services/campaign_import_export_service.dart';

/// Prepara y comparte cada sección de forma independiente.
class CampaignExportWizardScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignExportWizardScreen({super.key, required this.campaign});

  @override
  State<CampaignExportWizardScreen> createState() => _CampaignExportWizardScreenState();
}

class _CampaignExportWizardScreenState extends State<CampaignExportWizardScreen> {
  static const sections = <(String, String, IconData)>[
    ('base', 'Datos de campaña', Icons.auto_stories_rounded),
    ('shops', 'Tiendas', Icons.storefront_rounded),
    ('creatures', 'Criaturas', Icons.pets_rounded),
    ('npcs', 'NPC', Icons.people_rounded),
    ('missions', 'Misiones', Icons.flag_rounded),
    ('classes', 'Clases', Icons.school_rounded),
    ('players', 'Personajes jugadores', Icons.person_rounded),
  ];

  int index = 0;
  bool busy = false;
  bool shared = false;
  String? errorMessage;

  Future<void> _shareCurrent() async {
    if (busy) return;
    setState(() { busy = true; errorMessage = null; });
    try {
      await CampaignImportExportService.shareCampaignPart(
        widget.campaign, sections[index].$1);
      if (!mounted) return;
      setState(() { shared = true; });
    } catch (error) {
      if (!mounted) return;
      setState(() { errorMessage = error.toString(); });
    } finally {
      if (mounted) setState(() { busy = false; });
    }
  }

  Future<void> _next() async {
    if (busy || !shared) return;
    // El usuario confirma que ha guardado o enviado el archivo antes de eliminarlo.
    setState(() => busy = true);
    try {
      await CampaignImportExportService.deleteExportPart(
        widget.campaign, sections[index].$1);
      if (!mounted) return;
      setState(() {
        index++;
        shared = false;
        errorMessage = null;
      });
    } catch (error) {
      if (mounted) setState(() => errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final completed = index >= sections.length;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar toda la campaña')),
      body: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LinearProgressIndicator(value: index / sections.length),
            const SizedBox(height: 20),
            Text(completed ? 'Exportación finalizada'
                : 'Sección ${index + 1} de ${sections.length}',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(completed
                ? 'Se han compartido todas las secciones. Impórtalas en la misma campaña.'
                : 'Se crea un solo archivo cada vez. Tras guardarlo o enviarlo, confirma para liberar espacio y continuar.'),
            const SizedBox(height: 24),
            if (!completed)
              Card(
                child: ListTile(
                  leading: Icon(sections[index].$3, color: scheme.primary, size: 32),
                  title: Text(sections[index].$2),
                  subtitle: Text(shared ? 'Archivo preparado. Confirma que lo has guardado.'
                      : 'Pendiente de exportar'),
                ),
              ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(errorMessage!, style: TextStyle(color: scheme.error)),
            const Spacer(),
            if (completed)
              FilledButton(onPressed: () => Navigator.pop(context),
                child: const Text('Terminar'))
            else ...[
              FilledButton.icon(
                onPressed: busy ? null : (shared ? _next : _shareCurrent),
                icon: Icon(shared ? Icons.arrow_forward_rounded : Icons.ios_share_rounded),
                label: Text(busy ? 'Preparando...' :
                    shared ? 'Ya lo he guardado · Siguiente' : 'Compartir sección'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(context),
                child: const Text('Salir por ahora'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
