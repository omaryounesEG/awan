#!/usr/bin/env bash
# Attach the 1.23.0 artifacts to the release that already exists for the tag.
set -u

REPO="omaryounesEG/awan"
TAG="v1.23.0"
API="https://api.github.com/repos/$REPO"

cd "$(dirname "$0")/.." || exit 1

printf "protocol=https\nhost=github.com\n\n" | git credential fill > .gitcred.tmp 2>/dev/null
TOK=$(grep '^password=' .gitcred.tmp | cut -d= -f2-)
rm -f .gitcred.tmp
if [ -z "${TOK:-}" ]; then echo "no credential"; exit 1; fi

ID=$(curl -sS --max-time 60 -H "Authorization: token $TOK" "$API/releases/tags/$TAG" \
  | python -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
echo "release id: ${ID:-none}"
[ -z "$ID" ] && exit 1

for f in Awan_v1.23.0-arm64-v8a.apk Awan_v1.23.0-armeabi-v7a.apk 1.22.1__1.23.0.patch SHA256SUMS; do
  out=$(curl -sS --max-time 1800 -X POST \
    -H "Authorization: token $TOK" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"dist/$f" \
    "https://uploads.github.com/repos/$REPO/releases/$ID/assets?name=$f" \
    | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('name') or d.get('errors') or d.get('message'), d.get('size',''), d.get('state',''))")
  echo "$f -> $out"
done

echo "--- latest:"
curl -sS --max-time 60 "$API/releases/latest" \
  | python -c "import json,sys; d=json.load(sys.stdin); print(d['tag_name'], d['prerelease'], [(a['name'], a['size']) for a in d['assets']])"
