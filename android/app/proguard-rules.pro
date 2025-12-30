# Add project specific ProGuard rules here.
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn io.flutter.embedding.**

# Keep Supabase
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

# Keep notification classes
-keep class com.dexterous.** { *; }
