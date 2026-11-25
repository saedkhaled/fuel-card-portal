import 'package:fleet_cards_demo/app/portal_app.dart';
import 'package:fleet_cards_demo/demo/demo_fixtures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixture_assets.dart';
import 'support/memory_preferences.dart';

void main() {
  testWidgets('guards routes, switches direction, resumes and signs out', (
    tester,
  ) async {
    final preferences = MemoryPreferences();
    Future<void> open() async {
      await tester.pumpWidget(
        PortalBootstrap(
          loader: FixtureLoader(FixtureAssets()),
          preferences: preferences,
          now: () => DateTime.utc(2026, 11, 25),
          initialLocation: '/cards',
        ),
      );
      await tester.pumpAndSettle();
    }

    const phone = Key('phone-field');
    const code = Key('code-field');
    await open();
    expect(find.byKey(phone), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byKey(phone))),
      TextDirection.rtl,
    );
    await tester.tap(find.byTooltip('اللغة'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();
    expect(
      Directionality.of(tester.element(find.byKey(phone))),
      TextDirection.ltr,
    );

    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.text('Enter 10 digits starting with 09.'), findsOneWidget);
    await tester.enterText(find.byKey(phone), '٠٩٠٠٠٠٠٠٠٠');
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    expect(find.byKey(code), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(phone), findsOneWidget);
    await tester.tap(find.text('Send code'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(code), '111222');
    await tester.pumpAndSettle();
    expect(find.text('That code does not match. Try again.'), findsOneWidget);
    await tester.enterText(find.byKey(code), '246810');
    await tester.pumpAndSettle();
    expect(find.text('Station alerts'), findsOneWidget);
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    expect(find.text('Fleet overview'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await open();
    expect(find.byKey(phone), findsNothing);
    expect(
      find.text('This section is awaiting implementation.'),
      findsOneWidget,
    );
    await tester.tap(find.byIcon(Icons.menu));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Sign out'));
    await tester.pumpAndSettle();
    expect(find.text('Send code'), findsOneWidget);
    expect(await tester.binding.handlePopRoute(), isFalse);
  });

  testWidgets('failed startup loads after fixture is restored and retried', (
    tester,
  ) async {
    final assets = FixtureAssets();
    final auth = assets.files.remove(FixtureAssets.authPath)!;
    await tester.pumpWidget(
      PortalBootstrap(
        loader: FixtureLoader(assets),
        preferences: MemoryPreferences(),
        now: DateTime.now,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('تعذّر تحميل البيانات التجريبية.'), findsOneWidget);
    assets.files[FixtureAssets.authPath] = auth;
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('phone-field')), findsOneWidget);
  });
}
