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
-keep class **.*stockfish*.** { *; }

# Keep AudioPlayers plugin
-keep class xyz.luan.audioplayers.** { *; }

# Keep Play Services (AdMob & Play Games Services)
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep In-App Update / Play Core
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Keep AndroidX Startup, WorkManager & Room Database
-keep class androidx.startup.** { *; }
-keep class androidx.work.** { *; }
-keep class androidx.work.impl.** { *; }
-keep class androidx.room.** { *; }
-dontwarn androidx.work.impl.**
-keep class * extends androidx.room.RoomDatabase { *; }
-keepclassmembers class * extends androidx.room.RoomDatabase {
    <init>(...);
}

# Keep Android WebKit and JavascriptEngine interfaces for AdMob
-keep class android.webkit.** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Preserve annotations and signatures for reflection
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod