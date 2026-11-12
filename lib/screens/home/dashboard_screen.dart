import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../models/dashboard.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/stat_card.dart';
import '../items/items_screen.dart';
import '../master/master_screen.dart';
import '../profile/profile_screen.dart';
import '../reports/report_screen.dart';
import '../transactions/transactions_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<ItemProvider>();
      provider.loadReferences();
      _loadDashboard(provider);
    });
  }

  Future<void> _loadDashboard(ItemProvider provider) async {
    try {
      await provider.loadDashboard();
      if (mounted && _error != null) setState(() => _error = null);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ItemProvider>();
    final isAdmin = auth.user?.roles.contains('admin') ?? false;

    final screens = [
      _DashboardTab(
        provider: provider,
        error: _error,
        userName: auth.user?.name,
        canReports: auth.can('reports.view'),
        onLowStockSeeAll: () {
          setState(() => _selectedIndex = 1);
          provider.setLowStockOnly(true);
        },
      ),
      const ItemsScreen(),
      if (isAdmin) const MasterScreen(),
      const TransactionsScreen(),
      const ProfileScreen(),
    ];

    final destinations = [
      const NavigationDestination(
        icon: Icon(PhosphorIcons.squaresFour),
        selectedIcon: Icon(PhosphorIcons.squaresFour),
        label: 'Dashboard',
      ),
      const NavigationDestination(
        icon: Icon(PhosphorIcons.package),
        selectedIcon: Icon(PhosphorIcons.package),
        label: 'Barang',
      ),
      if (isAdmin)
        const NavigationDestination(
          icon: Icon(PhosphorIcons.gridFour),
          selectedIcon: Icon(PhosphorIcons.gridFour),
          label: 'Master',
        ),
      const NavigationDestination(
        icon: Icon(PhosphorIcons.arrowsLeftRight),
        selectedIcon: Icon(PhosphorIcons.arrowsLeftRight),
        label: 'Transaksi',
      ),
      const NavigationDestination(
        icon: Icon(PhosphorIcons.userCircle),
        selectedIcon: Icon(PhosphorIcons.userCircle),
        label: 'Profil',
      ),
    ];

    final titles = [
      'Dashboard',
      'Barang',
      if (isAdmin) 'Master',
      'Transaksi',
      'Profil',
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(titles[_selectedIndex]),
      ),
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) =>
            setState(() => _selectedIndex = index),
        destinations: destinations,
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab({
    required this.provider,
    this.error,
    this.userName,
    this.canReports = false,
    this.onLowStockSeeAll,
  });

  final ItemProvider provider;
  final String? error;
  final String? userName;
  final bool canReports;
  final VoidCallback? onLowStockSeeAll;

  static const _days = [
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];
  static const _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  Future<void> _reload() async {
    try {
      await provider.loadDashboard();
    } catch (_) {}
  }

  String _dateLabel() {
    final now = DateTime.now();
    return '${_days[now.weekday - 1]}, ${now.day} ${_months[now.month - 1]} ${now.year}';
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    return hour < 11
        ? 'Selamat pagi'
        : hour < 15
        ? 'Selamat siang'
        : hour < 19
        ? 'Selamat sore'
        : 'Selamat malam';
  }

  @override
  Widget build(BuildContext context) {
    if (provider.dashboardLoading && provider.dashboard == null) {
      return const LoadingWidget(text: 'Memuat dashboard...');
    }
    if (error != null) {
      return ErrorView(
        message: error!,
        onRetry: () => provider.loadDashboard(),
      );
    }

    final dashboard = provider.dashboard;
    if (dashboard == null) {
      return const LoadingWidget();
    }

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.pagePadding,
          8,
          AppTheme.pagePadding,
          24,
        ),
        children: [
          _buildHero(context, dashboard),
          const SizedBox(height: AppTheme.sectionGap),
          _buildStats(context, dashboard),
          const SizedBox(height: AppTheme.sectionGap),
          if (canReports) ...[
            _buildReportCard(context),
            const SizedBox(height: AppTheme.sectionGap),
          ],
          _buildLowStockSection(context, dashboard, onSeeAll: onLowStockSeeAll),
        ],
      ),
    );
  }

  Widget _buildHero(BuildContext context, DashboardData dashboard) {
    final theme = Theme.of(context);
    return Container(
          padding: const EdgeInsets.all(AppTheme.cardPadding),
          decoration: BoxDecoration(
            color: context.colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: theme.dividerTheme.color ?? Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -18,
                right: -18,
                child: Icon(
                  PhosphorIcons.package,
                  size: 120,
                  color: context.primary.withValues(alpha: 0.06),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_dateLabel(), style: theme.textTheme.bodySmall),
                  const SizedBox(height: 12),
                  Text('${_greeting()},', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    userName ?? 'Pengguna',
                    style: theme.textTheme.displaySmall?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: context.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${dashboard.stats.totalItems} barang terdaftar',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: context.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .moveY(begin: 10, duration: 400.ms, curve: Curves.easeOut);
  }

  Widget _buildStats(BuildContext context, DashboardData dashboard) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: AppTheme.gapSm,
      crossAxisSpacing: AppTheme.gapSm,
      mainAxisExtent: 132,
      children: [
        StatCard(
          icon: PhosphorIcons.package,
          label: 'Total Barang',
          value: '${dashboard.stats.totalItems}',
        ),
        StatCard(
          icon: PhosphorIcons.tag,
          label: 'Kategori',
          value: '${dashboard.stats.totalCategories}',
        ),
        StatCard(
          icon: PhosphorIcons.building,
          label: 'Ruangan',
          value: '${dashboard.stats.totalRooms}',
        ),
        StatCard(
          icon: PhosphorIcons.arrowsLeftRight,
          label: 'Masuk / Keluar',
          value:
              '${dashboard.stats.totalIncoming} / ${dashboard.stats.totalOutgoing}',
        ),
      ],
    );
  }

  Widget _buildReportCard(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ReportScreen())),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(PhosphorIcons.chartBar, color: context.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Laporan',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Inventaris, barang masuk & keluar',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Icon(
              PhosphorIcons.caretRight,
              color: context.colors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLowStockSection(
    BuildContext context,
    DashboardData dashboard, {
    VoidCallback? onSeeAll,
  }) {
    final theme = Theme.of(context);
    final items = dashboard.lowStockItems;
    final onWarning = theme.brightness == Brightness.light
        ? Colors.white
        : const Color(0xFF101218);
    const maxVisible = 4;
    final visible = items.take(maxVisible).toList();

    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: theme.dividerTheme.color ?? Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: context.warning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  PhosphorIcons.warningCircle,
                  size: 20,
                  color: context.warning,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stok Menipis', style: theme.textTheme.titleMedium),
                    Text(
                      'Sisa stok ${AppConfig.lowStockThreshold} atau kurang',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (items.isNotEmpty)
                Text(
                  '${items.length} barang',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: context.warning,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: context.success.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.checkCircle,
                    size: 28,
                    color: context.success,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Semua stok aman',
                    style: TextStyle(color: context.success),
                  ),
                ],
              ),
            )
          else ...[
            ...visible.map(
              (item) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: theme.dividerTheme.color ?? Colors.transparent,
                  ),
                ),
                child: Row(
                  children: [
                    IconBadge(
                      icon: PhosphorIcons.package,
                      color: theme.colorScheme.onSurfaceVariant,
                      size: 44,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(item.code, style: theme.textTheme.bodySmall),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: context.warning,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.stock} ${item.unit ?? ''}',
                        style: TextStyle(
                          color: onWarning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (items.length > maxVisible && onSeeAll != null)
              Center(
                child: TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(foregroundColor: context.primary),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Lihat semua'),
                      SizedBox(width: 4),
                      Icon(PhosphorIcons.caretRight, size: 16),
                    ],
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
