# Live Translator — UI/UX Architect Brief
**Για:** UI/UX Architect
**Από:** Product Team
**Ημερομηνία:** 2026-04-16
**Platform:** iOS (SwiftUI, iPhone only)
**Status:** Λειτουργικό app — χρειάζεται visual/UX redesign

---

## Σε μια πρόταση

Live Translator είναι ένα native iOS app για real-time φωνητική μετάφραση μεταξύ δύο ατόμων. Κρατάς ένα κουμπί, μιλάς, αφήνεις — ακούς τη μετάφραση φωνητικά. Δύο γλώσσες, ένα κουμπί, χωρίς subscription.

---

## 1. Ταυτότητα & Τόνος

### Τι είναι η εφαρμογή
Εργαλείο επικοινωνίας για ταξίδια, συνεντεύξεις, επαγγελματικές συναντήσεις. Χρησιμοποιείται όταν δύο άτομα δεν μιλούν την ίδια γλώσσα και θέλουν να επικοινωνήσουν φυσικά, χωρίς γρήγορο internet browsing ή copy-paste.

### Τόνος
- **Minimalist, premium, dark-first** — η εφαρμογή χρησιμοποιείται σε δημόσιους χώρους (αεροδρόμια, ξενοδοχεία, εστιατόρια)
- **Confidence** — το κουμπί πρέπει να αισθάνεται σαν να "ανοίγει κανάλι", σαν walkie-talkie
- **Calm tech** — δεν αποσπά, δεν "φωνάζει", βοηθάει σιωπηλά

### Τι ΔΕΝ είναι
- Δεν είναι chat app
- Δεν είναι language learning app
- Δεν είναι chatbot

---

## 2. Τρέχον Design System

### Χρώματα (από τον κώδικα)
| Token | Hex / Opacity | Χρήση |
|-------|--------------|-------|
| `bg` | `#000000` | Background (full black) |
| `bgMid` | `#0C0F18` | Gradient mid-bg |
| `surface` | white 5.5% | Cards, pills |
| `border` | white 8% | Default borders |
| `borderBright` | white 14% | Active/hover borders |
| `textPrimary` | `#FFFFFF` | Κύριο κείμενο |
| `textSecondary` | white 55% | Secondary labels |
| `textTertiary` | white 25% | Placeholder, captions |
| `accent` (cyan) | `#33D1E6` | CTAs, icons, links |
| `accentSoft` | cyan 15% | Backgrounds active elements |
| `recording` | `#F25A4D` (κόκκινο) | Recording state |
| `translating` | `#8C72F2` (μωβ) | Translating state |
| `speaking` | `#4DE099` (πράσινο) | Speaking/TTS state |

### Typography
- Font: **SF Pro Rounded** (`.design: .rounded`) παντού
- Sizes: 11px (captions/labels) → 14px (body) → 22px (κύρια translation) → 30px (onboarding titles)
- Weight: medium/semibold/bold — ποτέ regular για κύριο περιεχόμενο

### Spacing
- Horizontal padding: 20px (main content), 24px (sheets)
- Corner radius: 16–22px (cards), 18–20px (pills), 12px (buttons σε sheets)
- Bottom safe area: πάντα respected

### Υλικά
- `.ultraThinMaterial` για language pills (top bar)
- Plain `DS.surface` (white 5.5%) για cards

---

## 3. Screens — Πλήρης Περιγραφή

---

### SCREEN 1: Onboarding (3 βήματα)

**Πότε εμφανίζεται:** Μόνο την πρώτη φορά. `fullScreenCover`.

**Layout:**
- Full-screen dark background (black → `#141416` diagonal gradient)
- Center: μεγάλο icon σε κύκλο με χρωματιστό background, title, subtitle
- Bottom: step indicators (capsule dots) + CTA button (λευκό, full-width)
- Transition: slide left/right με opacity

**Τα 3 steps:**

| Step | Icon | Color | Title | Subtitle |
|------|------|-------|-------|---------|
| 1 | `mic.fill` | Κόκκινο | "Hold to speak." | Press and hold the button, say something, release. You'll hear the translation instantly. |
| 2 | `globe` | Μπλε | "20 languages." | Switch between any two languages at any time — great for conversations on the go. |
| 3 | `clock` | Πράσινο | "Pay for what you use." | 15 minutes free. No subscription — buy more time when you need it. |

**CTA Button:**
- "Next" → "Get Started" στο τελευταίο step
- Λευκό background, μαύρο κείμενο, corner radius 18px

