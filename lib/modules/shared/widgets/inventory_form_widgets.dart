import 'package:flutter/material.dart';

const Color kTitle = Color(0xFF111827);
const Color kGray = Color(0xFF6B7280);
const Color kPurple = Color(0xFF6D28D9);
const Color kBorder = Color(0xFFE5E7EB);
const Color kBg = Color(0xFFFFFFFF);
const Color kRed = Color(0xFFEF4444);
const Color kFieldFill = Color(0xFFF9FAFB);

const LinearGradient kPurpleGradient = LinearGradient(
  colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
  begin: Alignment.centerLeft,
  end: Alignment.centerRight,
);

InputDecoration fieldDecoration(String hint, {bool alignRight = false}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: kGray, fontSize: 14),
    filled: true,
    fillColor: kBg,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
    disabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: kBorder),
    ),
  );
}

class InventoryHeader extends StatelessWidget {
  final String title;
  final String initials;
  final VoidCallback? onBack;
  final bool showMenu;
  final VoidCallback? onMenu;

  const InventoryHeader({
    super.key,
    required this.title,
    required this.initials,
    this.onBack,
    this.showMenu = false,
    this.onMenu,
  });

  @override
  Widget build(BuildContext ctx) {
    return Row(
      children: [
        if (showMenu)
          IconButton(
            icon: const Icon(Icons.menu, color: kTitle),
            onPressed: onMenu,
          )
        else
          IconButton(
            icon: const Icon(Icons.arrow_back, color: kTitle),
            onPressed: onBack ?? () => Navigator.of(ctx).pop(),
          ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: kTitle,
            ),
          ),
        ),
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_outlined, color: kTitle),
              onPressed: () {},
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: kRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 8),
        CircleAvatar(
          radius: 20,
          backgroundColor: kPurple,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}

class InventoryBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const InventoryBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: kPurple,
      unselectedItemColor: kGray,
      type: BottomNavigationBarType.fixed,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Inventory'),
        BottomNavigationBarItem(icon: Icon(Icons.category), label: 'Product'),
        BottomNavigationBarItem(icon: Icon(Icons.point_of_sale), label: 'Sale'),
        BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
      ],
    );
  }
}

class BreadcrumbItem {
  final String label;
  final bool active;
  const BreadcrumbItem(this.label, this.active);
}

class Breadcrumb extends StatelessWidget {
  final List<BreadcrumbItem> items;
  const Breadcrumb(this.items, {super.key});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      if (i > 0) {
        children.add(const Text('  >  ', style: TextStyle(fontSize: 13, color: kGray)));
      }
      children.add(
        Text(
          items[i].label,
          style: TextStyle(
            fontSize: 13,
            color: items[i].active ? kGray : kPurple,
          ),
        ),
      );
    }
    return Wrap(children: children);
  }
}

class FormCard extends StatelessWidget {
  final String label;
  final String? helper;
  final bool required;
  final Widget child;

  const FormCard({
    super.key,
    required this.label,
    this.helper,
    this.required = false,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kTitle,
                ),
              ),
              if (required)
                const Text(' *', style: TextStyle(color: kRed, fontSize: 15)),
            ],
          ),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(
              helper!,
              style: const TextStyle(fontSize: 13, color: kGray),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class DisabledField extends StatelessWidget {
  final IconData icon;
  final String value;
  final bool alignRight;

  const DisabledField({
    super.key,
    required this.icon,
    required this.value,
    this.alignRight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: kFieldFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: kGray),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              textAlign: alignRight ? TextAlign.right : TextAlign.left,
              style: const TextStyle(fontSize: 14, color: kGray),
            ),
          ),
        ],
      ),
    );
  }
}

class CounterTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int max;
  final int maxLines;
  final TextInputType? keyboardType;

  const CounterTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.max,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          onChanged: (_) {},
          decoration: fieldDecoration(hint),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Text(
              '${controller.text.length} / $max',
              style: const TextStyle(fontSize: 12, color: kGray),
            ),
          ),
        ),
      ],
    );
  }
}

class DropdownField extends StatelessWidget {
  final String? value;
  final String hint;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const DropdownField({
    super.key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: kGray, fontSize: 14)),
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class FormActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final String saveLabel;

  const FormActions({
    super.key,
    required this.onCancel,
    required this.onSave,
    this.saveLabel = 'Save',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton(
              onPressed: onCancel,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: kBorder),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: kTitle,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              gradient: kPurpleGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onSave,
                child: Center(
                  child: Text(
                    saveLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class InfoBox extends StatelessWidget {
  final String title;
  final String body;

  const InfoBox({super.key, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F0FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: kPurple),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: kTitle,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(fontSize: 13, color: kGray),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
