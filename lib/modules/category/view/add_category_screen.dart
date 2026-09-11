import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/core/utils/error_handler.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/modules/login/model/login_response.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AddCategoryScreen extends StatefulWidget {
  final LoginResponse? user;
  final String inventoryType;
  final Category? existingCategory;
  const AddCategoryScreen({
    super.key,
    this.user,
    this.inventoryType = 'self',
    this.existingCategory,
  });

  bool get isEditing => existingCategory != null;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingCategory != null) {
      final c = widget.existingCategory!;
      _nameController.text = c.name;
      _amountController.text = c.packageLimit > 0 ? c.packageLimit.toString() : '';
      _descController.text = c.description;
    }
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final amountText = _amountController.text.trim();
      final amount = int.tryParse(amountText);

      if (widget.isEditing) {
        final existing = widget.existingCategory;
        if (existing == null) return;
        final updated = await CategoryRepositoryImpl().updateCategory(
          id: existing.id,
          name: name,
          description: _descController.text.trim(),
          packageLimit: amount,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Category updated')),
        );
        Navigator.of(context).pop(updated);
      } else {
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
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(formatApiError(e))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content();

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

  Widget _content() {
    final isEdit = widget.isEditing;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTopBar(
              title: isEdit ? 'Edit Category' : 'Add Category',
              showMenuButton: false,
              showBackButton: true,
              user: widget.user,
            ),
            const SizedBox(height: 20),
            Breadcrumb([
              const BreadcrumbItem('Dashboard', false),
              const BreadcrumbItem('Inventory', false),
              const BreadcrumbItem('Categories', false),
              BreadcrumbItem(isEdit ? 'Edit Category' : 'Add Category', true),
            ]),
            const SizedBox(height: 24),
            Text(
              isEdit ? 'Edit Category' : 'Category Information',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: kTitle),
            ),
            const SizedBox(height: 6),
            Text(
              isEdit
                  ? 'Update the details for this category.'
                  : 'Provide the details for your new inventory category.',
              style: const TextStyle(fontSize: 16, color: kGray),
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
            FormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _save,
              saveLabel: isEdit ? 'Update Category' : 'Save Category',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
