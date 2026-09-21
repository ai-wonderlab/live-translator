# Live Translator

Public repo for the Live Translator project.

## Structure

- `EasyLiveTranslator/` — iOS app
- `backend/` — Vercel serverless proxy/API
- `index.html` — web prototype
- `HANDOFF.md` — setup and operational handoff

## Security notes

This repo is sanitized for public sharing:
- no local build artifacts
- no local Vercel state
- no `.env` files
- no hardcoded API keys
- no embedded app secret values

## App Review remediation

See [APP-REVIEW-2026-09-21.md](APP-REVIEW-2026-09-21.md) for the current rejection, source/build mismatch, verified fixes and remaining release checks. Older handoff/audit documents describe historical states.

Run `./tests/run-credit-checks.sh` on macOS with Xcode command-line tools to check recording-time billing.

## Setup

See `HANDOFF.md` for project setup and deployment steps.
