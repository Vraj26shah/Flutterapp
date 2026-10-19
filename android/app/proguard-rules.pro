# Flutter Proguard Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.autofill.**  { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep shared preferences plugin and Pigeon generated code
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class dev.flutter.plugins.** { *; }

# Keep MethodChannel Handlers
-keep class * implements io.flutter.plugin.common.MethodChannel$MethodCallHandler { *; }
