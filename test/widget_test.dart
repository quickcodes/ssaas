// ignore_for_file: avoid_relative_lib_imports
import 'package:flutter_test/flutter_test.dart';
import '../lib/core/di/service_locator.dart';
import '../lib/main.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  testWidgets('empty club workspace renders without demo data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SsaasApp());
    await tester.pump();

    expect(find.text('Your club workspace is ready'), findsOneWidget);
    expect(find.textContaining('No demo data has been added'), findsOneWidget);
    expect(find.text('SET UP MY CLUB'), findsOneWidget);
  });
}
