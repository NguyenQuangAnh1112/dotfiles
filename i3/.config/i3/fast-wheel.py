#!/usr/bin/env python3
"""Speed up vertical mouse-wheel scrolling on X11/i3.

Set WHEEL_SCROLL_MULTIPLIER in the environment to change speed.
Example: WHEEL_SCROLL_MULTIPLIER=5 ~/.config/i3/fast-wheel.py
"""
import os
import signal
import sys
import time

from Xlib import X, display, error
from Xlib.ext import xtest

MULTIPLIER = max(1, int(os.environ.get("WHEEL_SCROLL_MULTIPLIER", "4")))
BUTTONS = (4, 5)  # wheel up/down

running = True

def stop(_signum, _frame):
    global running
    running = False

signal.signal(signal.SIGTERM, stop)
signal.signal(signal.SIGINT, stop)


def main():
    d = display.Display()
    root = d.screen().root

    # Replace any previous instance started by i3 reload/restart.
    root.change_property(
        d.intern_atom("_PI_FAST_WHEEL_PID"),
        Xatom_cardinal(d),
        32,
        [os.getpid()],
    )

    for button in BUTTONS:
        try:
            root.grab_button(
                button,
                X.AnyModifier,
                False,
                X.ButtonPressMask,
                X.GrabModeAsync,
                X.GrabModeAsync,
                X.NONE,
                X.NONE,
            )
        except error.XError:
            pass
    d.sync()

    while running:
        if not d.pending_events():
            time.sleep(0.005)
            continue
        event = d.next_event()
        if event.type == X.ButtonPress and event.detail in BUTTONS:
            button = event.detail
            # Temporarily ungrab so fake wheel clicks go to the window under cursor.
            root.ungrab_button(button, X.AnyModifier)
            d.sync()
            for _ in range(MULTIPLIER):
                xtest.fake_input(d, X.ButtonPress, button)
                xtest.fake_input(d, X.ButtonRelease, button)
            d.sync()
            root.grab_button(
                button,
                X.AnyModifier,
                False,
                X.ButtonPressMask,
                X.GrabModeAsync,
                X.GrabModeAsync,
                X.NONE,
                X.NONE,
            )
            d.sync()

    for button in BUTTONS:
        root.ungrab_button(button, X.AnyModifier)
    d.sync()


def Xatom_cardinal(d):
    return d.intern_atom("CARDINAL")


if __name__ == "__main__":
    try:
        main()
    except Exception as exc:
        print(f"fast-wheel: {exc}", file=sys.stderr)
        sys.exit(1)
