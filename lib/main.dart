import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import 'persistence/launch_state.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'theme/app_theme.dart';
import 'theme/eco_colors.dart';
import 'repositories/user_repository.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'seeds/seed_vouchers.dart' as seed;

Future<void> main() async {
  // 1. Khởi tạo cầu nối Flutter - Native
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Unhandled platform error: $error');
    return true;
  };

  // 2. Kích hoạt Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Auto-seed vouchers
  try {
    await seed.runSeed();
  } catch (e) {
    debugPrint('Seed error: $e');
  }

  // 4. Bật tính năng Offline-First (Lưu data khi rớt mạng)
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const EcoCollectApp());
}

class EcoCollectApp extends StatefulWidget {
  const EcoCollectApp({super.key});

  @override
  State<EcoCollectApp> createState() => _EcoCollectAppState();
}

class _EcoCollectAppState extends State<EcoCollectApp> {
  bool _prefsLoaded = false;
  bool _onboardingComplete = false;

  @override
  void initState() {
    super.initState();
    _loadLaunchState();
  }

  Future<void> _loadLaunchState() async {
    final done = await isOnboardingComplete();
    if (!mounted) return;
    setState(() {
      _onboardingComplete = done;
      _prefsLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoCollect',
      debugShowCheckedModeBanner: false,
      theme: buildEcoTheme(),
      builder: (context, child) {
        if (!kIsWeb) return child!;
        return ColoredBox(
          color: EcoColors.webChromeBg,
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 430),
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: child!,
              ),
            ),
          ),
        );
      },
      home: !_prefsLoaded
          ? const _LaunchPlaceholder()
          : (_onboardingComplete
              ? const _AuthWrapper()
              : const WelcomeScreen()),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  const _AuthWrapper();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LaunchPlaceholder();
        }
        if (snapshot.hasError) {
          return const AuthScreen();
        }
        if (snapshot.hasData) {
          final user = snapshot.data!;
          return FutureBuilder<void>(
            future: UserRepository().createUserIfNotExists(user),
            builder: (context, profileSnapshot) {
              if (profileSnapshot.connectionState == ConnectionState.waiting) {
                return const _LaunchPlaceholder();
              }
              return const HomeScreen();
            },
          );
        }
        return const AuthScreen();
      },
    );
  }
}

class _LaunchPlaceholder extends StatelessWidget {
  const _LaunchPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: EcoColors.welcomeGradientEnd,
        child: Center(
          child: CircularProgressIndicator(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, EcoColors.welcomeGradientEnd],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LogoMark(),
                    const SizedBox(height: 48),
                    Text(
                      'EcoCollect',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 58,
                        fontWeight: FontWeight.w900,
                        color: EcoColors.primaryDark,
                        letterSpacing: -1.5,
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.2),
                    Text(
                      'Đồng nát Online',
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: EcoColors.bodySecondary,
                        letterSpacing: 0.5,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    const SizedBox(height: 32),
                    Text(
                      'Ngân hàng rác thải số kết nối hộ gia đình, người thu gom và trạm tái chế trong một quy trình sạch, minh bạch.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 16,
                        height: 1.6,
                        color: EcoColors.bodyMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    const SizedBox(height: 48),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const OnboardingScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Bắt đầu ngay'),
                      style: FilledButton.styleFrom(
                        backgroundColor: EcoColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(62),
                        elevation: 4,
                        shadowColor: EcoColors.primary.withOpacity(0.4),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ).animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    ).shimmer(delay: 3.seconds, duration: 2.seconds),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [EcoColors.logoGreenLight, EcoColors.logoGreenDark],
        ),
        boxShadow: [
          BoxShadow(
            color: EcoColors.primary.withOpacity(0.25),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 0,
            spreadRadius: -10,
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, size: 90, color: Colors.white),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(
          begin: const Offset(1, 1),
          end: const Offset(1.05, 1.05),
          duration: 3.seconds,
          curve: Curves.easeInOut,
        ).shimmer(duration: 2.seconds);
  }
}
