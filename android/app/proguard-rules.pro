# flutter_local_notifications persists its scheduled notifications with Gson, and
# Gson's TypeToken needs the generic signature at runtime. In a release build the
# plugin failed with `java.lang.RuntimeException: Missing type parameter` and
# pendingNotificationRequests() threw, so the settings screen's "pending adhan"
# count and cancelAdhan() broke. Keep Gson's model and signatures.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.** { *; }
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.google.gson.**