**Τι χρειάζεται redesign:**
- Το onboarding είναι generic — κάθε step φαίνεται ίδιο (icon + text + button)
- Χωρίς animation στα transitions μεταξύ steps — μόνο slide
- Δεν δείχνει καλά τι είναι η εφαρμογή — θα ήταν καλύτερο αν το 1ο step ήταν ένα visual demo του κουμπιού

---

### SCREEN 2: HomeView (Κύρια Οθόνη)

Αυτή είναι η μόνη οθόνη της εφαρμογής. Ο χρήστης περνά σχεδόν όλο του χρόνο εδώ.

**Layout (top → bottom):**
```
┌─────────────────────────────────┐
│  [🇬🇷 Greek ˅]  [🇺🇸 English ˅] │  ← Top Bar
├─────────────────────────────────┤
│                                 │
│         Wire Sphere             │  ← Animated 3D sphere
│                                 │
│    [🇬🇷 Greek detected]          │  ← Detected language badge (optional)
│                                 │
│      "Hold to speak"            │  ← Status line
│                                 │
│    [  🎙  HOLD TO TALK  ]       │  ← Mic Capsule (CTA)
│                                 │
├─────────────────────────────────┤
│  Translation                    │  ← Translation Card
│  "Hello, how are you?"          │
├─────────────────────────────────┤
│  🕐 15 min remaining  [+Add]👤  │  ← Credits Row
└─────────────────────────────────┘
```

#### 2a. Top Bar — Language Pills

Δύο pills side-by-side, κάθε μία full-width (50/50).

```
[🇬🇷 Greek ˅]    [🇺🇸 English ˅]
```

- Material: `.ultraThinMaterial` με white 14% border
- Corner radius: 20px
- Κάνοντας tap: ανοίγει Language Pair Sheet
- Δεν υπάρχει και δεν χρειάζεται swap button — το app ανιχνεύει αυτόματα σε ποια γλώσσα μίλησες και μεταφράζει στην άλλη

#### 2b. Wire Sphere

Animated sphere στο κέντρο — το οπτικό "heart" της εφαρμογής.

- 165×165px
- Αποτελείται από 5 ellipses (wire rings) που περιστρέφονται
- Αλλάζει συμπεριφορά ανάλογα με state:

| State | Sphere behavior | Glow color |
|-------|-----------------|------------|
| idle | Αργή περιστροφή, ήπιο breathing | Cyan |
| recording | Γρήγορη περιστροφή, intense breathing | Κόκκινο |
| translating | Γρήγορη περιστροφή | Μωβ |
| speaking | Γρήγορη περιστροφή | Πράσινο |

- Center icon: `mic.fill` (idle/recording), `ellipsis` (translating), `speaker.wave.2.fill` (speaking)
- Ambient glow: ένα blur ellipse πίσω από τη sphere που αλλάζει χρώμα

#### 2c. Detected Language Badge

Εμφανίζεται μόνο αφού γίνει μια μετάφραση. Δείχνει ποια γλώσσα ανιχνεύτηκε.

```
[🇬🇷 Greek detected]
```

- Capsule shape, cyan border, κείμενο cyan
- `.transition(.scale.combined(with: .opacity))` — appear/disappear με animation

#### 2d. Status Line

Ένα string κείμενο που περιγράφει τι γίνεται:

| Κατάσταση | Status text |
|-----------|-------------|
| idle (με permissions) | "Hold to speak" |
| idle (χωρίς permissions) | "Microphone access required" |
| recording | "Listening..." |
| translating | "Translating..." |
| speaking | "Speaking..." |
| error | [error message] — σε κόκκινο |

#### 2e. Mic Capsule (CTA button)

Το κύριο κουμπί. **Capsule shape** (όχι circle).

```
[  🎙  HOLD TO TALK  ]
```

- Padding: 32px horizontal, 16px vertical
- Background color = state.accentColor (cyan/κόκκινο/μωβ/πράσινο)
- Κείμενο: bold, letter-spacing 1.8, caps
- Shadow: state.glowColor
- Press effect: scaleEffect 0.93

**States:**
| State | Background | Icon | Label |
|-------|-----------|------|-------|
| idle | Cyan | mic.fill | HOLD TO TALK |
| recording | Κόκκινο | mic.fill | LISTENING |
| translating | Μωβ | ellipsis | TRANSLATING |
| speaking | Πράσινο | speaker.wave.2.fill | SPEAKING |

