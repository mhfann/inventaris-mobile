import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../models/outgoing_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/transaction_filter_bar.dart';
import 'transaction_form_screen.dart';

class OutgoingScreen extends StatefulWidget {
  const OutgoingScreen({super.key});

  @override
  State<OutgoingScreen> createState() => _OutgoingScreenState();
}

class _OutgoingScreenState extends State<OutgoingScreen> {
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().loadOutgoing(refresh: true);
    });
  }

  /// Muat halaman berikutnya di luar fase build.
  void _loadMore() {
    if (_loadingMore) return;
    _loadingMore = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _loadingMore = false;
        return;
      }
      final provider = context.read<TransactionProvider>();
      try {
        if (provider.outgoingHasMore && !provider.outgoingLoading) {
          await provider.loadOutgoing(refresh: false);
        }
      } finally {
        _loadingMore = false;
      }
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<TransactionProvider>();
    await provider.loadOutgoing(refresh: true);
    if (!mounted) return;
    if (provider.outgoingError != null && provider.outgoing.isNotEmpty) {
      showAppSnackBar(
        context,
        provider.outgoingError!,
        type: AppSnackType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final auth = context.watch<AuthProvider>();
    final itemProvider = context.watch<ItemProvider>();
    final isEmptyByFilter =
        provider.outgoing.isEmpty &&
        !provider.outgoingFilter.isEmpty &&
        !provider.outgoingLoading;

    return Scaffold(
      body: Column(
        children: [
          TransactionFilterBar(
            filter: provider.outgoingFilter,
            hint: 'Cari barang keluar...',
            loadItems: itemProvider.fetchAllItems,
            onChanged: (f) => provider.setOutgoingFilter(f),
          ),
          Expanded(
            child: provider.outgoingLoading && provider.outgoing.isEmpty
                ? const LoadingWidget(text: 'Memuat barang keluar...')
                : provider.outgoingError != null && provider.outgoing.isEmpty
                ? ErrorView(
                    message: provider.outgoingError!,
                    onRetry: () => provider.loadOutgoing(refresh: true),
                  )
                : provider.outgoing.isEmpty
                ? Center(
                    child: Text(
                      isEmptyByFilter
                          ? 'Tidak ditemukan dengan filter ini'
                          : 'Belum ada barang keluar',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount:
                          provider.outgoing.length +
                          (provider.outgoingHasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= provider.outgoing.length) {
                          _loadMore();
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          );
                        }
                        final record = provider.outgoing[index];
                        return _OutgoingTile(record: record)
                            .animate(delay: (index * 30).ms)
                            .fadeIn(duration: 300.ms)
                            .moveY(
                              begin: 8,
                              duration: 300.ms,
                              curve: Curves.easeOut,
                            );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: auth.can('outgoing-items.create')
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(
                      type: TransactionType.outgoing,
                    ),
                  ),
                );
                if (context.mounted) {
                  context.read<TransactionProvider>().loadOutgoing(
                    refresh: true,
                  );
                  context.read<ItemProvider>().loadItems(refresh: true);
                }
              },
              icon: const Icon(PhosphorIcons.plus),
              label: const Text('Barang Keluar'),
            )
          : null,
    );
  }
}

class _OutgoingTile extends StatelessWidget {
  const _OutgoingTile({required this.record});

  final OutgoingItem record;

  @override
  Widget build(BuildContext context) {
    final destination =
        record.destination != null && record.destination!.isNotEmpty
        ? record.destination
        : null;

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconBadge(
              icon: PhosphorIcons.arrowUpRight,
              color: context.danger,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    record.item?.name ?? 'Barang',
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      record.transactionNumber,
                      record.date,
                      if (destination != null) '→ $destination',
                      record.createdBy,
                    ].whereType<String>().join(' · '),
                    style: Theme.of(context).textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.danger.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '-${record.quantity}',
                style: TextStyle(
                  color: context.danger,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
