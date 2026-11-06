import 'forgot_password_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../state/auth_state.dart';
import '../../state/locale_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/google_account_sheet.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    final auth = context.read<AuthState>();
    final s = context.read<LocaleState>().strings;

    final id = _identifierController.text.trim();
    final pwd = _passwordController.text;

    if (id.isEmpty || pwd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(s.emailOrPhone)),
      );
      return;
    }

    final success = await auth.login(id, pwd);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? s.errorOccurred)),
      );
    }
  }

  Future<void> _handleGoogleButton(bool isHe) async {
    final auth = context.read<AuthState>();
    final localeState = context.read<LocaleState>();
    try {
      await auth.signInWithGoogle(locale: localeState.locale);
    } catch (e) {
      if (mounted) {
        await showGoogleAccountSheet(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final localeState = context.watch<LocaleState>();
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            tooltip: s.language,
            onSelected: (lang) => localeState.setLocale(lang),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'he', child: Text('עברית')),
              PopupMenuItem(value: 'en', child: Text('English')),
              PopupMenuItem(value: 'es', child: Text('Español')),
              PopupMenuItem(value: 'ru', child: Text('Русский')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.language, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    localeState.currentLanguageName,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  const Icon(Icons.arrow_drop_down, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primary, width: 2),
                      ),
                      alignment: Alignment.center,
                      child: const Text('👶', style: TextStyle(fontSize: 42)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    s.appName,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    s.loginSubtitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: AppTheme.textMuted),
                  ),
                  const SizedBox(height: 36),
                  TextField(
                    controller: _identifierController,
                    decoration: InputDecoration(
                      labelText: s.emailOrPhone,
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: s.password,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text(s.forgotPassword, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleLogin,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(s.login),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Expanded(child: Divider()),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          localeState.isHe ? 'או' : 'OR',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textMuted),
                        ),
                      ),
                      const Expanded(child: Divider()),
                    ],
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF1F2937),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                      side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: auth.isLoading ? null : () => _handleGoogleButton(localeState.isHe),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFFEA4335),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          localeState.isHe ? 'המשך עם Google / Gmail' : 'Continue with Google',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      );
                    },
                    child: Text(s.noAccount),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'v0.1.4',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
