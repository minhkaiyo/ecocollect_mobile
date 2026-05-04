import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'screens/onboarding_screen.dart';

void main() {
  runApp(const EcoCollectApp());
}

class EcoCollectApp extends StatelessWidget {
  const EcoCollectApp({super.key});

  @override
  Widget build(BuildContext context) {
    const emerald = Color(0xFF119F63);

    return MaterialApp(
      title: 'EcoCollect',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: emerald,
          primary: emerald,
          secondary: const Color(0xFF1F73D6),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F8F7),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Color(0xFF102A24),
        ),
      ),
      home: const WelcomeScreen(),
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFEAF8F1), Color(0xFFFFFFFF), Color(0xFFEAF2FF)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LogoMark(size: 132)
                        .animate()
                        .fadeIn(duration: 800.ms)
                        .scale(delay: 200.ms)
                        .shimmer(delay: 1200.ms, duration: 1500.ms),
                    const SizedBox(height: 28),
                    Text(
                      'EcoCollect',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF0B6B4B),
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),
                    const SizedBox(height: 6),
                    const Text(
                      'Đồng nát Online',
                      style: TextStyle(
                        fontSize: 18,
                        color: Color(0xFF60736D),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    const SizedBox(height: 24),
                    const Text(
                      'Ngân hàng rác thải số kết nối hộ gia đình, người thu gom và trạm tái chế trong một quy trình sạch, minh bạch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        height: 1.45,
                        color: Color(0xFF52645F),
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
                        backgroundColor: const Color(0xFF119F63),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(62),
                        elevation: 4,
                        shadowColor: const Color(0xFF119F63).withOpacity(0.4),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                     .shimmer(delay: 3.seconds, duration: 2.seconds),
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
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF7AD34F), Color(0xFF0B8D5B)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF119F63).withOpacity(.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: const Icon(Icons.eco_rounded, color: Colors.white, size: 76),
    );
  }
}
