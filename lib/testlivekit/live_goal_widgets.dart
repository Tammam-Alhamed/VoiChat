import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../core/helpers/toast_helper.dart';

/// Goal UI shared by the Go Live setup screen and the live room:
/// [showSetGoalDialog], [showCurrentGoalDialog], [GoalIcon] and
/// [GoalAchievedBanner].

/// "Set a Goal" card. Returns the chosen amount, or null if dismissed.
Future<int?> showSetGoalDialog(BuildContext context) {
  return showGeneralDialog<int>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Set a Goal',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => const _SetGoalDialog(),
    transitionBuilder: _dialogTransition,
  );
}

/// "Current Goal" card. Returns true when the user taps Cancel Goal.
Future<bool?> showCurrentGoalDialog(
  BuildContext context, {
  required int targetAmount,
  num? currentAmount,
  bool isCompleted = false,
}) {
  return showGeneralDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Current Goal',
    barrierColor: Colors.black26,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => _CurrentGoalDialog(
      amount: targetAmount,
      currentAmount: currentAmount,
      isCompleted: isCompleted,
    ),
    transitionBuilder: _dialogTransition,
  );
}

Widget _dialogTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutBack);
  return FadeTransition(
    opacity: animation,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.92, end: 1).animate(curved),
      child: child,
    ),
  );
}

/// "Goal Achieved!" celebration pill shown over the live room.
class GoalAchievedBanner extends StatelessWidget {
  final int targetAmount;
  const GoalAchievedBanner({super.key, required this.targetAmount});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5530F7), Color(0xFFB25AEE)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6A3BF5).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🎉', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Goal Achieved!',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${_formatCoins(targetAmount)} coins reached',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Goal dialogs
// ═══════════════════════════════════════════════════════════════════════════

const _kPurple = Color(0xFF6A3BF5);
const _kCardColor = Color(0xFFF8F6FD);
const _kTitleColor = Color(0xFF14142B);
const _kMutedColor = Color(0xFF6E6E80);

String _formatCoins(int value) => NumberFormat.decimalPattern().format(value);

