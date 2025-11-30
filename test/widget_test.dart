import 'package:flutter_test/flutter_test.dart';
import 'package:streakoo/main.dart';

void main() {
  testWidgets('App loads home screen correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const StreakooApp());
    await tester.pumpAndSettle();

    expect(find.text('Streakoo 🔥'), findsOneWidget);
  });
}
