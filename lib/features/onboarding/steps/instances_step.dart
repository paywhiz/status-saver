import 'package:flutter/material.dart';

import 'step_scaffold.dart';

class InstancesStep extends StatelessWidget {
  const InstancesStep({
    super.key,
    required this.personalSelected,
    required this.businessSelected,
    required this.onChanged,
    required this.onNext,
  });

  final bool personalSelected;
  final bool businessSelected;
  final void Function(bool personal, bool business) onChanged;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final atLeastOne = personalSelected || businessSelected;
    return StepScaffold(
      icon: Icons.chat_bubble_outline,
      title: 'Which WhatsApp do you use?',
      body: 'Pick the apps whose statuses you want to see. '
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
          value: personalSelected,
          onChanged: (v) => onChanged(v, businessSelected),
        ),
        const SizedBox(height: 12),
        _ToggleTile(
          icon: Icons.storefront_outlined,
          title: 'WhatsApp Business',
          subtitle: 'com.whatsapp.w4b',
          value: businessSelected,
          onChanged: (v) => onChanged(personalSelected, v),
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
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => onChanged(!value),
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
            Icon(icon,
                color: value ? scheme.onPrimaryContainer : scheme.onSurface),
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
                    subtitle,
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
    );
  }
}
