import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../core/theme/app_theme.dart';
import '../models/item.dart';
import '../models/transaction_filter.dart';
import 'search_select_field.dart';

class TransactionFilterBar extends StatefulWidget {
  const TransactionFilterBar({
    super.key,
    required this.filter,
    required this.onChanged,
    required this.hint,
    required this.loadItems,
  });

  final TransactionFilter filter;
  final ValueChanged<TransactionFilter> onChanged;
  final String hint;
  final Future<List<Item>> Function() loadItems;

  @override
  State<TransactionFilterBar> createState() => _TransactionFilterBarState();
}

class _TransactionFilterBarState extends State<TransactionFilterBar> {
  late final TextEditingController _searchController;
  late String _pendingSearch;
  List<Item> _items = [];
  Future<void>? _itemsLoad;
  bool _sheetOpen = false;

  static final _dateFormat = DateFormat('dd/MM/yyyy');

  @override
  void initState() {
    super.initState();
    _pendingSearch = widget.filter.search ?? '';
    _searchController = TextEditingController(text: _pendingSearch);
    _loadItems();
  }

  /// Muat daftar barang untuk pilihan filter. Pemanggilan yang bersamaan
  /// memakai satu permintaan yang sama, jadi `await` selalu menunggu hasilnya.
  Future<void> _loadItems() {
    return _itemsLoad ??= _fetchItems().whenComplete(() => _itemsLoad = null);
  }

  Future<void> _fetchItems() async {
    try {
      final items = await widget.loadItems();
      if (mounted) setState(() => _items = items);
    } catch (_) {
      // Biarkan daftar terakhir yang berhasil dimuat tetap dipakai.
    }
  }

  @override
  void didUpdateWidget(covariant TransactionFilterBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter.search != widget.filter.search) {
      _pendingSearch = widget.filter.search ?? '';
      if (_searchController.text != _pendingSearch) {
        _searchController.text = _pendingSearch;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch(String value) {
    final text = value.trim();
    _pendingSearch = text;
    widget.onChanged(
      text.isEmpty
          ? widget.filter.copyWith(clearSearch: true)
          : widget.filter.copyWith(search: text),
    );
  }

  Future<void> _openSheet() async {
    // Abaikan ketukan berikutnya selama form filter sedang dibuka/terbuka.
    if (_sheetOpen) return;
    _sheetOpen = true;
    try {
      if (_items.isEmpty) {
        await _loadItems();
      } else {
        // Sudah ada data: buka langsung, segarkan di latar belakang.
        unawaited(_loadItems());
      }
      if (!mounted) return;
      final result = await showModalBottomSheet<TransactionFilter>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) =>
            _FilterSheet(filter: widget.filter, items: _items),
      );
      if (result != null && mounted) widget.onChanged(result);
    } finally {
      _sheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = widget.filter;
    final selectedItem = filter.itemId == null
        ? null
        : _items.where((i) => i.id == filter.itemId).firstOrNull;
    final chips = <Widget>[];

    if (filter.from != null || filter.to != null) {
      final from = filter.from != null
          ? _dateFormat.format(DateTime.parse(filter.from!))
          : '...';
      final to = filter.to != null
          ? _dateFormat.format(DateTime.parse(filter.to!))
          : '...';
      chips.add(
        _FilterChip(
          label: '$from – $to',
          onDelete: () =>
              widget.onChanged(filter.copyWith(clearFrom: true, clearTo: true)),
        ),
      );
    }
    if (selectedItem != null) {
      chips.add(
        _FilterChip(
          label: selectedItem.name,
          onDelete: () => widget.onChanged(filter.copyWith(clearItemId: true)),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (v) => setState(() => _pendingSearch = v),
                  onSubmitted: _applySearch,
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    isDense: true,
                    prefixIcon: const Icon(
                      PhosphorIcons.magnifyingGlass,
                      size: 20,
                    ),
                    suffixIcon: _pendingSearch.isNotEmpty
                        ? IconButton(
                            tooltip: 'Hapus',
                            icon: const Icon(PhosphorIcons.x, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _pendingSearch = '');
                              _applySearch('');
                            },
                          )
                        : null,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _FilterButton(activeCount: filter.activeCount, onTap: _openSheet),
            ],
          ),
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 8, runSpacing: 4, children: chips),
            ),
        ],
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton.filledTonal(
          tooltip: 'Filter',
          onPressed: onTap,
          icon: const Icon(PhosphorIcons.sliders, size: 20),
        ),
        if (activeCount > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$activeCount',
                style: TextStyle(
                  color: context.colors.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onDelete});

  final String label;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // Seluruh chip bisa diketuk untuk menghapus filter, bukan hanya ikon X.
    return Semantics(
      button: true,
      label: 'Hapus filter $label',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onDelete,
        child: Container(
          padding: const EdgeInsets.only(left: 12, right: 4),
          decoration: BoxDecoration(
            color: context.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(PhosphorIcons.x, size: 14, color: context.primary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.filter, required this.items});

  final TransactionFilter filter;
  final List<Item> items;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _search;
  late String? _from;
  late String? _to;
  late int? _itemId;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _search = widget.filter.search;
    _from = widget.filter.from;
    _to = widget.filter.to;
    _itemId = widget.filter.itemId;
    _searchController = TextEditingController(text: _search ?? '');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial =
        DateTime.tryParse(isFrom ? _from ?? _to ?? '' : _to ?? _from ?? '') ??
        DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final value =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {
        if (isFrom) {
          _from = value;
        } else {
          _to = value;
        }
      });
    }
  }

  TransactionFilter _build() => TransactionFilter(
    search: _search?.trim().isEmpty ?? true ? null : _search!.trim(),
    from: _from,
    to: _to,
    itemId: _itemId,
  );

  @override
  Widget build(BuildContext context) {
    final format = DateFormat('dd/MM/yyyy');
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filter Transaksi',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Tutup',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(PhosphorIcons.x),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                autofocus: true,
                controller: _searchController,
                onChanged: (v) => setState(() => _search = v),
                decoration: const InputDecoration(
                  hintText: 'Kata kunci (nomor, nama barang, petugas...)',
                  prefixIcon: Icon(PhosphorIcons.magnifyingGlass),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Dari',
                      value: _from != null
                          ? format.format(DateTime.parse(_from!))
                          : null,
                      onTap: () => _pickDate(isFrom: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'Sampai',
                      value: _to != null
                          ? format.format(DateTime.parse(_to!))
                          : null,
                      onTap: () => _pickDate(isFrom: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SearchSelectField<Item>(
                label: 'Barang',
                hint: 'Semua barang',
                items: widget.items,
                value: _itemId == null
                    ? null
                    : widget.items.where((i) => i.id == _itemId).firstOrNull,
                onChanged: (item) => setState(() => _itemId = item?.id),
                searchText: (i) => '${i.code} — ${i.name}',
                itemBuilder: (i) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    i.name,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  subtitle: Text(
                    i.code,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(_build()),
                child: const Text('Terapkan Filter'),
              ),
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _search = null;
                    _from = null;
                    _to = null;
                    _itemId = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Reset'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(PhosphorIcons.calendarBlank, size: 18),
        ),
        child: Text(
          value ?? 'Semua',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: value != null
                ? Theme.of(context).colorScheme.onSurface
                : Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: value != null ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
