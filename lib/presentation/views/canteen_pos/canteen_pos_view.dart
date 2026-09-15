import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/canteen_item.dart';
import '../../../domain/entities/table_session.dart';
import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/canteen_pos/canteen_pos_bloc.dart';
import '../../blocs/floor_matrix/floor_matrix_bloc.dart';

class CanteenPosView extends StatelessWidget {
  const CanteenPosView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        final activeUser = authState.currentUser;
        final activeBranch = authState.activeBranch;

        if (activeUser == null || activeBranch == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return BlocBuilder<FloorMatrixBloc, FloorMatrixState>(
          builder: (context, matrixState) {
            final activeSessions = matrixState.activeSessions;

            return BlocConsumer<CanteenPosBloc, CanteenPosState>(
              listener: (context, state) {
                if (state.successMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(state.successMessage!),
                      backgroundColor: AppColors.tableAvailable,
                    ),
                  );
                }
              },
              builder: (context, posState) {
                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Product catalog & search (Expanded)
                          Expanded(
                            flex: 6,
                            child: _buildCatalogSection(context, posState),
                          ),
                          // Vertical divider
                          const VerticalDivider(
                            width: 1,
                            color: AppColors.cardBorderStroke,
                          ),
                          // Active Order / Tab Cart panel (380px)
                          SizedBox(
                            width: 380,
                            child: _buildCartPanel(
                              context,
                              posState,
                              activeSessions,
                              activeUser,
                              activeBranch.id,
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Compact mobile layout: stacked catalog with bottom cart bar
                      return Column(
                        children: [
                          Expanded(
                            child: _buildCatalogSection(context, posState),
                          ),
                          if (posState.cart.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: const BoxDecoration(
                                color: AppColors.cardSurface,
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.cardBorderStroke,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${posState.cartTotalQuantity} items in cart',
                                        style: const TextStyle(
                                          color: AppColors.secondaryText,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        AppFormatters.currency(
                                          posState.cartTotal,
                                        ),
                                        style: const TextStyle(
                                          color: AppColors.tableAvailable,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  ElevatedButton(
                                    onPressed: () => _showMobileCartBottomSheet(
                                      context,
                                      posState,
                                      activeSessions,
                                      activeUser,
                                      activeBranch.id,
                                    ),
                                    child: const Text('View Cart & Checkout'),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    }
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildCatalogSection(BuildContext context, CanteenPosState state) {
    final filteredItems = state.filteredItems;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (context.read<AuthBloc>().state.currentUser?.role.canManageRates ??
              false)
            Align(
              alignment: Alignment.centerRight,
              child: OutlinedButton.icon(
                onPressed: () => _showItemDialog(
                  context,
                  context.read<AuthBloc>().state.activeBranch!.id,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Add canteen item'),
              ),
            ),
          // Search & Filter header
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) => context.read<CanteenPosBloc>().add(
                    SearchQueryChangedEvent(val),
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Search snacks, drinks, chalk, cue rentals...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: AppColors.secondaryText,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildCategoryChip(
                  context,
                  null,
                  'All Products',
                  state.selectedCategory == null,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context,
                  CanteenCategory.beverages,
                  'Beverages & Drinks',
                  state.selectedCategory == CanteenCategory.beverages,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context,
                  CanteenCategory.snacks,
                  'Snacks & Bites',
                  state.selectedCategory == CanteenCategory.snacks,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context,
                  CanteenCategory.accessories,
                  'Chalk & Accessories',
                  state.selectedCategory == CanteenCategory.accessories,
                ),
                const SizedBox(width: 8),
                _buildCategoryChip(
                  context,
                  CanteenCategory.cueCare,
                  'Cue Care & Rentals',
                  state.selectedCategory == CanteenCategory.cueCare,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Items Grid
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      'No products found matching selection',
                      style: TextStyle(color: AppColors.secondaryText),
                    ),
                  )
                : GridView.builder(
                    itemCount: filteredItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 0.95,
                        ),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return _buildProductCard(context, item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    BuildContext context,
    CanteenCategory? category,
    String label,
    bool isSelected,
  ) {
    return InkWell(
      onTap: () => context.read<CanteenPosBloc>().add(
        SelectCanteenCategoryEvent(category),
      ),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.brandAccent.withAlpha(40)
              : AppColors.inputSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.brandAccent
                : AppColors.cardBorderStroke,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryText : AppColors.secondaryText,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, CanteenItem item) {
    final isOutOfStock = item.stockQuantity <= 0;

    return InkWell(
      onLongPress:
          context.read<AuthBloc>().state.currentUser?.role.canManageRates ??
              false
          ? () => _showItemDialog(context, item.branchId, item)
          : null,
      onTap: isOutOfStock
          ? null
          : () {
              context.read<CanteenPosBloc>().add(AddItemToCartEvent(item));
            },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: item.isLowStock
                ? AppColors.tableOccupied.withAlpha(120)
                : AppColors.cardBorderStroke,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Category icon & Stock Pill
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _getCategoryIcon(item.category),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: item.isLowStock
                        ? AppColors.tableOccupied.withAlpha(30)
                        : AppColors.inputSurface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: item.isLowStock
                          ? AppColors.tableOccupied
                          : AppColors.cardBorderStroke,
                    ),
                  ),
                  child: Text(
                    isOutOfStock
                        ? 'OUT OF STOCK'
                        : '${item.stockQuantity} ${item.unit}',
                    style: TextStyle(
                      color: item.isLowStock
                          ? AppColors.tableOccupied
                          : AppColors.secondaryText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Item Name
            Text(
              item.name,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),

            // Price & Add button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppFormatters.currency(item.unitPrice),
                  style: const TextStyle(
                    color: AppColors.tableAvailable,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isOutOfStock
                        ? AppColors.inputSurface
                        : AppColors.brandAccent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 16, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showItemDialog(
    BuildContext context,
    String branchId, [
    CanteenItem? existing,
  ]) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final price = TextEditingController(
      text: existing?.unitPrice.toString() ?? '',
    );
    final stock = TextEditingController(
      text: existing?.stockQuantity.toString() ?? '0',
    );
    var category = existing?.category ?? CanteenCategory.beverages;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.cardSurface,
          title: Text(
            existing == null ? 'Add canteen item' : 'Edit canteen item',
            style: const TextStyle(color: AppColors.primaryText),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Item name'),
              ),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Selling price (₹)',
                ),
              ),
              TextField(
                controller: stock,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Opening / current stock',
                ),
              ),
              DropdownButtonFormField<CanteenCategory>(
                initialValue: category,
                dropdownColor: AppColors.cardSurface,
                items: CanteenCategory.values
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(v.displayName),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => category = v ?? category),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final selling = double.tryParse(price.text),
                    quantity = int.tryParse(stock.text);
                if (name.text.trim().isEmpty ||
                    selling == null ||
                    quantity == null) {
                  return;
                }
                context.read<CanteenPosBloc>().add(
                  SaveCanteenItemEvent(
                    existing?.copyWith(
                          name: name.text.trim(),
                          category: category,
                          unitPrice: selling,
                          stockQuantity: quantity,
                        ) ??
                        CanteenItem(
                          id: const Uuid().v4(),
                          branchId: branchId,
                          name: name.text.trim(),
                          category: category,
                          unitPrice: selling,
                          costPrice: 0,
                          stockQuantity: quantity,
                        ),
                  ),
                );
                Navigator.pop(dialogContext);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getCategoryIcon(CanteenCategory cat) {
    IconData icon;
    Color color;
    switch (cat) {
      case CanteenCategory.beverages:
        icon = Icons.local_drink_outlined;
        color = AppColors.tableReserved;
        break;
      case CanteenCategory.snacks:
        icon = Icons.fastfood_outlined;
        color = AppColors.tableMaintenance;
        break;
      case CanteenCategory.accessories:
        icon = Icons.square_outlined;
        color = AppColors.tableAvailable;
        break;
      case CanteenCategory.cueCare:
        icon = Icons.hardware_outlined;
        color = AppColors.brandAccentLight;
        break;
    }
    return Icon(icon, color: color, size: 20);
  }

  Widget _buildCartPanel(
    BuildContext context,
    CanteenPosState state,
    List<TableSession> activeSessions,
    dynamic activeUser,
    String branchId,
  ) {
    final selectedSessionId = state.targetSessionId;
    final isTableTab = selectedSessionId != null;

    return Container(
      color: AppColors.cardSurface,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Panel Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'COUNTER POS CART',
                style: TextStyle(
                  color: AppColors.primaryText,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  letterSpacing: 0.8,
                ),
              ),
              if (state.cart.isNotEmpty)
                TextButton(
                  onPressed: () =>
                      context.read<CanteenPosBloc>().add(ClearCartEvent()),
                  child: const Text(
                    'Clear',
                    style: TextStyle(
                      color: AppColors.tableOccupied,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Tab Destination Selector (Walk-in vs Table Tab)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.inputSurface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.cardBorderStroke),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sale Destination',
                  style: TextStyle(
                    color: AppColors.secondaryText,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String?>(
                    isExpanded: true,
                    value: selectedSessionId,
                    dropdownColor: AppColors.cardSurface,
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Row(
                          children: [
                            Icon(
                              Icons.point_of_sale,
                              size: 16,
                              color: AppColors.tableAvailable,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Walk-in Counter Direct Sale',
                              style: TextStyle(
                                color: AppColors.primaryText,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...activeSessions.map((session) {
                        return DropdownMenuItem<String?>(
                          value: session.id,
                          child: Row(
                            children: [
                              const Icon(
                                Icons.table_restaurant,
                                size: 16,
                                color: AppColors.brandAccentLight,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Add to ${session.tableName} (${session.playerName})',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (val) {
                      context.read<CanteenPosBloc>().add(
                        SetTargetSessionEvent(val),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.cardBorderStroke),
          const SizedBox(height: 12),

          // Cart Items List
          Expanded(
            child: state.cart.isEmpty
                ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 40,
                          color: AppColors.secondaryText,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Cart is empty',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          'Tap any item on the left to add',
                          style: TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: state.cart.length,
                    separatorBuilder: (_, index) => const Divider(
                      color: AppColors.cardBorderStroke,
                      height: 16,
                    ),
                    itemBuilder: (context, index) {
                      final entry = state.cart[index];
                      return Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  entry.item.name,
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${AppFormatters.currency(entry.item.unitPrice)} each',
                                  style: const TextStyle(
                                    color: AppColors.secondaryText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove,
                                  size: 14,
                                  color: AppColors.secondaryText,
                                ),
                                onPressed: () {
                                  context.read<CanteenPosBloc>().add(
                                    UpdateCartQuantityEvent(entry.item.id, -1),
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                              Text(
                                '${entry.quantity}',
                                style: const TextStyle(
                                  color: AppColors.primaryText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColors.primaryText,
                                ),
                                onPressed: () {
                                  context.read<CanteenPosBloc>().add(
                                    UpdateCartQuantityEvent(entry.item.id, 1),
                                  );
                                },
                                visualDensity: VisualDensity.compact,
                              ),
                            ],
                          ),
                          SizedBox(
                            width: 60,
                            child: Text(
                              AppFormatters.currency(entry.subtotal),
                              style: const TextStyle(
                                color: AppColors.primaryText,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          const Divider(color: AppColors.cardBorderStroke),
          const SizedBox(height: 12),

          // Total & Checkout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total Amount',
                style: TextStyle(color: AppColors.secondaryText, fontSize: 14),
              ),
              Text(
                AppFormatters.currency(state.cartTotal),
                style: const TextStyle(
                  color: AppColors.tableAvailable,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: state.cart.isEmpty
                ? null
                : () async {
                    final paymentMethod = isTableTab
                        ? PaymentMethod.cash
                        : await _selectPaymentMethod(context);
                    if (paymentMethod == null || !context.mounted) return;
                    context.read<CanteenPosBloc>().add(
                      CheckoutCartEvent(
                        branchId: branchId,
                        operatorId: activeUser.id,
                        operatorName: activeUser.name,
                        paymentMethod: paymentMethod,
                        targetSessionId: selectedSessionId,
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: isTableTab
                  ? AppColors.brandAccent
                  : AppColors.tableAvailable,
              foregroundColor: isTableTab ? Colors.white : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              isTableTab
                  ? 'ADD TO TABLE TAB (${AppFormatters.currency(state.cartTotal)})'
                  : 'COLLECT CASH (${AppFormatters.currency(state.cartTotal)})',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<PaymentMethod?> _selectPaymentMethod(BuildContext context) {
    return showDialog<PaymentMethod>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardSurface,
        title: const Text(
          'Select payment method',
          style: TextStyle(color: AppColors.primaryText),
        ),
        content: const Text(
          'Record the tender received for this walk-in sale.',
          style: TextStyle(color: AppColors.secondaryText),
        ),
        actions: PaymentMethod.values
            .map(
              (method) => TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(method),
                child: Text(method.displayName),
              ),
            )
            .toList(),
      ),
    );
  }

  void _showMobileCartBottomSheet(
    BuildContext context,
    CanteenPosState posState,
    List<TableSession> activeSessions,
    dynamic activeUser,
    String branchId,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardSurface,
      builder: (sheetContext) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.75,
          child: BlocListener<CanteenPosBloc, CanteenPosState>(
            listenWhen: (previous, current) =>
                previous.isSubmitting &&
                !current.isSubmitting &&
                current.successMessage != null,
            listener: (listenerContext, state) =>
                Navigator.of(sheetContext).pop(),
            child: BlocBuilder<CanteenPosBloc, CanteenPosState>(
              builder: (context, liveState) => _buildCartPanel(
                sheetContext,
                liveState,
                activeSessions,
                activeUser,
                branchId,
              ),
            ),
          ),
        );
      },
    );
  }
}
