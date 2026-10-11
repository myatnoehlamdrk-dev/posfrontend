import 'package:flutter/material.dart';
import 'package:posfrontend/shared/theme/app_dimens.dart';
import 'package:posfrontend/shared/theme/app_typography.dart';
import 'package:posfrontend/shared/l10n/l10n_x.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_screen_top_bar.dart';

/// Shared scaffold for the long-form legal documents.
///
/// The Privacy Policy and Terms of Service screens were byte-for-byte identical
/// apart from their title, the "last updated" line and the section data, which
/// meant every theme change had to be applied twice and one of them would be
/// forgotten. The body now lives here once.
class LegalDocumentScreen extends StatelessWidget {
  final String title;
  final String lastUpdated;
  final List<(String, List<String>)> sections;

  const LegalDocumentScreen({
    super.key,
    required this.title,
    required this.lastUpdated,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.scaffoldBg,
      body: SafeArea(
        child: Column(
          children: [
            AppScreenTopBar(
              title: title,
              showBackButton: true,
              showMenuButton: false,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(AppSpacing.s20, AppSpacing.s20, AppSpacing.s20, AppSpacing.s40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.l10n
                          .t('Last Updated: {v1}')
                          .replaceAll('{v1}', (lastUpdated).toString()),
                      style: TextStyle(
                        color: p.textSecondary,
                        fontSize: AppTypography.labelMediumSize,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.s20),
                    for (final (sectionTitle, paragraphs) in sections)
                      _Section(title: sectionTitle, paragraphs: paragraphs),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<String> paragraphs;

  const _Section({required this.title, required this.paragraphs});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: TextStyle(
              color: p.textPrimary,
              fontSize: AppTypography.bodyLargeSize,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.s8),
          for (final paragraph in paragraphs)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.s12),
              child: Text(
                paragraph,
                textAlign: TextAlign.justify,
                style: TextStyle(
                  color: p.textSecondary,
                  fontSize: AppTypography.bodySmallSize,
                  height: 1.6,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
