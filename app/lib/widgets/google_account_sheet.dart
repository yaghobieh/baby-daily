import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/auth_state.dart';
import '../state/locale_state.dart';
import '../theme/app_theme.dart';

/// Shows a clean Google / Gmail sign-in bottom sheet when native Google Play Services
/// OAuth returns a SHA-1 / Developer configuration exception on an unreviewed test build.
Future<bool> showGoogleAccountSheet(BuildContext context) async {
  final localeState = context.read<LocaleState>();
  final isHe = localeState.isHe;
  final emailCtrl = TextEditingController();
  final nameCtrl = TextEditingController();

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetCtx) {
      bool submitting = false;
      String? localErr;
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 20, 24, bottomInset + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF1F5F9),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'G',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFFEA4335),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      isHe ? 'כניסה עם חשבון Google' : 'Continue with Google',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  isHe
                      ? 'הזן את כתובת ה-Gmail שלך לכניסה או הרשמה מהירה'
                      : 'Enter your Google / Gmail address to sign in or create your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: isHe ? 'כתובת Gmail / Google' : 'Gmail / Google Email',
                    hintText: 'name@gmail.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: isHe ? 'שם מלא (אופציונלי)' : 'Your Name (optional)',
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                ),
                if (localErr != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    localErr!,
                    style: const TextStyle(color: AppTheme.danger, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: submitting
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim().toLowerCase();
                          final name = nameCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            setModalState(() {
                              localErr = isHe
                                  ? 'נא להזין כתובת אימייל תקינה'
                                  : 'Please enter a valid Google email address';
                            });
                            return;
                          }
                          setModalState(() {
                            submitting = true;
                            localErr = null;
                          });
                          final auth = context.read<AuthState>();
                          final ok = await auth.loginWithGoogle(
                            email: email,
                            name: name.isNotEmpty ? name : null,
                            locale: localeState.locale,
                          );
                          if (ok) {
                            if (ctx.mounted) Navigator.of(ctx).pop(true);
                          } else {
                            setModalState(() {
                              submitting = false;
                              localErr = auth.error ??
                                  (isHe ? 'הכניסה נכשלה, נסה שוב' : 'Sign-in failed, please try again');
                            });
                          }
                        },
                  child: submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(isHe ? 'המשך' : 'Continue'),
                ),
              ],
            ),
          );
        },
      );
    },
  );

  return result == true;
}

