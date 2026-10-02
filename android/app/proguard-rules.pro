# Flutter ProGuard / R8 Optimization Rules

# Flutter engine wrappers
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Play Core & Flutter Deferred Components (optional engine dependencies)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication

# Google Mobile Ads SDK (suppress missing inner class reflection warnings)
-dontwarn com.google.android.gms.internal.ads.**
-dontwarn com.google.android.gms.ads.**
-keep class com.google.android.gms.ads.** { *; }

# Google Play Billing SDK (suppress missing enclosing method reflection warnings)
-dontwarn com.google.android.gms.internal.play_billing.**
-dontwarn com.android.billingclient.**
-keep class com.android.billingclient.api.** { *; }

# Firebase & Google Play Services
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Gson
-dontwarn com.google.gson.**
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
