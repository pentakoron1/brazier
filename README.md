# Brazier 🔥

**Track the true monthly cost of your items and purchases.**

Brazier is a privacy-first, open-source Android application built with Flutter that helps you calculate and track the actual value and monthly cost of your physical belongings over time.

To download the app
---
  ### *!!! Be one of the first testers for Playstore*
_If you want to be part of the first testers so that the app can be published on playstore, please join this group: https://play.google.com/apps/testing/dev.pentakoron.brazier_

> We need at least 12 testers for 2 weeks to be able to publish the app, so thanks for joining!

  ### Before 2027 on F-droid 
The F-droid platform requires app to be maintained for at least 3 months before being published, that means we could get it available for everyone just before 2027!

> Meanwhile, you can still download on your phone just by downloading the .apk file on your phone, or via the obtainium app if you want automatic updates.

  ### Other platforms 
Once the app will get a bit more mature, is also planned to release it on linux and windows, or maybe just as a website/web extension.

> Don't forget to star the repo until then!🌟




## ✨ Features

- **True Cost Calculation**: Compare your goal cost-per-month against your real usage rate.
- **Monthly Usage Review**: Swipe right if used, left if not used, with smooth cards, exit animations, and haptic feedback.
- **Usage Winstreaks**: Earn streak fire badges for consistent monthly item usage.
- **Overview & Statistics**: Analyze total spend, average monthly rates, category distributions, and goal reach milestones.
- **Custom Categories**: Create, edit, and organize items with custom icons, colors, and names.
- **100% Offline & Private**: Zero telemetry, zero ads, zero tracking, and no internet permission required. All data is stored locally using `SharedPreferences`.
- **Material 3 UI**: Full support for Dark Mode and Light Mode.

---

## 📱 Screenshots

|                          Items View                           |                               Monthly Review                                |                        Statistics Overview                         |
|:-------------------------------------------------------------:|:---------------------------------------------------------------------------:|:------------------------------------------------------------------:|
| ![Items view](/assets/screenshots/Brazier_items.png?raw=true) | ![Items view](/assets/screenshots/Brazier_monthly-review_used.png?raw=true) | ![Items view](/assets/screenshots/Brazier_statistics.png?raw=true) |

## 🛠️ Building From Source

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.13+ or latest stable)
- Android SDK (API 34+)

### Build APK
```bash
git clone https://github.com/your-username/brazier.git
cd brazier
flutter pub get
flutter build apk --release
```
The compiled APK will be located at:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 📦 F-Droid

Brazier is built to comply strictly with [F-Droid Inclusion Policy](https://f-droid.org/docs/Inclusion_Policy/):
- **100% Free and Open Source Software (FOSS)**
- **No Proprietary Dependencies**: Free of Google Play Services, Firebase, or non-free SDKs.
- **No Anti-Features**: Zero ads, zero tracking, zero telemetry.

---

## 📄 License

Brazier is released under the [GNU General Public License v3.0 (GPL-3.0)](LICENSE).