**Αν δεν υπάρχουν credits:**
- Εμφανίζεται κλειδωμένη (lock icon overlay), opacity 50%
- Tap → ανοίγει Paywall Sheet

**Gesture:** `DragGesture(minimumDistance: 0)` — δουλεύει σαν press-and-hold. Ξεκινά recording στο `onChanged`, σταματά στο `onEnded`.

**Πρόβλημα:** Δεν υπάρχει καμία visual ένδειξη ότι υπάρχει cooldown (2 δευτερόλεπτα μετά κάθε μετάφραση όπου δεν μπορείς να ξαναμιλήσεις). Ο χρήστης πατά και δεν γίνεται τίποτα — χωρίς feedback.

#### 2f. Translation Card

Εμφανίζεται κάτω από το κουμπί. Card με rounded corners.

**Empty state:**
```
💬 Translation will appear here
```
(icon + text, tertiary color)

**Με περιεχόμενο:**
```
Translation  [icon]
"Γεια σας, πώς είστε;"
```
- Label: 11px, cyan, letter-spacing 0.8
- Κείμενο μετάφρασης: 22px, bold, white, max 4 γραμμές
- Μόνο η ΜΕΤΑΦΡΑΣΗ φαίνεται (όχι το αρχικό κείμενο που μιλήθηκε)
- Animation: `.easeInOut(0.3)` on content change

**Πρόβλημα:** Δεν φαίνεται το αρχικό κείμενο (transcript). Δεν υπάρχει history — κάθε νέα μετάφραση αντικαθιστά την προηγούμενη. Σε conversation με πολλά turns, ο χρήστης χάνει context.

#### 2g. Credits Row

Η τελευταία γραμμή της οθόνης, πάνω από το safe area.

```
🕐  15 min remaining     [+ Add time]  [👤]
```

- Left: clock icon + remaining time text
- Right: "Add time" capsule button (cyan) + profile icon
- Και τα δύο δεξιά buttons ανοίγουν Profile Sheet

**Background:** `DS.surface` με border, corner radius 18px

---

### SCREEN 3: Language Pair Sheet

Ανοίγει από tap σε οποιοδήποτε language pill. `.presentationDetents([.medium, .large])`.

**Layout:**

```
┌─────────────────────────────────┐
│        Language Pair            │  ← Navigation title
├─────────────────────────────────┤
│  [🇬🇷 Greek]    [🇺🇸 English]    │  ← Pair preview (A | B)
├─────────────────────────────────┤
│  🔍 Search language             │  ← Searchable
├─────────────────────────────────┤
│  🇸🇦  Arabic               ●    │
│  🇩🇰  Danish                    │
│  🇳🇱  Dutch               ●     │  ← cyan dot = selected as A
│  🇺🇸  English                   │  ← green dot = selected as B
│  ...                            │
└─────────────────────────────────┘
```

**Pair Preview (top section):**
- Δύο κουτιά, side-by-side
- Το active/selected slot έχει cyan border + cyan background
- Κάνοντας tap σε slot αλλάζει ποιο επιλέγεις
- Επιλογή γλώσσας → αυτόματα αλλάζει το active slot στο επόμενο

**List:**
- 38 γλώσσες, sorted alphabetically
- Flag emoji + language name
- Dot indicator για το ποια είναι επιλεγμένη (cyan = A, green = B)
- Row background: `DS.accentSoft` αν επιλεγμένη, `DS.surface` αλλιώς

**Done button** top-right, cyan.

**Σημείωση:** Δεν υπάρχει — και δεν χρειάζεται — swap button. Οι δύο γλώσσες είναι απλώς "η μία και η άλλη". Το app ανιχνεύει αυτόματα ποια μιλήθηκε και μεταφράζει στην άλλη. Αυτό είναι το core UX, όχι παράλειψη.

---

### SCREEN 4: Credits Purchase Sheet

Ανοίγει από "Add time" button. `.presentationDetents([.fraction(0.48), .medium])`.

```
──── (drag handle) ────

Add Translation Time
  🕐 15 min remaining

[ 1 Hour             1h of translation    €0.99 ]
[ 5 Hours            5h of translation    €3.99 ]
[ 10 Hours           10h of translation   €6.99 ]
[ 50 Hours           50h of translation  €24.99 ]

(loading spinner αν γίνεται αγορά)

15 min free trial · 20 sec per translation
```

