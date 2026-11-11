#!/usr/bin/env python3
"""usage: start TIME [NAME], toggle [ID], add SECONDS [ID], cancel [ID].
no arguments prints waybar json, list prints rofi rows. a bare TIME is minutes.
"""

import fcntl
import html
import json
import math
import os
from pathlib import Path
import re
import subprocess
import sys
import time
import uuid

DIRECTORY = Path(os.environ["XDG_RUNTIME_DIR"]) / "timers"
STATE = DIRECTORY / "state.json"


def command(*args):
    result = subprocess.run(args, capture_output=True, text=True, timeout=10, env={**os.environ, "LC_ALL": "C"})
    if result.returncode:
        raise ValueError(result.stderr.strip() or f"{args[0]} failed")
    return result.stdout


def refresh():
    # no bar running isn't a timer failure
    try:
        subprocess.run(["pkill", "-RTMIN+9", "waybar"], stderr=subprocess.DEVNULL, timeout=2)
    except (OSError, subprocess.TimeoutExpired):
        pass


def duration(text):
    if text.isdecimal():
        text += "m"
    output = command("systemd-analyze", "timespan", text)
    match = re.search(r"(?:us|μs):\s*(\d+)", output)
    seconds = int(match[1]) / 1_000_000 if match else 0
    if seconds < 1:
        raise ValueError("Use a duration of at least one second, e.g. 25m, 90s or 1h30m")
    return seconds


def remaining(timer):
    return max(0, timer["deadline"] - time.monotonic()) if timer["unit"] else timer["remaining"]


def ordered(timers):
    return sorted(timers, key=lambda key: remaining(timers[key]))


def label(timer):
    n = math.ceil(remaining(timer))
    hours, n = divmod(n, 3600)
    minutes, seconds = divmod(n, 60)
    clock = f"{hours}:{minutes:02}:{seconds:02}" if hours else f"{minutes}:{seconds:02}"
    return f"{clock} {timer['name']}"


def stop(timer):
    if timer["unit"]:
        # only the .timer: its service may be waiting on our lock
        command("systemctl", "--user", "stop", timer["unit"] + ".timer")


def arm(key, timer, seconds, timers):
    unit = "dotfiles-timer-" + uuid.uuid4().hex
    updated = {**timer, "unit": unit, "deadline": time.monotonic() + seconds,
               "remaining": seconds}
    previous = timers.get(key)
    timers[key] = updated
    # Record intent first: a crash before systemd starts is recoverable by the bar.
    write_state(timers)
    try:
        command("systemd-run", "--user", "--quiet", "--collect", "--expand-environment=no",
                "--unit=" + unit, f"--on-active={seconds}s", "--timer-property=AccuracySec=1s",
                "--property=Restart=on-failure", "--property=RestartSec=15s",
                "--description=" + timer["name"], sys.executable, str(Path(__file__).resolve()),
                "expire", key, unit)
    except (ValueError, OSError, subprocess.TimeoutExpired):
        if previous is None:
            timers.pop(key, None)
        else:
            timers[key] = previous
        write_state(timers)
        raise
    stop(timer)
    return updated


def display(timers):
    keys = ordered(timers)
    if not keys:
        return {"text": "", "tooltip": "", "class": ""}
    first = timers[keys[0]]
    text = html.escape(label(first))
    if len(keys) > 1:
        text += f" +{len(keys) - 1}"
    rows = [html.escape(label(timers[key])) + (" (paused)" if not timers[key]["unit"] else "")
            for key in keys]
    state = "paused" if not first["unit"] else "ending" if remaining(first) < 60 else "running"
    tooltip = "<b>timers</b>\n" + "\n".join(rows)
    tooltip += "\n\n<span alpha='60%'>click: pause · right-click: cancel\nscroll: ±1m · middle-click: menu</span>"
    return {"text": text, "tooltip": tooltip, "class": state}


def read_state():
    """Reject invalid state visibly; never silently discard reminders."""
    timers = json.loads(STATE.read_text()) if STATE.exists() else {}
    if not isinstance(timers, dict):
        raise ValueError(f"Invalid timer state: {STATE}")
    for key, timer in timers.items():
        if (not isinstance(timer, dict) or not isinstance(timer.get("name"), str)
                or not isinstance(timer.get("remaining"), (int, float))
                or not math.isfinite(timer["remaining"]) or timer["remaining"] < 0
                or not (timer.get("unit") is None or
                        re.fullmatch(r"dotfiles-timer-[0-9a-f]{32}", str(timer["unit"])))
                or (timer.get("unit") and
                    (not isinstance(timer.get("deadline"), (int, float))
                     or not math.isfinite(timer["deadline"])))):
            raise ValueError(f"Invalid timer {key} in {STATE}")
    return timers


def write_state(timers):
    temporary = STATE.with_suffix(".tmp")
    temporary.write_text(json.dumps(timers))
    temporary.replace(STATE)


def deliver(timer):
    """Keep state on failure; systemd retries and the bar can also recover it."""
    command("notify-send", "-u", "critical", "-a", "timer", "-i", "clock", "timer", timer["name"])


def main(args):
    action = args[0] if args else "show"
    if action not in {"show", "list", "start", "toggle", "add", "cancel", "expire"}:
        raise ValueError(__doc__)
    DIRECTORY.mkdir(parents=True, exist_ok=True)
    changed = False
    with (DIRECTORY / ".lock").open("w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        timers = read_state()
        # If the process died between unit creation and the state commit, or a
        # unit disappeared, the bar still delivers recorded due reminders.
        if action in {"show", "list"}:
            for key in list(timers):
                if timers[key]["unit"] and remaining(timers[key]) <= 0:
                    deliver(timers[key])
                    del timers[key]
                    write_state(timers)
        if action == "show":
            print(json.dumps(display(timers)))
            return
        if action == "list":
            for key in ordered(timers):
                timer = timers[key]
                print(f"{key} {label(timer)}" + (" (paused)" if not timer["unit"] else ""))
            return
        if action == "start":
            seconds = duration(args[1])
            name = " ".join(args[2:]) or args[1]
            name = " ".join(name.split())  # one line for rofi and notify-send
            key = uuid.uuid4().hex
            timers[key] = arm(key, {"name": name, "unit": None}, seconds, timers)
            changed = True
        elif action == "expire":
            key, unit = args[1:]
            # a cancelled or rearmed timer's old callback
            if key in timers and timers[key]["unit"] == unit:
                deliver(timers[key])
                del timers[key]
                changed = True
        else:
            index = 2 if action == "add" else 1
            key = args[index] if len(args) > index else next(iter(ordered(timers)), None)
            if key not in timers:
                raise ValueError("No timer selected")
            timer = timers[key]
            seconds = remaining(timer)
            if action == "cancel":
                stop(timer)
                del timers[key]
            elif action == "toggle" and timer["unit"]:
                stop(timer)
                timers[key] = {**timer, "unit": None, "remaining": seconds}
            elif action == "toggle":
                timers[key] = arm(key, timer, max(1, seconds), timers)
            elif action == "add":
                seconds += int(args[1])
                if seconds < 1 or remaining(timer) <= 0:
                    raise ValueError("A timer must have at least one second remaining")
                timers[key] = arm(key, timer, seconds, timers) if timer["unit"] else {**timer, "remaining": seconds}
            changed = True
        if changed:
            write_state(timers)
    if changed:
        refresh()


if __name__ == "__main__":
    try:
        main(sys.argv[1:])
    except (ValueError, OSError, IndexError, subprocess.TimeoutExpired) as error:
        print(f"timer: {error}", file=sys.stderr)
        sys.exit(1)
