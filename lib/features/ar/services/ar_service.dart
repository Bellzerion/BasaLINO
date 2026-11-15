import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

abstract interface class ArAvailabilityService {
  Future<bool> isSupported();
}

class PlatformArService implements ArAvailabilityService {
  const PlatformArService();

  static const MethodChannel _channel = MethodChannel('basalino/ar');

  @override
  Future<bool> isSupported() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return await _channel.invokeMethod<bool>('isSupported') ?? false;
    } on MissingPluginException {
      return false;
    }
  }
}
