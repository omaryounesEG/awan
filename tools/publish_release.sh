#!/usr/bin/env bash
# Create the update repository (if it does not exist) and publish a release
# the in-app updater can actually read.
#
#   ./tools/publish_release.sh omaryounesEG/awan 1.22.0
#
# Requires `gh auth login` to have run once. Everything is idempotent: an
# existing repository is reused, and an existing release for the tag is
# updated rather than duplicated.
set -euo pipefail

REPO="${1:?usage: publish_release.sh <owner/repo> <version>}"
VERSION="${2:?usage: publish_release.sh <owner/repo> <version>}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DIST="$ROOT/dist"
GH="${GH_BIN:-/c/Users/ok/tools/gh/gh.exe}"
export GH_CONFIG_DIR="${GH_CONFIG_DIR:-/c/Users/ok/.config/gh}"

APK="$DIST/Awan_v${VERSION}-arm64-v8a.apk"
[ -f "$APK" ] || { echo "missing $APK — build it first" >&2; exit 1; }

echo "== auth"
"$GH" auth status >/dev/null 2>&1 || { echo "run: gh auth login" >&2; exit 1; }

echo "== repository"
if "$GH" repo view "$REPO" >/dev/null 2>&1; then
  echo "exists: $REPO"
else
  "$GH" repo create "$REPO" --public \
    --description "أَوَان | Awan — تطبيق إسلامي شامل يعمل دون إنترنت، مع تحديث ذاتي عبر GitHub Releases" \
    --homepage "https://github.com/$REPO"
fi

echo "== checksums"
cd "$DIST"
sha256sum "$(basename "$APK")" > SHA256SUMS
cat SHA256SUMS

echo "== release"
TAG="v${VERSION}"
if "$GH" release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  "$GH" release upload "$TAG" --repo "$REPO" --clobber "$APK" SHA256SUMS
else
  "$GH" release create "$TAG" --repo "$REPO" \
    --title "أَوَان ${VERSION}" \
    --notes-file NOTES.md \
    "$APK" SHA256SUMS
fi

echo "== verify (this is what the app asks for)"
curl -s "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -E '"tag_name"|"name": "Awan|"browser_download_url".*(apk|SHA256)' | head -6
