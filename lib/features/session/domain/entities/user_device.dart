/// A device (phone) that currently holds a session for the user.
class UserDevice {
  final String id;
  final String userId;
  final String? deviceName;
  final String? deviceType;
  final String? deviceId;
  final String? ipAddress;
  final String? fcmToken;
  final bool isActive;
  final DateTime? lastUsedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserDevice({
    required this.id,
    required this.userId,
    this.deviceName,
    this.deviceType,
    this.deviceId,
    this.ipAddress,
    this.fcmToken,
    required this.isActive,
    this.lastUsedAt,
    required this.createdAt,
    required this.updatedAt,
  });
}
