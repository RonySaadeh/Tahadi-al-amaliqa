import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tahadi_al_amaliqa/core/theme/app_colors.dart';
import 'package:tahadi_al_amaliqa/core/theme/app_theme.dart';
import 'package:tahadi_al_amaliqa/core/utils/rank_tier.dart';
import 'package:tahadi_al_amaliqa/core/widgets/arena_panel.dart';
import 'package:tahadi_al_amaliqa/core/widgets/giants_logo.dart';
import 'package:tahadi_al_amaliqa/core/widgets/rank_badge.dart';
import 'package:tahadi_al_amaliqa/core/widgets/slab_button.dart';
import 'package:tahadi_al_amaliqa/data/models/leaderboard_entry_model.dart';
import 'package:tahadi_al_amaliqa/features/duel/widgets/answer_option_tile.dart';
import 'package:tahadi_al_amaliqa/features/duel/widgets/arena_hud.dart';
import 'package:tahadi_al_amaliqa/features/duel/widgets/duel_timer.dart';
import 'package:tahadi_al_amaliqa/features/leaderboard/widgets/leaderboard_podium.dart';
import 'package:tahadi_al_amaliqa/features/profile/widgets/stat_tile.dart';
import 'package:tahadi_al_amaliqa/l10n/app_localizations.dart';

