#!/usr/bin/env bash
# Publish the current build to GitHub Releases using the credential that `git
# push` already uses. The token is read into a variable and never printed.
set -u

REPO="omaryounesEG/awan"
TAG="v1.23.0"
NOTES="dist/NOTES_1.23.0.md"
API="https://api.github.com/repos/$REPO"

cd "$(dirname "$0")/.." || exit 1

printf "protocol=https\nhost=github.com\n\n" | git credential fill > .gitcred.tmp 2>/dev/null
TOK=$(grep '^password=' .gitcred.tmp | cut -d= -f2-)
rm -f .gitcred.tmp
if [ -z "${TOK:-}" ]; then echo "no credential"; exit 1; fi

BODY=$(python -c "import json,sys; print(json.dumps({'tag_name':sys.argv[1],'name':'أَوَان 1.23.0','body':open(sys.argv[2],encoding='utf-8').read(),'draft':False,'prerelease':False}))" "$TAG" "$NOTES")

echo "$BODY" > .release.json
RESP=$(curl -sS --max-time 120 -X POST \
  -H "Authorization: token $TOK" \
  -H "Accept: application/vnd.github+json" \
  -H "Content-Type: application/json" \
  --data @.release.json "$API/releases")
rm -f .release.json
ID=$(printf '%s' "$RESP" | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('id',''))")
echo "release id: ${ID:-none}"
if [ -z "$ID" ]; then printf '%s\n' "$RESP" | head -c 600; exit 1; fi

for f in Awan_v1.23.0-arm64-v8a.apk Awan_v1.23.0-armeabi-v7a.apk 1.22.1__1.23.0.patch SHA256SUMS; do
  out=$(curl -sS --max-time 1800 -X POST \
    -H "Authorization: token $TOK" \
    -H "Content-Type: application/octet-stream" \
    --data-binary @"dist/$f" \
    "https://uploads.github.com/repos/$REPO/releases/$ID/assets?name=$f" \
    | python -c "import json,sys; d=json.load(sys.stdin); print(d.get('name','ERR'), d.get('size',''), d.get('state',''), d.get('error','') or '')")
  echo "$f -> $out"
done

echo "--- latest:"
curl -sS --max-time 60 "$API/releases/latest" \
  | python -c "import json,sys; d=json.load(sys.stdin); print(d['tag_name'], d['prerelease'], [ (a['name'], a['size']) for a in d['assets']])"
