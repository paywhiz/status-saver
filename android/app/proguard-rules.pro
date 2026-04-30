# Project-specific R8 / ProGuard rules.
#
# The Flutter Gradle plugin and each Flutter plugin (saf_util, video_player,
# gal, share_plus, file_picker, receive_sharing_intent, shared_preferences,
# path_provider) ship their own consumer-rules.pro, so most keep-rules are
# handled automatically.
#
# Add a -keep here only if a release build crashes with NoClassDefFoundError /
# NoSuchMethodError that the default config doesn't already cover.
