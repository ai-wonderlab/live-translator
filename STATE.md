# STATE.md — Easy Live Translator
_Last updated: 2026-03-27 16:15_

---

## Κατάσταση: Active Development — Feature Build Phase

---

## Τι έχει γίνει (2026-03-27)

### ✅ UI Redesign — Wire Sphere
- Deep navy/black background, animated wire sphere (layered Ellipse rings)
- Cyan accent (#33D1E6), state-based glow (recording=red, speaking=green, translating=purple)
- MicCapsule button, ambient background glow

### ✅ Conversation Mode
- Δύο equal language pills (langA + langB) — χωρίς FROM/TO, χωρίς βέλη
- LanguagePairSheet: επιλογή slot 1 + slot 2 ξεχωριστά
- AppStorage keys: `langA`, `langB`

### ✅ Auto-detect Speaker
- Backend λαμβάνει langA.code + langB.code, ανιχνεύει ποια μιλήθηκε
- `activeSttLanguage` εναλλάσσεται μετά κάθε μετάφραση
- Detected language badge εμφανίζεται μετά τη μετάφραση
- Original transcript κρυφό

### ✅ 38 Γλώσσες
- Αρχικές 20 + 18 νέες: Albanian, Bulgarian, Catalan, Chinese (Traditional),
  Croatian, Czech, Filipino, Hebrew, Hungarian, Indonesian, Malay,
  Romanian, Serbian, Slovak, Thai, Ukrainian, Vietnamese

### ✅ Info.plist
- APP_SECRET: easyfair-app-secret-v1
- UIUserInterfaceStyle: Dark
- UIRequiresFullScreen: true
- iOS Deployment Target: 26.0

---

## Ανοιχτά PRs (pending merge)

| Branch | Περιγραφή |
|--------|-----------|
| `feat/wire-sphere-ui` | Wire sphere UI redesign |
| `feat/auto-detect-source` | Conversation mode + auto-detect + 38 γλώσσες |
| `fix/full-screen-layout` | Full screen layout fixes |
| `fix/product-ids` | Product ID alignment |
| `fix/auto-detect-language-swap` | Language swap on detect |

---

## 🔴 Pending Issues

### Full-screen background gaps (iOS 26)
- Πάνω/κάτω μαύρα κενά λόγω iOS 26 windowing
- Δοκιμάστηκε: ignoresSafeArea, GeometryReader, SceneDelegate, UIHostingController, onAppear frame fix, App-level ZStack
- Ακόμα ανοιχτό — χρειάζεται διερεύνηση iOS 26 API

---

## 🔜 Επόμενα (συμφωνημένα)

### 1. User Profile
- Οθόνη προφίλ χρήστη
- Ονοματεπώνυμο, email, avatar
- Σύνδεση με Supabase Auth ή custom backend

### 2. Billing / Credits
- Πώς λειτουργεί το σύστημα credits
- In-App Purchase flow (StoreKit 2)
- Product IDs: gr.easyfair.credits.1h / 5h / 10h / 50h
- Credit display + refill UI

---

## Αρχιτεκτονικές Αποφάσεις

| Θέμα | Απόφαση |
|------|---------|
| Bundle ID | com.openclaw.EasyLiveTranslator |
| Backend | https://backend-gamma-eight-88.vercel.app/api/translate |
| Product ID format | gr.easyfair.credits.{1h/5h/10h/50h} |
| Auto-detect | langA + langB στο backend, backend αποφασίζει |
| STT alternation | activeSttLanguage εναλλάσσεται μετά κάθε translation |
| File writes | Python open().write() — edit/write tools fail on this repo |

---

## Κανόνες Εργασίας
- Κάθε feature σε δικό του branch
- Merge μόνο μέσω PR — ποτέ direct push στο main
- Surgical edits μόνο — ποτέ full rewrite αρχείου
- Κάθε task ξεκινά με συζήτηση → "ναι" → εκτέλεση
