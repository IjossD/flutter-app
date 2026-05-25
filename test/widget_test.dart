import 'package:flutter_test/flutter_test.dart';

import 'package:wellbeing_app/app.dart';

void main() {
  testWidgets('renders wellbeing shell', (WidgetTester tester) async {
    await tester.pumpWidget(const WellbeingApp());
    await tester.pumpAndSettle();

    expect(find.text('Bienestar de hoy'), findsOneWidget);
    expect(find.text('Check-in'), findsWidgets);
  });
}
