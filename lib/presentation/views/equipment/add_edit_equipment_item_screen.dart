import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../../core/di/service_locator.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/interactive_feedback.dart';
import '../../../data/datasources/firestore_service.dart';
import '../../../domain/entities/stock_item.dart';

class AddEditEquipmentItemScreen extends StatefulWidget {
  final String companyId;
  final StockItem? existing;

  const AddEditEquipmentItemScreen({
    super.key,
    required this.companyId,
    this.existing,
  });

  @override
  State<AddEditEquipmentItemScreen> createState() =>
      _AddEditEquipmentItemScreenState();
}

class _AddEditEquipmentItemScreenState
    extends State<AddEditEquipmentItemScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _descCtrl;
  DateTime? _expiryDate;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.existing?.name ?? '');
    _stockCtrl = TextEditingController(
      text: widget.existing != null ? widget.existing!.stock.toString() : '5',
    );
    _descCtrl = TextEditingController(text: widget.existing?.desc ?? '');
    _expiryDate = widget.existing?.expiryDate;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          _expiryDate ?? DateTime.now().add(const Duration(days: 180)),
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

    if (name.isEmpty || stock == null) return;

    setState(() => _isSaving = true);

    final item = StockItem(
      id: widget.existing?.id ?? const Uuid().v4(),
      companyId: widget.companyId,
      name: name,
      stock: stock,
      price: null,
      desc: _descCtrl.text.trim(),
      expiryDate: _expiryDate,
      category: StockCategory.equipment,
      createdAt: widget.existing?.createdAt ?? DateTime.now(),
    );

    try {
      await sl<FirestoreService>().saveEquipmentItem(item);
      if (mounted) {
        AppHaptics.success();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existing == null
                  ? 'Added "$name" to equipment.'
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
              isEdit ? 'EDIT EQUIPMENT ITEM' : 'NEW EQUIPMENT ITEM',
              style: const TextStyle(
                color: AppColors.brandAccentLight,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            Text(
              isEdit ? widget.existing!.name : 'Add Snooker Equipment',
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
                          labelText: 'Equipment Name *',
                          hintText: 'e.g. Master Chalk, Cue Sticks, Table Cloth',
                        ),
                        validator: (val) => val == null || val.trim().isEmpty
                            ? 'Please enter equipment name'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Stock Count / Units *',
                          hintText: 'e.g. 12',
                        ),
                        validator: (val) {
                          final n = int.tryParse(val?.trim() ?? '');
                          if (n == null || n < 0) return 'Invalid stock count';
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _descCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText:
                              'e.g. Green Triangle Chalk Box, Ash Wood Cues',
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Expiry/Replacement Date Card
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
                                  'Expiry / Replacement Date (Optional)',
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
                                      : 'No date set',
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
                          isEdit ? 'SAVE CHANGES' : 'ADD EQUIPMENT ITEM',
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
