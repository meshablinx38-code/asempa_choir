$pubspec = @'
name: asempa_choir
description: Asempa Choir App - NUPS-G UMaT
publish_to: none
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

  # Firebase - web compatible versions
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
  firebase_storage: ^12.0.0
  firebase_messaging: ^15.0.0
  flutter_local_notifications: ^17.0.0

  # State Management
  flutter_riverpod: ^2.4.10
  go_router: ^13.2.0

  # QR Code
  qr_flutter: ^4.1.0
  mobile_scanner: ^3.5.7

  # PDF
  pdf: ^3.10.8
  printing: ^5.12.0
  path_provider: ^2.1.2

  # Audio
  just_audio: ^0.9.36

  # UI
  cached_network_image: ^3.3.1
  shimmer: ^3.0.0
  intl: ^0.19.0
  uuid: ^4.3.3
  image_picker: ^1.0.7
  permission_handler: ^11.3.0
  share_plus: ^7.2.2
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
  assets:
    - assets/images/
    - assets/icons/
    - assets/animations/
'@

[System.IO.File]::WriteAllText("pubspec.yaml", $pubspec, [System.Text.Encoding]::UTF8)
Write-Host "pubspec.yaml fixed!" -ForegroundColor Green
Write-Host "Now run: flutter pub get" -ForegroundColor Yellow
