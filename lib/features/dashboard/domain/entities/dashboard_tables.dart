import 'package:posfrontend/features/dashboard/domain/entities/dashboard_table.dart';

/// Stable identity for a dashboard summary tile.
///
/// `MetricEntity.label` used to double as the routing key, so the summary tile
/// and its table were matched on shared English wording — and translating that
/// wording would have broken the "View all" link. The label is now free to be
/// copy; this is what navigation switches on.
enum DashboardTableKey { products, inStock, lowStock, sales }

/// The tables reachable from the dashboard's "View all" links.
///
/// Each [DashboardTableSpec] pairs an endpoint with the columns the user asked
/// for, so the request and the code can be read side by side. Adding a column
/// is a one-line change here and nothing else.
class DashboardTableSpec {
  final String title;
  final String endpoint;
  final List<TableColumn> columns;

  /// Shown under the title. The stock tables need it: a variant product is one
  /// row per variant, so the row count is larger than the product count on the
  /// card that opened it, and without this the table looks like a mismatch.
  final String? note;

  /// Lets the toolbar scope the table to one month. Only the sales table has a
  /// meaningful month dimension, so only it opts in.
  final bool showMonthFilter;

  const DashboardTableSpec({
    required this.title,
    required this.endpoint,
    required this.columns,
    this.note,
    this.showMonthFilter = false,
  });

  double get totalWidth =>
      columns.fold<double>(0, (sum, column) => sum + column.width) +
      _cellPadding * 2 * columns.length;
}

const double _cellPadding = 14;

class DashboardTables {
  const DashboardTables._();

  /// Total Products: product name, stock, category, package, who created, when.
  static const products = DashboardTableSpec(
    title: 'Total Products',
    endpoint: '/dashboard/tables/products',
    columns: [
      TableColumn(label: 'Product Name', width: 210, jsonKey: 'name'),
      TableColumn(
        label: 'Stock',
        width: 80,
        jsonKey: 'stock',
        align: TableColumnAlign.right,
        kind: TableValueKind.number,
      ),
      TableColumn(label: 'Category', width: 130, jsonKey: 'category'),
      TableColumn(label: 'Package', width: 130, jsonKey: 'package'),
      TableColumn(label: 'Created By', width: 140, jsonKey: 'created_by'),
      TableColumn(
        label: 'Created',
        width: 150,
        jsonKey: 'created_at',
        kind: TableValueKind.dateTime,
      ),
    ],
  );

  static const inStock = DashboardTableSpec(
    title: 'In Stock',
    endpoint: '/dashboard/tables/stock',
    note: 'One row per variant.',
    columns: _variantColumns,
  );

  static const lowStock = DashboardTableSpec(
    title: 'Low Stock',
    endpoint: '/dashboard/tables/stock',
    note: 'One row per variant. Low stock means 1 to 5 left.',
    columns: _variantColumns,
  );

  /// In Stock and Low Stock read the same rows; the low-stock table adds
  /// `low=1` as a query parameter.
  static const List<TableColumn> _variantColumns = [
    TableColumn(label: 'Product Name', width: 200, jsonKey: 'name'),
    TableColumn(label: 'Size', width: 90, jsonKey: 'size'),
    TableColumn(label: 'Color', width: 90, jsonKey: 'color'),
    TableColumn(
      label: 'Stock',
      width: 80,
      jsonKey: 'stock',
      align: TableColumnAlign.right,
      kind: TableValueKind.number,
    ),
    TableColumn(label: 'Category', width: 140, jsonKey: 'category'),
  ];

