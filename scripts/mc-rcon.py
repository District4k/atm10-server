#!/usr/bin/env python3
"""Send a Minecraft RCON command.

Usage:
  RCON_PASSWORD=secret mc-rcon.py say hello
  RCON_PASSWORD=secret mc-rcon.py 127.0.0.1 25575 say hello
"""
from __future__ import annotations

import os
import socket
import struct
import sys


def _send(sock: socket.socket, req_id: int, req_type: int, payload: str) -> tuple[int, int, str]:
    body = payload.encode("utf-8") + b"\x00\x00"
    pkt = struct.pack("<ii", req_id, req_type) + body
    sock.sendall(struct.pack("<i", len(pkt)) + pkt)
    data = b""
    while len(data) < 4:
        chunk = sock.recv(4 - len(data))
        if not chunk:
            raise OSError("rcon closed")
        data += chunk
    (length,) = struct.unpack("<i", data)
    data = b""
    while len(data) < length:
        chunk = sock.recv(length - len(data))
        if not chunk:
            raise OSError("rcon short read")
        data += chunk
    resp_id, resp_type = struct.unpack("<ii", data[:8])
    return resp_id, resp_type, data[8:-2].decode("utf-8", errors="replace")


def rcon(host: str, port: int, password: str, command: str, timeout: float = 8.0) -> str:
    sock = socket.create_connection((host, port), timeout=timeout)
    try:
        sock.settimeout(timeout)
        resp_id, _, _ = _send(sock, 1, 3, password)
        if resp_id == -1:
            raise OSError("rcon auth failed")
        _, _, out = _send(sock, 2, 2, command)
        return out
    finally:
        sock.close()


def main() -> int:
    args = sys.argv[1:]
    host = os.environ.get("RCON_HOST", "127.0.0.1")
    port = int(os.environ.get("RCON_PORT", "25575"))
    password = os.environ.get("RCON_PASSWORD", "")

    if len(args) >= 3 and args[1].isdigit():
        host = args[0]
        port = int(args[1])
        command = " ".join(args[2:])
    elif args:
        command = " ".join(args)
    else:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    if not password:
        print("RCON_PASSWORD is not set", file=sys.stderr)
        return 2

    try:
        print(rcon(host, port, password, command), end="")
        return 0
    except OSError as exc:
        print(f"rcon failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
