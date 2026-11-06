import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/inventory/domain/entities/inventory_store_item.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_message.dart';

class EditInventoryStoreScreen extends StatefulWidget {
  final InventoryStoreItem item;
  const EditInventoryStoreScreen({super.key, required this.item});

  @override
  State<EditInventoryStoreScreen> createState() =>
      _EditInventoryStoreScreenState();
}

class _EditInventoryStoreScreenState extends State<EditInventoryStoreScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _upc;
  late final TextEditingController _brand;
  late final TextEditingController _description;
  late final TextEditingController _category;
  late final TextEditingController _location;
  late final TextEditingController _qoh;
  late final TextEditingController _qtyAvail;
  late final TextEditingController _safety;
  late final TextEditingController _reorder;
  late final TextEditingController _cost;
  late final TextEditingController _retail;
  late final TextEditingController _dimensions;
  late final TextEditingController _weight;
  late final TextEditingController _batch;
  late final TextEditingController _expiration;
  late final TextEditingController _bestBefore;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    _name = TextEditingController(text: i.name);
    _sku = TextEditingController(text: i.sku);
    _upc = TextEditingController();
    _brand = TextEditingController(text: i.brand);
    _description = TextEditingController();
    _category = TextEditingController(text: i.category);
    _location = TextEditingController();
    _qoh = TextEditingController(text: i.quantityOnHand.toString());
    _qtyAvail = TextEditingController(text: i.quantityAvailable.toString());
    _safety = TextEditingController(text: i.safetyStock.toString());
    _reorder = TextEditingController(text: i.reorderPoint.toString());
    _cost = TextEditingController(text: i.costPrice.toString());
    _retail = TextEditingController(text: i.retailPrice.toString());
    _dimensions = TextEditingController();
    _weight = TextEditingController();
    _batch = TextEditingController();
    _expiration = TextEditingController();
    _bestBefore = TextEditingController();
  }

  @override
  void dispose() {
    for (final c in [
      _name, _sku, _upc, _brand, _description, _category, _location,
      _qoh, _qtyAvail, _safety, _reorder, _cost, _retail, _dimensions,
      _weight, _batch, _expiration, _bestBefore,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ApiClient.instance.put('/inventory-stores/${widget.item.id}', data: {
        'name': _name.text.trim(),
        if (_sku.text.trim().isNotEmpty) 'sku': _sku.text.trim(),
        if (_upc.text.trim().isNotEmpty) 'universal_identifier': _upc.text.trim(),
        if (_brand.text.trim().isNotEmpty) 'brand': _brand.text.trim(),
        if (_description.text.trim().isNotEmpty)
          'description': _description.text.trim(),
        if (_category.text.trim().isNotEmpty) 'category': _category.text.trim(),
        if (_location.text.trim().isNotEmpty) 'location_id': _location.text.trim(),
        'quantity_on_hand': int.tryParse(_qoh.text.trim()) ?? 0,
        'quantity_available': int.tryParse(_qtyAvail.text.trim()) ?? 0,
        'safety_stock': int.tryParse(_safety.text.trim()) ?? 0,
        'reorder_point': int.tryParse(_reorder.text.trim()) ?? 0,
        'cost_price': double.tryParse(_cost.text.trim()) ?? 0,
        'retail_price': double.tryParse(_retail.text.trim()) ?? 0,
        if (_dimensions.text.trim().isNotEmpty)
          'dimensions': _dimensions.text.trim(),
        if (_weight.text.trim().isNotEmpty)
          'weight': double.tryParse(_weight.text.trim()),
        if (_batch.text.trim().isNotEmpty) 'batch_number': _batch.text.trim(),
        if (_expiration.text.trim().isNotEmpty)
          'expiration_date': _expiration.text.trim(),
        if (_bestBefore.text.trim().isNotEmpty)
          'best_before_date': _bestBefore.text.trim(),
      });
      if (mounted) {
        showSuccessMessage(context, context.l10n.t('Inventory item updated.'));
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) showErrorMessage(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _section(String title, AppPalette p) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
            color: p.textSecondary,
          ),
        ),
      );

  Widget _field(BuildContext context, String label, TextEditingController c,
      {TextInputType? kb, int maxLines = 1, bool required = false}) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: c,
        keyboardType: kb,
        maxLines: maxLines,
        validator: required
            ? (v) => (v == null || v.trim().isEmpty)
                ? context.l10n.t('Required')
                : null
            : null,
        decoration: InputDecoration(
          labelText: context.l10n.t(label),
          filled: true,
          fillColor: p.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: p.border),
          ),
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      appBar: AppBar(
        title: Text(context.l10n.t('Edit inventory item')),
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _section('Product identity', p),
            _field(context, 'Title / Name', _name, required: true),
            _field(context, 'Universal Identifier (UPC/EAN/ISBN)', _upc),
            _field(context, 'Brand / Manufacturer', _brand),
            _field(context, 'Description', _description, maxLines: 3),
            _field(context, 'Category / Taxonomy', _category),
            _field(context, 'SKU', _sku),

            _section('Location & inventory', p),
            _field(context, 'Location ID', _location),
            _field(context, 'Quantity On Hand (QOH)', _qoh,
                kb: TextInputType.number),
            _field(context, 'Quantity Available', _qtyAvail,
                kb: TextInputType.number),
            _field(context, 'Safety Stock', _safety, kb: TextInputType.number),
            _field(context, 'Reorder Point', _reorder, kb: TextInputType.number),

            _section('Pricing', p),
            _field(context, 'Cost Price (COGS)', _cost, kb: TextInputType.number),
            _field(context, 'Retail Price', _retail, kb: TextInputType.number),

            _section('Physical & batch', p),
            _field(context, 'Dimensions', _dimensions),
            _field(context, 'Weight', _weight, kb: TextInputType.number),
            _field(context, 'Batch / Lot Number', _batch),
            _field(context, 'Expiration Date (YYYY-MM-DD)', _expiration),
            _field(context, 'Best Before Date (YYYY-MM-DD)', _bestBefore),

            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: p.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        context.l10n.t('Save'),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}