# Live Translator — App Store Metadata

> Release note (21 September 2026): this document describes repository source, not the verified September binary. Resolve the source/build mismatch in `APP-REVIEW-2026-09-21.md` before updating App Store Connect.

## Core Metadata

- App Name: Live Translator
- Subtitle: Talk, Translate, Pay As You Go.
- Bundle ID: `gr.easyfair.app` (πρέπει να ταιριάζει με το Xcode project — τρέχον: δες Signing & Capabilities)
- Category: Travel (primary), Utilities (secondary)
- Keywords: live translator, travel translator, voice translator, conversation translator, real-time translation, speak translate, language translation, tourist translator

## Description

Talk across languages with a hold-to-speak conversation flow.
Set two languages. Hold the button. Speak. Hear the translation.
No subscription. Buy translation time when you need it. First 30 minutes free. Successful translations use recorded time, rounded up to a second; processing and playback time are not charged.

## In-App Purchases (πρέπει να ταιριάζουν με StoreManager.swift)

| Product ID | Τύπος | Τίτλος |
|-----------|-------|--------|
| `gr.easyfair.credits.1h` | Consumable | 1 Hour |
| `gr.easyfair.credits.5h` | Consumable | 5 Hours |
| `gr.easyfair.credits.10h` | Consumable | 10 Hours |
| `gr.easyfair.credits.50h` | Consumable | 50 Hours |

> ⚠️ Τιμές: αποφασίζονται στο App Store Connect — το app δείχνει πλέον `product.displayPrice`, οπότε ό,τι οριστεί εκεί εμφανίζεται σωστά. (Παλιές αναφορές: HANDOFF $9.99/10h, παλιό paywall €6.99/10h — μία απόφαση, ένα μέρος.)

## App Privacy (nutrition labels)

- Contact Info → Email Address: collected, linked to user, **μόνο** για app functionality (optional account)
- Δεν γίνεται tracking. Δεν συλλέγεται audio.

## Screenshot Descriptions

1. Hero: dark screen, one big button, two flags — "One button. Two languages."
2. Recording state: button glowing red — "Hold to speak"
3. Translation displayed: transcript plus translation text — "Instant translation"
4. Language picker: grid of flags — "37 languages"
5. Credits screen: packs displayed — "No subscription. Buy only what you need."
6. Lifestyle: person in foreign city, phone in hand — travel use case

## Review Notes (για Apple)

```
This app requires microphone access to record speech for translation.
In-app purchases are consumable credits for translation time.
To test IAP: use a Sandbox tester account. Tap the credits bar or wait for the paywall.
No login is required to translate or purchase time. This repository includes optional accounts; account deletion is available in Profile and must be tested against the deployed backend.
Choose two languages before speaking. Speech recognition starts in the first language and alternates after each successful translation.
Translation first attempts Apple on-device models when installed, otherwise it uses our cloud service. This does not guarantee offline speech recognition.
Successful translations charge recorded duration rounded up to one second. Network processing and speech playback are not charged.
```

## Submission Links (production deployment)

- Privacy URL: https://backend-gamma-eight-88.vercel.app/privacy
- Support URL: https://backend-gamma-eight-88.vercel.app/support
