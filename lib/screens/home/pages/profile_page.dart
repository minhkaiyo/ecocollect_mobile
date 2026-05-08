import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/user_profile.dart';
import '../../../repositories/user_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';
import '../../scan_screen.dart';
import '../widgets/subscription_sheet.dart';
import '../../../constants/app_constants.dart';

void _showProfileSheet(
  BuildContext context, {
  required String title,
  required String body,
  required IconData icon,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(icon, color: EcoColors.primary, size: 42),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            Text(body, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, height: 1.45, color: EcoColors.bodyMuted)),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              style: FilledButton.styleFrom(backgroundColor: EcoColors.primary),
              child: const Text('Đóng', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key, required this.onFieldTap});

  final ValueChanged<int> onFieldTap;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Center(child: Text('Vui lòng đăng nhập'));
    }

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
        return Container(
          color: const Color(0xFFF4F3F7),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 28, 18, 112),
            children: [
              _ProfileHeader(
                profile: profile,
                onAvatarTap: () => _chooseAvatarSource(context, profile),
              ),
              const SizedBox(height: 18),
              _SubscriptionTierCard(profile: profile),
              const SizedBox(height: 18),
              _CompletionNotice(onLater: () => onFieldTap(0)),
              const SizedBox(height: 20),
              _ProfileShortcutGrid(
                onItemTap: (title, icon) => _showProfileSheet(
                  context,
                  title: title.replaceAll('\n', ' '),
                  body: 'Khu vực quản lý ${title.replaceAll('\n', ' ').toLowerCase()} của tài khoản EcoCollect.',
                  icon: icon,
                ),
              ),
              const SizedBox(height: 22),
              _SecurityScanCard(
                onScan: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const ScanScreen()),
                ),
              ),
              _GreenPointsWalletCard(
                points: profile.greenPoints,
                uid: profile.uid,
              ),
              const SizedBox(height: 14),
              const _DonationCard(),
              const SizedBox(height: 22),
              const _FriendFeedHeader(),
              const SizedBox(height: 14),
              _ProfileField(
                icon: Icons.person_rounded,
                title: 'Tên hiển thị',
                value: profile.displayName,
                onTap: () => _editField(context, 'displayName', profile.displayName, profile.uid, 'Tên hiển thị'),
              ),
              _ProfileField(
                icon: Icons.phone_rounded,
                title: 'Số điện thoại',
                value: profile.phone,
                onTap: () => _editField(context, 'phone', profile.phone, profile.uid, 'Số điện thoại'),
              ),
              _ProfileField(
                icon: Icons.location_on_rounded,
                title: 'Địa chỉ',
                value: profile.address,
                onTap: () => _editField(context, 'address', profile.address, profile.uid, 'Địa chỉ'),
              ),
              const SizedBox(height: 16),
              if (profile.role == 'seller')
                SizedBox(
                  height: 50,
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Đăng ký Người thu gom'),
                          content: const Text('Bạn có muốn nâng cấp tài khoản để bắt đầu nhận thu mua rác và được ghim vị trí trên bản đồ không?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                            FilledButton(
                              onPressed: () async {
                                Navigator.pop(ctx);
                                try {
                                  await UserRepository().updateProfile(profile.uid, {'role': 'collector'});
                                  if (context.mounted) {
                                    showEcoSnackBar(context, 'Chúc mừng! Bạn đã trở thành Người thu gom.', icon: Icons.celebration_rounded);
                                  }
                                } catch (e) {
                                  if (context.mounted) showEcoSnackBar(context, 'Lỗi: $e');
                                }
                              },
                              style: FilledButton.styleFrom(backgroundColor: EcoColors.primary),
                              child: const Text('Đăng ký ngay'),
                            ),
                          ],
                        ),
                      );
                    },
                    icon: const Icon(Icons.handshake_rounded),
                    label: const Text('Trở thành người thu gom', style: TextStyle(fontWeight: FontWeight.w900)),
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              if (profile.role == 'seller') const SizedBox(height: 12),
              SizedBox(
                height: 50,
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: FirebaseAuth.instance.signOut,
                  icon: const Icon(Icons.logout_rounded, color: EcoColors.orange),
                  label: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: EcoColors.orange, fontWeight: FontWeight.w900),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: EcoColors.orange, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    backgroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _chooseAvatarSource(BuildContext context, UserProfile profile) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: EcoColors.sheetHandle,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.camera_alt_rounded, color: EcoColors.primary),
                  title: const Text('Chụp ảnh'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadAvatar(context, profile, ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_rounded, color: EcoColors.blue),
                  title: const Text('Chọn từ thư viện'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _pickAndUploadAvatar(context, profile, ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadAvatar(
    BuildContext context,
    UserProfile profile,
    ImageSource source,
  ) async {
    try {
      final photo = await ImagePicker().pickImage(source: source, imageQuality: 70);
      if (photo == null) return;

      if (context.mounted) {
        showEcoSnackBar(context, 'Đang tải ảnh lên...', icon: Icons.upload_rounded);
      }

      final bytes = await photo.readAsBytes();
      final ref = FirebaseStorage.instance.ref().child('avatars/${profile.uid}.jpg');
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await UserRepository().updateProfile(profile.uid, {'photoUrl': url});
      if (context.mounted) {
        showEcoSnackBar(context, 'Cập nhật ảnh thành công!', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (context.mounted) {
        showEcoSnackBar(context, 'Lỗi tải ảnh: $e', icon: Icons.error_outline);
      }
    }
  }

  Future<void> _editField(
    BuildContext context,
    String field,
    String currentValue,
    String uid,
    String label,
  ) async {
    final controller = TextEditingController(text: currentValue);
    final newValue = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cập nhật $label'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Nhập $label mới',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Lưu')),
        ],
      ),
    );

    if (newValue != null && newValue != currentValue && newValue.isNotEmpty) {
      try {
        await UserRepository().updateProfile(uid, {field: newValue});
        if (context.mounted) {
          showEcoSnackBar(context, 'Đã cập nhật $label', icon: Icons.check_circle_rounded);
        }
      } catch (e) {
        if (context.mounted) {
          showEcoSnackBar(context, 'Lỗi cập nhật: $e', icon: Icons.error_outline);
        }
      }
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onAvatarTap});

  final UserProfile profile;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final account = profile.phone.isNotEmpty && !profile.phone.toLowerCase().contains('chưa')
        ? profile.phone
        : profile.uid.substring(0, profile.uid.length > 10 ? 10 : profile.uid.length);

    return Row(
      children: [
        GestureDetector(
          onTap: onAvatarTap,
          child: CircleAvatar(
            radius: 46,
            backgroundColor: const Color(0xFFE9E9EF),
            backgroundImage: profile.photoUrl != null && profile.photoUrl!.isNotEmpty
                ? NetworkImage(profile.photoUrl!)
                : null,
            child: profile.photoUrl == null || profile.photoUrl!.isEmpty
                ? const Icon(Icons.add_a_photo_outlined, color: EcoColors.navInactive, size: 34)
                : null,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (profile.isCollector)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: EcoColors.mintBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Người thu gom ', style: TextStyle(color: EcoColors.primary, fontSize: 11, fontWeight: FontWeight.bold)),
                          Icon(Icons.check_circle_rounded, color: EcoColors.primary, size: 14),
                        ],
                      ),
                    )
                  else
                    const Icon(Icons.check_circle_rounded, color: Color(0xFF4ACB3F), size: 22),
                ],
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: const Color(0xFFE9E9EF), borderRadius: BorderRadius.circular(9)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Số tài khoản: $account',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, color: EcoColors.navInactive, size: 18),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: EcoColors.navInactive, size: 38),
      ],
    );
  }
}

