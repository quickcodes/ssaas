import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../domain/entities/table_billing_item.dart';
import '../../../domain/entities/table_session.dart';
import '../../../domain/entities/user_account.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';
import '../../widgets/bouncing_tap.dart';

class ManageTableItemsDialog extends StatelessWidget {
  final String companyId;
  final String sessionId;
  final String tableName;
  final UserAccount activeOperator;
  final VoidCallback onAddMoreItems;

  const ManageTableItemsDialog({
    super.key,
    required this.companyId,
    required this.sessionId,
    required this.tableName,
    required this.activeOperator,
    required this.onAddMoreItems,
  });

  bool _checkOnline(BuildContext context) {
    if (!activeOperator.isOnline) {
      AppHaptics.medium();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Operator "${activeOperator.name}" is OFFLINE. Please go online to edit or delete table items.',
          ),
          backgroundColor: AppColors.tableOccupied,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return false;
    }
    return true;
  }

  void _updateQuantity(
    BuildContext context,
    TableSession session,
    TableBillingItem item,
    int newQuantity,
  ) {
    if (!_checkOnline(context)) return;
    if (newQuantity <= 0) {
      _confirmDeleteItem(context, session, item);
      return;
    }

    AppHaptics.light();
    final updatedItem = item.copyWith(quantity: newQuantity);
    context.read<FloorMatrixBloc>().add(
          UpdateBillingItemEvent(
            companyId: companyId,
            sessionId: session.id,
            oldItem: item,
            newItem: updatedItem,
          ),
        );
  }

  void _confirmDeleteItem(
    BuildContext context,
    TableSession session,
    TableBillingItem item,
  ) {
    if (!_checkOnline(context)) return;
    AppHaptics.medium();

    showDialog(
      context: context,
      builder: (alertCtx) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorderStroke),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.tableOccupied.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: AppColors.tableOccupied,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Remove Item?',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to remove "${item.name}" from ${session.tableName}?',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.inputSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.cardBorderStroke),
              ),
              child: Row(
                children: [
                  Icon(
                    item.stockItemId != null && !item.isCustom
                        ? Icons.inventory_2_outlined
                        : Icons.sell_outlined,
                    size: 16,
                    color: AppColors.brandAccentLight,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.stockItemId != null && !item.isCustom
                          ? '${item.quantity} unit(s) will be returned to Canteen Stock inventory.'
                          : 'Custom charge will be completely deducted from table bill.',
                      style: const TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(alertCtx).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tableOccupied,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(alertCtx).pop();
              context.read<FloorMatrixBloc>().add(
                    RemoveBillingItemEvent(
                      companyId: companyId,
                      sessionId: session.id,
                      item: item,
                    ),
                  );
            },
            child: const Text(
              'Remove Item',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(
    BuildContext context,
    TableSession session,
    TableBillingItem item,
  ) {
    if (!_checkOnline(context)) return;
    AppHaptics.light();

    final nameCtrl = TextEditingController(text: item.name);
    final descCtrl = TextEditingController(text: item.desc);
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(2));
    final formKey = GlobalKey<FormState>();
    int quantity = item.quantity;

    showDialog(
      context: context,
      builder: (editCtx) => StatefulBuilder(
        builder: (ctx, setEditState) => Dialog(
          backgroundColor: AppColors.cardSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.cardBorderStroke),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
              maxWidth: 440,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.brandAccent.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.brandAccentLight,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.isCustom
                                    ? 'Edit Custom Item'
                                    : 'Edit Canteen Item',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${session.tableName} • ${item.name}',
                                style: const TextStyle(
                                  color: AppColors.secondaryText,
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Divider(color: AppColors.cardBorderStroke),
                    const SizedBox(height: 16),

                    // If custom item, allow changing name and price
                    if (item.isCustom) ...[
                      const Text(
                        'Item Name *',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Energy Drink, Chips',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Unit Price (₹) *',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d*\.?\d{0,2}')),
                        ],
                        decoration: const InputDecoration(
                          prefixText: '₹ ',
                          hintText: '0.00',
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter price';
                          }
                          final p = double.tryParse(v);
                          if (p == null || p <= 0) {
                            return 'Price must be greater than 0';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      const Text(
                        'Description / Note (Optional)',
                        style: TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: descCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Optional instructions or flavor',
                        ),
                      ),
                      const SizedBox(height: 14),
                    ] else ...[
                      // Canteen stock item display info
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.cardBorderStroke),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              item.name,
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              '₹${item.price.toStringAsFixed(0)} each',
                              style: const TextStyle(
                                color: AppColors.brandAccentLight,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Quantity selector
                    const Text(
                      'Quantity',
                      style: TextStyle(
                        color: AppColors.secondaryText,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.inputSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.cardBorderStroke),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Select Quantity',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                color: quantity > 1
                                    ? AppColors.brandAccentLight
                                    : AppColors.textDisabled,
                                onPressed: quantity > 1
                                    ? () => setEditState(() => quantity--)
                                    : null,
                              ),
                              Container(
                                constraints:
                                    const BoxConstraints(minWidth: 32),
                                alignment: Alignment.center,
                                child: Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                color: AppColors.brandAccentLight,
                                onPressed: () =>
                                    setEditState(() => quantity++),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Live Total Calculation
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Item Total:',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          '₹${((double.tryParse(priceCtrl.text) ?? item.price) * quantity).toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppColors.brandAccentLight,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.of(editCtx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.brandAccent,
                              foregroundColor: Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            onPressed: () {
                              if (!formKey.currentState!.validate()) return;
                              final updatedPrice = item.isCustom
                                  ? double.parse(priceCtrl.text.trim())
                                  : item.price;
                              final updated = item.copyWith(
                                name: item.isCustom
                                    ? nameCtrl.text.trim()
                                    : item.name,
                                desc: item.isCustom
                                    ? descCtrl.text.trim()
                                    : item.desc,
                                price: updatedPrice,
                                quantity: quantity,
                              );
                              Navigator.of(editCtx).pop();
                              context.read<FloorMatrixBloc>().add(
                                    UpdateBillingItemEvent(
                                      companyId: companyId,
                                      sessionId: session.id,
                                      oldItem: item,
                                      newItem: updated,
                                    ),
                                  );
                            },
                            child: const Text(
                              'Save Changes',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.cardSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.cardBorderStroke),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 580,
        ),
        child: BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
          builder: (context, matrixState) {
            // Find live session from matrix state so updates reflect in real-time
            final session = matrixState.activeSessions
                .where((s) => s.id == sessionId)
                .firstOrNull;

            if (session == null) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 40,
                      color: AppColors.secondaryText,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Session is no longer running.',
                      style: TextStyle(
                        color: AppColors.primaryText,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }

            final items = session.items;
            final totalAmount = session.itemsAmount;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Dialog Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.brandAccent.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.fastfood_outlined,
                                color: AppColors.brandAccentLight,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          tableName,
                                          style: const TextStyle(
                                            color: AppColors.primaryText,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w800,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.brandAccent
                                              .withAlpha(30),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${items.length} ${items.length == 1 ? 'item' : 'items'}',
                                          style: const TextStyle(
                                            color: AppColors.brandAccentLight,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Canteen & Extra Items on this table',
                                    style: TextStyle(
                                      color: AppColors.secondaryText,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: AppColors.secondaryText),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.cardBorderStroke),
                  const SizedBox(height: 12),

                  // Summary card & Add button
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.inputSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.brandAccent.withAlpha(50),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL ITEMS BILL',
                              style: TextStyle(
                                color: AppColors.secondaryText,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '₹${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppColors.brandAccentLight,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        BouncingTap(
                          onTap: () {
                            Navigator.of(context).pop();
                            onAddMoreItems();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.brandAccent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.add_shopping_cart,
                                    size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Add More',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Items List or Empty state
                  if (items.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.remove_shopping_cart_outlined,
                            size: 48,
                            color: AppColors.textDisabled.withAlpha(120),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'No items added to this table',
                            style: TextStyle(
                              color: AppColors.primaryText,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Accidentally added items can be edited or removed from here.',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 11,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).pop();
                              onAddMoreItems();
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Canteen Item'),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: items.length,
                      separatorBuilder: (ctx, idx) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final isStock =
                            item.stockItemId != null && !item.isCustom;

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.inputSurface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.cardBorderStroke,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Line 1: Name, Category Badge, Price Subtotal
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading category icon
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isStock
                                          ? AppColors.tableAvailable
                                              .withAlpha(25)
                                          : AppColors.brandAccentLight
                                              .withAlpha(25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Icon(
                                      isStock
                                          ? Icons.fastfood_outlined
                                          : Icons.sell_outlined,
                                      size: 15,
                                      color: isStock
                                          ? AppColors.tableAvailable
                                          : AppColors.brandAccentLight,
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Name and rate info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.name,
                                                style: const TextStyle(
                                                  color: AppColors.primaryText,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 13,
                                                ),
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 5,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: isStock
                                                    ? AppColors.tableAvailable
                                                        .withAlpha(20)
                                                    : AppColors
                                                        .brandAccentLight
                                                        .withAlpha(20),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                isStock
                                                    ? 'Canteen Stock'
                                                    : 'Custom Item',
                                                style: TextStyle(
                                                  color: isStock
                                                      ? AppColors
                                                          .tableAvailable
                                                      : AppColors
                                                          .brandAccentLight,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '₹${item.price.toStringAsFixed(0)} each'
                                          '${item.desc.isNotEmpty ? " • ${item.desc}" : ""}',
                                          style: const TextStyle(
                                            color: AppColors.secondaryText,
                                            fontSize: 11,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Total line price
                                  Text(
                                    '₹${item.totalAmount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      color: AppColors.brandAccentLight,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              const Divider(
                                  height: 1,
                                  color: AppColors.cardBorderStroke),
                              const SizedBox(height: 8),

                              // Line 2: Quantity Adjuster + Action Buttons (Edit / Delete)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  // Quick Quantity Stepper
                                  Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cardSurface,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.cardBorderStroke,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Minus Button
                                        InkWell(
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(8),
                                            bottomLeft: Radius.circular(8),
                                          ),
                                          onTap: () {
                                            if (item.quantity > 1) {
                                              _updateQuantity(
                                                context,
                                                session,
                                                item,
                                                item.quantity - 1,
                                              );
                                            } else {
                                              _confirmDeleteItem(
                                                  context, session, item);
                                            }
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Icon(
                                              item.quantity > 1
                                                  ? Icons.remove
                                                  : Icons.delete_outline,
                                              size: 14,
                                              color: item.quantity > 1
                                                  ? AppColors.secondaryText
                                                  : AppColors.tableOccupied,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          child: Text(
                                            '${item.quantity}',
                                            style: const TextStyle(
                                              color: AppColors.primaryText,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                        ),
                                        // Plus Button
                                        InkWell(
                                          borderRadius: const BorderRadius.only(
                                            topRight: Radius.circular(8),
                                            bottomRight: Radius.circular(8),
                                          ),
                                          onTap: () {
                                            _updateQuantity(
                                              context,
                                              session,
                                              item,
                                              item.quantity + 1,
                                            );
                                          },
                                          child: const Padding(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            child: Icon(
                                              Icons.add,
                                              size: 14,
                                              color:
                                                  AppColors.brandAccentLight,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Edit & Delete actions
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Edit button
                                      BouncingTap(
                                        onTap: () => _showEditItemDialog(
                                            context, session, item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.cardSurface,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors
                                                    .cardBorderStroke),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(Icons.edit_outlined,
                                                  size: 12,
                                                  color:
                                                      AppColors.secondaryText),
                                              SizedBox(width: 4),
                                              Text(
                                                'Edit',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.secondaryText,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Delete button
                                      BouncingTap(
                                        onTap: () => _confirmDeleteItem(
                                            context, session, item),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: AppColors.tableOccupied
                                                .withAlpha(20),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                              color: AppColors.tableOccupied
                                                  .withAlpha(60),
                                            ),
                                          ),
                                          child: const Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.delete_outline_rounded,
                                                size: 12,
                                                color: AppColors.tableOccupied,
                                              ),
                                              SizedBox(width: 4),
                                              Text(
                                                'Delete',
                                                style: TextStyle(
                                                  color:
                                                      AppColors.tableOccupied,
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  // Bottom Done Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.inputSurface,
                      foregroundColor: AppColors.primaryText,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side:
                            const BorderSide(color: AppColors.cardBorderStroke),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