- Background: `DS.bg` (full black)
- Κάθε plan row: card με DS.surface, border, corner 16px
- Price: cyan, bold
- CTA: απευθείας tap στο row
- Error/success messages εμφανίζονται πάνω από τα rows

---

### SCREEN 5: Paywall Sheet

Εμφανίζεται αυτόματα όταν τελειώσουν τα credits. `.presentationDetents([.large])`.

```
──── (drag handle) ────

⏱️
"Your free 15 minutes are up"
"Create a free account to continue
and purchase translation time."

[ 1 hour    ~60 translations    €0.99  ]
[ 5 hours   ~300 translations   €3.99  ]
[ 10 hours  ~600 translations   €6.99  ]
[ 50 hours  ~3000 translations €24.99  ]

[  Create Free Account  ]  ← cyan button (αν δεν είναι logged in)
   ή
[  Purchase Hours  ]       ← αν είναι logged in
```

- Background: `#0D0D1A` (dark blue-black)
- Plans: rows με white 6% background
- CTA: cyan background, μαύρο κείμενο

---

### SCREEN 6: Auth Sheet (Sign In / Sign Up)

Ανοίγει από Paywall όταν ο χρήστης πατά "Create Free Account". `.presentationDetents([.large])`.

```
──── (drag handle) ────

🌐
"Welcome back" / "Create account"
"15 minutes free · No credit card required"

[  Sign in with Apple  ]   ← native ASAuthorizationAppleIDButton

────── or ──────

[ email@example.com        ]
[ ••••••••                 ]

[error message αν υπάρχει]

[  Sign In / Create Account  ]   ← cyan

"Don't have an account? Sign up"  ← toggle
```

- Toggle μεταξύ Sign In / Sign Up mode
- Apple Sign In: native button (white style)
- Email/password: custom styled text fields (white 7% bg)
- Loading state: ProgressView στο button

---

### SCREEN 7: Profile Sheet

Ανοίγει από το person icon ή "Add time" button. `.presentationDetents([.medium, .large])`.

Δεν έχω δει τον πλήρη κώδικα αλλά από context:
- Δείχνει profile info (email/Apple account)
- Trigger για Paywall/purchase
- Sign out option

---

## 4. Κύρια UX Flow

```
App Launch
    → Onboarding (3 steps) — μόνο 1η φορά
        → HomeView

HomeView (idle)
    → Tap language pill → Language Pair Sheet → dismiss → HomeView
    → Hold mic button:
        → recording state (κόκκινο)
        → release
        → translating state (μωβ)
        → speaking state (πράσινο) — TTS plays translation
        → idle state (2sec cooldown)
        → ready για επόμενο turn
    → Tap "+ Add time" / profile icon → Profile Sheet
    → Credits = 0 → Paywall Sheet auto

Paywall Sheet
    → Not logged in → AuthSheet → back to Paywall → Purchase
    → Logged in → Purchase directly
```

---

## 5. State Machine — Πλήρης Περιγραφή

Η εφαρμογή έχει 4 states για το mic:

```
IDLE ──[hold button]──→ RECORDING
RECORDING ──[release]──→ TRANSLATING
TRANSLATING ──[API response]──→ SPEAKING
SPEAKING ──[TTS done + 2sec cooldown]──→ IDLE
```

**Σε κάθε state αλλάζει:**
- Sphere animation speed + breathing
- Sphere glow color
- Mic capsule background color
- Mic capsule icon + label
- Status text line
- Ambient background glow

**Τεχνικές λεπτομέρειες που επηρεάζουν UX:**
- Ενώ παίζει TTS (speaking state), δεν μπορείς να ξαναπατήσεις (blocked)
- 2 δευτερόλεπτα cooldown μετά κάθε μετάφραση (invisible στο UI)
- Auto-detect γλώσσας: αφού ανιχνευτεί ποιος μίλησε (A ή B), αλλάζει αυτόματα ποιος "πρέπει να μιλήσει επόμενος"

---

## 6. Γνωστά UX Προβλήματα

### Πρόβλημα 1: Invisible blocking states
Όταν παίζει TTS ή υπάρχει cooldown, το κουμπί φαίνεται ίδιο με idle. Ο χρήστης πατά, δεν γίνεται τίποτα, δεν ξέρει γιατί.

### Πρόβλημα 2: Stale translation
Αφού γίνει μια μετάφραση και ο χρήστης μιλήσει ξανά, η παλιά μετάφραση παραμένει μέχρι να γίνει η νέα. Μπορεί να φαίνεται σαν "δεν άλλαξε τίποτα".

