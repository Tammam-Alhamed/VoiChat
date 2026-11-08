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
  "email_not_registered_please_use_google": "This email isn't registered. Please continue with Google to sign up.",

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
  "call_rating": "Call Rating",
  "partner_hub": "Partner Hub",
  "manage_creators": "Manage Creators",
  "invite_link": "Invite link",
  "settings": "Settings",
  "notifications": "Notifications",
  "privacy": "Privacy",
  "display": "Display",
  "support": "Support",
  "support_chat": "Support Chat",
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

  // ─── Notification settings ───────────────────────────────────────────────
  "live_stream": "Live Stream",
  "live_notification": "Live Notification",
  "live_notification_desc": "Get notified when your Friends are Live",
  "in_app_sound": "In-App Sound",
  "in_app_vibrations": "In-App Vibrations",

  // ─── Home shell (bottom nav + exit confirmation) ────────────────────────
  "home": "Home",
  "message": "Message",
  "following": "Following",
  "recent": "Recent",
  "exit_app": "Exit App",
  "exit_app_confirm": "Are you sure you want to exit?",
  "exit": "Exit",
  "access_denied": "Access Denied",

  // ─── Shared error / empty state (AppStateView) ──────────────────────────
  "something_went_wrong": "Something went wrong",
  "check_connection_retry": "Please check your connection and try again.",
  "nothing_here_yet": "Nothing here yet",
  "go_back": "Go Back",

  // ─── Misc ────────────────────────────────────────────────────────────────
  "load more": "Load more",
};
