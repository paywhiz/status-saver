import 'package:flutter/material.dart';

import '../../settings/settings_controller.dart';
import 'step_scaffold.dart';

/// Lets the user choose between combined and separate destinations when both
/// instances are enabled. State is held locally and reported up to the
/// onboarding parent on every change so it can be persisted at the end of the
/// flow — `SettingsController.viewMode`'s getter ignores stored values until
/// `bothInstancesEnabled` is true, which doesn't happen until `_finish()`.
class ViewModeStep extends StatefulWidget {
  const ViewModeStep({
    super.key,
    required this.initial,
    required this.onChanged,
    required this.onNext,
  });

  final RecentViewMode initial;
  final ValueChanged<RecentViewMode> onChanged;
  final VoidCallback onNext;

  @override
  State<ViewModeStep> createState() => _ViewModeStepState();
}

class _ViewModeStepState extends State<ViewModeStep> {
  late RecentViewMode _selected = widget.initial;

  void _select(RecentViewMode mode) {
    if (mode == _selected) return;
    setState(() => _selected = mode);
    widget.onChanged(mode);
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      icon: Icons.dashboard_customize_outlined,
      title: 'How should the two be shown?',
      body: 'You enabled both Personal and Business. Choose how to organize them.',
      primary: FilledButton(
        onPressed: widget.onNext,
        child: const Text('Continue'),
      ),
      children: [
        _Choice(
          icon: Icons.view_module_outlined,
          title: 'Separate destinations',
          body:
              'Personal and Business each get their own bottom-nav tab so you can switch between them like apps.',
          selected: _selected == RecentViewMode.separate,
          onTap: () => _select(RecentViewMode.separate),
        ),
        const SizedBox(height: 12),
        _Choice(
          icon: Icons.merge_type,
          title: 'Combined feed',
          body: 'All statuses appear together in a single Recent tab, sorted by time.',
          selected: _selected == RecentViewMode.combined,
          onTap: () => _select(RecentViewMode.combined),
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
