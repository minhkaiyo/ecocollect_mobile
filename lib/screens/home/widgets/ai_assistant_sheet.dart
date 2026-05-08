import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class AiAssistantSheet extends StatefulWidget {
  const AiAssistantSheet({super.key});

  @override
  State<AiAssistantSheet> createState() => _AiAssistantSheetState();
}

class _AiAssistantSheetState extends State<AiAssistantSheet> {
  final TextEditingController _messageController = TextEditingController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  XFile? _selectedImage;
  
  late GenerativeModel _model;
  late ChatSession _chat;

  @override
  void initState() {
    super.initState();
    // Khởi tạo Gemini (Sử dụng API Key của Minh hoặc placeholder)
    // Lưu ý: Cần thay thế bằng API Key thực tế từ Google AI Studio
    const apiKey = 'AIzaSyCeUP5qQBRzHL3gpn7lo65Ck_TfdP1SdQc';
    
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system(
        'Bạn là "AI Tái Chế" - trợ lý thông minh của ứng dụng EcoCollect. '
        'Nhiệm vụ của bạn là giúp người dùng phân loại rác, nhận diện vật liệu phế liệu qua hình ảnh và cung cấp thông tin về bảo vệ môi trường tại Việt Nam. '
        'Hãy trả lời thân thiện, ngắn gọn và chuyên nghiệp. Nếu người dùng gửi ảnh, hãy phân tích kỹ đó là loại nhựa/giấy/kim loại nào.'
      ),
    );
    _chat = _model.startChat();
    
    // Tin nhắn chào mừng
    _messages.add(ChatMessage(
      text: 'Xin chào! Tôi là trợ lý EcoCollect. Bạn cần tôi giúp phân loại loại rác nào hôm nay? Bạn có thể gửi ảnh để tôi nhận diện giúp nhé!',
      isUser: false,
    ));
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = image);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty && _selectedImage == null) return;

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true, imagePath: _selectedImage?.path));
      _isLoading = true;
    });

    final prompt = text.isEmpty ? "Đây là vật liệu gì và tôi nên xử lý thế nào?" : text;
    _messageController.clear();

    try {
      GenerateContentResponse response;
      if (_selectedImage != null) {
        final imageBytes = await _selectedImage!.readAsBytes();
        final content = [
          Content.multi([
            TextPart(prompt),
            DataPart('image/jpeg', imageBytes),
          ]),
        ];
        response = await _model.generateContent(content);
      } else {
        response = await _chat.sendMessage(Content.text(prompt));
      }

      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(text: response.text ?? 'Tôi không rõ, bạn thử hỏi cách khác nhé.', isUser: false));
          _selectedImage = null;
        });
      }
    } catch (e) {
      if (mounted) showEcoSnackBar(context, 'Lỗi AI: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999))),
          const SizedBox(height: 16),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_rounded, color: EcoColors.primary),
              SizedBox(width: 8),
              Text('Trợ lý AI Tái chế', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
            ],
          ),
          const Divider(height: 32),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _messages[index],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(_selectedImage!.path, height: 80, width: 80, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedImage = null),
                      child: Container(color: Colors.black54, child: const Icon(Icons.close, color: Colors.white, size: 18)),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_a_photo_rounded, color: EcoColors.primary),
                  onPressed: _pickImage,
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Hỏi AI về vật liệu...',
                      filled: true,
                      fillColor: EcoColors.inputFill,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: EcoColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: _sendMessage,
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

class ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;
  final String? imagePath;

  const ChatMessage({super.key, required this.text, required this.isUser, this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (imagePath != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imagePath!, height: 150, fit: BoxFit.cover, errorBuilder: (_,__,___) => const Icon(Icons.image)),
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isUser ? EcoColors.primary : EcoColors.surfaceMuted,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(isUser ? 16 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 16),
              ),
            ),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: Text(
              text,
              style: TextStyle(color: isUser ? Colors.white : EcoColors.textBody, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
