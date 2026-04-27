import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../recent/recent_controller.dart';

/// Android first-run page: explains the SAF folder picker and triggers it.
/// On iOS this page is never reached because the Recent tab is hidden.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Welcome')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            const Text(
              'To show recent WhatsApp statuses, this app needs read access '
              'to your WhatsApp .Statuses folder.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            const Text(
              'On the next screen, navigate to:\n\n'
              '  Android  ›  media  ›  com.whatsapp  ›  WhatsApp  ›  Media  ›  .Statuses\n\n'
              'and tap "Use this folder."',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _busy ? null : _grant,
              child: const Text('Grant access'),
            ),
            const SizedBox(height: 8),
            const Text(
              'You can grant a second folder for WhatsApp Business after '
              'the first one is set up.',
              style: TextStyle(color: Colors.black54, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grant() async {
    setState(() => _busy = true);
    try {
      await context.read<RecentController>().setup();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
