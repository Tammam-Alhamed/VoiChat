import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../../core/helpers/toast_helper.dart';
import '../widgets/footer_widget.dart';
import 'otp_screen.dart';

import '../controllers/auth_controller.dart';

// ─────────────────────────────────────────────────────────────
// Country data (inline — no JSON asset needed)
// ─────────────────────────────────────────────────────────────
class _Country {
  final String name;
  final String code;
  final String dial;
  const _Country(this.name, this.code, this.dial);
}

const List<_Country> _kCountries = [
  _Country('Afghanistan', 'AF', '+93'),
  _Country('Albania', 'AL', '+355'),
  _Country('Algeria', 'DZ', '+213'),
  _Country('American Samoa', 'AS', '+1'),
  _Country('Andorra', 'AD', '+376'),
  _Country('Angola', 'AO', '+244'),
  _Country('Anguilla', 'AI', '+1'),
  _Country('Antigua and Barbuda', 'AG', '+1'),
  _Country('Argentina', 'AR', '+54'),
  _Country('Armenia', 'AM', '+374'),
  _Country('Aruba', 'AW', '+297'),
  _Country('Australia', 'AU', '+61'),
  _Country('Austria', 'AT', '+43'),
  _Country('Azerbaijan', 'AZ', '+994'),
  _Country('Bahamas', 'BS', '+1'),
  _Country('Bahrain', 'BH', '+973'),
  _Country('Bangladesh', 'BD', '+880'),
  _Country('Barbados', 'BB', '+1'),
  _Country('Belarus', 'BY', '+375'),
  _Country('Belgium', 'BE', '+32'),
  _Country('Belize', 'BZ', '+501'),
  _Country('Benin', 'BJ', '+229'),
  _Country('Bermuda', 'BM', '+1'),
  _Country('Bhutan', 'BT', '+975'),
  _Country('Bolivia', 'BO', '+591'),
  _Country('Bosnia and Herzegovina', 'BA', '+387'),
  _Country('Botswana', 'BW', '+267'),
  _Country('Brazil', 'BR', '+55'),
  _Country('British Virgin Islands', 'VG', '+1'),
  _Country('Brunei', 'BN', '+673'),
  _Country('Bulgaria', 'BG', '+359'),
  _Country('Burkina Faso', 'BF', '+226'),
  _Country('Burundi', 'BI', '+257'),
  _Country('Cambodia', 'KH', '+855'),
  _Country('Cameroon', 'CM', '+237'),
  _Country('Canada', 'CA', '+1'),
  _Country('Cape Verde', 'CV', '+238'),
  _Country('Cayman Islands', 'KY', '+1'),
  _Country('Central African Republic', 'CF', '+236'),
  _Country('Chad', 'TD', '+235'),
  _Country('Chile', 'CL', '+56'),
  _Country('China', 'CN', '+86'),
  _Country('Colombia', 'CO', '+57'),
  _Country('Comoros', 'KM', '+269'),
  _Country('Congo', 'CG', '+242'),
  _Country('Cook Islands', 'CK', '+682'),
  _Country('Costa Rica', 'CR', '+506'),
  _Country('Croatia', 'HR', '+385'),
  _Country('Cuba', 'CU', '+53'),
  _Country('Curaçao', 'CW', '+599'),
  _Country('Cyprus', 'CY', '+357'),
  _Country('Czech Republic', 'CZ', '+420'),
  _Country('Denmark', 'DK', '+45'),
  _Country('Djibouti', 'DJ', '+253'),
  _Country('Dominica', 'DM', '+1'),
  _Country('Dominican Republic', 'DO', '+1'),
  _Country('DR Congo', 'CD', '+243'),
  _Country('Ecuador', 'EC', '+593'),
  _Country('Egypt', 'EG', '+20'),
  _Country('El Salvador', 'SV', '+503'),
  _Country('Equatorial Guinea', 'GQ', '+240'),
  _Country('Eritrea', 'ER', '+291'),
  _Country('Estonia', 'EE', '+372'),
  _Country('Eswatini', 'SZ', '+268'),
  _Country('Ethiopia', 'ET', '+251'),
  _Country('Falkland Islands', 'FK', '+500'),
  _Country('Faroe Islands', 'FO', '+298'),
  _Country('Fiji', 'FJ', '+679'),
  _Country('Finland', 'FI', '+358'),
  _Country('France', 'FR', '+33'),
  _Country('French Guiana', 'GF', '+594'),
  _Country('French Polynesia', 'PF', '+689'),
  _Country('Gabon', 'GA', '+241'),
  _Country('Gambia', 'GM', '+220'),
  _Country('Georgia', 'GE', '+995'),
  _Country('Germany', 'DE', '+49'),
  _Country('Ghana', 'GH', '+233'),
  _Country('Gibraltar', 'GI', '+350'),
  _Country('Greece', 'GR', '+30'),
  _Country('Greenland', 'GL', '+299'),
  _Country('Grenada', 'GD', '+1'),
  _Country('Guadeloupe', 'GP', '+590'),
  _Country('Guam', 'GU', '+1'),
  _Country('Guatemala', 'GT', '+502'),
  _Country('Guinea', 'GN', '+224'),
  _Country('Guinea-Bissau', 'GW', '+245'),
  _Country('Guyana', 'GY', '+592'),
  _Country('Haiti', 'HT', '+509'),
  _Country('Honduras', 'HN', '+504'),
  _Country('Hong Kong', 'HK', '+852'),
  _Country('Hungary', 'HU', '+36'),
  _Country('Iceland', 'IS', '+354'),
  _Country('India', 'IN', '+91'),
  _Country('Indonesia', 'ID', '+62'),
  _Country('Iran', 'IR', '+98'),
  _Country('Iraq', 'IQ', '+964'),
  _Country('Ireland', 'IE', '+353'),
  _Country('Israel', 'IL', '+972'),
  _Country('Italy', 'IT', '+39'),
  _Country('Ivory Coast', 'CI', '+225'),
  _Country('Jamaica', 'JM', '+1'),
  _Country('Japan', 'JP', '+81'),
  _Country('Jordan', 'JO', '+962'),
  _Country('Kazakhstan', 'KZ', '+7'),
  _Country('Kenya', 'KE', '+254'),
  _Country('Kiribati', 'KI', '+686'),
  _Country('Kosovo', 'XK', '+383'),
  _Country('Kuwait', 'KW', '+965'),
  _Country('Kyrgyzstan', 'KG', '+996'),
  _Country('Laos', 'LA', '+856'),
  _Country('Latvia', 'LV', '+371'),
  _Country('Lebanon', 'LB', '+961'),
  _Country('Lesotho', 'LS', '+266'),
  _Country('Liberia', 'LR', '+231'),
  _Country('Libya', 'LY', '+218'),
  _Country('Liechtenstein', 'LI', '+423'),
  _Country('Lithuania', 'LT', '+370'),
  _Country('Luxembourg', 'LU', '+352'),
  _Country('Macau', 'MO', '+853'),
  _Country('Madagascar', 'MG', '+261'),
  _Country('Malawi', 'MW', '+265'),
  _Country('Malaysia', 'MY', '+60'),
  _Country('Maldives', 'MV', '+960'),
  _Country('Mali', 'ML', '+223'),
  _Country('Malta', 'MT', '+356'),
  _Country('Marshall Islands', 'MH', '+692'),
  _Country('Martinique', 'MQ', '+596'),
  _Country('Mauritania', 'MR', '+222'),
  _Country('Mauritius', 'MU', '+230'),
  _Country('Mayotte', 'YT', '+262'),
  _Country('Mexico', 'MX', '+52'),
  _Country('Micronesia', 'FM', '+691'),
  _Country('Moldova', 'MD', '+373'),
  _Country('Monaco', 'MC', '+377'),
  _Country('Mongolia', 'MN', '+976'),
  _Country('Montenegro', 'ME', '+382'),
  _Country('Montserrat', 'MS', '+1'),
  _Country('Morocco', 'MA', '+212'),
  _Country('Mozambique', 'MZ', '+258'),
  _Country('Myanmar', 'MM', '+95'),
  _Country('Namibia', 'NA', '+264'),
  _Country('Nauru', 'NR', '+674'),
  _Country('Nepal', 'NP', '+977'),
  _Country('Netherlands', 'NL', '+31'),
  _Country('New Caledonia', 'NC', '+687'),
  _Country('New Zealand', 'NZ', '+64'),
  _Country('Nicaragua', 'NI', '+505'),
  _Country('Niger', 'NE', '+227'),
  _Country('Nigeria', 'NG', '+234'),
  _Country('Niue', 'NU', '+683'),
  _Country('North Korea', 'KP', '+850'),
  _Country('North Macedonia', 'MK', '+389'),
  _Country('Northern Mariana Islands', 'MP', '+1'),
  _Country('Norway', 'NO', '+47'),
  _Country('Oman', 'OM', '+968'),
  _Country('Pakistan', 'PK', '+92'),
  _Country('Palau', 'PW', '+680'),
  _Country('Palestine', 'PS', '+970'),
  _Country('Panama', 'PA', '+507'),
  _Country('Papua New Guinea', 'PG', '+675'),
  _Country('Paraguay', 'PY', '+595'),
  _Country('Peru', 'PE', '+51'),
  _Country('Philippines', 'PH', '+63'),
  _Country('Poland', 'PL', '+48'),
  _Country('Portugal', 'PT', '+351'),
  _Country('Puerto Rico', 'PR', '+1'),
  _Country('Qatar', 'QA', '+974'),
  _Country('Réunion', 'RE', '+262'),
  _Country('Romania', 'RO', '+40'),
  _Country('Russia', 'RU', '+7'),
  _Country('Rwanda', 'RW', '+250'),
  _Country('Saint Kitts and Nevis', 'KN', '+1'),
  _Country('Saint Lucia', 'LC', '+1'),
  _Country('Saint Martin', 'MF', '+590'),
  _Country('Saint Pierre and Miquelon', 'PM', '+508'),
  _Country('Saint Vincent and the Grenadines', 'VC', '+1'),
  _Country('Samoa', 'WS', '+685'),
  _Country('San Marino', 'SM', '+378'),
  _Country('São Tomé and Príncipe', 'ST', '+239'),
  _Country('Saudi Arabia', 'SA', '+966'),
  _Country('Senegal', 'SN', '+221'),
  _Country('Serbia', 'RS', '+381'),
  _Country('Seychelles', 'SC', '+248'),
  _Country('Sierra Leone', 'SL', '+232'),
  _Country('Singapore', 'SG', '+65'),
  _Country('Sint Maarten', 'SX', '+1'),
  _Country('Slovakia', 'SK', '+421'),
  _Country('Slovenia', 'SI', '+386'),
  _Country('Solomon Islands', 'SB', '+677'),
  _Country('Somalia', 'SO', '+252'),
  _Country('South Africa', 'ZA', '+27'),
  _Country('South Korea', 'KR', '+82'),
  _Country('South Sudan', 'SS', '+211'),
  _Country('Spain', 'ES', '+34'),
  _Country('Sri Lanka', 'LK', '+94'),
  _Country('Sudan', 'SD', '+249'),
  _Country('Suriname', 'SR', '+597'),
  _Country('Sweden', 'SE', '+46'),
  _Country('Switzerland', 'CH', '+41'),
  _Country('Syria', 'SY', '+963'),
  _Country('Taiwan', 'TW', '+886'),
  _Country('Tajikistan', 'TJ', '+992'),
  _Country('Tanzania', 'TZ', '+255'),
  _Country('Thailand', 'TH', '+66'),
  _Country('Timor-Leste', 'TL', '+670'),
  _Country('Togo', 'TG', '+228'),
  _Country('Tokelau', 'TK', '+690'),
  _Country('Tonga', 'TO', '+676'),
  _Country('Trinidad and Tobago', 'TT', '+1'),
  _Country('Tunisia', 'TN', '+216'),
  _Country('Turkey', 'TR', '+90'),
  _Country('Turkmenistan', 'TM', '+993'),
  _Country('Turks and Caicos Islands', 'TC', '+1'),
  _Country('Tuvalu', 'TV', '+688'),
  _Country('Uganda', 'UG', '+256'),
  _Country('Ukraine', 'UA', '+380'),
  _Country('United Arab Emirates', 'AE', '+971'),
  _Country('United Kingdom', 'GB', '+44'),
  _Country('United States', 'US', '+1'),
  _Country('Uruguay', 'UY', '+598'),
  _Country('US Virgin Islands', 'VI', '+1'),
  _Country('Uzbekistan', 'UZ', '+998'),
  _Country('Vanuatu', 'VU', '+678'),
  _Country('Vatican City', 'VA', '+39'),
  _Country('Venezuela', 'VE', '+58'),
  _Country('Vietnam', 'VN', '+84'),
  _Country('Wallis and Futuna', 'WF', '+681'),
  _Country('Western Sahara', 'EH', '+212'),
  _Country('Yemen', 'YE', '+967'),
  _Country('Zambia', 'ZM', '+260'),
  _Country('Zimbabwe', 'ZW', '+263'),
];

