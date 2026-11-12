import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/widgets/custom_snackbar.dart';
import '../../services/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final _service = AuthService();

  bool _loading = false;
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validateNew(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password baru wajib diisi';
    }
    if (value.length < 8) {
      return 'Minimal 8 karakter';
    }
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Harus mengandung huruf besar, huruf kecil, dan angka';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi password wajib diisi';
    }
    if (value != _newController.text) {
      return 'Konfirmasi password tidak cocok';
    }
    return null;
  }

  /// Label kecil statis di atas field — selalu terlihat, tidak jadi placeholder.
  Widget _buildFieldLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required ValueChanged<bool> onToggle,
    String? hint,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: IconButton(
              onPressed: () => onToggle(!obscure),
              icon: Icon(
                obscure ? PhosphorIcons.eyeSlash : PhosphorIcons.eye,
                size: 20,
              ),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      await _service.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      showAppSnackBar(
        context,
        'Password berhasil diubah',
        type: AppSnackType.success,
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(context, e.toString(), type: AppSnackType.error);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ganti Password')),
      body:
          SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPasswordField(
                        label: 'Password saat ini',
                        controller: _currentController,
                        obscure: _obscureCurrent,
                        onToggle: (v) => setState(() => _obscureCurrent = v),
                        hint: 'Password yang sedang aktif',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Password saat ini wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        label: 'Password baru',
                        controller: _newController,
                        obscure: _obscureNew,
                        onToggle: (v) => setState(() => _obscureNew = v),
                        hint: 'Minimal 8 karakter',
                        validator: _validateNew,
                      ),
                      const SizedBox(height: 12),
                      _buildPasswordField(
                        label: 'Konfirmasi password baru',
                        controller: _confirmController,
                        obscure: _obscureConfirm,
                        onToggle: (v) => setState(() => _obscureConfirm = v),
                        hint: 'Ulangi password baru',
                        validator: _validateConfirm,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Password harus minimal 8 karakter, mengandung huruf besar, '
                        'huruf kecil, dan angka.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: _loading ? null : _submit,
                        icon: _loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(PhosphorIcons.floppyDisk, size: 20),
                        label: const Text('Simpan Password'),
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .moveY(begin: 8, duration: 350.ms, curve: Curves.easeOut),
    );
  }
}
