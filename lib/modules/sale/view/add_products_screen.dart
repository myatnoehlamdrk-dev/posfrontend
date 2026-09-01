import 'package:flutter/material.dart';
import 'package:posfrontend/modules/product/model/catalog_product.dart';
import 'package:posfrontend/modules/sale/model/sale_models.dart';
import 'package:posfrontend/modules/sale/repository/sale_product_repository_impl.dart';
import 'package:posfrontend/modules/sale/repository/sale_repository_impl.dart';
import 'package:posfrontend/modules/sale/viewmodel/sale_view_model.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/modules/shared/widgets/price_text.dart';

class AddProductsScreen extends StatefulWidget {
  const AddProductsScreen({super.key});

  @override
  State<AddProductsScreen> createState() => _AddProductsScreenState();
}

class _AddProductsScreenState extends State<AddProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final SaleViewModel _viewModel = SaleViewModel(
    productRepository: SaleProductRepositoryImpl(),
    saleRepository: SaleRepositoryImpl(),
  );
  String _selectedCategory = 'All';
  String _searchQuery = '';

  List<String> _categories = ['All'];

  final Map<String, int> _quantities = {};
  final Set<String> _selectedIds = {};
  final Set<String> _expandedIds = {};
  final Map<String, String> _selectedSizes = {};
  final Map<String, String> _selectedColors = {};
  final Map<String, TextEditingController> _notesCtrls = {};
  final Map<String, TextEditingController> _qtyCtrls = {};

  @override
  void initState() {
    super.initState();
    _viewModel.loadProducts();
    _viewModel.addListener(_onDataLoaded);
  }

  void _onDataLoaded() {
    if (!_viewModel.isLoading && _viewModel.errorMessage == null) {
      final cats = _viewModel.products
          .map((p) => p.category)
          .where((c) => c.isNotEmpty)
          .toSet()
          .toList();
      setState(() {
        _categories = ['All', ...cats];
        for (final p in _viewModel.products) {
          _quantities.putIfAbsent(p.id, () => 0);
          _selectedSizes.putIfAbsent(p.id, () => 'Regular');
          _selectedColors.putIfAbsent(p.id, () => '');
          _notesCtrls.putIfAbsent(p.id, () => TextEditingController());
          _qtyCtrls.putIfAbsent(p.id, () => TextEditingController(text: '0'));
        }
      });
    }
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onDataLoaded);
    _viewModel.dispose();
    _searchCtrl.dispose();
    for (final c in _notesCtrls.values) {
      c.dispose();
    }
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<CatalogProduct> get _filtered {
    return _viewModel.products.where((p) {
      final matchCat = _selectedCategory == 'All' || p.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          p.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.sku.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  int get _selectedCount => _selectedIds.length;

  double get _selectedTotal {
    double total = 0;
    for (final id in _selectedIds) {
      final p = _viewModel.products.firstWhere((x) => x.id == id);
      final qty = _quantities[id] ?? 0;
      double price = p.price;
      final size = _selectedSizes[id];
      if (size == 'Large') price += 2;
      if (size == 'XL') price += 4;
      total += price * qty;
    }
    return total;
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
        _quantities[id] = 0;
        _syncQtyCtrl(id);
      } else {
        _selectedIds.add(id);
        _quantities[id] = 2;
        _syncQtyCtrl(id);
      }
    });
  }

  void _updateQty(String id, int delta) {
    setState(() {
      final newQty = (_quantities[id] ?? 0) + delta;
      if (newQty <= 0) {
        _quantities[id] = 0;
        _selectedIds.remove(id);
      } else {
        _quantities[id] = newQty;
        _selectedIds.add(id);
      }
      _syncQtyCtrl(id);
    });
  }

  void _syncQtyCtrl(String id) {
    final ctrl = _qtyCtrls[id];
    if (ctrl != null) {
      final v = '${_quantities[id] ?? 0}';
      if (ctrl.text != v) {
        ctrl.value = TextEditingValue(
          text: v,
          selection: TextSelection.collapsed(offset: v.length),
        );
      }
    }
  }

  void _toggleExpanded(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  void _addToSale() {
    final items = <SaleItem>[];
    for (final id in _selectedIds) {
      final p = _viewModel.products.firstWhere((x) => x.id == id);
      final qty = _quantities[id] ?? 0;
      if (qty <= 0) continue;
      double price = p.price;
      final size = _selectedSizes[id];
      if (size == 'Large') price += 2;
      if (size == 'XL') price += 4;
      items.add(SaleItem(
        productId: p.id,
        productName: p.name,
        imageUrl: p.imageUrl,
        unitPrice: price,
        quantity: qty,
        size: size,
        color: _selectedColors[p.id],
        notes: _notesCtrls[p.id]?.text,
        category: p.category,
      ));
    }
    Navigator.of(context).pop(items);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        children: [
          _header(),
          _searchBar(),
          _categoryChips(),
          Expanded(child: _productList()),
          _bottomBar(),
        ],
      ),
    );
  }

  Widget _header() {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(Icons.close, size: 24, color: kTitle),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Add Products',
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: kTitle),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.filter_list, size: 18, color: kGray),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: InputDecoration(
          hintText: 'Search products by name, SKU, category...',
          hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: kGray, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorder),
          ),
        ),
      ),
    );
  }

  Widget _categoryChips() {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (ctx, index) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          final active = _selectedCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: active ? const Color(0xFF2563EB) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: active ? const Color(0xFF2563EB) : kBorder,
                ),
              ),
              child: Text(
                cat,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : kGray,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _productList() {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kPurple),
      );
    }
    if (_viewModel.hasError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_viewModel.errorMessage ?? 'Failed to load products',
                style: const TextStyle(color: kGray)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _viewModel.loadProducts(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(
        child: Text('No products found.', style: TextStyle(color: kGray)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: items.length,
      itemBuilder: (_, i) => _productCard(items[i]),
    );
  }

  Widget _productCard(CatalogProduct p) {
    final selected = _selectedIds.contains(p.id);
    final expanded = _expandedIds.contains(p.id);
    final qty = _quantities[p.id] ?? 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? const Color(0xFF2563EB) : kBorder,
          width: selected ? 2 : 1,
        ),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleSelect(p.id),
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF2563EB) : Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF2563EB)
                            : const Color(0xFFD1D5DB),
                      ),
                    ),
                    child: selected
                        ? const Icon(Icons.check, color: Colors.white, size: 14)
                        : null,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: p.color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: p.imageUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(p.imageUrl!, fit: BoxFit.cover),
                        )
                      : Icon(p.icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: kTitle)),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: p.stock > 0
                                  ? const Color(0xFFDCFCE7)
                                  : const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                                p.stock > 0 ? '${p.stock} in stock' : 'Out of stock',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: p.stock > 0
                                        ? const Color(0xFF16A34A)
                                        : const Color(0xFFDC2626))),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: PriceText(p.price,
                                maxLength: 10,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kTitle)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected) _qtyControl(p.id),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _toggleExpanded(p.id),
                  child: Icon(
                    expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: kGray,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          if (selected && qty > 0)
            Padding(
              padding: const EdgeInsets.only(left: 86, right: 10, bottom: 10),
              child: Row(
                children: [
                  const Text('Total:',
                      style: TextStyle(fontSize: 12, color: kGray)),
                  const SizedBox(width: 4),
                  PriceText(_itemTotal(p),
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTitle)),
                ],
              ),
            ),
          if (expanded && selected) _expandedSection(p),
        ],
      ),
    );
  }

  Widget _qtyControl(String productId) {
    final ctrl = _qtyCtrls[productId];
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: kBorder),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyBtn(Icons.remove, () => _updateQty(productId, -1)),
          SizedBox(
            width: 32,
            child: TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 4,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: kTitle),
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              onChanged: (v) {
                final n = int.tryParse(v) ?? 0;
                setState(() => _quantities[productId] = n);
              },
            ),
          ),
          _qtyBtn(Icons.add, () => _updateQty(productId, 1)),
        ],
      ),
    );
  }

  Widget _qtyBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        child: Icon(icon, size: 12, color: kGray),
      ),
    );
  }

  double _itemTotal(CatalogProduct p) {
    final qty = _quantities[p.id] ?? 0;
    final size = _selectedSizes[p.id];
    final color = _selectedColors[p.id];
    double price = p.price;
    for (final v in p.variants) {
      if ((size == null || size.isEmpty || v.size == size) &&
          (color == null || color.isEmpty || v.color == color)) {
        price = v.price;
        break;
      }
    }
    return price * qty;
  }

  Widget _expandedSection(CatalogProduct p) {
    final currentSize = _selectedSizes[p.id] ?? '';
    final currentColor = _selectedColors[p.id] ?? '';
    final sizes = p.sizes;
    final colors = p.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: kBorder),
          if (sizes.isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text('Size',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTitle)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sizes.map((s) {
                final active = currentSize == s;
                return GestureDetector(
                  onTap: () => setState(() => _selectedSizes[p.id] = s),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? const Color(0xFF2563EB) : kBorder,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? const Color(0xFF2563EB) : kGray,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
          if (colors.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Color',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: kTitle)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: colors.map((c) {
                final active = currentColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColors[p.id] = c),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: active ? const Color(0xFFEFF6FF) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: active ? const Color(0xFF2563EB) : kBorder,
                      ),
                    ),
                    child: Text(c,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: active ? const Color(0xFF2563EB) : kGray,
                        )),
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 16),
          const Text('Notes (Optional)',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kTitle)),
          const SizedBox(height: 8),
          TextField(
            controller: _notesCtrls[p.id],
            maxLines: 2,
            style: const TextStyle(fontSize: 13, color: kTitle),
            decoration: InputDecoration(
              hintText: 'Special instructions...',
              hintStyle: const TextStyle(color: Color(0xFFD1D5DB)),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorder)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: kBorder)),
              contentPadding: const EdgeInsets.all(10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: kBorder)),
        boxShadow: [
          BoxShadow(
              color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart, size: 28, color: kTitle),
                if (_selectedCount > 0)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF2563EB),
                        shape: BoxShape.circle,
                      ),
                      child: Text('$_selectedCount',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_selectedCount Items Selected',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: kTitle)),
                  PriceText(_selectedTotal,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: kTitle)),
                ],
              ),
            ),
            GestureDetector(
              onTap: _selectedCount > 0 ? _addToSale : null,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: _selectedCount > 0
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)])
                      : null,
                  color: _selectedCount > 0 ? null : const Color(0xFFD1D5DB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('Add to Sale',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
