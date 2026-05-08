import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../models/voucher.dart';
import '../../../repositories/voucher_repository.dart';
import '../../../theme/eco_colors.dart';
import '../../../ui/app_feedback.dart';

class AddVoucherSheet extends StatefulWidget {
  const AddVoucherSheet({super.key});

  @override
  State<AddVoucherSheet> createState() => _AddVoucherSheetState();
}

class _AddVoucherSheetState extends State<AddVoucherSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _pointsController = TextEditingController();
  String _category = 'food';
  DateTime _expiry = DateTime.now().add(const Duration(days: 30));
  bool _isSubmitting = false;

  final Map<String, String> _categories = {
    'food': 'Ăn uống',
    'shopping': 'Mua sắm',
    'transport': 'Di chuyển',
    'points': 'Điểm xanh',
    'recycle': 'Tái chế',
  };

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      final voucher = Voucher(
        id: '', // Firestore will generate
        title: _titleController.text,
        description: _descController.text,
        pointsCost: int.parse(_pointsController.text),
        category: _category,
        isActive: true,
        createdBy: uid,
        expiresAt: _expiry,
        imageUrl: 'assets/images/vouchers/eco_default.jpg', // Default for new vouchers
      );

      await VoucherRepository().addVoucher(voucher);
      if (mounted) {
        showEcoSnackBar(context, 'Đã đăng voucher mới thành công!', icon: Icons.check_circle_rounded);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showEcoSnackBar(context, 'Lỗi: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(22, 16, 22, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 42, height: 5, decoration: BoxDecoration(color: EcoColors.sheetHandle, borderRadius: BorderRadius.circular(999)))),
              const SizedBox(height: 18),
              const Text('Đăng Voucher Mới', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tên Voucher',
                  hintText: 'VD: Giảm 20k tại Highlands',
                  filled: true,
                  fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
                validator: (v) => v!.isEmpty ? 'Vui lòng nhập tên' : null,
              ),
              const SizedBox(height: 12),
              
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Mô tả chi tiết',
                  hintText: 'Điều kiện áp dụng...',
                  filled: true,
                  fillColor: EcoColors.inputFill,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _pointsController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Điểm đổi',
                        filled: true,
                        fillColor: EcoColors.inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      validator: (v) => v!.isEmpty ? 'Nhập điểm' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _category,
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        filled: true,
                        fillColor: EcoColors.inputFill,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                      items: _categories.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setState(() => _category = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ListTile(
                title: const Text('Ngày hết hạn', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('${_expiry.day}/${_expiry.month}/${_expiry.year}'),
                trailing: const Icon(Icons.calendar_today_rounded, color: EcoColors.primary),
                tileColor: EcoColors.surfaceMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _expiry,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) setState(() => _expiry = date);
                },
              ),
              
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _submit,
                style: FilledButton.styleFrom(
                  backgroundColor: EcoColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSubmitting 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('XÁC NHẬN ĐĂNG', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
