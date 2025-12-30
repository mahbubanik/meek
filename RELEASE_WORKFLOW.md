# MEEK App Release Workflow

## 📱 Android Release (Play Store)

### Step 1: Generate Signing Key
Run this command in terminal (one-time setup):
```bash
keytool -genkey -v -keystore ~/meek-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias meek-key
```
**IMPORTANT**: Save the password you create! You'll need it for every release.

### Step 2: Create key.properties
Create `android/key.properties`:
```properties
storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=meek-key
storeFile=C:\\Users\\HP\\meek-release-key.jks
```

### Step 3: Update build.gradle.kts
Already configured in `android/app/build.gradle.kts` with the release signing config.

### Step 4: Build Release APK
```bash
cd c:\Users\HP\Downloads\OS\meek_app
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

### Step 5: Build App Bundle (for Play Store)
```bash
flutter build appbundle --release
```
**Output**: `build/app/outputs/bundle/release/app-release.aab`

---

## 🍎 iOS Release (App Store)

### Step 1: Open in Xcode
```bash
cd ios && open Runner.xcworkspace
```

### Step 2: Configure Signing
1. Select "Runner" project
2. Go to "Signing & Capabilities"
3. Select your Apple Developer Team
4. Xcode will auto-create provisioning profile

### Step 3: Build Archive
1. Select "Any iOS Device (arm64)"
2. Product → Archive
3. Window → Organizer → Distribute App

---

## 🚀 Quick Commands

| Action | Command |
|--------|---------|
| Debug APK | `flutter build apk --debug` |
| Release APK | `flutter build apk --release` |
| App Bundle | `flutter build appbundle --release` |
| iOS Build | `flutter build ios --release` |
| Analyze | `flutter analyze` |
| Clean | `flutter clean && flutter pub get` |

---

## 📋 Pre-Release Checklist

- [ ] Update version in `pubspec.yaml` (e.g., `1.0.0+1` → `1.0.1+2`)
- [ ] Test on physical device
- [ ] Verify all API keys are production keys
- [ ] Test notification permissions
- [ ] Review app permissions in manifest
- [ ] Create store listing screenshots
- [ ] Write store description

---

## 🔑 API Keys for Production

Make sure `.env` has production keys:
```env
SUPABASE_URL=your_production_url
SUPABASE_ANON_KEY=your_production_key
GEMINI_API_KEY=your_gemini_key
GROQ_API_KEY=your_groq_key
OPENAI_API_KEY=your_openai_key
```
