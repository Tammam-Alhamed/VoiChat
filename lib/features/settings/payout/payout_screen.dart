import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  static final RegExp _thousandsPattern = RegExp(r'\B(?=(\d{3})+(?!\d))');
  static final RegExp _amountPattern = RegExp(r'^\d*\.?\d*$');
  static final RegExp _displayAmountPattern = RegExp(
    r'^(-?)(\d+)(?:\.(\d+))?$',
  );

  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  final TextEditingController _amountController = TextEditingController();

  // 0 = Bank, 1 = Agent
  int _selectedPayoutMethod = 0;

  bool _isLoadingBalance = true;
  double _balance = 0;
  String _balanceRaw = '0';

  String _formatPayoutNumber(String? value) {
    final match = _displayAmountPattern.firstMatch(value?.trim() ?? '');
    if (match == null) return '0.00';

    final whole = match.group(2)!.replaceAllMapped(
      _thousandsPattern,
      (_) => ',',
    );
    final fraction = (match.group(3) ?? '').padRight(2, '0');
    return '${match.group(1)}$whole.$fraction';
  }

  TextEditingValue _formatAmountInput(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (!_amountPattern.hasMatch(raw)) return oldValue;

    final dotIndex = raw.indexOf('.');
    final whole = dotIndex == -1 ? raw : raw.substring(0, dotIndex);
    final fraction = dotIndex == -1 ? '' : raw.substring(dotIndex);
    final formatted =
        whole.replaceAllMapped(_thousandsPattern, (_) => ',') + fraction;

    int formattedOffset(int offset) {
      final rawOffset = newValue.text
          .substring(0, offset.clamp(0, newValue.text.length))
          .replaceAll(',', '')
          .length;
      if (rawOffset == 0) return 0;
      var seen = 0;
      for (var i = 0; i < formatted.length; i++) {
        if (formatted[i] != ',') seen++;
        if (seen == rawOffset) {
          return i + 1;
        }
      }
      return formatted.length;
    }

    final selection = newValue.selection;
    return TextEditingValue(
      text: formatted,
      selection: selection.isValid
          ? TextSelection(
              baseOffset: formattedOffset(selection.baseOffset),
              extentOffset: formattedOffset(selection.extentOffset),
            )
          : TextSelection.collapsed(offset: formatted.length),
    );
  }

  @override
  void initState() {
    super.initState();
    // Show the cached balance immediately (no blank flash), then refresh
    // from the server so this screen always reflects the real, current
    // wallet_balance rather than a stale/local value.
    final cached = Get.find<SessionController>().session?.user?.walletBalance;
    if (cached != null) {
      _balance = double.tryParse(cached) ?? 0;
      _balanceRaw = cached;
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
          final parsed = double.tryParse(raw);
          if (parsed != null) {
            _balance = parsed;
            _balanceRaw = raw;
          }
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
    final amount = double.tryParse(
      _amountController.text.replaceAll(',', '').trim(),
    );

    if (amount == null || amount <= 0) {
      ToastHelper.showErrorToast(message: 'payout_invalid_amount'.tr);
      return;
    }
    if (amount > _balance) {
      ToastHelper.showErrorToast(message: 'payout_amount_exceeds_balance'.tr);
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
              padding: const EdgeInsetsDirectional.only(
                end: 16,
                top: 4,
                bottom: 4,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: IconButton(
                          onPressed: () => Navigator.maybePop(context),
                          icon: Icon(
                            Icons.arrow_back_ios_new,
                            color: context.shellTextPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
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
                    child: Icon(Icons.history, color: context.shellTextPrimary),
                  ),
                ],
              ),
            ),

            // 2. المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),

                      // عنوان الرصيد المتاح
                      Text(
                        'payout_available_balance'.tr,
                        style: TextStyle(
                          color: context.shellTextPrimary,
                          fontSize: 20,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.02,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Wallet balance and total earnings come from their
                      // existing, separate user fields.
                      _isLoadingBalance
                          ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Column(
                              children: [
                                SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${_formatPayoutNumber(_balanceRaw)} \$',
                                      style: TextStyle(
                                        color: context.shellTextPrimary,
                                        fontSize: 42,
                                        fontFamily: 'Roboto',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                SizedBox(
                                  width: double.infinity,
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          WalletHelper.format(
                                            Get.find<SessionController>()
                                                .session
                                                ?.user
                                                ?.totalEarnings,
                                          ).replaceAllMapped(
                                            _thousandsPattern,
                                            (_) => ',',
                                          ),
                                          style: TextStyle(
                                            color: context.shellTextPrimary,
                                            fontSize: 19,
                                            fontFamily: 'Roboto',
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          Icons.diamond_outlined,
                                          size: 20,
                                          color: context.shellTextPrimary,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                      const SizedBox(height: 34),

                      // حقل إدخال المبلغ المراد سحبه (Amount)
                      Container(
                        width: double.infinity,
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: context.themedColor(
                            const Color(0xFFF3F3F3),
                            AppDarkColors.card,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'payout_amount'.tr,
                              style: TextStyle(
                                color: context.shellTextSecondary,
                                fontSize: 15,
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: _amountController,
                                inputFormatters: [
                                  TextInputFormatter.withFunction(
                                    _formatAmountInput,
                                  ),
                                ],
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: TextStyle(
                                  color: context.shellTextPrimary,
                                  fontSize: 18,
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
                            Icon(
                              Icons.attach_money,
                              size: 20,
                              color: context.shellTextPrimary,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // خيارات السحب (Bank Transfer / Agent Payout)
                      _buildPayoutMethodOption(
                        title: 'payout_bank_transfer'.tr,
                        index: 0,
                      ),
                      const SizedBox(height: 14),
                      _buildPayoutMethodOption(
                        title: 'payout_agent_payout'.tr,
                        index: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 3. زر السحب (Withdrawal Button) في أسفل الشاشة
            Padding(
              padding: EdgeInsets.fromLTRB(
                24,
                16,
                24,
                MediaQuery.viewInsetsOf(context).bottom > 0 ? 16 : 58,
              ),
              child: InkWell(
                onTap: _onWithdrawalTap,
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  width: double.infinity, // يأخذ عرض الشاشة بالكامل باحترافية
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF6825F3),
                        Color(0xFFBA08E4),
                      ], // تدرج لون البنفسجي للوردي
                    ),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'payout_withdraw'.tr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 23,
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
  Widget _buildPayoutMethodOption({required String title, required int index}) {
    final isSelected = _selectedPayoutMethod == index;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        setState(() {
          _selectedPayoutMethod = index;
        });
      },
      child: Container(
        height: 54,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.themedColor(
              const Color(0xFFD9D9D9),
              AppDarkColors.border,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF8B12DF)
                      : const Color(0xFFA0A0A0),
                  width: 2,
                ),
              ),
              padding: const EdgeInsets.all(4),
              child: isSelected
                  ? Container(
                      decoration: const BoxDecoration(
                        color: Color(0xFF8B12DF),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: context.shellTextPrimary,
                  fontSize: 20,
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