  /// Total Sales: date, sale id, the products in the sale, price, who rang it
  /// up, and the time.
  static const sales = DashboardTableSpec(
    title: 'Total Sales',
    endpoint: '/dashboard/tables/sales',
    showMonthFilter: true,
    columns: [
      TableColumn(
        label: 'Date',
        width: 100,
        jsonKey: 'date',
        kind: TableValueKind.date,
      ),
      TableColumn(
        label: 'Time',
        width: 70,
        jsonKey: 'time',
        kind: TableValueKind.time,
      ),
      TableColumn(label: 'Sale ID', width: 190, jsonKey: 'voucher_no'),
      TableColumn(
        label: 'Products In Sale',
        width: 280,
        jsonKey: 'products',
        wrap: true,
      ),
      TableColumn(
        label: 'Price',
        width: 110,
        jsonKey: 'price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
      TableColumn(label: 'Sold By', width: 140, jsonKey: 'user'),
    ],
  );

  /// Most bought and least bought share every column, so they share a spec and
  /// differ only by the `direction` query parameter.
  static const bought = DashboardTableSpec(
    title: 'Most Bought',
    endpoint: '/dashboard/tables/bought-products',
    note: 'Last 30 days.',
    columns: [
      TableColumn(label: 'Product Name', width: 240, jsonKey: 'name'),
      TableColumn(
        label: 'Bought Stock',
        width: 120,
        jsonKey: 'bought_stock',
        align: TableColumnAlign.right,
        kind: TableValueKind.number,
      ),
      TableColumn(
        label: 'Price Per 1',
        width: 130,
        jsonKey: 'unit_price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
      TableColumn(
        label: 'Total Price',
        width: 140,
        jsonKey: 'total_price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
    ],
  );

  static DashboardTableSpec get leastBought => DashboardTableSpec(
    title: 'Least Bought',
    endpoint: DashboardTables.bought.endpoint,
    note: DashboardTables.bought.note,
    columns: DashboardTables.bought.columns,
  );

  /// No bought: product name, price, who created it, when.
  static const noBought = DashboardTableSpec(
    title: 'No Bought',
    endpoint: '/dashboard/tables/no-bought-products',
    columns: [
      TableColumn(label: 'Product Name', width: 240, jsonKey: 'name'),
      TableColumn(
        label: 'Price',
        width: 140,
        jsonKey: 'price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
      TableColumn(label: 'Created By', width: 160, jsonKey: 'creator_name'),
      TableColumn(
        label: 'Created Time',
        width: 160,
        jsonKey: 'created_at',
        kind: TableValueKind.dateTime,
      ),
    ],
  );
}

/// The four tables drawn inline on the dashboard, each a narrow slice of the
/// full table it links to.
///
/// A preview cannot reuse the full spec: the full specs are sized for a
/// horizontal scroll view with every column on screen, while a preview sits in
/// half a row and would rather drop a column than scroll. So each entry here
/// keeps only the columns the design shows and states its own widths; "View
/// all" still opens the full spec from [DashboardTables], with the full column
/// set.
class DashboardTablePreviews {
  const DashboardTablePreviews._();

  static const lowStockItems = DashboardTableSpec(
    title: 'Low Stock Items',
    endpoint: '/dashboard/tables/stock',
    columns: [
      TableColumn(label: 'Product Name', width: 200, jsonKey: 'name'),
      TableColumn(label: 'Category', width: 120, jsonKey: 'category'),
      TableColumn(
        label: 'Stock',
        width: 64,
        jsonKey: 'stock',
        align: TableColumnAlign.right,
        kind: TableValueKind.number,
      ),
    ],
  );

  /// The backend has no "days since last sale" column, so the design's Days
  /// column is answered with the price and the creator instead — the two
  /// things the row actually carries.
  static const productsNotSold = DashboardTableSpec(
    title: 'Products Not Sold',
    endpoint: '/dashboard/tables/no-bought-products',
    columns: [
      TableColumn(label: 'Product Name', width: 200, jsonKey: 'name'),
      TableColumn(
        label: 'Price',
        width: 110,
        jsonKey: 'price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
      TableColumn(label: 'Created By', width: 120, jsonKey: 'creator_name'),
    ],
  );

  static const recentSales = DashboardTableSpec(
    title: 'Recent Sales',
    endpoint: '/dashboard/tables/sales',
    columns: [
      TableColumn(
        label: 'Date',
        width: 100,
        jsonKey: 'date',
        kind: TableValueKind.date,
      ),
      TableColumn(
        label: 'Items',
        width: 64,
        jsonKey: 'product_count',
        align: TableColumnAlign.right,
        kind: TableValueKind.number,
      ),
      TableColumn(
        label: 'Total',
        width: 110,
        jsonKey: 'price',
        align: TableColumnAlign.right,
        kind: TableValueKind.currency,
      ),
      TableColumn(label: 'Payment', width: 96, jsonKey: 'pay_method'),
    ],
  );

  static const recentProducts = DashboardTableSpec(
    title: 'Recent Products',
    endpoint: '/dashboard/tables/products',
    columns: [
      TableColumn(label: 'Product Name', width: 180, jsonKey: 'name'),
      TableColumn(label: 'Category', width: 104, jsonKey: 'category'),
      TableColumn(
        label: 'Stock',
        width: 64,
        jsonKey: 'stock',
        align: TableColumnAlign.right,
        kind: TableValueKind.number,
      ),
      TableColumn(
        label: 'Added Date',
        width: 110,
        jsonKey: 'created_at',
        kind: TableValueKind.date,
      ),
    ],
  );

  /// How many rows each preview fetches. Five is what the design shows and
  /// what fits above a fold without the card growing taller than the chart
  /// beside it.
  static const int rowsPerPage = 5;

  /// The requests behind [tablePreviews] on the view model, keyed the way the
  /// screen looks them up. `low: 1` is the same flag the Low Stock "View all"
  /// link sends, so the preview and the screen behind it show the same rows.
  static const List<
    ({String key, String endpoint, Map<String, dynamic> query})
  >
  requests = [
    (
      key: 'lowStockItems',
      endpoint: '/dashboard/tables/stock',
      query: <String, dynamic>{'low': 1},
    ),
    (
      key: 'productsNotSold',
      endpoint: '/dashboard/tables/no-bought-products',
      query: <String, dynamic>{},
    ),
    (
      key: 'recentSales',
      endpoint: '/dashboard/tables/sales',
      query: <String, dynamic>{},
    ),
    (
      key: 'recentProducts',
      endpoint: '/dashboard/tables/products',
      query: <String, dynamic>{},
    ),
  ];
}
