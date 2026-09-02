# UT99 Walk and Move Forward — Project Instructions

## Key Files

| File | Purpose |
|---|---|
| `UT99_WalkAndMoveForward.ahk` | AutoHotkey v1 tap-to-autorun script for UT99 — tap Mouse4 to walk forward hands-free, any key cancels |
| `UT99 Walk Forward.md` | Earlier research notes on the hold-to-walk `User.ini` alias (background, not the current solution) |
| `Readme.md` | Project readme — how the autorun works, setup, and tuning |

---

## Project Overview

Provides **tap-to-autorun** for Unreal Tournament 99. Tapping **Mouse4** once makes the player keep walking forward without holding any key; pressing any movement/action key — or tapping Mouse4 again — cancels it.

---

## Why an AHK script (and not just User.ini)

UT99's forward movement command `Axis aBaseY Speed=+300.0` only contributes movement **while a key is physically held**. The engine rebuilds all movement axes every frame from currently-held keys, so a single tap cannot leave a lasting forward velocity through aliases alone. The script bridges this: on a Mouse4 tap it physically **holds the `Backspace` key down**; `Backspace` is bound in `User.ini` to the existing `Walking` alias (`Button bRun | Axis aBaseY Speed=+300.0`), so the game walks forward until the script releases `Backspace`.

The user never presses `Backspace` — it is purely the channel between the script and the game.

---

## AutoHotkey Version

**AHK v1 only.** Do not use v2 syntax (fat-arrow functions, expression-only `if`, `A_Clipboard` as object, etc.).

---

## Required External Config

| Location | Setting | Purpose |
|---|---|---|
| `C:\UnrealTournament\System\User.ini` | `Backspace=Walking` | Binds the channel key to the existing `Walking` alias (`Aliases[18]`). Without this line the script holds a key the game ignores. |

`User.ini` must be edited with UT **closed** — UT overwrites it on exit.

---

## Key Implementation Notes

### Channel key = Backspace (must be non-extended)
`WALK_KEY := "Backspace"` in the script must match the key bound to `Walking` in `User.ini`. Change both together if a different spare key is preferred — but it **must be a non-extended key**. Extended keys (Insert, Home, End, Delete, Page Up/Down, the arrows — anything sending an `E0` scancode prefix) appear to break UT's `Button bRun` handling: forward movement keeps working but the walk modifier drops after ~1 second. Insert was the original choice and exhibited exactly this; Backspace (non-extended) was the fix.

### Repeat timer — required for the walk modifier (up+down re-press)
The forward `Axis aBaseY` responds to the key's held *state*, so a single injected key-down keeps you moving forward. But `Button bRun` (the walk modifier) is driven by the keyboard **auto-repeat stream** — a continuous flow of key-down events. A single injected key-down only sustains `bRun` for ~1 second, after which walk decays back to run. `StartAutorun()` arms `SetTimer, RepeatWalkKey, 100`, which re-presses the key 10×/sec; `StopAutorun()` turns the timer off and releases the key. The timer also auto-cancels if UT loses focus, so the key is never spammed into other windows.

**Critical — why up+down, not just down:** Windows **de-duplicates a redundant key-down** injected while the key is already held (no new `WM_KEYDOWN` is posted), so re-sending only `{down}` emits no fresh key-down events and `bRun` still decays — that was a failed attempt (both `Send`- and `keybd_event`-based). `RepeatWalkKey` therefore calls `WalkKeyUp()` **then** `WalkKeyDown()` each cycle: the brief release (microseconds, far shorter than a game frame, so forward stays smooth) makes the following key-down a genuine fresh press that re-arms `bRun`. Both use the Win32 `keybd_event` API via `DllCall`; VK / scan / extended-key values derive from `WALK_KEY` at startup (`GetKeyVK` / `GetKeySC`).

**Diagnostic history:** a *physically* held channel key (Backspace) sustains walk indefinitely — confirming the issue is injected-input-specific (the de-dup above), not the key or the engine. The original Mouse4 hold worked because mouse buttons never repeat *and* a held mouse button keeps `bRun` set without needing a repeat stream.

### Elevation
UT is launched elevated by `UT_Launcher.ahk`. A non-elevated process cannot send input to an elevated window (Windows UIPI), so the script self-elevates via `*RunAs` when run standalone, and inherits the admin token silently when launched from the (already elevated) launcher.

### Hotkey scope
All hotkeys are wrapped in `#IfWinActive ahk_exe UnrealTournament.exe`, so Mouse4 and the cancel keys behave normally in every other application.

### Cancel-key list
The `~`-prefixed cancel block lists every movement/combat/weapon key in the current `User.ini` so "any key cancels" holds in practice. Edit this list to add/remove keys. `~` lets each press still reach the game.

**Space (jump) uses a delayed cancel:** `~Space::` is handled separately from the shared cancel block. Instead of calling `StopAutorun()` immediately, it schedules a one-shot 20ms timer (`SetTimer, StopAfterJump, -20`). This keeps bRun active when UT processes the jump input. If `StopAutorun()` ran first, Backspace would release before UT sees the Space key-down, UT would see a running jump (no bRun), and Jumpboots would be consumed. The 20ms delay (~2 frames at 100fps) lets UT process the jump as a walking jump (no boots consumed), then autorun stops.

### Stuck-key safety
`OnExit("ReleaseOnExit")` releases the walk key (`WalkKeyUp()`) if autorun is active when the script exits, so it is never left logically held.

---

## Launcher Integration

`UT_Launcher.ahk` (in the `UT99 Launcher` project) launches this script at step 8c and closes it on UT exit via `WinClose, UT99_WalkAndMoveForward.ahk ahk_class AutoHotkey`. Update both projects' docs when changing that wiring.