/// Shared card shell: drag handle, close button, icon badge.
class _GoalCard extends StatelessWidget {
  final List<Widget> children;
  const _GoalCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Material(
              color: _kCardColor,
              borderRadius: BorderRadius.circular(26),
              clipBehavior: Clip.antiAlias,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 10, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD5D3DE),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: const BoxDecoration(
                            color: Color(0xFFEAE8F0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 22,
                            color: _kTitleColor,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: const BoxDecoration(
                        color: Color(0xFFEDE7FC),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const GoalIcon(color: _kPurple, size: 40),
                    ),
                    const SizedBox(height: 16),
                    ...children,
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SetGoalDialog extends StatefulWidget {
  const _SetGoalDialog();

  @override
  State<_SetGoalDialog> createState() => _SetGoalDialogState();
}

class _SetGoalDialogState extends State<_SetGoalDialog> {
  static const _presets = <int>[1000, 5000, 10000, 50000, 100000];
  static const _maxGoal = 100000000;

  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int? get _amount => int.tryParse(_controller.text.trim());

  String _presetLabel(int v) => v >= 1000 ? '${v ~/ 1000}K' : v.toString();

  void _save() {
    final amount = _amount;
    if (amount == null || amount <= 0) {
      ToastHelper.showErrorToast(message: 'Enter a goal amount');
      return;
    }
    if (amount > _maxGoal) {
      ToastHelper.showErrorToast(
        message: 'Goal can be at most ${_formatCoins(_maxGoal)} coins',
      );
      return;
    }
    Navigator.of(context).pop(amount);
  }

  @override
  Widget build(BuildContext context) {
    final amount = _amount;
    return _GoalCard(
      children: [
        const Text(
          'Set a Goal',
          style: TextStyle(
            color: _kTitleColor,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Set a gift goal to motivate your viewers\nduring the live stream.',
          textAlign: TextAlign.center,
          style: TextStyle(color: _kMutedColor, fontSize: 11, height: 1.4),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Text(
              'Goal Amount',
              style: TextStyle(
                color: _kTitleColor,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Image.asset('assets/icons/sm-coin.png', width: 24, height: 24),
            const SizedBox(width: 6),
            const Text(
              'Coins',
              style: TextStyle(color: _kMutedColor, fontSize: 15),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _controller,
          autofocus: false,
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(9),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _save(),
          style: const TextStyle(fontSize: 18, color: _kTitleColor),
          decoration: InputDecoration(
            hintText: 'e.g. 10000',
            hintStyle: const TextStyle(color: Color(0xFFB0AEBD)),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 16,
            ),
            suffixIcon: _controller.text.isEmpty
                ? null
                : IconButton(
                    onPressed: _controller.clear,
                    icon: const Icon(Icons.cancel, color: Color(0xFFA3A1AE)),
                  ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFB9A5F5),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _kPurple, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < _presets.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _presetChip(
                  _presetLabel(_presets[i]),
                  selected: amount == _presets[i],
                  onTap: () {
                    _controller.text = _presets[i].toString();
                    _controller.selection = TextSelection.collapsed(
                      offset: _controller.text.length,
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 26),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kPurple,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(27),
              ),
            ),
            child: const Text(
              'Save Goal',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  Widget _presetChip(
    String label, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE6DCFD) : const Color(0xFFEDECF2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _kPurple : const Color(0xFF55556A),
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CurrentGoalDialog extends StatelessWidget {
  final int amount;
  final num? currentAmount;
  final bool isCompleted;
  const _CurrentGoalDialog({
    required this.amount,
    this.currentAmount,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    final current = currentAmount;
    final progress = (current == null || amount <= 0)
        ? null
        : (current / amount).clamp(0.0, 1.0).toDouble();
    return _GoalCard(
      children: [
        Text(
          isCompleted ? 'Goal Achieved!' : 'Current Goal',
          style: const TextStyle(
            color: _kTitleColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/icons/sm-coin.png', width: 26, height: 26),
            const SizedBox(width: 10),
            Text(
              '${_formatCoins(amount)} Coins',
              style: const TextStyle(color: Color(0xFF4A4A5C), fontSize: 20),
            ),
          ],
        ),
        if (progress != null) ...[
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: const Color(0xFFE6E2F3),
              valueColor: AlwaysStoppedAnimation<Color>(
                isCompleted ? const Color(0xFF22B573) : _kPurple,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCompleted
                ? '🎉 ${_formatCoins(current!.toInt())} / ${_formatCoins(amount)}'
                : '${_formatCoins(current!.toInt())} / ${_formatCoins(amount)}',
            style: const TextStyle(color: _kMutedColor, fontSize: 14),
          ),
        ],
        const SizedBox(height: 22),
        Material(
          color: const Color(0xFFEDE6FA),
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(true),
            child: const SizedBox(
              width: double.infinity,
              height: 66,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.delete_outline_rounded,
                    color: Color(0xFFE5484D),
                    size: 28,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Cancel Goal',
                    style: TextStyle(
                      color: Color(0xFFE5484D),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Target-with-arrow glyph used for the goal button and dialogs.
class GoalIcon extends StatelessWidget {
  final Color color;
  final double size;
  const GoalIcon({super.key, required this.color, required this.size});

  static const _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke="#000000" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
  <path d="M21 11.2A9 9 0 1 1 12.8 3.04"/>
  <path d="M17 11.6A5 5 0 1 1 12.4 7.02"/>
  <circle cx="12" cy="12" r="1.2"/>
  <path d="M12 12 18.2 5.8"/>
  <path d="M17.2 3.2v3.6h3.6L23 4.6h-3.4V1.2z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(
      _svg,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}
