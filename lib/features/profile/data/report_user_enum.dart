import 'package:flutter/material.dart';

enum ReportReason {
  spam,
  harassmentOrBullying,
  sexualContentOrNudity,
  childSafety,
  violenceOrThreats,
  scamsAndFraud,
  fakeProfileOrImpersonation,
  privacyViolation,
  dangerousOrIllegalActivities,
  hateSpeechOrDiscrimination,
  inappropriateContent,
  other,
}

extension ReportReasonExtension on ReportReason {
  String get value {
    switch (this) {
      case ReportReason.spam:
        return 'spam';
      case ReportReason.harassmentOrBullying:
        return 'harassment';
      case ReportReason.sexualContentOrNudity:
      case ReportReason.childSafety:
      case ReportReason.violenceOrThreats:
      case ReportReason.scamsAndFraud:
      case ReportReason.privacyViolation:
      case ReportReason.dangerousOrIllegalActivities:
      case ReportReason.hateSpeechOrDiscrimination:
        return 'other';
      case ReportReason.inappropriateContent:
        return 'inappropriate_content';
      case ReportReason.fakeProfileOrImpersonation:
        return 'fake_profile';
      case ReportReason.other:
        return 'other';
    }
  }

  String get titleKey {
    switch (this) {
      case ReportReason.spam:
        return 'report_reason_spam';
      case ReportReason.harassmentOrBullying:
        return 'report_reason_harassment_bullying';
      case ReportReason.sexualContentOrNudity:
        return 'report_reason_sexual_content_nudity';
      case ReportReason.childSafety:
        return 'report_reason_child_safety';
      case ReportReason.violenceOrThreats:
        return 'report_reason_violence_threats';
      case ReportReason.scamsAndFraud:
        return 'report_reason_scams_fraud';
      case ReportReason.fakeProfileOrImpersonation:
        return 'report_reason_fake_profile_impersonation';
      case ReportReason.privacyViolation:
        return 'report_reason_privacy_violation';
      case ReportReason.dangerousOrIllegalActivities:
        return 'report_reason_dangerous_illegal_activities';
      case ReportReason.hateSpeechOrDiscrimination:
        return 'report_reason_hate_speech_discrimination';
      case ReportReason.inappropriateContent:
        return 'report_reason_inappropriate_content';
      case ReportReason.other:
        return 'report_reason_other';
    }
  }

  IconData get icon {
    switch (this) {
      case ReportReason.spam:
        return Icons.report_gmailerrorred_rounded;
      case ReportReason.harassmentOrBullying:
        return Icons.gpp_bad_rounded;
      case ReportReason.sexualContentOrNudity:
        return Icons.no_adult_content_rounded;
      case ReportReason.childSafety:
        return Icons.child_care_rounded;
      case ReportReason.violenceOrThreats:
        return Icons.warning_amber_rounded;
      case ReportReason.scamsAndFraud:
        return Icons.money_off_rounded;
      case ReportReason.fakeProfileOrImpersonation:
        return Icons.person_off_rounded;
      case ReportReason.privacyViolation:
        return Icons.lock_outline_rounded;
      case ReportReason.dangerousOrIllegalActivities:
        return Icons.dangerous_outlined;
      case ReportReason.hateSpeechOrDiscrimination:
        return Icons.diversity_3_outlined;
      case ReportReason.inappropriateContent:
        return Icons.no_adult_content_rounded;
      case ReportReason.other:
        return Icons.more_horiz_rounded;
    }
  }
}
