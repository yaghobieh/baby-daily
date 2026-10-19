import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../api/api_client.dart';
import '../../state/locale_state.dart';
import '../../theme/app_theme.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _identifierController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final identifier = _identifierController.text.trim();
    if (identifier.isEmpty) return;

    final s = context.read<LocaleState>().strings;
    final api = context.read<ApiClient>();

    setState(() => _isLoading = true);

    try {
      await api.post('/auth/forgot-password', {
        'identifier': identifier,
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.card(ctx),
            title: Row(
              children: [
                const Text('📬', style: TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Text(
                  s.resetLinkSentTitle,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.ink(ctx)),
                ),
              ],
            ),
            content: Text(
              s.resetLinkSentMessage,
              style: TextStyle(fontSize: 14, color: AppTheme.ink(ctx), height: 1.5),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(s.backToLogin),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.danger,
            content: Text(e.toString()),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleState>().strings;
    final ink = AppTheme.ink(context);
    final card = AppTheme.card(context);
    final line = AppTheme.line(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(s.forgotPasswordTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: line),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Text('🔐', style: TextStyle(fontSize: 32)),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      s.forgotPasswordTitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ink),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      s.forgotPasswordSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _identifierController,
                      keyboardType: TextInputType.emailAddress,
                      style: TextStyle(color: ink),
                      decoration: InputDecoration(
                        labelText: s.emailOrPhone,
                        hintText: 'user@example.com / 0501234567',
                        prefixIcon: const Icon(Icons.alternate_email),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _handleSendResetLink,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(s.sendResetLink),
                    ),
                    const SizedBox(height: 14),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(s.backToLogin),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
