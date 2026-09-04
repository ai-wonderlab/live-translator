# Live Translator Submission Checklist

- Apple Developer account active and ready for submission
- Bundle ID `gr.easyfair.app` registered in Apple Developer, with iCloud (Key-Value storage) capability enabled
- App Icon (1024×1024, no alpha) in Assets.xcassets
- Backend redeployed to Vercel with rotated `APP_SECRET` (matches `Secrets.xcconfig`); `/privacy` shows "Last updated: September 4, 2026"
- Enrolled in App Store Small Business Program (15% commission)
- In-App Purchase product IDs created for translation time packs
- TestFlight configured for internal and external testing
- Screenshots for iPhone 6.9-inch (required) and 6.5-inch (optional, recommended)
- App Store Connect metadata completed: app name, subtitle, keywords, description, categories, support URL, marketing/support details
- Privacy policy URL added in App Store Connect
- Review notes prepared for microphone permissions and IAP sandbox testing (see APP-STORE-METADATA.md)
- TestFlight E2E: sandbox purchase → force-quit → relaunch → balance persists; credits=0 → paywall → purchase → mic unlocks; airplane mode → clear error
