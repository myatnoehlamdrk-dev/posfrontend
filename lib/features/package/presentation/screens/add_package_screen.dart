import 'package:flutter/material.dart';
import 'package:posfrontend/core/network/api_client.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/features/package/domain/entities/package.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

class AddPackageScreen extends StatefulWidget {
  final Category? category;
  final PackageEntity? existingPackage;
  const AddPackageScreen({super.key, this.category, this.existingPackage});

  bool get isEditing => existingPackage != null;

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController(
    text: '0',
  );
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  Category? _selectedCategory;

  List<Category> _categoryObjects = [];

  String _labelOf(Category c) =>
      c.type.isNotEmpty ? '${c.name} (${c.type})' : c.name;

  @override
  void initState() {
    super.initState();
    if (widget.existingPackage != null) {
      final p = widget.existingPackage!;
      _nameController.text = p.name;
      _amountController.text = p.productLimit > 0
          ? p.productLimit.toString()
          : '0';
      _descController.text = p.spec;
      _locationController.text = p.location;
    }
    _selectedCategory = widget.category;
    _loadCategories();
  }

  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Package name is required');
      return;
    }
    if (_selectedCategory == null) {
      showErrorSnackBar(context, 'Please select a category');
      return;
    }

    setState(() => _saving = true);
    try {
      final amountText = _amountController.text.trim();
      final amount = int.tryParse(amountText);

      if (widget.isEditing) {
        final existing = widget.existingPackage;
        final cat = _selectedCategory;
        if (existing == null || cat == null) return;
        final updated = await PackageRepositoryImpl().updatePackage(
          id: existing.id,
          categoryId: cat.id,
          name: name,
          productLimit: amount,
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          stockStatus: null,
        );
        if (!mounted) return;
        showSuccessSnackBar(context, 'Package updated');
        Navigator.of(context).pop(updated);
      } else {
        final created = await PackageRepositoryImpl().createPackage(
          categoryId: _selectedCategory!.id,
          name: name,
          productLimit: amount,
          description: _descController.text.trim(),
          location: _locationController.text.trim(),
          stockStatus: null,
        );
        if (!mounted) return;
        showSuccessSnackBar(context, 'Package saved');
        Navigator.of(context).pop(created);
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
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
        } else if (widget.existingPackage != null && cats.isNotEmpty) {
          _selectedCategory = cats.firstWhere(
            (c) => c.id == widget.existingPackage!.categoryId,
            orElse: () => cats.first,
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
    final selectedLabel = _selectedCategory == null
        ? null
        : _labelOf(_selectedCategory!);

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isWide = constraints.maxWidth >= 768;
        final body = _content(categoryLabels, selectedLabel);

        if (isWide) {
          return Scaffold(backgroundColor: Colors.white, body: body);
        }
        return Scaffold(backgroundColor: Colors.white, body: body);
      },
    );
  }

  Widget _content(List<String> categoryLabels, String? selectedLabel) {
    final isEdit = widget.isEditing;
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: isEdit ? 'Edit Package' : 'Add Package',
            showMenuButton: false,
            showBackButton: true,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Breadcrumb([
                    const BreadcrumbItem('Dashboard', false),
                    const BreadcrumbItem('Inventory', false),
                    const BreadcrumbItem('Packages', false),
                    BreadcrumbItem(
                      isEdit ? 'Edit Package' : 'Add Package',
                      true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    isEdit ? 'Edit Package' : 'Package Information',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: kTitle,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEdit
                        ? 'Update the details for this package.'
                        : 'Provide the details for your new inventory package.',
                    style: const TextStyle(fontSize: 16, color: kGray),
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
                  FormActions(
                    onCancel: () => Navigator.of(context).pop(),
                    onSave: _save,
                    saveLabel: isEdit ? 'Update Package' : 'Save Package',
                    loading: _saving,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
