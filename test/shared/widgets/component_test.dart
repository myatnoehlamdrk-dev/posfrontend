import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:posfrontend/shared/theme/app_palette.dart';
import 'package:posfrontend/shared/theme/palette_x.dart';
import 'package:posfrontend/shared/widgets/app_badge.dart';
import 'package:posfrontend/shared/widgets/app_card.dart';
import 'package:posfrontend/shared/widgets/app_empty_state.dart';

void main() {
  testWidgets('AppEmptyState renders title and icon', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppPalette.light],
        ),
        home: const Scaffold(
          body: AppEmptyState(
            title: 'Nothing here',
            subtitle: 'Try again later',
            icon: Icons.inbox_outlined,
          ),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try again later'), findsOneWidget);
    expect(find.byIcon(Icons.inbox_outlined), findsOneWidget);
  });

  testWidgets('AppCard renders child', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppPalette.light],
        ),
        home: const Scaffold(
          body: AppCard(child: Text('hello')),
        ),
      ),
    );
    expect(find.text('hello'), findsOneWidget);
  });

  testWidgets('AppBadge renders label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppPalette.light],
        ),
        home: const Scaffold(
          body: AppBadge(label: 'New', tone: AppBadgeTone.success),
        ),
      ),
    );
    expect(find.text('New'), findsOneWidget);
  });

  testWidgets('AppEmptyState action button fires callback', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          extensions: const [AppPalette.light],
        ),
        home: Scaffold(
          body: AppEmptyState(
            title: 'Empty',
            actionLabel: 'Retry',
            onAction: () => tapped = true,
          ),
        ),
      ),
    );
    await tester.tap(find.text('Retry'));
    expect(tapped, isTrue);
  });
}
