import 'package:flutter/foundation.dart'; // Pour kIsWeb
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  // 💡 FIX SINGLETON : Garantit qu'une seule et unique instance d'AuthService
  // existe dans toute l'application et partage le stockage.
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();
  static const String _webClientId = '716969252582-urc5abg454hiv1rt2pjcc61aonbgan9f.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    clientId: kIsWeb ? _webClientId : null,
  );

  // On n'instancie SecureStorage que si on n'est PAS sur le web pour éviter les crashs/blocages
  final FlutterSecureStorage? _secureStorage = kIsWeb ? null : const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // 1. Déclencher la connexion
  Future<String?> signIn() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      String? tokenToSave;

      // Récupération de l'authentification
      final GoogleSignInAuthentication auth = await account.authentication;
      tokenToSave = auth.idToken;

      // Secours si le premier jet est null sur le web
      if (kIsWeb && tokenToSave == null) {
        final silentAccount = await _googleSignIn.signInSilently();
        if (silentAccount != null) {
          final silentAuth = await silentAccount.authentication;
          tokenToSave = silentAuth.idToken;
        }
      }

      if (tokenToSave != null) {
        // Sauvegarde adaptée à la plateforme
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, tokenToSave);
        } else {
          await _secureStorage!.write(key: _tokenKey, value: tokenToSave);
        }
        print("✅ Token (JWT) sauvegardé avec succès pour l'email : ${account.email}");
        return tokenToSave;
      } else {
        print("⚠️ Impossible de récupérer l'idToken de Google.");
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

  // 3. Récupérer le token (C'est cette méthode que ton service de Sync doit appeler !)
  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      print("[AuthService] Token récupéré sur le Web : ${token != null ? 'Présent (JWT)' : 'NULL'}");
      return token;
    } else {
      return await _secureStorage!.read(key: _tokenKey);
    }
  }

  // 4. Vérifier si l'utilisateur est connecté
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}