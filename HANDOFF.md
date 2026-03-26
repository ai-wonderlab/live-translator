# Easy Live Translator — Complete Handoff
**Ημερομηνία:** 2026-03-24  
**Για:** Νίκος Μετρήδης, Πετράκης, Κλαούντια Ναντάδη  
**Επικοινωνία:** Νίκος Λούβαρης — τηλέφωνο (για οποιαδήποτε απορία)

---

## Η ιδέα — 2 γραμμές

Native iOS app. Κρατάς ένα κουμπί, μιλάς, αφήνεις — ακούς τη μετάφραση.  
Δύο γλώσσες, ένα κουμπί, 20 γλώσσες. Χωρίς subscription. Αγοράζεις χρόνο.

---

## Πού είναι ο κώδικας

**GitHub:** https://github.com/AiWonderLab/cognitive-bic  
**Φάκελος:** `projects/translator-game/`

```
projects/translator-game/
├── EasyLiveTranslator/                   ← iOS app (Xcode project)
│   └── EasyLiveTranslator/
│       ├── Engine/
│       │   ├── SpeechRecognizer.swift    ← Μικρόφωνο + Apple Speech API
│       │   ├── SpeechSynthesizer.swift   ← Ανάγνωση μετάφρασης (TTS)
│       │   ├── TranslationAPI.swift      ← Στέλνει στο backend, παίρνει μετάφραση
│       │   └── TranslationEngine.swift   ← Ενορχηστρώνει όλη τη ροή
│       ├── Views/
│       │   ├── HomeView.swift            ← Κύρια οθόνη (το κουμπί + flags)
│       │   └── MicButton.swift           ← Το μεγάλο κουμπί με states
│       ├── Store/
│       │   ├── CreditManager.swift       ← Credits λογική + iCloud sync
│       │   └── StoreManager.swift        ← StoreKit 2 in-app purchases
│       ├── Models/
│       │   └── Language.swift            ← 20 γλώσσες με flags + locale codes
│       └── Info.plist                    ← Permissions + API secret placeholder
│
├── backend/                              ← Vercel serverless (Node.js)
│   └── api/translate.js                  ← OpenAI proxy με auth + rate limiting
│
├── APP-STORE-METADATA.md                 ← Τίτλος, περιγραφή, keywords για App Store
├── SUBMISSION-CHECKLIST.md              ← Λίστα για App Store submission
└── HANDOFF.md                           ← Αυτό το αρχείο
```

---

## Πώς λειτουργεί (flow)

```
Χρήστης κρατάει κουμπί
  → AVAudioEngine ξεκινάει recording
  → Apple SFSpeechRecognizer μετατρέπει φωνή σε κείμενο (real-time)

Χρήστης αφήνει κουμπί
  → Audio σταματάει, τελικό transcript παίρνεται
  → POST https://backend.vercel.app/api/translate
      Headers: { X-App-Secret: <secret> }
      Body:    { text, sourceLang, targetLang }
      → Vercel backend → OpenAI GPT-4o-mini → μετάφραση
  → AVSpeechSynthesizer παίζει τη μετάφραση φωνητικά
  → CreditManager αφαιρεί 20 δευτερόλεπτα credits
```

**Stack:**
| Layer | Τεχνολογία | Κόστος |
|-------|-----------|--------|
| Speech-to-text | Apple SFSpeechRecognizer | $0 |
| Translation | OpenAI GPT-4o-mini via proxy | ~$0.005/ώρα χρήστη |
| Text-to-speech | Apple AVSpeechSynthesizer | $0 |
| Backend | Vercel serverless (Node.js) | $0 (free tier) |
| Billing | StoreKit 2 Consumables | Apple native |
| Sync | iCloud Key-Value Storage | $0 |
| UI | SwiftUI | — |

**Κόστος ανά user-ώρα: ~$0.006 | Margin στο 5hr pack: ~99%**

---

## Τι έχει γίνει ήδη ✅

| Κομμάτι | Κατάσταση |
|---------|-----------|
| iOS app — πλήρης UI (HomeView, MicButton, Language Picker, Credits Sheet) | ✅ |
| Microphone + Apple Speech Recognition | ✅ |
| Translation flow E2E (hold → speak → release → hear) | ✅ |
| 20 γλώσσες | ✅ |
| Credits system (30 min free trial + PAYG) | ✅ |
| StoreKit 2 IAP consumables (sandbox-ready) | ✅ |
| iCloud sync για credits | ✅ |
| Vercel backend proxy (OpenAI, με auth + rate limiting) | ✅ |
| App Store metadata + submission checklist | ✅ |
| Xcode build → BUILD SUCCEEDED (iOS 26.2 simulator) | ✅ |
| Layout fixes (language picker, mic centered, credits row visible) | ✅ |
| Mic stability fixes (thread-safety, crash prevention, freeze fix) | ✅ |
| English flag fixed (🇺🇸 αντί 🇬🇧 για en-US) | ✅ |

