import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:posfrontend/features/category/data/repositories/category_repository_impl.dart';
import 'package:posfrontend/features/notifications/domain/entities/app_notification.dart';
import 'package:posfrontend/features/package/data/repositories/package_repository_impl.dart';
import 'package:posfrontend/features/package/presentation/screens/package_details_screen.dart';
import 'package:posfrontend/features/product/presentation/screens/product_detail_screen.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

/// Detail page behind the daily stock report notification.
///
/// The push is deliberately ONE message per day ("4 out of stock, 7 low
/// stock, 2 packages out"); the per-product and per-package breakdowns
/// travel in `data.products` / `data.packages` and are rendered here as a
/// plain text report — heading, date, summary sentence and numbered lines,
/// like a document. Product lines open the product page, package lines the
/// package page.
class StockReportDetailScreen extends StatelessWidget {
  final AppNotification notification;

  const StockReportDetailScreen({super.key, required this.notification});

  List<Map<String, dynamic>> _list(String key) {
    try {
      final raw = notification.data[key];
      if (raw is String && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          return decoded.whereType<Map<String, dynamic>>().toList();
        }
      }
    } catch (_) {
      // Malformed payload: fall through to the empty state below.
    }
    return const [];
  }

  /// Backend counts are authoritative (the list in the payload is capped);
  /// fall back to the parsed list when an old payload lacks them.
  int _count(String key, int fallback) {
    final parsed = int.tryParse((notification.data[key] ?? '').toString());
    return parsed ?? fallback;
  }

  String _dateLine(DateTime time) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${time.year}-${two(time.month)}-${two(time.day)} '
        '${two(time.hour)}:${two(time.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final products = _list('products');
    final packages = _list('packages');
    final out = products.where((e) => (e['kind'] ?? '') == 'out').toList();
    final low = products.where((e) => (e['kind'] ?? '') == 'low').toList();
    final outCount = _count('out_count', out.length);
    final lowCount = _count('low_count', low.length);
    final packageOutCount = _count('package_out_count', packages.length);

    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: notification.title,
              showBackButton: true,
              showMenuButton: false,
              showNotificationsButton: false,
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.s16),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppSpacing.s16),
                    decoration: BoxDecoration(
                      color: p.surface,
                      border: Border.all(color: p.border),
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            notification.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.textPrimary,
                              fontSize: AppTypography.titleMediumSize,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s4),
                        SizedBox(
                          width: double.infinity,
                          child: Text(
                            _dateLine(notification.receivedAt),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: AppTypography.bodySmallSize,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        Divider(height: 1, color: p.border),
                        const SizedBox(height: AppSpacing.s12),
                        Text(
                          context.l10n
                              .t('{v1} out of stock, {v2} low stock')
                              .replaceFirst('{v1}', '$outCount')
                              .replaceFirst('{v2}', '$lowCount'),
                          style: TextStyle(
                            color: p.textSecondary,
                            fontSize: AppTypography.bodyMediumSize,
                            height: 1.4,
                          ),
                        ),
                        if (products.isEmpty && packages.isEmpty) ...[
                          const SizedBox(height: AppSpacing.s16),
                          Text(
                            context.l10n
                                .t('No product details in this message.'),
                            style: TextStyle(
                              color: p.textMuted,
                              fontSize: AppTypography.bodyMediumSize,
                              height: 1.4,
                            ),
                          ),
                        ] else ...[
                          if (out.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s16),
                            _DocSection(
                              title:
                                  '${context.l10n.t('Out of Stock')} (${out.length})',
                              entries: out,
                              isOut: true,
                            ),
                          ],
                          if (low.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s16),
                            _DocSection(
                              title:
                                  '${context.l10n.t('Low Stock')} (${low.length})',
                              entries: low,
                              isOut: false,
                            ),
                          ],
                          if (packages.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s16),
                            _DocSection(
                              title:
                                  '${context.l10n.t('Packages Out of Stock')} ($packageOutCount)',
                              entries: packages,
                              isOut: true,
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocSection extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> entries;
  final bool isOut;

  const _DocSection({
    required this.title,
    required this.entries,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: p.textPrimary,
            fontSize: AppTypography.bodyMediumSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Divider(height: 1, color: p.border),
        for (var i = 0; i < entries.length; i++)
          _DocLine(
            index: i + 1,
            entry: entries[i],
            isOut: isOut,
          ),
      ],
    );
  }
}

class _DocLine extends StatelessWidget {
  final int index;
  final Map<String, dynamic> entry;
  final bool isOut;

  const _DocLine({
    required this.index,
    required this.entry,
    required this.isOut,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final name = (entry['name'] ?? '').toString();

    String? note;
    if (!isOut) {
      final stock = (entry['stock'] ?? '').toString();
      final threshold = (entry['threshold'] ?? '').toString();
      note = context.l10n
          .t('{v1} left (threshold {v2})')
          .replaceFirst('{v1}', stock)
          .replaceFirst('{v2}', threshold);
    }

    return InkWell(
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$index.',
                style: TextStyle(
                  color: p.textMuted,
                  fontSize: AppTypography.bodyMediumSize,
                  height: 1.4,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: p.textPrimary,
                      fontSize: AppTypography.bodyMediumSize,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (note != null)
                    Text(
                      note,
                      style: TextStyle(
                        color: p.textMuted,
                        fontSize: AppTypography.bodySmallSize,
                        height: 1.4,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _open(BuildContext context) {
    if ((entry['kind'] ?? '') == 'package_out') {
      final id = (entry['id'] ?? '').toString();
      if (id.isNotEmpty) _openPackage(context, id);
      return;
    }
    final id = (entry['id'] ?? '').toString();
    if (id.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: id),
      ),
    );
  }

  /// Package lines carry only an id; the detail page wants the package plus
  /// its category, both fetched by id. A failure (offline, record deleted)
  /// just leaves the report open.
  Future<void> _openPackage(BuildContext context, String packageId) async {
    try {
      final package = await PackageRepositoryImpl().getPackageById(packageId);
      final category = await CategoryRepositoryImpl().getCategoryById(
        package.categoryId,
      );
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PackageDetailsScreen(
            package: package,
            category: category,
          ),
        ),
      );
    } catch (_) {
      debugPrint('Package report navigation failed: $packageId');
    }
  }
}
