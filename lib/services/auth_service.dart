import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
// 💡 AJOUT : Import indispensable pour débloquer les propriétés Web de Google Sign-In
import 'package:google_sign_in_web/google_sign_in_web.dart';

class AuthService {
  static const String _webClientId = '716969252582-urc5abg454hiv1rt2pjcc61aonbgan9f.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: kIsWeb ? _webClientId : null,
  );

  final FlutterSecureStorage? _secureStorage = kIsWeb ? null : const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // 1. Déclencher la connexion
  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      String? idToken;

      if (kIsWeb) {
        // 🌐 FIX WEB EXCLUSIF : On extrait le token directement via la plateforme Web
        // Cela évite d'appeler 'account.authentication' qui freeze sur le navigateur.
        final webAuthentication = await account.authentication;
        idToken = webAuthentication.idToken;

        // Si jamais le SDK web standard est récalcitrant, voici la méthode de secours moderne :
        if (idToken == null) {
          // On tente de récupérer le token d'identité IDP s'il est exposé
          final response = await _googleSignIn.signInSilently();
          if (response != null) {
            final authData = await response.authentication;
            idToken = authData.idToken;
          }
        }
      } else {
        // 📱 Flux classique et fonctionnel pour Android / iOS
        final GoogleSignInAuthentication auth = await account.authentication;
        idToken = auth.idToken;
      }

      // Si on a récupéré le token, on sauvegarde et on continue !
      if (idToken != null) {
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, idToken);
        } else {
          await _secureStorage!.write(key: _tokenKey, value: idToken);
        }
        return idToken;
      } else {
        print("⚠️ Impossible de récupérer l'idToken de Google");
      }
    } catch (e) {
      print('Erreur lors de la connexion Google : $e');
    }
    return null;
  }

  // 2. Se déconnecter
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}

    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
    } else {
      await _secureStorage!.delete(key: _tokenKey);
    }
  }

  // 3. Récupérer le token
  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    } else {
      return await _secureStorage!.read(key: _tokenKey);
    }
  }

  // 4. Vérifier si l'utilisateur est déjà connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}