// ─────────────────────────────────────────────────────────────
// Bottom sheet — country picker
// ─────────────────────────────────────────────────────────────
class _CountryPickerSheet extends StatefulWidget {
  final _Country selected;
  const _CountryPickerSheet({required this.selected});

  @override
  State<_CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<_CountryPickerSheet> {
  final TextEditingController _search = TextEditingController();
  List<_Country> _filtered = _kCountries;

  @override
  void initState() {
    super.initState();
    _search.addListener(_onSearch);
  }

  @override
  void dispose() {
    _search.removeListener(_onSearch);
    _search.dispose();
    super.dispose();
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
  Widget build(BuildContext context) {
    return Container(
      width: 1.sw, // 100% من عرض الشاشة
      height: .8.sh, // 100% من طول الشاشة
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [Color(0xff060912), Color(0xff111032)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // ── Drag handle ──────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E0E0),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // ── Title ────────────────────────────────────────────
          Text(
            'select_country'.tr,
            style: TextStyle(
              fontSize: 18,
              fontFamily: 'Tajawal',
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // ── Search field ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF31266A), width: 1.5),
                borderRadius: BorderRadius.circular(46),
              ),
              child: TextField(
                controller: _search,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontFamily: 'Tajawal',
                ),
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    Icons.search,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  hintText: 'search_country_or_code'.tr,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 14,
                    fontFamily: 'Tajawal',
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ── List ─────────────────────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _filtered.length,
              itemBuilder: (context, i) {
                final country = _filtered[i];
                final isSelected = country.code == widget.selected.code;

                return InkWell(
                  onTap: () => Navigator.pop(context, country),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: isSelected
                        ? BoxDecoration(
                            color: const Color(0xFF222222).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          )
                        : null,
                    child: Row(
                      children: [
                        // Circular flag
                        ClipOval(
                          child: SizedBox(
                            width: 32,
                            height: 32,
                            child: CountryFlag.fromCountryCode(
                              country.code,
                              theme: ImageTheme(width: 32, height: 32),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        // Name
                        Expanded(
                          child: Text(
                            country.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontFamily: 'Tajawal',
                              fontWeight: FontWeight.w400,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        // Dial code
                        Text(
                          country.dial,
                          style: TextStyle(
                            fontSize: 14,
                            fontFamily: 'Tajawal',
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? const Color(0xFF222222)
                                : const Color(0xFF737373),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check,
                            size: 18,
                            color: Color(0xFF222222),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Phone login screen — unchanged design, dial code picker added
// ─────────────────────────────────────────────────────────────
class PhoneLoginScreen extends StatefulWidget {
  const PhoneLoginScreen({super.key});

  @override
  State<PhoneLoginScreen> createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  // Default: Syria +963
  _Country _selectedCountry = const _Country('Syria', 'SY', '+963');

  Future<void> _openCountryPicker() async {
    final result = await showModalBottomSheet<_Country>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CountryPickerSheet(selected: _selectedCountry),
    );
    if (result != null) {
      setState(() => _selectedCountry = result);
    }
  }

  Future<void> _handleSendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ToastHelper.showErrorToast(message: 'enter_valid_phone_number'.tr);
      return;
    }

    // Some phone formats might include the + in the text field or starting 0
    final fullPhone =
        '${_selectedCountry.dial}${phone.startsWith('0') ? phone.substring(1) : phone}';

    final authProvider = Get.find<AuthController>();
    final success = await authProvider.sendOtp(fullPhone);

    if (success) {
      Get.to(() => OTPScreen(contactInfo: fullPhone));
    } else {
      ToastHelper.showErrorToast(
        message: authProvider.errorMessage ?? 'failed_to_send_otp'.tr,
      );
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      body: Container(
        width: 1.sw,
        height: 1.sh,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xff060912), Color(0xff111032)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 30.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20.h),
                // زر الرجوع
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 28.sp,
                  ),
                ),
                SizedBox(height: 40.h),
                Text(
                  'continue_with_phone'.tr,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10.h),
                Text(
                  'phone_otp_subtitle'.tr,
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
                SizedBox(height: 40.h),
                // حقل الإدخال
                Container(
                  height: 60.h,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(
                      color: const Color(0xFF31266A),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 15.w),

                      // علم افتراضي (استخدم مكتبتك)
                      GestureDetector(
                        onTap: () => _openCountryPicker(),
                        child: Row(
                          children: [
                            // تم استبدال الحاوية الحمراء بكود المكتبة الفعلي
                            ClipOval(
                              child: SizedBox(
                                width: 25.w,
                                height: 25.w,
                                child: CountryFlag.fromCountryCode(
                                  _selectedCountry
                                      .code, // هنا نمرر كود الدولة المختار (مثل SY أو PL)
                                ),
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              _selectedCountry.dial,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20.sp,
                            ),
                          ],
                        ),
                      ),

                      VerticalDivider(
                        color: Colors.white24,
                        indent: 15.h,
                        endIndent: 15.h,
                      ),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: 'mobile_number'.tr,
                            hintStyle: TextStyle(
                              color: Colors.white38,
                              fontSize: 15.sp,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10.w,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 80.h),
                // زر Continue المتدرج
                GetBuilder<AuthController>(
                  builder: (auth) {
                    final isLoading = auth.isLoading;
                    return GestureDetector(
                      onTap: isLoading ? null : _handleSendOtp,
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
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'continue'.tr,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const Spacer(),

                // نصوص الشروط بالأسفل
                if (!isKeyboardOpen) FooterWidget(),
                SizedBox(height: 30.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
