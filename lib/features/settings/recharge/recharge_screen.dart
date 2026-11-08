import 'package:flutter/material.dart';

import '../../../show_next_dialog.dart';
import '../../../core/themes/app_dark_colors.dart';

class RechargeCenterScreen extends StatefulWidget {
  const RechargeCenterScreen({super.key});

  @override
  State<RechargeCenterScreen> createState() => _RechargeCenterScreenState();
}

class _RechargeCenterScreenState extends State<RechargeCenterScreen> {
  // للتحكم في الباقة المحددة
  int _selectedPackageIndex = 0;

  // قائمة ببيانات باقات الشحن (يمكن استبدالها بـ API)
  final List<Map<String, dynamic>> _diamondPackages = [
    {"base": "150", "bonus": "+50", "price": "\$1.04", "tag": null},
    {"base": "500", "bonus": "+100", "price": "\$5.99", "tag": "Hot"},
    {"base": "1000", "bonus": "+250", "price": "\$9.99", "tag": null},
    {"base": "3000", "bonus": "+800", "price": "\$25.50", "tag": "Popular"},
    {"base": "5000", "bonus": "+1500", "price": "\$45.00", "tag": null},
    {"base": "10000", "bonus": "+3500", "price": "\$85.99", "tag": null},
  ];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.shellBackground,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. الشريط العلوي (App Bar) ومعلومات الرصيد الحالي
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
                        'Recharge Center',
                        style: TextStyle(
                          color: context.shellTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  // رصيد الألماس الحالي
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: context.themedColor(
                        const Color(0xFFF2F2F2),
                        AppDarkColors.card,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Image.asset(
                            "assets/icons/diamond.png",
                            fit: BoxFit.fill,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '3812', // الرصيد
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. المحتوى القابل للتمرير
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // عنوان قسم الباقات
                    Text(
                      "Select Package",
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // شبكة عرض باقات الألماس
                    GridView.builder(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // لمنع التعارض مع السكرول الأساسي
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, // 3 باقات في كل صف
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.65, // طول الباقة مقارنة بعرضها
                          ),
                      itemCount: _diamondPackages.length,
                      itemBuilder: (context, index) {
                        final pkg = _diamondPackages[index];
                        return _buildDiamondPackage(
                          index: index,
                          baseDiamonds: pkg['base'],
                          bonusDiamonds: pkg['bonus'],
                          price: pkg['price'],
                          tag: pkg['tag'],
                        );
                      },
                    ),

                    const SizedBox(height: 40),

                    // عنوان طرق الدفع
                    Text(
                      "Choose Payment method",
                      style: TextStyle(
                        color: context.shellTextPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // خيارات الدفع (Google Play & Card)
                    InkWell(
                      onTap: () {
                        showPaymentGateAlert();
                      },
                      child: _buildPaymentMethodOption(
                        title: "Google Play",
                        iconUrl: "assets/icons/google-play.png",
                        price:
                            _diamondPackages[_selectedPackageIndex]['price'], // السعر يتحدث حسب الباقة المختارة
                      ),
                    ),
                    const SizedBox(height: 12),

                    // خيار البطاقة مع إظهار الخصم
                    InkWell(
                      onTap: () {
                        showPaymentGateAlert();
                      },
                      child: _buildPaymentMethodOption(
                        title: "Card Payment",
                        iconUrl:
                            "assets/icons/atm-card.png", // استخدمت أيقونة فلاتر كبديل
                        price: "\$5.39", // سعر بعد الخصم (مثال)
                        oldPrice:
                            _diamondPackages[_selectedPackageIndex]['price'], // سعر مشطوب
                      ),
                    ),

                    const SizedBox(height: 40), // مسافة في النهاية
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // ودجت بناء باقات الألماس (تتفاعل وتتلون عند النقر)
  // ==========================================
  Widget _buildDiamondPackage({
    required int index,
    required String baseDiamonds,
    required String bonusDiamonds,
    required String price,
    String? tag,
  }) {
    bool isSelected = _selectedPackageIndex == index;

    return GestureDetector(
      onTap: () {
        showPaymentGateAlert();
        setState(() {
          _selectedPackageIndex = index;
        });
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // إطار الباقة الأساسي
          Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7B13E2).withOpacity(0.05)
                  : Colors.white,
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF7B13E2)
                    : const Color(0xFFE0E0E0),
                width: isSelected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // الرقم الأساسي
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Image.asset(
                        "assets/icons/diamond.png",
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      baseDiamonds,
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                // البونص الإضافي
                Text(
                  bonusDiamonds,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // صورة صندوق الألماس (يمكن تغييرها بصورة حقيقية)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/icons/diamond_box.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // زر السعر في الأسفل
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7B13E2)
                        : const Color(0xFFF5F5F5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(10),
                      bottomRight: Radius.circular(10),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    price,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // شريط التمييز العلوي (Hot / Popular)
          if (tag != null)
            Positioned(
              top: -10,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: tag == "Hot"
                      ? Colors.redAccent
                      : const Color(0xFF7B13E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tag,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // ودجت بناء طرق الدفع
  // ==========================================
  Widget _buildPaymentMethodOption({
    required String title,
    String? iconUrl,
    IconData? icon,
    required String price,
    String? oldPrice,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE0E0E0)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // أيقونة طريقة الدفع
          if (iconUrl != null)
            Image.asset(iconUrl, fit: BoxFit.cover, width: 32, height: 32)
          else if (icon != null)
            Icon(icon, size: 32, color: Colors.blueGrey),

          const SizedBox(width: 16),

          // اسم طريقة الدفع
          Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),

          const Spacer(),

          // السعر المعروض
          if (oldPrice != null) ...[
            Text(
              oldPrice,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
                decoration: TextDecoration.lineThrough, // خط شطب للسعر القديم
                decorationColor: Color.fromARGB(255, 65, 65, 65),
              ),
            ),
            const SizedBox(width: 8),
          ],

          Text(
            price,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
