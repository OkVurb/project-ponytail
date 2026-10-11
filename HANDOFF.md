# Project Ponytail handoff

Updated: 2026-10-11. This records completed local work and its verification boundary, not a successful in-game boot.

## Publication state

- Repository: [OkVurb/project-ponytail](https://github.com/OkVurb/project-ponytail).
- Working folder: `C:\Users\cr0od\OneDrive\Documents\GitHub\project-ponytail`.
- Branch: `codex/handoff-initialization`, not merged into `master`.
- Last pushed commit: [`7620ad6`](https://github.com/OkVurb/project-ponytail/commit/7620ad6e7de5741c33372c74189266de7bd2c93c), the Project Ponytail rename. Initialization was previously pushed as [`df75898`](https://github.com/OkVurb/project-ponytail/commit/df758981dfd265fae52bacbbc262e113d9a5dcff).
- The latest suggested follow-ups described below are local and uncommitted. They have not been pushed or merged. No pull request was created.
- Work originally continued from the Downloads handoff and the user's baseline commit `6633f27`.

## Latest suggested follow-ups

### Targeted merge-ready review

Reviewed source URL selection, runtime/cache behavior, connection ownership and callers, initialization/menu/refresh contracts, timing storage/schema and map consumers. The public mantra and mesh JSON was already present, but empty Lua wrappers made it unreachable. Restored those lookups. Tightened timing validation so mixed or sparse arrays and unsupported hitbox/offset fields are rejected rather than silently ignored.

The generated static literal require graph has no cycles. Build, automated tests and syntax checks pass. This is a targeted local readiness check, not an exhaustive review of every feature or live release approval. Dynamic/native imports, executor environments and the nonstandard game reset signal remain acceptance gates. Original hook source and failure guard remain unchanged.

### Public data lookup restoration

Moved the existing maps into `assets/mantras.json` and `assets/deepwoken_meshes.json`, then connected both Lua consumers to the compressed-asset decoder. Objects match the original baseline and pinned public forks. The mantra map contains 229 entries; the mesh map contains 534. One malformed released mesh ID also receives a bare-digit alias for its consumer. No JSON entries were fabricated.

The public forks all contain the same empty `assets/base.json`, so they cannot supply the private timing database. The historical staff stub remains unchanged; detection/evasion behavior was not expanded. Sources and pinned revisions are in [DATA_PROVENANCE.md](DATA_PROVENANCE.md).

### Timing timeline and animation watcher

Replaced the JSON-only builder with a native GUI that retains JSON editing and adds:

- Draggable mouse/touch time markers and exact seconds input, with millisecond rounding and stable action sorting.
- Action selection through lane labels or Previous/Next, action-type changes, adding actions and deleting all but the last required action.
- A read-only watcher of currently playing and newly played client-visible animations. It tracks new Animators, displays the selected position/duration/speed and playhead, and keeps the latest 40 observations.
- Explicit Use ID to replace draft IDs, without changing them simply because a track was observed. The timing logger's existing Load Track callback now reaches the builder.
- Dirty-JSON preservation, schema validation, custom save/lookup refresh, and unsaved-draft preservation on close/reopen. New or selecting a different custom file intentionally replaces the current draft without saving.
- Watcher/input/render cleanup on close or unload. Snapshot failures warn without preventing future AnimationPlayed observations.

The watcher never plays, stops or changes game animations. Hitbox and offset remain JSON fields requiring real calibration. This is a new public implementation, not the private builder recovered. The UI targets desktop/tablet-sized viewports and has not been rendered inside Roblox.

## Earlier completed work

The later launcher request added `executor.lua`. Copy the latest generated bundle into the executor's readfile workspace as `project_ponytail_bundle.lua`, then paste this short launcher. It waits for the game, reads the local bundle and reports read/compile failures. It does not use the original Project Rain key or service. Local mocked launcher checks pass; no executor execution was performed. The launcher and current follow-ups remain uncommitted and unpushed.

- **Initialization:** Key-free startup shim, shared globals, early Feature constructor and safe timing callbacks. Local OSS identity is not paid access or authenticated private access.
- **Module loading:** Shared source/bundle runtime, native Roblox forwarding, multiple/nil returns, caching, discovery, circular-import errors and retry after failed imports.
- **Feature registration:** Generated manifest and isolated import failures, with idempotent feature connections.
- **Build and assets:** Dependency auditing, deterministic manifest generation and single-file bundling with compressed assets. Loader behavior is not overwritten by regeneration.
- **Refresh:** Existing reset-signal contract instead of server-only character loading, combat checks, bounded respawn wait, position restoration and a timeout-race fix.
- **Menu and dependencies:** Menu initializer called and existing Start remote used. Optional SDK/portrait failures warn; unused missing Spotify dependency removed.
- **Rename:** Project Ponytail titles, watermark, messages, webhook names, export labels and package/Rojo metadata. Old logos/invite promotions removed. Requested credits-reminder removed from CLAUDE.md. Legacy save folders and loader flags retained.

The original `src/features/hooking.lua` is untouched. The existing kick-on-hook-failure path remains. Neither establishes safety from detection or account penalties.

## Current local verification

Checks used Node 24.19.0 and official Luau 0.742.

| Check | Result |
| --- | --- |
| Build | Passed; `dist/project_ponytail_bundle.lua` generated |
| Source modules | 277 |
| Feature candidates | 156, not a live registration count |
| Static module/asset references | 200 checked; none missing |
| Static literal require cycles | None found |
| Dynamic/native calls | 10 remain runtime-dependent |
| Bundled assets | 17; byte-exact decoded round trips |
| Automated tests | 10 passed; no failures or skips |
| Official Luau syntax | 282 files checked; no failures |
| Original hook source | Unchanged |
| Diff whitespace | Passed |

Runtime tests execute actual selected source factories against explicit Roblox GUI, signal, JSON, buffer and encoding mocks. They cover timeline sorting, finite times, mouse/touch ownership, deferred text signals, dirty-text preservation, save/reload, map decoding contracts and aliases, watcher history/subscriptions, logger integration, duration updates and cleanup. They do not execute full initialization or prove real GUI layout. Node tests separately validate the actual asset JSON and compression bytes. Details are in [VERIFICATION.md](VERIFICATION.md).

## Remaining limits

- No live executor boot, real GUI rendering, game remotes, refresh/reset or teleport session was tested. Real EncodingService decoding, native imports and setfenv/getfenv availability also require the intended runtime.
- The private base timing database is still absent. Public historical maps may be stale. Templates and timing coverage are not independently calibrated.
- The default loader URL still targets `master`. The earlier fixes are on the published review branch; current follow-ups exist only locally. Use the local rebuilt bundle to include them until publication. A remote source URL must point to a trusted published revision containing all required files.
- `dist/` and `.tools/` are ignored. Generated bundles and downloaded Luau binaries are not automatically published.
- Do not hide startup failures by removing the original hook failure guard. Record actual warnings. Passing local checks does not establish account safety.

Follow the live checklist in [VERIFICATION.md](VERIFICATION.md). Setup and editor workflow are in [INSTALL.md](INSTALL.md). Reproduce the local checks from the repository root:

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