---

## Τι απομένει — με ΑΚΡΙΒΕΙΣ οδηγίες

### 1. Apple Developer Signing (ΠΡΩΤΟ — χωρίς αυτό τίποτα δεν βγαίνει)

**Χρειάζεσαι:**
- Apple Developer account ενεργό ($99/χρόνο στο developer.apple.com)
- Το **Team ID** σου (10 χαρακτήρες, π.χ. `AB12CD34EF`) — βρίσκεται στο developer.apple.com → Account → Membership → Team ID
- Αποφάσισε Bundle ID: **`gr.easyfair.app`** (προτείνεται) ή `com.aiwonderlab.easylivetranslator`

**Βήματα στο Xcode:**
1. Άνοιξε `EasyLiveTranslator/EasyLiveTranslator.xcodeproj`
2. Αριστερά: κλικ στο **EasyLiveTranslator** (project root)
3. Target **EasyLiveTranslator** → **Signing & Capabilities**
4. Team → επίλεξε το Apple account σου
5. Bundle Identifier → αλλάξτε σε `gr.easyfair.app`
6. Βεβαιώσου ότι "Automatically manage signing" = ✅
7. Product → Run → επίλεξε physical device ή simulator

---

### 2. Vercel Backend — Environment Variables

Το backend είναι ήδη deployed. Χρειάζεται 2 env vars:

**Στο Vercel dashboard → Project Settings → Environment Variables:**
```
OPENAI_API_KEY  =  sk-proj-...    (το OpenAI API key)
APP_SECRET      =  <οποιοδήποτε μυστικό string>   π.χ. easyfair-secret-2026
```

**Αντίστοιχα στο Xcode → Build Settings → User-Defined:**
```
TRANSLATION_API_APP_SECRET  =  <ίδιο value με APP_SECRET>
```
(αυτό διαβάζεται από το `Info.plist` → `TranslationAPIAppSecret`)

**Αν κάνεις δικό σου Vercel deploy:**
```bash
cd backend
npm install
vercel env add OPENAI_API_KEY
vercel env add APP_SECRET
vercel --prod
```
Μετά: αλλαγή URL στο `Engine/TranslationAPI.swift` γραμμή 9.

---

### 3. App Store Connect — In-App Purchase Products

**Δημιούργησε αυτά τα 4 products** (In-App Purchases → Create):

| Product ID | Τύπος | Τιμή | Τίτλος |
|-----------|-------|------|--------|
| `gr.easyfair.credits.1h` | Consumable | $0.99 | 1 Hour |
| `gr.easyfair.credits.5h` | Consumable | $3.99 | 5 Hours |
| `gr.easyfair.credits.10h` | Consumable | $9.99 | 10 Hours |
| `gr.easyfair.credits.50h` | Consumable | $24.99 | 50 Hours |

> ⚠️ Τα Product IDs **πρέπει** να ταιριάζουν ακριβώς με το `StoreManager.swift`.  
> Αν αλλάξεις IDs → αλλαγή και στο `Store/StoreManager.swift` γραμμές 12-16.

**Ώρες → δευτερόλεπτα credits (υπάρχει ήδη στον κώδικα):**
```
1h  = 3.600 sec
5h  = 18.000 sec
10h = 36.000 sec
50h = 180.000 sec
```

---

### 4. Privacy Policy + Support Pages

Το backend έχει ήδη `/privacy` και `/support` routes. Χρειάζεται μόνο το HTML:

**`backend/pages/privacy.html`** (αρκεί απλό):
```html
<!DOCTYPE html><html><body>
<h1>Easy Live Translator — Privacy Policy</h1>
<p>This app uses your microphone ONLY while you hold the talk button.</p>
<p>Audio is processed by Apple Speech Recognition for transcription.</p>
<p>We do not store recordings. Credits sync via iCloud.</p>
<p>We collect no personal data. No account required.</p>
<p>Contact: connect@viralpassion.gr</p>
</body></html>
```

URL για App Store: `https://backend-9wqntu3ln-connect-1143s-projects.vercel.app/privacy`

---

