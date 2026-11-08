import 'package:get/get.dart';

/// Registers an app-wide controller. It is created the first time a screen
/// asks for it and then lives for the whole app session (it is never
/// disposed when a route closes).
void registerAppController<T>(T Function() builder) {
  GetInstance().lazyPut<T>(builder, permanent: true);
}

/// Runs [action] only if the controller [T] has already been created, so
/// resetting state never instantiates a controller just to clear it.
void ifControllerCreated<T>(void Function(T controller) action) {
  if (Get.isRegistered<T>() && !Get.isPrepared<T>()) action(Get.find<T>());
}
