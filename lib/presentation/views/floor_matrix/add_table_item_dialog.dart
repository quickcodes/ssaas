import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../core/utils/responsive.dart';
import '../../../domain/entities/stock_item.dart';
import '../../../domain/entities/table_billing_item.dart';
import '../../widgets/bouncing_tap.dart';

class AddTableItemDialog extends StatefulWidget {
  final List<StockItem> canteenItems;
  final String tableName;
  final int existingItemsCount;
  final VoidCallback? onManageExistingItems;

  const AddTableItemDialog({
    super.key,
    required this.canteenItems,
    required this.tableName,
    this.existingItemsCount = 0,
    this.onManageExistingItems,
  });

  @override
  State<AddTableItemDialog> createState() => _AddTableItemDialogState();
}

class _AddTableItemDialogState extends State<AddTableItemDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Canteen stock tab state
  StockItem? _selectedStockItem;
  int _canteenQty = 1;

  // Custom item tab state
  final _customNameCtrl = TextEditingController();
  final _customDescCtrl = TextEditingController();
  final _customPriceCtrl = TextEditingController();
  int _customQty = 1;
  final _customFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.canteenItems.isNotEmpty) {
      _selectedStockItem = widget.canteenItems.first;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _customNameCtrl.dispose();
    _customDescCtrl.dispose();
    _customPriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ADD TO TABLE BILLING',
              style: TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              widget.tableName,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        actions: [
          if (widget.existingItemsCount > 0 &&
              widget.onManageExistingItems != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  widget.onManageExistingItems!();
                },
                icon: const Icon(
                  Icons.receipt_long,
                  size: 16,
                  color: AppColors.brandAccentLight,
                ),
                label: Text(
                  '${widget.existingItemsCount} on Table',
                  style: const TextStyle(
                    color: AppColors.brandAccentLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            height: 44,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerHeight: 0,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                  colors: [AppColors.brandAccent, Color(0xFF0F9D58)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.brandAccent.withAlpha(70),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.secondaryText,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fastfood_outlined, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Snacks & Drinks',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_note, size: 18),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Custom Item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: TabBarView(
              controller: _tabController,
              children: [
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    padding: EdgeInsets.all(isMobile ? 18 : 24),
                    child: _buildCanteenStockTab(),
                  ),
                ),
                SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 16 : 24,
                    vertical: 20,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.cardBorderStroke),
                    ),
                    padding: EdgeInsets.all(isMobile ? 18 : 24),
                    child: _buildCustomItemTab(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCanteenStockTab() {
    if (widget.canteenItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 40,
              color: AppColors.secondaryText,
            ),
            const SizedBox(height: 10),
            const Text(
              'No food/drink items in stock.',
              style: TextStyle(color: AppColors.secondaryText),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _tabController.animateTo(1),
              child: const Text('Add Custom Item Instead'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 4),
        DropdownButtonFormField<StockItem>(
          initialValue: _selectedStockItem,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Select Canteen Item',
            prefixIcon: Icon(Icons.fastfood_outlined),
          ),
          dropdownColor: AppColors.cardSurface,
          items: widget.canteenItems.map((item) {
            return DropdownMenuItem<StockItem>(
              value: item,
              child: Text(
                '${item.name} (₹${(item.price ?? 0).toStringAsFixed(0)}) • ${item.stock} in stock',
                style: const TextStyle(color: AppColors.primaryText),
              ),
            );
          }).toList(),
          onChanged: (item) {
            setState(() => _selectedStockItem = item);
          },
        ),
        const SizedBox(height: 20),

        // Quantity Selector
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quantity:',
              style: TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            Row(
              children: [
                IconButton(
                  onPressed: _canteenQty > 1
                      ? () {
                          AppHaptics.selection();
                          setState(() => _canteenQty--);
                        }
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Text(
                  '$_canteenQty',
                  style: const TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    AppHaptics.selection();
                    setState(() => _canteenQty++);
                  },
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Add Button
        BouncingTap(
          onTap: _selectedStockItem == null
              ? null
              : () {
                  AppHaptics.light();
                  final price = _selectedStockItem!.price ?? 0.0;
                  final item = TableBillingItem(
                    id: const Uuid().v4(),
                    name: _selectedStockItem!.name,
                    desc: _selectedStockItem!.desc,
                    price: price,
                    quantity: _canteenQty,
                    isCustom: false,
                    stockItemId: _selectedStockItem!.id,
                  );
                  Navigator.of(context).pop(item);
                },
          child: ElevatedButton(
            onPressed: _selectedStockItem == null
                ? null
                : () {
                    AppHaptics.light();
                    final price = _selectedStockItem!.price ?? 0.0;
                    final item = TableBillingItem(
                      id: const Uuid().v4(),
                      name: _selectedStockItem!.name,
                      desc: _selectedStockItem!.desc,
                      price: price,
                      quantity: _canteenQty,
                      isCustom: false,
                      stockItemId: _selectedStockItem!.id,
                    );
                    Navigator.of(context).pop(item);
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.brandAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              'ADD TO BILL (₹${((_selectedStockItem?.price ?? 0) * _canteenQty).toStringAsFixed(0)})',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomItemTab() {
    return Form(
      key: _customFormKey,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _customNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Item Name *',
                hintText: 'e.g. Fresh Juice, Cigarettes, Coffee',
              ),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Item name is required'
                  : null,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _customPriceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Price (₹) *',
                      prefixText: '₹ ',
                    ),
                    validator: (val) {
                      final p = double.tryParse(val ?? '');
                      if (p == null || p <= 0) return 'Valid price required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _customQty > 1
                          ? () {
                              AppHaptics.selection();
                              setState(() => _customQty--);
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text(
                      '$_customQty',
                      style: const TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        AppHaptics.selection();
                        setState(() => _customQty++);
                      },
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customDescCtrl,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'e.g. External item brought for customer',
              ),
            ),
            const SizedBox(height: 16),
            BouncingTap(
              onTap: () {
                if (!_customFormKey.currentState!.validate()) return;
                AppHaptics.light();
                final price = double.parse(_customPriceCtrl.text.trim());
                final item = TableBillingItem(
                  id: const Uuid().v4(),
                  name: _customNameCtrl.text.trim(),
                  desc: _customDescCtrl.text.trim(),
                  price: price,
                  quantity: _customQty,
                  isCustom: true,
                );
                Navigator.of(context).pop(item);
              },
              child: ElevatedButton(
                onPressed: () {
                  if (!_customFormKey.currentState!.validate()) return;
                  AppHaptics.light();
                  final price = double.parse(_customPriceCtrl.text.trim());
                  final item = TableBillingItem(
                    id: const Uuid().v4(),
                    name: _customNameCtrl.text.trim(),
                    desc: _customDescCtrl.text.trim(),
                    price: price,
                    quantity: _customQty,
                    isCustom: true,
                  );
                  Navigator.of(context).pop(item);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'ADD CUSTOM ITEM',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

typedef AddTableItemScreen = AddTableItemDialog;

