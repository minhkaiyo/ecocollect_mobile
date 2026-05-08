import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../repositories/notification_repository.dart';
import '../../../theme/eco_colors.dart';

class NotificationsSheet extends StatelessWidget {
  const NotificationsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
    final notifRepo = NotificationRepository();

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Text('Thông báo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: notifRepo.watchUserNotifications(uid),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final notifications = snapshot.data!;
                if (notifications.isEmpty) return const _EmptyNotifications();

                return ListView.builder(
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    final n = notifications[index];
                    return _NotificationTile(
                      icon: _getIconForTitle(n['title'] ?? ''),
                      title: n['title'] ?? 'Thông báo',
                      body: n['body'] ?? '',
                      time: _formatTime(n['createdAt']),
                      color: _getColorForTitle(n['title'] ?? ''),
                      isNew: n['read'] == false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    if (title.contains('Hoàn tất') || title.contains('thành')) return Icons.check_circle_rounded;
    if (title.contains('đã nhận') || title.contains('đang đến')) return Icons.local_shipping_rounded;
    if (title.contains('gửi yêu cầu')) return Icons.send_rounded;
    return Icons.notifications_rounded;
  }

  Color _getColorForTitle(String title) {
    if (title.contains('Hoàn tất')) return EcoColors.success;
    if (title.contains('đã nhận')) return EcoColors.orange;
    if (title.contains('gửi yêu cầu')) return EcoColors.blue;
    return EcoColors.primary;
  }

  String _formatTime(dynamic createdAt) {
    if (createdAt == null) return 'Vừa xong';
    // Simple mock formatter for demo
    return 'Vừa xong'; 
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.icon,
    required this.title,
    required this.body,
    required this.time,
    required this.color,
    this.isNew = false,
  });

  final IconData icon;
  final String title;
  final String body;
  final String time;
  final Color color;
  final bool isNew;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isNew ? color.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isNew ? color.withOpacity(0.2) : EcoColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14)),
                    Text(time, style: const TextStyle(fontSize: 11, color: EcoColors.bodyMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(fontSize: 13, color: EcoColors.textBody, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyNotifications extends StatelessWidget {
  const _EmptyNotifications();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_rounded, size: 64, color: EcoColors.surfaceMuted),
          const SizedBox(height: 16),
          const Text('Chưa có thông báo nào.', style: TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
