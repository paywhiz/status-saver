import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../services/permissions.dart';
import '../../settings/settings_controller.dart';
import 'step_scaffold.dart';

class DestinationStep extends StatelessWidget {
  const DestinationStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return StepScaffold(
      icon: Icons.save_alt_rounded,
      title: 'Where should saves go?',
      body:
          'Pick a default for the Save button. You can change this in Settings, '
          'or long-press Save to override for a single item.',
      primary: FilledButton(
        onPressed: onNext,
        child: const Text('Continue'),
      ),
      children: [
        _Choice(
          icon: Icons.photo_library_outlined,
          title: 'Gallery',
          body:
              'Saves appear in your Photos / Gallery in a "Status Saver" album, '
              'can be shared anywhere, and stay on your phone if you uninstall.',
          selected: s.saveDestination == SaveDestination.gallery,
          onTap: () => _pickGallery(context, s),
        ),
        const SizedBox(height: 12),
        _Choice(
          icon: Icons.bookmark_outline,
          title: 'In-App',
          body:
              'Saves live privately inside Status Saver — they don\'t clutter '
              'your gallery and are removed if you uninstall the app.',
          selected: s.saveDestination == SaveDestination.inApp,
          onTap: () => s.setSaveDestination(SaveDestination.inApp),
        ),
      ],
    );
  }

  Future<void> _pickGallery(
      BuildContext context, SettingsController s) async {
    // Prompt for Photos / MediaStore access right when the user selects
    // Gallery, so the prompt is contextual and the actual save is friction-free.
    final messenger = ScaffoldMessenger.of(context);
    final ok = await Permissions().ensureGallerySave();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
              'Gallery access denied — saves will fail. You can grant later in system settings.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
    await s.setSaveDestination(SaveDestination.gallery);
  }
}

class _Choice extends StatelessWidget {
  const _Choice({
    required this.icon,
    required this.title,
    required this.body,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String body;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
          border: Border.all(
            color: selected ? scheme.primary : scheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                color: selected ? scheme.onPrimaryContainer : scheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(body, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? scheme.primary : scheme.outlineVariant,
            ),
          ],
        ),
      ),
    );
  }
}
