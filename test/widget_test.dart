import 'package:flutter_test/flutter_test.dart';

import 'package:travelpal/main.dart';

void main() {
  testWidgets('TravelPal starts successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const TravelPalApp());

    expect(find.text('TravelPal'), findsOneWidget);
    expect(find.text('Welcome to TravelPal'), findsOneWidget);
  });
}