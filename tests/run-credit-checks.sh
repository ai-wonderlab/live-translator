#!/bin/sh
set -eu
cd "$(dirname "$0")/.."
checks_dir=$(mktemp -d)
trap 'rm -rf "$checks_dir"' EXIT
# Interpret the production code and checks together; no app signing or iCloud
# entitlement is needed because tests supply isolated defaults and a fake store.
cat EasyLiveTranslator/EasyLiveTranslator/Store/CreditManager.swift > "$checks_dir/checks.swift"
sed '/^@main$/d' tests/CreditManagerChecks.swift >> "$checks_dir/checks.swift"
printf '\nawait CreditManagerChecks.main()\n' >> "$checks_dir/checks.swift"
xcrun swift "$checks_dir/checks.swift"
