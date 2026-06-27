# UT99 Walk and Move Forward

Tap-to-autorun for Unreal Tournament 99. **Tap Mouse4 once to keep walking forward hands-free; press any movement/action key (or tap Mouse4 again) to stop.**

---

## How it works

UT99 only moves you forward while a movement key is *physically held* — the engine rebuilds movement every frame from the keys currently down, so a single tap can't leave you running on its own.

This AutoHotkey script bridges that gap:

1. You **tap Mouse4** (XButton1).
2. The script **holds down the `Backspace` key** for you (via the Win32 `keybd_event` API).
3. `User.ini` binds `Backspace` to the `Walking` alias (`Button bRun | Axis aBaseY Speed=+300.0`), so the game keeps walking you forward.
4. Pressing any movement/action key — or tapping Mouse4 again — makes the script **release `Backspace`**, stopping you.

You never press `Backspace` yourself; it is just the wire between the script and the game.

> **Why Backspace and not Insert?** The channel key must be **non-extended**. Extended keys (Insert, Home, End, Delete, Page Up/Down, the arrows) send an `E0` scancode prefix that breaks UT's `Button bRun` handling — forward movement still works but walk speed drops back to run after ~1 second. Backspace is a plain, non-extended key and avoids this.

---

## Setup

1. **Edit `User.ini`** (with UT **closed**) at `C:\UnrealTournament\System\User.ini` so the `Backspace` bind reads:
   ```
   Backspace=Walking
   ```
   (The existing `Walking` alias, `Aliases[18]`, is unchanged.)
2. **Run the script** — either standalone (it self-elevates with one UAC prompt) or, normally, let `UT_Launcher.ahk` start it automatically alongside UT.

---

## Usage

| Action | Result |
|---|---|
| Tap **Mouse4** | Start walking forward, hands-free |
| Tap **Mouse4** again | Stop |
| Press any movement/combat key (W/A/S/D, fire, jump, weapon switch, etc.) | Cancels autorun immediately |

Hotkeys are only active while Unreal Tournament is the foreground window.

---

## Tuning

- **Different channel key:** change `WALK_KEY` in the script *and* the matching `User.ini` bind to any spare key.
- **Cancel keys:** edit the `~`-prefixed hotkey block to add or remove keys that cancel autorun.

---

## Requirements

- AutoHotkey **v1**
- `Backspace=Walking` present in `User.ini` (a non-extended channel key)
- Must run elevated (UT runs elevated; matched automatically when started by `UT_Launcher.ahk`)
