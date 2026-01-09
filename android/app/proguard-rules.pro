# WindowManager
-keep class androidx.window.** { *; }
-keep class androidx.window.extensions.** { *; }
-keep class androidx.window.sidecar.** { *; }

# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugin.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# CameraX
-keep class androidx.camera.** { *; }

# JSON
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer