# UI Build Request — Live Translator: Visual Refinement

**Platform:** iOS · SwiftUI · iPhone only
**Approach:** Surgical refinement — the app is functionally complete and visually close. Do NOT rewrite. Fix the 3 known UX gaps and polish.
**Principle:** Every edit is minimal. If something isn't listed here, leave it alone.

---

## Context

Live Translator is a native iOS app for real-time voice translation between two people. The design system (`DS` enum in `HomeView.swift`), state machine (`MicState`), `WireSphere`, `MicCapsule`, `historyRows`, `translationCard`, and `creditsRow` are all implemented and working.

The screenshot (`easylive-ui-final.png`) is outdated — the current codebase is already more advanced. Read `HomeView.swift` as the source of truth.

**What's working and must not change:**
- DS color tokens (bg, surface, border, accent/cyan, recording/red, translating/purple, speaking/green)
- SF Pro Rounded typography throughout
- WireSphere animation and state-reactive glow
- MicCapsule shape, press animation, state colors
- Language pills layout (no swap button — auto-detect is a feature)
- History rows (last 2 translations above the card)
- Credits row structure
- All sheets (LanguagePairSheet, CreditsPurchaseSheet, PaywallSheet, AuthSheet, ProfileSheet)
- The hold-to-talk DragGesture

---

## Files to modify

| File | What changes |
|------|-------------|
| `Views/HomeView.swift` | Fix 1, Fix 2 (MicCapsule + translationCard) |
| `Views/OnboardingView.swift` | Fix 3 (onboarding redesign) |

Do not create new files unless Fix 3 requires a new sub-view within OnboardingView.swift.

---

## Fix 1 — Cooldown / Blocked state on MicCapsule

**Problem:** When `engine.isInCooldown == true` or `engine.isSpeaking == true`, the MicCapsule looks identical to idle (cyan). The user taps and nothing happens — no feedback.

**The engine already provides:**
- `engine.isInCooldown: Bool`
- `engine.isSpeaking: Bool` (maps to `.speaking` MicState)

**What to add:**

Add a `.cooldown` case to `MicState`:

```swift
enum MicState: Equatable { case idle, recording, translating, speaking, cooldown }
```

Extend `MicState` with:

```swift
// in accentColor:
case .cooldown: return DS.textTertiary  // dim white — clearly inactive

// in glowColor:
case .cooldown: return .clear

// in label:
case .cooldown: return "HOLD TO TALK"

// in icon:
case .cooldown: return "mic.fill"
```

Update `micState` computed var in `HomeView`:

```swift
private var micState: MicState {
    if engine.isListening  { return .recording }
    if engine.isSpeaking   { return .speaking }
    if engine.isProcessing { return .translating }
    if engine.isInCooldown { return .cooldown }
    return .idle
}
```

In `MicCapsule.body`, add opacity + pointer-events:

```swift
.opacity(state == .cooldown ? 0.45 : 1.0)
.allowsHitTesting(state != .cooldown)
.animation(.easeInOut(duration: 0.2), value: state == .cooldown)
```

Add a micro progress indicator during cooldown — a thin 2-second draining arc overlay on the capsule:

```swift
// Inside MicCapsule, when state == .cooldown:
// Show a thin stroke Capsule border that animates from full → empty over 2s
// strokeColor: DS.textTertiary.opacity(0.4), lineWidth: 1.5
// Use a @State var cooldownProgress: CGFloat = 1.0
// On .cooldown appear: animate to 0.0 over 2.0s with .linear
// This is purely cosmetic — it doesn't need to sync with engine.isInCooldown exactly
```

**Hard decision:** `.cooldown` must be visually distinct from `.idle`. Dim white (textTertiary) + 45% opacity achieves this. Do not use a different color.

---

## Fix 2 — Show transcript in translation card

**Problem:** `engine.transcript` (the original spoken text) is available but not shown. The user doesn't know if they were heard correctly.

**Current `translationCard` state:**
- Empty: shows placeholder icon + "Translation will appear here"
- With content: shows only `engine.translationText` (22px bold)

**What to add:**

When both `engine.transcript` and `engine.translationText` are non-empty, show both:

```
Translation  [bubble.left.fill icon]
"Hello, how are you?"          ← engine.translationText, 22px semibold, white

────────────────────────────── ← Divider, white 8% opacity

"Γεια σας, πώς είστε;"        ← engine.transcript, 13px medium, textSecondary
```

