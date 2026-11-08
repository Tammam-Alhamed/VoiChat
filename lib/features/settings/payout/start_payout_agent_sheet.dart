import 'package:flutter/material.dart';

import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/utils/api_status.dart';
import '../../../app/di/injection_container.dart';

class AgentPayoutBottomSheet extends StatefulWidget {
  final double amount;

  const AgentPayoutBottomSheet({super.key, required this.amount});

  @override
  State<AgentPayoutBottomSheet> createState() => _AgentPayoutBottomSheetState();
}

class _AgentPayoutBottomSheetState extends State<AgentPayoutBottomSheet> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  // للتحكم في حقل الملاحظة الاختياري
  final TextEditingController _noteController = TextEditingController();

  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.postHelper(
        target: '/v1/wallet/withdraw',
        token: token,
        data: {
          'amount': widget.amount,
          'paymentMethod': 'agent',
          'paymentDetails': {
            'agent': 'Sally',
            'agencyId': '30154212',
            'note': _noteController.text.trim(),
          },
        },
      );

      if (response is Failure) {
        final message = response.errorResponse?.toString().isNotEmpty == true
            ? response.errorResponse.toString()
            : 'Failed to submit withdrawal request';
        ToastHelper.showErrorToast(message: message);
        return;
      }

      if (mounted) {
        Navigator.pop(context, true);
        ToastHelper.showSuccessToast(
          message: 'Payout request sent to Agent successfully!',
        );
      }
    } catch (_) {
      ToastHelper.showErrorToast(
        message: 'Failed to submit withdrawal request',
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // الحصول على مساحة الكيبورد لرفع الواجهة عند الكتابة
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.8, // 80% من ارتفاع الشاشة
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // مؤشر السحب (Drag Handle)
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // 1. الشريط العلوي (App Bar)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                InkWell(
                  onTap: () => Navigator.maybePop(context),
                  borderRadius: BorderRadius.circular(20),
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(Icons.close, color: Colors.black, size: 24),
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Agent Payout',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),

          // خط فاصل للجمالية
          Container(height: 1, color: const Color(0xFFEDEDED)),

          // 2. المحتوى القابل للتمرير
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 32,
                bottom: bottomInset + 24, // لتجنب تغطية الكيبورد للحقل
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // بطاقة معلومات الوكيل (Read Only)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 20,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildAgentInfoRow('Agent', 'Sally'),
                        const SizedBox(height: 12),
                        _buildAgentInfoRow('Agency ID', '30154212'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // حقل إضافة ملاحظة (Add a note - optional)
                  Container(
                    width: double.infinity,
                    height: 150,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextField(
                      controller: _noteController,
                      maxLines: null,
                      keyboardType: TextInputType.multiline,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 18,
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Add a note (optional)',
                        hintStyle: TextStyle(
                          color: Color(0xFF7A7A7A),
                          fontSize: 18,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  // مسافة مرنة قبل الزر
                  SizedBox(height: screenHeight * 0.08),

                  // 3. زر "Apply" التفاعلي
                  InkWell(
                    onTap: _isSubmitting ? null : _submit,
                    borderRadius: BorderRadius.circular(50),
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(50),
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                        ),
                      ),
                      alignment: Alignment.center,
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Apply',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.02,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. النص التحذيري السفلي
                  const Text(
                    'Withdrawals are processed weekly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black87,
                      fontSize: 12,
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.01,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ودجت لإنشاء سطر معلومات الوكيل
  Widget _buildAgentInfoRow(String label, String value) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w400,
              letterSpacing: 0.02,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.02,
            ),
          ),
        ],
      ),
    );
  }
}
