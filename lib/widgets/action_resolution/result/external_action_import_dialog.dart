import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/character.dart';
import '../../../models/external_action_transfer.dart';

import '../../../services/external_action_transfer_receiver_service.dart';

Future<void> showExternalActionImportDialog(
  BuildContext context, {
  required Character character,
  required Future<void> Function() onCharacterChanged,
  required Future<bool> Function(ExternalActionTransfer transfer)
  onConfirmTransfer,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) {
      return _ExternalActionImportDialog(
        character: character,
        onCharacterChanged: onCharacterChanged,
        onConfirmTransfer: onConfirmTransfer,
      );
    },
  );
}

class _ExternalActionImportDialog extends StatefulWidget {
  final Character character;

  final Future<void> Function() onCharacterChanged;

  final Future<bool> Function(ExternalActionTransfer transfer)
  onConfirmTransfer;

  const _ExternalActionImportDialog({
    required this.character,
    required this.onCharacterChanged,
    required this.onConfirmTransfer,
  });

  @override
  State<_ExternalActionImportDialog> createState() =>
      _ExternalActionImportDialogState();
}

class _ExternalActionImportDialogState
    extends State<_ExternalActionImportDialog> {
  final TextEditingController _controller = TextEditingController();

  ExternalActionTransfer? _transfer;

  String? _error;

  bool _processing = false;

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  // ===========================================================================
  // PARSE
  // ===========================================================================

  void _parse() {
    final source = _controller.text.trim();

    if (source.isEmpty) {
      setState(() {
        _transfer = null;
        _error = 'Pega primero una transferencia de Asteria.';
      });

      return;
    }

    try {
      final parsed = ExternalActionTransfer.fromJson(source);

      if (parsed.isPending && parsed.pendingOutcome == null) {
        throw StateError('La transferencia pendiente no contiene resultado.');
      }

      if (parsed.isConfirmed && parsed.confirmedOutcome == null) {
        throw StateError('La confirmación no contiene resultado.');
      }

      setState(() {
        _transfer = parsed;
        _error = null;
      });
    } catch (error) {
      setState(() {
        _transfer = null;
        _error = _cleanError(error);
      });
    }
  }

  // ===========================================================================
  // PASTE
  // ===========================================================================

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);

    if (!mounted) {
      return;
    }

    final text = data?.text?.trim();

    if (text == null || text.isEmpty) {
      setState(() {
        _error = 'El portapapeles está vacío.';
      });

      return;
    }

    _controller.text = text;

    _parse();
  }

  // ===========================================================================
  // APLICAR PENDING
  // ===========================================================================

  Future<void> _applyPending() async {
    final transfer = _transfer;

    if (transfer == null || !transfer.isPending) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      final service = ExternalActionTransferReceiverService(
        character: widget.character,
      );

      final confirmation = await service.receive(transfer);

      await widget.onCharacterChanged();

      await Clipboard.setData(ClipboardData(text: confirmation.toJson()));

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      // No hacemos nada más con context
      // después del pop.
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
        _error = _cleanError(error);
      });
    }
  }

  // ===========================================================================
  // CONFIRMAR
  // ===========================================================================

  Future<void> _confirm() async {
    final transfer = _transfer;

    if (transfer == null || !transfer.isConfirmed) {
      return;
    }

    setState(() {
      _processing = true;
      _error = null;
    });

    try {
      await widget.onConfirmTransfer(transfer);

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();

      // IMPORTANTÍSIMO:
      // no setState
      // no ScaffoldMessenger
      // no Theme.of
      // no await
      // después del pop.
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
        _error = _cleanError(error);
      });
    }
  }

  String _cleanError(Object error) {
    final text = error.toString();

    const statePrefix = 'Bad state: ';

    if (text.startsWith(statePrefix)) {
      return text.substring(statePrefix.length);
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final transfer = _transfer;

    final pending = transfer?.pendingOutcome;

    final confirmed = transfer?.confirmedOutcome;

    return AlertDialog(
      title: const Text('Importar resultado externo'),

      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _controller,
                enabled: !_processing,
                minLines: 3,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Transferencia',
                  hintText: 'Pega aquí el resultado recibido...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) {
                  if (_transfer != null || _error != null) {
                    setState(() {
                      _transfer = null;
                      _error = null;
                    });
                  }
                },
              ),

              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _paste,
                      icon: const Icon(Icons.content_paste_rounded),
                      label: const Text('Pegar'),
                    ),
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _processing ? null : _parse,
                      icon: const Icon(Icons.check_rounded),
                      label: const Text('Validar'),
                    ),
                  ),
                ],
              ),

              if (_error != null) ...[
                const SizedBox(height: 12),

                Text(
                  _error!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],

              if (pending != null) ...[
                const SizedBox(height: 18),

                _IncomingOutcomePreview(
                  transfer: transfer!,
                  character: widget.character,
                ),
              ],

              if (confirmed != null) ...[
                const SizedBox(height: 18),

                _IncomingConfirmationPreview(transfer: transfer!),
              ],
            ],
          ),
        ),
      ),

      actions: [
        TextButton(
          onPressed: _processing
              ? null
              : () {
                  Navigator.of(context).pop();
                },
          child: const Text('Cancelar'),
        ),

        if (pending != null)
          FilledButton.icon(
            onPressed: _processing ? null : _applyPending,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.playlist_add_check_rounded),
            label: Text(
              _processing ? 'Aplicando...' : 'Aplicar a mi personaje',
            ),
          ),

        if (confirmed != null)
          FilledButton.icon(
            onPressed: _processing ? null : _confirm,
            icon: _processing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_rounded),
            label: Text(
              _processing ? 'Confirmando...' : 'Procesar confirmación',
            ),
          ),
      ],
    );
  }
}

