# STATE.md — Easy Live Translator
_Last updated: 2026-03-27_

---

## Κατάσταση: Active Development — Pre-Submission Bugfix Phase

---

## Bugs που κλείσαμε σήμερα

### ✅ BUG 1 — Ασυνέπεια Product IDs
- **Branch:** `fix/product-ids`
- **PR:** https://github.com/ai-wonderlab/live-translator/pull/new/fix/product-ids
- **Τι έγινε:** Τα product IDs στο `StoreManager.swift` ήταν `com.aiwonderlab.easylivetranslator.hours.1/5/20/50`. Αλλάξαν σε `gr.easyfair.credits.1h/5h/10h/50h` ώστε να ταιριάζουν με το HANDOFF.md και το App Store Connect.
- **Seconds mapping:** 1h=3600, 5h=18000, 10h=36000, 50h=180000
- **Status:** Committed, pushed — PR ανοιχτό, δεν έχει γίνει merge

### ✅ BUG 3 — Auto-detect γλώσσας δεν ενημέρωνε το UI
- **Branch:** `fix/auto-detect-language-swap`
- **PR:** https://github.com/ai-wonderlab/live-translator/pull/new/fix/auto-detect-language-swap
- **Τι έγινε:** Το backend επέστρεφε `detected` field αλλά το app το αγνοούσε. Τώρα, αν `detected ≠ sourceLanguage`, το app κάνει silent swap source/target στο UI αμέσως μετά τη μετάφραση.
- **Αρχείο:** `Engine/TranslationEngine.swift`
- **Status:** Committed, pushed — PR ανοιχτό, δεν έχει γίνει merge

---

## Bugs που μένουν ανοιχτά

### 🔴 BUG 2 — (δεν συζητήθηκε ακόμα)
_Αριθμός 2 από τη λίστα — αναμένεται στην επόμενη συνεδρία_

### 🔴 Λοιπά bugs από τη λίστα
_Συνεχίζουμε από εκεί που σταματήσαμε_

---

## Αποφάσεις Αρχιτεκτονικής

| Θέμα | Απόφαση |
|------|---------|
| Bundle ID | gr.easyfair.app |
| Product ID format | gr.easyfair.credits.{1h/5h/10h/50h} |
| Auto-detect behavior | Silent swap source/target (όχι visual indicator) |

---

## Κανόνες Εργασίας
- Κάθε fix σε δικό του branch
- Merge μόνο μέσω PR — ποτέ direct push στο main
- Surgical edits μόνο — ποτέ full rewrite αρχείου

---

## Pending για την επόμενη συνεδρία
1. Merge τα 2 ανοιχτά PRs (αν εγκριθούν)
2. Συνέχεια bugfix λίστας από BUG 2 και κάτω
3. Bundle ID αλλαγή στο Xcode (ακόμα χειροκίνητο — δεν έγινε)
