// Only keys actually referenced via `.tr` / `.trParams` in the app are kept
// here — every key in this file is wired to a real screen. Add a key only
// once the string it represents is actually used with `.tr`.
const Map<String, String> en = {
  // ─── Auth flow ────────────────────────────────────────────────────────────
  "login_to_account": "Log in to your account",
  "continue_with_google": "Continue with Google",
  "continue_with_phone": "Continue with Phone",
  "continue_with_email": "Continue with Email",
  "footer_age_confirm": "By continuing, you confirm you're 18+ and agree",
  "to_our": "to our",
  "terms_of_use": "Terms of Use",
  "and_conjunction": "and",
  "privacy_policy": "Privacy Policy",

  "select_country": "Select Country",
  "search_country_or_code": "Search country or code",
  "enter_valid_phone_number": "Please enter a valid phone number",
  "failed_to_send_otp": "Failed to send OTP",
  "continue": "Continue",
  "phone_otp_subtitle": "We'll send a verification code to this number.",
  "mobile_number": "Mobile number",

  "enter_your_email": "Enter Your Email",
  "email_otp_subtitle": "Enter your email to continue.",
  "email_address": "Email address",
  "send_otp": "Send",
  "enter_valid_email_address": "Please enter a valid email address",
  "email_not_registered_please_use_google":
      "This email isn't registered. Please continue with Google to sign up.",

  "enter_verification_code": "Enter Verification Code",
  "code_sent_via": "Code was sent to @contact via @method",
  "email": "Email",
  "sms": "SMS",
  "verify": "Verify",
  "resend_code": "Resend code",
  "resend_in": "Resend in @time",
  "code_sent_desc": "A new code has been sent.",
  "failed_to_resend_code": "Failed to resend code",
  "invalid_otp": "Invalid OTP",

  "welcome_exclaim": "Welcome !",
  "enter_name_to_continue": "Enter your name to continue",
  "name": "Name",

  "birthday": "Birthday",
  "select_your_birthdate": "Select Your Birthdate",
  "enter_your_birthday": "Enter your Birthday",
  "go_back_enter_name": "Please go back and enter your name",
  "failed_to_complete_profile": "Failed to complete profile",

  // ─── Account settings ───────────────────────────────────────────────────────
  "account": "Account",
  "personal_info": "Personal Info",
  "phone_number": "Phone Number",
  "other": "Other",
  "report_reason_spam": "Spam",
  "report_reason_harassment_bullying": "Harassment or Bullying",
  "report_reason_sexual_content_nudity": "Sexual Content or Nudity",
  "report_reason_child_safety": "Child Safety",
  "report_reason_violence_threats": "Violence or Threats",
  "report_reason_scams_fraud": "Scams and Fraud",
  "report_reason_fake_profile_impersonation": "Fake Profile or Impersonation",
  "report_reason_privacy_violation": "Privacy Violation",
  "report_reason_dangerous_illegal_activities": "Dangerous or Illegal Activities",
  "report_reason_hate_speech_discrimination": "Hate Speech or Discrimination",
  "report_reason_inappropriate_content": "Inappropriate Content",
  "report_reason_other": "Other",
  "report_user": "Report",
  "report_main_reason": "Main Report Reason:",
  "report_additional_details": "Additional Details (Optional):",
  "report_details_hint": "Write details to help the admin review the account...",
  "report_submit": "Submit Report",
  "join_an_agency": "Join an agency",
  "already_in_agency": "You Are already in Agency",
  "linked_device": "Linked device",
  "see_all_devices_desc": "See all devices connected to this account",
  "language_settings": "Language Settings",
  "delete_account": "Delete account",

  "update_in_progress": "Update in progress...",
  "update_phone_number": "Update Phone Number",
  "update_google_email": "Update Google Email",
  "update_phone_desc":
      "Please enter your valid phone number below to secure your profile access.",
  "update_email_desc":
      "Please enter your active google email address below to bind to your profile.",
  "phone_hint_example": "e.g. +123456789",
  "email_hint_example": "e.g. user@gmail.com",
  "field_cannot_be_empty": "This field cannot be empty",
  "save_changes": "Save Changes",

  "enter_referral_code": "Enter Referral Code",
  "referral_code_desc":
      "Enter the 6-character code from your\ninviter to join their Agency.",
  "enter_code": "Enter code",
  "enter_valid_referral_code": "Please enter a valid referral code",
  "join_agency": "Join Agency",

  "delete_this_account": "Delete this Account",
  "delete_account_desc":
      "Your account will be scheduled for deletion in 30 days.\n"
      "If you log in before then, your account will be reactivated automatically.\n\n"
      "After deletion, all personal data will be permanently removed.\n"
      "This process may take up to one additional day to complete.",
  "all_word": "All",
  "personal_data": "personal data",
  "will_be_removed": "will be removed.",
  "delete_account_coming_soon": "Delete account feature coming soon",
  "confirm_account_deletion": "Confirm Account Deletion",
  "cancel": "Cancel",

  "select_language": "Select Language",
  "choose_preferred_language": "Choose your preferred app language",
  "apply": "Apply",
  "language_set_to": "App language set to @language",

  // ─── Account Center hub ──────────────────────────────────────────────────
  "account_center": "Account Center",
  "profile": "Profile",
  "edit_profile": "Edit Profile",
  "exclusive_features": "Exclusive Features",
  "vip_membership": "VIP Membership",
  "verified_plus": "Verified+",
  "recharge_center": "Recharge Center",
  "creator_hub": "Creator Hub",
  "performance": "Performance",
  "payout": "Payout",
  "payout_available_balance": "Available Balance",
  "payout_amount": "Amount",
  "payout_bank_transfer": "Bank Transfer",
  "payout_agent_payout": "Agent Payout",
  "payout_withdraw": "Withdraw",
  "payout_invalid_amount": "Enter a valid withdrawal amount",
  "payout_amount_exceeds_balance": "Amount exceeds available balance",
  "call_rating": "Call Rating",
  "partner_hub": "Partner Hub",
  "manage_creators": "Manage Creators",
  "invite_link": "Invite link",
  "settings": "Settings",
  "notifications": "Notifications",
  "privacy": "Privacy",
  "display": "Display",
  "display_light": "Light",
  "display_dark": "Dark",
  "display_system": "System",
  "display_system_unavailable": "System theme isn't available yet — pick Light or Dark",
  "display_ok": "OK",
  "support": "Support",
  "contact_support": "Contact Support",
  "contact_support_description": "Get help and assistance from our team.",
  "message_support_hint": "Message Support...",
  "help_and_support": "Help & Support",
  "support_info": "Support Info",
  "help_faq": "Help & FAQ",
  "voichat": "VoiChat",
  "faq_search_hint_detail":
      "Type a keyword to filter questions. Tap any question to open its answer.",
  "clear": "Clear",
  "faq_introduction": "Introduction",
  "faq_intro_body":
      "Welcome to VoiChat! Find answers to common questions about your account, profile, chats, calls, live streams, Coins, gifts, memberships, verification, privacy, and account settings.",
  "faq_intro_support":
      "If you need further assistance, contact the VoiChat Support Team through Support Chat in the app.",
  "faq_footer_support":
      "Need assistance? Contact VoiChat Support through Support Chat in the app.",
  "faq_footer_copyright": "© VoiChat. All rights reserved.",
  "help_faq_description": "Find answers to common questions about VoiChat.",
  "support_chat": "Support Chat",
  "support_chat_description":
      "Contact our support team for further assistance.",
  "faq_search_hint": "Search questions and answers…",
  "faq_no_results": "No matching questions found.",
  "faq_load_error": "Could not load the FAQ.",
  "logins": "Logins",
  "logout": "Logout",
  "app_footer_version":
      "Version 1.1.0\n© 2026 VoiChat. All Rights Reserved\n\n",
  "terms_and_conditions": "Terms And Conditions",

  // ─── Privacy ─────────────────────────────────────────────────────────────
  "hide_country": "Hide Country",
  "hide_country_desc": "Hides your country from other users.",
  "last_time_seen": "Last Time Seen",
  "last_seen_desc": "Others will see when you were last online",
  "total_spend": "Total Spend",
  "total_spend_desc": "Shows how much you have spent in the app.",
  "blocked_users": "Blocked Users",
  "privacy_settings_updated": "Your privacy settings updated successfully",

  // ─── Blocked users ───────────────────────────────────────────────────────
  "failed_load_blocked_users": "Failed to load blocked users",
  "retry": "Retry",
  "no_blocked_users": "No blocked users",
  "unblock": "Unblock",
  "block_user_title": "Block @name?",
  "block_user_warning":
      "You won't be able to see this account's content or communicate with them again after blocking.",
  "confirm_block": "Confirm Block",
  "unblock_success_message": "You can now communicate with @name again.",

  "notifications_subtitle": "All your latest updates appear here",

  // ─── Notification settings ───────────────────────────────────────────────
  "live_stream": "Live Stream",
  "live_notification": "Live Notification",
  "live_notification_desc": "Get notified when your Friends are Live",
  "in_app_sound": "In-App Sound",
  "in_app_vibrations": "In-App Vibrations",

  // ─── Live gift banner ───────────────────────────────────────────────────
  "live_gift_sent": "Sent @gift",
  "live_gift_combo": "Combo",

  // ─── Home shell (bottom nav + exit confirmation) ────────────────────────
  "home": "Home",
  "message": "Message",
  "following": "Following",
  "recent": "Recent",
  "exit_app": "Exit App",
  "exit_app_confirm": "Are you sure you want to exit?",
  "exit": "Exit",
  "access_denied": "Access Denied",

  // ─── Centered content empty states ──────────────────────────────────────
  "no_notifications_yet": "No notifications yet",
  "no_messages_yet": "No messages yet",
  "no_recent_calls": "No recent calls yet",
  "no_live_streams": "No live streams",
  "no_online_users": "No online users yet",
  "no_country_users": "No users found in this country",
  "no_discover_users": "No users found",
  "start_a_conversation": "Start a conversation",
  "pull_down_to_refresh": "Pull down to refresh",
  "no_followings_yet": "No followings yet",
  "no_results_found": "No results found",
  "no_photos_yet": "No Photos Yet",
  "photos_will_appear_here": "Photos you share will appear here.",
  "no_videos_yet": "No Videos Yet",
  "videos_will_appear_here": "When you post videos, they will appear here",

  "user_photos_will_appear_here": "Photos shared by this user will appear here.",
  "user_videos_will_appear_here": "Videos posted by this user will appear here.",

  // ─── Shared error / empty state (AppStateView) ──────────────────────────
  "something_went_wrong": "Something went wrong",
  "check_connection_retry": "Please check your connection and try again.",
  "nothing_here_yet": "Nothing here yet",
  "go_back": "Go Back",

  // ─── Misc ────────────────────────────────────────────────────────────────
  "load more": "Load more",
};
