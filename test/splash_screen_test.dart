import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahadi_al_amaliqa/core/providers/core_providers.dart';
import 'package:tahadi_al_amaliqa/core/theme/app_theme.dart';
import 'package:tahadi_al_amaliqa/features/splash/screens/splash_screen.dart';
import 'package:tahadi_al_amaliqa/l10n/app_localizations.dart';

/// Regression coverage for the splash painting into only part of the screen.
///
/// `Scaffold` hands its body *loose* constraints, and a `Stack` whose
/// children are all either positioned or a single non-positioned `Column`
/// sizes itself to that Column — which is only as wide as its widest line of
/// text. Every `Positioned.fill` in the Stack then fills that text-width box
/// instead of the screen, and the remaining screen shows bare Scaffold
/// background. On a phone that reads as the whole app crammed into a column
/// down the left edge.
///
/// The test asserts against the real viewport width rather than any
/// particular widget's width, so it fails for that bug specifically and not
/// for cosmetic layout changes.
void main() {
  const viewport = Size(390, 844);

  Future<void> pumpSplash(WidgetTester tester, {required bool online}) async {
    tester.view.physicalSize = viewport;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          connectivityStatusProvider.overrideWith((ref) => Stream.value(online)),
        ],
        child: MaterialApp(
          theme: AppTheme.light(isArabic: false),
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: const SplashScreen(),
        ),
      ),
    );
    // `pumpAndSettle` can't be used here — the progress indicator spins
    // forever, so the tree never settles. Pump explicit frames instead:
    // one to mount, then past the longest `flutter_animate` entrance
    // (300ms delay + 400ms fade) so its timers don't outlive the tree.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
  }

  group('SplashScreen', () {
    testWidgets('fills the full width of the screen', (tester) async {
      await pumpSplash(tester, online: true);

      // The Stack is what every `Positioned.fill` background sizes against,
      // so this is the measurement that matters.
      final stack = tester.getSize(find.byType(Stack).first);
      expect(
        stack.width,
        viewport.width,
        reason: 'Stack collapsed to its widest text child instead of the screen',
      );
      expect(stack.height, viewport.height);
    });

    testWidgets('paints its gradient edge to edge', (tester) async {
      await pumpSplash(tester, online: true);

      // The gradient is the visible symptom: if it stops short, the user
      // sees bare Scaffold background beside it.
      final gradient = find.byType(DecoratedBox).first;
      expect(tester.getSize(gradient).width, viewport.width);
      expect(tester.getTopLeft(gradient).dx, 0);
      expect(tester.getTopRight(gradient).dx, viewport.width);
    });

    testWidgets('still fills the screen with the longer offline caption', (tester) async {
      // A supplementary check rather than a second reproduction: the
      // offline caption is long enough that it happened to fill a 390pt
      // viewport even while the bug was present. It's here so the offline
      // branch is still pinned to the viewport and not to its own text.
      await pumpSplash(tester, online: false);

      expect(tester.getSize(find.byType(Stack).first).width, viewport.width);
    });
  });
}
