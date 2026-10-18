import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'state/auth_state.dart';
import 'state/baby_state.dart';
import 'state/entry_state.dart';
import 'state/locale_state.dart';
import 'state/notification_state.dart';
import 'state/theme_state.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient();
  await apiClient.init();

  final localeState = LocaleState();
  await localeState.init();

  final themeState = ThemeState();
  await themeState.init();

  final authState = AuthState(apiClient);
  await authState.init();

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<LocaleState>.value(value: localeState),
        ChangeNotifierProvider<ThemeState>.value(value: themeState),
        ChangeNotifierProvider<AuthState>.value(value: authState),
        ChangeNotifierProvider<BabyState>(create: (_) => BabyState(apiClient)),
        ChangeNotifierProvider<EntryState>(create: (_) => EntryState(apiClient)),
        ChangeNotifierProvider<NotificationState>(create: (_) => NotificationState(apiClient)),
        ChangeNotifierProvider<ReminderState>(create: (_) => ReminderState(apiClient)),
      ],
      child: const BabyDailyApp(),
    ),
  );
}

class BabyDailyApp extends StatelessWidget {
  const BabyDailyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final localeState = context.watch<LocaleState>();
    final themeState = context.watch<ThemeState>();
    final authState = context.watch<AuthState>();

    return MaterialApp(
      title: 'BabyDaily',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(localeState.locale, themeState.primaryColor),
      locale: localeState.flutterLocale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('he', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: authState.isLoading
          ? const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            )
          : authState.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
