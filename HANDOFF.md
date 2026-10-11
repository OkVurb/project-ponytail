# Project Ponytail handoff

Updated: 2026-10-11. This is a recap of the completed local work, not a claim that the script has been tested in the game.

## Where things stand

- Repository: [OkVurb/project-ponytail](https://github.com/OkVurb/project-ponytail).
- Working folder: `C:\Users\cr0od\OneDrive\Documents\GitHub\project-ponytail`.
- Pushed branch: `codex/handoff-initialization`. It has not been merged into `master`.
- Code commit: [`df75898`](https://github.com/OkVurb/project-ponytail/commit/df758981dfd265fae52bacbbc262e113d9a5dcff). The remote commit was checked against local HEAD after pushing.
- The work continued from the supplied Downloads handoff and the user's baseline commit `6633f27`.
- This recap is included with the Project Ponytail rename commit, separate from the earlier initialization commit.

## Rename follow-up

The local follow-up renames UI titles, watermark, messages, webhook display names, exported-build labels, package/Rojo metadata, and the generated bundle to Project Ponytail. Old webhook logos and invite promotions were removed. The requested credits-reminder line was removed from `CLAUDE.md`. Existing save paths and loader settings were retained for compatibility. This rename and this handoff are not part of the earlier pushed commit. Follow-up checks passed: build, all 9 automated tests without skips, and syntax checks of 278 files. The original hook implementation remains unchanged. The generated output is now `dist/project_ponytail_bundle.lua`.

## What changed

- **Initialization:** Restored the key-free startup shim, shared globals, early Feature constructor, and safe timing callbacks. The user service reports a local OSS identity, not paid access or successful authentication.
- **Module loading:** Added a shared runtime for the source loader and bundle. It preserves native Roblox imports, multiple return values, nil returns, and caching. It also supplies module discovery and reports circular imports and failed imports.
- **Feature registration:** Replaced the large hardcoded loader list with a generated manifest. A failed feature import warns instead of stopping the whole registry. Default feature connections no longer subscribe twice.
- **Assets and build:** Added dependency auditing, repeatable manifest generation, bundling, and tests. The bundle contains all available source modules and compressed assets. Rebuilding does not overwrite feature-loader behavior.
- **Refresh:** Replaced server-only character loading with the existing reset-signal contract. Added combat checks, a bounded respawn wait, position restoration, and a fix for an old timeout clearing a newer request.
- **Custom timings:** Replaced the nonfunctional timing builder with a small JSON editor. It validates and saves custom files, refreshes the lookup, and connects to Reload Timings. Invalid edits keep the last good in-memory timing.
- **Menu and errors:** The menu initializer is now called. Its button uses the existing menu Start remote instead of teleporting to an arbitrary place. Optional SDK and timing-handler failures now produce warnings.
- **Stripped dependencies:** Added clearly labeled empty fallbacks for unavailable private mantra, mesh-name, and historical staff maps. Removed the unused missing Spotify import and made the missing Brayden portrait optional.
- **Documentation:** Added [INSTALL.md](INSTALL.md) and [VERIFICATION.md](VERIFICATION.md). Original source references are documented in the install guide.

The original `src/features/hooking.lua` was not changed. Its existing kick-on-hook-failure path remains in initialization. That is not a guarantee against detection or account penalties.

## What was checked

Checks used Node 24.19.0 and official Luau 0.742. These were actual local results before the code push:

| Check | Result |
| --- | --- |
| Build | Passed |
| Source modules bundled | 274 |
| Feature candidates | 156, not a live registration count |
| Static module/asset references | 193 checked; none missing |
| Dynamic/native calls | 10 still need runtime verification |
| Automated tests | 8 passed; none failed or skipped |
| Luau syntax | 278 files checked; no failures |
| Diff whitespace | Passed |

The runtime tests use selected real source modules with explicit Roblox mocks. They do not run the entire script inside an executor. Asset tests decode every bundled asset back to the original bytes. Tests also cover loading/cache behavior, feature lifecycle, timing storage, and the refresh timeout race.

## Important limits and continuation notes

- Live executor boot, Main/Combat/automation UI, game remotes, actual refresh, and teleport autoload remain untested. Start with the live acceptance checklist in [VERIFICATION.md](VERIFICATION.md), rather than assuming a successful build means a working game session.
- The timing editor is JSON-only. The private graphical timeline and automatic animation watcher were not recreated. Private datasets were not recovered; `assets/base.json` is still the release's empty file.
- The default source-loader URL points at `master`. The new code is on the review branch. Use the published branch or a pinned commit as the source URL; do not assume the default URL contains these fixes.
- Local build output is `dist/project_ponytail_bundle.lua`. Both `dist/` and `.tools/` are ignored by Git, so the generated bundle and downloaded Luau executables were not pushed.
- Node 24 or newer is needed. No npm packages need installing. For full checks, provide the official Luau interpreter and compiler as described in [INSTALL.md](INSTALL.md).
- Do not remove the original hook failure guard to hide a startup problem. Record the actual warning or error first. Builds, syntax checks, and mocked tests do not establish account safety.

To reproduce the local checks from the repository root, run these in order:

```bash
npm run build
```

```bash
npm test
```

```bash
npm run check:luau
```

```bash
git diff --check
```
