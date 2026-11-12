import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../models/item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/icon_badge.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/search_field.dart';
import 'item_detail_screen.dart';
import 'item_form_screen.dart';

class ItemsScreen extends StatefulWidget {
  const ItemsScreen({super.key});

  @override
  State<ItemsScreen> createState() => _ItemsScreenState();
}

class _ItemsScreenState extends State<ItemsScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _loadingMore = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ItemProvider>().loadItems(refresh: true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    if (value.trim().isEmpty) {
      context.read<ItemProvider>().setSearch('');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      context.read<ItemProvider>().setSearch(value);
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
      final provider = context.read<ItemProvider>();
      try {
        if (provider.hasMore) await provider.loadItems();
      } finally {
        _loadingMore = false;
      }
    });
  }

  Future<void> _confirmDelete(Item item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Barang?'),
        content: Text(
          'Barang "${item.name}" akan dihapus. Tindakan ini tidak bisa dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: context.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    try {
      await context.read<ItemProvider>().deleteItem(item.id);
      if (mounted) _showSnack('Barang berhasil dihapus');
    } catch (e) {
      if (mounted) _showSnack(e.toString(), isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    showAppSnackBar(
      context,
      message,
      type: isError ? AppSnackType.error : AppSnackType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();
    final auth = context.watch<AuthProvider>();
    final canCreate = auth.can('items.create');
    final canEdit = auth.can('items.update') || canCreate;
    final canDelete = auth.can('items.delete');
    final canView = auth.can('items.view');
    final hasSearch =
        _searchController.text.trim().isNotEmpty || provider.lowStockOnly;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchField(
              controller: _searchController,
              hint: 'Cari barang',
              onChanged: _onSearchChanged,
            ),
          ),
          if (provider.lowStockOnly)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.warning.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.warning.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    PhosphorIcons.warningCircle,
                    size: 18,
                    color: context.warning,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menampilkan stok menipis (≤ ${AppConfig.lowStockThreshold})',
                      style: TextStyle(
                        color: context.warning,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () =>
                        context.read<ItemProvider>().setLowStockOnly(false),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        PhosphorIcons.x,
                        size: 18,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: provider.loading && provider.items.isEmpty
                ? const LoadingWidget(text: 'Memuat barang...')
                : provider.error != null && provider.items.isEmpty
                ? ErrorView(
                    message: provider.error!,
                    onRetry: () => provider.loadItems(refresh: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => provider.loadItems(refresh: true),
                    child: provider.items.isEmpty
                        ? _EmptyState(
                            hasSearch: hasSearch,
                            onReset: () {
                              _debounce?.cancel();
                              _searchController.clear();
                              if (provider.lowStockOnly) {
                                provider.setLowStockOnly(false);
                              }
                              provider.setSearch('');
                            },
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                            itemCount:
                                provider.items.length +
                                (provider.hasMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              if (index >= provider.items.length) {
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
                              final item = provider.items[index];
                              return _ItemCard(
                                    item: item,
                                    canEdit: canEdit,
                                    canDelete: canDelete,
                                    onEdit: canEdit
                                        ? () => _openForm(context, item: item)
                                        : null,
                                    onView: canView
                                        ? () => _openDetail(context, item)
                                        : null,
                                    onDelete: () => _confirmDelete(item),
                                  )
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
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context),
              icon: const Icon(PhosphorIcons.plus),
              label: const Text('Barang'),
            )
          : null,
    );
  }

  Future<void> _openForm(BuildContext context, {Item? item}) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));
    if (context.mounted) {
      context.read<ItemProvider>().loadItems(refresh: true);
    }
  }

  Future<void> _openDetail(BuildContext context, Item item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ItemDetailScreen(itemId: item.id)),
    );
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({
    required this.item,
    required this.canEdit,
    required this.canDelete,
    this.onEdit,
    this.onView,
    this.onDelete,
  });

  final Item item;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback? onEdit;
  final VoidCallback? onView;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final lowStock = item.isLowStock;
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: canEdit ? onEdit : onView,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              IconBadge(
                icon: PhosphorIcons.package,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 44,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        item.code,
                        item.category?.name,
                        item.room?.name,
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: (lowStock ? context.warning : context.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${item.stock} ${item.unit ?? ''}',
                  style: TextStyle(
                    color: lowStock ? context.warning : context.success,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              if (canDelete)
                PopupMenuButton<String>(
                  tooltip: 'Aksi',
                  onSelected: (value) {
                    if (value == 'edit') onEdit?.call();
                    if (value == 'delete') onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Hapus'),
                      ),
                  ],
                )
              else if (canEdit)
                IconButton(
                  visualDensity: VisualDensity.compact,
                  onPressed: onEdit,
                  icon: const Icon(PhosphorIcons.caretRight, size: 20),
                  color: context.colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasSearch, required this.onReset});

  final bool hasSearch;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(
          PhosphorIcons.package,
          size: 64,
          color: context.colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            hasSearch ? 'Barang tidak ditemukan' : 'Belum ada barang',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            hasSearch
                ? 'Coba kata kunci lain atau reset pencarian'
                : 'Tambahkan barang pertama Anda',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
        if (hasSearch)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Center(
              child: TextButton.icon(
                onPressed: onReset,
                icon: const Icon(PhosphorIcons.x, size: 18),
                label: const Text('Reset pencarian'),
              ),
            ),
          ),
      ],
    );
  }
}
