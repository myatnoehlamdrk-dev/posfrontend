import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AddPackageScreen extends StatefulWidget {
  final LoginResponse? user;
  const AddPackageScreen({super.key, this.user});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  String? _category;
  String? _status;

  final List<String> _categories = CategoryRepositoryImpl()
      .getCategories()
      .map((c) => c.name)
      .toList();
  final List<String> _statuses = const [
    'Overstock',
    'Optimal',
    'Low Stock',
    'Critical',
    'No Stock',
  ];

  String get _initials {
    final name = widget.user?.fullName.trim() ?? 'John Doe';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Package saved')),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sidebar = InventorySidebar(
      user: widget.user,
      activeItem: 'Inventory',
      onNavigate: (_) {},
    );

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content();

        if (isWide) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Row(children: [sidebar, Expanded(child: body)]),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: Drawer(child: sidebar),
          body: body,
        );
      },
    );
  }

  Widget _content() {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InventoryHeader(
              title: 'Add Package',
              initials: _initials,
              showMenu: false,
            ),
            const SizedBox(height: 20),
            const Breadcrumb([
              BreadcrumbItem('Dashboard', false),
              BreadcrumbItem('Inventory', false),
              BreadcrumbItem('Packages', false),
              BreadcrumbItem('Add Package', true),
            ]),
            const SizedBox(height: 24),
            const Text(
              'Package Information',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTitle),
            ),
            const SizedBox(height: 6),
            const Text(
              'Provide the details for your new inventory package.',
              style: TextStyle(fontSize: 16, color: kGray),
            ),
            const SizedBox(height: 24),
            FormCard(
              label: 'Package ID',
              helper: 'Automatically generated.',
              child: const DisabledField(
                icon: Icons.shield,
                value: 'PKG-2024-00058',
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Category ID',
              required: true,
              helper: 'Select the category for this package.',
              child: DropdownField(
                value: _category,
                hint: 'Select category',
                items: _categories,
                onChanged: (v) => setState(() => _category = v),
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Package Name',
              required: true,
              helper: 'Enter a name for this package.',
              child: CounterTextField(
                controller: _nameController,
                hint: 'Enter package name',
                max: 100,
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Amount of Products',
              required: true,
              helper: 'Total number of products in this package.',
              child: TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.right,
                decoration: fieldDecoration('Enter amount of products'),
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Description',
              helper: 'Enter a brief description of this package.',
              child: CounterTextField(
                controller: _descController,
                hint: 'Enter package description',
                max: 300,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Location',
              helper: 'Specify where this package is stored.',
              child: CounterTextField(
                controller: _locationController,
                hint: 'Enter location (e.g., Aisle 1, Shelf 2)',
                max: 100,
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Stock Status',
              required: true,
              helper: 'Current stock analysis based on amount of products.',
              child: DropdownField(
                value: _status,
                hint: 'Select stock status',
                items: _statuses,
                onChanged: (v) => setState(() => _status = v),
              ),
            ),
            const SizedBox(height: 16),
            const InfoBox(
              title: 'About Stock Status',
              body:
                  'Indicates how the current amount compares to expected or target levels. Examples: Overstock, Optimal, Low Stock, Critical, No Stock.',
            ),
            const SizedBox(height: 24),
            FormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
              saveLabel: 'Save Package',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
