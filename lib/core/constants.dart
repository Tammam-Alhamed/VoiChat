import 'package:flutter/foundation.dart';
import 'package:http/http.dart';

class Constants {
  // server host and ports and end points
  static String baseUrl = "https://api.voichat.live/api";
  static String imageUrl = "https://api.voichat.live/";
  static String privacyUrl = "https://api.voichat.live/privacy-policy";
  static String socketServer = "https://api.voichat.live";
  static String sfu = "wss://sfu-st.voichat.live";

  // Shareable profile links: https://api.voichat.live/u/<profileId>. Tapping
  // one opens the app on that profile (see DeepLinkService). Must match the
  // host in AndroidManifest.xml's app-link intent-filter.
  static const String shareHost = "api.voichat.live";
  static String profileLink(String profileId) =>
      "https://$shareHost/u/${Uri.encodeComponent(profileId)}";

  static String googleClientId =
      "231753033001-4kghc9v2n2gqovotaq32udi5qd33o8fm.apps.googleusercontent.com";
  // Http debuger for read errors and status code and info about request
  static void httpDebuger(Response response) {
    if (kDebugMode) {
      // ignore: avoid_print
      print(
        "\n http : ${response.statusCode} => ${response.request!.method} ${response.request!.url} \n ${response.body}",
      );
    }
  }

  // Http Errors
  static int invalidResponse = 100;
  static int noInternet = 101;
  static int invalidFormat = 102;
  static int unKnownError = 103;
  static int unAuthorized = 401;
  static int methodNotAllowed = 403;
  static int badRequest = 400;
}
