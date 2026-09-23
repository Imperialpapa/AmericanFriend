## flutter_local_notifications (18.x) — README "Release build configuration"
# 플러그인은 예약 알림을 Gson으로 직렬화해 저장하고, 알림 시각·재부팅·앱 업데이트 때 다시 읽는다.
# Gson 2.8.9에는 R8 규칙이 들어 있지 않아, AGP 8의 R8 full mode에서 TypeToken 제네릭 정보가 지워지면
# release 빌드에서만 zonedSchedule/리시버가 "Missing type parameter"로 실패한다.

## Gson rules (flutter_local_notifications example/android/app/proguard-rules.pro)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# 저장된 JSON은 필드 이름으로 읽는다. 난독화 이름은 빌드마다 바뀌므로, 앱 업데이트 후
# MY_PACKAGE_REPLACED 재예약이 이전 빌드의 JSON을 못 읽지 않게 모델 필드 이름을 고정한다.
-keep class com.dexterous.flutterlocalnotifications.models.** { *; }
