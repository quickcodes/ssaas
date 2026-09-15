import 'package:flutter_test/flutter_test.dart';
import 'package:snooker/core/di/service_locator.dart';
import 'package:snooker/main.dart';

void main() {
  setUp(() {
    setupServiceLocator();
  });

  testWidgets('empty club workspace renders without demo data', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SnookerClubApp());
    await tester.pump();

    expect(find.text('Your club workspace is ready'), findsOneWidget);
    expect(find.textContaining('No demo data has been added'), findsOneWidget);
    expect(find.text('SET UP MY CLUB'), findsOneWidget);
  });
}