### Πρόβλημα 3: Conversation history
Κάθε νέα μετάφραση αντικαθιστά την προηγούμενη. Σε conversation πολλών turns, ο χρήστης χάνει context. Δεν υπάρχει thread/history.

### Πρόβλημα 4: No transcript visible
Το αρχικό κείμενο που αναγνωρίστηκε (transcript) δεν φαίνεται. Ο χρήστης δεν ξέρει αν "ακούστηκε σωστά".

### Πρόβλημα 5: State clarity
Τα states recording → translating → speaking αλλάζουν χρώμα αλλά η αλλαγή είναι subtle. Σε φωτεινό περιβάλλον (εξωτερικοί χώροι) δύσκολα διακρίνονται.

---

## 7. Τι ΔΕΝ αλλάζει (Technical Constraints)

- **Platform:** iOS μόνο, SwiftUI
- **Dark mode only** — η εφαρμογή είναι πάντα dark (χρησιμοποιείται σε low-light conditions συχνά)
- **Gesture:** Το hold-to-talk gesture παραμένει. Είναι core UX.
- **4 states:** idle / recording / translating / speaking — και οι 4 πρέπει να είναι visually distinct
- **Language pills:** Πρέπει να φαίνονται και οι δύο γλώσσες πάντα
- **Credits row:** Πρέπει να φαίνεται πάντα το remaining time
- **Sheets:** Onboarding, Language Picker, Credits, Paywall, Auth — όλα sheets/overlays

---

## 8. Τι είναι ελεύθερο για redesign

Ο UI Architect έχει πλήρη ελευθερία σε:

- **Layouts** — η σειρά των elements, το spacing, η ιεραρχία
- **Sphere** — το wire sphere concept είναι ωραίο αλλά μπορεί να αντικατασταθεί με οτιδήποτε visualizes "listening / thinking / speaking"
- **Mic button shape** — capsule, circle, οτιδήποτε
- **Translation card** — μπορεί να γίνει conversation thread, bubbles, κλπ
- **State feedback** — haptics, animations, visual indicators για cooldown
- **Onboarding** — πλήρης redesign
- **Typography scale**
- **Color tokens** — με constraint ότι υπάρχουν 4 distinct state colors

### Προτεινόμενα areas για βελτίωση (priority order):

1. **State clarity** — Πώς φαίνεται ΞΕΚΑΘΑΡΑ σε ποιο state είναι η εφαρμογή, ειδικά το "blocked/cooldown" state
2. **Conversation feel** — Η κάρτα μετάφρασης να αισθάνεται σαν live conversation, όχι σαν static display
3. **Onboarding** — Να δείχνει το actual product experience, όχι bullet points

---

## 9. Reference Assets

- **Τρέχον UI screenshot:** `easylive-ui-final.png` (στη ρίζα του repo)
- **Xcode project:** `EasyLiveTranslator/EasyLiveTranslator.xcodeproj`
- **Κύριες views:**
  - `Views/HomeView.swift` — κύρια οθόνη + όλα τα components
  - `Views/OnboardingView.swift` — onboarding
  - `Views/MicButton.swift` — legacy mic button (δεν χρησιμοποιείται στο τρέχον UI)
  - `Auth/PaywallSheet.swift` — paywall
  - `Auth/AuthSheet.swift` — login

---

## 10. Deliverable που ζητάμε

**Από τον UI Architect:**

1. **Redesigned HomeView** — η κύρια οθόνη με:
   - Ξεκάθαρο state machine visualization
   - Language pills που δείχνουν καθαρά τις δύο επιλεγμένες γλώσσες (χωρίς swap — το app αυτο-ανιχνεύει)
   - Translation area που αισθάνεται σαν conversation
   - Credits indicator που δεν "φωνάζει" αλλά είναι πάντα ορατό

2. **Onboarding redesign** — 3 steps max, να δείχνει το actual UX

3. **Paywall/credits sheet** — premium feel, easy to understand pricing

4. **Design tokens** — colors, typography, spacing, corner radii

5. **Component states** — κάθε component σε όλα τα states (idle, recording, translating, speaking, disabled, error)

**Format:** Figma file ή annotated mockups. SwiftUI-friendly specs (όχι CSS/web).

---

*Live Translator — UI Architect Brief v1.0 — 2026-04-16*
*Για απορίες: connect@viralpassion.gr*
