import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/campaign.dart';
import '../services/campaign_image_service.dart';
import '../services/campaign_storage_service.dart';

class CampaignFormScreen extends StatefulWidget {
  final Campaign? campaign;

  const CampaignFormScreen({super.key, this.campaign});

  @override
  State<CampaignFormScreen> createState() => _CampaignFormScreenState();
}

class _CampaignFormScreenState extends State<CampaignFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  String? _imagePath;
  String? _pendingImagePath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.campaign?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.campaign?.description ?? '',
    );
    _imagePath = widget.campaign?.imagePath;
  }

  Future<void> _pickImage() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 88,
    );
    if (image == null || !mounted) return;
    setState(() {
      _pendingImagePath = image.path;
      _imagePath = image.path;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id =
        widget.campaign?.id ??
        'campaign_${DateTime.now().microsecondsSinceEpoch}';
    var finalImagePath = widget.campaign?.imagePath;
    if (_pendingImagePath != null) {
      finalImagePath = await CampaignImageService.saveImage(
        campaignId: id,
        sourcePath: _pendingImagePath!,
      );
    } else if (_imagePath == null && widget.campaign?.imagePath != null) {
      await CampaignImageService.deleteImage(widget.campaign?.imagePath);
      finalImagePath = null;
    }

    final campaign = Campaign(
      id: id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      imagePath: finalImagePath,
      createdAt: widget.campaign?.createdAt,
      shops: widget.campaign?.shops,
      missions: widget.campaign?.missions,
    );
    await CampaignStorageService.saveCampaign(campaign);
    if (!mounted) return;
    Navigator.pop(context, campaign);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final image = _pendingImagePath ?? _imagePath;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.campaign == null ? 'Nueva campaña' : 'Editar campaña',
        ),
        actions: [
          IconButton(onPressed: _save, icon: const Icon(Icons.check_rounded)),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(18),
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(26),
                child: Material(
                  color: colors.primaryContainer,
                  child: InkWell(
                    onTap: _pickImage,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (image != null)
                          Image.file(File(image), fit: BoxFit.cover)
                        else
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  colors.primaryContainer,
                                  colors.secondaryContainer,
                                ],
                              ),
                            ),
                            child: Icon(
                              Icons.landscape_rounded,
                              size: 72,
                              color: colors.primary,
                            ),
                          ),
                        Positioned(
                          right: 12,
                          bottom: 12,
                          child: FilledButton.tonalIcon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.photo_library_rounded),
                            label: Text(
                              image == null
                                  ? 'Añadir portada'
                                  : 'Cambiar portada',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (image != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _pendingImagePath = null;
                    _imagePath = null;
                  }),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Quitar portada'),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre de la campaña',
                prefixIcon: Icon(Icons.auto_stories_rounded),
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ponle un nombre a la campaña'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Descripción',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: Text(
                widget.campaign == null ? 'Crear campaña' : 'Guardar cambios',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