class _CompletionNotice extends StatelessWidget {
  const _CompletionNotice({required this.onLater});

  final VoidCallback onLater;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: EcoColors.blue, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.task_alt_rounded, color: EcoColors.blue, size: 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Còn 1 bước cuối cùng để hoàn thiện tài khoản',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Thêm ảnh đại diện giúp mọi người yên tâm hơn khi giao dịch với bạn.',
                  style: TextStyle(fontSize: 16, height: 1.35, fontWeight: FontWeight.w600),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onLater,
                    child: const Text('Nhắc tôi sau', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileShortcutGrid extends StatelessWidget {
  const _ProfileShortcutGrid({required this.onItemTap});

  final void Function(String title, IconData icon) onItemTap;

  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.manage_accounts_outlined, 'Bảo mật tài\nkhoản'),
      (Icons.account_balance_wallet_outlined, 'Nguồn tiền\n& thanh toán'),
      (Icons.support_agent_rounded, 'Trợ giúp'),
      (Icons.settings_outlined, 'Tất cả cài\nđặt'),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: GestureDetector(
            onTap: () => onItemTap(item.$2, item.$1),
            child: Column(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(color: const Color(0xFFEDEDF2), borderRadius: BorderRadius.circular(18)),
                  child: Icon(item.$1, color: EcoColors.navInactive, size: 30),
                ),
                const SizedBox(height: 8),
                Text(
                  item.$2,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, height: 1.25),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SecurityScanCard extends StatelessWidget {
  const _SecurityScanCard({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Icon(Icons.bug_report_outlined, color: EcoColors.blue, size: 34),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Công cụ quét rác độc hại', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                SizedBox(height: 4),
                Text('Rà soát ảnh rác và cảnh báo phân loại sai.', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, height: 1.3, color: EcoColors.textBody)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          OutlinedButton(
            onPressed: onScan,
            style: OutlinedButton.styleFrom(
              foregroundColor: EcoColors.primary,
              side: const BorderSide(color: EcoColors.primary, width: 1.4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Quét ngay', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _DonationCard extends StatelessWidget {
  const _DonationCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.volunteer_activism_outlined, color: EcoColors.primary, size: 30),
              const SizedBox(width: 10),
              const Expanded(child: Text('Gom yêu thương 1/6', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900))),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: Color(0xFFFFECF5), shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right_rounded, color: EcoColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 112,
                height: 84,
                decoration: BoxDecoration(
                  color: EcoColors.mintBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.recycling_rounded, size: 48, color: EcoColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bạn ơi, góp 1 tay gửi niềm vui đến các chiến binh xanh.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, height: 1.35, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [
                        Expanded(child: Text('5943 lượt quyên góp', style: TextStyle(color: EcoColors.bodyMuted))),
                        Text('64%', style: TextStyle(color: EcoColors.bodyMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: const LinearProgressIndicator(
                        value: .64,
                        minHeight: 6,
                        color: EcoColors.primary,
                        backgroundColor: EcoColors.progressTrack,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '85.867.276/133.400.000 VND',
                      style: TextStyle(color: EcoColors.primary, fontSize: 14, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _DonateChip(label: '50.000đ'),
                _DonateChip(label: '20.000đ'),
                _DonateChip(label: '10.000đ'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DonateChip extends StatelessWidget {
  const _DonateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showProfileSheet(
        context,
        title: 'Quyên góp $label',
        body: 'EcoCollect sẽ ghi nhận khoản đóng góp mô phỏng này vào chiến dịch Gom yêu thương.',
        icon: Icons.volunteer_activism_outlined,
      ),
      child: Container(
        width: 118,
        margin: const EdgeInsets.only(right: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: EcoColors.primary, width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 15, color: EcoColors.primary, fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _FriendFeedHeader extends StatelessWidget {
  const _FriendFeedHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Bảng tin bạn bè', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: Center(child: Text('Bản thân', style: TextStyle(fontSize: 15, color: EcoColors.primary, fontWeight: FontWeight.w900)))),
            Expanded(child: Center(child: Text('Xu hướng', style: TextStyle(fontSize: 15, color: EcoColors.textBody, fontWeight: FontWeight.w700)))),
          ],
        ),
        SizedBox(height: 8),
        LinearProgressIndicator(value: .5, minHeight: 3, color: EcoColors.primary, backgroundColor: Colors.transparent),
      ],
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Icon(icon, color: EcoColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 13, color: EcoColors.bodyMuted, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: EcoColors.iconMuted),
          ],
        ),
      ),
    );
  }
}

class _GreenPointsWalletCard extends StatelessWidget {
  const _GreenPointsWalletCard({required this.points, required this.uid});

  final int points;
  final String uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: EcoColors.mintBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.account_balance_wallet_rounded, color: EcoColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Ví điểm xanh', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text('$points điểm', style: const TextStyle(fontSize: 14, color: EcoColors.primary, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          FilledButton(
            onPressed: () => _showTopUpDialog(context),
            style: FilledButton.styleFrom(
              backgroundColor: EcoColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: const Text('Nạp điểm', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }

  void _showTopUpDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nạp Điểm Xanh', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Nhập số điểm bạn muốn nạp (Kiểm thử):'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Ví dụ: 5000',
                suffixText: 'điểm',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Ghi chú: Nút thanh toán bên dưới dùng để mô phỏng quy trình thực tế.',
              style: TextStyle(fontSize: 12, color: EcoColors.bodyMuted, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
          FilledButton.icon(
            onPressed: () async {
              final amount = int.tryParse(controller.text);
              if (amount == null || amount <= 0) {
                showEcoSnackBar(context, 'Vui lòng nhập số điểm hợp lệ');
                return;
              }
              Navigator.pop(ctx);
              
              try {
                // Giả lập thanh toán
                showEcoSnackBar(context, 'Đang xử lý thanh toán...', icon: Icons.payment_rounded);
                await Future.delayed(const Duration(seconds: 1));
                
                await UserRepository().updateProfile(uid, {
                  'greenPoints': FieldValue.increment(amount),
                });
                
                if (context.mounted) {
                  ecoSuccessTap();
                  showEcoSnackBar(context, 'Đã nạp thành công $amount điểm xanh!', icon: Icons.check_circle_rounded);
                }
              } catch (e) {
                if (context.mounted) showEcoSnackBar(context, 'Lỗi nạp điểm: $e');
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.blue.shade700),
            icon: const Icon(Icons.payment_rounded, size: 18),
            label: const Text('Thanh toán & Nạp'),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionTierCard extends StatelessWidget {
  const _SubscriptionTierCard({required this.profile});
  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final tier = AppConstants.subTiers[profile.subscriptionTier] ?? AppConstants.subTiers['free']!;
    final isFree = profile.subscriptionTier == 'free';
    
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: isFree ? EcoColors.border : EcoColors.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isFree ? EcoColors.inputFill : EcoColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFree ? Icons.person_outline_rounded : Icons.workspace_premium_rounded, 
              color: isFree ? EcoColors.iconMuted : EcoColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gói thành viên: ${tier['label']}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                ),
                const SizedBox(height: 4),
                Text(
                  'Giới hạn: ${tier['limit']} điểm vị trí',
                  style: const TextStyle(color: EcoColors.bodyMuted, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => SubscriptionSheet(
                  currentTier: profile.subscriptionTier,
                  uid: profile.uid,
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: EcoColors.primary,
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
            child: const Text('NÂNG CẤP'),
          ),
        ],
      ),
    );
  }
}
