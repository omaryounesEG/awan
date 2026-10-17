#!/usr/bin/env bash
# Build two consecutive x86_64 builds so a delta can be cut between them and
# exercised on the emulator. Split-per-abi is used because that is what ships:
# mixing split and non-split builds changes the versionCode base per ABI and
# makes the second build look like a downgrade.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH=/h/flutter/bin:$PATH
PY="/c/Users/ok/AppData/Local/Programs/Python/Python312/python.exe"

set_version() {
  "$PY" - "$1" "$2" <<'EOF'
import sys, re, io
name, num = sys.argv[1], sys.argv[2]
p = "pubspec.yaml"
s = io.open(p, encoding="utf-8").read()
s = re.sub(r"^version: .*$", f"version: {name}+{num}", s, count=1, flags=re.M)
io.open(p, "w", encoding="utf-8", newline="\n").write(s)
c = "lib/core/constants/app_constants.dart"
t = io.open(c, encoding="utf-8").read()
t = re.sub(r"appVersion = '[^']*'", f"appVersion = '{name}+{num}'", t, count=1)
io.open(c, "w", encoding="utf-8", newline="\n").write(t)
print(f"version -> {name}+{num}")
EOF
}

build() { # $1 name  $2 number
  set_version "$1" "$2"
  flutter build apk --release --split-per-abi \
    --dart-define=AWAN_UPDATE_REPO=saipconsulting/awan \
    --dart-define=AWAN_UPDATE_API=http://10.0.2.2:8099 > "build_${2}.log" 2>&1
  grep -E "^e: |FAILURE|Built" "build_${2}.log" | head -3
  cp build/app/outputs/flutter-apk/app-x86_64-release.apk "dist/Awan_v${1}_emulator_localapi.apk"
}

build 1.21.0 25
build 1.22.0 26
ls -la dist/Awan_v1.21.0_emulator_localapi.apk dist/Awan_v1.22.0_emulator_localapi.apk
