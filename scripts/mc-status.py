#!/usr/bin/env python3
"""Minecraft server-list ping: print online player count. Exit 2 if unreachable."""
from __future__ import annotations

import json
import socket
import struct
import sys


def _varint(n: int) -> bytes:
    out = bytearray()
    while True:
        b = n & 0x7F
        n >>= 7
        out.append(b | (0x80 if n else 0))
        if not n:
            return bytes(out)


def _read_varint(sock: socket.socket) -> int:
    n = 0
    shift = 0
    while True:
        b = sock.recv(1)
        if not b:
            raise OSError("closed")
        val = b[0]
        n |= (val & 0x7F) << shift
        if not val & 0x80:
            return n
        shift += 7
        if shift > 35:
            raise OSError("varint too long")


def player_count(host: str, port: int, timeout: float = 8.0) -> int:
    sock = socket.create_connection((host, port), timeout=timeout)
    try:
        sock.settimeout(timeout)
        host_b = host.encode("utf-8")
        handshake = _varint(0) + _varint(765) + _varint(len(host_b)) + host_b + struct.pack(">H", port) + _varint(1)
        sock.sendall(_varint(len(handshake)) + handshake)
        sock.sendall(_varint(1) + _varint(0))
        _read_varint(sock)
        _read_varint(sock)
        length = _read_varint(sock)
        data = b""
        while len(data) < length:
            chunk = sock.recv(length - len(data))
            if not chunk:
                raise OSError("short json")
            data += chunk
        payload = json.loads(data.decode("utf-8"))
        return int(payload.get("players", {}).get("online", 0))
    finally:
        sock.close()


def main() -> int:
    host = sys.argv[1] if len(sys.argv) > 1 else "127.0.0.1"
    port = int(sys.argv[2]) if len(sys.argv) > 2 else 25565
    try:
        print(player_count(host, port))
        return 0
    except (OSError, TimeoutError, json.JSONDecodeError, KeyError, ValueError) as exc:
        print(f"unreachable: {exc}", file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
