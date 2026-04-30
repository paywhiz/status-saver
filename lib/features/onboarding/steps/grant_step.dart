import 'package:flutter/material.dart';

import '../../../data/android_status_source.dart';
import 'step_scaffold.dart';

/// Per-instance SAF folder grant step. Each selected instance gets its own
/// tappable row that launches only that instance's picker; the user returns
/// to this same screen between picks.
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

enum _Instance { personal, business }

class _GrantStepState extends State<GrantStep> {
  bool _personalGranted = false;
  bool _businessGranted = false;
  _Instance? _busy;
  String? _error;

  bool get _allChosenGranted =>
      (!widget.personal || _personalGranted) &&
      (!widget.business || _businessGranted);

  bool get _anyChosenGranted =>
      (widget.personal && _personalGranted) ||
      (widget.business && _businessGranted);

  Future<void> _pick(_Instance which) async {
    final android = widget.android;
    if (android == null || _busy != null) return;
    setState(() {
      _busy = which;
      _error = null;
    });
    try {
      final ok = which == _Instance.personal
          ? await android.pickMessengerFolder()
          : await android.pickBusinessFolder();
      setState(() {
        if (which == _Instance.personal) {
          _personalGranted = ok;
        } else {
          _businessGranted = ok;
        }
        if (!ok) {
          _error = 'That folder didn\'t look right. Tap the row to try again.';
        }
      });
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _continue() {
    widget.onResult(
      personalGranted: _personalGranted,
      businessGranted: _businessGranted,
    );
  }

  @override
  Widget build(BuildContext context) {
    final continueEnabled =
        _busy == null && (_allChosenGranted || _anyChosenGranted);
    return StepScaffold(
      icon: Icons.folder_open_outlined,
      title: 'Grant folder access',
      body: 'Tap each app below to grant access to its .Statuses folder. '
          'The system picker opens in the right place — just tap '
          '"Use this folder" to confirm. (To exit the picker without '
          'picking, tap the X in its toolbar.)',
      primary: Column(
        children: [
          FilledButton(
            onPressed: continueEnabled ? _continue : null,
            child: Text(_allChosenGranted ? 'Continue' : 'Continue with these'),
          ),
          TextButton(
            onPressed: _busy != null ? null : _continue,
            child: const Text('Skip for now'),
          ),
        ],
      ),
      children: [
        if (widget.personal)
          _StatusRow(
            label: 'Personal WhatsApp',
            granted: _personalGranted,
            busy: _busy == _Instance.personal,
            disabled: _busy != null && _busy != _Instance.personal,
            onTap: () => _pick(_Instance.personal),
          ),
        if (widget.business)
          _StatusRow(
            label: 'WhatsApp Business',
            granted: _businessGranted,
            busy: _busy == _Instance.business,
            disabled: _busy != null && _busy != _Instance.business,
            onTap: () => _pick(_Instance.business),
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
  const _StatusRow({
    required this.label,
    required this.granted,
    required this.busy,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final bool granted;
  final bool busy;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = granted ? scheme.primary : scheme.outline;
    final tappable = !busy && !disabled;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: tappable ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: scheme.outlineVariant),
            ),
            child: Row(
              children: [
                if (busy)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    granted ? Icons.check_circle : Icons.lock_outline,
                    color: accent,
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.bodyLarge),
                ),
                Text(
                  granted
                      ? 'Granted'
                      : (busy ? 'Opening…' : 'Tap to grant'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
