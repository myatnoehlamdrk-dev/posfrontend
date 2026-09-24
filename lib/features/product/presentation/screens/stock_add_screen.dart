import 'dart:async';

import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/app_exceptions.dart';
import 'package:posfrontend/features/product/data/models/product_create_models.dart';
import 'package:posfrontend/features/product/data/repositories/product_create_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

const Color kPurple700 = Color(0xFF7C3AED);
const Color kLightPurple = Color(0xFFF5F0FF);
const Color kPurple900 = Color(0xFF5B21B6);

class StockAddScreen extends StatefulWidget {
  const StockAddScreen({super.key});

  @override
  State<StockAddScreen> createState() => _StockAddScreenState();
}

class _StockAddScreenState extends State<StockAddScreen> {
  final TextEditingController _search = TextEditingController();
  final ProductCreateRepositoryImpl _repository = ProductCreateRepositoryImpl();

  Timer? _debounce;
  bool _searching = false;
  List<ProductSearchResult> _results = [];

  ProductSearchResult? _selected;
  late List<TextEditingController> _variantControllers;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _variantControllers = [];
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    for (final c in _variantControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searching = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _searchProducts(query));
  }

  Future<void> _searchProducts(String query) async {
    setState(() => _searching = true);
    final results = await _repository.searchProducts(query.trim());
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  void _select(ProductSearchResult product) {
    setState(() {
      _selected = product;
      _results = [];
      _search.text = '';
      _variantControllers = product.variants.isEmpty
          ? [TextEditingController()]
          : product.variants.map((v) => TextEditingController()).toList();
    });
  }

  void _deselect() {
    setState(() {
      _selected = null;
      for (final c in _variantControllers) {
        c.dispose();
      }
      _variantControllers = [];
    });
  }

  String _variantLabel(Map<String, dynamic> v) {
    final size = (v['size'] ?? '').toString();
    final color = (v['color'] ?? '').toString();
    if (size.isEmpty && color.isEmpty) return 'Variant';
    if (size.isEmpty) return color;
    if (color.isEmpty) return size;
    return '$size · $color';
  }

  int _variantQuantity(Map<String, dynamic> v) {
    final qty = v['quantity'];
    if (qty is num) return qty.toInt();
    return 0;
  }

  Future<void> _submit() async {
    final product = _selected;
    if (product == null) return;

    if (_variantControllers.any((c) => c.text.trim().isNotEmpty && (int.tryParse(c.text.trim()) ?? -1) < 0)) {
      showErrorMessage(context, 'Enter a valid stock amount');
      return;
    }

    setState(() => _saving = true);
    try {
      final request = _buildRequest(product);
      await _repository.updateProduct(product.id, request);
      if (!mounted) return;
      showSuccessMessage(context, 'Stock added successfully');
      _deselect();
    } on ApiException catch (e) {
      showErrorMessage(context, e.message);
    } catch (_) {
      showErrorMessage(context, 'Failed to add stock');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  ProductCreateRequest _buildRequest(ProductSearchResult product) {
    if (product.variants.isEmpty) {
      final added = int.tryParse(_variantControllers.first.text.trim()) ?? 0;
      return ProductCreateRequest(
        name: product.name,
        stock: product.stock + added,
        variants: const [],
      );
    }

    final updated = product.variants.asMap().entries.map((e) {
      final i = e.key;
      final v = e.value;
      final added = int.tryParse(_variantControllers[i].text.trim()) ?? 0;
      return {
        ...v,
        'quantity': _variantQuantity(v) + added,
      };
    }).toList();

    return ProductCreateRequest(
      name: product.name,
      variants: updated.map((v) => ProductCreateVariant(
        size: (v['size'] ?? '').toString(),
        color: (v['color'] ?? '').toString(),
        quantity: (v['quantity'] as num).toInt(),
        price: ((v['price'] ?? 0) as num).toDouble(),
      )).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(
                title: 'Stock Add',
                showMenuButton: false,
                showBackButton: true,
              ),
              const SizedBox(height: 20),
              FormCard(
                label: 'Search Product',
                helper: 'Search a product to add stock.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _searchField(),
                    if (_searching)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: CircularProgressIndicator(color: kPurple700, strokeWidth: 2.5),
                        ),
                      )
                    else if (_results.isNotEmpty)
                      ..._results.map((p) => _resultTile(p)),
                  ],
                ),
              ),
              if (_selected != null) ...[
                const SizedBox(height: 16),
                FormCard(
                  label: 'Add Stock',
                  helper: 'Enter the amount of stock to add.',
                  child: _stockForm(),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selected != null ? _submitButton() : null,
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _search,
      onChanged: _onSearchChanged,
      decoration: InputDecoration(
        hintText: 'Search products...',
        hintStyle: const TextStyle(color: kGray, fontSize: 14),
        prefixIcon: const Icon(Icons.search, color: kGray),
        filled: true,
        fillColor: kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPurple700),
        ),
      ),
    );
  }

  Widget _resultTile(ProductSearchResult p) {
    return InkWell(
      onTap: () => _select(p),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        margin: const EdgeInsets.only(top: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: kBorder),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: p.imageUrl.isNotEmpty
                  ? Image.network(
                      p.imageUrl,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _placeholderIcon(),
                    )
                  : _placeholderIcon(),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: kTitle),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (p.brand.isNotEmpty)
                    Text(
                      p.brand,
                      style: const TextStyle(fontSize: 12, color: kGray),
                      overflow: TextOverflow.ellipsis,
                    ),
                  Text(
                    p.variants.isEmpty
                        ? 'Stock: ${p.stock}'
                        : 'Stock: ${p.stock} · ${p.variants.length} variants',
                    style: const TextStyle(fontSize: 12, color: kGray),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: kGray),
          ],
        ),
      ),
    );
  }

  Widget _placeholderIcon() {
    return Container(
      width: 40,
      height: 40,
      color: kLightPurple,
      child: const Icon(Icons.inventory_2_outlined, color: kPurple700, size: 20),
    );
  }

  Widget _stockForm() {
    final product = _selected!;

    if (product.variants.isEmpty) {
      return _stockRow('Stock', 'Current: ${product.stock}', _variantControllers.first);
    }

    return Column(
      children: product.variants.asMap().entries.map((e) {
        final i = e.key;
        final v = e.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _stockRow(
            _variantLabel(v),
            'Current: ${_variantQuantity(v)}',
            _variantControllers[i],
          ),
        );
      }).toList(),
    );
  }

  Widget _stockRow(String label, String current, TextEditingController c) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: kTitle)),
              const SizedBox(height: 4),
              Text(current, style: const TextStyle(fontSize: 12, color: kGray)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: TextField(
            controller: c,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Add',
              hintStyle: const TextStyle(color: kGray, fontSize: 14),
              filled: true,
              fillColor: kBg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: kPurple700),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, -2)),
        ],
      ),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: _saving ? null : kPurpleGradient,
          color: _saving ? kGray : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _saving ? null : _submit,
            child: Center(
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                    )
                  : const Text(
                      'Add Stock',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}