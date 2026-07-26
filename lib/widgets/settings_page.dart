import 'dart:io';

import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../l10n/app_localizations.dart';
import '../models/app_settings.dart';
import '../services/update_checker.dart';
import '../services/update_prompt.dart';

final Future<String> _versionLabelFuture = PackageInfo.fromPlatform()
    .then((info) => 'v${info.version}')
    .catchError((_) => 'v0.1.0');

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final GitHubUpdateChecker _updateChecker = GitHubUpdateChecker();

  Future<void> _checkForUpdates() async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await _updateChecker.checkForUpdates();
    if (!mounted) {
      return;
    }
    Navigator.of(context, rootNavigator: true).pop();

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to check updates')),
      );
      return;
    }

    if (result.hasUpdate) {
      await showUpdateAvailableDialog(context, result);
      return;
    }

    await showNoUpdateDialog(context, result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ValueListenableBuilder<AppSettings>(
      valueListenable: widget.controller,
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3EF),
          appBar: AppBar(
            title: Text(l10n.appTitleSettings),
            backgroundColor: const Color(0xFFF5F3EF),
            foregroundColor: Colors.black,
          ),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 48),
                children: [
                  _Section(
                    title: l10n.sectionLanguage,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return DropdownMenu<String>(
                          initialSelection: settings.languageCode,
                          width: constraints.maxWidth,
                          textStyle: const TextStyle(color: Colors.black),
                          inputDecorationTheme: const InputDecorationTheme(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          dropdownMenuEntries: [
                            DropdownMenuEntry(
                              value: '',
                              label: l10n.languageSystem,
                            ),
                            DropdownMenuEntry(
                              value: 'en',
                              label: l10n.languageEnglish,
                            ),
                            DropdownMenuEntry(
                              value: 'zh',
                              label: l10n.languageChinese,
                            ),
                          ],
                          onSelected: (value) {
                            widget.controller.setLanguageCode(value ?? '');
                          },
                        );
                      },
                    ),
                  ),
                  if (!Platform.isAndroid)
                    _Section(
                      title: l10n.sectionAemeathSize,
                      child: _SliderRow(
                        label: l10n.labelSize,
                        value: settings.petScale,
                        min: 0.6,
                        max: 2.0,
                        divisions: 14,
                        format: (v) => '${(v * 100).round()}%',
                        onChanged: widget.controller.setPetScale,
                      ),
                    ),
                  _Section(
                    title: l10n.sectionRoamSpeed,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux)
                          _SliderRow(
                            label: l10n.labelDesktop,
                            value: settings.desktopRoamSpeed,
                            min: 60,
                            max: 320,
                            divisions: 13,
                            format: (v) => l10n.pxPerSecond(v.round()),
                            onChanged: widget.controller.setDesktopRoamSpeed,
                          ),
                        if (Platform.isWindows ||
                            Platform.isMacOS ||
                            Platform.isLinux)
                          const SizedBox(height: 12),
                        if (Platform.isAndroid || Platform.isIOS)
                          _SliderRow(
                            label: l10n.labelMobile,
                            value: settings.mobileRoamSpeed,
                            min: 10,
                            max: 320,
                            divisions: 31,
                            format: (v) => l10n.pxPerSecond(v.round()),
                            onChanged: widget.controller.setMobileRoamSpeed,
                          ),
                      ],
                    ),
                  ),
                  if (Platform.isAndroid)
                    _Section(
                      title: l10n.sectionAndroidOverlay,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SliderRow(
                            label: l10n.labelOverlaySize,
                            value: settings.androidOverlayScale,
                            min: 0.1,
                            max: 2.0,
                            divisions: 19,
                            format: (v) => '${v.toStringAsFixed(1)}x',
                            onChanged: widget.controller.setAndroidOverlayScale,
                          ),
                          const SizedBox(height: 12),
                          SwitchListTile.adaptive(
                            value: settings.clickThrough,
                            title: Text(l10n.clickThrough),
                            subtitle: Text(l10n.clickThroughDescription),
                            contentPadding: EdgeInsets.zero,
                            onChanged: widget.controller.setClickThrough,
                          ),
                          SwitchListTile.adaptive(
                            value: settings.showOverlayDebug,
                            title: Text(l10n.showOverlayDebug),
                            contentPadding: EdgeInsets.zero,
                            onChanged: widget.controller.setShowOverlayDebug,
                          ),
                        ],
                      ),
                    ),
                  if (Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux)
                    _Section(
                      title: l10n.sectionInteraction,
                      child: SwitchListTile.adaptive(
                        value: settings.clickThrough,
                        title: Text(l10n.clickThrough),
                        subtitle: Text(l10n.clickThroughDescription),
                        contentPadding: EdgeInsets.zero,
                        onChanged: widget.controller.setClickThrough,
                      ),
                    ),
                  if (Platform.isWindows ||
                      Platform.isMacOS ||
                      Platform.isLinux)
                    _Section(
                      title: l10n.sectionStartup,
                      child: SwitchListTile.adaptive(
                        value: settings.launchAtStartup,
                        title: Text(l10n.launchAtStartup),
                        contentPadding: EdgeInsets.zero,
                        onChanged: widget.controller.setLaunchAtStartup,
                      ),
                    ),
                  _Section(
                    title: 'Update',
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _checkForUpdates,
                        icon: const Icon(Icons.system_update_alt),
                        label: const Text('Check for updates'),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                bottom: 12,
                child: FutureBuilder<String>(
                  future: _versionLabelFuture,
                  builder: (context, snapshot) {
                    return Text(
                      snapshot.data ?? 'v0.1.0',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: Colors.black),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text(format(value)),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
