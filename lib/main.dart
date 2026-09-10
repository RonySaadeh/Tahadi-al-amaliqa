import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'features/home/home_controller.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';

/// Run with `--dart-define=USE_FIREBASE_EMULATOR=true` to point the app at
/// the local Firebase emulator suite instead of your real project — see
/// SETUP.md / RUN_WHEN_HOME.md for the exact command. Defaults to false so
/// a plain `flutter run` always talks to your real Firebase project.
const bool _useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');

/// `10.0.2.2` is how the Android emulator reaches the host machine's
/// `localhost`; iOS simulators and desktop can use `localhost` directly.
const String _emulatorHost = String.fromEnvironment(
  'EMULATOR_HOST',
  defaultValue: 'localhost',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // `firebase_options.dart` is generated locally by `flutterfire configure`
  // (see RUN_WHEN_HOME.md) and is intentionally NOT committed to git, so
  // this import will show as unresolved until you run that command once.
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (_useFirebaseEmulator) {
    await FirebaseAuth.instance.useAuthEmulator(_emulatorHost, 9099);
    FirebaseFirestore.instance.useFirestoreEmulator(_emulatorHost, 8080);
    FirebaseFunctions.instance.useFunctionsEmulator(_emulatorHost, 5001);
  }

  runApp(const ProviderScope(child: TahadiApp()));
}

class TahadiApp extends ConsumerWidget {
  const TahadiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    // Arabic is the primary/default locale; English is fully supported.
    // Reflects the signed-in player's stored `locale` preference (see
    // `features/profile`) once their user doc has loaded — defaults to
    // Arabic before that, and for a signed-out user. `AppLocalizations` is
    // generated from lib/l10n/app_*.arb — see l10n.yaml. Flutter
    // automatically flips the whole widget tree to RTL for Arabic via the
    // `Directionality` inherited from `Locale`, so individual screens don't
    // need manual RTL handling.
    final preferredLocale = ref.watch(currentUserProvider).value?.locale;
    final locale = preferredLocale == 'en'
        ? const Locale('en')
        : const Locale('ar');

    return MaterialApp.router(
      title: 'تحدي العمالقة',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
