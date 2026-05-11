import 'dart:developer' as developer;
import 'dart:io' show Platform;

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const supportedAlternateAppIcons = <String>{
  'icon_orangethinker',
  'icon_newdark',
  'icon_water',
  'icon_minimal',
  'icon_llm',
};

final appIconControllerProvider =
    AsyncNotifierProvider<AppIconController, String?>(AppIconController.new);

class AppIconController extends AsyncNotifier<String?> {
  @override
  Future<String?> build() => AppIconService.getCurrentIcon();

  Future<void> selectIcon(String? iconName) async {
    final previous = state;
    state = const AsyncLoading();

    try {
      await AppIconService.setAppIcon(iconName);
      if (!ref.mounted) {
        return;
      }
      final currentIcon = await AppIconService.getCurrentIcon();
      if (!ref.mounted) {
        return;
      }
      state = AsyncValue.data(currentIcon);
    } catch (error, stackTrace) {
      state = previous;
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}

class AppIconService {
  AppIconService._();

  static const MethodChannel _channel = MethodChannel(
    'app.cogwheel.conduit/app_icon',
  );

  static bool get isPlatformSupported => Platform.isAndroid || Platform.isIOS;

  static String? normalizeIconName(String? iconName) {
    final normalized = iconName?.trim();
    if (normalized == null || normalized.isEmpty) {
      return null;
    }

    if (!supportedAlternateAppIcons.contains(normalized)) {
      throw ArgumentError.value(
        iconName,
        'iconName',
        'Unsupported alternate app icon.',
      );
    }

    return normalized;
  }

  static Future<String?> getCurrentIcon() async {
    if (!isPlatformSupported) {
      return null;
    }

    try {
      final iconName = await _channel.invokeMethod<String>('getCurrentIcon');
      if (iconName == null || !supportedAlternateAppIcons.contains(iconName)) {
        return null;
      }
      return iconName;
    } on MissingPluginException {
      developer.log(
        'App icon channel is unavailable while reading the current icon.',
        name: 'AppIconService',
      );
      return null;
    }
  }

  static Future<void> setAppIcon(String? iconName) async {
    if (!isPlatformSupported) {
      throw UnsupportedError('Alternate app icons are unavailable here.');
    }
    final normalized = normalizeIconName(iconName);

    await _channel.invokeMethod<void>('setAlternateIcon', {
      'iconName': normalized,
    });
  }
}
