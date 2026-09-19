# JARVIS V1.1 Secure Edition

Security-focused Flutter starter.

## Included
- Device authentication using Android/iOS biometric/PIN via `local_auth`
- Authentication gate before entering JARVIS
- Authentication before voice commands
- Secure settings gate
- Speech input/output
- Local notes
- Futuristic UI

## Important security limitation
This starter does NOT claim that speaker verification is already implemented. True voice enrollment/speaker verification requires a dedicated speaker-recognition model and secure local storage. The current build uses device authentication as the security boundary.

## Run
flutter pub get
flutter run

Never put an AI provider secret/API key directly in the mobile app. Use a secure backend.
