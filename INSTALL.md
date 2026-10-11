# Project Rain OSS setup

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

The build regenerates `module-manifest.json` and `src/features/manifest.lua`, checks source dependencies, then writes `dist/project_rain_bundle.lua`. It never rewrites the feature loader. The bundle includes the available assets as Zstandard-compressed, base64-encoded strings. Rebuild after changing source or assets.

`dist/` and `.tools/` are ignored by Git. The generated manifests belong with the source if you publish it.

### Luau checks

The syntax check needs the official Luau compiler. The mock runtime test also needs the official Luau interpreter. This checkout was checked with Luau 0.742 from the [official Windows release](https://github.com/luau-lang/luau/releases/tag/0.742).

Extract its Windows archive into `.tools/luau/`, so `luau.exe` and `luau-compile.exe` are directly inside that folder. Alternatively, set `LUAU` and `LUAU_COMPILE` to your installed executables before running the checks.

Without the interpreter, the runtime test is explicitly skipped. Without the compiler, the syntax command fails. Neither case counts as runtime verification.

## Entry points

### Local bundle

Open the generated `dist/project_rain_bundle.lua` in your executor's script editor and execute that file. Do not execute `src/init.lua` by itself. The bundle supplies the shared module environment, native ModuleScript forwarding, multi-return module cache, module discovery, and assets.

The code targets Deepwoken and executor APIs. It is not an ordinary Roblox Studio LocalScript. The Rojo map is only a source layout for inspecting the tree in Studio.

### Source loader

Root `loader.lua` fetches the manifest, shared runtime, modules, and assets from a published repository. Its default URL uses this repository's `master` branch, not `main`.

**Pushing a review branch does not update the default `master` URL. Remote fetching and live executor behavior have not been verified.** Point the source URL at your published reviewed branch or commit before using the remote entry point. Prefer a trusted commit-pinned base URL so a running session cannot mix changing revisions.

To use your published revision, replace the example placeholders below:

```lua
getgenv().PROJECT_RAIN_SOURCE_URL = "https://raw.githubusercontent.com/OWNER/REPOSITORY/COMMIT/";
local source = game:HttpGet(getgenv().PROJECT_RAIN_SOURCE_URL .. "loader.lua");
local chunk, reason = loadstring(source);
assert(chunk, reason);
chunk();
```

This executes remote code. Only point it at source you trust and reviewed. The source loader also configures its own teleport reload URL.

For a bundle, teleport autoload remains disabled unless you explicitly set `getgenv().PROJECT_RAIN_LOADER_URL` to a trusted HTTPS URL serving your reviewed executable bundle or source loader. The existing autoload preference and a supported teleport-queue API must also be available.

## Required capabilities

The released code depends on executor functionality, including `getgenv`, `loadstring`, `setfenv`, filesystem access, protected UI access, signal functions, and the original hook APIs. Native Roblox ModuleScript imports are still required. The source entry point additionally needs HTTP fetching.

Asset decoding needs buffers and Roblox `EncodingService` with Zstandard support. Its base64 encoder returns a buffer, which the source loader converts to a string. See the [EncodingService API](https://create.roblox.com/docs/reference/engine/classes/EncodingService).

Refresh requires `replicatesignal` and the game's reset signal. Without that capability, it warns and returns rather than attempting server-only character loading. Actual reset, position restoration, teleport queueing, and game remotes have not been tested live.

Initialization preserves the original hook-before-feature-before-UI sequence. The hook implementation is unchanged. Its existing failure path still kicks; this is not a guarantee against detection or account penalties.

## Custom timing editor

The Combat tab opens a small JSON editor, not the unreleased animation-watching or draggable timeline tool. Enter a real numeric animation ID, edit ordered actions, then select **Save JSON**. Existing custom files appear in its list.

Files are saved under `Project Rain/Custom Timings/<name>.json` in the executor filesystem. Saving the same name replaces that custom file. Names permit only letters, numbers, underscores, and hyphens, up to 64 characters. Changing a name creates another file; it does not delete the old one.

Supported fields:

- Timing: `name`, `ids`, `actions`, optional `action_type`.
- Move type: `M1`, `Critical`, `Spell`, `Bell`, `Untagged`, or `Undefined`.
- Action: finite, nonnegative `when` in seconds, ordered ascending; `type` is `Parry`, `Block`, `Roll`, or `End Block`.
- Optional action `hitbox` and `offset`: numeric `X`, `Y`, `Z` objects. Hitbox sizes cannot be negative.

Executable fields and other unsupported fields are rejected. Saved timings immediately refresh the custom lookup. **Reload Timings** also reloads custom files. Malformed edits preserve the last valid in-memory timing and warn; removing a file removes its lookup entry on reload.

The original `rw_timings` loader remains separate and can execute Lua timing files. Only use trusted files there. This reconstruction does not alter existing user timing or configuration files during the build.

## Known release gaps and credits

- Private mantra, mesh-name, and historical staff maps are unavailable. Explicit empty maps warn instead of inventing data. Existing server-name, generic dropped-item, and live group-rank fallbacks remain.
- `assets/base.json` is empty in the release. Existing `extra_data.json` and source-defined timings are preserved, but coverage is not complete or independently calibrated.
- The missing Brayden portrait is optional and is skipped with a warning unless you provide the expected local image. The unused missing Spotify import was removed.
- A failed feature import is reported and skipped. Successful initialization does not imply that every original feature works with today's game.

Project Rain branding and the [original release](https://github.com/unionizing/project-rain-oss) are preserved. Reconstruction references include [cutegirlnkcw/project-rain-oss](https://github.com/cutegirlnkcw/project-rain-oss) and [beyondthetowers/project-rain](https://github.com/beyondthetowers/project-rain). These are references, not claims that private modules were recovered.
