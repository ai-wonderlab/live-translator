# App Review remediation — 21 September 2026

## Status

**Not ready to resubmit.** These changes fix verified quality and metadata problems in this repository. They do not establish that Apple's Guideline 4.3(a) concern has been resolved.

The App Store Connect submission of 15 September uses **1.0 (1)** and was rejected on 16 September for similar binary, metadata and/or concept. Build 2 exists, but both builds were uploaded on 8 September. A higher build number is not evidence of a 4.3 fix. The reply requesting specific examples is saved as a draft, not sent.

## Source-to-build mismatch — resolve before uploading

The starting main commit is `43ed621`; the latest app-code change is the 8 July merge `7239f5c`. This source includes optional Supabase accounts, two selected conversation languages, and Apple on-device translation with cloud fallback. September's review notes describe no account functionality and a single target-language workflow. No source commit is recorded for the uploaded builds.

Identify the source/archive used on 8 September and compare it with this branch before merging or uploading. Do not replace the reviewed build with this checkout without that comparison. The checkout also has no app icon asset catalog; restore the actual release assets, do not invent replacements.

## Implemented fixes

- Successful translations charge the measured recording duration, rounded up to one second, rather than a fixed 20 seconds. Translation/network/playback time is excluded; failed translations do not charge. Charges span the free-trial/purchased boundary and cannot exceed the balance.
- “Add time” opens the existing StoreKit purchase sheet instead of the profile screen.
- Purchase copy describes recorded-time billing; onboarding derives the language count (37) from the actual enum.
- Transcript and translation contents are no longer printed to logs.
- Missing, unresolved, and example backend-secret configurations fail locally before a request is sent. No secrets are included in this branch.
- Info.plist reads version/build from Xcode build settings so changing the archive build number is effective.

## Evidence for a reviewer — validate on the actual release build

1. Select the two conversation languages. The speech recognizer listens in the active language and alternates after a successful translation; this is not unrestricted automatic speech-language recognition. Do not claim otherwise in metadata.
2. Hold to speak, release, verify text and spoken output. Check both conversation directions and consecutive turns by the same speaker.
3. Tap “Add time” while signed out. Verify available StoreKit packs and localized prices. No account is required for translation or purchases; optional account screens do exist in this checkout.
4. Record for approximately 3 seconds. On success the balance should decrease by the rounded recording duration, not 20 seconds. Verify silence, translation failure and trial-to-paid rollover.
5. Apple Translation is attempted only for installed language models. Other cases fall back to the backend. Do not claim the complete app works offline: speech recognition and language support have separate constraints.
6. Verify optional login and account deletion against the configured Supabase environment. Presence of source code does not prove the remote deletion function is deployed.

## Before resubmission

- Obtain Apple's concrete 4.3 examples or identify the actual shared/template content from release-source provenance. Prepare evidence of original implementation and distinct functionality; do not assert originality merely because the repository exists.
- Align screenshots, description, review notes, privacy declarations and the selected binary. Copying this document into the current review notes would misdescribe the existing build.
- Verify all intended IAP products: only Credits 5h was included in the rejected submission, while source references four packs.
- Configure the backend secret privately using Secrets.xcconfig; preserve release signing and icon assets from the actual release project.
- Test on a physical device with Sandbox purchases, including interrupted purchases and iCloud balance sync. The existing client-side balance synchronization and transaction-crediting design still require separate validation.
- Archive with a new build number, select that tested build, update review information and then resubmit. Do not repeatedly resubmit unchanged binaries.

References: [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/#spam), especially 4.3 and “Before You Submit”.

## Validation of this branch

- Passed `./tests/run-credit-checks.sh`: duration rounding, invalid durations, free-trial/purchased crossover, balance reload, exhaustion and very large finite durations. Runs the actual CreditManager with isolated UserDefaults and a fake cloud store.
- Passed Swift syntax parsing of all changed Swift files and `plutil -lint` on Info.plist.
- Passed `git diff --check`.
- Full Release simulator build **not completed**: Xcode 26.4 failed during dependency resolution with “Missing or empty JSON output from manifest compilation for supabase-swift”. This is not a successful app build or a device test. The generated standalone check binary also terminated with signal 9; running the same checks with the Swift interpreter passed.
- No backend deployment, archive upload, App Store metadata update or review resubmission has been performed.
