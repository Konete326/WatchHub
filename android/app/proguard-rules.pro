# Stripe Android - Keep push provisioning classes
-keep class com.stripe.android.pushProvisioning.** { *; }
-keepclassmembers class com.stripe.android.pushProvisioning.** { *; }

# Keep all Stripe SDK classes
-keep class com.stripe.android.** { *; }
-dontwarn com.stripe.android.**

# Keep React Native Stripe SDK classes
-keep class com.reactnativestripesdk.** { *; }
-dontwarn com.reactnativestripesdk.**
