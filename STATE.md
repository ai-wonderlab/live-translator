# STATE.md — Easy Live Translator
_Last updated: 2026-03-27 16:48_

---

## Κατάσταση: Active Development

---

## ✅ Έτοιμο (merged to main `2dbbe9b`)

| Feature | Περιγραφή |
|---------|-----------|
| Wire Sphere UI | Dark navy/black bg, animated rings, cyan accent, state glow |
| Conversation Mode | langA + langB pills, auto-detect ποια γλώσσα μιλήθηκε |
| 38 Γλώσσες | +Albanian, Romanian, Ukrainian, Bulgarian, Croatian, Czech, Hungarian, Slovak, Serbian, Hebrew, Thai, Vietnamese, Indonesian, Malay, Catalan, Filipino, Chinese Traditional |
| Supabase Auth | Apple Sign In + email/password — λειτουργικό |
| ProfileSheet | Person icon στο creditsRow, πάντα ορατό |
| PaywallSheet | Trigger όταν credits=0, 4 plans (€0.99/3.99/6.99/24.99) |
| Mic Lock | 🔒 + disabled όταν credits=0, πατώντας ανοίγει paywall |
| Free Trial | 30 λεπτά δωρεάν, CreditManager ήδη υλοποιημένο |

---

## 🔴 Ανοιχτά — για αύριο

### 1. Payment Flow 💳
- **Απόφαση αφεντικού**: Stripe vs StoreKit (Apple IAP)
- Τα plans είναι placeholder: €0.99 / €3.99 / €6.99 / €24.99
- Μόλις αποφασιστεί, συνδέουμε το "Purchase Hours" button
- Product IDs έτοιμα: `gr.easyfair.credits.1h/5h/10h/50h`

### 2. Apple Sign In — Supabase Setup 🍎
- Πρέπει να ενεργοποιηθεί στο Supabase dashboard:
  **Authentication → Providers → Apple → Enable**
- Χρειάζεται Apple Developer: Service ID + Key

### 3. Google Sign In 🔐
- Δεν υλοποιήθηκε ακόμα
- Χρειάζεται: Google OAuth Client ID για iOS
- Μετά: προσθήκη στο AuthSheet

### 4. Full-screen background gaps 📱
- Πάνω/κάτω μαύρα κενά — iOS 26 windowing behavior
- Έχουν δοκιμαστεί 10+ προσεγγίσεις — ακόμα ανοιχτό
- Δεν επηρεάζει λειτουργικότητα

---

## Τεχνικές Πληροφορίες

| | |
|-|-|
| **Repo** | https://github.com/ai-wonderlab/live-translator |
| **Branch** | main (τελευταίο merge: `2dbbe9b`) |
| **Device UDID** | `00008030-001434290280802E` |
| **iOS** | 26.3.1 |
| **Backend** | https://backend-gamma-eight-88.vercel.app/api/translate |
| **Supabase URL** | https://ctrddyzybgeyipsslznw.supabase.co |
| **Supabase Key** | sb_publishable_1-mGhNHxlREzyaG2XkWn-w_HUo9Z4Yj |
| **App Secret** | easyfair-app-secret-v1 |

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
- Merge μόνο μέσω PR (ή explicit εντολή)
- Surgical edits μόνο — ποτέ full rewrite
- Κάθε task: συζήτηση → "ναι" → εκτέλεση
