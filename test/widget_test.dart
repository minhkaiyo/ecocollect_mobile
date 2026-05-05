import 'package:ecocollect/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EcoCollect welcome screen renders', (tester) async {
    await tester.pumpWidget(const EcoCollectApp());
    await tester.pumpAndSettle();

    expect(find.text('EcoCollect'), findsOneWidget);
    expect(find.text('Đồng nát Online'), findsOneWidget);
    expect(find.text('Bắt đầu ngay'), findsOneWidget);
  });
}
