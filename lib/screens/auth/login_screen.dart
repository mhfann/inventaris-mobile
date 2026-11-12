import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/custom_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../home/dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    // Cegah login ganda (mis. Enter ditekan lagi saat masih memproses).
    if (auth.loading) return;
    final success = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (route) => false,
      );
    } else {
      showAppSnackBar(
        context,
        auth.error ?? 'Gagal login. Periksa email dan password Anda.',
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: AutofillGroup(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                            child: Container(
                              width: 72,
                              height: 72,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.10,
                                ),
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                PhosphorIcons.package,
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                            begin: const Offset(0.9, 0.9),
                            duration: 400.ms,
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 24),
                      Text(
                            'Selamat Datang',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                          )
                          .animate(delay: 100.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: 8,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 8),
                      Text(
                            'Masuk untuk mengelola inventaris sekolah',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium,
                          )
                          .animate(delay: 180.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: 8,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 36),
                      TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.username],
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(PhosphorIcons.envelope),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Email wajib diisi';
                              if (!v.trim().contains('@'))
                                return 'Format email tidak valid';
                              return null;
                            },
                          )
                          .animate(delay: 260.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: 12,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 16),
                      TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            textInputAction: TextInputAction.done,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: Icon(PhosphorIcons.lockSimple),
                              suffixIcon: IconButton(
                                tooltip: _obscure
                                    ? 'Tampilkan password'
                                    : 'Sembunyikan password',
                                icon: Icon(
                                  _obscure
                                      ? PhosphorIcons.eye
                                      : PhosphorIcons.eyeSlash,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Password wajib diisi';
                              return null;
                            },
                            onFieldSubmitted: (_) => _submit(),
                          )
                          .animate(delay: 340.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: 12,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                      const SizedBox(height: 28),
                      FilledButton(
                            onPressed: auth.loading ? null : _submit,
                            child: auth.loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text('Masuk'),
                          )
                          .animate(delay: 420.ms)
                          .fadeIn(duration: 400.ms)
                          .moveY(
                            begin: 12,
                            duration: 400.ms,
                            curve: Curves.easeOut,
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
