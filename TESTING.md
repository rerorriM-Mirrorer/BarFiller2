# TESTING.md — BarFiller2 (cumulative)

## Current Development Status — October 18, 2026 (America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/BarFiller2` / `dev/ctrl-drag-grid`.
- **Starting source checkpoint:** `BarFiller2_CtrlDrag_Grid_Test3_Complete.zip` (SHA-256 `8aedddaaedd55206878a85feb0b4b547d05b9e635a92863ddfbc086612c28c8e`); code and assets carried forward from the complete package, with documentation updated for this repository.
- **Runtime:** Windower 4 Lua addon; no external addon's files or DLL are required.
- **Most recent user-confirmed live behavior:** Complete Install Test 2 successfully loaded for Franklet (2026-10-16); previously approved Test 12's EXP and level-up visuals were retained. This does NOT certify every animation/command on Franklet.
- **Automation/static verification:** Packaging and content comparison against the source ZIP, syntax parsing, and source-level checks. These are not Windows/FFXI game tests.
- **Remaining:** Live Ctrl+drag on both Ctrl keys, lock handling, boundary behavior, settings persistence and multibox interference.
- **Next:** In-game test on Franklet and/or other characters, report any unexpected input behavior..

### Repository publication — October 18, 2026

- Populate a dedicated repository without introducing runtime changes to the archived source package. The `main` branch holds the most recent user-confirmed loading baseline; Ctrl+drag experiment remains on a separate working branch.
- `AGENTS.md` and `WORKFLOW.md` adopt the latest canonical NPCmirror documentation, including current-development-status methodology.
- Keep original cumulative Test 1–3 reports and distinguish prior simulated checks from in-game observations. No new in-game testing was performed during repository initialization.
- This document identifies the starting ZIP by SHA-256; the publication commit SHA is in GitHub history and the delivery handoff (it must not be embedded in the commit that defines it).

---


## Current testing batch — Ctrl+drag Grid Test 3 (2026-10-17)

**Request / motivation:** Match EnemyBar2's Ctrl+drag alignment without modifying approved BarFiller Test 12 animations or the successful Complete Install Test 2. Explain common layout anchors vs individual drawn primitives to guide future addons.

**Sources reviewed:** NPCMirror `AGENTS.md`, `WORKFLOW.md`, and `TESTING.md` on `rerorriM-Mirrorer/ffxi-NPCmirror@main`; EnemyBar2 `AGENTS.md`, `WORKFLOW.md`, `TESTING.md` on `rerorriM-Mirrorer/enemybar2@master`, plus the actual Ctrl/drag implementation on `underbar-glow-2026-10-17` (event codes 29/157, 10px floor grid, group translation); Windower `addons/libs/images.lua` mouse handler on `dev`; Complete Install Test 2 ZIP.

**Changes:** Only `barfiller2.lua` runtime code changed: hold left/right Ctrl while dragging to snap the single widget anchor to a fixed screen-origin grid; default `DragGrid=10`; `//bf grid [positive whole pixels]`, help/status; viewport-aware snap fallback. All active animation modules, images, and underlying EXP handling unchanged. Added layout explanation and updated usage documentation. No data/settings shipped, preserving existing preferences.

**Simulated checks:** All 6 bundled Lua modules parse with `texlua` (not strict Lua 5.1 verification). Executed the real BarFiller2 startup + keyboard callbacks, snap/free-drag paths, status, grid command, layout scale change and invalid grid rejection against stub Windower image/text and game APIs; **passed**. Boundary stress test: when a scaled widget cannot reach a requested snapped position, choose the last valid grid multiple in the screen instead of an off-grid clamp. File hash comparison confirmed **all 59 other original package files (including 5 other Lua modules, images and AGENTS/WORKFLOW guides) unchanged**; unit mock does not test actual Windower mouse dispatch ordering or native glyph rendering.

