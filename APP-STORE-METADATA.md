# Live Translator — App Store Metadata

## Core Metadata

- App Name: Live Translator
- Subtitle: Talk, Translate, Pay As You Go.
- Bundle ID: `gr.easyfair.app` (πρέπει να ταιριάζει με το Xcode project — τρέχον: δες Signing & Capabilities)
- Category: Travel (primary), Utilities (secondary)
- Keywords: live translator, travel translator, voice translator, conversation translator, real-time translation, speak translate, language translation, tourist translator

## Description

The fastest way to talk across languages.
Set two languages. Hold the button. Speak. Hear the translation.
No subscription. Buy hours, use them whenever you travel. First 30 minutes free.

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
4. Language picker: grid of flags — "38 languages"
5. Credits screen: packs displayed — "No subscription. Buy only what you need."
6. Lifestyle: person in foreign city, phone in hand — travel use case

## Review Notes (για Apple)

```
This app requires microphone access to record speech for translation.
In-app purchases are consumable credits for translation time.
To test IAP: use a Sandbox tester account. Tap the credits bar or wait for the paywall.
No login required to use the app. Account is optional (sync); account deletion is available in Profile.
```

## Submission Links (production deployment)

- Privacy URL: https://backend-gamma-eight-88.vercel.app/privacy
- Support URL: https://backend-gamma-eight-88.vercel.app/support
