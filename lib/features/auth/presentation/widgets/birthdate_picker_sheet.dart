import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../../core/utils/age_policy.dart';

/// The app's birthday wheel picker (dark sheet with Month / Day / Year).
/// Used by registration and Edit Profile. Years run up to
/// [AgePolicy.maxPickerYear]; the day wheel always matches the chosen
/// month (no "Feb 31"). Returns the picked date, or null if dismissed.
Future<DateTime?> showBirthdatePickerSheet(
  BuildContext context, {
  DateTime? initial,
}) {
  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _BirthdatePickerSheet(initial: initial),
  );
}

class _BirthdatePickerSheet extends StatefulWidget {
  final DateTime? initial;
  const _BirthdatePickerSheet({this.initial});

  @override
  State<_BirthdatePickerSheet> createState() => _BirthdatePickerSheetState();
}

class _BirthdatePickerSheetState extends State<_BirthdatePickerSheet> {
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  late final List<int> _years;
  late int _monthIndex;
  late int _day;
  late int _year;

  late final FixedExtentScrollController _monthCtrl;
  late final FixedExtentScrollController _dayCtrl;
  late final FixedExtentScrollController _yearCtrl;

  @override
  void initState() {
    super.initState();
    _years = List.generate(
      AgePolicy.maxPickerYear - AgePolicy.minPickerYear + 1,
      (i) => AgePolicy.minPickerYear + i,
    );
    final start = widget.initial ?? DateTime(2002, 9, 12);
    _year = start.year.clamp(_years.first, _years.last);
    _monthIndex = start.month - 1;
    _day = start.day.clamp(1, AgePolicy.daysInMonth(_year, _monthIndex + 1));

    _monthCtrl = FixedExtentScrollController(initialItem: _monthIndex);
    _dayCtrl = FixedExtentScrollController(initialItem: _day - 1);
    _yearCtrl = FixedExtentScrollController(initialItem: _years.indexOf(_year));
  }

  @override
  void dispose() {
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    _yearCtrl.dispose();
    super.dispose();
  }

  int get _daysInMonth => AgePolicy.daysInMonth(_year, _monthIndex + 1);

  /// Keeps the day valid after the month/year changes (31 → 30 / 28 ...).
  void _clampDay() {
    final max = _daysInMonth;
    if (_day > max) {
      _day = max;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_dayCtrl.hasClients) _dayCtrl.jumpToItem(_day - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 480.h,
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewPadding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30.r),
          topRight: Radius.circular(30.r),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: 12.h),
          Container(
            width: 40.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          SizedBox(height: 25.h),
          Text(
            'birthday'.tr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5.h),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  height: 50.h,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    border: Border(
                      top: BorderSide(color: Colors.white10, width: 1),
                      bottom: BorderSide(color: Colors.white10, width: 1),
                    ),
                  ),
                ),
                SizedBox(
                  height: 200.h,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _wheel(
                        width: 80.w,
                        controller: _monthCtrl,
                        count: _months.length,
                        onSelected: (i) => setState(() {
                          _monthIndex = i;
                          _clampDay();
                        }),
                        label: (i) => _months[i],
                        selected: (i) => i == _monthIndex,
                      ),
                      _wheel(
                        width: 60.w,
                        controller: _dayCtrl,
                        count: _daysInMonth,
                        onSelected: (i) => setState(() => _day = i + 1),
                        label: (i) => '${i + 1}',
                        selected: (i) => i + 1 == _day,
                      ),
                      _wheel(
                        width: 100.w,
                        controller: _yearCtrl,
                        count: _years.length,
                        onSelected: (i) => setState(() {
                          _year = _years[i];
                          _clampDay();
                        }),
                        label: (i) => '${_years[i]}',
                        selected: (i) => _years[i] == _year,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w, vertical: 5.h),
            child: GestureDetector(
              onTap: () => Navigator.pop(
                context,
                DateTime(_year, _monthIndex + 1, _day),
              ),
              child: Container(
                width: double.infinity,
                height: 55.h,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30.r),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'continue'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 32.h),
        ],
      ),
    );
  }

  Widget _wheel({
    required double width,
    required FixedExtentScrollController controller,
    required int count,
    required ValueChanged<int> onSelected,
    required String Function(int) label,
    required bool Function(int) selected,
  }) {
    return SizedBox(
      width: width,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        itemExtent: 50.h,
        physics: const FixedExtentScrollPhysics(),
        onSelectedItemChanged: onSelected,
        childDelegate: ListWheelChildBuilderDelegate(
          childCount: count,
          builder: (context, i) => Center(
            child: Text(
              label(i),
              style: TextStyle(
                color: selected(i) ? Colors.white : Colors.white38,
                fontSize: 20.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
