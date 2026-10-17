#!/usr/bin/env bash
# Cut an Awan release the way the in-app updater expects to find it.
#
# The updater reads `GET /repos/<owner>/<repo>/releases/latest` and looks for:
#   * an `.apk` asset (preferring one with `arm64` in the name) — the full build;
#   * an optional `<from>__<to>.patch` — the delta the app applies to the APK it
#     is already running, so an update costs megabytes instead of ~93 MB.
# If the release publishes SHA-256 values, a download or a rebuilt APK that
# does not match is deleted instead of installed.
#
#   ./tools/release.sh 1.21.0 OWNER/REPO [PREVIOUS_VERSION]
#
# This script does NOT publish: pushing a release is a decision, not a side
# effect. It prints the `gh release create` line to run when you have decided.
set -euo pipefail

VERSION="${1:?usage: release.sh <version> <owner/repo> [previous_version]}"
REPO="${2:?usage: release.sh <version> <owner/repo> [previous_version]}"
PREV="${3:-}"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/dist"
APK="$OUT/Awan_v${VERSION}-arm64-v8a.apk"
PY="/c/Users/ok/AppData/Local/Programs/Python/Python312/python.exe"

cd "$ROOT"

echo "== version check"
PUBSPEC_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
if [ "${PUBSPEC_VERSION%%+*}" != "$VERSION" ]; then
  echo "pubspec.yaml says $PUBSPEC_VERSION but you are releasing $VERSION" >&2
  echo "bump pubspec.yaml (and AppConstants.appVersion) first" >&2
  exit 1
fi

echo "== build (split per ABI; only the arm64 APK is published)"
export PATH="/h/flutter/bin:$PATH"
# Split is not cosmetic: it is what gives each ABI its own versionCode base,
# and mixing split and universal builds makes the next release look like a
# downgrade to every installed copy.
flutter build apk --release --split-per-abi \
  --dart-define=AWAN_UPDATE_REPO="$REPO"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$APK"

echo "== checksums"
cd "$OUT"
SUM=$(sha256sum "$(basename "$APK")" | awk '{print $1}')
printf '%s  %s\n' "$SUM" "$(basename "$APK")" > SHA256SUMS

ASSETS=("$APK")

echo "== delta"
if [ -z "$PREV" ]; then
  # The newest build in dist that is not this one, if any.
  PREV=$(ls -1 "$OUT"/Awan_v*-arm64-v8a.apk 2>/dev/null \
    | sed -E 's#.*Awan_v([0-9.]+)-arm64-v8a\.apk#\1#' \
    | grep -v "^${VERSION}$" | sort -V | tail -1 || true)
fi

if [ -n "$PREV" ] && [ -f "$OUT/Awan_v${PREV}-arm64-v8a.apk" ]; then
  "$PY" tools/make_patch.py \
    --from "$OUT/Awan_v${PREV}-arm64-v8a.apk" \
    --to "$APK" \
    --from-version "$PREV" --to-version "$VERSION" \
    --out "$OUT"
  PATCH="$OUT/${PREV}__${VERSION}.patch"
  if [ -f "$PATCH" ]; then
    PSUM=$(sha256sum "$(basename "$PATCH")" | awk '{print $1}')
    printf '%s  %s\n' "$PSUM" "$(basename "$PATCH")" >> SHA256SUMS
    ASSETS+=("$PATCH")
  fi
else
  echo "no previous arm64 build in dist — this release ships a full APK only"
fi

cat SHA256SUMS

cat <<EOF

== publish

  gh release create "v${VERSION}" \\
     $(printf '"%s" ' "${ASSETS[@]}")SHA256SUMS \\
     --repo "$REPO" --title "Awan ${VERSION}" --notes-file NOTES.md

Upload every file together: the app only offers a delta when it finds a patch
named for its own installed version, and falls back to the full APK when it
does not. Nothing is offered silently, and nothing is installed without the
checksum matching.
EOF
