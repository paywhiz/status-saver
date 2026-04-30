import 'package:flutter/material.dart';

import 'step_scaffold.dart';

class DoneStep extends StatefulWidget {
  const DoneStep({super.key, required this.onFinish});
  final Future<void> Function() onFinish;

  @override
  State<DoneStep> createState() => _DoneStepState();
}

class _DoneStepState extends State<DoneStep> {
  bool _busy = false;

  Future<void> _finish() async {
    setState(() => _busy = true);
    try {
      await widget.onFinish();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      icon: Icons.check_circle_outline,
      title: 'You\'re all set',
      body: 'Open WhatsApp, view a few statuses, then come back. '
          'They\'ll appear in the Recent tab.',
      primary: FilledButton(
        onPressed: _busy ? null : _finish,
        child: Text(_busy ? 'Opening…' : 'Open Status Saver'),
      ),
    );
  }
}
