# Releasing 아는척 to Google Play

Application id: `com.eunwon.aneuncheok` (permanent once uploaded).
Version: `version: 1.0.0+1` in `pubspec.yaml`. The number after `+` is the
Android `versionCode`; **raise it for every upload** or Play rejects the bundle.

## 1. One-time: create an upload key (on your own machine)

```sh
keytool -genkey -v -keystore ~/upload-keystore.jks -storetype JKS \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Keep `upload-keystore.jks` and its passwords somewhere safe and backed up. Never
commit them (they are git-ignored). Then copy `android/key.properties.example` to
`android/key.properties` and fill it in.

Play App Signing keeps the real app-signing key; this is only your *upload* key,
and Google can reset it if you lose it.

## 2. Build the bundle

```sh
flutter pub get
flutter build appbundle --release
# -> build/app/outputs/bundle/release/app-release.aab
```

Without `android/key.properties` Gradle prints a warning and signs with the debug
key. Google Play rejects such a bundle, so check the warning is gone.

The build targets API 36 (`flutter.targetSdkVersion`), which meets Google Play's
current requirement for new apps. The Android build config was prepared without an
Android SDK and has not been built yet, so run the build above and try the app
with `flutter run --release` on a phone before you upload.

## 3. Play Console checklist

1. **Create app**: name 아는척, default language Korean, App, Free, accept the declarations.
2. **Testing, Closed testing**: create a track, upload the `.aab`, add testers.
   For a *personal* developer account created after 13 Nov 2023, Google requires
   a closed test with at least 12 testers opted in for 14 days in a row before you
   can apply for production ([Google's rules](https://support.google.com/googleplay/android-developer/answer/14151465)).
   Organization accounts are exempt.
3. **App content** (all required):
   - Privacy policy URL (publish a page first; the app collects no data, say so).
   - App access: everything works without logging in.
   - Ads: none. Government / financial features: none.
   - Content rating (IARC questionnaire). It is an educational quiz app.
   - Target audience: it is aimed at young people. Choosing an age group that
     includes under-13s brings in Google's Families policies, so decide this on purpose.
   - Data safety: the app has no `INTERNET` permission and makes no network
     calls; progress is stored on the device only. Update this the day a real
     social backend is added.
   - If asked about health features: the 건강 cards are general information, not medical advice.
4. **Store listing**: use the files in `assets/store/`
   - `icon-512.png` (512x512 app icon)
   - `feature-graphic.png` (1024x500)
   - `screenshots/phone-*.png` (1080x2160). Retake them if the UI changes.
     The home screenshot shows the friend-rank teaser, which is **simulated data**
     (see below); retake it without that if the social features are not real yet.

## Listing text (draft, Korean)

- Title (max 30): `아는척 - 생활 상식 카드`
- Short description (max 80): `하루 5장, 짧은 카드로 배우는 생활 상식! 퀴즈와 복습으로 오래 기억해요.`
- Full description:

  ```
  아는척은 생활 속 꼭 알아야 할 상식을 짧은 카드로 배우는 앱이에요.

  • 243개의 상식 카드: 생활, 건강, 음식, 돈, 안전, 몸, 과학, 디지털, 환경, 말과 글
  • "몰랐어요! / 알고 있었어요" 반응으로 나만의 학습 기록 만들기
  • 몰랐던 상식은 1일, 3일, 7일, 14일, 30일 뒤에 복습 카드로 다시 만나요
  • 퀴즈 챌린지: 설명을 보고 어떤 상식인지 맞혀 보세요
  • 경험치, 레벨, 연속 접속, 28개의 배지로 꾸준히 배우는 재미
  ```

  (Do not mention friends or live rankings until a real backend exists.)

## Before you submit to production

- Social features run on simulated players (`DemoSocialRepository`, labeled
  "🧪 데모 모드"). Either build a real backend (see the README) or hide the ranking
  tab, and keep the listing honest either way.
- A human should read the health, safety, money and labor-law cards.
