import 'package:flutter/material.dart';
import 'package:posfrontend/modules/category/model/category_models.dart';
import 'package:posfrontend/modules/category/repository/category_repository_impl.dart';
import 'package:posfrontend/modules/category/viewmodel/add_category_view_model.dart';
import 'package:posfrontend/shared/widgets/app_drawer.dart';
import 'package:posfrontend/shared/widgets/app_top_bar.dart';
import 'package:posfrontend/shared/widgets/error_snackbar.dart';
import 'package:posfrontend/modules/shared/widgets/inventory_form_widgets.dart';

class AddCategoryScreen extends StatefulWidget {
  final String inventoryType;
  final Category? existingCategory;
  const AddCategoryScreen({
    super.key,
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
  late final AddCategoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AddCategoryViewModel(repository: CategoryRepositoryImpl());
    if (widget.existingCategory != null) {
      _viewModel.loadExisting(widget.existingCategory!);
      _nameController.text = widget.existingCategory!.name;
      _amountController.text = widget.existingCategory!.packageLimit > 0
          ? widget.existingCategory!.packageLimit.toString()
          : '';
      _descController.text = widget.existingCategory!.description;
    }
  }

  Future<void> _save() async {
    final success = await _viewModel.save(
      isEditing: widget.isEditing,
      categoryId: widget.existingCategory?.id,
      inventoryType: widget.inventoryType,
    );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.isEditing ? 'Category updated' : 'Category created'),
        ),
      );
      Navigator.of(context).pop(_viewModel.result);
    } else if (_viewModel.hasError && mounted) {
      showErrorSnackBar(context, _viewModel.errorMessage!);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
                    child: AppDrawer(activeItem: 'Inventory'),
                ),
                Expanded(child: body),
              ],
            ),
          );
        }
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.white,
          drawer: AppDrawer(activeItem: 'Inventory'),
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
                onChanged: _viewModel.setName,
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
                onChanged: _viewModel.setPackageLimit,
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
                onChanged: _viewModel.setDescription,
              ),
            ),
            const SizedBox(height: 24),
            FormActions(
              onCancel: () => Navigator.of(context).pop(),
              onSave: _viewModel.isSaving ? null : _save,
              saveLabel: isEdit ? 'Update Category' : 'Save Category',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
