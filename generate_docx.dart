import 'dart:io';
import 'dart:convert';
import 'package:archive/archive.dart';

void main() {
  final contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
  <Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>
  <Override PartName="/docProps/app.xml" ContentType="application/vnd.openxmlformats-officedocument.extended-properties+xml"/>
</Types>''';

  final rels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/extended-properties" Target="docProps/app.xml"/>
</Relationships>''';

  final coreXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <dc:title>Function Requirements - POS System</dc:title>
  <dc:subject>POS System Functional Requirements</dc:subject>
  <dc:creator>POS Development Team</dc:creator>
</cp:coreProperties>''';

  final appXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Properties xmlns="http://schemas.openxmlformats.org/officeDocument/2006/extended-properties">
  <Application>POS System</Application>
</Properties>''';

  final wordRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

  final stylesXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="heading 1"/>
    <w:pPr><w:spacing w:before="360" w:after="200"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="32"/><w:color w:val="7C3AED"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="heading 2"/>
    <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="26"/><w:color w:val="5B21B6"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading3">
    <w:name w:val="heading 3"/>
    <w:pPr><w:spacing w:before="200" w:after="80"/></w:pPr>
    <w:rPr><w:b/><w:sz w:val="22"/><w:color w:val="111827"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:pPr><w:spacing w:after="120" w:line="276" w:lineRule="auto"/></w:pPr>
    <w:rPr><w:sz w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="ListParagraph">
    <w:name w:val="List Paragraph"/>
    <w:pPr><w:ind w:left="720"/><w:spacing w:after="60"/></w:pPr>
    <w:rPr><w:sz w:val="21"/></w:rPr>
  </w:style>
</w:styles>''';

  final body = _buildDocumentBody();

  final documentXml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:wpc="http://schemas.microsoft.com/office/word/2010/wordprocessingCanvas" xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006" xmlns:o="urn:schemas-microsoft-com:office:office" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" xmlns:m="http://schemas.openxmlformats.org/officeDocument/2006/math" xmlns:v="urn:schemas-microsoft-com:vml" xmlns:wp="http://schemas.openxmlformats.org/drawingml/2006/wordprocessingDrawing" xmlns:w10="urn:schemas-microsoft-com:office:word" xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:wne="http://schemas.microsoft.com/office/word/2006/wordml" mc:Ignorable="w14">
<w:body>
$body
<w:sectPr>
  <w:pgSz w:w="12240" w:h="15840"/>
  <w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="720" w:footer="720" w:gutter="0"/>
  <w:cols w:space="720"/>
  <w:docGrid w:linePitch="360"/>
</w:sectPr>
</w:body>
</w:document>''';

  final archive = Archive();
  archive.addFile(ArchiveFile('[Content_Types].xml', contentTypes.length, utf8.encode(contentTypes)));
  archive.addFile(ArchiveFile('_rels/.rels', rels.length, utf8.encode(rels)));
  archive.addFile(ArchiveFile('docProps/core.xml', coreXml.length, utf8.encode(coreXml)));
  archive.addFile(ArchiveFile('docProps/app.xml', appXml.length, utf8.encode(appXml)));
  archive.addFile(ArchiveFile('word/_rels/document.xml.rels', wordRels.length, utf8.encode(wordRels)));
  archive.addFile(ArchiveFile('word/styles.xml', stylesXml.length, utf8.encode(stylesXml)));
  archive.addFile(ArchiveFile('word/document.xml', documentXml.length, utf8.encode(documentXml)));

  final zipData = ZipEncoder().encode(archive);
  final outputPath = 'C:/Users/LENOVO/Desktop/POS/Function Requirements Updated.docx';
  File(outputPath).writeAsBytesSync(zipData);
  print('Created: $outputPath');
}

String _esc(String s) => s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('"', '&quot;');

String _p(String text, {String? style}) {
  final styleTag = style != null ? '<w:pStyle w:val="$style"/>' : '';
  return '<w:p><w:pPr>$styleTag</w:pPr><w:r><w:t xml:space="preserve">${_esc(text)}</w:t></w:r></w:p>';
}

String _heading1(String text) => _p(text, style: 'Heading1');
String _heading2(String text) => _p(text, style: 'Heading2');
String _heading3(String text) => _p(text, style: 'Heading3');

String _bullet(String text) => _p('  • $text', style: 'ListParagraph');

String _kvLine(String key, String value) {
  return '<w:p><w:pPr><w:pStyle w:val="ListParagraph"/></w:pPr><w:r><w:rPr><w:b/></w:rPr><w:t xml:space="preserve">${_esc(key)}</w:t></w:r><w:r><w:t xml:space="preserve"> ${_esc(value)}</w:t></w:r></w:p>';
}

