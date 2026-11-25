import 'package:flutter/services.dart';

class AndroidFileActions {
  const AndroidFileActions();

  static const channel = MethodChannel('com.example.fleet_cards_demo/exports');

  Future<bool> send({
    required String name,
    required String mime,
    required Uint8List bytes,
    required bool share,
  }) async =>
      await channel.invokeMethod<bool>(share ? 'share' : 'save', {
        'name': name,
        'mime': mime,
        'bytes': bytes,
      }) ??
      false;

  Future<String?> appVersion() => channel.invokeMethod<String>('appVersion');
}
