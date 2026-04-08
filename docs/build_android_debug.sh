#!/usr/bin/env bash

set -euo pipefail

echo "🛠️ Baue Android Debug-APK (DeveloperMode aktiv)"

command -v flutter >/dev/null 2>&1 || { echo "❌ flutter nicht gefunden"; exit 1; }

flutter clean >/dev/null 2>&1 || true
flutter pub get

echo "🏗️ Build APK (debug)"
flutter build apk --debug --dart-define=DEVELOPER_MODE=true

APK="build/app/outputs/flutter-apk/app-debug.apk"
if [[ ! -f "$APK" ]]; then
  echo "❌ APK nicht gefunden: $APK"
  exit 1
fi

echo "✅ APK gebaut: $APK"
echo ""
echo "📲 Installation per ADB:"
echo "   adb install -r \"$APK\""
echo ""
echo "🧪 Logs ansehen:"
echo "   adb logcat | grep -i flutter"
echo "   adb logcat | grep -E 'Cloud-Sync|HiDrive|WebDAV|PUT|GET|LIST'"
echo ""
