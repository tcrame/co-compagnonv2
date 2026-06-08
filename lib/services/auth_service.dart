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

// 💡 CONFIGURATION HYBRIDE SÉCURISÉE :
  // On sépare strictement les besoins du Web et du Mobile lors de l'instanciation
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email'],
    // Le Web a impérativement besoin du clientId
    clientId: kIsWeb ? _webClientId : null,
    // Le Mobile a besoin du serverClientId, mais le Web NE DOIT PAS l'avoir (surtout sur localhost)
    serverClientId: kIsWeb ? null : '716969252582-urc5abg454hiv1rt2pjcc61aonbgan9f.apps.googleusercontent.com',
  );

  // On n'instancie SecureStorage que si on n'est PAS sur le web pour éviter les crashs/blocages
  final FlutterSecureStorage? _secureStorage = kIsWeb ? null : const FlutterSecureStorage();
  static const String _tokenKey = 'jwt_token';

  // 1. Déclencher la connexion
  Future<String?> signIn() async {
    try {
      // 🌐 SÉCURITÉ WEB UNIQUEMENT : On ne nettoie la session fantôme que sur le Web
      if (kIsWeb) {
        try {
          await _googleSignIn.signOut();
        } catch (_) {}
      }

      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) return null;

      String? tokenToSave;

      if (kIsWeb) {
        // 🌐 FLUX WEB : Récupération de l'authentification Web
        final GoogleSignInAuthentication auth = await account.authentication;
        tokenToSave = auth.idToken;

        // Secours Web vers l'accessToken (ya29.) si l'idToken fait de la résistance
        tokenToSave ??= auth.accessToken;

        print("Utilisateur connecté sur le Web : ${account.email}");
      } else {
        // 📱 FLUX MOBILE (Android/iOS) : On extrait STRICTEMENT l'idToken (JWT)
        final GoogleSignInAuthentication auth = await account.authentication;
        tokenToSave = auth.idToken;

        print("Utilisateur connecté sur Mobile : ${account.email}");
      }

      if (tokenToSave != null) {
        if (kIsWeb) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, tokenToSave);

          // Double vérification Web
          final check = prefs.getString(_tokenKey);
          print("[AuthService] Validation immédiate du stockage Web : ${check != null ? 'Succès' : 'ÉCHEC'}");
        } else {
          // 📱 Stockage sécurisé natif Mobile
          await _secureStorage!.write(key: _tokenKey, value: tokenToSave);
          print("[AuthService] Validation immédiate du stockage Mobile : Sauvegardé dans SecureStorage");
        }
        return tokenToSave;
      } else {
        print("⚠️ Impossible de récupérer un jeton (idToken et accessToken sont tous les deux null)");
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