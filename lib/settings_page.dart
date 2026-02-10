import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'app_settings.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppSettings>(
      valueListenable: controller,
      builder: (context, settings, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF5F3EF),
          appBar: AppBar(
            title: const Text('Pet Settings'),
            backgroundColor: const Color(0xFFF5F3EF),
            foregroundColor: Colors.black,
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (!Platform.isAndroid)
                _Section(
                  title: 'Pet Size',
                  child: _SliderRow(
                    label: 'Size',
                    value: settings.petScale,
                    min: 0.6,
                    max: 2.0,
                    divisions: 14,
                    format: (v) => '${(v * 100).round()}%',
                    onChanged: controller.setPetScale,
                  ),
                ),
              _Section(
                title: 'Roam Speed',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                      _SliderRow(
                        label: 'Desktop',
                        value: settings.desktopRoamSpeed,
                        min: 60,
                        max: 320,
                        divisions: 13,
                        format: (v) => '${v.round()} px/s',
                        onChanged: controller.setDesktopRoamSpeed,
                      ),
                    if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                      const SizedBox(height: 12),
                    _SliderRow(
                      label: 'Mobile',
                      value: settings.mobileRoamSpeed,
                      min: 10,
                      max: 320,
                      divisions: 31,
                      format: (v) => '${v.round()} px/s',
                      onChanged: controller.setMobileRoamSpeed,
                    ),
                  ],
                ),
              ),
              if (Platform.isAndroid)
                _Section(
                  title: 'Android Overlay',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SliderRow(
                        label: 'Overlay Size',
                        value: settings.androidOverlayScale,
                        min: 0.1,
                        max: 2.0,
                        divisions: 19,
                        format: (v) => '${v.toStringAsFixed(1)}x',
                        onChanged: controller.setAndroidOverlayScale,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            final mq = MediaQuery.of(context);
                            final fullWidth =
                                mq.size.width + mq.padding.left + mq.padding.right;
                            final fullHeight =
                                mq.size.height + mq.padding.top + mq.padding.bottom;
                            final current = controller.value;
                            await FlutterOverlayWindow.shareData({
                              'type': 'apply',
                              'petScale': current.petScale,
                              'mobileRoamSpeed': current.mobileRoamSpeed,
                              'androidOverlayScale': current.androidOverlayScale,
                              'showOverlayDebug': current.showOverlayDebug,
                              'screenWidth': fullWidth,
                              'screenHeight': fullHeight,
                              'padLeft': mq.padding.left,
                              'padTop': mq.padding.top,
                              'padRight': mq.padding.right,
                              'padBottom': mq.padding.bottom,
                            });
                          },
                          child: const Text('Apply Settings'),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile.adaptive(
                        value: settings.showOverlayDebug,
                        title: const Text('Show overlay debug'),
                        contentPadding: EdgeInsets.zero,
                        onChanged: controller.setShowOverlayDebug,
                      ),
                    ],
                  ),
                ),
              if (Platform.isWindows || Platform.isMacOS || Platform.isLinux)
                _Section(
                  title: 'Startup',
                  child: SwitchListTile.adaptive(
                    value: settings.launchAtStartup,
                    title: const Text('Launch at startup'),
                    contentPadding: EdgeInsets.zero,
                    onChanged: controller.setLaunchAtStartup,
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
