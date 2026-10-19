# BabyDaily — Release & Deployment Guide

This guide covers building and releasing BabyDaily for Web, Google Play Store (Android), and Apple App Store (iOS), as well as deploying the backend to Vercel.

---

## 1. Architecture & Environments

- **Development**:
  - Flutter Web: `http://localhost:8080` (or local IP `http://10.0.0.34:8080` on local Wi-Fi)
  - Backend API: `http://localhost:5050`
  - When accessing web from phone on Wi-Fi, the app automatically connects to `http://<host>:5050` in debug mode.
- **Production**:
  - Backend API on Vercel: `https://baby-daily-api.vercel.app` (or your custom domain)
  - Flutter Web on Vercel: `https://baby-daily.vercel.app`
  - In release builds, `ApiClient` automatically targets the production URL unless overridden via `--dart-define=API_URL=<custom_url>`.

---

## 2. Backend Deployment on Vercel

The backend Fastify/Prisma application is configured for Vercel Serverless Functions (`backend/vercel.json` + `backend/api/index.js`).

### Step 1: Link & Add Environment Variables
From the `backend` directory:
```bash
cd backend
npx vercel link
```

Set the following required production environment variables:
```bash
npx vercel env add DATABASE_URL production
npx vercel env add DIRECT_URL production
npx vercel env add JWT_SECRET production
npx vercel env add CORS_ORIGINS production    # set to * or your frontend domain
npx vercel env add APP_URL production         # e.g., https://baby-daily.vercel.app
npx vercel env add RESEND_API_KEY production  # your Resend API key for invite emails
npx vercel env add EMAIL_FROM production      # e.g., BabyDaily <notifications@yourdomain.com>
npx vercel env add CRON_SECRET production     # secret token for /cron/tick
```

### Step 2: Deploy Backend to Production
```bash
npx vercel --prod
```

Verify deployment:
```bash
curl https://<your-vercel-api-domain>/health
# Expected: {"status":"ok","time":"..."}
```

---

## 3. Flutter Web Release Build & Vercel Hosting

### Step 1: Build Web Bundle
From the `app` directory:
```bash
cd app
flutter build web --release --dart-define=API_URL=https://<your-vercel-api-domain>
```

### Step 2: SPA Rewrite Configuration
Ensure `app/build/web/vercel.json` contains:
```json
{
  "rewrites": [
    { "source": "/(.*)", "destination": "/index.html" }
  ]
}
```

### Step 3: Deploy Web App
```bash
cd build/web
npx vercel --prod
```

---

## 4. Google Play Store (Android) Build

> **Note on Local Environment**: Building an Android App Bundle (`.aab`) requires the Android SDK and Java (JDK 17+), which should be installed on your development workstation or CI/CD runner.

### Step 1: Generate Release Keystore (one-time)
```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### Step 2: Create `android/key.properties`
```properties
storePassword=<your-store-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=upload-keystore.jks
```

### Step 3: Build Android App Bundle (.aab)
```bash
cd app
flutter build appbundle --release --dart-define=API_URL=https://<your-vercel-api-domain>
```
Output artifact: `build/app/outputs/bundle/release/app-release.aab`.

Upload this file to the **Google Play Console** under **Internal Testing** or **Production**.

---

## 5. Apple App Store (iOS) Build

> **Note on Local Environment**: Building an iOS archive (`.ipa`) requires a Mac with Xcode and an active Apple Developer Program membership.

### Step 1: Open project in Xcode
```bash
open app/ios/Runner.xcworkspace
```
1. Select the `Runner` target.
2. In **Signing & Capabilities**, select your Apple Developer **Team**.
3. Confirm the Bundle Identifier is `com.babydaily.baby_daily`.

### Step 2: Build IPA
```bash
cd app
flutter build ipa --release --dart-define=API_URL=https://<your-vercel-api-domain>
```
Output artifact: `build/ios/archive/Runner.xcarchive` (or `build/ios/ipa/Runner.ipa`).

Upload to **TestFlight** / **App Store Connect** directly from Xcode Organizer or via:
```bash
xcrun altool --upload-app --type ios --file build/ios/ipa/Runner.ipa \
  --username "your-apple-id" --password "app-specific-password"
```

---

## 6. Store Assets Checklist
- App Icon: `branding/app-icon-1024.png` (used for 1024x1024 store icon).
- Play Store Feature Graphic: `branding/feature-graphic-1024x500.png`.
- Store descriptions and metadata: see [STORE_LISTING.md](STORE_LISTING.md).
