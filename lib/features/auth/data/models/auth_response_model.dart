/// Parsed body of the sign-in endpoints:
/// `{ success, message, data: { user, isNewUser, accessToken, refreshToken,
/// deviceId, requiresOtp } }`.
class AuthResponseModel {
  final bool success;
  final bool hasData;
  final String? message;
  final String? accessToken;
  final String? refreshToken;
  final dynamic deviceId;
  final dynamic user;
  final bool isNewUser;
  final bool requiresOtp;

  const AuthResponseModel({
    required this.success,
    required this.hasData,
    this.message,
    this.accessToken,
    this.refreshToken,
    this.deviceId,
    this.user,
    this.isNewUser = false,
    this.requiresOtp = false,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'];
    return AuthResponseModel(
      success: json['success'] == true,
      hasData: data != null,
      message: json['message']?.toString(),
      accessToken: data?['accessToken'],
      refreshToken: data?['refreshToken'],
      deviceId: data?['deviceId'],
      user: data?['user'],
      isNewUser: data?['isNewUser'] ?? false,
      requiresOtp: data?['requiresOtp'] == true,
    );
  }

  /// True when the response carries a usable signed-in session.
  bool get hasSession => success && hasData && accessToken != null;
}