/// Smoke coverage for the arena design system.
///
/// These components lean on `Stack`, `Transform`, `ClipPath` and negative
/// offsets far more than the card layouts they replaced, and the failure
/// mode of that style is a `RenderFlex` overflow with a long name or a
/// narrow screen — something `flutter analyze` cannot see. Every widget test
/// here renders at a real phone viewport and asserts nothing threw.
void main() {
  /// Wraps a widget in the app's real theme + localizations at a 390x844
  /// phone viewport, so tests fail on the same constraints a device has.
  Future<void> pumpPhone(
    WidgetTester tester,
    Widget child, {
    bool isArabic = false,
    Color background = AppColors.arenaDark,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(isArabic: isArabic),
        locale: Locale(isArabic ? 'ar' : 'en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(backgroundColor: background, body: child),
      ),
    );
    await tester.pump();
  }

  LeaderboardEntryModel entry(String name, int elo) => LeaderboardEntryModel(
    uid: name,
    displayName: name,
    elo: elo,
    wins: 10,
    losses: 4,
  );

  group('RankTier', () {
    test('maps ELO onto the right tier at every boundary', () {
      expect(RankTier.forElo(0), RankTier.noviceClay);
      expect(RankTier.forElo(500), RankTier.noviceClay);
      expect(RankTier.forElo(501), RankTier.bronzeSpartan);
      expect(RankTier.forElo(1200), RankTier.bronzeSpartan);
      expect(RankTier.forElo(1201), RankTier.silverGladiator);
      expect(RankTier.forElo(2000), RankTier.silverGladiator);
      expect(RankTier.forElo(2001), RankTier.goldTitan);
      expect(RankTier.forElo(3000), RankTier.goldTitan);
      expect(RankTier.forElo(3001), RankTier.colossusMythic);
      expect(RankTier.forElo(999999), RankTier.colossusMythic);
    });

    test('progress stays within 0..1 and fills across the tier', () {
      expect(RankTier.bronzeSpartan.progress(501), closeTo(0, 0.01));
      expect(RankTier.bronzeSpartan.progress(1200), closeTo(1, 0.01));
      // Out-of-tier values must still clamp rather than overflow a bar.
      expect(RankTier.bronzeSpartan.progress(-500), 0);
      expect(RankTier.bronzeSpartan.progress(99999), 1);
      expect(RankTier.colossusMythic.progress(3001), 1);
    });

    test('top tier reports no distance left to climb', () {
      expect(RankTier.colossusMythic.isMax, isTrue);
      expect(RankTier.colossusMythic.eloToNext(5000), 0);
      expect(RankTier.goldTitan.eloToNext(2900), 101);
    });
  });

  group('SlabButton', () {
    testWidgets('travels down on press and back up on release', (tester) async {
      var taps = 0;
      await pumpPhone(
        tester,
        Center(child: SlabButton(label: 'DUEL', onPressed: () => taps++)),
      );

      Matrix4 transform() => tester
          .widget<AnimatedContainer>(find.byType(AnimatedContainer))
          .transform!;

      expect(transform().getTranslation().y, 0);

      final gesture = await tester.startGesture(tester.getCenter(find.text('DUEL')));
      await tester.pump(const Duration(milliseconds: 120));
      expect(transform().getTranslation().y, greaterThan(0));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 120));
      expect(transform().getTranslation().y, 0);
      expect(taps, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('disabled button ignores taps', (tester) async {
      await pumpPhone(
        tester,
        const Center(child: SlabButton(label: 'DUEL', onPressed: null)),
      );
      await tester.tap(find.text('DUEL'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });

  group('AnswerOptionTile', () {
    testWidgets('renders every visual state without overflowing', (tester) async {
      for (final state in AnswerTileVisualState.values) {
        await pumpPhone(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: AnswerOptionTile(
              label: 'The Treaty of Westphalia, signed in 1648 in Osnabruck',
              indexLabel: 'A',
              visualState: state,
              onTap: () {},
            ),
          ),
        );
        await tester.pump(const Duration(milliseconds: 400));
        expect(tester.takeException(), isNull, reason: 'state $state overflowed');
      }
    });
  });

  group('ArenaHud', () {
    testWidgets('long display names ellipsize instead of overflowing', (tester) async {
      await pumpPhone(
        tester,
        const ArenaHud(
          myName: 'Bartholomew Maximilian The Third',
          myScore: 1250,
          opponentName: 'Konstantinos Papadopoulos Jr',
          opponentScore: 980,
          center: ClashMark(),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('handles an empty name without crashing on the initial', (tester) async {
      await pumpPhone(
        tester,
        const ArenaHud(
          myName: '',
          myScore: 0,
          opponentName: '   ',
          opponentScore: 0,
          center: ClashMark(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('?'), findsNWidgets(2));
    });
  });

  group('DuelTimer', () {
    // The widget derives its remaining time from `DateTime.now()`, which
    // FakeAsync does not advance — so these drive it by choosing where
    // `roundStartedAt` sits relative to real now, not by pumping time
    // forward.
    testWidgets('rounds the remaining seconds up rather than truncating', (tester) async {
      await pumpPhone(
        tester,
        Center(
          child: DuelTimer(
            // Kept above the 5s urgent threshold on purpose: below it the
            // ring starts an endlessly repeating pulse, which leaves a
            // pending timer and fails the test for unrelated reasons.
            roundStartedAt: DateTime.now().subtract(const Duration(seconds: 2)),
            timeLimitSeconds: 10,
          ),
        ),
      );

      // Just under 8s left. Truncation would render "7" here, and at the end
      // of a round would leave "0" on screen for a full second.
      expect(find.text('8'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('fires onTimeUp exactly once for an already-expired round', (tester) async {
      var timeUpCalls = 0;
      await pumpPhone(
        tester,
        Center(
          child: DuelTimer(
            roundStartedAt: DateTime.now().subtract(const Duration(seconds: 15)),
            timeLimitSeconds: 10,
            onTimeUp: () => timeUpCalls++,
          ),
        ),
      );

      expect(find.text('0'), findsOneWidget);

      // Several ticks pass; the callback must not repeat, or a duel would
      // submit a blank answer over and over.
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(seconds: 1));
      }
      expect(timeUpCalls, 1);
      expect(tester.takeException(), isNull);
    });
  });

  group('LeaderboardPodium', () {
    testWidgets('degrades cleanly with one, two or three entries', (tester) async {
      for (var count = 1; count <= 3; count++) {
        final entries = [
          entry('Maximus', 3420),
          entry('Sophia', 2890),
          entry('Tarik', 2650),
        ].take(count).toList();

        await pumpPhone(
          tester,
          LeaderboardPodium(entries: entries, myUid: 'Sophia', onTap: (_) {}),
        );
        expect(tester.takeException(), isNull, reason: 'podium broke with $count entries');
        expect(find.text('Maximus'), findsOneWidget);
      }
    });

    testWidgets('renders nothing when the board is empty', (tester) async {
      await pumpPhone(
        tester,
        LeaderboardPodium(entries: const [], myUid: null, onTap: (_) {}),
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('Brand and layout primitives', () {
    testWidgets('lockup renders in both scripts', (tester) async {
      for (final isArabic in [false, true]) {
        await pumpPhone(tester, const Center(child: GiantsLockup()), isArabic: isArabic);
        await tester.pump(const Duration(milliseconds: 300));
        expect(tester.takeException(), isNull, reason: 'lockup broke (isArabic: $isArabic)');
      }
    });

    testWidgets('arena panel clips and lays out its child', (tester) async {
      await pumpPhone(
        tester,
        const ArenaPanel(
          padding: EdgeInsets.all(24),
          child: Text('ARENA', style: TextStyle(color: Colors.white)),
        ),
      );
      expect(find.text('ARENA'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clash backdrop paints at any size', (tester) async {
      await pumpPhone(tester, const SizedBox.expand(child: ClashBackdrop()));
      expect(tester.takeException(), isNull);
    });

    testWidgets('rank badge and progress bar render for every tier', (tester) async {
      for (final tier in RankTier.values) {
        await pumpPhone(
          tester,
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RankBadge(tier: tier),
              const SizedBox(height: 8),
              RankProgressBar(tier: tier, elo: tier.floor + 10),
            ],
          ),
        );
        expect(tester.takeException(), isNull, reason: 'tier $tier broke');
      }
    });

    testWidgets('stat tiles render in both emphases', (tester) async {
      await pumpPhone(
        tester,
        const SizedBox(
          height: 108,
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: StatTile(
                  label: 'Wins',
                  value: '184',
                  emphasis: StatEmphasis.hero,
                  icon: Icons.military_tech_rounded,
                ),
              ),
              Expanded(child: StatTile(label: 'Current streak', value: '7')),
            ],
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
