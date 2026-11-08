import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shoeebapk/core/assets_manager.dart';
import 'package:shoeebapk/core/widgets/action_bottom_sheet.dart';

import '../../tabs/profile/viewmodel/profile_tab_viewmodel.dart';

/// "Add Post" action sheet — uses the same unified [showActionBottomSheet]
/// design as the profile-photo picker (same shape, icon treatment, sizes,
/// spacing) so every bottom sheet in the app looks consistent. Icons match
/// the Figma design's dedicated camera/play glyphs (AssetsManager.addPhoto
/// / addVideo) instead of generic Material icons.
Future<void> showAddPostSheet(BuildContext context) {
  return showActionBottomSheet(
    context,
    options: [
      ActionSheetOption(
        iconAsset: AssetsManager.addPhoto,
        text: "Add Photo",
        onTap: () => _pickAndUpload(context, ImageSource.gallery, false),
      ),
      ActionSheetOption(
        iconAsset: AssetsManager.addVideo,
        text: "Add Video",
        onTap: () => _pickAndUpload(context, ImageSource.gallery, true),
      ),
    ],
  );
}

Future<void> _pickAndUpload(
  BuildContext context,
  ImageSource source,
  bool isVideo,
) async {
  final provider = context.read<ProfileTabViewModel>();

  final picker = ImagePicker();
  final XFile? picked = isVideo
      ? await picker.pickVideo(source: source)
      : await picker.pickImage(source: source);

  if (picked != null) {
    provider.addPost(File(picked.path));
  }
}
