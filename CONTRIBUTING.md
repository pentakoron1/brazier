# Contributing to Brazier 🔥

Thank you for your interest in contributing to Brazier! Brazier is a privacy-first, open-source Android app built with Flutter that helps users track the true cost of their belongings over time.

---

## Table of Contents
- [Creating an Issue](#creating-an-issue)
  - [Bug Reports](#bug-reports)
  - [Feature Requests](#feature-requests)
- [Work on Issues (Code Contributions)](#work-on-issues-code-contributions)
  - [Development Setup](#development-setup)
  - [Git Workflow & Pull Requests](#git-workflow--pull-requests)
- [Translating the App](#translating-the-app)
- [Code Style & Privacy Principles](#code-style--principles)

---

## Creating an Issue

Whether you found a bug or have an idea for an improvement, creating an issue is the best place to start. Even if you plan to write the code yourself, please open an issue first so the community knows what you are working on.

**Before creating an issue:**
- Check existing issues to make sure your bug or feature request hasn't already been created.
- Check that you are on the latest version of the app.

### Bug Reports

When filing a bug report, please be as precise as possible. Helpful details include:
- **Device & OS version**: What device and Android version are you using? (e.g., Pixel 7, Android 14)
- **App Version**: What version of Brazier are you running?
- **Steps to Reproduce**: What exact steps reproduce the bug?
- **Expected vs. Actual Behavior**: What did you expect to happen, and what actually happened?
- **Screenshots/Logs**: Screenshots or error logs (if applicable).

### Feature Requests

Have an idea to make Brazier better? When opening a feature request, consider including:
- **The Problem**: What issue or limitation are you trying to address?
- **Proposed Solution**: What is your proposed fix or feature?
- **Alternatives Considered**: Did you consider any alternative solutions or workarounds?
- **Visuals**: Feel free to attach pictures, sketches, or mockups to better describe your idea.

---

## Work on Issues (Code Contributions)

If you have some programming knowledge, we welcome your direct code contributions!

### Tips for Getting Started
- **Start Small**: If it's your first time contributing, look for issues labeled `good first issue`.
- **Comment First**: Consider commenting on an issue before you start working on it. Share your implementation plan so a maintainer can assign the issue to you—especially for new contributors or large changes.

### Development Setup

1. **Prerequisites**:
   - [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable version)
   - Android SDK (API 34+)

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/your-username/brazier.git
   cd brazier
   ```

3. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

### Git Workflow & Pull Requests

1. **Create a New Branch**:
   Name your branch after the issue you are working on (e.g., `fix/issue-123` or `feature/monthly-review-ui`).
   ```bash
   git checkout -b fix/issue-123
   ```

2. **Make & Test Your Changes**:
   Verify code formatting, static analysis, and unit tests:
   ```bash
   dart format .
   flutter analyze
   flutter test
   ```

3. **Commit & Push**:
   ```bash
   git add .
   git commit -m "fix: resolve monthly cost calculation rounding (#123)"
   git push origin fix/issue-123
   ```

4. **Open a Pull Request**:
   - Reference the issue it addresses in the PR description (e.g., `Fixes #123`).
   - Include screenshots or short screen recordings for any UI changes.
   - Maintainers will review your PR and merge it once approved.

---

## Translating the App

You don't need programming knowledge to contribute! Helping translate the app makes Brazier accessible to more users worldwide.

### Focused Languages
- English (`en`)
- Spanish (`es`)
- German (`de`)
- French (`fr`)
- Hindi (`hi`)

*(You are also welcome to add any new language not listed above!)*

### How to Translate:

1. **Locate Localization Files**:
   Translations are stored as ARB files under `lib/l10n/`.
   - `lib/l10n/app_en.arb` is the main template file.
2. **Edit or Add a Language File**:
   - To update an existing translation, edit `lib/l10n/app_<locale>.arb` (e.g., `app_fr.arb`).
   - To add a new language, create a new file named `app_<locale>.arb` in `lib/l10n/`.
3. **Format ARB Entries**:
   ```json
   {
     "@@locale": "fr",
     "appTitle": "Brazier"
   }
   ```
4. **Test Translations Locally**:
   Run `flutter gen-l10n` or `flutter run` to generate and verify localization classes.
5. **AI Translation Guidelines**:
   You may use AI tools to assist with translations, but you should speak or be familiar with the target language so you can review and verify that the generated translations are accurate and natural.

---

## Code Style & Principles

- **Dart Style Guidelines**: Enforced via `analysis_options.yaml`. Run `dart format .` and `flutter analyze` before committing.
- **Strict Privacy-First**: Brazier is 100% offline and F-Droid compliant. Do **not** add network permissions, tracking, telemetry, ads, or non-FOSS SDKs.
- **No Hardcoded Strings**: All user-facing text must be added to `lib/l10n/app_en.arb` rather than hardcoded in UI widgets, so that it can be easily translated.
