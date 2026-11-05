# TESTING.md — BarFiller2 (cumulative)

## Current Development Status — November 5, 2026 (America/Chicago)

- **Repository / branch:** rerorriM-Mirrorer/BarFiller2 / dev/cioara-hardcoded-defaults; main is preserved as the live-tested baseline.
- **Starting source checkpoint:** main commit 683dbb539ae520b23835c2dba375c6793dd653ff (Complete Install Test 2).
- **Runtime:** Windower 4 Lua addon; no new dependencies or asset changes.
- **Most recent user-confirmed live behavior:** Complete Install Test 2 loaded on Franklet (2026-10-16); Test 12 animation feedback previously approved. This candidate has not been tested in FFXI.
- **Static checks:** Cioara effective layout extracted from the uploaded settings with sanitized numeric-font XML tags; source defaults, migration branches, saved-settings merge and positioning code reviewed. These are source-level checks, NOT in-game load tests.
- **Outstanding:** Fresh profile load, existing-character override preservation, reload and zoning persistence, 3840×2160 placement, smaller-client clamping and animation smoke test. Independent dev/ctrl-drag-grid is also pending acceptance.
- **Next:** User live-test the defaults on a fresh profile before considering merge to main.

### Direct-install ZIP packaging — November 5, 2026

- **Package:** `BarFiller2_Cioara_Defaults_Fresh_Install_20261105.zip`, built from `dev/cioara-hardcoded-defaults` at its source checkpoint. The ZIP root contains the installable `barfiller2/` directory, with complete Lua modules, PNG art assets, README, WORKFLOW and this TESTING record.
- **Install:** Back up `Windower/addons/barfiller2/data/` and any existing settings. Unload `//lua u barfiller2`, extract the `barfiller2/` folder from the ZIP directly into `Windower/addons/`, do not overwrite or delete existing `data/`, then run `//lua l barfiller2` and `//bf status`.
- **Freshness:** No `data/`, `settings.xml`, external bootstrap scripts or legacy BarFiller directory included. Existing saved profiles still take precedence over the new code defaults.
- **Verification:** Compare every packaged file with its GitHub source/blob metadata, validate all ZIP local/central records and CRC32 values, and confirm the candidate's scale, gold skin, 5.5-second gain fade and completed migration markers in source. This is static/package verification, not in-game testing.
- **Live acceptance:** First-load behavior, artwork rendering, positioning and persistence remain pending an actual Windower/FFXI test.

### Current testing batch — Cioara hardcoded defaults (November 5, 2026)

**Input:** User-uploaded settings(20261105-105950).xml. Effective Cioara layout takes most options from global settings and overrides Scale=0.9, X=3209, Y=2124.9 plus the completed Test 9/11/12 migration markers. The uploaded settings file is not committed. Windower numeric-font nodes needed a sanitized external XML parser.

**Changes:** Fresh-profile defaults now match Cioara's saved layout. The gold skin, hybrid/gold-only level-up, text digits, gain sparkles, 5.5-second gain fade and 60-second auto-hide were already existing code defaults and remain unchanged. Historical migration markers now begin true for brand-new profiles so the old Test 11 one-time scale conversion cannot turn 0.9 into 1.2. Earlier saved profiles with false markers retain their migration behavior. No animation modules, artwork, rendering or clamping paths changed. Legacy hidden image/text defaults stay in statics.lua.

**Testing procedure:**
1. Back up the existing BarFiller2 data and settings; retain the main-branch known-good source.
2. With a truly fresh test profile, load //lua l barfiller2 and check //bf status. Expect gold, scale 0.9, gainfade 5.5, autohide 60.
3. On Cioara's 3840x2160 client, check near X=3209 and Y=2124 (the runtime truncates the saved 2124.9 position). Reload; confirm scale stays 0.9 and the Test 9/11/12 markers are true.
4. On an existing character profile with custom scale/position, reload and confirm its saved settings are not overwritten.
5. On a 1280x720 UI, confirm the bar stays on-screen using existing clamping. Test //bf preview gain, //bf preview goldonly, auto-hide, restart, and a zone transition.
6. Check //bf help and //bf status; confirm the original BarFiller is not simultaneously loaded. Report any in-game errors or visual differences.

**Verification:** Uploaded values were inspected against the source default table. No game client, Windower load, in-game rendering, profile regression or live multibox test occurred for this candidate.

**November 5 correction:** ~~An isolated texlua script parsed the changed default table and passed simulated checks for the fresh-profile migration flags, preservation of saved scale/position overrides, and 1280×720 clamping.~~ That earlier claim was recorded without an executable texlua run being performed. The work was source inspection only. Archive integrity checks for this delivery are distinct and do not substitute for FFXI testing.

**Publication:** Development-branch commits will be identified by the GitHub delivery handoff, without embedding the final moving head in this file.

---
## Archived Development Status — October 18, 2026 (America/Chicago)

- **Repository / branch:** `rerorriM-Mirrorer/BarFiller2` / `main`.
- **Starting source checkpoint:** `BarFiller2_Complete_Install_Test2.zip` (SHA-256 `ed77a256fb3d3457bffa27e7a55d8de8641fd4bab386b28add39401fd86b1813`); code and assets carried forward from the complete package, with documentation updated for this repository.
- **Runtime:** Windower 4 Lua addon; no external addon's files or DLL are required.
- **Most recent user-confirmed live behavior:** Complete Install Test 2 successfully loaded for Franklet (2026-10-16); previously approved Test 12's EXP and level-up visuals were retained. This does NOT certify every animation/command on Franklet.
- **Automation/static verification:** Packaging and content comparison against the source ZIP, syntax parsing, and source-level checks. These are not Windows/FFXI game tests.
- **Remaining:** Ctrl+drag Test 3 needs live acceptance before promotion; representative zoning/relogin and long animation behavior also outstanding.
- **Next:** Live-test the separate Ctrl+drag candidate and promote it only after approval..

### Repository publication — October 18, 2026

- Populate a dedicated repository without introducing runtime changes to the archived source package. The `main` branch holds the most recent user-confirmed loading baseline; Ctrl+drag experiment remains on a separate working branch.
- `AGENTS.md` and `WORKFLOW.md` adopt the latest canonical NPCmirror documentation, including current-development-status methodology.
- Keep original cumulative Test 1–3 reports and distinguish prior simulated checks from in-game observations. No new in-game testing was performed during repository initialization.
- This document identifies the starting ZIP by SHA-256; the publication commit SHA is in GitHub history and the delivery handoff (it must not be embedded in the commit that defines it).

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
