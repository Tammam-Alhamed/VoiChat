import 'package:flutter/material.dart';

enum ReportReason {
  spam,
  harassment,
  inappropriateContent,
  fakeProfile,
  underage,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get value {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.harassment:
        return 'harassment';
      case ReportReason.inappropriateContent:
        return 'inappropriate_content';
      case ReportReason.fakeProfile:
        return 'fake_profile';
      case ReportReason.underage:
        return 'underage';
      case ReportReason.other:
        return 'other';
    }
  }

  String get title {
    switch (this) {
      case ReportReason.spam:
        return 'Spam';
      case ReportReason.harassment:
        return 'Harassment';
      case ReportReason.inappropriateContent:
        return 'Inappropriate Content';
      case ReportReason.fakeProfile:
        return 'Fake Profile';
      case ReportReason.underage:
        return 'Underage User';
      case ReportReason.other:
        return 'Other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportReason.spam:
        return Icons.report_gmailerrorred_rounded;
      case ReportReason.harassment:
        return Icons.gpp_bad_rounded;
      case ReportReason.inappropriateContent:
        return Icons.no_adult_content_rounded;
      case ReportReason.fakeProfile:
        return Icons.person_off_rounded;
      case ReportReason.underage:
        return Icons.child_care_rounded;
      case ReportReason.other:
        return Icons.more_horiz_rounded;
    }
  }
}
