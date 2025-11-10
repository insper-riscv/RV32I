#!/usr/bin/env python3
"""
pad_bin.py -- pad a binary file to a 4-byte boundary (append 0x00 bytes)
Usage:
    python3 tools/pad_bin.py <file>
Exit codes:
    0 success
    1 file not found
    2 other IO error
"""
import sys
import os

def pad_file(path):
    try:
        if not os.path.exists(path):
            print(f"pad_bin.py: file not found: {path}", file=sys.stderr)
            return 1
        with open(path, "rb") as f:
            data = f.read()
        pad = (-len(data)) % 4
        if pad:
            data += b"\x00" * pad
            with open(path, "wb") as f:
                f.write(data)
            print(f"pad_bin.py: padded {path} with {pad} byte(s)")
        else:
            # nothing to do
            print(f"pad_bin.py: {path} already aligned (len={len(data)})")
        return 0
    except Exception as e:
        print(f"pad_bin.py: error: {e}", file=sys.stderr)
        return 2

def main():
    if len(sys.argv) != 2:
        print("Usage: pad_bin.py <file>", file=sys.stderr)
        sys.exit(2)
    rc = pad_file(sys.argv[1])
    sys.exit(rc)

if __name__ == "__main__":
    main()
