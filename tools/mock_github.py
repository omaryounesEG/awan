"""A stand-in for `api.github.com`, to exercise the updater end to end.

Serves a real GitHub-shaped `releases/latest` payload built from whatever APKs
and patches sit in a folder, plus the files themselves. Nothing pretends to be
production: it exists so the delta path can be proven on a device before any
repository is published.

    python tools/mock_github.py --dir build/release_mock --port 8099 \
        --repo saipconsulting/awan --tag v1.21.0

Then build the APK with `--dart-define=AWAN_UPDATE_API=http://10.0.2.2:8099`.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote

ARGS: argparse.Namespace


def sha256(path: str) -> str:
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()


def release_payload(host: str) -> dict:
    files = sorted(os.listdir(ARGS.dir))
    assets = []
    sums = []
    for name in files:
        path = os.path.join(ARGS.dir, name)
        if not os.path.isfile(path):
            continue
        if not (name.endswith(".apk") or name.endswith(".patch")):
            continue
        digest = sha256(path)
        assets.append(
            {
                "name": name,
                "size": os.path.getsize(path),
                "browser_download_url": f"http://{host}/files/{name}",
                "content_type": "application/octet-stream",
            }
        )
        sums.append(f"{digest}  {name}")
    return {
        "tag_name": ARGS.tag,
        "name": ARGS.tag,
        "body": "\n".join(sums),
        "published_at": "2026-10-17T00:00:00Z",
        "assets": assets,
    }


class Handler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, fmt: str, *args) -> None:  # quiet by default
        if ARGS.verbose:
            super().log_message(fmt, *args)

    def do_HEAD(self) -> None:
        self.do_GET(head_only=True)

    def do_GET(self, head_only: bool = False) -> None:
        path = unquote(self.path.split("?", 1)[0])
        host = self.headers.get("Host", f"127.0.0.1:{ARGS.port}")

        if path == f"/repos/{ARGS.repo}/releases/latest":
            body = json.dumps(release_payload(host)).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
            return

        if path == f"/repos/{ARGS.repo}":
            body = json.dumps({"full_name": ARGS.repo, "private": False}).encode()
            self.send_response(200)
            self.send_header("Content-Type", "application/json")
            self.send_header("Content-Length", str(len(body)))
            self.end_headers()
            if not head_only:
                self.wfile.write(body)
            return

        if path.startswith("/files/"):
            name = os.path.basename(path[len("/files/"):])
            target = os.path.join(ARGS.dir, name)
            if not os.path.isfile(target):
                self.send_error(404)
                return
            size = os.path.getsize(target)
            self.send_response(200)
            self.send_header("Content-Type", "application/octet-stream")
            self.send_header("Content-Length", str(size))
            self.send_header("Accept-Ranges", "none")
            self.end_headers()
            if head_only:
                return
            with open(target, "rb") as f:
                while True:
                    chunk = f.read(1 << 20)
                    if not chunk:
                        break
                    self.wfile.write(chunk)
            return

        self.send_error(404)


def main() -> int:
    global ARGS
    ap = argparse.ArgumentParser()
    ap.add_argument("--dir", required=True)
    ap.add_argument("--port", type=int, default=8099)
    ap.add_argument("--repo", default="saipconsulting/awan")
    ap.add_argument("--tag", default="v1.21.0")
    ap.add_argument("--verbose", action="store_true")
    ARGS = ap.parse_args()
    ARGS.port = ARGS.port

    server = ThreadingHTTPServer(("0.0.0.0", ARGS.port), Handler)
    print(f"mock github on :{ARGS.port}  repo={ARGS.repo}  dir={ARGS.dir}", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
