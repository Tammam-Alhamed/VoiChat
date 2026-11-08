import '../../app/di/controller_registry.dart';
import '../../core/session/session_manager.dart';
import 'presentation/controllers/navigation_controller.dart';

/// Wires the Home shell (bottom navigation).
void initHomeFeature() {
  registerAppController(() => NavigationController());

  SessionManager.addResetHook(
    () => ifControllerCreated<NavigationController>((c) => c.reset()),
  );
}
