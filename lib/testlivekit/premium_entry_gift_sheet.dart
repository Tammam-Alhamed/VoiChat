import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shoeebapk/core/helpers/store_helper.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/core/utils/api_status.dart';
import 'package:shoeebapk/app/di/injection_container.dart';

import 'gifts_bottom_sheet.dart';

const _kPurple = Color(0xFF7B3BF5);
const _kSheetColor = Color(0xF21A1A1A);

/// Host picks the gift viewers must send to enter the Premium live.
/// Returns the chosen gift after "Continue", or null if dismissed.
Future<GiftItem?> showEntryGiftSheet(
  BuildContext context, {
  String? selectedGiftId,
}) {
  return showModalBottomSheet<GiftItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (_) => _EntryGiftSheet(initialGiftId: selectedGiftId),
  );
}

enum PremiumManageAction { changeGift, turnOff }

/// Shown to the host when Premium is already on.
Future<PremiumManageAction?> showPremiumManageSheet(
  BuildContext context, {
  required GiftItem? entryGift,
}) {
  return showModalBottomSheet<PremiumManageAction>(
    context: context,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.5),
    builder: (context) => Container(
      padding: EdgeInsets.fromLTRB(
        20,
        14,
        20,
        20 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: _kSheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _handle(),
          const SizedBox(height: 14),
          const PremiumBadge(fontSize: 13),
          const SizedBox(height: 14),
          const Text(
            'Your live is Premium',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Viewers send the entry gift to join.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
          if (entryGift != null) ...[
            const SizedBox(height: 16),
            EntryGiftTile(gift: entryGift),
          ],
          const SizedBox(height: 20),
          _primaryButton(
            label: 'Change entry gift',
            onTap: () => Navigator.pop(context, PremiumManageAction.changeGift),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: TextButton(
              onPressed: () =>
                  Navigator.pop(context, PremiumManageAction.turnOff),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5A6E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Turn off Premium',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _handle() => Container(
  width: 40,
  height: 4,
  decoration: BoxDecoration(
    color: Colors.white24,
    borderRadius: BorderRadius.circular(2),
  ),
);

Widget _primaryButton({
  required String label,
  required VoidCallback? onTap,
  bool loading = false,
}) {
  final enabled = onTap != null;
  return GestureDetector(
    onTap: loading ? null : onTap,
    child: AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: enabled ? 1 : 0.45,
      child: Container(
        width: double.infinity,
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF5530F7), Color(0xFFB25AEE)],
          ),
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.4,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    ),
  );
}

/// Small gold "PREMIUM" pill.
class PremiumBadge extends StatelessWidget {
  final double fontSize;
  const PremiumBadge({super.key, this.fontSize = 10});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: fontSize * 0.8,
        vertical: fontSize * 0.3,
      ),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFD86B), Color(0xFFF5A623)],
        ),
        borderRadius: BorderRadius.circular(fontSize * 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_rounded,
            size: fontSize + 3,
            color: const Color(0xFF5A3200),
          ),
          SizedBox(width: fontSize * 0.3),
          Text(
            'PREMIUM',
            style: TextStyle(
              color: const Color(0xFF5A3200),
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gift image + name + coin price, used on the sheets and the join screen.
class EntryGiftTile extends StatelessWidget {
  final GiftItem gift;
  final bool dark;
  const EntryGiftTile({super.key, required this.gift, this.dark = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPurple.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 52,
            height: 52,
            child: gift.imageUrl.isEmpty
                ? const Icon(Icons.card_giftcard, color: Colors.white54)
                : CachedNetworkImage(
                    imageUrl: gift.imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: (_, __, ___) =>
                        const Icon(Icons.card_giftcard, color: Colors.white54),
                  ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                gift.name,
                style: TextStyle(
                  color: dark ? Colors.white : const Color(0xFF14142B),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Image.asset('assets/icons/sm-coin.png', width: 16),
                  const SizedBox(width: 4),
                  Text(
                    gift.price.toInt().toString(),
                    style: const TextStyle(
                      color: Color(0xFFFFC23A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EntryGiftSheet extends StatefulWidget {
  final String? initialGiftId;
  const _EntryGiftSheet({this.initialGiftId});

  @override
  State<_EntryGiftSheet> createState() => _EntryGiftSheetState();
}

class _EntryGiftSheetState extends State<_EntryGiftSheet> {
  List<GiftItem> _gifts = [];
  bool _loading = true;
  bool _failed = false;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialGiftId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    final response = await sl<ServiceHelper>().getHelper(
      target: '/v1/gifts/with-gifts',
      token: sl<StoreHelper>().getAccessToken(),
    );
    final gifts = <GiftItem>[];
    if (response is Success) {
      try {
        final body = response.data is String
            ? jsonDecode(response.data as String)
            : response.data;
        if (body is Map && body['data'] is List) {
          for (final c
              in (body['data'] as List).whereType<Map<String, dynamic>>().map(
                GiftCategory.fromJson,
              )) {
            gifts.addAll(c.gifts);
          }
        }
      } catch (_) {}
    }
    // One list, cheapest first; drop duplicates across categories.
    final seen = <String>{};
    final unique =
        gifts.where((g) => g.id.isNotEmpty && seen.add(g.id)).toList()
          ..sort((a, b) => a.price.compareTo(b.price));
    if (!mounted) return;
    setState(() {
      _gifts = unique;
      _loading = false;
      _failed = response is! Success;
    });
  }

  GiftItem? get _selected {
    for (final g in _gifts) {
      if (g.id == _selectedId) return g;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.62,
      padding: const EdgeInsets.only(top: 12),
      decoration: const BoxDecoration(
        color: _kSheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      child: Column(
        children: [
          _handle(),
          const SizedBox(height: 14),
          const Text(
            'Select Entry Gift',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'Viewers send this gift to join your Premium live.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody()),
          Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            child: _primaryButton(
              label: 'Continue',
              onTap: _selected == null
                  ? null
                  : () => Navigator.pop(context, _selected),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _kPurple));
    }
    if (_gifts.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _failed ? "Couldn't load gifts" : 'No gifts available',
              style: const TextStyle(color: Colors.white70),
            ),
            if (_failed)
              TextButton(
                onPressed: _load,
                child: const Text('Retry', style: TextStyle(color: _kPurple)),
              ),
          ],
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.78,
      ),
      itemCount: _gifts.length,
      itemBuilder: (context, i) {
        final gift = _gifts[i];
        final selected = gift.id == _selectedId;
        return GestureDetector(
          onTap: () => setState(() => _selectedId = gift.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              color: selected
                  ? _kPurple.withOpacity(0.22)
                  : Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? _kPurple : Colors.transparent,
                width: 1.6,
              ),
            ),
            padding: const EdgeInsets.all(6),
            child: Column(
              children: [
                Expanded(
                  child: gift.imageUrl.isEmpty
                      ? const Icon(Icons.card_giftcard, color: Colors.white54)
                      : CachedNetworkImage(
                          imageUrl: gift.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const Icon(
                            Icons.card_giftcard,
                            color: Colors.white54,
                          ),
                        ),
                ),
                const SizedBox(height: 4),
                Text(
                  gift.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/icons/sm-coin.png', width: 11),
                    const SizedBox(width: 3),
                    Text(
                      gift.price.toInt().toString(),
                      style: const TextStyle(
                        color: Color(0xFFFFC23A),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Exposed for the join screen's button style.
Widget premiumPrimaryButton({
  required String label,
  required VoidCallback? onTap,
  bool loading = false,
}) => _primaryButton(label: label, onTap: onTap, loading: loading);