String _buildDocumentBody() {
  final buf = StringBuffer();

  buf.writeln(_p('Function Requirements (POS System)', style: 'Heading1'));
  buf.writeln(_p('Updated: September 14, 2026'));
  buf.writeln(_p('Architecture: Flutter (Dart) Frontend + Laravel (PHP) Backend REST API'));
  buf.writeln(_p(''));

  // ===== USER FR =====
  buf.writeln(_heading1('User Functional Requirements'));

  // FR 1
  buf.writeln(_heading2('FR 1: Authentication'));
  buf.writeln(_p('Description: User registration, login, email verification, and password management.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('User Register with fields: email, password, full name, phone, social, role, address, NRC number, billing way, date of birth, gender'));
  buf.writeln(_bullet('Email verification via 6-digit OTP (sent via Resend/email service)'));
  buf.writeln(_bullet('User Login with email/password (token-based auth via Laravel Sanctum)'));
  buf.writeln(_bullet('Password Reset via OTP flow (send OTP → verify OTP → set new password)'));
  buf.writeln(_bullet('Forgot Password (3-step: send OTP → verify → set new password)'));
  buf.writeln(_bullet('Logout (token revocation)'));
  buf.writeln(_bullet('Users belong to a shop (shop_id)'));
  buf.writeln(_bullet('Unverified users (is_verified = false) cannot log in'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'User credentials, personal info, OTP code'));
  buf.writeln(_kvLine('Output:', 'Auth token, user session, access to dashboard'));
  buf.writeln(_p(''));

  // FR 2
  buf.writeln(_heading2('FR 2: Dashboard'));
  buf.writeln(_p('Description: Main landing page after login. Provides summary cards, analytics trends, and navigation gate to all modules.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Summary Cards: Today\'s sales (count & total), Monthly sales (count & total), Pending orders, Total products, In stock count, Low stock count, Pending purchases, Total sales'));
  buf.writeln(_bullet('Sales Trend Chart: Line chart (fl_chart) with period filter (This Month / This Year / All Time)'));
  buf.writeln(_bullet('Category Buying Trend: Multi-series line chart showing buying trend by category'));
  buf.writeln(_bullet('Most Bought Products: List with images, names, sold counts'));
  buf.writeln(_bullet('Least Bought Products: List with images, names, sold counts'));
  buf.writeln(_bullet('Single API call returns all dashboard data (/api/dashboard/all)'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Click to navigate to modules, period filter selection'));
  buf.writeln(_kvLine('Output:', 'Analytics data, summary cards, trend charts'));
  buf.writeln(_p(''));

  // FR 3
  buf.writeln(_heading2('FR 3: Inventory Management'));
  buf.writeln(_p('Description: Hierarchical inventory organization: Inventory > Categories > Products.'));
  buf.writeln(_heading3('Two Inventory Types:'));
  buf.writeln(_bullet('Self Inventory (private, owned by user)'));
  buf.writeln(_bullet('Public Inventory (shared across system)'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Inventory CRUD (create, read, update, delete)'));
  buf.writeln(_bullet('Category CRUD with fields: name, amount_of_package, package_limit, description, user_id, inventory_id'));
  buf.writeln(_bullet('Package CRUD with fields: name, amount_of_product, product_limit, description, location, stock_status, category_id'));
  buf.writeln(_bullet('Breadcrumb navigation (Dashboard > Inventory > Category > Package)'));
  buf.writeln(_bullet('Category navigation from inventory screen'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Create/update inventory, category, package'));
  buf.writeln(_kvLine('Output:', 'Realtime inventory hierarchy with category, package, and product counts'));
  buf.writeln(_p(''));

  // FR 4
  buf.writeln(_heading2('FR 4: Products Management'));
  buf.writeln(_p('Description: Full CRUD on products including variants, images, and stock management.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Product CRUD with fields: name, description, SKU, brand, product_type, is_set, image, image_delete_url, supplier_id'));
  buf.writeln(_bullet('Variant System: Each product has multiple variants with Size options (Individual, Family Pack, Small, Medium, Large, XL, Standard, Premium, Enterprise) and Color options (Black, White, Gray, Navy Blue, Royal Blue, Red, Green, Yellow, Orange, Brown) with per-variant quantity and price'));
  buf.writeln(_bullet('Product images uploaded to ImgBB (external hosting) with delete URL tracking'));
  buf.writeln(_bullet('Product search (dedicated search endpoint)'));
  buf.writeln(_bullet('Stock management: Stock calculation via StockCalculatorFactory (supports variant-level stock)'));
  buf.writeln(_bullet('Stock deduction/restoration on sale (size & color specific)'));
  buf.writeln(_bullet('Supplier association per product (optional)'));
  buf.writeln(_bullet('Supplier inline creation from product form'));
  buf.writeln(_bullet('Category/Package cascade selection (inventory type → categories → packages)'));
  buf.writeln(_bullet('"Use from Purchase" - auto-fill product details from pending purchase items'));
  buf.writeln(_bullet('Product search from existing products - search and select to pre-fill form'));
  buf.writeln(_bullet('Active/inactive product status'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Create new product with correct inventory, variant details, images'));
  buf.writeln(_kvLine('Output:', 'Correct products list with stock levels'));
  buf.writeln(_p(''));

  // FR 5
  buf.writeln(_heading2('FR 5: Sales (Point of Sale)'));
  buf.writeln(_p('Description: Complete sale workflow from adding products to checkout with PDF/print output.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('New Sale Screen with full cart workflow'));
  buf.writeln(_bullet('Add Products with search, category filter, variant selection (size/color), quantity controls'));
  buf.writeln(_bullet('Stock Validation - prevents overselling (checks available stock per variant)'));
  buf.writeln(_bullet('Customer Info: customer name (default "Customer"), customer phone (optional)'));
  buf.writeln(_bullet('Auto-generated Voucher No (INV-XXXXX) and Order ID (ORD-XXXXX)'));
  buf.writeln(_bullet('Payment Methods: Cash, Card, Mobile Pay, Other'));
  buf.writeln(_bullet('Discount: Percentage-based discount with calculated discount amount'));
  buf.writeln(_bullet('Notes Field for additional sale notes'));
  buf.writeln(_bullet('Summary Section: Total items, Subtotal, Discount %, Discount Amount, Total Payable'));
  buf.writeln(_bullet('Preview - navigates to SalePreviewScreen for invoice preview before completing'));
  buf.writeln(_bullet('Sale Submission via API'));
  buf.writeln(_bullet('Draft Save - saves as Order with status "draft" instead of completing'));
  buf.writeln(_bullet('After Sale Actions (configurable via settings): Export PDF and/or Print Voucher'));
  buf.writeln(_bullet('Draft-to-Sale Conversion: When converting a draft, deletes the original order'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Sale form (products, customer info, payment method, discount, notes)'));
  buf.writeln(_kvLine('Output:', 'Sale record created, stock deducted, voucher/invoice produced'));
  buf.writeln(_p(''));

  // FR 6
  buf.writeln(_heading2('FR 6: Sale Items / History'));
  buf.writeln(_p('Description: List and detail view of all sales history and pending orders.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Sale Items List showing all completed sales and pending orders'));
  buf.writeln(_bullet('Filter Tabs: All, Sold (Already Sale), Order (Will Be Sale)'));
  buf.writeln(_bullet('Search by product name, order ID, customer name'));
  buf.writeln(_bullet('Sale Detail Screen showing: order header with status badge, customer info, ordered items list (product name, size, color, quantity, price), payment info, order status and history'));
  buf.writeln(_bullet('"Up to Sale" Button on pending orders - converts draft/order to sale'));
  buf.writeln(_bullet('Delete sale items with confirmation'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Filter buttons, search, tap on item'));
  buf.writeln(_kvLine('Output:', 'History of orders, sale list with details'));
  buf.writeln(_p(''));

  // FR 7
  buf.writeln(_heading2('FR 7: Purchase Items (Inward Stock)'));
  buf.writeln(_p('Description: Manage purchase orders from suppliers, track incoming stock.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Purchase Items List showing all purchase orders'));
  buf.writeln(_bullet('Filter Tabs: All, Completed, Pending'));
  buf.writeln(_bullet('Search by order ID, product name, supplier name'));
  buf.writeln(_bullet('Add New Purchase via bottom sheet form'));
  buf.writeln(_bullet('Add Supplier inline from purchase screen'));
  buf.writeln(_bullet('Mark as Completed status toggle'));
  buf.writeln(_bullet('Purchase Fields: user_id, supplier_id, product_id, product_name, quantity, unit_price, total_price, date, status, notes'));
  buf.writeln(_bullet('Supplier Management (CRUD) linked to purchase items'));
  buf.writeln(_bullet('Status Tracking: Completed / Pending'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Purchase form (supplier, product, quantity, price, date, notes)'));
  buf.writeln(_kvLine('Output:', 'History of purchase orders, purchase list with supplier info'));
  buf.writeln(_p(''));

  // FR 8
  buf.writeln(_heading2('FR 8: Settings'));
  buf.writeln(_p('Description: App configuration including appearance, business info, and print settings.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Profile Card: User name, email'));
  buf.writeln(_bullet('Appearance: Light/Dark mode toggle (persisted via API)'));
  buf.writeln(_bullet('Regional: Language selection (Myanmar, English, Thai, Japanese, Korean)'));
  buf.writeln(_bullet('Business: Shop Type selector (Shop, Service, Restaurant, Store) with icon grid'));
  buf.writeln(_bullet('Business: Shop Image upload/change via gallery'));
  buf.writeln(_bullet('Support: Feedback form (Comment/Suggestion/Bug Report), Rate App'));
  buf.writeln(_bullet('About: App version, Developer info, Privacy Policy, Terms of Service'));
  buf.writeln(_bullet('Sign Out with confirmation dialog'));
  buf.writeln(_bullet('Settings persistence via backend API'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Button/toggle for action'));
  buf.writeln(_kvLine('Output:', 'Effect the whole system appearance and behavior'));
  buf.writeln(_p(''));

  // FR 9
  buf.writeln(_heading2('FR 9: PDF / Print / Export'));
  buf.writeln(_p('Description: Voucher/invoice generation in A4 and thermal receipt formats with print and export options.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Client-Side PDF Generation (Flutter pdf + printing packages)'));
  buf.writeln(_bullet('A4 Invoice PDF - full invoice with shop logo, gradient header, customer info, items table, summary, payment method, notes, footer'));
  buf.writeln(_bullet('Thermal Receipt PDF - narrow 56.7mm receipt format with shop logo, compact layout'));
  buf.writeln(_bullet('Print Settings (persisted in SharedPreferences, survives app restart)'));
  buf.writeln(_p('    • Export PDF toggle (auto-share PDF after sale)', style: 'ListParagraph'));
  buf.writeln(_p('    • Print Voucher toggle (auto-print after sale)', style: 'ListParagraph'));
  buf.writeln(_p('    • Print Format selection (Thermal Paper / A4 Paper)', style: 'ListParagraph'));
  buf.writeln(_bullet('Backend PDF Generation via DomPDF: Server-side voucher PDF download'));
  buf.writeln(_bullet('Export Endpoints: Export sales data and orders data with date range filter'));
  buf.writeln(_bullet('Sale Preview Screen - visual invoice preview before printing'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Click export/print button or auto-trigger after sale'));
  buf.writeln(_kvLine('Output:', 'PDF file saved/shared, printed voucher'));
  buf.writeln(_p(''));

  // FR 10
  buf.writeln(_heading2('FR 10: Draft Orders'));
  buf.writeln(_p('Description: Save incomplete sales as drafts, convert to completed sales later.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Save as Draft from New Sale screen (saves Order with status "draft")'));
  buf.writeln(_bullet('Draft list appears in Sale Items screen under "Will Be Sale" tab'));
  buf.writeln(_bullet('Draft detail shows full order information with "Up to Sale" button'));
  buf.writeln(_bullet('Convert draft to sale: Opens NewSaleScreen pre-populated with draft items, customer info, and payment method'));
  buf.writeln(_bullet('Order deletion: When draft is converted to sale, the original order is deleted'));
  buf.writeln(_bullet('Order fields: Same as Sale plus status field (draft, completed)'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Click Draft button, click Up to Sale button'));
  buf.writeln(_kvLine('Output:', 'Draft order saved, draft converted to sale'));
  buf.writeln(_p(''));

  // FR 11
  buf.writeln(_heading2('FR 11: Customer Management'));
  buf.writeln(_p('Description: User can manage customers linked to their shops.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Customer CRUD with fields: name, phone, email, address, tax_id, total_purchases, total_spent'));
  buf.writeln(_bullet('Shop-scoped customer lists'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Customer form'));
  buf.writeln(_kvLine('Output:', 'Customer list per shop'));
  buf.writeln(_p(''));

  // FR 12
  buf.writeln(_heading2('FR 12: Audit Logging'));
  buf.writeln(_p('Description: System tracks all changes for accountability.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Tracks all changes (create/update/delete) on sales and orders'));
  buf.writeln(_bullet('Stores old/new values, IP address, user agent'));
  buf.writeln(_bullet('Audit logs per sale or per order'));
  buf.writeln(_bullet('Recent activity feed'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Automatic (runs in background)'));
  buf.writeln(_kvLine('Output:', 'Audit log entries'));
  buf.writeln(_p(''));

  // FR 13
  buf.writeln(_heading2('FR 13: Stock Alerts'));
  buf.writeln(_p('Description: Configurable alerts for low stock products.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Configurable threshold per product per shop'));
  buf.writeln(_bullet('Active/inactive toggle'));
  buf.writeln(_bullet('Check and notify for triggered alerts'));
  buf.writeln(_bullet('View triggered alerts'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Set threshold, toggle alert'));
  buf.writeln(_kvLine('Output:', 'Triggered stock alerts notification'));
  buf.writeln(_p(''));

  // FR 14
  buf.writeln(_heading2('FR 14: Image Upload Service'));
  buf.writeln(_p('Description: Centralized image upload service using ImgBB.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Upload product images, profile images, shop images'));
  buf.writeln(_bullet('Delete URL tracking for cleanup'));
  buf.writeln(_bullet('Supports gallery picker from device'));
  buf.writeln(_p(''));
  buf.writeln(_kvLine('Input:', 'Select image from gallery'));
  buf.writeln(_kvLine('Output:', 'Hosted image URL + delete URL'));
  buf.writeln(_p(''));

  // ===== ADMIN FR =====
  buf.writeln(_heading1('System Admin Functional Requirements'));

  buf.writeln(_heading2('FR 15: Admin Login'));
  buf.writeln(_p('Description: Admin login with predefined credentials.'));
  buf.writeln(_kvLine('Input:', 'Admin credentials'));
  buf.writeln(_kvLine('Output:', 'Access to admin dashboard'));
  buf.writeln(_p(''));

  buf.writeln(_heading2('FR 16: Admin Dashboard'));
  buf.writeln(_p('Description: Admin overview of all shops, users, and their sales performance.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('User trend by shops and their sale summary'));
  buf.writeln(_bullet('Shop listing with status'));
  buf.writeln(_bullet('User approval gate'));
  buf.writeln(_kvLine('Input:', 'Filter buttons'));
  buf.writeln(_kvLine('Output:', 'Shop and user analytics overview'));
  buf.writeln(_p(''));

  buf.writeln(_heading2('FR 17: Approve Staff'));
  buf.writeln(_p('Description: Admin can view and approve staff registration profiles.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('View staff register profile'));
  buf.writeln(_bullet('Approve and assign to a shop'));
  buf.writeln(_bullet('Activate user (active_status = 1)'));
  buf.writeln(_kvLine('Input:', 'Click approve, choose shop assignment'));
  buf.writeln(_kvLine('Output:', 'User active_status set to 1, user assigned to shop'));
  buf.writeln(_p(''));

  buf.writeln(_heading2('FR 18: User Management'));
  buf.writeln(_p('Description: Admin can manage all users in the system.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('User listing with filter'));
  buf.writeln(_bullet('Delete or disable users'));
  buf.writeln(_bullet('View user details'));
  buf.writeln(_bullet('Clear UI for easy understanding'));
  buf.writeln(_kvLine('Input:', 'Delete button, select user, filter'));
  buf.writeln(_kvLine('Output:', 'Updated user list'));
  buf.writeln(_p(''));

  buf.writeln(_heading2('FR 19: Shop Management'));
  buf.writeln(_p('Description: Admin can manage all shops in the system.'));
  buf.writeln(_heading3('Features:'));
  buf.writeln(_bullet('Shop CRUD with fields: shop_image, shop_name, shop_type, shop_physical_address, owner_name, owner_email, owner_phone, is_active'));
  buf.writeln(_bullet('Paginated shop listing (20 per page)'));
  buf.writeln(_bullet('Shop activation/deactivation'));
  buf.writeln(_kvLine('Input:', 'Shop form, filter, delete'));
  buf.writeln(_kvLine('Output:', 'Updated shop list'));
  buf.writeln(_p(''));

  // System Requirements
  buf.writeln(_heading1('System Requirements'));
  buf.writeln(_bullet('System must calculate correct stock quantity (variant-level)'));
  buf.writeln(_bullet('Analysis trends must be correct'));
  buf.writeln(_bullet('Settings persist in local storage (SharedPreferences) until app data is deleted'));
  buf.writeln(_bullet('Print settings persist locally (survive app restart)'));
  buf.writeln(_bullet('All API calls use Laravel Sanctum token authentication'));
  buf.writeln(_bullet('Responsive layout adapts between mobile (drawer) and wide screen (sidebar)'));

  return buf.toString();
}
