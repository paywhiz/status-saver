import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/android_status_source.dart';
import '../../data/status_repository.dart';
import '../recent/recent_controller.dart';
import '../settings/settings_controller.dart';
import 'steps/destination_step.dart';
import 'steps/done_step.dart';
import 'steps/grant_step.dart';
import 'steps/instances_step.dart';
import 'steps/view_mode_step.dart';
import 'steps/welcome_step.dart';

/// Multi-step first-run flow.
///
/// Steps (Android):
///   1. Welcome
///   2. Default save destination (gallery vs in-app)
///   3. Which WhatsApp instances (personal / business / both)
///   4. Grant SAF folder access for each chosen instance (sequential)
///   5. Combined vs separate destinations (only when both granted)
///   6. Done
///
/// On iOS the page is never shown (no SAF folder access; share-extension flow).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pc = PageController();

  // Local state — only persisted to SettingsController on completion.
  bool _personalSelected = true;
  bool _businessSelected = false;

  // Track which instances actually got their SAF permission granted, so the
  // view-mode step is only shown when both are usable.
  bool _personalGranted = false;
  bool _businessGranted = false;

  // Default to "separate" — when the user explicitly enabled both instances
  // it's the more useful starting choice, and avoids the impression that the
  // toggle isn't responsive on the view-mode step.
  RecentViewMode _viewMode = RecentViewMode.separate;

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _next() => _pc.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  Future<void> _finish() async {
    final settings = context.read<SettingsController>();
    await settings.setPersonalEnabled(_personalGranted && _personalSelected);
    await settings.setBusinessEnabled(_businessGranted && _businessSelected);
    // Persist the view-mode choice only when both instances ended up enabled —
    // the getter ignores it otherwise. Done after the enable toggles so the
    // value sticks.
    if (settings.bothInstancesEnabled) {
      await settings.setViewMode(_viewMode);
    }
    await settings.setOnboardingCompleted(true);
    if (mounted) {
      await context.read<RecentController>().init();
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<StatusRepository>();
    final android = repo is AndroidStatusSource ? repo : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome'),
        automaticallyImplyLeading: false,
      ),
      body: PageView(
        controller: _pc,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          WelcomeStep(onNext: _next),
          DestinationStep(onNext: _next),
          InstancesStep(
            personalSelected: _personalSelected,
            businessSelected: _businessSelected,
            onChanged: (p, b) => setState(() {
              _personalSelected = p;
              _businessSelected = b;
            }),
            onNext: _next,
          ),
          GrantStep(
            personal: _personalSelected,
            business: _businessSelected,
            android: android,
            onResult: ({required bool personalGranted, required bool businessGranted}) {
              setState(() {
                _personalGranted = personalGranted;
                _businessGranted = businessGranted;
              });
              // Skip view-mode step if only one ended up granted.
              if (personalGranted && businessGranted) {
                _next();
              } else {
                _pc.animateToPage(5,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOut);
              }
            },
          ),
          ViewModeStep(
            initial: _viewMode,
            onChanged: (m) => setState(() => _viewMode = m),
            onNext: _next,
          ),
          DoneStep(onFinish: _finish),
        ],
      ),
    );
  }
}
