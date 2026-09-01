import 'package:flutter/material.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/purchase_items/model/purchase_models.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';

class PurchaseItemsScreen extends StatefulWidget {
  final LoginResponse? user;

  const PurchaseItemsScreen({super.key, this.user});

  @override
  State<PurchaseItemsScreen> createState() => _PurchaseItemsScreenState();
}

class _PurchaseItemsScreenState extends State<PurchaseItemsScreen> {
  int _selectedTab = 0;
  final _searchController = TextEditingController();

  static const Color teal = Color(0xFF14B8A6);
  static const Color tealDark = Color(0xFF0F9D8A);
  static const Color titleColor = Color(0xFF111827);
  static const Color gray = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5E7EB);
  static const Color green = Color(0xFF16A34A);
  static const Color greenBg = Color(0xFFDCFCE7);
  static const Color orange = Color(0xFFD97706);
  static const Color orangeBg = Color(0xFFFEF3C7);

  final List<Supplier> _suppliers = [
    const Supplier(id: 'SUP-001', name: 'Golden Harvest Co.', phone: '09-1234-5678', address: 'No.12, Market St, Yangon'),
    const Supplier(id: 'SUP-002', name: 'Fresh Farm Supply', phone: '09-8765-4321', address: 'No.45, Farm Road, Mandalay'),
    const Supplier(id: 'SUP-003', name: 'City Beverage Ltd.', phone: '09-1111-2222', address: 'No.78, Business Ave, Yangon'),
  ];

  final List<PurchaseOrder> _orders = [
    const PurchaseOrder(orderId: 'PUR-2025-0001', supplierId: 'SUP-001', supplierName: 'Golden Harvest Co.', productName: 'All-Purpose Flour (50kg)', quantity: 10, unitPrice: 45000, date: '30 Aug 2025', status: PurchaseStatus.completed),
    const PurchaseOrder(orderId: 'PUR-2025-0002', supplierId: 'SUP-002', supplierName: 'Fresh Farm Supply', productName: 'Fresh Tomatoes (10kg)', quantity: 20, unitPrice: 5000, date: '30 Aug 2025', status: PurchaseStatus.completed),
    const PurchaseOrder(orderId: 'PUR-2025-0003', supplierId: 'SUP-003', supplierName: 'City Beverage Ltd.', productName: 'Coca-Cola (24 cans)', quantity: 15, unitPrice: 12000, date: '31 Aug 2025', status: PurchaseStatus.completed),
    const PurchaseOrder(orderId: 'PUR-2025-0004', supplierId: 'SUP-001', supplierName: 'Golden Harvest Co.', productName: 'Cheese Block (5kg)', quantity: 8, unitPrice: 35000, date: '31 Aug 2025', status: PurchaseStatus.pending),
    const PurchaseOrder(orderId: 'PUR-2025-0005', supplierId: 'SUP-002', supplierName: 'Fresh Farm Supply', productName: 'Fresh Milk (1L x 12)', quantity: 12, unitPrice: 8000, date: '01 Sep 2025', status: PurchaseStatus.pending),
  ];

  List<PurchaseOrder> get _filteredOrders {
    var list = _orders;
    if (_selectedTab == 1) {
      list = list.where((o) => o.status == PurchaseStatus.completed).toList();
    } else if (_selectedTab == 2) {
      list = list.where((o) => o.status == PurchaseStatus.pending).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((o) =>
          o.orderId.toLowerCase().contains(query) ||
          o.productName.toLowerCase().contains(query) ||
          o.supplierName.toLowerCase().contains(query)).toList();
    }
    return list;
  }

  int get _allCount => _orders.length;
  int get _completedCount => _orders.where((o) => o.status == PurchaseStatus.completed).length;
  int get _pendingCount => _orders.where((o) => o.status == PurchaseStatus.pending).length;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      drawer: AppDrawer(user: widget.user, activeItem: 'Purchase Item'),
      floatingActionButton: FloatingActionButton(
        onPressed: _showNewPurchaseSheet,
        backgroundColor: teal,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    const Text(
                      'Manage purchase orders from your suppliers',
                      style: TextStyle(fontSize: 13, color: gray),
                    ),
                    const SizedBox(height: 16),
                    _buildTabs(),
                    const SizedBox(height: 16),
                    _buildSearchBar(),
                    const SizedBox(height: 16),
                    ..._filteredOrders.map((order) => _buildOrderCard(order)),
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: border, width: 1)),
      ),
      child: Row(
        children: [
          Builder(
            builder: (ctx) => IconButton(
              onPressed: () => Scaffold.of(ctx).openDrawer(),
              icon: const Icon(Icons.menu, color: titleColor),
            ),
          ),
          const Expanded(
            child: Center(
              child: Text(
                'Purchase Items',
                style: TextStyle(color: titleColor, fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          Stack(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined, color: titleColor),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
          CircleAvatar(
            radius: 18,
            backgroundColor: teal,
            child: Text(
              widget.user != null && widget.user!.fullName.trim().isNotEmpty
                  ? widget.user!.fullName.trim()[0].toUpperCase()
                  : 'A',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    final tabs = [('All', _allCount), ('Completed', _completedCount), ('Pending', _pendingCount)];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = i == _selectedTab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? teal : Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    '${tabs[i].$1} (${tabs[i].$2})',
                    style: TextStyle(color: active ? Colors.white : gray, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        decoration: const InputDecoration(
          hintText: 'Search item, order ID, supplier...',
          hintStyle: TextStyle(color: gray, fontSize: 14),
          prefixIcon: Icon(Icons.search, color: gray, size: 22),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrder order) {
    final isCompleted = order.status == PurchaseStatus.completed;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.inventory_2_outlined, color: gray, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderId}',
                      style: const TextStyle(fontSize: 12, color: gray, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.productName,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: titleColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? greenBg : orangeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Pending',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isCompleted ? green : orange),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: border, height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.business_outlined, size: 14, color: gray),
              const SizedBox(width: 4),
              Text(order.supplierName, style: const TextStyle(fontSize: 12, color: gray)),
              const Spacer(),
              Text(
                'x${order.quantity}',
                style: const TextStyle(fontSize: 12, color: gray, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Text('@', style: TextStyle(fontSize: 12, color: gray)),
              const SizedBox(width: 4),
              Text(
                'MMK ${_formatAmount(order.unitPrice)}',
                style: const TextStyle(fontSize: 12, color: gray),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: gray),
              const SizedBox(width: 4),
              Text(order.date, style: const TextStyle(fontSize: 11, color: gray)),
              const Spacer(),
              Text(
                'MMK ${_formatAmount(order.totalAmount)}',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: tealDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNewPurchaseSheet() {
    String? selectedSupplierId;
    final nameController = TextEditingController();
    final qtyController = TextEditingController();
    final priceController = TextEditingController();
    final dateController = TextEditingController(text: '08/31/2025');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                          decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'New Purchase Order',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: titleColor),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(ctx),
                            child: const Icon(Icons.close, color: gray),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          const Text('Supplier', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
                          const Spacer(),
                          GestureDetector(
                            onTap: () {
                              Navigator.pop(ctx);
                              _showAddSupplierSheet();
                            },
                            child: const Text(
                              '+ Add Supplier',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: teal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: selectedSupplierId,
                            hint: const Text('Select a supplier...', style: TextStyle(color: gray, fontSize: 14)),
                            items: _suppliers.map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, style: const TextStyle(fontSize: 14)),
                            )).toList(),
                            onChanged: (val) => setSheetState(() => selectedSupplierId = val),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _inputField('Item / Product Name', 'e.g. All-Purpose Flour (50kg)', nameController),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _inputField('Quantity', '0', qtyController, isNumber: true)),
                          const SizedBox(width: 12),
                          Expanded(child: _inputField('Unit Price (MMK)', '0', priceController, isNumber: true)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _inputField('Purchase Date', 'mm/dd/yyyy', dateController),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: () {
                            if (selectedSupplierId != null && nameController.text.isNotEmpty) {
                              final supplier = _suppliers.firstWhere((s) => s.id == selectedSupplierId);
                              final qty = int.tryParse(qtyController.text) ?? 1;
                              final price = int.tryParse(priceController.text) ?? 0;
                              setState(() {
                                _orders.insert(0, PurchaseOrder(
                                  orderId: 'PUR-2025-${(_orders.length + 1).toString().padLeft(4, '0')}',
                                  supplierId: supplier.id,
                                  supplierName: supplier.name,
                                  productName: nameController.text,
                                  quantity: qty,
                                  unitPrice: price,
                                  date: dateController.text,
                                  status: PurchaseStatus.pending,
                                ));
                              });
                              Navigator.pop(ctx);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: teal,
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
          },
        );
      },
    );
  }

  void _showAddSupplierSheet() {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final addressController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
                      decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add New Supplier',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: titleColor),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(ctx),
                        child: const Icon(Icons.close, color: gray),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _inputField('Supplier Name', 'e.g. Golden Harvest Co.', nameController),
                  const SizedBox(height: 16),
                  _inputField('Contact / Phone', 'e.g. 09-1234-5678', phoneController),
                  const SizedBox(height: 16),
                  _inputField('Address', 'e.g. No.12, Market St, Yangon', addressController),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameController.text.isNotEmpty) {
                          setState(() {
                            _suppliers.add(Supplier(
                              id: 'SUP-${(_suppliers.length + 1).toString().padLeft(3, '0')}',
                              name: nameController.text,
                              phone: phoneController.text,
                              address: addressController.text,
                            ));
                          });
                          Navigator.pop(ctx);
                          _showNewPurchaseSheet();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Save Supplier', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _inputField(String label, String hint, TextEditingController controller, {bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: titleColor)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: gray, fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: teal, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  String _formatAmount(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }
}
