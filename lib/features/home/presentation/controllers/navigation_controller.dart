import 'package:get/get.dart';

/// Selected tab of the bottom navigation bar on the Home screen.
class NavigationController extends GetxController {
  int _currentIndex = 0;

  int get currentIndex => _currentIndex;

  void updateIndex(int index) {
    _currentIndex = index;
    update();
  }

  /// Back to the Home tab. Silent by default: used when a new Home screen
  /// is created (fresh login) and on logout, where nothing should rebuild.
  void reset({bool notify = false}) {
    _currentIndex = 0;
    if (notify) update();
  }
}
