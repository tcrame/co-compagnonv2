import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  // ⚠️ TRÈS IMPORTANT : Mettez ici votre Client ID WEB (le même que dans Cloudflare)
  static const String _webClientId = '716969252582-urc5abg454hiv1rt2pjcc61aonbgan9f.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    serverClientId: _webClientId,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // 1. Déclencher la connexion
  Future<String?> signIn() async {
    try {
      // Ouvre la modale Google
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null; // L'utilisateur a annulé

      // Récupère les jetons
      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken != null) {
        // Sauvegarde le token de manière sécurisée sur le téléphone
        await _storage.write(key: _tokenKey, value: idToken);
        return idToken;
      }
    } catch (e) {
      print('Erreur lors de la connexion Google : $e');
    }
    return null;
  }

  // 2. Se déconnecter
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _storage.delete(key: _tokenKey); // On efface le token local
  }

  // 3. Récupérer le token (à utiliser avant chaque requête vers votre Worker)
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // 4. Vérifier si l'utilisateur est déjà connecté au lancement de l'app
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}