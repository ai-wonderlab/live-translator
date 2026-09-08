# Live Translator — App Store Metadata

## Core Metadata

- App Name (ASC record): **Live Translator – Talk & Go**
- Subtitle (30 chars max): `Speak. Hear it in any language.`
- Bundle ID: `gr.easyfair.livetranslator`
- Team: WDMF PC (`4377RHJY7Z`)
- Category: Travel (primary), Utilities (secondary)
- Age rating: 4+
- Keywords (100 chars max, comma-separated, no spaces after commas):
  `voice translator,live translation,travel translator,speak translate,conversation,interpreter,greek`

## Promotional Text (170 chars — αλλάζει χωρίς νέα έκδοση)

Hold the button, say anything, hear it back in the language you chose. 30 minutes free, then pay only for the time you use. No subscription.

## Description (4000 chars max)

Talk to anyone, anywhere. Live Translator turns your voice into another language in seconds — no typing, no menus, no subscription.

HOW IT WORKS
Pick the language you want to hear. Hold the button and speak naturally — the app figures out which language you spoke, translates it, and reads it aloud. When the other person answers, hold the button again: their words come back in your language. That's it.

BUILT FOR REAL CONVERSATIONS
• Detects the spoken language automatically — no switching back and forth
• Translates the way a native speaker would say it, not word for word
• Spoken aloud instantly with a natural voice
• 37 languages, including Greek, English, Spanish, French, German, Italian, Turkish, Arabic, Chinese, Japanese and more

PAY ONLY FOR WHAT YOU USE
Your first 30 minutes are free. After that, buy translation time in packs — one hour, five, ten or fifty. Time is counted only while you hold the button, it never expires, and there is no subscription to cancel. Your balance follows your Apple ID through iCloud, so it's there on your next device too.

PRIVATE BY DESIGN
No account. No sign-up. We never store your voice or what you say. Text is translated on the fly and discarded.

Perfect for travel, hotels, restaurants, markets, taxis, medical visits, meeting new people — anywhere words get in the way.

Speech recognition is provided by Apple. Translation requires an internet connection.

## What's New (v1.0)

First release.

## App Privacy (nutrition labels)

- **Data Not Collected.** Δεν υπάρχουν accounts, δεν γίνεται tracking, δεν συλλέγεται audio. Το κείμενο της μετάφρασης περνά transient από το backend χωρίς identifier → δεν θεωρείται "collected" κατά Apple.
- Το `PrivacyInfo.xcprivacy` δηλώνει μόνο UserDefaults (CA92.1).

## App Review — Notes & Contact

Contact: connect@viralpassion.gr · τηλέφωνο επικοινωνίας της WDMF

```
Live Translator is a voice translator. Hold the button, speak, release: the app
recognizes the speech (Apple Speech), sends the transcript to our translation
service (OpenAI via our Vercel backend), and reads the result aloud (AVSpeech).

MICROPHONE / SPEECH RECOGNITION: required only while the button is held.

NO ACCOUNT: there is no login of any kind. Nothing to sign in to.

IN-APP PURCHASES: four consumable packs of translation time
(gr.easyfair.credits.1h / 5h / 10h / 50h). New users get 30 free minutes.
To reach the paywall quickly: tap "Add time" on the home screen.
Purchases can be tested with a Sandbox account. Time is charged per second
while the button is held; the balance is stored in iCloud Key-Value storage.

To test translation: set "Translate to" to any language, hold the button,
say a sentence in English (or Greek), release.
```

## In-App Purchases (πρέπει να ταιριάζουν με StoreManager.swift)

| Product ID | Τύπος | Display Name | Τιμή (ASC) |
|-----------|-------|--------------|------------|
| `gr.easyfair.credits.1h` | Consumable | 1 Hour | €1.99 ✅ |
| `gr.easyfair.credits.5h` | Consumable | 5 Hours | εκκρεμεί (πρόταση €4.99) |
| `gr.easyfair.credits.10h` | Consumable | 10 Hours | εκκρεμεί (πρόταση €8.99) |
| `gr.easyfair.credits.50h` | Consumable | 50 Hours | εκκρεμεί (πρόταση €29.99) |

Κάθε IAP θέλει **review screenshot** πριν το submit (screenshot του paywall από τη συσκευή αρκεί, το ίδιο και για τα 4).

## Screenshots (iPhone 6.9" υποχρεωτικά — 1320×2868, 3 έως 10)

Τραβηγμένα από τη συσκευή (iPhone 16/17 Pro Max ή simulator), χωρίς debug γραμμές (Release build / TestFlight):

1. Home, idle — "Translate to 🇫🇷 French", σφαίρα, HOLD TO TALK → caption: **One button. Any language.**
2. Recording — κόκκινη κατάσταση LISTENING → **Just talk. It detects your language.**
3. Μετάφραση στην κάρτα + "English detected" → **Hear it back instantly.**
4. Language picker → **37 languages.**
5. Paywall με τα 4 πακέτα → **No subscription. Pay as you go.**

## Submission Links (production)

- Privacy URL: https://backend-gamma-eight-88.vercel.app/privacy
- Support URL: https://backend-gamma-eight-88.vercel.app/support
