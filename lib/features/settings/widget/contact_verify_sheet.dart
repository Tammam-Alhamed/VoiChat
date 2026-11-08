import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../state/account_setting_provider.dart';

/// Account settings sheet to change the phone number or add an email.
/// Step 1: type the new value → "Send code". Step 2: type the code that
/// arrived (WhatsApp for phone, inbox for email) → "Verify". Same look as
/// the previous edit sheet.
class ContactVerifySheet extends StatefulWidget {
  final bool isPhone;
  final String? initialValue;

  const ContactVerifySheet({
    super.key,
    required this.isPhone,
    this.initialValue,
  });

  static Future<void> show(
    BuildContext context, {
    required bool isPhone,
    String? initialValue,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          ContactVerifySheet(isPhone: isPhone, initialValue: initialValue),
    );
  }

  @override
  State<ContactVerifySheet> createState() => _ContactVerifySheetState();
}

class _ContactVerifySheetState extends State<ContactVerifySheet> {
  static const _resendSeconds = 60;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueCtrl =
      TextEditingController(text: widget.initialValue ?? '');
  final TextEditingController _codeCtrl = TextEditingController();

  bool _codeSent = false;
  String _sentTo = '';
  int _resendIn = 0;
  Timer? _timer;

  @override
  void dispose() {
    _timer?.cancel();
    _valueCtrl.dispose();
    _codeCtrl.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    setState(() => _resendIn = _resendSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendIn -= 1);
      if (_resendIn <= 0) t.cancel();
    });
  }

  Future<void> _sendCode() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final value = _valueCtrl.text.trim();
    final ok = await context.read<AccountSettingProvider>().sendContactCode(
      isPhone: widget.isPhone,
      value: value,
    );
    if (!ok || !mounted) return;
    setState(() {
      _codeSent = true;
      _sentTo = value;
      _codeCtrl.clear();
    });
    _startResendTimer();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length < 4) return;
    final ok = await context.read<AccountSettingProvider>().verifyContactCode(
      context: context,
      isPhone: widget.isPhone,
      value: _sentTo,
      otp: code,
    );
    if (ok && mounted) Navigator.pop(context);
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 16),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFBBBBBB)),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFF7247EF)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPhone = widget.isPhone;
    final loading = context.watch<AccountSettingProvider>().isUpdating;

    return Container(
      padding: EdgeInsets.only(
        left: 22,
        right: 22,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(15),
          topRight: Radius.circular(15),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Text(
              isPhone ? "update_phone_number".tr : 'Add email',
              style: const TextStyle(
                fontSize: 20,
                fontFamily: 'Open Sans',
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _codeSent
                  ? (isPhone
                        ? 'Enter the code we sent on WhatsApp to $_sentTo'
                        : 'Enter the code we sent to $_sentTo')
                  : (isPhone
                        ? "We'll send a code on WhatsApp to confirm your new number."
                        : "We'll send a code to confirm this email. Once added, it can't be changed."),
              style: const TextStyle(
                fontSize: 14,
                fontFamily: 'Open Sans',
                color: Color(0xFF7A7A7A),
              ),
            ),
            const SizedBox(height: 25),
            TextFormField(
              controller: _valueCtrl,
              enabled: !_codeSent,
              keyboardType:
                  isPhone ? TextInputType.phone : TextInputType.emailAddress,
              decoration: _decoration(
                isPhone ? "phone_hint_example".tr : "email_hint_example".tr,
              ),
              validator: (value) {
                final v = value?.trim() ?? '';
                if (v.isEmpty) return "field_cannot_be_empty".tr;
                if (!isPhone && !GetUtils.isEmail(v)) {
                  return "enter_valid_email_address".tr;
                }
                if (isPhone && !RegExp(r'^\+?[1-9]\d{6,14}$').hasMatch(v)) {
                  return 'Enter the number with country code, e.g. +963…';
                }
                return null;
              },
            ),
            if (_codeSent) ...[
              const SizedBox(height: 14),
              TextField(
                controller: _codeCtrl,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _verify(),
                style: const TextStyle(fontSize: 20, letterSpacing: 6),
                decoration: _decoration('Code'),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  TextButton(
                    onPressed: loading
                        ? null
                        : () => setState(() {
                            _codeSent = false;
                            _timer?.cancel();
                            _resendIn = 0;
                          }),
                    child: Text(
                      isPhone ? 'Change number' : 'Change email',
                      style: const TextStyle(color: Color(0xFF7A7A7A)),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: (loading || _resendIn > 0) ? null : _sendCode,
                    child: Text(
                      _resendIn > 0 ? 'Resend in ${_resendIn}s' : 'Resend code',
                      style: TextStyle(
                        color: _resendIn > 0
                            ? const Color(0xFFBBBBBB)
                            : const Color(0xFF7247EF),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            _gradientButton(
              label: _codeSent ? 'Verify' : 'Send code',
              loading: loading,
              enabled: !_codeSent || _codeCtrl.text.trim().length >= 4,
              onPressed: _codeSent ? _verify : _sendCode,
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _gradientButton({
    required String label,
    required bool loading,
    required bool enabled,
    required VoidCallback onPressed,
  }) {
    final active = enabled && !loading;
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: active ? onPressed : null,
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.zero,
          backgroundColor: Colors.transparent,
          disabledBackgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: active
                  ? const [Color(0xFF7247EF), Color(0xFFB862E1)]
                  : [Colors.grey.shade400, Colors.grey.shade300],
            ),
            borderRadius: const BorderRadius.all(Radius.circular(50)),
          ),
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontSize: 20,
                      fontFamily: 'Open Sans',
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
