import '../../domain/entities/session_data.dart';
import 'session_user_model.dart';
import 'user_device_model.dart';

/// JSON mapping for [SessionData], used for both the server response and
/// the local snapshot.
class SessionDataModel extends SessionData {
  SessionDataModel({
    super.user,
    required super.isBlocked,
    required super.country,
    required super.unseen,
    required super.unReadMessages,
    required super.userDevices,
  });

  factory SessionDataModel.fromJson(Map<String, dynamic> json) {
    return SessionDataModel(
      user: json['user'] != null
          ? SessionUserModel.fromJson(json['user'])
          : null,
      isBlocked: json['isBlocked'] ?? false,
      country: json['country'] ?? '',
      unseen: json['unseen'] ?? 0,
      unReadMessages: json['un_read_messages'] ?? 0,
      userDevices:
          (json['user_devices'] as List<dynamic>?)
              ?.map((e) => UserDeviceModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// Serialises [SessionData] for the local snapshot.
extension SessionDataJson on SessionData {
  Map<String, dynamic> toJson() {
    return {
      'user': user?.toJson(),
      'isBlocked': isBlocked,
      'country': country,
      'unseen': unseen,
      'un_read_messages': unReadMessages,
      'user_devices': userDevices.map((e) => e.toJson()).toList(),
    };
  }
}
