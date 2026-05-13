import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../logic/settings_provider.dart';
import '../logic/workout_provider.dart';
import '../data/csv_service.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(context.t('settings'))),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────────
          _SectionHeader(context.t('appearance')),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: context.t('theme'),
            subtitle: _themeLabel(context, settings.themeMode),
            onTap: () => _showThemePicker(context, settings),
          ),
          _SettingsTile(
            icon: Icons.language,
            title: context.t('language'),
            subtitle: settings.locale == 'de'
                ? context.t('german')
                : context.t('english'),
            onTap: () => _showLanguagePicker(context, settings),
          ),
          const Divider(height: 1),

          // ── Data ─────────────────────────────────────────────────────────
          _SectionHeader(context.t('data')),
          _SettingsTile(
            icon: Icons.upload_file,
            title: context.t('export_csv'),
            onTap: () {
              final provider = context.read<WorkoutProvider>();
              CsvService.exportToCsv(provider.history);
            },
          ),
          _SettingsTile(
            icon: Icons.download,
            title: context.t('import_csv'),
            onTap: () => _importCsv(context),
          ),
          _SettingsTile(
            icon: Icons.restore,
            title: context.t('import_puud'),
            onTap: () => _importPuud(context),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }

  String _themeLabel(BuildContext context, ThemeMode mode) => switch (mode) {
        ThemeMode.light => context.tr('theme_light'),
        ThemeMode.system => context.tr('theme_system'),
        _ => context.tr('theme_dark'),
      };

  void _showThemePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _ThemePicker(settings: settings),
    );
  }

  void _showLanguagePicker(BuildContext context, SettingsProvider settings) {
    showModalBottomSheet<void>(
      context: context,
      builder: (_) => _LanguagePicker(settings: settings),
    );
  }

  Future<void> _importCsv(BuildContext context) async {
    final provider = context.read<WorkoutProvider>();
    final imported = await CsvService.importFromCsv();
    if (!context.mounted) return;
    if (imported.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('no_data_imported'))),
      );
      return;
    }
    await provider.saveMultipleWorkouts(imported);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${imported.length} ${context.tr('entries_imported')}'),
      ),
    );
  }

  Future<void> _importPuud(BuildContext context) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('opening_file'))),
    );
    final provider = context.read<WorkoutProvider>();
    final count = await provider.importFromPuud();
    if (!context.mounted) return;
    final msg = switch (count) {
      -1 => context.tr('cancelled'),
      0 => context.tr('no_data_found'),
      _ => '$count ${context.tr('entries_imported')}',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

// ── Theme picker sheet ────────────────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.settings});
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.t('theme'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          _ThemeOption(
            icon: Icons.dark_mode,
            label: context.t('theme_dark'),
            selected: settings.themeMode == ThemeMode.dark,
            onTap: () {
              settings.setThemeMode(ThemeMode.dark);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            icon: Icons.light_mode,
            label: context.t('theme_light'),
            selected: settings.themeMode == ThemeMode.light,
            onTap: () {
              settings.setThemeMode(ThemeMode.light);
              Navigator.pop(context);
            },
          ),
          _ThemeOption(
            icon: Icons.brightness_auto,
            label: context.t('theme_system'),
            selected: settings.themeMode == ThemeMode.system,
            onTap: () {
              settings.setThemeMode(ThemeMode.system);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      trailing: selected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}

// ── Language picker sheet ─────────────────────────────────────────────────────

class _LanguagePicker extends StatelessWidget {
  const _LanguagePicker({required this.settings});
  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PickerHandle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Text(
              context.t('language'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          ListTile(
            leading: const Text('🇩🇪', style: TextStyle(fontSize: 24)),
            title: Text(context.t('german')),
            trailing: settings.locale == 'de'
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              settings.setLocale('de');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
            title: Text(context.t('english')),
            trailing: settings.locale == 'en'
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () {
              settings.setLocale('en');
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _PickerHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.outlineVariant,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
