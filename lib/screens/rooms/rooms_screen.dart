import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:phosphoricons_flutter/phosphoricons_flutter.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../models/room.dart';
import '../../providers/auth_provider.dart';
import '../../providers/item_provider.dart';
import '../../widgets/error_view.dart';
import '../../widgets/loading_widget.dart';
import '../../widgets/master_form_sheet.dart';
import '../../widgets/search_field.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});

  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<ItemProvider>();
      if (!provider.referencesLoading) provider.loadReferences();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final provider = context.read<ItemProvider>();
    await provider.loadReferences();
    if (!mounted) return;
    if (provider.referencesError != null && provider.rooms.isNotEmpty) {
      _showSnack(provider.referencesError!, isError: true);
    }
  }

  Future<void> _openForm({Room? room}) async {
    final result = await showMasterFormSheet(
      context: context,
      title: room == null ? 'Tambah Ruangan' : 'Edit Ruangan',
      fields: [
        MasterFormField(
          id: 'name',
          label: 'Nama Ruangan',
          hint: 'cth: Lab Komputer',
          initialValue: room?.name ?? '',
        ),
        MasterFormField(
          id: 'location',
          label: 'Lokasi',
          hint: 'cth: Lantai 2',
          initialValue: room?.location ?? '',
        ),
        MasterFormField(
          id: 'pic',
          label: 'Penanggung Jawab (PIC)',
          hint: 'Opsional',
          initialValue: room?.pic ?? '',
        ),
      ],
      submitLabel: room == null ? 'Simpan Ruangan' : 'Simpan Perubahan',
    );
    if (result == null || !mounted) return;

    final provider = context.read<ItemProvider>();
    final name = (result['name'] ?? '').trim();
    final location = (result['location'] ?? '').trim();
    final pic = (result['pic'] ?? '').trim();
    final payload = {
      'name': name,
      'location': location.isEmpty ? null : location,
      'pic': pic.isEmpty ? null : pic,
    };
    try {
      if (room == null) {
        await provider.createRoom(payload);
      } else {
        await provider.updateRoom(room.id, payload);
      }
      _showSnack(
        'Ruangan berhasil ${room == null ? 'ditambahkan' : 'diperbarui'}',
      );
    } catch (e) {
      _showSnack(e.toString(), isError: true);
    }
  }

  Future<void> _confirmDelete(Room room) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Ruangan?'),
        content: Text(
          'Ruangan "${room.name}" akan dihapus. Tindakan ini tidak bisa dibatalkan.',
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
      await context.read<ItemProvider>().deleteRoom(room.id);
      _showSnack('Ruangan berhasil dihapus');
    } catch (e) {
      _showSnack(e.toString(), isError: true);
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
    final canCreate = auth.can('rooms.create');
    final canUpdate = auth.can('rooms.update');
    final canDelete = auth.can('rooms.delete');

    Widget body;
    if (provider.referencesLoading && provider.rooms.isEmpty) {
      body = const LoadingWidget(text: 'Memuat ruangan...');
    } else if (provider.referencesError != null && provider.rooms.isEmpty) {
      body = ErrorView(
        message: provider.referencesError!,
        onRetry: () => provider.loadReferences(),
      );
    } else {
      final q = _query.trim().toLowerCase();
      final rooms = provider.rooms.where((r) {
        if (q.isEmpty) return true;
        return [
          r.name,
          r.location ?? '',
          r.pic ?? '',
        ].join(' ').toLowerCase().contains(q);
      }).toList();

      body = Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: SearchField(
              controller: _searchController,
              hint: 'Cari ruangan...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: rooms.isEmpty
                ? Center(
                    child: Text(
                      q.isNotEmpty ? 'Tidak ditemukan' : 'Belum ada ruangan',
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      itemCount: rooms.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _RoomCard(
                              room: room,
                              canManage: canUpdate || canDelete,
                              onEdit: canUpdate
                                  ? () => _openForm(room: room)
                                  : null,
                              onDelete: canDelete
                                  ? () => _confirmDelete(room)
                                  : null,
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
      );
    }

    return Scaffold(
      body: body,
      floatingActionButton: canCreate
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(),
              icon: const Icon(PhosphorIcons.plus),
              label: const Text('Ruangan'),
            )
          : null,
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.room,
    required this.canManage,
    this.onEdit,
    this.onDelete,
  });

  final Room room;
  final bool canManage;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final detail = [
      if (room.location != null && room.location!.isNotEmpty) room.location,
      if (room.pic != null && room.pic!.isNotEmpty) 'PIC: ${room.pic}',
    ].join(' · ');

    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          radius: 20,
          backgroundColor: Theme.of(
            context,
          ).colorScheme.primary.withValues(alpha: 0.10),
          child: Icon(
            PhosphorIcons.building,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        title: Text(room.name, style: Theme.of(context).textTheme.titleSmall),
        subtitle: detail.isNotEmpty
            ? Text(detail, style: Theme.of(context).textTheme.bodySmall)
            : null,
        trailing: canManage
            ? PopupMenuButton<String>(
                tooltip: 'Aksi',
                onSelected: (value) {
                  if (value == 'edit') onEdit?.call();
                  if (value == 'delete') onDelete?.call();
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                  if (onDelete != null)
                    const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                ],
              )
            : null,
      ),
    );
  }
}
