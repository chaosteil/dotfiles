#!/usr/bin/env python3
"""Hint mode for Rex, like tmux-thumbs. Pick text from a pane by its hint.

Usage: thumbs.py SESSION TARGET SCREEN

The "thumbs" action in init.lua writes the visible lines of the TARGET pane
to the SCREEN file. Then it swaps this picker into the place of TARGET.
The picker shows the lines again, and puts a hint on each URL, path, hash,
IP address, and long number.

Keys:
  hint in lowercase  copy the text
  hint in uppercase  copy the text and type it into the pane
  backspace          remove the last hint letter
  Esc, Ctrl-C        stop without a copy

The shell command around the picker swaps the TARGET pane back when the
picker exits. Then the tab of the picker closes.
"""
import base64, fcntl, os, re, select, shutil, signal, struct, subprocess, sys, termios, tty

ALPHABET = "asdfqwerzxcvjklmiuopghtybn"

# In priority order. When two patterns start at the same column, the first
# one wins. A group named "v" selects the part of the match to copy.
PATTERNS = [
    r"\[[^\]]*\]\((?P<v>[^)\s]+)\)",                                 # markdown link
    r"(?:https?://|git@|git://|ssh://|ftp://|file:///)[^\s<>\"'`]+",  # URL
    r"--- a/(?P<v>\S+)",                                            # diff a/
    r"\+\+\+ b/(?P<v>\S+)",                                         # diff b/
    r"sha256:[0-9a-f]{64}",                                         # docker
    r"\b[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\b",
    r"(?:[\w.\-@~]+)?(?:/[\w.\-@]+)+(?::\d+){0,2}",                 # path[:line[:col]]
    r"#[0-9a-fA-F]{6}\b",                                           # color
    r"\b\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?\b",                        # IPv4[:port]
    r"\b0x[0-9a-fA-F]+\b",                                          # address
    r"\b[0-9a-f]{7,40}\b",                                          # git hash
    r"\b[k-z]{8,32}\b",                                             # jj change ID
    r"\b\d{4,}\b",                                                  # number
]
PATTERNS = [re.compile(p) for p in PATTERNS]

DIM = "\x1b[0;2m"
MATCH = "\x1b[0;32m"
HINT = "\x1b[0;1;30;43m"
RESET = "\x1b[0m"

session, target, screen_path = sys.argv[1:4]
out = sys.stdout


def rex(*args, **kw):
    """Run the rex CLI. Rex sets REX_BIN_DIR in its panes."""
    bin_dir = os.environ.get("REX_BIN_DIR")
    exe = os.path.join(bin_dir, "rex") if bin_dir else "rex"
    return subprocess.run([exe, *args], capture_output=True, text=True, **kw)


def trim_url(text):
    """Remove the punctuation that ends a sentence, and a ')' with no '('."""
    text = text.rstrip(".,;:!?'\"")
    while text.endswith(")") and text.count(")") > text.count("("):
        text = text[:-1].rstrip(".,;:!?")
    return text


def find(line):
    """The matches in one line, as (start, end) column pairs, left to right."""
    found, pos = [], 0
    while True:
        best = None
        for p in PATTERNS:
            m = p.search(line, pos)
            if m and (best is None or m.start() < best.start()):
                best = m
        if best is None:
            return found
        span = best.span("v") if "v" in best.re.groupindex else best.span()
        start, end = span
        end = start + len(trim_url(line[start:end]))
        if end > start:
            found.append((start, end))
        pos = max(best.end(), pos + 1)


def hints(n):
    """N hints, no hint is the start of another. Short hints come first."""
    if n <= len(ALPHABET):
        return list(ALPHABET[:n])
    keys, i = [""], 0
    while len(keys) - i < n:
        prefix = keys[i]
        i += 1
        keys.extend(prefix + c for c in ALPHABET)
    return keys[i:i + n]


def assign(lines):
    """Give each different text one hint. The lines near the bottom get the
    short hints, because the newest output is there."""
    spans, order = [], []
    for row in range(len(lines) - 1, -1, -1):
        for start, end in find(lines[row]):
            text = lines[row][start:end]
            spans.append((row, start, end, text))
            if text not in order:
                order.append(text)
    by_text = dict(zip(order, hints(len(order))))
    return [(row, start, end, text, by_text[text]) for row, start, end, text in spans]


def size():
    buf = fcntl.ioctl(out.fileno(), termios.TIOCGWINSZ, b"\0" * 8)
    rows, cols = struct.unpack("HHHH", buf)[:2]
    return rows, cols


def draw(lines, marks, typed):
    rows, _ = size()
    first = max(0, len(lines) - rows)
    by_row = {}
    for mark in marks:
        by_row.setdefault(mark[0], []).append(mark)
    buf = ["\x1b[?25l\x1b[?7l\x1b[H\x1b[2J"]
    for row in range(first, len(lines)):
        line = lines[row]
        buf.append(f"\x1b[{row - first + 1};1H{DIM}")
        col = 0
        for _, start, end, _, hint in sorted(by_row.get(row, []), key=lambda m: m[1]):
            buf.append(DIM + line[col:start])
            if hint.startswith(typed):
                rest = hint[len(typed):]
                buf.append(HINT + rest + MATCH + line[start + len(rest):end])
            else:
                buf.append(DIM + line[start:end])
            col = end
        buf.append(DIM + line[col:] + RESET)
    out.write("".join(buf))
    out.flush()


def copy(text):
    """Copy with pbcopy when there is one. Else ask the terminal with OSC 52."""
    if shutil.which("pbcopy"):
        subprocess.run(["pbcopy"], input=text, text=True)
        return
    data = base64.b64encode(text.encode()).decode()
    out.write(f"\x1b]52;c;{data}\x07")
    out.flush()


def pick(lines, marks):
    """Read keys until a hint is complete. Return (text, paste) or None."""
    full = {m[4]: m[3] for m in marks}
    typed, paste = "", False
    resized = os.pipe()
    signal.signal(signal.SIGWINCH, lambda *_: os.write(resized[1], b"x"))
    draw(lines, marks, typed)
    stdin = sys.stdin.fileno()
    while True:
        ready, _, _ = select.select([stdin, resized[0]], [], [])
        if resized[0] in ready:
            os.read(resized[0], 64)
            draw(lines, marks, typed)
        if stdin not in ready:
            continue
        for ch in os.read(stdin, 64).decode(errors="ignore"):
            if ch in "\x1b\x03\x07":
                return None
            if ch in "\x7f\x08":
                typed = typed[:-1]
                paste = paste and typed != ""
            elif ch.lower() in ALPHABET:
                paste = paste or (typed == "" and ch.isupper())
                typed += ch.lower()
                if typed in full:
                    return full[typed], paste
                if not any(h.startswith(typed) for h in full):
                    typed = typed[:-1]
            draw(lines, marks, typed)


def main():
    with open(screen_path) as f:
        lines = f.read().split("\n")
    os.unlink(screen_path)
    marks = assign(lines)
    if not marks:
        return

    result = None
    saved = termios.tcgetattr(sys.stdin)
    out.write("\x1b[?1049h")
    try:
        tty.setraw(sys.stdin)
        result = pick(lines, marks)
    finally:
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, saved)
        out.write("\x1b[?7h\x1b[?25h\x1b[?1049l")
        out.flush()

    if result:
        copy(result[0])
        if result[1]:
            rex("send", "-s", session, "-b", target, result[0])


if __name__ == "__main__":
    main()
