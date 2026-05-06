import 'package:ecocollect/main.dart';
import 'package:ecocollect/screens/auth_screen.dart';
import 'package:ecocollect/screens/home_screen.dart';
import 'package:ecocollect/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('EcoCollect welcome screen renders', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: WelcomeScreen()),
    );

    expect(find.text('EcoCollect'), findsOneWidget);
    expect(find.text('Đồng nát Online'), findsOneWidget);
    expect(find.text('Bắt đầu ngay'), findsOneWidget);
  });

  test('onboarding next screen is auth when signed out', () {
    final screen = nextScreenAfterOnboarding(false);
    expect(screen, isA<AuthScreen>());
  });

  test('onboarding next screen is home when signed in', () {
    final screen = nextScreenAfterOnboarding(true);
    expect(screen, isA<HomeScreen>());
  });
}