class _IncomingConfirmationPreview extends StatelessWidget {
  final ExternalActionTransfer transfer;

  const _IncomingConfirmationPreview({required this.transfer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final outcome = transfer.confirmedOutcome!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirmación externa',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'ID ${transfer.transferId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          if (outcome.damageApplied > 0) ...[
            const SizedBox(height: 12),

            _IncomingValueLine(
              icon: Icons.flash_on_rounded,
              label: 'Daño aplicado',
              value: outcome.damageApplied,
            ),
          ],

          if (outcome.healingApplied > 0) ...[
            const SizedBox(height: 8),

            _IncomingValueLine(
              icon: Icons.favorite_rounded,
              label: 'Curación aplicada',
              value: outcome.healingApplied,
            ),
          ],

          if (outcome.effectsApplied > 0) ...[
            const SizedBox(height: 8),

            _IncomingValueLine(
              icon: Icons.auto_awesome_rounded,
              label: 'Efectos aplicados',
              value: outcome.effectsApplied,
            ),
          ],

          if (outcome.killed) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.dangerous_rounded, size: 18),

                const SizedBox(width: 8),

                Text(
                  'Objetivo derrotado',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ],

          if (outcome.hasCompleteHealthInformation) ...[
            const SizedBox(height: 8),

            Text(
              'PV: '
              '${outcome.healthBefore} '
              '→ ${outcome.healthAfter}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _IncomingOutcomePreview extends StatelessWidget {
  final ExternalActionTransfer transfer;
  final Character character;

  const _IncomingOutcomePreview({
    required this.transfer,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final outcome = transfer.pendingOutcome!;

    return Container(
      padding: const EdgeInsets.all(12),

      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            outcome.effectiveTargetLabel,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            'ID ${transfer.transferId}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          if (outcome.damage > 0) ...[
            const SizedBox(height: 12),

            _IncomingValueLine(
              icon: Icons.flash_on_rounded,
              label: 'Daño',
              value: outcome.damage,
            ),
          ],

          if (outcome.healing > 0) ...[
            const SizedBox(height: 8),

            _IncomingValueLine(
              icon: Icons.favorite_rounded,
              label: 'Curación',
              value: outcome.healing,
            ),
          ],

          if (outcome.effects.isNotEmpty) ...[
            const SizedBox(height: 12),

            Text(
              'Efectos',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 6),

            for (final result in outcome.effects)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.auto_awesome_rounded, size: 17),

                    const SizedBox(width: 7),

                    Expanded(
                      child: Text(
                        result.template.name.trim().isNotEmpty
                            ? result.template.name.trim()
                            : 'Efecto',
                      ),
                    ),
                  ],
                ),
              ),
          ],

          const SizedBox(height: 12),

          Text(
            'Este resultado se aplicará únicamente a '
            '${character.name.trim().isNotEmpty ? character.name.trim() : 'tu personaje'}.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomingValueLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final int value;

  const _IncomingValueLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),

        Text(
          '$value',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}