**Live FFXI tests requested:**
1. Back up working `addons/barfiller2/` and its `data/` settings. Unload `//lua u barfiller2` then replace files with complete Test 3 folder and `//lua l barfiller2`.
2. Verify `//bf status` and `//bf grid` show `10`; `//bf grid 10` keeps the shared grid; `//bf help` documents controls.
3. Drag normally (1px precision) and hold **left Ctrl** to snap to 10px screen-origin increments; release Ctrl and drag freely. Repeat with right Ctrl, including pressing both and releasing one.
4. Test `//bf scale 1` and `//bf scale 2` (or smaller), various window sizes, viewport edges and saved positions across reload.
5. Verify `//bf lock` disables drag and `//bf unlock` restores it. Confirm the original `//bf preview gain` and `//bf preview goldonly` still behave exactly like Test 2 and auto-hide/reveal is unaffected.
6. Report if Windower's mouse handler behaves differently than the simulated images.lua callback order; Test 2 is rollback baseline.

**Associated commit:** None; testing ZIP prepared locally and not pushed to a repository. BarFiller2 has no dedicated repository/working branch yet. This is *not* a GitHub-published testing batch; repository setup and a coherent commit remain pending.

**Delivery:** `BarFiller2_CtrlDrag_Grid_Test3_Complete.zip` — full standalone installation for testing; no original BarFiller dependency.

**User gameplay observations:** 2026-10-17: user confirmed Complete Install Test 2 works on Franklet; requested EnemyBar2-style Ctrl+drag snapping and an explanation of grid anchors and primitives. User observed that EnemyBar2 text and boundaries can drift relative to one another at different scales; no fix to EnemyBar2 was requested or made in this batch.

---

## Current testing batch — Complete Install Test 2 (2026-10-16)

**Goal:** A complete, directly installable `barfiller2` package that does not need another addon, a Windows batch script, or an extra download. Resolves the missing `statics.lua` and three PNG dependencies reported when trying to load on Franklet.

**Source:** BarFiller2 Rename Test 1 ZIP plus its Test 12 animation baseline; upstream Windower/Lua `addons/barfiller/statics.lua` consulted for stock behavior and requirements. NPCmirror current `WORKFLOW.md` and `AGENTS.md` reviewed.

**Changes:** Packaged a stock-compatible implementation of legacy EXP tracking, the genuine upstream moon icon, and two lightweight images for the hidden stock background/foreground primitives. Removed MIGRATE.cmd / MIGRATE.ps1 so first install is truly extract-and-load; no script execution or other BarFiller copy required. Moved README, WORKFLOW, TESTING into the addon folder per latest instructions. Advanced version identifier for diagnosis. No changes to the four active animation modules or the custom art assets.

**Install / smoke checklist:**
1. Unload BarFiller and any prior BarFiller2. Back up settings and working Test 12.
2. Extract `barfiller2/` into `Windower/addons/` (no folder nesting). Keep existing `barfiller2/data` without overwriting it.
3. `//lua l barfiller2`; report exact Windower console text if an error appears. Do NOT use `//load barfiller2` (DLL/plugin command).
4. `//bf status`, `//bf`, `//bf preview gain`, `//bf preview goldonly`.
5. Verify the 5.5-second arrival fade, level-up celebrations, autohide, moved/scaled positions and relog on Franklet. Verify the old `barfiller/` was not modified.

**Verification:** New legacy module and all bundled Lua modules were syntax checked; files validated in archive. Legacy module was smoke-tested with stand-in Windower image/text APIs. Original four animation modules and all original art copied byte-for-byte from Rename Test 1. Real game testing **not performed**.

**Repository / branch:** No dedicated BarFiller2 repository or branch established; this is a local ZIP, not committed or pushed. The fork `rerorriM-Mirrorer/Windower-Addons` (dev) was reviewed for shared conventions only; it was not changed.

**Correction to Rename Test 1:** ~~The addon is complete after running a migration script.~~ That package lacked `statics.lua` and three stock resources, so it would not run on a clean machine. This package removes the requirement and includes all runtime support files.

**New delivery:** `BarFiller2_Complete_Install_Test2.zip` — static/test delivery, gameplay verification pending.

---

## Preserved historical Rename Test 1 testing record (2026-10-15)


**Read this first.** Current batch: **BarFiller2 Rename Test 1**, 2026-10-15. Source baseline: user-tested BarFiller Test 12 (`BarFiller_Test12_LongGlow_UncappedDuration.zip`).

**Commit(s):** None yet — ZIP prepared locally, **not committed or pushed**. This package is not a published GitHub release. Adopt a dedicated BarFiller2 development repo/branch before declaring the next published batch.

## Installation precautions

1. Back up the original `addons/barfiller` directory and saved settings. **Do not delete it.**
2. Unload stock BarFiller. Do not load `barfiller` and `barfiller2` together (both claim `//bf`).
3. Extract only the `barfiller2/` subfolder into `Windower/addons`. The ZIP-root `WORKFLOW.md` and `TESTING.md` belong with test records, not over shared files already in `Windower/addons`.
4. Run `barfiller2/MIGRATE.cmd` once. Verify it copies stock `statics.lua`, three stock images and saved `data` files without modifying or overwriting the original.
5. Load `//lua l barfiller2`; run `//bf status`, `//bf`, `//bf preview gain`, `//bf preview goldonly`.
6. Change AddonManager global/character profiles to load **barfiller2**, not **barfiller**.
7. Test `//bf hide`, bare `//bf`, `//bf autohide 60`, `//bf help`, `//bf restart`, `//bf unload`. Test settings survive restart and do not change the old settings files.

## What changed

- Renamed main addon and installation directory; stock addon untouched.
- New commands: bare `//bf` reveals bar + short chat-only guide, `help`, `status`, `show`, `hide`, `auto`, `restart`; old animation controls remain.
- Reload/unload target the new addon.
- New own config/data folder copied *once* from the old addon. Imported absolute paths to known original stock PNGs retarget to new folder.
- Same Test 12 animation modules, including glow and sparkle behavior (no new animation tuning).

## Static and regression checks

- `texlua loadfile` parses the five Lua files: **passed** (not a Lua 5.1-aware linter; cannot verify Windower runtime APIs).
- Mocked Windower startup and bare/status/help/show/hide/auto/preview/restart/unload commands: **passed** under `texlua`; does not cover actual FFXI rendering or Windows filesystem migration.
- Check that `trust_gauge.lua`, `level_art.lua`, `native_digits.lua` and `native_dimensions.lua` are byte-for-byte identical to Test 12: **passed**.
- Package excludes `data/`, `settings.xml` and stock `statics.lua`; imported at install time, never overwritten in original.
- Windows PowerShell migration script reviewed statically, but not run on a Windows game installation.
- Actual FFXI/Windower smoke and live tests: **not yet performed**.

## Gameplay tests needed

- Ordinary gain: baseline 5.5-second motion and 5.5-second white cooldown unchanged.
- Chained gains continue alpha without dark reset.
- Real level-up: gold-only echoes and long sparkle trail unchanged; Level Sync does not misfire.
- `//bf` after auto-hide: reveal only, no EXP reset.
- Scale .7/.75/.8 and large scale; job/level baseline alignment unchanged.
- Zone/relog and 2+ Windower clients: independent preferences and proper alias resolution.

## Previous observations (from user-tested builds)

- Test 12: user approved sustained gold glow and 5.5-second gain cooldown.
- Test 10: user praised gold-only preview and improved small-scale crosses.
- Earlier native atlas digits were experimentally tried; user prefers crisp text digits.

## Delivery register

| Batch | Package | Verification | Release state |
|---|---|---|---|
| Rename Test 1 | `BarFiller2_Rename_Test1.zip` | Static parse and file/diff checks; live test outstanding | Local package; no commit yet |
| BarFiller Test 12 | `BarFiller_Test12_LongGlow_UncappedDuration.zip` | Earlier test package, user gameplay feedback positive | Preserved separately as known-good baseline |

## Materials

- User's Test 12 working package in the conversation.
- NPCmirror repository `WORKFLOW.md`, revision `424d643fd63b944bd8534f455342b5328f1ca48c` reviewed 2026-10-15. Included at the root of this testing ZIP.
- Windower upstream BarFiller `statics.lua` checked for 3 original texture filenames; original remains copied locally rather than modified.

## Follow-up

After successful migration tests, create a dedicated `barfiller2` repository/branch, make coherent commits for rename, command conventions, and migration, and keep the next trusted live-tested build as the stable branch. Verify that automated Windower addon updates do not touch `addons/barfiller2`; the separate folder reduces that risk but is not a universal guarantee.
