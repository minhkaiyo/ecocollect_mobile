import 'package:ecocollect/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('EcoCollect welcome screen renders', (tester) async {
    await tester.pumpWidget(const EcoCollectApp());

    expect(find.text('EcoCollect'), findsOneWidget);
    expect(find.text('Đồng nát Online'), findsOneWidget);
    expect(find.text('Bắt đầu ngay'), findsOneWidget);
  });
}