### 5. Screenshots για App Store (6 απαιτούνται)

**Μέγεθος:** iPhone 6.7" (1290×2796px) + iPhone 6.1" (1179×2556px)

Τι να δείξεις:
1. Κύρια οθόνη idle — "One button. Two languages."
2. Recording state (κουμπί κόκκινο) — "Hold to speak"
3. Translation εμφανίζεται — "Instant translation"
4. Language picker sheet (grid με flags) — "20 languages"
5. Credits sheet (τα packs) — "No subscription"
6. Lifestyle photo — άτομο σε ξένη πόλη με phone

> Μπορείς να τα κάνεις capture από τον iOS Simulator:  
> Xcode → Simulator → File → Take Screenshot (ή Cmd+S)

---

### 6. TestFlight (πριν το App Store)

1. App Store Connect → My Apps → Νέα εφαρμογή
2. Βάλε Bundle ID: `gr.easyfair.app`
3. Xcode → Product → Archive → Distribute App → TestFlight
4. App Store Connect → TestFlight → External Testing → Πρόσθεσε 5+ testers
5. Δοκίμασε E2E: permissions → recording → translation → credits → IAP sandbox

---

### 7. App Store Submission

**Metadata (έτοιμη — βρίσκεται στο `APP-STORE-METADATA.md`):**
```
Όνομα:     Easy Live Translator
Subtitle:  Talk, Translate, Pay As You Go.
Bundle ID: gr.easyfair.app
Category:  Travel (primary) · Utilities (secondary)
Keywords:  live translator, travel translator, voice translator,
           conversation translator, real-time translation, speak translate,
           language translation, tourist translator
```

**Review Notes** (σημαντικό για Apple):
```
This app requires microphone access to record speech for translation.
In-app purchases are consumable credits for translation time.
To test IAP: use Sandbox tester account. Tap [+] in the credits bar.
No login required to use the app.
```

---

## Πώς να τρέξεις τοπικά (από μηδέν)

```bash
# 1. Clone
git clone https://github.com/AiWonderLab/cognitive-bic.git
cd cognitive-bic/projects/translator-game

# 2. Άνοιξε στο Xcode
open EasyLiveTranslator/EasyLiveTranslator.xcodeproj

# 3. Xcode → Signing → βάλε το Apple account σου
# 4. Product → Run → iPhone Simulator
# (το app χτίζει και τρέχει — χωρίς backend: translation θα αποτύχει gracefully)

# Backend local (προαιρετικό):
cd backend
npm install
OPENAI_API_KEY=sk-... APP_SECRET=test node -e "require('./api/translate.js')"
```

---

## PLAN — Τι γίνεται μετά

### Άμεσα (αυτή η εβδομάδα)
- [ ] Apple signing setup + TestFlight build
- [ ] 5+ δοκιμαστές → feedback
- [ ] Διόρθωση mic bugs αν εμφανιστούν σε physical device
- [ ] Privacy policy page live
- [ ] App Store Connect setup (products + metadata)

### Βραχυπρόθεσμα (1-2 εβδομάδες)
- [ ] App Store submission
- [ ] Αναμονή Apple review (1-7 μέρες)
- [ ] Fix αν απαιτηθούν αλλαγές από Apple

### Μετά το launch
- [ ] Monitoring: OpenAI costs vs revenue
- [ ] User feedback collection (support email)
- [ ] Bug fixes βάσει real-device reports

### V2 — Μελλοντικές δυνατότητες
| Feature | Τι χρειάζεται | Αξία |
|---------|--------------|------|
| Offline mode | whisper.cpp (on-device STT) | $0 STT, χωρίς internet |
| Φυσικότερη φωνή | OpenAI TTS HD | Premium tier |
| Android | React Native / Expo | 2x αγορά |
| Group mode | WebSocket shared session | Meetings, τάξεις |
| Auto-detect γλώσσα | Remove source lang requirement | Simpler UX |

---

## Αριθμοί που πρέπει να ξέρεις

```
Κόστος launch:           ~$104 (Apple Developer + OpenAI testing)
Κόστος ops/μήνα:         ~$1 για 100 active users
Revenue (100 users):     ~$279/μήνα (μετά Apple 30%)
Margin:                  ~99%
Τιμή free trial:         30 λεπτά
Deduction ανά χρήση:     20 δευτερόλεπτα
```

---

## Επικοινωνία

**Για οποιαδήποτε απορία: επικοινωνήστε με τον Νίκο Λούβαρη**  
📧 connect@viralpassion.gr
