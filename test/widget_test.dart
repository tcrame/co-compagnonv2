import 'package:flutter_test/flutter_test.dart';
import 'package:co_compagnon_v2/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CoCompagnonApp());
    expect(find.text('CO Compagnon V2'), findsOneWidget);
  });
}
