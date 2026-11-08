import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

/// Instagram-style "pick then crop" flow for profile pictures: the user
/// picks a photo, then gets a native crop screen where they can pan/zoom
/// and position exactly what shows inside the circular profile frame.
/// Nothing is uploaded until they confirm the crop.
class ImageCropHelper {
  static final ImagePicker _picker = ImagePicker();

  /// Opens the given [source] (camera/gallery), then the circular crop
  /// screen. Returns the cropped image file, or null if the user cancelled
  /// at either step.
  static Future<File?> pickAndCropProfileImage(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (picked == null) return null;

    final CroppedFile? cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      // Locking the aspect ratio to 1:1 keeps the crop rectangle square,
      // matching the circular mask shown during cropping and the circular
      // avatar it will end up in.
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 90,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Move and Scale',
          toolbarColor: const Color(0xFF6044FF),
          toolbarWidgetColor: const Color(0xFFFFFFFF),
          activeControlsWidgetColor: const Color(0xFF6044FF),
          statusBarColor: const Color(0xFF6044FF),
          backgroundColor: const Color(0xFF000000),
          cropStyle: CropStyle.circle,
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Move and Scale',
          cropStyle: CropStyle.circle,
          aspectRatioLockEnabled: true,
          aspectRatioPickerButtonHidden: true,
          resetAspectRatioEnabled: false,
          doneButtonTitle: 'Done',
          cancelButtonTitle: 'Cancel',
        ),
      ],
    );

    if (cropped == null) return null;
    return File(cropped.path);
  }
}
