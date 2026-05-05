import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../persistence/launch_state.dart';
import '../theme/eco_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingItem> _items = [
    const _OnboardingItem(
      title: 'Phân loại thông minh',
      description:
          'Sử dụng AI để nhận diện và phân loại phế liệu chính xác. Tăng giá trị cho rác thải của bạn.',
      icon: FontAwesomeIcons.recycle,
      color: EcoColors.primary,
    ),
    const _OnboardingItem(
      title: 'Gọi thu gom tức thì',
      description:
          'Phát tín hiệu Radar để kết nối với người thu gom gần nhất trong khu vực của bạn.',
      icon: FontAwesomeIcons.wifi,
      color: EcoColors.blue,
    ),
    const _OnboardingItem(
      title: 'Tích lũy Điểm Xanh',
      description:
          'Mỗi kg rác thải được thu hồi sẽ đổi lại Điểm Xanh để nhận voucher và quà tặng hấp dẫn.',
      icon: FontAwesomeIcons.leaf,
      color: EcoColors.orange,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _goHome() async {
    await markOnboardingComplete();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _items.length,
            itemBuilder: (context, index) =>
                _OnboardingPage(item: _items[index]),
          ),
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: SafeArea(
              child: Column(
                children: [
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _items.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: EcoColors.primary,
                      dotColor: EcoColors.mapPark,
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 4,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Row(
                    children: [
                      TextButton(
                        onPressed: _goHome,
                        child: const Text(
                          'Bỏ qua',
                          style: TextStyle(
                            color: EcoColors.bodyMuted,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const Spacer(),
                      _currentPage == _items.length - 1
                          ? FilledButton(
                              onPressed: _goHome,
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: const Text(
                                'Bắt đầu',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            )
                          : FloatingActionButton(
                              onPressed: () => _controller.nextPage(
                                duration: 500.ms,
                                curve: Curves.easeOutCubic,
                              ),
                              backgroundColor: EcoColors.primary,
                              elevation: 2,
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                            ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item});
  final _OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: FaIcon(item.icon, size: 80, color: item.color),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 60),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 30,
              fontWeight: FontWeight.w900,
              color: EcoColors.headline,
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
          const SizedBox(height: 20),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.beVietnamPro(
              fontSize: 16,
              height: 1.6,
              color: EcoColors.bodyMuted,
              fontWeight: FontWeight.w500,
            ),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });

  final String title;
  final String description;
  final dynamic icon;
  final Color color;
}
