import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/demo_preferences.dart';
import 'app/portal_app.dart';
import 'demo/demo_fixtures.dart';

import 'features/support/support_gemini.dart';

void main() {
  const scenario = String.fromEnvironment('DEMO_SCENARIO');
  runApp(
    PortalBootstrap(
      loader: FixtureLoader(rootBundle),
      preferences: AndroidDemoPreferences(SharedPreferencesAsync()),
      now: DateTime.now,
      scenario: scenario.isEmpty ? null : scenario,
      supportGemini: SupportGemini.configured(),
    ),
  );
}
