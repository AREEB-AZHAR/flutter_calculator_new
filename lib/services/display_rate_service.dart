import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DisplayRateService with WidgetsBindingObserver {
  static final instance = DisplayRateService();
  static const channel = MethodChannel('com.areeb.tally/display_rate');
  static final preference = ValueNotifier<int>(0);
  static final supported = ValueNotifier<List<int>>([]);
  static final status = ValueNotifier<String>('System controlled');
  int _generation = 0;
  bool _observing = false;
  Future<void> initialize() async {
    if (!_observing) {
      WidgetsBinding.instance.addObserver(this);
      _observing = true;
    }
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getInt('tally_display_rate') ?? 0;
    preference.value = [0, 60, 120].contains(saved) ? saved : 0;
    await setPreference(preference.value);
  }

  Future<void> setPreference(int hz) async {
    if (![0, 60, 120].contains(hz)) throw ArgumentError.value(hz);
    final generation = ++_generation;
    try {
      final info = await channel.invokeMapMethod<String, dynamic>(
        'setPreference',
        {'hz': hz},
      );
      if (generation != _generation) return;
      supported.value = (info?['supported'] as List? ?? [])
          .whereType<num>()
          .map((n) => n.round())
          .toSet()
          .toList();
      final accepted = info?['accepted'] == true;
      preference.value = accepted ? hz : 0;
      status.value = accepted
          ? (hz == 0
                ? 'System controlled'
                : '$hz Hz requested; the OS may adjust it.')
          : 'Requested rate unavailable; using system control.';
    } on MissingPluginException {
      if (generation != _generation) return;
      supported.value = [];
      preference.value = 0;
      status.value =
          'Refresh-rate control is available on supported Android devices.';
    } on PlatformException {
      if (generation != _generation) return;
      preference.value = 0;
      status.value = 'Could not change refresh rate; using system control.';
    }
    if (generation != _generation) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('tally_display_rate', preference.value);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(setPreference(preference.value));
    }
  }
}
