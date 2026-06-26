import 'package:flutter_test/flutter_test.dart';
import 'package:karnama/app.dart';

void main() {
  testWidgets('App loads dashboard', (WidgetTester tester) async {
    await tester.pumpWidget(const KarnamaApp());
    expect(find.text('کارنما'), findsWidgets);
  });
}
