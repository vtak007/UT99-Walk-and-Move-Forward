Combining Walk + Forward Movement on a Single Key in UT99

Overview: Yes, an alias is exactly the right tool here. UT99's User.ini supports chaining multiple input commands through the alias system, letting Mouse4 simultaneously hold the walk modifier and move forward — both as held-state commands.

---
How It Works

In UT99's input system, movement and modifier commands are held-state ("Button") commands. When you chain them with |, the engine treats both as active for the entire duration the key is held. Releasing Mouse4 drops both simultaneously.

---
Step-by-Step

Step 1 — Locate your User.ini

Typically found at:
C:\UnrealTournament\System\User.ini
Close UT99 before editing to prevent overwrites.

---
Step 2 — Find the [Engine.Input] section

Scroll down until you see:
[Engine.Input]
Look for the Aliases array — it starts at index 0 and has pre-filled default entries.

---
Step 3 — Add your alias

Find the first unused Aliases slot (they look like Aliases[X]=(Command="",Alias="")) and add:

Aliases[X]=(Command="MoveForward | Button bRun",Alias="WalkForward")

Replace X with the actual slot number. If all slots look populated, you can safely overwrite a blank/empty one.

▎ Note on Always Run: This assumes you have Always Run = ON (the competitive default). With Always Run ON, Button bRun acts as the walk modifier — it slows you to walking speed while held. If Always Run is OFF, flip the logic: Button bRun would be your run key instead, and you'd want to bind just MoveForward for walking.

---
Step 4 — Bind Mouse4 to the alias

Find the Mouse4 line under [Engine.Input] and change it:

Mouse4=WalkForward

If you prefer to skip the alias entirely, a direct pipe bind also works:

Mouse4=MoveForward | Button bRun

Both are functionally identical. The alias approach is cleaner if you ever want to reuse WalkForward on a second key.

---
Step 5 — Save and test

Launch UT99, hold Mouse4 — you should glide forward at walking speed. Release to stop completely.

---
Pitfalls to Watch

- Editing while UT is running: UT99 overwrites User.ini on exit, so always edit with the game closed.
- Alias slot conflicts: UT99 has ~40 alias slots. Don't reuse a slot that already has a functional alias (check for things like FeignDeath, BehindView, etc.).
- Mouse4 recognition: Some systems map Mouse4 differently. If the bind doesn't register, check UT's key capture screen to confirm it sees Mouse4 by that name — it may appear as MiddleMouseButton or similar depending on your driver.

---
Pro Modder Insight

Since you're running Nexgen, be aware that Nexgen's admin overlay and some HUD components can intercept mouse button events when the Nexgen panel is open. If Mouse4 stops responding mid-session with the overlay active, that's the culprit — not your bind. Also, if you ever want to extend this into a mutator that programmatically forces walk-forward on a trigger condition (e.g., when near a zone boundary), you'd use Pawn.bRun = 1 and Pawn.Acceleration.X = Pawn.AccelRate in UnrealScript — but for a pure client keybind solution, the alias above is the correct and sufficient approach.

✻ Cooked for 1m 3s

> Where is this "Always Run" setting located?

Finding the "Always Run" Setting in UT99

It lives in two places — in-game menu and directly in the INI.

---
In-Game Menu

Main Menu → Options → Preferences → Controls tab

The Preferences window is a tabbed dialog. Look for the Controls tab — "Always Run" is a checkbox near the top of the movement/control options.

Alternatively, some builds expose it via:
Main Menu → Options → Game Settings

---
Directly in the INI (faster)

Open UnrealTournament.ini and search for:

[Engine.PlayerPawn]
bAlwaysRun=True

Set it to True to enable (most competitive/server players leave it on), False to disable.

---
Quick Sanity Check

The easiest way to confirm its current state without digging through menus: drop into a local practice match and tap your walk key (currently Mouse4).

- If holding Mouse4 slows you down → Always Run is ON (correct for our alias)
- If holding Mouse4 speeds you up → Always Run is OFF, and the Button bRun in the alias acts as a run key rather than a walk modifier — you'd need to invert the logic

For your setup (dedicated DM server, competitive play), Always Run ON is almost certainly already your config. The alias we built assumes that.