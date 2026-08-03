#!/usr/bin/env python3
"""Serve a bundle directory on an ephemeral loopback port."""

from __future__ import annotations

import functools
import http.server
from pathlib import Path
import sys


def main() -> None:
    if len(sys.argv) != 3:
        raise SystemExit("usage: serve-bundle.py SERVE_DIR PORT_FILE")

    serve_dir = Path(sys.argv[1]).resolve()
    port_file = Path(sys.argv[2])
    handler = functools.partial(
        http.server.SimpleHTTPRequestHandler,
        directory=serve_dir,
    )
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    port_file.write_text(str(server.server_address[1]), encoding="utf-8")
    try:
        server.serve_forever()
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
