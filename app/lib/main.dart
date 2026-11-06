import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';
import 'state/auth_state.dart';
import 'state/baby_state.dart';
import 'state/channel_state.dart';
import 'state/entry_state.dart';
import 'state/locale_state.dart';
import 'state/notification_state.dart';
import 'state/theme_state.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: const Color(0xFFFFF9F4),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Text(
              'BabyDaily Error:\n${details.exceptionAsString()}',
              style: const TextStyle(color: Color(0xFF2B2A3D), fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  };

  final apiClient = ApiClient();
  final localeState = LocaleState();
  final themeState = ThemeState();
  final channelState = ChannelState();
  final authState = AuthState(apiClient);

  Future<void>(() async {
    try {
      await Future.wait([
        apiClient.init(),
        localeState.init(),
        themeState.init(),
        channelState.init(),
      ]).timeout(const Duration(seconds: 4));
    } catch (_) {}
    await authState.init();
  });

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        ChangeNotifierProvider<LocaleState>.value(value: localeState),
        ChangeNotifierProvider<ThemeState>.value(value: themeState),
        ChangeNotifierProvider<ChannelState>.value(value: channelState),
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
      theme: AppTheme.build(Brightness.light, themeState.primaryColor),
      darkTheme: AppTheme.build(Brightness.dark, themeState.primaryColor),
      themeMode: themeState.mode,
      locale: localeState.flutterLocale,
      supportedLocales: const [
        Locale('en', ''),
        Locale('he', ''),
        Locale('es', ''),
        Locale('ru', ''),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: !authState.isInitialized
          ? const Scaffold(
              backgroundColor: Color(0xFFFFF9F4),
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('👶', style: TextStyle(fontSize: 48)),
                    SizedBox(height: 16),
                    CircularProgressIndicator(color: Color(0xFFFF7A59)),
                    SizedBox(height: 12),
                    Text(
                      'BabyDaily v0.1.4',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8C8AA0),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : authState.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen(),
    );
  }
}
