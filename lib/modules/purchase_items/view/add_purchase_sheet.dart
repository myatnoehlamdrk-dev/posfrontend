import 'package:flutter/material.dart';
import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';
import 'package:posfrontend/modules/purchase_items/viewmodel/purchase_item_view_model.dart';
import 'package:posfrontend/shared/theme/app_colors.dart';

class AddPurchaseSheet extends StatefulWidget {
  final PurchaseItemViewModel viewModel;
  final VoidCallback onAddSupplier;

  const AddPurchaseSheet({
    super.key,
    required this.viewModel,
    required this.onAddSupplier,
  });

  @override
  State<AddPurchaseSheet> createState() => _AddPurchaseSheetState();
}

class _AddPurchaseSheetState extends State<AddPurchaseSheet> {
  String? _selectedSupplierId;
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _priceController = TextEditingController();
  final _sizeController = TextEditingController();
  final _colorController = TextEditingController();
  final _dateController = TextEditingController(
    text: '${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );
  final _notesController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    _sizeController.dispose();
    _colorController.dispose();
    _dateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'New Purchase Order',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.titleColor),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.close, color: AppColors.gray),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.titleColor)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onAddSupplier();
                    },
                    child: const Text(
                      '+ Add Supplier',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.teal),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedSupplierId,
                    hint: const Text('Select a supplier...', style: TextStyle(color: AppColors.gray, fontSize: 14)),
                    items: widget.viewModel.suppliers.map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.name, style: const TextStyle(fontSize: 14)),
                    )).toList(),
                    onChanged: (val) => setState(() => _selectedSupplierId = val),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _inputField('Item / Product Name', 'e.g. All-Purpose Flour (50kg)', _nameController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _inputField('Size (optional)', 'e.g. Large', _sizeController)),
                  const SizedBox(width: 12),
                  Expanded(child: _inputField('Color (optional)', 'e.g. Red', _colorController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _inputField('Quantity', '0', _qtyController, isNumber: true)),
                  const SizedBox(width: 12),
                  Expanded(child: _inputField('Unit Price (MMK)', '0', _priceController, isNumber: true)),
                ],
              ),
              const SizedBox(height: 16),
              _inputField('Purchase Date (MM/DD/YYYY)', 'mm/dd/yyyy', _dateController),
              const SizedBox(height: 16),
              _inputField('Notes (optional)', 'Any notes...', _notesController),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_nameController.text.isEmpty) return;
                    final qty = int.tryParse(_qtyController.text) ?? 0;
                    final price = int.tryParse(_priceController.text) ?? 0;
                    if (qty <= 0) return;

                    final success = await widget.viewModel.createPurchaseItem(
                      productName: _nameController.text,
                      quantity: qty,
                      unitPrice: price,
                      date: _dateController.text,
                      supplierId: _selectedSupplierId,
                      notes: _notesController.text,
                      size: _sizeController.text,
                      color: _colorController.text,
                    );
                    if (success && context.mounted) {
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Create Purchase Order', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _inputField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.titleColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.gray, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.teal, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }
}
