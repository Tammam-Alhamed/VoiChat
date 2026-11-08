import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/helpers/store_helper.dart';
import '../../../core/helpers/wallet_helper.dart';
import '../../../core/network/service_helper.dart';
import '../../../core/utils/api_status.dart';
import '../../../core/widgets/app_state_view.dart';
import '../../../core/themes/app_dark_colors.dart';
import '../../../app/di/injection_container.dart';

class _WithdrawalEntry {
  final String id;
  final double amount;
  final String paymentMethod;
  final String status;
  final DateTime createdAt;

  _WithdrawalEntry({
    required this.id,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory _WithdrawalEntry.fromJson(Map<String, dynamic> json) {
    return _WithdrawalEntry(
      id: json['id']?.toString() ?? '',
      amount: double.tryParse(json['amount']?.toString() ?? '') ?? 0,
      paymentMethod: json['payment_method']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending',
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class PayoutHistoryScreen extends StatefulWidget {
  const PayoutHistoryScreen({super.key});

  @override
  State<PayoutHistoryScreen> createState() => _PayoutHistoryScreenState();
}

class _PayoutHistoryScreenState extends State<PayoutHistoryScreen> {
  final ServiceHelper _serviceHelper = sl<ServiceHelper>();
  final StoreHelper _storeHelper = sl<StoreHelper>();

  bool _isLoading = true;
  bool _hasError = false;
  List<_WithdrawalEntry> _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = _storeHelper.getAccessToken();
      final response = await _serviceHelper.getHelper(
        target: '/v1/wallet/withdrawals?page=1&limit=50',
        token: token,
      );

      if (response is Success) {
        final Map<String, dynamic> body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data as Map<String, dynamic>;
        final List<dynamic> rows = body['data']?['data'] ?? [];
        _entries = rows
            .map((e) => _WithdrawalEntry.fromJson(e as Map<String, dynamic>))
            .toList();
        setState(() => _isLoading = false);
      } else {
        setState(() {
          _isLoading = false;
          _hasError = true;
        });
      }
    } catch (_) {
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A very light grey background makes the white cards pop nicely
      backgroundColor: context.themedColor(
        const Color(0xFFF8F9FA),
        AppDarkColors.background,
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: context.shellTextPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Payout History',
          style: TextStyle(
            color: context.shellTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_hasError) {
      return AppStateView.error(onRetry: _load);
    }
    if (_entries.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * .7,
              child: AppStateView.empty(
                icon: Icons.account_balance_wallet_outlined,
                title: 'No withdrawals yet',
                message: 'Pull down to refresh',
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _entries.length,
        itemBuilder: (context, index) => _buildTransactionCard(_entries[index]),
      ),
    );
  }

  // ==========================================
  // Modern Transaction Card Widget
  // ==========================================
  Widget _buildTransactionCard(_WithdrawalEntry entry) {
    // Determine colors dynamically from the real backend status.
    Color statusBgColor;
    Color statusTextColor;
    String statusLabel;

    switch (entry.status) {
      case 'completed':
        statusBgColor = const Color(0xFFE8F5E9); // Light Green
        statusTextColor = const Color(0xFF2E7D32); // Dark Green
        statusLabel = 'Completed';
        break;
      case 'approved':
        statusBgColor = const Color(0xFFE3F2FD); // Light Blue
        statusTextColor = const Color(0xFF1565C0); // Dark Blue
        statusLabel = 'Approved';
        break;
      case 'rejected':
        statusBgColor = const Color(0xFFFFEBEE); // Light Red
        statusTextColor = const Color(0xFFC62828); // Dark Red
        statusLabel = 'Rejected';
        break;
      case 'pending':
      default:
        statusBgColor = const Color(0xFFFFF3E0); // Light Orange
        statusTextColor = const Color(0xFFE65100); // Dark Orange
        statusLabel = 'Pending';
    }

    final isBank = entry.paymentMethod == 'bank';
    final methodLabel = isBank ? 'Bank Account' : 'Agent Payout';
    final methodIcon = isBank
        ? Icons.account_balance_outlined
        : Icons.support_agent_outlined;
    final reference = entry.id.length >= 8
        ? '#${entry.id.substring(0, 8).toUpperCase()}'
        : '#${entry.id.toUpperCase()}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Modern rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04), // Very soft shadow
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon, Method, and Amount
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Circular Icon Background
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4F8), // Soft blue-grey
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  methodIcon,
                  color: const Color(0xFF4A5568),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              // Method & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      methodLabel,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM d, yyyy').format(entry.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Amount
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    WalletHelper.format(entry.amount),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.diamond_outlined,
                    size: 15,
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),

          // Bottom Row: Reference Number & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reference',
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reference,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              // Status Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(20), // Pill shape
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: statusTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
