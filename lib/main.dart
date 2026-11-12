import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import 'core/api/api_client.dart';
import 'core/api/api_exception.dart';
import 'core/config/app_config.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/item_provider.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/errors/maintenance_screen.dart';
import 'screens/home/dashboard_screen.dart';
import 'widgets/loading_widget.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

bool _maintenanceScreenShowing = false;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ApiClient.instance.onMaintenance = () {
    if (_maintenanceScreenShowing) return;
    final navigator = appNavigatorKey.currentState;
    // Navigator belum siap: jangan nyalakan penanda, supaya 503 berikutnya
    // masih bisa menampilkan layar maintenance.
    if (navigator == null) return;
    _maintenanceScreenShowing = true;
    navigator.pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => MaintenanceScreen(
          onResolved: () => _maintenanceScreenShowing = false,
        ),
      ),
      (route) => false,
    );
  };
  runApp(const InventarisApp());
}

class InventarisApp extends StatelessWidget {
  const InventarisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(
            onSessionExpired: () {
              final navigator = appNavigatorKey.currentState;
              if (navigator == null) return;
              // Layar maintenance (bila ada) ikut terbuang oleh navigasi ini.
              _maintenanceScreenShowing = false;
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ),
        ChangeNotifierProvider(create: (_) => ItemProvider()),
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: MaterialApp(
        title: 'Inventaris Sekolah',
        debugShowCheckedModeBanner: false,
        navigatorKey: appNavigatorKey,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const AppBootstrap(),
      ),
    );
  }
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _boot();
    });
  }

  Future<void> _boot() async {
    final auth = context.read<AuthProvider>();
    try {
      final response = await ApiClient.instance.request('/status');
      _applyStatus(response.data);
    } on ApiException catch (e) {
      if (e.statusCode == 503) {
        // Handler onMaintenance sudah menampilkan layar maintenance.
        return;
      }
    } catch (_) {
      // Gagal mengambil status (jaringan, format, dll.) tidak boleh
      // menghentikan aplikasi: lanjut ke pemulihan sesi.
    }
    // Layar maintenance sudah mengambil alih navigasi.
    if (!mounted || _maintenanceScreenShowing) return;

    bool loggedIn;
    try {
      loggedIn = await auth.restoreSession();
    } catch (_) {
      // Sesi tersimpan tidak bisa dibaca: anggap belum login.
      loggedIn = false;
    }
    if (!mounted || _maintenanceScreenShowing) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            loggedIn ? const DashboardScreen() : const LoginScreen(),
      ),
    );
  }

  void _applyStatus(Object? data) {
    if (data is! Map) return;
    final payload = data['data'];
    if (payload is! Map) return;
    final raw = payload['low_stock_threshold'];
    final int? threshold = switch (raw) {
      int v => v,
      num v => v.toInt(),
      String v => int.tryParse(v.trim()),
      _ => null,
    };
    if (threshold != null && threshold >= 0) {
      AppConfig.lowStockThreshold = threshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: LoadingWidget(text: 'Memuat sesi...'));
  }
}
