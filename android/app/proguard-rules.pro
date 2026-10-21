# Flutter's own keep rules are applied by the Flutter Gradle plugin; these
# cover plugins that use reflection or optional dependencies.

# Flutter references Play Core (deferred components) which this app doesn't ship.
-dontwarn com.google.android.play.core.**

# Firebase Messaging / Google Play services
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# Google Maps
-keep class com.google.android.gms.maps.** { *; }

# Geolocator / permission_handler
-keep class com.baseflow.** { *; }

# Syncfusion PDF viewer (pdfium bindings)
-keep class com.syncfusion.** { *; }
-dontwarn com.syncfusion.**

# Keep annotations and generic signatures used by Gson-style reflection.
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod
