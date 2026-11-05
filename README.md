# BarFiller2

**Current repository status:** `main` remains the Franklet-tested Complete Install Test 2 baseline. Cioara's fresh-install defaults are on `dev/cioara-hardcoded-defaults` pending in-game acceptance; the independent Ctrl+drag candidate remains on `dev/ctrl-drag-grid`. See [`TESTING.md`](TESTING.md).

A self-contained, independently installable Windower fork of BarFiller with animated EXP fills, trailing sparkles, golden level-up echoes, auto-hide, saved positioning, and adjustable timing. Built collaboratively with A, based on original BarFiller by Morath86.

**This package fixes the incomplete Rename Test 1 installation. The approved Test 12 animations and active artwork remain unchanged.**

## Complete installation (no migration required)

1. Back up your previously working `Windower/addons/barfiller/` or `barfiller2/` directory and any existing settings before changing files.
2. In-game, unload the old addon with **`//lua u barfiller`** (if running). Also unload an older BarFiller2 before replacing its files: `//lua u barfiller2`.
3. Extract the **entire `barfiller2/` folder** from this ZIP into **`Windower/addons/`**. The main file must be `Windower/addons/barfiller2/barfiller2.lua`, with `statics.lua`, `bar_bg.png`, `bar_fg.png`, `moon.png`, `assets/`, `WORKFLOW.md`, and `TESTING.md` alongside it. Do **not** nest the folder inside `addons/barfiller/`.
4. Enter **`//lua l barfiller2`** in Windower (not `//load barfiller2`, which asks Windower to find a DLL plugin).
5. Type `//bf status` or `//bf preview gain`. The addon creates its own settings on first load; no `.cmd`, PowerShell script, internet download, or existing BarFiller installation is required.
6. When successful, update AddonManager/autoload profiles to load **barfiller2** instead of **barfiller**. Do not load both: both claim the `//bf` alias.

**Existing settings:** If you're upgrading an already-installed BarFiller2, leave its `data` folder and `settings.xml` untouched when extracting. The ZIP includes neither of these. If you specifically want to import preferences from the old original BarFiller, optionally copy its `data` tree and any `settings.xml` into `barfiller2` *after backing up both*, while avoiding overwriting any newer BarFiller2 settings. Imported stock image paths are redirected to BarFiller2's own folder.

**Rollback:** `//lua u barfiller2`, then `//lua l barfiller`; the old addon and its settings were never altered by this installation.

**What is bundled:** All required Lua modules, native and Trust-style art, the genuine original `moon.png`, and self-contained stock-compatible EXP logic and legacy image resources. The old background and foreground PNGs are lightweight compatible substitutes for two *hidden* legacy primitives; the visible custom gold/blue gauge and its assets are byte-for-byte unchanged from Test 12. Windower's standard Lua libraries (`config`, `files`, `packets`, `texts`, `images`, `chat`) are still provided by Windower itself, not this addon.

## Fresh-install defaults — Cioara preset (November 5, 2026)

New BarFiller2 profiles use Cioara's effective saved layout: gold skin, compact scale **0.9**, width **420**, initial position **X=3209, Y=2124.9** on a 3840×2160 client, gold-only hybrid level-up artwork, text level digits, gain sparkles, 5.5-second arrival fade and 60-second auto-hide. The existing positioning code clamps the coordinates on smaller displays.

These are **defaults**, not forced overrides. Existing character/global settings are left untouched; the code does not overwrite `data/` or `settings.xml`. Fresh profiles start with historical Test 9/11/12 preset migration markers completed so scale 0.9 is not unexpectedly rescaled to 1.2. Existing profiles retain the previous migration behavior.

## Controls

| Command | Behavior |
|---|---|
| `//bf` | Reveals the auto-hidden bar and prints a concise command reminder; does **not** restart EXP motion |
| `//bf help` | Complete chat-only colored command guide |
| `//bf status` | Version, mode/visibility, job/level, position, skin, scale, timing, and main toggles |
| `//bf show` | Refreshes visibility without resetting EXP |
| `//bf hide` | Manually hides the bar until `//bf` or `//bf show` |
| `//bf auto` | Restores automatic timed visibility |
| `//bf restart` / `//bf reload` | Reinitializes **BarFiller2** by reloading the addon |
| `//bf unload` | Unloads **BarFiller2** |
| `//bf skin gold` / `blue` | Selects bar skin; gold default |
| `//bf preview gain` / `goldonly` / `level` / `nogold` | Run previews without modifying EXP |
| `//bf gainfade 5.5` | Arrival-glow cooldown in seconds (unrestricted finite nonnegative) |
| `//bf levelramp 2` | Level-up lead-in time |
| `//bf autohide 60` / `off` | Idle fade controls |
| `//bf move` / `lock` / `unlock` | Draggable positioning |
| `//bf scale 0.9` | Sets compact scale; Cioara-derived fresh-install default |
| `//bf details tnl on` | Toggle additional readouts |
| `//bf levelsize 15` | Size of level number |
| `//bf jobbold off` | Unbolded job name; default |
| `//bf leveldigits text` / `native` | Regular versus native digit rendering |

Aliases: `//bf2` and `//barfiller2`. The original `//barfiller` alias is intentionally **not** claimed by this fork.

The additional commands are documented by `//bf help`. No gameplay animation timings were changed for this rename.

## Known limitations

- EXP is supported; merit, capacity/job and exemplar/master points are future work.
- The new Cioara defaults candidate needs a live first-load test; Franklet previously confirmed the Complete Install Test 2 baseline loads. Static checks cannot prove live rendering.
- The module `statics.lua` is a locally bundled stock-compatible adaptation rather than a verbatim upstream file. The original BarFiller background/foreground resources are approximations, and the legacy bar primitives are hidden in BarFiller2's active gauge mode. The genuine moon art is bundled.
- The historical local ZIP predates the GitHub repository; the current untested defaults candidate is tracked on a separate development branch, while `main` remains known-good.
- Loading original BarFiller and BarFiller2 together conflicts over `//bf`.

## Credits and license

Original BarFiller code: **Morath86**. BSD license disclaimer retained in `barfiller2.lua`; the bundled adapted `statics.lua` retains the original BSD-style attribution and disclaimer. Trust-style textures: CyriteGameStudios/Trust. Sprite-derived native digits: FFXI 51.DAT; the stylized gold `Level Up!!` art is not a native DAT asset. Custom design and code: Awake (A) with user testing and direction.

## Cumulative changelog

- **Cioara hardcoded defaults (2026-11-05, development candidate):** Fresh-install position/scale match Cioara's 4K settings; approved existing gold/animation defaults retained, new-profile migration markers completed, existing saved settings preserved. Pending live testing.

- **BarFiller2 Complete Install Test 2 (2026-10-16):** Bundled stock-compatible `statics.lua`, original moon image and self-contained hidden legacy background/foreground resources; eliminated migration scripts and first-install dependency; corrected instructions and moved current workflow/testing documentation inside addon directory. BarFiller2 animation modules and custom art unchanged.

- **BarFiller2 rename test 1 (2026-10-15):** Independent addon name/folder/main file, preserved `//bf`, new `//bf2` and `//barfiller2` aliases, corrected lifecycle targets, own data location, non-destructive saved-setting migration, path retargeting for known stock assets, bare-command reveal/short help, fuller colored help, `status`, `show`/`hide`/`auto`. Animation modules and art unchanged from Test 12.
- **BarFiller Test 12:** Longer 5.5-second gain cooldown, chained gain glow continuity, uncapped finite nonnegative animation-duration controls, approved gold/typography defaults, auto-hide outline fade.
- **BarFiller Tests 10–11:** Gold-only level-up presentation, level-number sparkles, 2-second level buildup, independent long afterglows, scaling and visibility refinements.
- **BarFiller Tests 5–9:** Actual FFXI native font/digit artwork experiments, return to crisp type, gold echo effects, trailing cross-sparkle gains, integrated previews.
- **Earlier prototypes:** Trust-textured blue/gold EXP gauge and controller-friendly drag/scale controls.
