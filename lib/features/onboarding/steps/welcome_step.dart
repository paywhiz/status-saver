import 'package:flutter/material.dart';

import 'step_scaffold.dart';

class WelcomeStep extends StatelessWidget {
  const WelcomeStep({super.key, required this.onNext});
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      icon: Icons.waving_hand_outlined,
      title: 'Welcome to Status Saver',
      body: 'Save WhatsApp statuses you want to keep — free, ad-free, '
          'and entirely on-device. A few quick choices and you\'re set.',
      primary: FilledButton(
        onPressed: onNext,
        child: const Text('Get started'),
      ),
    );
  }
}
