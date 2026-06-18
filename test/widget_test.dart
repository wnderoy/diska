import 'package:flutter_test/flutter_test.dart';

import 'package:bamap/app.dart';

void main() {
  testWidgets('App renders bottom navigation with 5 tabs',
      (WidgetTester tester) async {
    await tester.pumpWidget(const BamapApp());

    // Verify the 5 nav labels exist
    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Add Show'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
