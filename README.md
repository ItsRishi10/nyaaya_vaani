# nyaaya_vaani

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Localization (l10n)

This repository uses Flutter's ARB/gen_l10n workflow. Source English strings live in `lib/l10n/intl_en.arb`. A prefilled Hindi file `lib/l10n/intl_hi.arb` is included to bootstrap translations.

Weblate integration
- A `.weblate.yml` file is present to help Weblate detect ARB components. To connect Weblate:
	1. Create a project on Hosted Weblate (https://hosted.weblate.org/) or your self-hosted Weblate instance.
	2. Add this GitHub repository as a component and point the source file to `lib/l10n/intl_en.arb`.
	3. Configure the file mask as `lib/l10n/intl_%two_letters_code%.arb` so translations are saved back to `lib/l10n/`.
	4. Enable Weblate's push/PR workflow so translations are synchronized as PRs.

CI
- A GitHub Action `l10n-validate.yml` validates ARB changes by running `flutter gen-l10n` and `flutter analyze` on PRs that touch `lib/l10n` files.

Notes
- The project currently has an existing runtime `AppLocalizations` ChangeNotifier implementation. We created a separate generated localization file (`g_app_localizations.dart`) by setting `l10n.yaml` to avoid immediate conflicts. After translations are synchronized you may migrate the app to use the generated localization class and remove the manual implementation.

