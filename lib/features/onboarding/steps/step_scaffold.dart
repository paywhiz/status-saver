import 'package:flutter/material.dart';

/// Shared layout for onboarding steps: large icon, title, body, scrollable
/// content area, and a primary CTA pinned to the bottom.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    required this.primary,
    this.children = const [],
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget primary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 48, color: scheme.onPrimaryContainer),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      body,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                    ),
                    const SizedBox(height: 28),
                    ...children,
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            primary,
          ],
        ),
      ),
    );
  }
}
