import 'package:flutter/material.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class ApplyCodeSheet extends StatefulWidget {
  const ApplyCodeSheet({super.key});

  @override
  State<ApplyCodeSheet> createState() => _ApplyCodeSheetState();
}

class _ApplyCodeSheetState extends State<ApplyCodeSheet> {
  final _controller = TextEditingController();
  bool _isLoading = false;

  void _apply() async {
    final code = _controller.text.trim().toUpperCase();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // Simulate API

    if (mounted) {
      if (code == 'ECO2026' || code == 'HUST') {
        showEcoSnackBar(context, 'Chúc mừng! Bạn đã nhận được 100 điểm xanh.', icon: Icons.celebration_rounded);
        Navigator.pop(context);
      } else {
        showEcoSnackBar(context, 'Mã không tồn tại hoặc đã hết hạn.', icon: Icons.error_outline);
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
          const SizedBox(height: 20),
          const Text('Nhập mã nhận thưởng', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          const Text('Nhập mã giới thiệu hoặc mã ưu đãi để nhận thêm điểm xanh vào ví.', textAlign: TextAlign.center, style: TextStyle(color: EcoColors.bodyMuted, fontSize: 13)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'VD: ECO2026',
              filled: true,
              fillColor: EcoColors.inputFill,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _isLoading ? null : _apply,
            style: FilledButton.styleFrom(
              backgroundColor: EcoColors.primary,
              padding: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}
