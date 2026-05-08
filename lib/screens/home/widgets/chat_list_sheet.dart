import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';

class ChatListSheet extends StatelessWidget {
  const ChatListSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Text('Tin nhắn', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          Expanded(
            child: ListView(
              children: [
                _ChatTile(
                  name: 'Hoàng Collector',
                  lastMsg: 'Tôi đang đến trạm của bạn, khoảng 5 phút nữa.',
                  time: '11:45',
                  isOnline: true,
                  unreadCount: 1,
                ),
                _ChatTile(
                  name: 'Minh Tái Chế',
                  lastMsg: 'Ảnh nhựa PET này bạn thu bao nhiêu?',
                  time: 'Hôm qua',
                ),
                _ChatTile(
                  name: 'Trung Tâm EcoCollect',
                  lastMsg: 'Chào bạn, chúng tôi có thể giúp gì cho bạn?',
                  time: 'Thứ 2',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatTile extends StatelessWidget {
  const _ChatTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    this.isOnline = false,
    this.unreadCount = 0,
  });

  final String name;
  final String lastMsg;
  final String time;
  final bool isOnline;
  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: EcoColors.surfaceMuted,
            child: Text(name[0], style: const TextStyle(fontWeight: FontWeight.w900, color: EcoColors.primary)),
          ),
          if (isOnline)
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: EcoColors.success, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
              ),
            ),
        ],
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
      subtitle: Text(lastMsg, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: unreadCount > 0 ? EcoColors.textBody : EcoColors.bodyMuted, fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.w500)),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(time, style: const TextStyle(fontSize: 11, color: EcoColors.bodyMuted)),
          if (unreadCount > 0)
            Container(
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: EcoColors.coral, borderRadius: BorderRadius.circular(10)),
              child: Text(unreadCount.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
            ),
        ],
      ),
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      onTap: () {},
    );
  }
}
