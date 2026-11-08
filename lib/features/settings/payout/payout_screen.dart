import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/helpers/wallet_helper.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/utils/api_status.dart';
import '../../../app/di/injection_container.dart';
import '../../../core/themes/app_dark_colors.dart';
import 'payout_history.dart';
import 'start_payout_agent_sheet.dart';
import 'start_payout_bank_sheet.dart';

import '../../session/presentation/controllers/session_controller.dart';

class PayoutScreen extends StatefulWidget {
  const PayoutScreen({super.key});

  @override
  State<PayoutScreen> createState() => _PayoutScreenState();
}

class _PayoutScreenState extends State<PayoutScreen> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  final TextEditingController _amountController = TextEditingController();

  // 0 = Bank, 1 = Agent
  int _selectedPayoutMethod = 0;

  bool _isLoadingBalance = true;
  double _balance = 0;

  @override
  void initState() {
    super.initState();
    // Show the cached balance immediately (no blank flash), then refresh
    // from the server so this screen always reflects the real, current
    // wallet_balance rather than a stale/local value.
    final cached = Get.find<SessionController>().session?.user?.walletBalance;
    if (cached != null) {
      _balance = double.tryParse(cached) ?? 0;
    }
    _fetchWallet();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _fetchWallet() async {
    setState(() => _isLoadingBalance = true);
    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/wallet',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final raw = body['data']?['wallet_balance']?.toString();
        if (raw != null) {
          _balance = double.tryParse(raw) ?? _balance;
          // Keep the app-wide cached balance in sync too.
          if (mounted) {
            Get.find<SessionController>().session?.user?.walletBalance = raw;
          }
        }
      }
    } catch (_) {
      // Best-effort refresh; keep showing the cached value on failure.
    } finally {
      if (mounted) setState(() => _isLoadingBalance = false);
    }
  }

  Future<void> _onWithdrawalTap() async {
    final amount = double.tryParse(_amountController.text.trim());

    if (amount == null || amount <= 0) {
      ToastHelper.showErrorToast(message: 'Enter a valid withdrawal amount');
      return;
    }
    if (amount > _balance) {
      ToastHelper.showErrorToast(message: 'Amount exceeds available balance');
      return;
    }

    bool? completed;
    if (_selectedPayoutMethod == 0) {
      completed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => BankTransferBottomSheet(amount: amount),
      );
    } else {
      completed = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AgentPayoutBottomSheet(amount: amount),
      );
    }

    if (completed == true) {
      _amountController.clear();
      _fetchWallet();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          children: [
            // 1. الشريط العلوي (App Bar)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.maybePop(context),
                        borderRadius: BorderRadius.circular(20),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: context.shellTextPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Payout',
                        style: TextStyle(
                          color: context.shellTextPrimary,
                          fontSize: 18,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.02,
                        ),
                      ),
                    ],
                  ),
                  // أيقونة التاريخ أو السجلات (History)
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      Get.to(const PayoutHistoryScreen());
                    },
                    child: Icon(
                      Icons.history,
                      color: context.shellTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // 2. المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                  ), // مسافة جانبية للتركيز
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.center, // توسيط المحتوى
                    children: [
                      const SizedBox(height: 40),

                      // عنوان الرصيد المتاح
                      Text(
                        'Available Balance',
                        style: TextStyle(
                          color: context.shellTextPrimary,
                          fontSize: 22,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.02,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // الرصيد الإجمالي — رقم صحيح دائماً بدون فواصل
                      // (نفس تنسيق الواليت بكل شاشات التطبيق).
                      _isLoadingBalance
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  WalletHelper.format(_balance),
                                  style: TextStyle(
                                    color: context.shellTextPrimary,
                                    fontSize: 32,
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.02,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(
                                  Icons.diamond_outlined,
                                  size: 22,
                                  color: Colors.blueAccent,
                                ),
                              ],
                            ),
                      const SizedBox(height: 40),

                      // حقل إدخال المبلغ المراد سحبه (Amount)
                      Container(
                        width: double.infinity,
                        height: 50,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.themedColor(
                            const Color(0xFFF5F5F5),
                            AppDarkColors.card,
                          ),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: context.themedColor(
                              const Color(0xFFEDEDED),
                              AppDarkColors.border,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Amount',
                              style: TextStyle(
                                color: context.shellTextSecondary,
                                fontSize: 14,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(
                                  color: context.shellTextPrimary,
                                  fontSize: 16,
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.w700,
                                ),
                                decoration: const InputDecoration(
                                  hintText: '0',
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // خيارات السحب (Bank Transfer / Agent Payout)
                      _buildPayoutMethodOption(
                        title: 'Bank Transfer',
                        index: 0,
                        hasSettingsIcon:
                            true, // الخيار البنكي قد يحتاج إعدادات إضافية
                      ),
                      const SizedBox(height: 24),
                      _buildPayoutMethodOption(
                        title: 'Agent Payout',
                        index: 1,
                        hasSettingsIcon: false,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. زر السحب (Withdrawal Button) في أسفل الشاشة
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: InkWell(
                onTap: _onWithdrawalTap,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: double.infinity, // يأخذ عرض الشاشة بالكامل باحترافية
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF7247EF),
                        Color(0xFFB862E1),
                      ], // تدرج لون البنفسجي للوردي
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    'Withdrawal',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20, // حجم مناسب للزر
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.02,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ودجت لبرمجة خيارات طرق السحب (Radio Button System)
  // ==========================================
  Widget _buildPayoutMethodOption({
    required String title,
    required int index,
    required bool hasSettingsIcon,
  }) {
    bool isSelected = _selectedPayoutMethod == index;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          width: 1,
          color: context.themedColor(Colors.black12, AppDarkColors.border),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPayoutMethod = index;
          });
        },
        child: Row(
          children: [
            // الدائرة الخاصة بالاختيار (Radio Icon)
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xFF7B13E2) : Colors.grey,
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(3), // مسافة للون الداخلي
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF7B13E2),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),

            // اسم طريقة الدفع
            Text(
              title,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 18,
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w500,
                letterSpacing: 0.02,
              ),
            ),

            const Spacer(),

            // أيقونة إعدادات (إذا لزم الأمر، كما في تصميمك بجانب Bank Transfer)
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
