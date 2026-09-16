import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/stock_item.dart';
import '../../blocs/auth/auth_bloc.dart';

class EquipmentStockView extends StatefulWidget {
  const EquipmentStockView({super.key});

  @override
  State<EquipmentStockView> createState() => _EquipmentStockViewState();
}

class _EquipmentStockViewState extends State<EquipmentStockView> {
  String _searchQuery = '';

  void _showItemDialog(
    BuildContext context,
    String companyId, {
    StockItem? existing,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.stock.toString() : '5',
    );
    final descCtrl = TextEditingController(text: existing?.desc ?? '');
    DateTime? expiryDate = existing?.expiryDate;

    showDialog(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          title: Row(
            children: [
              Icon(
                existing == null ? Icons.add_circle_outline : Icons.edit_note,
                color: AppColors.brandAccentLight,
              ),
              const SizedBox(width: 10),
              Text(
                existing == null
                    ? 'Add Equipment Stock'
                    : 'Edit Equipment Item',
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Equipment Name *',
                      hintText: 'e.g. Master Chalk, Cue Sticks, Table Cloth',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Count / Units *',
                      hintText: 'e.g. 12',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g. Green Triangle Chalk Box, Ash Wood Cues',
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Expiry Date (Optional)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Expiry Date or\nMaintenance Due (Optional)',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            expiryDate != null
                                ? DateFormat('dd MMM yyyy').format(expiryDate!)
                                : 'No expiry set',
                            style: const TextStyle(
                              color: AppColors.primaryText,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          if (expiryDate != null)
                            IconButton(
                              onPressed: () =>
                                  setDialogState(() => expiryDate = null),
                              icon: const Icon(
                                Icons.close,
                                size: 18,
                                color: AppColors.secondaryText,
                              ),
                            ),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate:
                                    expiryDate ??
                                    DateTime.now().add(
                                      const Duration(days: 180),
                                    ),
                                firstDate: DateTime.now().subtract(
                                  const Duration(days: 30),
                                ),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365 * 5),
                                ),
                              );
                              if (picked != null) {
                                setDialogState(() => expiryDate = picked);
                              }
                            },
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(expiryDate == null ? 'Set' : 'Change'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.inputSurface,
                              foregroundColor: AppColors.primaryText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final stock = int.tryParse(stockCtrl.text.trim()) ?? 0;
                if (name.isEmpty) return;

                final item = StockItem(
                  id: existing?.id ?? const Uuid().v4(),
                  companyId: companyId,
                  name: name,
                  stock: stock,
                  desc: descCtrl.text.trim(),
                  expiryDate: expiryDate,
                  category: StockCategory.equipment,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );

                Navigator.of(dialogCtx).pop();
                await sl<FirestoreService>().saveEquipmentItem(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null
                            ? 'Added "$name" to equipment stock.'
                            : 'Updated "$name".',
                      ),
                      backgroundColor: AppColors.tableAvailable,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
              ),
              child: Text(existing == null ? 'Add Item' : 'Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String companyId, StockItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: const Text('Delete Equipment Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await sl<FirestoreService>().deleteEquipmentItem(
                companyId,
                item.id,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final companyId = context.watch<AuthBloc>().state.activeCompany?.id;
    if (companyId == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return StreamBuilder<List<StockItem>>(
      stream: sl<FirestoreService>().watchEquipmentStock(companyId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allItems = snapshot.data!;
        final filtered = allItems.where((i) {
          if (_searchQuery.isEmpty) return true;
          return i.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              i.desc.toLowerCase().contains(_searchQuery.toLowerCase());
        }).toList();

        final totalUnits = allItems.fold<int>(0, (sum, i) => sum + i.stock);
        final lowStock = allItems.where((i) => i.stock <= 3).length;

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Wrap(
                  // mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'EQUIPMENT & STOCK',
                          style: TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sticks, Chalks, Table Cloth & Cues',
                          style: TextStyle(
                            color: AppColors.primaryText,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showItemDialog(context, companyId),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Equipment'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.brandAccent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Metrics Bar
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildPill(
                        'Unique Items',
                        allItems.length.toString(),
                        AppColors.brandAccentLight,
                        Icons.inventory_2,
                      ),
                      const SizedBox(width: 12),
                      _buildPill(
                        'Total Units In Club',
                        totalUnits.toString(),
                        AppColors.tableAvailable,
                        Icons.sports_esports,
                      ),
                      const SizedBox(width: 12),
                      _buildPill(
                        'Low Stock (<3)',
                        lowStock.toString(),
                        lowStock > 0
                            ? AppColors.tableOccupied
                            : AppColors.secondaryText,
                        Icons.warning_amber_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: const InputDecoration(
                    hintText:
                        'Search equipment (sticks, chalks, cloths, etc)...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),

                // Grid of items
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            allItems.isEmpty
                                ? 'No equipment items recorded yet. Click "Add Equipment" to record sticks, chalks, etc.'
                                : 'No items match your search.',
                            style: const TextStyle(
                              color: AppColors.secondaryText,
                            ),
                          ),
                        )
                      : GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 340,
                                mainAxisExtent: 160,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                              ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isLowStock = item.stock <= 3;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isLowStock
                                      ? AppColors.tableOccupied.withAlpha(100)
                                      : AppColors.cardBorderStroke,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 15,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        onSelected: (action) {
                                          if (action == 'edit') {
                                            _showItemDialog(
                                              context,
                                              companyId,
                                              existing: item,
                                            );
                                          } else if (action == 'delete') {
                                            _confirmDelete(
                                              context,
                                              companyId,
                                              item,
                                            );
                                          }
                                        },
                                        color: AppColors.cardSurface,
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(
                                            value: 'edit',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                  color: AppColors
                                                      .brandAccentLight,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.primaryText,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuItem(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.delete,
                                                  size: 16,
                                                  color:
                                                      AppColors.tableOccupied,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Delete',
                                                  style: TextStyle(
                                                    color:
                                                        AppColors.tableOccupied,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  if (item.desc.isNotEmpty) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      item.desc,
                                      style: const TextStyle(
                                        color: AppColors.secondaryText,
                                        fontSize: 11,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  const Spacer(),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLowStock
                                              ? AppColors.tableOccupied
                                                    .withAlpha(30)
                                              : AppColors.brandAccent.withAlpha(
                                                  30,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: isLowStock
                                                ? AppColors.tableOccupied
                                                : AppColors.brandAccent,
                                          ),
                                        ),
                                        child: Text(
                                          'Stock: ${item.stock} units',
                                          style: TextStyle(
                                            color: isLowStock
                                                ? AppColors.tableOccupied
                                                : AppColors.brandAccentLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      if (item.expiryDate != null)
                                        Text(
                                          'Due: ${DateFormat('dd MMM yyyy').format(item.expiryDate!)}',
                                          style: TextStyle(
                                            color: item.isExpired
                                                ? AppColors.tableOccupied
                                                : AppColors.secondaryText,
                                            fontSize: 11,
                                            fontWeight: item.isExpired
                                                ? FontWeight.w700
                                                : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPill(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.cardBorderStroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.secondaryText,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
