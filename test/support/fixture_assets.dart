import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FixtureAssets extends CachingAssetBundle {
  static const authPath = 'assets/demo/standard/auth.json';
  final files = <String, String>{
    FixtureLoader.manifestPath: '''
      {"schemaVersion":1,"defaultScenario":"standard","scenarios":{
        "standard":{"files":{"auth":"assets/demo/standard/auth.json"}}
      }}
      ''',
    authPath: '''
      {"validitySeconds":300,"resendSeconds":60,"accounts":[
        {"id":"fleet","phone":"0900000000","code":"246810"}
      ]}
      ''',
  };

  @override
  Future<String> loadString(String key, {bool cache = true}) async =>
      files[key] ?? (throw FlutterError('asset unavailable'));

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}
