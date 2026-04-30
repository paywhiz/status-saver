import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/android_status_source.dart';
import '../../data/status_repository.dart';
import '../recent/recent_controller.dart';
import 'settings_controller.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsController>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          if (Platform.isAndroid) _whatsappSection(context, settings),
          if (Platform.isAndroid && settings.bothInstancesEnabled)
            _viewModeSection(context, settings),
          _saveDestinationSection(context, settings),
          _appearanceSection(context, settings),
          _aboutSection(context),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- sections

  Widget _whatsappSection(BuildContext context, SettingsController s) {
    return _Section(
      title: 'WhatsApp Sources',
      children: [
        _InstanceTile(
          label: 'Personal WhatsApp',
          enabled: s.personalEnabled,
          onToggle: (v) => _onToggleInstance(context, s, personal: true, v: v),
          onRePick: () => _rePick(context, personal: true),
        ),
        _InstanceTile(
          label: 'WhatsApp Business',
          enabled: s.businessEnabled,
          onToggle: (v) => _onToggleInstance(context, s, personal: false, v: v),
          onRePick: () => _rePick(context, personal: false),
        ),
      ],
    );
  }

  Widget _viewModeSection(BuildContext context, SettingsController s) {
    return RadioGroup<RecentViewMode>(
      groupValue: s.viewMode,
      onChanged: (v) {
        if (v != null) s.setViewMode(v);
      },
      child: const _Section(
        title: 'View Mode',
        subtitle:
            'How to show Personal and Business statuses when both are enabled.',
        children: [
          RadioListTile<RecentViewMode>(
            value: RecentViewMode.combined,
            title: Text('Combined feed'),
            subtitle: Text('All statuses together, sorted by time.'),
          ),
          RadioListTile<RecentViewMode>(
            value: RecentViewMode.separate,
            title: Text('Separate destinations'),
            subtitle: Text(
                'Personal and Business each get their own bottom-nav tab.'),
          ),
        ],
      ),
    );
  }

  Widget _saveDestinationSection(BuildContext context, SettingsController s) {
    return RadioGroup<SaveDestination>(
      groupValue: s.saveDestination,
      onChanged: (v) {
        if (v != null) s.setSaveDestination(v);
      },
      child: const _Section(
        title: 'Default Save Destination',
        subtitle: 'Where the Save button puts statuses by default. '
            'Long-press Save to choose the other destination once.',
        children: [
          RadioListTile<SaveDestination>(
            value: SaveDestination.gallery,
            title: Text('Gallery'),
            subtitle: Text(
                'Saved statuses appear in your Photos/Gallery and stay if you uninstall the app.'),
          ),
          RadioListTile<SaveDestination>(
            value: SaveDestination.inApp,
            title: Text('In-App'),
            subtitle: Text(
                'Saved statuses live privately inside Status Saver and are removed if you uninstall.'),
          ),
        ],
      ),
    );
  }

  Widget _appearanceSection(BuildContext context, SettingsController s) {
    return RadioGroup<ThemeMode>(
      groupValue: s.themeMode,
      onChanged: (v) {
        if (v != null) s.setThemeMode(v);
      },
      child: _Section(
        title: 'Appearance',
        children: [
          for (final mode in ThemeMode.values)
            RadioListTile<ThemeMode>(
              value: mode,
              title: Text(_themeLabel(mode)),
            ),
        ],
      ),
    );
  }

  Widget _aboutSection(BuildContext context) {
    return const _Section(
      title: 'About',
      children: [
        ListTile(
          title: Text('Status Saver'),
          subtitle: Text('Version 0.1.0'),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- handlers

  Future<void> _onToggleInstance(
    BuildContext context,
    SettingsController s, {
    required bool personal,
    required bool v,
  }) async {
    final otherEnabled = personal ? s.businessEnabled : s.personalEnabled;
    if (!v && !otherEnabled) {
      _toast(context, 'At least one WhatsApp source must stay enabled.');
      return;
    }
    // Enabling for the first time? Prompt the folder picker if needed.
    if (v) {
      final repo = context.read<StatusRepository>();
      if (repo is AndroidStatusSource) {
        final existing =
            personal ? await repo.messengerUri() : await repo.businessUri();
        if (existing == null) {
          final picked = personal
              ? await repo.pickMessengerFolder()
              : await repo.pickBusinessFolder();
          if (!picked) return;
        }
      }
    }
    if (personal) {
      await s.setPersonalEnabled(v);
    } else {
      await s.setBusinessEnabled(v);
    }
  }

  Future<void> _rePick(BuildContext context, {required bool personal}) async {
    final messenger = ScaffoldMessenger.of(context);
    final repo = context.read<StatusRepository>();
    if (repo is! AndroidStatusSource) return;
    final ok = personal
        ? await repo.pickMessengerFolder()
        : await repo.pickBusinessFolder();
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No folder selected')),
      );
      return;
    }
    if (context.mounted) {
      await context.read<RecentController>().refresh();
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _themeLabel(ThemeMode m) => switch (m) {
        ThemeMode.system => 'Follow system',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children, this.subtitle});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Text(
                subtitle!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
                  children[i],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InstanceTile extends StatelessWidget {
  const _InstanceTile({
    required this.label,
    required this.enabled,
    required this.onToggle,
    required this.onRePick,
  });

  final String label;
  final bool enabled;
  final ValueChanged<bool> onToggle;
  final VoidCallback onRePick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      subtitle: Text(enabled ? 'Showing in Recent' : 'Hidden'),
      trailing: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.folder_open_outlined),
            tooltip: 'Re-pick folder',
            onPressed: enabled ? onRePick : null,
          ),
          Switch(value: enabled, onChanged: onToggle),
        ],
      ),
    );
  }
}
