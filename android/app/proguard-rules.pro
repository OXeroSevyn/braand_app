# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Google Services / Firebase
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Supabase / Postgrest (if necessary, usually Kotlin/Java interop is fine but keep just in case)
-keep class io.supabase.** { *; }

# General safety
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# Prevent problems with data classes or serializables if used in native code
-keep class **.R$* { *; }
-keepclassmembers class **.R$* {
    public static <fields>;
}

# Flutter Deferred Components / Play Core (Fix for missing class error)
-dontwarn io.flutter.embedding.engine.deferredcomponents.**
-dontwarn com.google.android.play.**
-dontwarn com.google.android.finsky.**
