import os
import re

mapping = {
    'GiĂ¡ÂºÂ¥y': 'Giấy',
    'NhĂ¡Â»Â±a': 'Nhựa',
    'Kim loĂ¡ÂºÂ¡i': 'Kim loại',
    'Ă„Â iĂ¡Â»â€¡n tĂ¡Â»Â­': 'Điện tử',
    'CĂ¡Â»â€œng kĂ¡Â»Â nh': 'Cồng kềnh',
    'Ä‚â€°p phĂ¡ÂºÂ³ng, buĂ¡Â»â„¢c gĂ¡Â»Â n': 'Ép phẳng, buộc gọn',
    'LÄ‚Â m sĂ¡ÂºÂ¡ch, thÄ‚Â¡o nhÄ‚Â£n': 'Làm sạch, tháo nhãn',
    'TÄ‚Â¡ch theo nhÄ‚Â³m kim loĂ¡ÂºÂ¡i': 'Tách theo nhóm kim loại',
    'BĂ¡ÂºÂ£o quĂ¡ÂºÂ£n nguyÄ‚Âªn khĂ¡Â»â€˜i': 'Bảo quản nguyên khối',
    'ChĂ¡Â»Â¥p Ă¡ÂºÂ£nh trĂ†Â°Ă¡Â»â€ºc khi gĂ¡Â»Â­i': 'Chụp ảnh trước khi gửi',
    'Trang chĂ¡Â»Â§': 'Trang chủ',
    'LĂ¡Â»â€¹ch sĂ¡Â»Â­': 'Lịch sử',
    'Thu mua': 'Thu mua',
    'VÄ‚Â­ Xanh': 'Ví Xanh',
    'CÄ‚Â i Ă„â€˜Ă¡ÂºÂ·t': 'Cài đặt',
    'Ă„Â Ä‚Â£ phÄ‚Â¡t tÄ‚Â­n hiĂ¡Â»â€¡u. EcoCollect Ă„â€˜ang ghÄ‚Â©p ngĂ†Â°Ă¡Â»Â i thu gom gĂ¡ÂºÂ§n nhĂ¡ÂºÂ¥t.': 'Đã phát tín hiệu. EcoCollect đang ghép người thu gom gần nhất.',
    'KĂ¡ÂºÂ¿t quĂ¡ÂºÂ£ tÄ‚Â¬m kiĂ¡ÂºÂ¿m': 'Kết quả tìm kiếm',
    'GiĂ¡ÂºÂ¥y bÄ‚Â¬a': 'Giấy bìa',
    'TrĂ¡ÂºÂ¡m CĂ¡ÂºÂ§u GiĂ¡ÂºÂ¥y cÄ‚Â¡ch 1.8km, Ă„â€˜ang mĂ¡Â»Å¸ cĂ¡Â»Â­a': 'Trạm Cầu Giấy cách 1.8km, đang mở cửa',
    'CĂ¡ÂºÂ©m nang: lÄ‚Â m sĂ¡ÂºÂ¡ch, phÄ‚Â¢n nhÄ‚Â³m trĂ†Â°Ă¡Â»â€ºc khi gĂ¡Â»Â­i': 'Cẩm nang: làm sạch, phân nhóm trước khi gửi',
    'AI scan phĂ¡ÂºÂ¿ liĂ¡Â»â€¡u': 'AI scan phế liệu',
    'VĂ¡Â»Â  lon bia': 'Vỏ lon bia',
    'NhÄ‚Â´m': 'Nhôm',
    'ThÄ‚Â¹ng carton': 'Thùng carton',
    'GĂ¡Â»Â£i Ä‚Â½': 'Gợi ý',
    'chĂ¡Â»Â¥p rÄ‚Âµ nĂ¡Â»Â n': 'chụp rõ nền',
    'trÄ‚Â¡nh trĂ¡Â»â„¢n nhiĂ¡Â»Â u nhÄ‚Â³m rÄ‚Â¡c': 'tránh trộn nhiều nhóm rác',
    'Ă„Â Ă¡ÂºÂ·t lĂ¡Â»â€¹ch gom Ă„â€˜Ă¡Â»â€¹nh kĂ¡Â»Â³': 'Đặt lịch gom định kỳ',
    'Dá»|n rĂ¡c thĂ´ng minh - TĂCH LÅ©y sá»‘ng xanh': 'Dọn rác thông minh - Tích luỹ sống xanh',
    'NhĂ¢p vĂ o chá»...': 'Nhập vào chữ...',
    'Loáº¡i phĂª liĂªu': 'Loại phế liệu',
    'TrĂ¡ng lĂºong vĂ  Ä a trĂ¡': 'Trọng lượng ước tính',
    'TĂ¡m tĂ¡m': 'Tạm tính',
    'Ă p phĂª dĂºng...': 'Áp dụng thành công',
    'PHĂ T TĂ N HIĂ U THU GOM': 'PHÁT TÍN HIỆU THU GOM',
    'Ä ang ghĂ©p ...': 'Đang ghép chuyến...',
    'Radar tĂ¬m ngÆ°á» i thu gom': 'Radar tìm người thu gom',
    'Tráº¡m táº­p káº¿t': 'Trạm tập kết',
    'CĂ¡ch 1.2km': 'Cách 1.2km',
    'Ä á»“ng nĂ¡t Online': 'Đồng nát Online',
    'PhĂ¢n loáº¡i dá»… dĂ ng': 'Phân loại dễ dàng',
    'QuĂ©t camera nháº­n diá»‡n giáº¥y, nhá»±a, kim loáº¡i vĂ  rĂ¡c Ä‘iá»‡n tá»­ báº±ng AI trÆ°á»›c khi táº¡o Ä‘Æ¡n thu gom.': 'Quét camera nhận diện giấy, nhựa, kim loại và rác điện tử bằng AI trước khi tạo đơn thu gom.',
    'Káº¿t ná»‘i nhanh chĂ³ng': 'Kết nối nhanh chóng',
    'Radar tĂ¬m ngÆ°á» i thu gom trong bĂ¡n kĂ­nh gáº§n nháº¥t hoáº·c gá»£i Ă½ tráº¡m táº­p káº¿t phĂ¹ há»£p.': 'Radar tìm người thu gom trong bán kính gần nhất hoặc gợi ý trạm tập kết phù hợp.',
    'TĂ­ch Ä‘iá»ƒm sá»‘ng xanh': 'Tích điểm sống xanh',
    'Nháº­n tiá» n hoáº·c Ä‘á»•i sang Ä iá»ƒm Xanh Ä‘á»ƒ láº¥y voucher, náº¡p Ä‘iá»‡n thoáº¡i vĂ  gĂ³p quá»¹ trá»“ng cĂ¢y.': 'Nhận tiền hoặc đổi sang Điểm Xanh để lấy voucher, nạp điện thoại và góp quỹ trồng cây.',
    'Bá»  qua': 'Bỏ qua',
    'Báº¯t Ä‘áº§u': 'Bắt đầu',
    'Tiáº¿p': 'Tiếp',
    'NhĂ¡ÂºÂ­p tĂ¡Â»Â« khĂƒÂ³a tĂƒÂ¬m kiĂ¡ÂºÂ¿m, loĂ¡ÂºÂ¡i phĂ¡ÂºÂ¿ liĂ¡Â»â€¡u, cĂ¡ÂºÂ©m nang phĂƒÂ¢n loĂ¡ÂºÂ¡i': 'Nhập từ khóa tìm kiếm, loại phế liệu, cẩm nang phân loại',
    'DĂ¡Â»Â n rĂƒÂ¡c thĂƒÂ´ng minh - TĂƒÂCH lĂ…Â©y sĂ¡Â»â€˜ng xanh': 'Dọn rác thông minh - TÍCH lũy sống xanh',
    'NhĂ¡ÂºÂ­p Ă„â€˜Ă¡Â»â€¹a chĂ¡Â»â€°...': 'Nhập địa chỉ...',
    'ChĂ¡Â»Â n nhĂƒÂ m phĂ¡ÂºÂ¿ liĂ¡Â»â€¡u vĂƒÂ  phĂƒÂ¡t tĂƒÂn hiĂ¡Â»â€¡u Ă„â€˜Ă¡Â»Æ’ hĂ¡Â»â€¡ thĂ¡Â»â€˜ng ghĂƒÂ©p ngĂ†Â°Ă¡Â»Â i thu gom hoĂ¡ÂºÂ·c trĂ¡ÂºÂ¡m tĂ¡ÂºÂ­p kĂ¡ÂºÂ¿t gĂ¡ÂºÂ§n nhĂ¡ÂºÂ¥t.': 'Chọn nhóm phế liệu và phát tín hiệu để hệ thống ghép người thu gom hoặc trạm tập kết gần nhất.',
    'Ă„Â Ă¡Â»â€¹a chĂ¡Â»â€°': 'Địa chỉ',
    'VĂƒÂ­ dĂ¡Â»Â¥: SĂ¡Â»â€˜ 12 ChĂƒÂ¹a BĂƒÂ³c, HĂƒÂ  NĂ¡Â»â„¢i': 'Ví dụ: Số 12 Chùa Bộc, Hà Nội',
    'LoĂ¡ÂºÂ¡i phĂ¡ÂºÂ¿ liĂ¡Â»â€¡u': 'Loại phế liệu',
    'CĂ¡Â»â€œng kĂ¡Â»Â nh': 'Cồng kềnh',
    'TrĂ¡Â»Â ng lĂ†Â°Ă¡Â»Â£ng Ă†Â°Ă¡Â»â€ºc tĂƒÂ­nh': 'Trọng lượng ước tính',
    'TĂ¡ÂºÂ¡m tĂƒÂ­nh': 'Tạm tính',
    'ĂƒÂ p phĂƒÂ¢ dĂ¡Â»Â¥ng...': 'Áp dụng thành công',
    'PHĂƒÂ T TĂƒÂ N HIĂ¡Â»â€ U THU GOM': 'PHÁT TÍN HIỆU THU GOM',
    'Ă„Â ang ghĂƒÂ©p Ă„â€˜Ă¡Â»â€¹n quanh Ă„â€˜ĂƒÂ¡ng Ă„â€˜a': 'Đang ghép chuyến quanh khu vực',
    '3 ngĂ†Â°Ă¡Â»Â i thu gom sĂ¡ÂºÂµn sĂƒÂ ng, thĂ¡Â»Â i gian Ă„â€˜ĂƒÂ¡n cĂƒÂ¡ tĂƒÂ­nh 8-12 phĂƒÂºt': '3 người thu gom sẵn sàng, thời gian đón ước tính 8-12 phút.',
    'Theo dĂƒÂµi': 'Theo dõi',
    'NhĂ¡ÂºÂ­n diĂ¡Â»â€¡n rĂƒÂ¡c': 'Nhận diện rác',
    'Gom Ă„â€˜Ă¡Â»â€¹nh kĂ¡Â»Â³': 'Gom định kỳ',
    'TrĂ¡ÂºÂ¡m gĂ¡ÂºÂ§n': 'Trạm gần',
    'TĂƒÂ¬m mang ra': 'Tìm mang ra',
    'Ă„Â Ă¡Â»â€¢i Ă„â€˜iĂ¡Â»Æ’m': 'Đổi điểm',
    'Voucher xanh': 'Voucher xanh',
    'Radar TĂƒÂ¬m NgĂ†Â°Ă¡Â»Â i Thu Gom': 'Radar Tìm Người Thu Gom',
    'CĂƒÂ¡ch 1.2km': 'Cách 1.2km',
    'TrĂ¡ÂºÂ¡m tĂ¡ÂºÂ­p kĂ¡ÂºÂ¿t': 'Trạm tập kết'
}

def clean_file(filepath):
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            
        for k, v in mapping.items():
            content = content.replace(k, v)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Cleaned {filepath}")
    except Exception as e:
        print(f"Error {filepath}: {e}")

clean_file('lib/screens/home_screen.dart')
clean_file('lib/screens/onboarding_screen.dart')
