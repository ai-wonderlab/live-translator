# App Review source recovery — 21 September 2026

The original GitHub-main assessment is superseded. Do not merge draft PR #18 into the release source without comparison: its baseline was the older public main commit 43ed621.

## Source located

- Vercel live-translator-preview: 4 September deployment, branch fix/prelaunch-audit, commit 61c5a3a2fb9e814afed0881eddb15ee46b6272c8. Its Source view contains the iOS project.
- The local Documents/GitHub/live-translator checkout contains that commit and subsequent September development, ending at 160b814 (8 September, build 3). Build 2 is recorded at 5aa4587.
- The September code already removed accounts/Supabase, fixed Add time, moved to recording-duration billing, and restricted content logging to DEBUG.
- These findings identify the September source lineage, but do not prove exactly which commit/archive was used for submitted build 1. App Store Connect still shows build 1 rejected under 4.3(a).

## Additional corrections on this branch

- Reduce the prior 3-second minimum billing to whole-second rounding (a 1-second utterance no longer costs 3 seconds). Preserve the existing 60-second per-translation cap and disclose rounding/cap in purchase copy.
- Reject non-finite/non-positive durations before converting to integer; clamp before conversion to avoid overflow.
- Use monotonic elapsed time for recording billing and guard recording start when there are no credits.

## Verification

- Release iOS Simulator build with Xcode 26.4: BUILD SUCCEEDED.
- ./tests/run-credit-checks.sh: passed rounding, invalid values, trial/purchased crossover, persistence, cap and exhausted balance checks against actual CreditManager.
- git diff --check: passed.
- Build used an empty ignored Secrets.xcconfig and CODE_SIGNING_ALLOWED=NO. It proves compilation, not live backend access, device audio, sandbox purchases, signing, or App Store upload readiness.

## App Review

The clarification response was updated and saved as a draft in App Store Connect, not sent. It describes the single-target conversation workflow and candidate-transcript selection, and asks Apple which specific binary/assets/metadata/concept similarities caused 4.3(a), plus whether Extended Review refers to additional issues.

No new archive was uploaded and nothing was resubmitted. This billing correction does not itself resolve the design/spam rejection. Do not claim unique/original code solely from this source inspection. Establish provenance and provide an actual release-build demo when responding to concrete reviewer concerns.
