import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> runSeed() async {
  final prefs = await SharedPreferences.getInstance();
  final alreadySeeded = prefs.getBool('vouchers_seeded_v2') ?? false;
  
  if (alreadySeeded) return;

  final db = FirebaseFirestore.instance;
  final vouchers = [
    {
      'title': '1000M Coffee - Giảm 10k',
      'description': 'Áp dụng cho hóa đơn từ 50k tại chuỗi 1000M Coffee.',
      'pointsCost': 100,
      'category': 'food',
      'imageUrl': 'assets/images/vouchers/1000m_1.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': '1000M Coffee - Mua 1 Tặng 1',
      'description': 'Mua 1 ly cà phê bất kỳ tặng 1 ly cà phê sữa.',
      'pointsCost': 200,
      'category': 'food',
      'imageUrl': 'assets/images/vouchers/1000m_2.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': '1000M Coffee - Giảm 20%',
      'description': 'Giảm 20% trên tổng hóa đơn thanh toán.',
      'pointsCost': 300,
      'category': 'food',
      'imageUrl': 'assets/images/vouchers/1000m_3.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Circle K - Combo Sáng',
      'description': 'Combo bánh bao + sữa bắp chỉ 25k.',
      'pointsCost': 150,
      'category': 'shopping',
      'imageUrl': 'assets/images/vouchers/circle_k.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Highlands - Trà Sen Vàng',
      'description': 'Giảm ngay 15k khi mua Trà Sen Vàng cỡ lớn.',
      'pointsCost': 250,
      'category': 'food',
      'imageUrl': 'assets/images/vouchers/highlands.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'TCH - Tặng Bánh Mì',
      'description': 'Tặng 1 bánh mì que khi mua cà phê size L.',
      'pointsCost': 120,
      'category': 'food',
      'imageUrl': 'assets/images/vouchers/the_coffee_house.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
    {
      'title': 'Winmart - Phiếu 50k',
      'description': 'Phiếu mua hàng trị giá 50,000 VNĐ tại Winmart.',
      'pointsCost': 500,
      'category': 'shopping',
      'imageUrl': 'assets/images/vouchers/winmart.jpg',
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
    },
  ];

  print('EcoCollect: Đang tự động nạp voucher branch...');

  for (var v in vouchers) {
    try {
      await db.collection('vouchers').add(v);
    } catch (e) {
      print('EcoCollect: Lỗi seeding ${v['title']}: $e');
    }
  }

  await prefs.setBool('vouchers_seeded_v2', true);
  print('EcoCollect: Đã hoàn tất nạp voucher branch!');
}
