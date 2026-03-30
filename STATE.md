# STATE.md — Live Translator (πρώην Easy Live Translator)
_Last updated: 2026-03-30 11:30_

---

## Κατάσταση: Active Development

---

## ✅ Έτοιμο (merged to main)

| Feature | Περιγραφή |
|---------|-----------|
| Wire Sphere UI | Dark navy/black bg, animated rings, cyan accent, state glow |
| Conversation Mode | langA + langB pills, auto-detect ποια γλώσσα μιλήθηκε |
| 38 Γλώσσες | Full list incl. Albanian, Romanian, Ukrainian κτλ |
| Supabase Auth | Apple Sign In + email/password — λειτουργικό |
| ProfileSheet | Person icon στο creditsRow, πάντα ορατό |
| PaywallSheet | Trigger όταν credits=0, 4 plans (€0.99/3.99/6.99/24.99) |
| Mic Lock | 🔒 + disabled όταν credits=0, πατώντας ανοίγει paywall |
| Free Trial | 30 λεπτά δωρεάν, CreditManager ήδη υλοποιημένο |

---

## 🔀 Branches έτοιμα για PR/merge

| Branch | Περιγραφή |
|--------|-----------|
| `fix/tts-language-fallback` | TTS voice fallback chain — fr-FR → fr → any fr voice |
| `fix/full-screen-ios26` | SceneDelegate manual UIWindow, forceFullScreen on appear |
| `feat/google-signin` | Google Sign In via ASWebAuthenticationSession |
| `chore/rename-to-live-translator` | App display name → "Live Translator" |

---

## 🔴 Ανοιχτά

### 1. Payment Flow 💳
- **Απόφαση**: StoreKit (Apple IAP) ✅
- Product IDs έτοιμα: `gr.easyfair.credits.1h/5h/10h/50h`
- **Εκκρεμεί**: Δημιουργία products στο App Store Connect
- StoreManager.swift είναι ήδη πλήρως υλοποιημένο

### 2. Apple Sign In — Supabase Setup 🍎
- Κώδικας υπάρχει ήδη
- **Εκκρεμεί**: Supabase dashboard → Apple → Enable (χρειάζεται κινητό για 2FA)
- **Εκκρεμεί**: Apple Developer Service ID + Key

### 3. Google Sign In 🔐
- Κώδικας υλοποιημένος (ASWebAuthenticationSession)
- **Εκκρεμεί**: Google Console OAuth Client ID (bundle: gr.easyfair.EasyLiveTranslator)
- **Εκκρεμεί**: Supabase dashboard → Google → Enable + Client ID/Secret

### 4. Full-screen background gaps 📱
- iOS 26 windowing behavior — πάνω/κάτω μαύρα κενά
- SceneDelegate approach δοκιμάστηκε — δεν έλυσε πλήρως
- **Παρκαρισμένο για το τέλος**

---

## Τεχνικές Πληροφορίες

| | |
|-|-|
| **Repo** | https://github.com/ai-wonderlab/live-translator |
| **Branch** | main |
| **Device UDID** | `00008030-001434290280802E` |
| **iOS** | 26.3.1 |
| **Backend** | https://backend-gamma-eight-88.vercel.app/api/translate |
| **Supabase URL** | https://ctrddyzybgeyipsslznw.supabase.co |
| **URL Scheme** | `easylive://auth-callback` |

### Build & Install
```bash
cd ~/Documents/GitHub/live-translator/EasyLiveTranslator
xcodebuild -scheme EasyLiveTranslator -destination 'id=00008030-001434290280802E' -allowProvisioningUpdates build
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/EasyLiveTranslator-*/Build/Products/Debug-iphoneos -name "EasyLiveTranslator.app" | head -1)
xcrun devicectl device install app --device 00008030-001434290280802E "$APP_PATH"
```

---

## Κανόνες Εργασίας
- Κάθε feature σε δικό του branch
- Surgical edits μόνο — ποτέ full rewrite
- Κάθε task: συζήτηση → "ναι" → εκτέλεση
