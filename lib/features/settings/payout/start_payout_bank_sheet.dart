import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/country_helper.dart';
// Note: Ensure you have your CountryFlag package imported if you are using it.
// import 'package:country_flag/country_flag.dart';

import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/toast_helper.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/utils/api_status.dart';
import '../../../app/di/injection_container.dart';

// (Truncated list for brevity - keep your full _kCountries list here)
List<Country> _kCountries = CountryHelper.countries;

// ─────────────────────────────────────────────────────────────
// Bottom sheet — Main Bank Transfer Form
// ─────────────────────────────────────────────────────────────
class BankTransferBottomSheet extends StatefulWidget {
  final double amount;

  const BankTransferBottomSheet({super.key, required this.amount});

  @override
  State<BankTransferBottomSheet> createState() =>
      _BankTransferBottomSheetState();
}

class _BankTransferBottomSheetState extends State<BankTransferBottomSheet> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ibanController = TextEditingController();

  // Replaced controller with a strong typed state variable
  Country? _selectedCountry;

  bool _isButtonActive = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateFields);
    _ibanController.addListener(_validateFields);
  }

  void _validateFields() {
    final bool isFilled =
        _nameController.text.trim().isNotEmpty &&
        _ibanController.text.trim().isNotEmpty &&
        _selectedCountry != null;

    if (isFilled != _isButtonActive) {
      setState(() {
        _isButtonActive = isFilled;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ibanController.dispose();
    super.dispose();
  }

  // Method to open the Country Picker
  Future<void> _openCountryPicker() async {
    // Unfocus keyboard before opening sheet
    FocusScope.of(context).unfocus();

    final Country? result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CountryPickerSheet(selected: _selectedCountry),
    );

    if (result != null) {
      setState(() {
        _selectedCountry = result;
      });
      _validateFields();
    }
  }

  Future<void> _submit() async {
    if (!_isButtonActive || _isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.postHelper(
        target: '/v1/wallet/withdraw',
        token: token,
        data: {
          'amount': widget.amount,
          'paymentMethod': 'bank',
          'paymentDetails': {
            'fullName': _nameController.text.trim(),
            'country': _selectedCountry?.name,
            'iban': _ibanController.text.trim(),
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
          message: 'Withdrawal request submitted successfully',
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bank Transfer',
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.maybePop(context),
                  icon: const Icon(Icons.close_rounded, color: Colors.black54),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.grey.shade200),

          // Scrollable Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildInputField(
                    hint: 'Full Name',
                    controller: _nameController,
                    icon: Icons.person_outline_rounded,
                  ),
                  const SizedBox(height: 20),

                  // Interactive Country Selector
                  GestureDetector(
                    onTap: _openCountryPicker,
                    child: Container(
                      height: 60,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.public,
                            color: Colors.grey.shade400,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _selectedCountry?.name ?? 'Select Country',
                              style: TextStyle(
                                color: _selectedCountry != null
                                    ? Colors.black87
                                    : Colors.grey.shade500,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    hint: 'IBAN',
                    controller: _ibanController,
                    icon: Icons.account_balance_wallet_outlined,
                  ),

                  SizedBox(height: screenHeight * 0.1),

                  // Apply Button
                  InkWell(
                    onTap: _isButtonActive && !_isSubmitting ? _submit : null,
                    borderRadius: BorderRadius.circular(16),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: _isButtonActive
                            ? const LinearGradient(
                                colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                              )
                            : null,
                        color: _isButtonActive ? null : Colors.grey.shade300,
                        boxShadow: _isButtonActive
                            ? [
                                BoxShadow(
                                  color: const Color(
                                    0xFF7247EF,
                                  ).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : [],
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
                          : Text(
                              'Apply',
                              style: TextStyle(
                                color: _isButtonActive
                                    ? Colors.white
                                    : Colors.grey.shade500,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Text(
                    'Funds will be transferred within 1–3 business days',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String hint,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Container(
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: controller,
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey.shade400, size: 22),
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 16,
            fontWeight: FontWeight.w400,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Bottom sheet — Country Picker
// ─────────────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final Country? selected;
  const _CountryPickerSheet({this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<Country> _filtered = _kCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  void _onSearch() {
    final q = _search.text.trim().toLowerCase();
    setState(() {
      _filtered = q.isEmpty
          ? _kCountries
          : _kCountries
                .where(
                  (c) => c.name.toLowerCase().contains(q) || c.dial.contains(q),
                )
                .toList();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          const Text(
            'Select Country',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: TextField(
                controller: _search,
                style: const TextStyle(fontSize: 16),
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                  hintText: 'Search country',
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // List of Countries
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final country = _filtered[i];
                final isSelected = widget.selected?.code == country.code;

                return ListTile(
                  onTap: () => Navigator.pop(context, country),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: isSelected
                      ? const Color(0xFF7247EF).withOpacity(0.08)
                      : null,
                  leading: ClipOval(
                    child: SizedBox(
                      width: 32,
                      height: 32,
                      child: CountryFlag.fromCountryCode(
                        country.code,
                        theme: ImageTheme(width: 32, height: 32),
                      ),
                    ),
                  ),
                  title: Text(
                    country.name,
                    style: TextStyle(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isSelected
                          ? const Color(0xFF7247EF)
                          : Colors.black87,
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected) ...[
                        const SizedBox(width: 12),
                        const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF7247EF),
                        ),
                      ] else ...[
                        const SizedBox(
                          width: 36,
                        ), // Keep alignment when no checkmark
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
