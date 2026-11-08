import 'constants.dart';

class AssetsManager {
  static const String noConnection = "assets/images/noconnection.png";

  static const String empty = 'assets/images/empty-box.png';

  // svg myprofile
  static const String setting = "assets/icons/setting.svg";
  static const String share = "assets/icons/share.svg";
  static const String addPhoto = "assets/icons/add_photo.svg";
  static const String addVideo = "assets/icons/add_video.svg";
  static const String liveVideoButton = "assets/icons/video_live.svg";

  // svg follwings
  static const String videoFollwing = "assets/icons/video_follwing.svg";
  static const String chatFollwing = "assets/icons/chat_follwing.svg";
  static const String light = "assets/icons/light.svg";
  static const String dark = "assets/icons/dark.svg";
  static const String system = "assets/icons/system.svg";
  static const String block = "assets/icons/block.svg";
  static const String search = "assets/icons/search.svg";

  //live
  static const String svip = "assets/icons/svip.svg";
  static const String vip = "assets/icons/vip.svg";
  static const String liveVideoPink = "assets/icons/live_video_pink.svg";
  static const String giftSm = "assets/icons/gift-sm.png";

  // live room toolbar — exact assets exported from the Figma live-streaming
  // screen, used as-is (native colors baked into each file).
  static const String liveSwitchCamera = "assets/icons/live_switch_camera.svg";
  static const String liveMute = "assets/icons/live_mute.svg";
  static const String liveMuteActive = "assets/icons/live_mute_active.svg";
  static const String livePremium = "assets/icons/live_premium.svg";
  static const String liveChat = "assets/icons/live_chat.svg";
  static const String liveStart1on1 = "assets/icons/live_start_1on1.svg";
  // These two are PNG, not SVG: the originals were SVGs wrapping a
  // pattern-filled <image> (a raster baked in via a Figma export), which
  // flutter_svg can't reliably render — the icon just came out blank. The
  // raw PNGs were extracted from those SVGs instead; live_call_off.png is
  // the plain white handset, with the diagonal "off" slash drawn on top in
  // code (see _buildCallOffIcon) to reproduce the vector line the original
  // SVG drew separately.
  static const String liveCallOff = "assets/icons/live_call_off.png";
  static const String liveCallOffActive =
      "assets/icons/live_call_off_active.png";
  static const String liveFilter = "assets/icons/live_filter.svg";

  //profile
  static const String defaultProfileImage =
      "assets/images/default_profile_image.png";

  static String getNetworkImagePath(String image) {
    if (image.startsWith("http")) {
      return image;
    }
    return Constants.imageUrl + image;
  }
}
