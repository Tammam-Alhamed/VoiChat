import 'package:google_sign_in/google_sign_in.dart';

import '../../../../core/constants.dart';
import '../../../../core/error/exceptions.dart';

/// Native Google sign-in, used only to obtain an ID token for the backend.
abstract class GoogleAuthDataSource {
  /// Shows the Google account picker and returns the ID token, or null when
  /// the user closed the picker.
  Future<String?> signIn();
}

class GoogleAuthDataSourceImpl implements GoogleAuthDataSource {
  @override
  Future<String?> signIn() async {
    final googleSignIn = GoogleSignIn(
      clientId: Constants.googleClientId,
      scopes: ['email', 'profile'],
    );

    // Always show the account picker instead of silently reusing the last
    // account.
    if (await googleSignIn.isSignedIn()) {
      await googleSignIn.signOut();
    }

    final account = await googleSignIn.signIn();
    if (account == null) return null;

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null) {
      throw ServerException(
        code: Constants.unKnownError,
        message: 'Failed to get Google authentication token',
      );
    }
    return idToken;
  }
}