Implementation in `translationCard`:

```swift
// After showing translationText, if engine.transcript is non-empty:
if !engine.transcript.isEmpty {
    Divider()
        .background(DS.border)
        .padding(.vertical, 8)
    Text(engine.transcript)
        .font(.system(size: 13, weight: .medium, design: .rounded))
        .foregroundStyle(DS.textSecondary)
        .lineLimit(2)
        .frame(maxWidth: .infinity, alignment: .leading)
}
```

**While recording** (micState == .recording), clear both and show a live "listening" shimmer:

```swift
// If micState == .recording && engine.transcript.isEmpty:
// Show a single animated shimmer line (width: 120px, height: 8px, corner: 4px)
// Color: DS.recording.opacity(0.3), animated scale x from 0.4 to 1.0, duration 0.8s, repeatForever autoreverse
// This replaces the placeholder text while recording
```

**Hard decision:** Transcript always goes BELOW the translation, separated by a divider. It's secondary information. Don't swap the order.

---

## Fix 3 — Onboarding redesign

**Problem:** The 3 onboarding steps are generic icon + text + button. They don't show what the app actually does.

**Goal:** Make Step 1 feel like you're experiencing the app, not reading about it.

### New onboarding layout (3 steps)

All steps share:
- Background: `Color.black` with a very subtle diagonal gradient (`#000000` → `#141416`, `UnitPoint.topLeading` → `UnitPoint.bottomTrailing`)
- Bottom: step dots (capsule, 6px × 16px active / 6px × 6px inactive, white 20% / white 60%) + CTA button
- CTA button: white background, `DS.bg` text, corner radius 18px, full width minus 40px padding, "Next" → "Get Started" on last step
- Transition between steps: `.asymmetric(insertion: .move(edge: .trailing).combined(with: .opacity), removal: .move(edge: .leading).combined(with: .opacity))`

---

**Step 1 — "Feel it first"**

Center area: render a live mock of the MicCapsule + WireSphere in `recording` state (not idle — show the red active state).

```
[WireSphere in .recording state — non-interactive, 120×120px]

[MicCapsule in .recording state — non-interactive, full visual with red glow]

    "Hold to speak."
    "Release. Hear the translation."     ← 14px, textSecondary
```

The sphere and capsule are purely visual — they don't need real gestures or audio. Use `WireSphere(state: .recording)` and `MicCapsule(state: .recording, isPressed: true)`.

**Why:** The user's first impression should be the glowing red capsule, not a bullet point.

---

**Step 2 — Languages**

```
[A 2×3 grid of language flags — 6 flags, large emoji, 36px, centered]
[Greek 🇬🇷, English 🇺🇸, Spanish 🇪🇸, French 🇫🇷, Arabic 🇸🇦, Japanese 🇯🇵]

    "20 languages."
    "Switch anytime. The app detects who's speaking."   ← 14px, textSecondary
```

Grid: `LazyVGrid(columns: [GridItem(), GridItem(), GridItem()], spacing: 16)` in a 200×120px frame.
Each flag: text emoji in a 52×52 circle with `DS.surface` background and `DS.border` stroke.

---

**Step 3 — Pricing**

```
[A small version of 2 plan rows — just €0.99 and €3.99, non-tappable]
[ 1 Hour    1h of translation    €0.99 ]
[ 5 Hours   5h of translation    €3.99 ]

    "Pay for what you use."
    "15 minutes free. No subscription."   ← 14px, textSecondary
```

Plan rows: same style as `CreditsPurchaseSheet` but at 80% scale, `opacity: 0.7`, non-interactive.

---

### Onboarding hard decisions

- **No skip button** — 3 steps is short enough
- **"Get Started" triggers microphone permission request** (if not already granted) before dismissing onboarding
- Step indicators: capsule shape (not dots) — active step is wider (16px), inactive is square (6px). White 60% active, white 20% inactive.
- Minimum onboarding height: respect safe area top and bottom — sphere/content must not touch status bar or home indicator

---

## Visual polish — while you're in these files

These are small and should be done alongside the fixes above:

**HomeView.swift:**

1. `historyRows` currently shows `entry.translatedText` (the translation). Also show `entry.sourceLanguage.flag → entry.targetLanguage.flag` direction more clearly:

