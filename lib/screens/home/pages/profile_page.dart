import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../theme/eco_colors.dart';
import '../widgets/common_home_widgets.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onFieldTap});
  final ValueChanged<int> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return const Center(child: Text('Vui lòng đăng nhập'));

    return StreamBuilder<UserProfile>(
      stream: UserRepository().watchProfile(uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text('Lỗi tải thông tin cá nhân'));
        }

        final profile = snapshot.data!;

        return ListView(
          padding: const EdgeInsets.all(18),
          children: [
            const Text(
              'Hồ sơ cá nhân',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 16),
            _ProfileField(
              index: 0,
              icon: Icons.person_rounded,
              text: profile.displayName,
              onTap: onFieldTap,
            ),
            _ProfileField(
              index: 1,
              icon: Icons.phone_rounded,
              text: profile.phone,
              onTap: onFieldTap,
            ),
            _ProfileField(
              index: 2,
              icon: Icons.location_on_rounded,
              text: profile.address,
              onTap: onFieldTap,
            ),
            _ProfileField(
              index: 3,
              icon: Icons.verified_user_rounded,
              text: 'UID: ${profile.uid.substring(0, 8)}...',
              onTap: onFieldTap,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () {
                  FirebaseAuth.instance.signOut();
                },
                icon: const Icon(Icons.logout_rounded, color: EcoColors.orange),
                label: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: EcoColors.orange, fontWeight: FontWeight.w800),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: EcoColors.orange, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.index,
    required this.icon,
    required this.text,
    required this.onTap,
  });

  final int index;
  final IconData icon;
  final String text;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return EcoTappablePanel(
      margin: const EdgeInsets.only(bottom: 12),
      onTap: () => onTap(index),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          EcoIconTile(icon: icon, color: EcoColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          const Icon(Icons.edit_outlined, color: EcoColors.iconMuted, size: 20),
        ],
      ),
    );
  }
}
