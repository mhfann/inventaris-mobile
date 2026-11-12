import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../models/report.dart';
import '../../services/report_service.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_widget.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const _types = ['inventory', 'incoming', 'outgoing'];
  static const _typeLabels = {
    'inventory': 'Inventaris',
    'incoming': 'Masuk',
    'outgoing': 'Keluar',
  };
  static const _periods = ['daily', 'monthly', 'yearly', 'range'];
  static const _periodLabels = {
    'daily': 'Harian',
    'monthly': 'Bulanan',
    'yearly': 'Tahunan',
    'range': 'Rentang Tanggal',
  };
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

  final _service = ReportService();

  String _type = 'inventory';
  String _period = 'daily';
  DateTime _date = DateTime.now();
  DateTime _month = DateTime.now();
  int _year = DateTime.now().year;
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();

  ReportData? _data;
  bool _loading = false;
  String? _error;
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  String get _monthLabel => '${_months[_month.month - 1]} ${_month.year}';

  Future<void> _load() async {
    final requestId = ++_requestId;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.fetch(
        type: _type,
        period: _period,
        date: _date,
        month: _month,
        year: _year,
        from: _from,
        to: _to,
      );
      if (!mounted || requestId != _requestId) return;
      setState(() => _data = data);
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      final message = e.toString();
      setState(() => _error = message);
      // Jika data lama masih tampil, ErrorView tidak muncul -> beri tahu lewat snackbar.
      if (_data != null) {
        showAppSnackBar(context, message, type: AppSnackType.error);
      }
    } finally {
      if (mounted && requestId == _requestId) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  Future<void> _pickMonth() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _month,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pilih Bulan',
    );
    if (picked != null) {
      setState(() => _month = picked);
    }
  }

  Future<void> _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(_year),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      helpText: 'Pilih Tahun',
      initialDatePickerMode: DatePickerMode.year,
    );
    if (picked != null) {
      setState(() => _year = picked.year);
    }
  }

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _from, end: _to),
    );
    if (picked != null) {
      setState(() {
        _from = picked.start;
        _to = picked.end;
      });
    }
  }

  String _formatDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: _buildFilterCard(context),
          ),
          Expanded(
            child: _loading && _data == null
                ? const LoadingWidget(text: 'Memuat laporan...')
                : _error != null && _data == null
                ? ErrorView(message: _error!, onRetry: _load)
                : _buildResult(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              Theme.of(context).dividerTheme.color ??
              Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Jenis Laporan', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: _types
                  .map(
                    (t) =>
                        ButtonSegment(value: t, label: Text(_typeLabels[t]!)),
                  )
                  .toList(),
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
              showSelectedIcon: false,
            ),
          ),
          const SizedBox(height: 16),
          Text('Periode', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _period,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
            items: _periods
                .map(
                  (p) => DropdownMenuItem(
                    value: p,
                    child: Text(_periodLabels[p]!),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _period = v ?? 'daily'),
          ),
          const SizedBox(height: 10),
          _buildPeriodInput(context),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _loading ? null : _load,
              icon: const Icon(PhosphorIcons.arrowsClockwise, size: 18),
              label: const Text('Tampilkan Laporan'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodInput(BuildContext context) {
    final (label, onTap) = switch (_period) {
      'monthly' => (_monthLabel, _pickMonth),
      'yearly' => ('$_year', _pickYear),
      'range' => ('${_formatDate(_from)} s/d ${_formatDate(_to)}', _pickRange),
      _ => (_formatDate(_date), _pickDate),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: InputDecorator(
        decoration: const InputDecoration(
          prefixIcon: Icon(PhosphorIcons.calendarBlank, size: 18),
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(label, style: Theme.of(context).textTheme.titleSmall),
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    final data = _data;
    if (data == null) return const SizedBox.shrink();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _buildSummary(context, data),
          const SizedBox(height: 16),
          Text(
            data.periodLabel,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${data.rangeFrom} s/d ${data.rangeTo}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (data.rows.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(
                    PhosphorIcons.tray,
                    size: 48,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tidak ada data pada periode ini',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            )
          else
            ...data.rows.asMap().entries.map(
              (e) => _ReportRowCard(row: e.value, isInventory: data.isInventory)
                  .animate(delay: (e.key * 30).ms)
                  .fadeIn(duration: 300.ms)
                  .moveY(begin: 8, duration: 300.ms, curve: Curves.easeOut),
            ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, ReportData data) {
    final entries = data.isInventory
        ? [
            ('Total Barang', '${data.totals['items'] ?? 0}'),
            ('Total Stok', '${data.totals['stock'] ?? 0}'),
          ]
        : [
            ('Transaksi', '${data.totals['transactions'] ?? 0}'),
            ('Jumlah Barang', '${data.totals['quantity'] ?? 0}'),
          ];

    return Row(
      children: [
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: context.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entries[i].$1,
                    style: TextStyle(
                      color: context.colors.onPrimary.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    entries[i].$2,
                    style: TextStyle(
                      color: context.colors.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ReportRowCard extends StatelessWidget {
  const _ReportRowCard({required this.row, required this.isInventory});

  final ReportRow row;
  final bool isInventory;

  @override
  Widget build(BuildContext context) {
    final subtitle = isInventory
        ? [row.code, row.category, row.room].whereType<String>().join(' · ')
        : [row.transactionNumber, row.date].whereType<String>().join(' · ');
    final badge = isInventory
        ? '${row.stock} ${row.unit ?? ''}'
        : '${row.quantity}';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: context.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isInventory
                    ? PhosphorIcons.package
                    : PhosphorIcons.arrowsLeftRight,
                size: 20,
                color: context.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.name,
                    style: Theme.of(context).textTheme.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (isInventory && row.condition != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Kondisi: ${row.condition}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  if (!isInventory && row.destination != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Tujuan: ${row.destination}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
                badge,
                style: TextStyle(
                  color: context.success,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
