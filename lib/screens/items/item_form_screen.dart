import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../models/item.dart';
import '../../providers/item_provider.dart';

const _conditions = ['Baik', 'Rusak Ringan', 'Rusak Berat', 'Hilang'];

class ItemFormScreen extends StatefulWidget {
  const ItemFormScreen({super.key, this.item});

  final Item? item;

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  late final TextEditingController _nameController;
  late final TextEditingController _brandController;
  late final TextEditingController _unitController;
  late final TextEditingController _yearController;
  late final TextEditingController _stockController;
  late final TextEditingController _descriptionController;

  int? _categoryId;
  int? _roomId;
  String _condition = 'Baik';
  bool _submitting = false;
  String? _serverError;

  bool get _isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _unitController = TextEditingController(text: item?.unit ?? '');
    _yearController = TextEditingController(text: item?.acquisitionYear ?? '');
    _stockController = TextEditingController(
      text: item?.stock.toString() ?? '0',
    );
    _descriptionController = TextEditingController(
      text: item?.description ?? '',
    );
    _categoryId = item?.categoryId;
    _roomId = item?.roomId;
    _condition = item?.condition ?? 'Baik';

    // Pastikan daftar kategori & ruangan tersedia untuk dropdown.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ItemProvider>();
      if ((provider.categories.isEmpty || provider.rooms.isEmpty) &&
          !provider.referencesLoading) {
        provider.loadReferences();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _unitController.dispose();
    _yearController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _buildPayload() => {
    'name': _nameController.text.trim(),
    'category_id': _categoryId,
    'room_id': _roomId,
    'brand': _brandController.text.trim().isEmpty
        ? null
        : _brandController.text.trim(),
    'unit': _unitController.text.trim(),
    'acquisition_year': _yearController.text.trim().isEmpty
        ? null
        : _yearController.text.trim(),
    'condition': _condition,
    'stock': int.tryParse(_stockController.text.trim()) ?? 0,
    'description': _descriptionController.text.trim().isEmpty
        ? null
        : _descriptionController.text.trim(),
  };

  void _scrollToTop() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });

    final provider = context.read<ItemProvider>();
    final item = widget.item;
    try {
      if (item != null) {
        await provider.updateItem(item.id, _buildPayload());
      } else {
        await provider.createItem(_buildPayload());
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _serverError = e.toString());
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToTop());
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _buildSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
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

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? hint,
    int? maxLines,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          inputFormatters: inputFormatters,
          decoration: InputDecoration(hintText: hint),
          validator: validator,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItemProvider>();

    // Nilai awal dropdown harus ada di daftar item, kalau tidak -> assertion.
    final categoryValue = provider.categories.any((c) => c.id == _categoryId)
        ? _categoryId
        : null;
    final roomValue = provider.rooms.any((r) => r.id == _roomId)
        ? _roomId
        : null;
    final conditionOptions = _conditions.contains(_condition)
        ? _conditions
        : [..._conditions, _condition];

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Barang' : 'Tambah Barang')),
      body:
          SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_serverError != null) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.danger.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                PhosphorIcons.warningCircle,
                                size: 20,
                                color: context.danger,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _serverError!,
                                  style: TextStyle(color: context.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildSection('INFORMASI DASAR'),
                      _buildField(
                        label: 'Nama Barang',
                        controller: _nameController,
                        hint: 'Contoh: Laptop Acer Aspire 5',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nama wajib diisi'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Kategori'),
                                DropdownButtonFormField<int>(
                                  key: ValueKey(
                                    'kategori-${provider.categories.length}',
                                  ),
                                  isExpanded: true,
                                  initialValue: categoryValue,
                                  hint: const Text('-- Pilih Kategori --'),
                                  items: provider.categories
                                      .map(
                                        (c) => DropdownMenuItem(
                                          value: c.id,
                                          child: Text(c.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) =>
                                      setState(() => _categoryId = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildFieldLabel('Ruangan'),
                                DropdownButtonFormField<int>(
                                  key: ValueKey(
                                    'ruangan-${provider.rooms.length}',
                                  ),
                                  isExpanded: true,
                                  initialValue: roomValue,
                                  hint: const Text('-- Pilih Ruangan --'),
                                  items: provider.rooms
                                      .map(
                                        (r) => DropdownMenuItem(
                                          value: r.id,
                                          child: Text(r.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) => setState(() => _roomId = v),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildFieldLabel('Kondisi'),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _condition,
                        items: conditionOptions
                            .map(
                              (c) => DropdownMenuItem(value: c, child: Text(c)),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _condition = v ?? 'Baik'),
                      ),
                      _buildSection('DETAIL'),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Merk',
                              controller: _brandController,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Satuan',
                              controller: _unitController,
                              hint: 'unit, buah, set, ...',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildField(
                              label: 'Tahun',
                              controller: _yearController,
                              keyboardType: TextInputType.number,
                              hint: 'YYYY',
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildField(
                              label: 'Stok',
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (v) {
                                final n = int.tryParse((v ?? '').trim());
                                if (n == null || n < 0) {
                                  return 'Stok tidak valid';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        label: 'Deskripsi',
                        controller: _descriptionController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 28),
                      FilledButton(
                        onPressed: _submitting ? null : _submit,
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                _isEdit ? 'Simpan Perubahan' : 'Simpan Barang',
                              ),
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
