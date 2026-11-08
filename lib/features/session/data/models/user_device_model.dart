import '../../domain/entities/user_device.dart';

/// JSON mapping for [UserDevice].
class UserDeviceModel extends UserDevice {
  const UserDeviceModel({
    required super.id,
    required super.userId,
    super.deviceName,
    super.deviceType,
    super.deviceId,
    super.ipAddress,
    super.fcmToken,
    required super.isActive,
    super.lastUsedAt,
    required super.createdAt,
    required super.updatedAt,
  });

  factory UserDeviceModel.fromJson(Map<String, dynamic> json) {
    return UserDeviceModel(
      id: json['id'],
      userId: json['user_id'],
      deviceName: json['device_name'],
      deviceType: json['device_type'],
      deviceId: json['device_id'],
      ipAddress: json['ip_address'],
      fcmToken: json['fcm_token'],
      isActive: json['is_active'] == true || json['is_active'] == 1,
      lastUsedAt: json['last_used_at'] != null
          ? DateTime.parse(json['last_used_at'])
          : null,
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Serialises a [UserDevice] for the local session snapshot.
extension UserDeviceJson on UserDevice {
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'device_name': deviceName,
      'device_type': deviceType,
      'device_id': deviceId,
      'ip_address': ipAddress,
      'fcm_token': fcmToken,
      'is_active': isActive,
      'last_used_at': lastUsedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
