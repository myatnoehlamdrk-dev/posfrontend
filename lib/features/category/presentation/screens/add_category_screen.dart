import 'package:flutter/material.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:get_it/get_it.dart';
import 'package:posfrontend/features/category/domain/entities/category.dart';
import 'package:posfrontend/features/category/domain/repositories/category_repository.dart';
import 'package:posfrontend/features/category/presentation/viewmodels/add_category_view_model.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';
import 'package:posfrontend/shared/widgets/inventory_form_widgets.dart';
import 'package:posfrontend/shared/widgets/snackbar_helper.dart';

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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  late final AddCategoryViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AddCategoryViewModel(
      repository: GetIt.instance<CategoryRepository>(),
    );
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
    if (_viewModel.isSaving) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Category name is required');
      return;
    }

    // The controllers are what the user is actually looking at, but the view
    // model keeps its own copy of each field, filled from `onChanged` — which
    // only fires for edits the user makes. Anything that fills a controller
    // programmatically (a restored draft, an autofill, a paste through an IME
    // commit) leaves the view model's copy stale, and it then rejects a name
    // that is plainly on screen. Sync before saving so there is one source of
    // truth instead of two that can disagree.
    _viewModel
      ..setName(name)
      ..setDescription(_descController.text)
      ..setPackageLimit(_amountController.text);

    final success = await _viewModel.save(
      isEditing: widget.isEditing,
      categoryId: widget.existingCategory?.id,
      inventoryType: widget.inventoryType,
    );
    if (!mounted) return;
    if (success) {
      showSuccessSnackBar(
        context,
        widget.isEditing ? 'Category updated' : 'Category created',
      );
      Navigator.of(context).pop(_viewModel.result);
      return;
    }

    // `save` can fail without an error message — a field-level rejection sets
    // `fieldErrors` only. Showing nothing here is what made the button look
    // dead, so the field error is the fallback rather than the only answer.
    final message = _viewModel.hasError
        ? _viewModel.errorMessage
        : _viewModel.getFieldError('name');
    if (message != null && message.isNotEmpty) {
      showErrorSnackBar(context, message);
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
    // The view model is a plain instance, not a provider, so nothing rebuilds
    // this screen on `isSaving` / `fieldErrors` unless it listens explicitly.
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            final isWide = constraints.maxWidth >= 768;
            final body = _content();

            if (isWide) {
              return Scaffold(
                backgroundColor: ctx.palette.scaffoldBg,
                body: body,
              );
            }
            return Scaffold(
              backgroundColor: ctx.palette.scaffoldBg,
              body: body,
            );
          },
        );
      },
    );
  }

  Widget _content() {
    final isEdit = widget.isEditing;
    final p = context.palette;
    return SafeArea(
      child: Column(
        children: [
          AppScreenTopBar(
            title: isEdit ? 'Edit Category' : 'Add Category',
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
                    BreadcrumbItem(context.l10n.t('Dashboard'), false),
                    BreadcrumbItem(context.l10n.t('Inventory'), false),
                    const BreadcrumbItem('Categories', false),
                    BreadcrumbItem(
                      isEdit ? 'Edit Category' : 'Add Category',
                      true,
                    ),
                  ]),
                  const SizedBox(height: 24),
                  Text(
                    isEdit ? 'Edit Category' : 'Category Information',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: p.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isEdit
                        ? 'Update the details for this category.'
                        : 'Provide the details for your new inventory category.',
                    style: TextStyle(fontSize: 16, color: p.textSecondary),
                  ),
                  const SizedBox(height: 24),
                  FormCard(
                    label: context.l10n.t('Category Name'),
                    required: true,
                    helper: context.l10n.t('Enter a name for this category.'),
                    child: CounterTextField(
                      controller: _nameController,
                      hint: context.l10n.t('Enter category name'),
                      max: 100,
                      onChanged: _viewModel.setName,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FormCard(
                    label: context.l10n.t('Amount of Packages (Limit)'),
                    helper: context.l10n.t(
                      'Maximum number of packages this category can hold.',
                    ),
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
                    label: context.l10n.t('Description'),
                    helper: context.l10n.t(
                      'Enter a brief description of this category.',
                    ),
                    child: CounterTextField(
                      controller: _descController,
                      hint: context.l10n.t('Enter category description'),
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
                    loading: _viewModel.isSaving,
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
