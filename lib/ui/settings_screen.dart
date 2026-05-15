import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/backup_service.dart';
import '../l10n/app_localizations.dart';
import '../logic/audio_service.dart';
import '../logic/settings_provider.dart';
import '../logic/workout_provider.dart';

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

          // ── Audio ─────────────────────────────────────────────────────────
          _SectionHeader(context.t('audio')),
          SwitchListTile(
            secondary: const Icon(Icons.volume_up_outlined),
            title: Text(context.t('audio_enabled')),
            value: settings.audioEnabled,
            onChanged: (v) => settings.setAudioEnabled(v),
          ),
          SwitchListTile(
            secondary: Icon(
              Icons.music_note_outlined,
              color: settings.audioEnabled ? null : Theme.of(context).disabledColor,
            ),
            title: Text(
              context.t('rep_sound'),
              style: settings.audioEnabled
                  ? null
                  : TextStyle(color: Theme.of(context).disabledColor),
            ),
            value: settings.audioEnabled && settings.repSoundEnabled,
            onChanged: settings.audioEnabled
                ? (v) => settings.setRepSoundEnabled(v)
                : null,
          ),
          _SliderTile(
            icon: settings.audioVolume == 0
                ? Icons.volume_off_outlined
                : settings.audioVolume < 0.5
                    ? Icons.volume_down_outlined
                    : Icons.volume_up_outlined,
            title: context.t('audio_volume'),
            value: settings.audioVolume,
            min: 0.0,
            max: 1.0,
            divisions: 20,
            label: '${(settings.audioVolume * 100).round()} %',
            onChanged: settings.audioEnabled
                ? (v) => settings.setAudioVolume(v)
                : (_) {},
            onChangeEnd: settings.audioEnabled
                ? (_) => AudioService.instance.playTargetReached()
                : null,
          ),
          const Divider(height: 1),

          // ── Training ──────────────────────────────────────────────────────
          _SectionHeader(context.t('training_settings')),
          _SliderTile(
            icon: Icons.timer_outlined,
            title: context.t('rest_easy'),
            value: settings.restSecondsEasy.toDouble(),
            min: 10,
            max: 60,
            divisions: 10,
            label: '${settings.restSecondsEasy} s',
            onChanged: (v) => settings.setRestSecondsEasy(v.round()),
          ),
          _SliderTile(
            icon: Icons.timer_outlined,
            title: context.t('rest_normal'),
            value: settings.restSecondsNormal.toDouble(),
            min: 30,
            max: 120,
            divisions: 9,
            label: '${settings.restSecondsNormal} s',
            onChanged: (v) => settings.setRestSecondsNormal(v.round()),
          ),
          _SliderTile(
            icon: Icons.timer_outlined,
            title: context.t('rest_hard'),
            value: settings.restSecondsHard.toDouble(),
            min: 60,
            max: 180,
            divisions: 8,
            label: '${settings.restSecondsHard} s',
            onChanged: (v) => settings.setRestSecondsHard(v.round()),
          ),
          _SensitivityTile(settings: settings),
          const Divider(height: 1),

          // ── Data ─────────────────────────────────────────────────────────
          _SectionHeader(context.t('data')),
          _SettingsTile(
            icon: Icons.upload_file,
            title: context.t('export_backup'),
            onTap: () => _exportBackup(context),
          ),
          _SettingsTile(
            icon: Icons.download,
            title: context.t('import_backup'),
            onTap: () => _importBackup(context),
          ),
          _SettingsTile(
            icon: Icons.restore,
            title: context.t('import_puud'),
            onTap: () => _importPuud(context),
          ),
          _SettingsTile(
            icon: Icons.delete_forever,
            title: context.t('clear_all_data'),
            titleColor: Colors.red,
            onTap: () => _confirmClearAll(context),
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

  Future<void> _exportBackup(BuildContext context) async {
    final settings = context.read<SettingsProvider>();
    final path = await BackupService.exportBackup(settings);
    if (!context.mounted) return;
    if (path != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('backup_saved_to').replaceAll('{path}', path)),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _importBackup(BuildContext context) async {
    final settings  = context.read<SettingsProvider>();
    final provider  = context.read<WorkoutProvider>();
    final result    = await BackupService.importBackup(settings);
    if (!context.mounted) return;

    if (result.workouts == -1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('cancelled'))),
      );
      return;
    }
    if (result.conflictAborted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('import_conflict_aborted')),
          backgroundColor: Colors.red.shade800,
          duration: const Duration(seconds: 6),
        ),
      );
      return;
    }
    if (result.workouts == 0 && !result.settings) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('no_data_imported'))),
      );
      return;
    }

    await provider.loadHistoryFromDb();
    if (!context.mounted) return;

    final importLine = context.tp('backup_restored', {
      'w': '${result.workouts}',
      'r': '${result.repDetails}',
    });
    final skippedLine = result.skipped > 0
        ? context.tr('import_skipped').replaceAll('{n}', '${result.skipped}')
        : null;
    final message = result.checksumMismatch
        ? '$importLine\n${context.tr('checksum_mismatch')}'
        : [importLine, if (result.settings) context.tr('settings_restored'),
           if (skippedLine != null) skippedLine].join(' ');

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: result.checksumMismatch ? Colors.orange.shade800 : null,
        duration: Duration(seconds: result.checksumMismatch ? 6 : 4),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(context.tr('clear_all_data')),
        content: Text(context.tr('clear_all_data_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<WorkoutProvider>().clearAllData();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('all_data_deleted'))),
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
    this.titleColor,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = titleColor;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: color != null ? TextStyle(color: color) : null),
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

// ── Slider tile ───────────────────────────────────────────────────────────────

class _SliderTile extends StatelessWidget {
  const _SliderTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.label,
    required this.onChanged,
    this.onChangeEnd,
  });

  final IconData              icon;
  final String                title;
  final double                value;
  final double                min;
  final double                max;
  final int                   divisions;
  final String                label;
  final ValueChanged<double>  onChanged;
  final ValueChanged<double>? onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          leading: Icon(icon),
          title: Text(title),
          trailing: Text(
            label,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(56, 0, 16, 4),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }
}

// ── Sensor sensitivity tile ───────────────────────────────────────────────────

class _SensitivityTile extends StatelessWidget {
  const _SensitivityTile({required this.settings});
  final SettingsProvider settings;

  static const _options = [
    (label: 'sensitivity_high',   value: 8.0),
    (label: 'sensitivity_medium', value: 12.0),
    (label: 'sensitivity_low',    value: 16.0),
  ];

  @override
  Widget build(BuildContext context) {
    final primary  = Theme.of(context).colorScheme.primary;
    final current  = settings.sensorThreshold;

    return ListTile(
      leading: const Icon(Icons.sensors),
      title: Text(context.t('sensor_sensitivity')),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: _options.map((opt) {
            final selected = current == opt.value;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => settings.setSensorThreshold(opt.value),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? primary : Colors.grey.shade400,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      context.t(opt.label),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                        color: selected ? Colors.white : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
