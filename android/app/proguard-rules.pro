# Conserver les classes nécessaires pour Google Sign-In
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class com.google.android.gms.common.api.** { *; }

# Conserver les classes pour Flutter Secure Storage (Corrigé !)
-keep class de.jensklingenberg.htmlNativeStorage.** { *; }
-dontwarn com.it_amalgamated.flutter_secure_storage.**