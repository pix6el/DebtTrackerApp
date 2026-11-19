import 'package:flutter/material.dart';
import '../utils/theme_controller.dart';
import 'about_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ValueListenableBuilder<ThemeMode>(
        valueListenable: ThemeController.instance,
        builder: (context, currentMode, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(
                  'APPEARANCE',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(140),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _ThemeOptionTile(
                      icon: Icons.light_mode_rounded,
                      title: 'Light Mode',
                      subtitle: 'Bright and clean interface for daytime use',
                      selected: currentMode == ThemeMode.light,
                      onTap: () =>
                          ThemeController.instance.setThemeMode(ThemeMode.light),
                    ),
                    const Divider(height: 1, indent: 68),
                    _ThemeOptionTile(
                      icon: Icons.dark_mode_rounded,
                      title: 'Dark Mode',
                      subtitle: 'Easy on the eyes in low-light environments',
                      selected: currentMode == ThemeMode.dark,
                      onTap: () =>
                          ThemeController.instance.setThemeMode(ThemeMode.dark),
                    ),
                    const Divider(height: 1, indent: 68),
                    _ThemeOptionTile(
                      icon: Icons.brightness_auto_rounded,
                      title: 'System Default',
                      subtitle: 'Automatically follows your device theme',
                      selected: currentMode == ThemeMode.system,
                      onTap: () => ThemeController.instance
                          .setThemeMode(ThemeMode.system),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                child: Text(
                  'APP INFORMATION',
                  style: textTheme.labelSmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.9,
                  ),
                ),
              ),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withAlpha(140),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: _iconBox(
                        colorScheme,
                        Icons.currency_exchange_rounded,
                      ),
                      title: const Text(
                        'Currency',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Malaysian Ringgit (MYR / RM)'),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: _iconBox(
                        colorScheme,
                        Icons.storage_rounded,
                      ),
                      title: const Text(
                        'Data Storage',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Local SQLite on this device'),
                    ),
                    const Divider(height: 1, indent: 68),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: _iconBox(
                        colorScheme,
                        Icons.info_outline_rounded,
                      ),
                      title: const Text(
                        'About & Guide',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Instructions and app version 1.0.0'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AboutScreen(initialTab: 0),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _iconBox(ColorScheme colorScheme, IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(160),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: colorScheme.primary, size: 22),
    );
  }
}

class _ThemeOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: selected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          color: selected ? colorScheme.primary : null,
        ),
      ),
      subtitle: Text(subtitle),
      trailing: Icon(
        selected
            ? Icons.check_circle_rounded
            : Icons.radio_button_unchecked_rounded,
        color: selected ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}
