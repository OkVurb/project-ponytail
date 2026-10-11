# Project Ponytail setup

This reconstructs the released source's initialization and build contracts. It does not recover private data, authenticate with Luarmor, or prove compatibility with a live executor. See [VERIFICATION.md](VERIFICATION.md) for the checked and unchecked parts.

## Build locally

Use Node.js 24 or newer. No npm dependencies or package installation are needed. Run these commands from the repository root, in order:

```bash
npm run build
```

```bash
npm test
```

```bash
npm run check:luau
```

The build regenerates `module-manifest.json` and `src/features/manifest.lua`, checks source dependencies, then writes `dist/project_ponytail_bundle.lua`. It never rewrites the feature loader. The bundle includes the available assets as Zstandard-compressed, base64-encoded strings. Rebuild after changing source or assets.

`dist/` and `.tools/` are ignored by Git. The generated manifests belong with the source if you publish it.

### Luau checks

The syntax check needs the official Luau compiler. The mock runtime test also needs the official Luau interpreter. This checkout was checked with Luau 0.742 from the [official Windows release](https://github.com/luau-lang/luau/releases/tag/0.742).

Extract its Windows archive into `.tools/luau/`, so `luau.exe` and `luau-compile.exe` are directly inside that folder. Alternatively, set `LUAU` and `LUAU_COMPILE` to your installed executables before running the checks.

Without the interpreter, the runtime test is explicitly skipped. Without the compiler, the syntax command fails. Neither case counts as runtime verification.

## Entry points

### Local bundle

Open the generated `dist/project_ponytail_bundle.lua` in your executor's script editor and execute that file. Do not execute `src/init.lua` by itself. The bundle supplies the shared module environment, native ModuleScript forwarding, multi-return module cache, module discovery, and assets.

For a short launcher, copy that bundle into your executor's **workspace folder** as `project_ponytail_bundle.lua`. This means the folder used by its `readfile` API, not the Roblox Workspace or this repository. Then paste [executor.lua](executor.lua) into its script editor:

```lua
repeat task.wait() until game:IsLoaded();
assert(type(readfile) == "function", "This launcher needs executor filesystem access.");
local run, reason = loadstring(readfile("project_ponytail_bundle.lua"), "@ProjectPonytail");
assert(run, reason);
run();
```

This launcher reads only the local file and waits for the game to load. It does not fetch the old Project Rain service or authenticate with Luarmor, and it does not require the original script key. Copy a fresh bundle after rebuilding. If you see a file-not-found error, check the filename and your executor's workspace folder.

The code targets Deepwoken and executor APIs. It is not an ordinary Roblox Studio LocalScript. The Rojo map is only a source layout for inspecting the tree in Studio.

### Source loader

Root `loader.lua` fetches the manifest, shared runtime, modules, and assets from a published repository. Its default URL uses this repository's `master` branch, not `main`.

**Pushing a review branch does not update the default `master` URL.** Critical public raw files at the code commit below were fetched and checked against Git blobs. Live executor behavior remains unverified. Set the source URL before loading the remote entry point so it does not fetch old modules from `master`.

Paste this launcher to use the published follow-ups at their fixed code revision. It requires no original script key and no local bundle copy:

```lua
repeat task.wait() until game:IsLoaded();
getgenv().PROJECT_RAIN_SOURCE_URL =
    "https://raw.githubusercontent.com/OkVurb/project-ponytail/bb2d6494732ca3fb7c7a311f13f56d8fdd9311c4/";
local run, reason = loadstring(
    game:HttpGet(getgenv().PROJECT_RAIN_SOURCE_URL .. "loader.lua"),
    "@ProjectPonytail"
);
assert(run, reason);
run();
```

This executes remote code. Only point it at source you trust and reviewed. The source loader also configures its own teleport reload URL.

For a bundle, teleport autoload remains disabled unless you explicitly set `getgenv().PROJECT_RAIN_LOADER_URL` to a trusted HTTPS URL serving your reviewed executable bundle or source loader. The existing autoload preference and a supported teleport-queue API must also be available.

## Saved-data compatibility

The visible name is Project Ponytail. Existing `Project Rain/` save folders, migration filenames, internal identifiers, and `PROJECT_RAIN_SOURCE_URL` / `PROJECT_RAIN_LOADER_URL` settings remain unchanged so existing files and loaders keep working. Path hints still show the real legacy folders. The existing remote preset-config URL is unchanged; no replacement website, invite, or logo is assumed.

## Required capabilities

The released code depends on executor functionality, including `getgenv`, `loadstring`, `setfenv`, filesystem access, protected UI access, signal functions, and the original hook APIs. Native Roblox ModuleScript imports are still required. The source entry point additionally needs HTTP fetching.

Asset decoding needs buffers and Roblox `EncodingService` with Zstandard support. Its base64 encoder returns a buffer, which the source loader converts to a string. See the [EncodingService API](https://create.roblox.com/docs/reference/engine/classes/EncodingService).

Refresh requires `replicatesignal` and the game's reset signal. Without that capability, it warns and returns rather than attempting server-only character loading. Actual reset, position restoration, teleport queueing, and game remotes have not been tested live.

Initialization preserves the original hook-before-feature-before-UI sequence. The hook implementation is unchanged. Its existing failure path still kicks; this is not a guarantee against detection or account penalties.

## Custom timing builder

Open **Show Timing Builder** in the Combat tab. Existing custom files appear on the left. For a new timing:

1. Select **New**. Enter a real numeric animation ID in JSON, or select an observed animation and choose **Use ID**. Use ID replaces the draft's IDs; observing a track alone never changes the draft.
2. Choose **Apply JSON** to validate the draft and draw its actions. Drag a time marker with a mouse or touch, or select an action and enter its time in seconds. Previous/Next also select actions without dragging.
3. Use the action-type button, **+ Action**, and **Delete** to edit actions. Time edits round to milliseconds and keep actions sorted. Equal-time actions keep their existing order.
4. Edit the name, move type, hitbox, and offset in JSON. Apply text changes before dragging. Invalid text is kept for correction, not replaced by the last applied draft.
5. Choose **Save JSON** to write the custom file and refresh its lookup. Closing and reopening preserves the unsaved draft in memory. New or selecting another file replaces that draft without saving it.

The watcher observes client-visible Animators under `workspace.Live`, or the workspace if that folder is absent. It includes already-playing tracks and newly added Animators, keeps the latest 40 observations, and shows the selected track's position, duration, speed, and playhead. Closing the builder disconnects its watcher and input/render subscriptions. The timing logger's existing Load Track action also opens the builder and selects the track.

It never plays, stops, scrubs, or changes an observed game animation. This is a new public implementation, not recovery of the private builder. The template's hitbox, offset, and delay are examples requiring real calibration. The interface targets desktop/tablet-sized viewports; live rendering and touch behavior still need checking in the game.

Files are saved under `Project Rain/Custom Timings/<name>.json` in the executor filesystem. Saving the same name replaces that custom file. Names permit only letters, numbers, underscores, and hyphens, up to 64 characters. Changing a name creates another file; it does not delete the old one.

Supported fields:

- Timing: `name`, `ids`, `actions`, optional `action_type`.
- Move type: `M1`, `Critical`, `Spell`, `Bell`, `Untagged`, or `Undefined`.
- Action: finite, nonnegative `when` in seconds, ordered ascending; `type` is `Parry`, `Block`, `Roll`, or `End Block`.
- Optional action `hitbox` and `offset`: numeric `X`, `Y`, `Z` objects. Hitbox sizes cannot be negative.

Executable fields and other unsupported fields are rejected. Saved timings immediately refresh the custom lookup. **Reload Timings** also reloads custom files. Malformed edits preserve the last valid in-memory timing and warn; removing a file removes its lookup entry on reload.

The original `rw_timings` loader remains separate and can execute Lua timing files. Only use trusted files there. This reconstruction does not alter existing user timing or configuration files during the build.

## Known release gaps and credits

- The released mantra and mesh-name maps now load through the compressed-asset pipeline. These historical maps are not guaranteed current or complete. Unknown entries retain the existing fallbacks. See [DATA_PROVENANCE.md](DATA_PROVENANCE.md).
- The historical staff-map stub remains unchanged. No staff-detection or hook behavior was expanded in this follow-up.
- `assets/base.json` is empty in the release. Existing `extra_data.json` and source-defined timings are preserved, but coverage is not complete or independently calibrated.
- The missing Brayden portrait is optional and is skipped with a warning unless you provide the expected local image. The unused missing Spotify import was removed.
- A failed feature import is reported and skipped. Successful initialization does not imply that every original feature works with today's game.

Project Ponytail is based on the [original Project Rain release](https://github.com/unionizing/project-rain-oss). Reconstruction references include [cutegirlnkcw/project-rain-oss](https://github.com/cutegirlnkcw/project-rain-oss) and [beyondthetowers/project-rain](https://github.com/beyondthetowers/project-rain). These are references, not claims that private modules were recovered.
