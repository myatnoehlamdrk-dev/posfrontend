import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/package/repository/package_repository_impl.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AddPackageScreen extends StatefulWidget {
  final LoginResponse? user;
  final Category? category;
  const AddPackageScreen({super.key, this.user, this.category});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(text: '0');
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Category? _selectedCategory;
  String? _status;

  List<Category> _categoryObjects = [];
  final List<String> _statuses = const [
    'Overstock',
    'Optimal',
    'Low Stock',
    'Critical',
    'No Stock',
  ];

  String _labelOf(Category c) =>
      c.type.isNotEmpty ? '${c.name} (${c.type})' : c.name;

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package name is required')),
      );
      return;
    }
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    try {
      final amountText = _amountController.text.trim();
      final amount = int.tryParse(amountText);
      final created = await PackageRepositoryImpl().createPackage(
        categoryId: _selectedCategory!.id,
        name: name,
        productLimit: amount,
        description: _descController.text.trim(),
        location: _locationController.text.trim(),
        stockStatus: _status,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Package saved')),
      );
      Navigator.of(context).pop(created);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _status = _statuses[1];
    _selectedCategory = widget.category;
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await CategoryRepositoryImpl().getCategories();
      if (!mounted) return;
      setState(() {
        _categoryObjects = cats;
        if (widget.category != null) {
          _selectedCategory = cats.firstWhere(
            (c) => c.id == widget.category!.id,
            orElse: () => widget.category!,
          );
        }
      });
    } on ApiException {
      // Leave the category list empty on failure.
    }
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
    final categoryLabels = _categoryObjects.map(_labelOf).toList();
    final selectedLabel =
        _selectedCategory == null ? null : _labelOf(_selectedCategory!);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content(categoryLabels, selectedLabel);

        if (isWide) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 240,
                  child: AppDrawer(user: widget.user, activeItem: 'Inventory'),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: AppDrawer(user: widget.user, activeItem: 'Inventory'),
          body: body,
        );
      },
    );
  }

  Widget _content(List<String> categoryLabels, String? selectedLabel) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTopBar(
              title: 'Add Package',
              showMenuButton: false,
              showBackButton: true,
              user: widget.user,
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
              label: 'Category',
              required: true,
              helper: 'Select the category for this package.',
              child: DropdownField(
                value: selectedLabel,
                hint: 'Select category',
                items: categoryLabels,
                onChanged: (v) => setState(() {
                  _selectedCategory = _categoryObjects.firstWhere(
                    (c) => _labelOf(c) == v,
                    orElse: () => _selectedCategory!,
                  );
                }),
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
              label: 'Amount of Products (Limit)',
              required: true,
              helper: 'Maximum number of products this package can hold.',
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
