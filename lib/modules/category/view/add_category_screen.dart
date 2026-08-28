import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/modules/inventory/view/inventory_sidebar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AddCategoryScreen extends StatefulWidget {
  final LoginResponse? user;
  final String inventoryType;
  const AddCategoryScreen({super.key, this.user, this.inventoryType = 'self'});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  String get _initials {
    final name = widget.user?.fullName.trim() ?? 'John Doe';
    final parts = name.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    try {
      final amountText = _amountController.text.trim();
      final amount = int.tryParse(amountText);
      final created = await CategoryRepositoryImpl().createCategory(
        type: widget.inventoryType,
        name: name,
        description: _descController.text.trim(),
        packageLimit: amount,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created')),
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
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _descController.dispose();
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
            body: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [sidebar, Expanded(child: body)]),
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
              title: 'Add Category',
              initials: _initials,
              showMenu: false,
            ),
            const SizedBox(height: 20),
            const Breadcrumb([
              BreadcrumbItem('Dashboard', false),
              BreadcrumbItem('Inventory', false),
              BreadcrumbItem('Categories', false),
              BreadcrumbItem('Add Category', true),
            ]),
            const SizedBox(height: 24),
            const Text(
              'Category Information',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTitle),
            ),
            const SizedBox(height: 6),
            const Text(
              'Provide the details for your new inventory category.',
              style: TextStyle(fontSize: 16, color: kGray),
            ),
            const SizedBox(height: 24),
            FormCard(
              label: 'Category Name',
              required: true,
              helper: 'Enter a name for this category.',
              child: CounterTextField(
                controller: _nameController,
                hint: 'Enter category name',
                max: 100,
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Amount of Packages (Limit)',
              helper:
                  'Maximum number of packages this category can hold.',
              child: CounterTextField(
                controller: _amountController,
                hint: '0',
                max: 11,
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 16),
            FormCard(
              label: 'Description',
              helper: 'Enter a brief description of this category.',
              child: CounterTextField(
                controller: _descController,
                hint: 'Enter category description',
                max: 300,
                maxLines: 4,
              ),
            ),
            const SizedBox(height: 24),
            FormActions(onCancel: () => Navigator.of(context).pop(), onSave: _save),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
