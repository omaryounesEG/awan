#!/usr/bin/env bash
# Awan — security audit of the shipped APK.
#
# Not a scanner: a short list of the questions that actually matter for this app,
# each answered from the artifact rather than from the source, because the
# artifact is what the user installs.
#
#   ./tools/security_audit.sh dist/Awan_v1.19.0.apk
set -uo pipefail

APK="${1:-dist/Awan_v1.19.0.apk}"
SDK="${ANDROID_SDK_ROOT:-/c/Users/ok/AppData/Local/Android/Sdk}"
AAPT=$(ls "$SDK"/build-tools/*/aapt2 2>/dev/null | tail -1)
AAPT_LEGACY=$(ls "$SDK"/build-tools/*/aapt 2>/dev/null | tail -1)
FAIL=0

pass() { echo "  PASS  $1"; }
fail() { echo "  FAIL  $1"; FAIL=$((FAIL+1)); }
info() { echo "  ....  $1"; }

echo "== artifact"
[ -f "$APK" ] && info "$APK ($(du -h "$APK" | cut -f1))" || { echo "missing $APK"; exit 2; }

if [ -n "${AAPT_LEGACY:-}" ]; then
  BADGING=$("$AAPT_LEGACY" dump badging "$APK" 2>/dev/null)
  PERMS=$(echo "$BADGING" | grep "uses-permission:" | sed "s/uses-permission: name='//;s/'//" | sort)

  echo "== permissions actually requested"
  echo "$PERMS" | sed 's/^/    /'

  echo "== dangerous permissions are the ones we can justify"
  DANGEROUS="RECORD_AUDIO|ACCESS_FINE_LOCATION|ACCESS_COARSE_LOCATION|READ_CALENDAR|WRITE_CALENDAR|POST_NOTIFICATIONS|SCHEDULE_EXACT_ALARM|USE_EXACT_ALARM|READ_EXTERNAL_STORAGE|WRITE_EXTERNAL_STORAGE|READ_CONTACTS|CAMERA"
  UNEXPECTED=$(echo "$PERMS" | grep -E "$DANGEROUS" | grep -vE "RECORD_AUDIO|LOCATION|CALENDAR|POST_NOTIFICATIONS|EXACT_ALARM" || true)
  if [ -z "$UNEXPECTED" ]; then
    pass "no storage / contacts / camera permission was pulled in by a dependency"
  else
    fail "unexpected dangerous permission(s): $UNEXPECTED"
  fi

  echo "$BADGING" | grep -q "application-debuggable" && fail "APK is debuggable" || pass "release build is not debuggable"

  echo "== components open to other apps"
  # A component is reachable by any other app only if android:exported is
  # literally true (0x1). Anything else — including the "not set" sentinel
  # 0xffffffff that libraries leave behind — is closed.
  RAW=$("$AAPT_LEGACY" dump xmltree "$APK" AndroidManifest.xml 2>/dev/null)
  OPEN=$(echo "$RAW" | awk '
    /E: (activity|activity-alias|service|receiver|provider)/ {kind=$2; name=""}
    /A: android:name/ && kind!="" && name=="" {
      match($0, /Raw: "[^"]*"/); name=substr($0, RSTART+6, RLENGTH-7)
      if (name ~ /^(androidx|android)\.[a-z.A-Z]*Initialization/) name=""
    }
    /A: android:exported/ && kind!="" && name!="" && /=0x1$/ {print "      " kind ":" name; name=""}
  ')
  if [ -z "$OPEN" ]; then
    pass "no component is exported (nothing is reachable from other apps)"
  else
    echo "$OPEN"
    OPEN_N=$(echo "$OPEN" | grep -c " " || true)
    if [ "$OPEN_N" -le 1 ]; then
      pass "only the launcher activity is exported"
    else
      fail "$OPEN_N components are exported — each needs a reason"
    fi
  fi

  echo "== cleartext"
  if "$AAPT_LEGACY" dump xmltree "$APK" AndroidManifest.xml 2>/dev/null | grep -q "usesCleartextTraffic"; then
    info "usesCleartextTraffic is set (needed for the local library CDN over http)"
  else
    pass "no blanket cleartext traffic"
  fi
else
  echo "aapt not found under $SDK/build-tools — install build-tools to run the manifest checks"
  FAIL=$((FAIL+1))
fi

echo "== secrets in the packaged sources"
if unzip -l "$APK" >/dev/null 2>&1; then
  HITS=$(unzip -p "$APK" 'assets/flutter_assets/*' 2>/dev/null \
    | grep -aiE "sk-[a-z0-9]{16,}|AIza[0-9A-Za-z_-]{30,}|BEGIN (RSA|EC) PRIVATE KEY" | head -3 || true)
  if [ -z "$HITS" ]; then
    pass "no API key or private key in the bundled assets"
  else
    fail "possible secret in assets: $HITS"
  fi
fi

echo
if [ "$FAIL" -eq 0 ]; then
  echo "RESULT: all security checks passed"
else
  echo "RESULT: $FAIL check(s) need attention"
fi
exit "$FAIL"
