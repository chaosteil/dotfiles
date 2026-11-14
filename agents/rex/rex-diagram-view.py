#!/usr/bin/env python3
"""Show a PNG with the kitty graphics protocol, fit to the terminal.

Usage: rex-diagram-view.py PNG

Keys: r loads the file again, q and Esc quit. The view draws again when the
terminal changes its size. The viewer waits for keys and signals only. It
does not poll.
"""
import base64, fcntl, os, select, signal, struct, sys, termios, tty

PNG_MAGIC = b"\x89PNG\r\n\x1a\n"
FOOTER = " q quit · r reload "

path = sys.argv[1]
out = sys.stdout.buffer


def cells():
    buf = fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
    rows, cols, xpx, ypx = struct.unpack("HHHH", buf)
    return rows, cols, xpx, ypx


def load():
    """The PNG data and its size, or None and a message."""
    try:
        with open(path, "rb") as f:
            data = f.read()
    except OSError as e:
        return None, f"cannot read {path}: {e.strerror}"
    if len(data) < 24 or not data.startswith(PNG_MAGIC):
        return None, f"not a PNG: {path}"
    return data, None


def draw():
    rows, cols, xpx, ypx = cells()
    out.write(b"\x1b_Ga=d,d=A,q=2\x1b\\\x1b[2J\x1b[H")
    data, msg = load()
    if data is None:
        out.write(msg[:cols].encode())
    else:
        iw, ih = struct.unpack(">II", data[16:24])
        cw = xpx / cols if xpx else 10
        ch = ypx / rows if ypx else 20
        avail_r = max(1, rows - 1)
        scale = min(cols * cw / iw, avail_r * ch / ih)
        c = max(1, int(iw * scale / cw))
        r = max(1, int(ih * scale / ch))
        left = (cols - c) // 2
        top = (avail_r - r) // 2
        out.write(f"\x1b[{top + 1};{left + 1}H".encode())
        b64 = base64.standard_b64encode(data)
        first = True
        while b64:
            chunk, b64 = b64[:4096], b64[4096:]
            m = 1 if b64 else 0
            head = f"a=T,f=100,q=2,C=1,c={c},r={r},m={m}" if first else f"m={m}"
            out.write(b"\x1b_G" + head.encode() + b";" + chunk + b"\x1b\\")
            first = False
    out.write(f"\x1b[{rows};1H\x1b[2m{FOOTER}\x1b[0m".encode())
    out.flush()


# SIGWINCH writes a byte to the wakeup pipe, so select wakes up.
wake_r, wake_w = os.pipe()
os.set_blocking(wake_w, False)
signal.set_wakeup_fd(wake_w)
signal.signal(signal.SIGWINCH, lambda *_: None)

fd = sys.stdin.fileno()
old = termios.tcgetattr(fd)
tty.setcbreak(fd)
out.write(b"\x1b[?25l")
try:
    draw()
    while True:
        ready, _, _ = select.select([fd, wake_r], [], [])
        if wake_r in ready:
            os.read(wake_r, 64)
            draw()
        if fd in ready:
            k = os.read(fd, 1)
            if not k or k in (b"q", b"\x1b"):
                break
            if k == b"r":
                draw()
finally:
    out.write(b"\x1b_Ga=d,d=A,q=2\x1b\\\x1b[2J\x1b[?25h")
    out.flush()
    termios.tcsetattr(fd, termios.TCSADRAIN, old)
