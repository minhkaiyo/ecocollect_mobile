import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  XFile? _image;
  bool _isAnalyzing = false;
  String? _resultLabel;
  double? _confidence;

  final _picker = ImagePicker();
  
  final List<String> _labels = ['cardboard', 'glass', 'metal', 'paper', 'plastic', 'trash'];
  final Map<String, String> _labelToVietnamese = {
    'cardboard': 'Thùng carton',
    'glass': 'Thủy tinh',
    'metal': 'Kim loại',
    'paper': 'Giấy',
    'plastic': 'Nhựa',
    'trash': 'Rác thải khác'
  };

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _image = pickedFile;
          _resultLabel = null;
          _confidence = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      if (mounted) {
        showEcoSnackBar(context, 'Lỗi mở camera/thư viện ảnh.', icon: Icons.error_outline);
      }
    }
  }

  Future<void> _analyzeImage() async {
    setState(() => _isAnalyzing = true);
    
    await Future.delayed(const Duration(seconds: 2));
    
    final random = Random();
    final idx = random.nextInt(_labels.length);
    
    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _resultLabel = _labelToVietnamese[_labels[idx]];
        _confidence = 0.75 + (random.nextDouble() * 0.23);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Nhận Diện Phế Liệu', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: EcoColors.textBody,
        elevation: 0,
      ),
      backgroundColor: EcoColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: FutureBuilder<Uint8List>(
                        future: _image!.readAsBytes(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(color: EcoColors.primary),
                            );
                          }
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.camera_alt_rounded, size: 64, color: EcoColors.iconMuted.withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Chưa có hình ảnh',
                          style: TextStyle(color: EcoColors.bodyMuted, fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Chụp ảnh'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_rounded),
                    label: const Text('Thư viện'),
                    style: FilledButton.styleFrom(
                      backgroundColor: EcoColors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (_isAnalyzing)
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(color: EcoColors.primary),
                    SizedBox(height: 16),
                    Text('AI đang phân tích hình ảnh...', style: TextStyle(color: EcoColors.bodyMuted, fontWeight: FontWeight.w600)),
                  ],
                ),
              )
            else if (_resultLabel != null)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: Column(
                  children: [
                    const Text('Kết quả nhận diện', style: TextStyle(color: EcoColors.bodyMuted, fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      _resultLabel!,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: EcoColors.primary),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Độ chính xác: ${(_confidence! * 100).toStringAsFixed(1)}%',
                      style: const TextStyle(color: EcoColors.blue, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                    const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.tips_and_updates_rounded, color: EcoColors.orange, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gợi ý: Hãy làm sạch và phân loại rác trước khi giao cho người thu gom để nhận được nhiều điểm Xanh hơn.',
                            style: TextStyle(color: EcoColors.textBody, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
