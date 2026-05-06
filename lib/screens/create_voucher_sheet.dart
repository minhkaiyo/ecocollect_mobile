import 'package:flutter/material.dart';
import '../repositories/voucher_repository.dart';
import '../theme/eco_colors.dart';
import '../ui/app_feedback.dart';

class CreateVoucherSheet extends StatefulWidget {
  final String buyerUid;

  const CreateVoucherSheet({super.key, required this.buyerUid});

  @override
  State<CreateVoucherSheet> createState() => _CreateVoucherSheetState();
}

class _CreateVoucherSheetState extends State<CreateVoucherSheet> {
  final _voucherRepo = VoucherRepository();
  
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _minKgController = TextEditingController();
  final _sellerIdController = TextEditingController();
  
  bool _isLoading = false;

  Future<void> _create() async {
    if (_titleController.text.isEmpty || _minKgController.text.isEmpty) {
      showEcoSnackBar(context, 'Vui lòng điền tên và mốc Kg.', icon: Icons.warning_rounded);
      return;
    }

    setState(() => _isLoading = true);
    try {
      await _voucherRepo.createBuyerVoucher(
        uid: widget.buyerUid,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        targetSellerId: _sellerIdController.text.trim().isEmpty ? null : _sellerIdController.text.trim(),
        minKg: double.tryParse(_minKgController.text.trim()) ?? 0.0,
        expiresAt: DateTime.now().add(const Duration(days: 30)),
      );
      
      if (mounted) {
        Navigator.pop(context);
        showEcoSnackBar(context, 'Tạo voucher thành công!', icon: Icons.check_circle_rounded);
      }
    } catch (e) {
      if (mounted) {
        showEcoSnackBar(context, 'Lỗi: $e', icon: Icons.error_outline);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _minKgController.dispose();
    _sellerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: EcoColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tạo Voucher Thưởng', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: EcoColors.textBody)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: EcoColors.iconMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tên Voucher (VD: Tặng 50k tiền mặt)',
                  filled: true, fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  filled: true, fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _minKgController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Mốc Kg tối thiểu để nhận',
                  suffixText: 'kg',
                  filled: true, fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _sellerIdController,
                decoration: InputDecoration(
                  labelText: 'Mã Seller (để trống nếu dành cho tất cả)',
                  filled: true, fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _create,
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('TẠO VOUCHER', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
