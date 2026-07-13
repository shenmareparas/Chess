# Keep Flutter JNI and plugin classes
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep Stockfish JNI classes from being optimized away or renamed
-keep class * {
    native <methods>;
}

# Explicitly keep all classes under packages containing "stockfish"
-keep class **.*stockfish*.** { *; }

# Ignore warnings for missing Play Core classes (deferred components)
-dontwarn com.google.android.play.core.**

