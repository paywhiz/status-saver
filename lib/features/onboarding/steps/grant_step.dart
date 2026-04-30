import 'package:flutter/material.dart';

import '../../../data/android_status_source.dart';
import 'step_scaffold.dart';

/// Sequentially asks for SAF folder permission for each chosen instance.
/// On completion, reports back which instances actually got granted.
class GrantStep extends StatefulWidget {
  const GrantStep({
    super.key,
    required this.personal,
    required this.business,
    required this.android,
    required this.onResult,
  });

  final bool personal;
  final bool business;
  final AndroidStatusSource? android;
  final void Function({
    required bool personalGranted,
    required bool businessGranted,
  }) onResult;

  @override
  State<GrantStep> createState() => _GrantStepState();
}

class _GrantStepState extends State<GrantStep> {
  bool _busy = false;
  bool _personalGranted = false;
  bool _businessGranted = false;
  String? _error;

  Future<void> _grant() async {
    final android = widget.android;
    if (android == null) {
      // No-op on non-Android (this page should not run there).
      widget.onResult(
        personalGranted: false,
        businessGranted: false,
      );
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    var personalOk = _personalGranted;
    var businessOk = _businessGranted;
    try {
      if (widget.personal && !personalOk) {
        personalOk = await android.pickMessengerFolder();
      }
      if (widget.business && !businessOk) {
        businessOk = await android.pickBusinessFolder();
      }
      setState(() {
        _personalGranted = personalOk;
        _businessGranted = businessOk;
      });
      if ((widget.personal && !personalOk) ||
          (widget.business && !businessOk)) {
        setState(() {
          _error = 'Some folders weren\'t granted. Tap to try again, '
              'or skip — you can always set them up later from Settings.';
        });
      } else {
        widget.onResult(
          personalGranted: personalOk,
          businessGranted: businessOk,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _skip() {
    widget.onResult(
      personalGranted: _personalGranted,
      businessGranted: _businessGranted,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StepScaffold(
      icon: Icons.folder_open_outlined,
      title: 'Grant folder access',
      body: 'Status Saver needs to read each app\'s .Statuses folder. '
          'The system picker will open in the right place — just tap '
          '"Use this folder" to confirm.',
      primary: Column(
        children: [
          FilledButton(
            onPressed: _busy ? null : _grant,
            child: Text(_busy ? 'Working…' : 'Grant access'),
          ),
          TextButton(
            onPressed: _busy ? null : _skip,
            child: const Text('Skip for now'),
          ),
        ],
      ),
      children: [
        if (widget.personal)
          _StatusRow(
            label: 'Personal WhatsApp',
            granted: _personalGranted,
          ),
        if (widget.business)
          _StatusRow(
            label: 'WhatsApp Business',
            granted: _businessGranted,
          ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({required this.label, required this.granted});
  final String label;
  final bool granted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.radio_button_unchecked,
            color: granted ? scheme.primary : scheme.outline,
          ),
          const SizedBox(width: 12),
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
