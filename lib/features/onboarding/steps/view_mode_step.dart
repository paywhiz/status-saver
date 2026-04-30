import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../settings/settings_controller.dart';
import 'step_scaffold.dart';

class ViewModeStep extends StatelessWidget {
  const ViewModeStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<SettingsController>();
    return StepScaffold(
      icon: Icons.dashboard_customize_outlined,
      title: 'How should the two be shown?',
      body: 'You enabled both Personal and Business. Choose how to organize them.',
      primary: FilledButton(
        onPressed: onNext,
        child: const Text('Continue'),
      ),
      children: [
        _Choice(
          icon: Icons.merge_type,
          title: 'Combined feed',
          body: 'All statuses appear together in a single Recent tab, sorted by time.',
          selected: s.viewMode == RecentViewMode.combined,
          onTap: () => s.setViewMode(RecentViewMode.combined),
        ),
        const SizedBox(height: 12),
        _Choice(
          icon: Icons.view_module_outlined,
          title: 'Separate destinations',
          body:
              'Personal and Business each get their own bottom-nav tab so you can switch between them like apps.',
          selected: s.viewMode == RecentViewMode.separate,
          onTap: () => s.setViewMode(RecentViewMode.separate),
        ),
      ],
    );
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
