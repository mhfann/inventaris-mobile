import 'package:flutter/material.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/api/api_client.dart';
import '../../core/api/api_exception.dart';
import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../home/dashboard_screen.dart';

/// Layar yang tampil saat server dalam mode pemeliharaan (HTTP 503).
class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key, this.onResolved});

  /// Dipanggil saat layar ditutup, agar penanganan 503 bisa aktif lagi.
  final VoidCallback? onResolved;

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _checking = false;

  @override
  void dispose() {
    widget.onResolved?.call();
    super.dispose();
  }

  Future<void> _retry() async {
    final auth = context.read<AuthProvider>();
    setState(() => _checking = true);
    try {
      final response = await ApiClient.instance.request('/status');
      final data = response.data;
      if (data is Map<String, dynamic> &&
          data['data'] is Map<String, dynamic>) {
        final threshold =
            (data['data'] as Map<String, dynamic>)['low_stock_threshold'];
        if (threshold is int) {
          AppConfig.lowStockThreshold = threshold;
        }
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _checking = false);
      if (e.statusCode == 503) {
        // Masih dalam maintenance: tetap di layar maintenance.
        return;
      }
      showAppSnackBar(context, e.message, type: AppSnackType.error);
      return;
    }
    // Maintenance sudah selesai.
    // Jika user sedang login, 401 sudah ditangani AuthProvider (kembali ke
    // halaman login), jadi layar ini tidak perlu menavigasi lagi.
    final wasAuthenticated = auth.isAuthenticated;
    try {
      await ApiClient.instance.request('/user');
      // Pulihkan sesi ke AuthProvider. Saat maintenance terjadi ketika
      // aplikasi baru dibuka, sesi belum sempat dipulihkan; tanpa ini
      // Dashboard tampil tanpa nama user dan tanpa hak akses.
      final loggedIn = await auth.restoreSession();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              loggedIn ? const DashboardScreen() : const LoginScreen(),
        ),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 401) {
        if (wasAuthenticated) return;
        // Sesi tidak valid: kembali ke halaman login.
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return;
      }
      setState(() => _checking = false);
      showAppSnackBar(context, e.message, type: AppSnackType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: context.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Icon(
                      PhosphorIcons.wrench,
                      size: 32,
                      color: context.warning,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Sistem Sedang Maintenance',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Layanan sedang dalam mode pemeliharaan. '
                  'Silahkan kembali dalam beberapa saat lagi.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: _checking ? null : _retry,
                  child: _checking
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Coba Lagi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
