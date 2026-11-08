import 'dart:convert';
import 'dart:io'; // <-- Added for File

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shoeebapk/core/helpers/image_crop_helper.dart';
import 'package:shoeebapk/core/helpers/avatar_helper.dart';
import 'package:shoeebapk/core/network/service_helper.dart';
import 'package:shoeebapk/app/di/injection_container.dart';

import '../../core/utils/api_status.dart';
import '../../core/themes/app_dark_colors.dart';
import '../../core/utils/age_policy.dart';
import '../../core/helpers/toast_helper.dart';
import '../auth/presentation/widgets/birthdate_picker_sheet.dart';
import 'package:intl/intl.dart';

import 'package:get/get.dart';
import '../session/presentation/controllers/session_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // للتحكم بالنصوص
  late TextEditingController _nameController;
  late TextEditingController _aboutController;

  // لحفظ الحالة الأصلية لمعرفة ما إذا تم التعديل أم لا
  late String _originalName;
  late String _originalAbout;

  bool _hasChanges = false;
  bool _isLoading = false; // <-- بديل لـ isBusy داخل الـ Widget

  @override
  void initState() {
    super.initState();

    // جلب البيانات الحالية من الـ Provider ديناميكياً
    final currentUser = Get.find<SessionController>().session?.user;
    _originalName = currentUser?.name ?? "";
    _originalAbout = currentUser?.bio ?? "";

    _nameController = TextEditingController(text: _originalName);
    _aboutController = TextEditingController(text: _originalAbout);

    // الاستماع للتغييرات في الحقول لتفعيل زر الحفظ وظهور التنبيه
    _nameController.addListener(_checkForChanges);
    _aboutController.addListener(_checkForChanges);
  }

  void _checkForChanges() {
    setState(() {
      _hasChanges =
          _nameController.text != _originalName ||
          _aboutController.text != _originalAbout;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    // Instagram-style flow: pick from the gallery, then let the user pan
    // and zoom inside a circular crop frame before anything is uploaded.
    final File? cropped = await ImageCropHelper.pickAndCropProfileImage(
      ImageSource.gallery,
    );

    if (cropped != null) {
      await updateProfileImage(cropped);
    }
  }

  // دالة تحديث الصورة الشخصية
  Future<void> updateProfileImage(File imageFile) async {
    setState(() => _isLoading = true);
    ServiceHelper serviceHelper = sl<ServiceHelper>();
    try {
      final multipartFile = await serviceHelper.createMultipartFile(
        'profile_image',
        imageFile,
      );

      final response = await serviceHelper.putMultipartHelper(
        target: '/v1/users/profile',
        files: [multipartFile],
        fields: {'name': _nameController.text, 'bio': _aboutController.text},
        token: 'provide',
      );

      if (response is Success) {
        final body = jsonDecode(response.data);
        if (body['success'] == true && body['data'] != null) {
          // تحديث البيانات في الـ SessionController مباشرة بعد نجاح الرفع
          final newImageUrl = body['data']['profile_image'];
          Get.find<SessionController>().updateUserData(
            name: _nameController.text,
            bio: _aboutController.text,
            profileImage: newImageUrl,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('ProfileTabViewModel.updateProfileImage error: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  // دالة حفظ البيانات النصية (الاسم و نبذة عني) عند الضغط على علامة الصح
  Future<void> _saveProfileTextData() async {
    setState(() => _isLoading = true);
    ServiceHelper serviceHelper = sl<ServiceHelper>();
    try {
      // تعديل البيانات عبر الـ API الخاص بالملف الشخصي
      final response = await serviceHelper.putMultipartHelper(
        target: '/v1/users/profile',
        files: [], // لا يوجد ملفات هنا، فقط نصوص
        fields: {'name': _nameController.text, 'bio': _aboutController.text},
        token: 'provide',
      );

      if (response is Success) {
        final body = jsonDecode(response.data);
        if (body['success'] == true) {
          // 1. تحديث الـ SessionController بالبيانات الجديدة لكي تتغير في كل التطبيق
          Get.find<SessionController>().updateUserData(
            name: _nameController.text,
            bio: _aboutController.text,
          );

          // 2. تحديث الحالة الأصلية لمنع ظهور تنبيه التراجع مجدداً
          setState(() {
            _originalName = _nameController.text;
            _originalAbout = _aboutController.text;
            _hasChanges = false;
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile Saved Successfully!')),
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error saving profile data: $e');
    }
    setState(() => _isLoading = false);
  }

  // دالة ذكية لإظهار رسالة التنبيه (Bottom Sheet) عند محاولة الرجوع مع وجود تعديلات
  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true; // إذا لم يكن هناك تعديل، ارجع فوراً

    // إظهار Bottom Sheet
    bool? shouldPop = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor:
          Colors.transparent, // لجعل الحواف العلوية تظهر بشكل دائري
      builder: (BuildContext context) {
        return const DiscardChangesBottomSheet();
      },
    );

    return shouldPop ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<SessionController>(
      builder: (_) => _buildSessionScope(context),
    );
  }

  Widget _buildSessionScope(BuildContext context) {
    // استخدمنا الاستماع لـ SessionController هنا لإعادة بناء الواجهة تلقائياً عند تغيير الصورة أو الاسم
    final userProvider = Get.find<SessionController>().session?.user;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: context.shellBackground,
        body: SafeArea(
          child: Column(
            children: [
              // مؤشر التحميل العلوي في حال وجود عملية معالجة
              if (_isLoading)
                const LinearProgressIndicator(color: Color(0xFF6044FF)),

              // 1. الشريط العلوي (App Bar)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        InkWell(
                          onTap: () async {
                            if (await _onWillPop()) {
                              if (mounted) Navigator.pop(context);
                            }
                          },
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: context.shellTextPrimary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Profile',
                          style: TextStyle(
                            color: context.shellTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),

                    // زر الحفظ
                    InkWell(
                      onTap: (_hasChanges && !_isLoading)
                          ? _saveProfileTextData
                          : null,
                      child: Icon(
                        Icons.check,
                        color: _hasChanges
                            ? const Color(0xFF6044FF)
                            : Colors.grey,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. المحتوى (الصورة والحقول)
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 30),

                        // صورة الملف الشخصي مع زر (+)
                        Center(
                          child: Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                width: 125,
                                height: 125,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEDEDED),
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.grey[100],
                                  backgroundImage: AvatarHelper.resolve(
                                    userProvider?.profileImage,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () {
                                  _pickAndUploadImage();
                                },
                                child: Container(
                                  width: 35,
                                  height: 35,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFBBBBBB),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: Colors.black,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),

                        // حقل الإدخال: Name
                        _buildInputField(
                          label: 'Name',
                          controller: _nameController,
                          maxLength: 15,
                        ),

                        const SizedBox(height: 20),

                        // حقل الإدخال: About Me
                        _buildInputField(
                          label: 'About Me',
                          controller: _aboutController,
                          maxLength: 150,
                          hint: 'Type few words about you',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 24),

                        // البيانات الثابتة (Read Only)
                        _buildReadOnlyField('User ID', '85485645'),
                        _buildReadOnlyField(
                          'Gender',
                          /* userProvider?.gender ??*/ 'Male',
                        ),
                        _buildBirthdateField(
                          userProvider?.birthdate,
                          userProvider?.birthdateUpdatedAt,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ودجت بناء حقول الإدخال مع عداد الأحرف
  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required int maxLength,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${controller.text.length}/$maxLength',
              style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 14),
            ),
          ],
        ),
        TextField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          style: TextStyle(
            color: context.shellTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint ?? '',
            hintStyle: const TextStyle(
              color: Color(0xFF7A7A7A),
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
            counterText: "",
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFBBBBBB)),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFF6044FF)),
            ),
          ),
        ),
      ],
    );
  }

  bool _savingBirthdate = false;

  // Same look as the read-only fields, but tappable: the birthdate can be
  // changed once every 6 months (18+ only — the server enforces both).
  Widget _buildBirthdateField(DateTime? birthdate, DateTime? updatedAt) {
    final nextChange = AgePolicy.nextBirthdateChange(updatedAt);
    final value = birthdate != null
        ? birthdate.toString().substring(0, 10)
        : '0000-00-00';
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _changeBirthdate(birthdate, nextChange),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date of Birth',
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      color: context.shellTextPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                if (_savingBirthdate)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    nextChange == null
                        ? Icons.chevron_right
                        : Icons.lock_outline,
                    size: 18,
                    color: const Color(0xFF7A7A7A),
                  ),
              ],
            ),
            if (nextChange != null) ...[
              const SizedBox(height: 4),
              Text(
                'You can change it again on ${DateFormat('MMM d, y').format(nextChange)}',
                style: const TextStyle(color: Color(0xFF7A7A7A), fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _changeBirthdate(DateTime? current, DateTime? nextChange) async {
    if (_savingBirthdate) return;
    if (nextChange != null) {
      ToastHelper.showInfoToast(
        message:
            'You can change your birthdate again on ${DateFormat('MMM d, y').format(nextChange)}',
      );
      return;
    }

    final picked = await showBirthdatePickerSheet(context, initial: current);
    if (picked == null || !mounted) return;
    if (current != null &&
        picked.year == current.year &&
        picked.month == current.month &&
        picked.day == current.day) {
      return;
    }
    if (!AgePolicy.isAdult(picked)) {
      ToastHelper.showErrorToast(message: AgePolicy.underageMessage);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Change birthdate?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Your birthdate will be ${DateFormat('MMM d, y').format(picked)}. '
          'You won\'t be able to change it again for 6 months.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Change',
              style: TextStyle(color: Color(0xFF6044FF)),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _savingBirthdate = true);
    final dateText = DateFormat('yyyy-MM-dd').format(picked);
    final response = await sl<ServiceHelper>().putHelper(
      target: '/v1/users/profile',
      token: 'provide',
      body: {'birthdate': dateText},
    );
    if (!mounted) return;
    setState(() => _savingBirthdate = false);

    if (response is Success) {
      DateTime changedAt = DateTime.now();
      try {
        final body = jsonDecode(response.data);
        final raw = body['data']?['birthdate_updated_at'];
        if (raw != null) changedAt = DateTime.parse(raw.toString());
      } catch (_) {}
      Get.find<SessionController>().updateBirthdate(picked, changedAt);
      ToastHelper.showSuccessToast(message: 'Birthdate updated');
    } else if (response is Failure) {
      ToastHelper.showErrorToast(message: response.errorResponse.toString());
    }
  }

  Widget _buildReadOnlyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.shellTextPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          if (label == "User ID")
            Row(
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: context.shellTextPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () async {
                    await Clipboard.setData(ClipboardData(text: value));
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text("Copied successfully"),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    margin: const EdgeInsets.only(left: 8),
                    decoration: const BoxDecoration(shape: BoxShape.circle),
                    child: Icon(
                      Icons.copy,
                      size: 18,
                      color: context.shellTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          if (label != "User ID")
            Text(
              value,
              style: TextStyle(
                color: context.shellTextPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w400,
              ),
            ),
        ],
      ),
    );
  }
}

class DiscardChangesBottomSheet extends StatelessWidget {
  const DiscardChangesBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Discard Changes?',
            style: TextStyle(
              color: Colors.black,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'If you go back now, you’ll lose any changes\nyou’ve made.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.w400,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 32),
          InkWell(
            onTap: () => Navigator.pop(context, true),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7247EF), Color(0xFFB862E1)],
                ),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Discard Changes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () => Navigator.pop(context, false),
            borderRadius: BorderRadius.circular(50),
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                border: Border.all(color: const Color(0xFFBBBBBB), width: 1),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Continue editing',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
