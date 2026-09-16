import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/stock_item.dart';
import '../../blocs/auth/auth_bloc.dart';

class FoodCanteenView extends StatefulWidget {
  const FoodCanteenView({super.key});

  @override
  State<FoodCanteenView> createState() => _FoodCanteenViewState();
}

class _FoodCanteenViewState extends State<FoodCanteenView> {
  String _searchQuery = '';

  void _showItemDialog(BuildContext context, String companyId, {StockItem? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final stockCtrl = TextEditingController(
      text: existing != null ? existing.stock.toString() : '10',
    );
    final priceCtrl = TextEditingController(
      text: existing?.price != null ? existing!.price!.toStringAsFixed(0) : '20',
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
                existing == null ? 'Add Food / Drink Item' : 'Edit Food / Drink Item',
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
                      labelText: 'Item Name *',
                      hintText: 'e.g. Red Bull, Cold Coffee, Lays Chips',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Current Stock *',
                            hintText: 'e.g. 24',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: priceCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Selling Price (₹) *',
                            prefixText: '₹ ',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g. 250ml Can, Salted flavor',
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
                            'Expiry Date (Optional)',
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
                                initialDate: expiryDate ??
                                    DateTime.now().add(const Duration(days: 90)),
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
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty || price <= 0) return;

                final item = StockItem(
                  id: existing?.id ?? const Uuid().v4(),
                  companyId: companyId,
                  name: name,
                  stock: stock,
                  price: price,
                  desc: descCtrl.text.trim(),
                  expiryDate: expiryDate,
                  category: StockCategory.food,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                );

                Navigator.of(dialogCtx).pop();
                await sl<FirestoreService>().saveFoodItem(item);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        existing == null
                            ? 'Added "$name" to canteen.'
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
        title: const Text('Delete Canteen Item?'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await sl<FirestoreService>().deleteFoodItem(companyId, item.id);
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
      stream: sl<FirestoreService>().watchFoodCanteen(companyId),
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

        final totalStockCount =
            allItems.fold<int>(0, (sum, i) => sum + i.stock);
        final lowStockCount = allItems.where((i) => i.stock <= 5).length;

        return Scaffold(
          backgroundColor: AppColors.backgroundBase,
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FOOD & CANTEEN STOCK',
                          style: TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Snacks, Drinks & Refreshments',
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
                      label: const Text('Add Food / Drink'),
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

                // Quick Metric Bar
                Row(
                  children: [
                    _buildPill(
                      'Total Items',
                      allItems.length.toString(),
                      AppColors.brandAccentLight,
                      Icons.fastfood,
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      'Total Stock Units',
                      totalStockCount.toString(),
                      AppColors.tableAvailable,
                      Icons.inventory,
                    ),
                    const SizedBox(width: 12),
                    _buildPill(
                      'Low Stock (<5)',
                      lowStockCount.toString(),
                      lowStockCount > 0
                          ? AppColors.tableOccupied
                          : AppColors.secondaryText,
                      Icons.warning_amber_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  decoration: const InputDecoration(
                    hintText: 'Search snacks, drinks, food items...',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: 16),

                // Items List
                Expanded(
                  child: filtered.isEmpty
                      ? Center(
                          child: Text(
                            allItems.isEmpty
                                ? 'No food or canteen items added yet. Click "Add Food / Drink" to begin.'
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
                            mainAxisExtent: 170,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            final isLowStock = item.stock <= 5;

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
                                                  color:
                                                      AppColors.brandAccentLight,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  'Edit',
                                                  style: TextStyle(
                                                    color: AppColors.primaryText,
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
                                                  color: AppColors.tableOccupied,
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
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Price',
                                            style: TextStyle(
                                              color: AppColors.secondaryText,
                                              fontSize: 10,
                                            ),
                                          ),
                                          Text(
                                            '₹${(item.price ?? 0).toStringAsFixed(0)}',
                                            style: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isLowStock
                                              ? AppColors.tableOccupied
                                                  .withAlpha(30)
                                              : AppColors.inputSurface,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: isLowStock
                                                ? AppColors.tableOccupied
                                                : AppColors.cardBorderStroke,
                                          ),
                                        ),
                                        child: Text(
                                          'Stock: ${item.stock}',
                                          style: TextStyle(
                                            color: isLowStock
                                                ? AppColors.tableOccupied
                                                : AppColors.brandAccentLight,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (item.expiryDate != null) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      'Exp: ${DateFormat('dd MMM yyyy').format(item.expiryDate!)}',
                                      style: TextStyle(
                                        color: item.isExpired
                                            ? AppColors.tableOccupied
                                            : AppColors.secondaryText,
                                        fontSize: 10,
                                        fontWeight: item.isExpired
                                            ? FontWeight.w700
                                            : FontWeight.normal,
                                      ),
                                    ),
                                  ],
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

  Widget _buildPill(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
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
