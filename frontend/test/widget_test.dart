import 'package:cardwise_ai/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders auth screen', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const CardWiseApp());
    await tester.pumpAndSettle();

    expect(find.text('CardWise'), findsOneWidget);
  });
}
