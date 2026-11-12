import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../models/incoming_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../providers/transaction_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/transaction_filter_bar.dart';
import 'transaction_form_screen.dart';

class IncomingScreen extends StatefulWidget {
  const IncomingScreen({super.key});

  @override
  State<IncomingScreen> createState() => _IncomingScreenState();
}

class _IncomingScreenState extends State<IncomingScreen> {
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<TransactionProvider>().loadIncoming(refresh: true);
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
        if (provider.incomingHasMore && !provider.incomingLoading) {
          await provider.loadIncoming(refresh: false);
        }
      } finally {
        _loadingMore = false;
      }
    });
  }

  Future<void> _refresh() async {
    final provider = context.read<TransactionProvider>();
    await provider.loadIncoming(refresh: true);
    if (!mounted) return;
    if (provider.incomingError != null && provider.incoming.isNotEmpty) {
      showAppSnackBar(
        context,
        provider.incomingError!,
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
        provider.incoming.isEmpty &&
        !provider.incomingFilter.isEmpty &&
        !provider.incomingLoading;

    return Scaffold(
      body: Column(
        children: [
          TransactionFilterBar(
            filter: provider.incomingFilter,
            hint: 'Cari barang masuk...',
            loadItems: itemProvider.fetchAllItems,
            onChanged: (f) => provider.setIncomingFilter(f),
          ),
          Expanded(
            child: provider.incomingLoading && provider.incoming.isEmpty
                ? const LoadingWidget(text: 'Memuat barang masuk...')
                : provider.incomingError != null && provider.incoming.isEmpty
                ? ErrorView(
                    message: provider.incomingError!,
                    onRetry: () => provider.loadIncoming(refresh: true),
                  )
                : provider.incoming.isEmpty
                ? Center(
                    child: Text(
                      isEmptyByFilter
                          ? 'Tidak ditemukan dengan filter ini'
                          : 'Belum ada barang masuk',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                      itemCount:
                          provider.incoming.length +
                          (provider.incomingHasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index >= provider.incoming.length) {
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
                        final record = provider.incoming[index];
                        return _IncomingTile(record: record)
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
      floatingActionButton: auth.can('incoming-items.create')
          ? FloatingActionButton.extended(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const TransactionFormScreen(
                      type: TransactionType.incoming,
                    ),
                  ),
                );
                if (context.mounted) {
                  context.read<TransactionProvider>().loadIncoming(
                    refresh: true,
                  );
                  context.read<ItemProvider>().loadItems(refresh: true);
                }
              },
              icon: const Icon(PhosphorIcons.plus),
              label: const Text('Barang Masuk'),
            )
          : null,
    );
  }
}

class _IncomingTile extends StatelessWidget {
  const _IncomingTile({required this.record});

  final IncomingItem record;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            IconBadge(
              icon: PhosphorIcons.arrowDownLeft,
              color: context.success,
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
                color: context.success.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '+${record.quantity}',
                style: TextStyle(
                  color: context.success,
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