```swift
// Current: flag → arrow → translatedText → flag
// Change: show sourceFlag → arrow → targetFlag + truncated translatedText
// No code change needed if current layout already does this — verify only
```

2. The ambient background glow (`ambientBackground`) currently uses a 360×360 ellipse. During `.cooldown`, ensure the glow color returns to cyan (not stays at speaking/translating color). Fix: the `micState` computed var already returns `.cooldown` after the fix above, so `state.glowColor` for `.cooldown` is `.clear` — which means the ambient glow disappears during cooldown. **This is correct.** No additional change needed.

3. Add `.animation(.easeInOut(duration: 0.25), value: micState)` to the `historyRows` container if not present.

---

## State machine reference

```
IDLE ──[hold]──→ RECORDING ──[release]──→ TRANSLATING ──[response]──→ SPEAKING ──[done]──→ COOLDOWN ──[2s]──→ IDLE
```

**Visual mapping:**
| State | MicCapsule color | Opacity | Glow | Status text |
|-------|-----------------|---------|------|-------------|
| idle | Cyan | 100% | Cyan glow | "Hold to speak" |
| recording | Red | 100% | Red glow | "Listening..." |
| translating | Purple | 100% | Purple glow | "Translating..." |
| speaking | Green | 100% | Green glow | "Speaking..." |
| **cooldown** | **Dim white** | **45%** | **None** | "Ready in a moment..." |

---

## HARD decisions (do not deviate)

1. **No language swap button** — ever. Auto-detect is the core UX.
2. **Cooldown state = dim white at 45% opacity** — not disabled gray, not hidden
3. **Transcript below translation** — secondary, separated by divider
4. **Onboarding Step 1 shows the recording state visually** — not a generic mic icon
5. **SF Pro Rounded everywhere** — `.design: .rounded` on all `Font.system` calls
6. **Dark mode only** — no `.preferredColorScheme` toggle anywhere

## SOFT decisions (your discretion)

- Exact cooldown arc animation duration (2s is a suggestion — match engine.isInCooldown actual duration if accessible)
- Whether to show transcript in italic or regular weight (brief says medium — but semibold also works)
- Flag grid in Step 2: exact flags chosen (these 6 are suggestions, pick visually balanced ones)
- Shimmer animation in translation card during recording: exact timing values

---

## SwiftUI gotchas

1. **`MicState` is used in multiple files** (HomeView.swift, possibly MicButton.swift legacy). Add the `.cooldown` case carefully — check all `switch` statements on `MicState` are exhaustive after adding the new case.

2. **`historyRows` uses `engine.history.prefix(2)`** — this already handles the conversation history problem from the brief. Do not change this.

3. **Onboarding `WireSphere` in Step 1** needs its own animation lifecycle. Since it's non-interactive, just pass `state: .recording` and let `.onAppear` trigger naturally.

4. **`isInCooldown` property on engine** — verify it exists in `TranslationEngine`. If it's named differently (e.g., `isCooldownActive`), adapt Fix 1 accordingly.

5. **Translation card `engine.transcript`** — verify this property exists on `TranslationEngine`. It may be named `transcribedText` or `recognizedText`. Grep before writing.

---

## Your task

1. Apply Fix 1 (cooldown MicState) — surgical edit to HomeView.swift
2. Apply Fix 2 (transcript in card) — surgical edit to HomeView.swift
3. Apply Fix 3 (onboarding) — rewrite OnboardingView.swift only
4. Apply visual polish items from the polish section

Start with Fix 1 (simplest, most impactful for usability). Then Fix 2. Then Fix 3.

Do not refactor anything not listed. Do not rename variables. Do not change spacing/padding values not mentioned.

---

## Reference files

| File | Purpose |
|------|---------|
| `Views/HomeView.swift` | Main view + all components |
| `Views/OnboardingView.swift` | Onboarding (full rewrite for Fix 3) |
| `Views/MicButton.swift` | Legacy — do not use or modify |
| `UI-ARCHITECT-BRIEF.md` | Full UX spec for context |
| `easylive-ui-final.png` | Outdated screenshot — ignore for UI reference, code is more current |

---

*UI Prompt · Live Translator · UX Architect · AiWonderLab · 2026-04-16*
