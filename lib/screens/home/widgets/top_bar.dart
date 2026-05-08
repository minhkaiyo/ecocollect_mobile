import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../theme/eco_colors.dart';
import 'mini_logo.dart';

class HomeTopBar extends StatefulWidget {
  const HomeTopBar({
    super.key,
    required this.isWide,
    required this.onSearch,
    required this.onMobileSearchOpen,
    required this.onNotificationsTap,
    required this.onPointsTap,
  });

  final bool isWide;
  final ValueChanged<String> onSearch;
  final VoidCallback onMobileSearchOpen;
  final VoidCallback onNotificationsTap;
  final VoidCallback onPointsTap;

  @override
  State<HomeTopBar> createState() => _HomeTopBarState();
}

class _HomeTopBarState extends State<HomeTopBar> {
  Stream<UserProfile>? _profileStream;

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _profileStream = UserRepository().watchProfile(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(widget.isWide ? 28 : 16, 16, widget.isWide ? 28 : 16, 10),
      child: Row(
        children: [
          EcoMiniLogo(compact: !widget.isWide),
          if (widget.isWide) ...[
            const SizedBox(width: 28),
            Expanded(
              child: TextField(
                onSubmitted: widget.onSearch,
                decoration: InputDecoration(
                  hintText: 'Giá thị trường, trạm tập kết, cẩm nang phân loại',
                  prefixIcon: const Icon(Icons.search_rounded),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
          ] else ...[
            const Spacer(),
            IconButton.filledTonal(
              onPressed: widget.onMobileSearchOpen,
              icon: const Icon(Icons.search_rounded),
              style: IconButton.styleFrom(
                backgroundColor: EcoColors.mintBg,
                foregroundColor: EcoColors.primary,
              ),
            ),
          ],
          const SizedBox(width: 10),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onNotificationsTap,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: EcoIconBadge(
                  icon: Icons.notifications_none_rounded,
                  badge: '1',
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Material(
            color: EcoColors.subtleBlue,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              onTap: widget.onPointsTap,
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    const Icon(Icons.token_rounded, color: EcoColors.blue),
                    const SizedBox(width: 8),
                    if (_profileStream != null)
                      StreamBuilder<UserProfile>(
                        stream: _profileStream,
                        builder: (context, snapshot) {
                          final points = snapshot.data?.greenPoints ?? 0;
                          return Text(
                            '$points Điểm',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
