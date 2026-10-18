#!/usr/bin/env bash
# Add the 1.22.0 → 1.23.0 delta and refresh the checksum list on v1.23.0.
set -u

REPO="omaryounesEG/awan"
TAG="v1.23.0"
API="https://api.github.com/repos/$REPO"

cd "$(dirname "$0")/.." || exit 1
cd dist || exit 1

sha256sum Awan_v1.23.0-arm64-v8a.apk Awan_v1.23.0-armeabi-v7a.apk \
          1.22.1__1.23.0.patch 1.22.0__1.23.0.patch > SHA256SUMS
cat SHA256SUMS

cd .. || exit 1
printf "protocol=https\nhost=github.com\n\n" | git credential fill > .gitcred.tmp 2>/dev/null
TOK=$(grep '^password=' .gitcred.tmp | cut -d= -f2-)
rm -f .gitcred.tmp
[ -z "${TOK:-}" ] && { echo "no credential"; exit 1; }

ID=$(curl -sS --max-time 60 -H "Authorization: token $TOK" "$API/releases/tags/$TAG" \
  | python -c "import json,sys; print(json.load(sys.stdin).get('id',''))")
echo "release id: $ID"

# Replace SHA256SUMS: an asset name can exist only once per release.
SUMS_ID=$(curl -sS --max-time 60 -H "Authorization: token $TOK" "$API/releases/$ID/assets?per_page=100" \
  | python -c "import json,sys; print(next((a['id'] for a in json.load(sys.stdin) if a['name']=='SHA256SUMS'), ''))")
if [ -n "$SUMS_ID" ]; then
  curl -sS --max-time 60 -X DELETE -H "Authorization: token $TOK" "$API/releases/assets/$SUMS_ID" > /dev/null
  echo "removed old SHA256SUMS ($SUMS_ID)"
fi

for f in 1.22.0__1.23.0.patch SHA256SUMS; do
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
  | python -c "import json,sys; d=json.load(sys.stdin); print(d['tag_name'], d['prerelease']); [print(' ', a['name'], a['size'], a['state']) for a in d['assets']]"
