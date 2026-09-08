# Account Deletion — OBSOLETE

Το account layer (Supabase auth, Sign in with Apple, Google, delete account) **αφαιρέθηκε στο v1.0** (branch `fix/prelaunch-audit`, 2026-09-04). Δεν υπάρχουν accounts, άρα η Guideline 5.1.1(v) δεν εφαρμόζεται.

Αν επανέλθουν accounts σε μελλοντική έκδοση, το SQL για το `delete_user` RPC βρίσκεται στο git history (`git show 43ed621:SETUP-ACCOUNT-DELETION.md`).
