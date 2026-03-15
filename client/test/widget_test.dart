import 'package:client/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('payment screen renders', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Secure checkout demo'), findsOneWidget);
    expect(find.text('Make a payment'), findsOneWidget);
    expect(find.text('Pay with Razorpay'), findsOneWidget);
  });
}
