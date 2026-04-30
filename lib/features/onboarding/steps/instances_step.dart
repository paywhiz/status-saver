import 'package:flutter/material.dart';

import 'step_scaffold.dart';

class InstancesStep extends StatelessWidget {
  const InstancesStep({
    super.key,
    required this.personalSelected,
    required this.businessSelected,
    required this.personalInstalled,
    required this.businessInstalled,
    required this.onChanged,
    required this.onNext,
  });

  final bool personalSelected;
  final bool businessSelected;
  final bool personalInstalled;
  final bool businessInstalled;
  final void Function(bool personal, bool business) onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final atLeastOne = personalSelected || businessSelected;
    final neitherInstalled = !personalInstalled && !businessInstalled;
    return StepScaffold(
      icon: Icons.chat_bubble_outline,
      title: 'Which WhatsApp do you use?',
      body: neitherInstalled
          ? 'We couldn\'t find WhatsApp or WhatsApp Business on this device. '
              'Install one and reopen Status Saver.'
          : 'Pick the apps whose statuses you want to see. '
              'You can add the other one later from Settings.',
      primary: FilledButton(
        onPressed: atLeastOne ? onNext : null,
        child: const Text('Continue'),
      ),
      children: [
        _ToggleTile(
          icon: Icons.chat_outlined,
          title: 'Personal WhatsApp',
          subtitle: 'com.whatsapp',
          installed: personalInstalled,
          value: personalSelected && personalInstalled,
          onChanged: personalInstalled
              ? (v) => onChanged(v, businessSelected)
              : null,
        ),
        const SizedBox(height: 12),
        _ToggleTile(
          icon: Icons.storefront_outlined,
          title: 'WhatsApp Business',
          subtitle: 'com.whatsapp.w4b',
          installed: businessInstalled,
          value: businessSelected && businessInstalled,
          onChanged: businessInstalled
              ? (v) => onChanged(personalSelected, v)
              : null,
        ),
      ],
    );
  }
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.installed,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool installed;
  final bool value;

  /// Null when the variant isn't installed — the tile renders disabled.
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disabled = onChanged == null;
    final accent = disabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (value ? scheme.onPrimaryContainer : scheme.onSurface);
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : () => onChanged!(!value),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: value ? scheme.primaryContainer : scheme.surfaceContainerLow,
            border: Border.all(
              color: value ? scheme.primary : scheme.outlineVariant,
              width: value ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Icon(icon, color: accent),
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
                    const SizedBox(height: 2),
                    Text(
                      disabled ? 'Not installed' : subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Switch(value: value, onChanged: onChanged),
            ],
          ),
        ),
      ),
    );
  }
}
