import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/stock_item.dart';

class AddEditCanteenItemScreen extends StatefulWidget {
  final String companyId;
  final StockItem? existing;

  const AddEditCanteenItemScreen({
    super.key,
    required this.companyId,
    this.existing,
  });

  @override
  State<AddEditCanteenItemScreen> createState() =>
      _AddEditCanteenItemScreenState();
}

class _AddEditCanteenItemScreenState extends State<AddEditCanteenItemScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _expiryDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _stockCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.stock.toString() : '10',
    );
    _priceCtrl = TextEditingController(
      text: widget.existing?.price != null
          ? widget.existing!.price!.toStringAsFixed(0)
          : '20',
    );
    _descCtrl = TextEditingController(text: widget.existing?.desc ?? '');
    _expiryDate = widget.existing?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 90)),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.brandAccent,
            onPrimary: Colors.white,
            surface: AppColors.cardSurface,
            onSurface: AppColors.primaryText,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameCtrl.text.trim();
    final stock = int.tryParse(_stockCtrl.text.trim());
    final price = double.tryParse(_priceCtrl.text.trim());

    if (name.isEmpty || stock == null || price == null) return;

    setState(() => _isSaving = true);

    final item = StockItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      companyId: widget.companyId,
      name: name,
      stock: stock,
      price: price,
      desc: _descCtrl.text.trim(),
      expiryDate: _expiryDate,
      category: StockCategory.food,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      await sl<FirestoreService>().saveFoodItem(item);
      if (mounted) {
        AppHaptics.success();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Added "$name" to canteen.'
                  : 'Updated "$name".',
            ),
            backgroundColor: AppColors.tableAvailable,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 680;
    final isEdit = widget.existing != null;

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
            Text(
              isEdit ? 'EDIT CANTEEN ITEM' : 'NEW CANTEEN ITEM',
              style: const TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              isEdit ? widget.existing!.name : 'Add Snacks & Drinks',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: SingleChildScrollView(
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Item Name *',
                          hintText: 'e.g. Red Bull, Cold Coffee, Lays Chips',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter an item name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Current Stock *',
                                hintText: 'e.g. 24',
                              ),
                              validator: (val) {
                                final n = int.tryParse(val?.trim() ?? '');
                                if (n == null || n < 0) return 'Invalid stock';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Selling Price (₹) *',
                                prefixText: '₹ ',
                              ),
                              validator: (val) {
                                final p = double.tryParse(val?.trim() ?? '');
                                if (p == null || p < 0) return 'Invalid price';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'e.g. 250ml Can, Salted flavor',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Expiry Date Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.inputSurface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.cardBorderStroke),
                        ),
                        child: Row(
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
                                const SizedBox(height: 4),
                                Text(
                                  _expiryDate != null
                                      ? DateFormat('dd MMM yyyy')
                                          .format(_expiryDate!)
                                      : 'No expiry set',
                                  style: const TextStyle(
                                    color: AppColors.primaryText,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                if (_expiryDate != null)
                                  IconButton(
                                    onPressed: () =>
                                        setState(() => _expiryDate = null),
                                    icon: const Icon(
                                      Icons.close,
                                      size: 18,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                ElevatedButton.icon(
                                  onPressed: _pickDate,
                                  icon: const Icon(Icons.calendar_month,
                                      size: 16),
                                  label: const Text('Pick Date'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cardSurface,
                                    foregroundColor: AppColors.primaryText,
                                    side: const BorderSide(
                                        color: AppColors.cardBorderStroke),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 24,
            vertical: 12,
          ),
          decoration: const BoxDecoration(
            color: AppColors.cardSurface,
            border: Border(top: BorderSide(color: AppColors.cardBorderStroke)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveItem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandAccent,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          isEdit ? 'SAVE CHANGES' : 'ADD CANTEEN ITEM',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
