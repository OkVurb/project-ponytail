# Public lookup data

Checked on 2026-10-11. The public mantra and mesh maps were already present in baseline commit `6633f27`, but their Lua wrappers returned empty tables. This follow-up moves the existing JSON into `assets/` and loads it through the source/bundle compressed-asset contract. No private database was recovered or invented.

## Sources and comparison

The local JSON objects match these pinned public files exactly, ignoring whitespace:

| Data | Local asset | Released entries | Pinned public source |
| --- | --- | --- | --- |
| Mantra names | `assets/mantras.json` | 229 | [beyondthetowers mantra map](https://github.com/beyondthetowers/project-rain/blob/692f167ea78a967e5afb31a632e779425c7ac4ba/src/features/removals/mantra_revealer/mantras.json) |
| Mesh names | `assets/deepwoken_meshes.json` | 534 | [beyondthetowers mesh map](https://github.com/beyondthetowers/project-rain/blob/692f167ea78a967e5afb31a632e779425c7ac4ba/src/utility/deepwoken/deepwoken_meshes.json) |

The same public map Git blobs appear in [cutegirlnkcw's pinned tree](https://github.com/cutegirlnkcw/project-rain-oss/tree/80f8a3b6f1fa1f6572a62b4b85584a0fa35692b8) and the [original release's pinned tree](https://github.com/unionizing/project-rain-oss/tree/fd8f8acb3e24ba47326273cfe57e0e3d5559f8bc). The maps are historical release data, not independently verified current game data.

| Data | Public Git blob |
| --- | --- |
| Mantras | `e05fa79b2b16eb70c53bbe6f421f12459e1d5ca4` |
| Meshes | `8147f4bd1e3c98837009b94ae0e82a8473db0c16` |
| Empty base timings | `0637a088a01e8ddab3bf3fa98dbe804cbde1a0dc` |

The mesh release contains one space-padded percent-encoded ID, `%202877143560%20`. The Lua wrapper adds the bare-digit alias `2877143560` for the existing ESP consumer. The source JSON remains unchanged. There are 535 lookup keys at runtime, with the alias pointing to the same released name.

## Still missing

`assets/base.json` is exactly `[]` in all three pinned public trees. See the [beyondthetowers base file](https://github.com/beyondthetowers/project-rain/blob/692f167ea78a967e5afb31a632e779425c7ac4ba/assets/base.json), [cutegirlnkcw base file](https://github.com/cutegirlnkcw/project-rain-oss/blob/80f8a3b6f1fa1f6572a62b4b85584a0fa35692b8/assets/base.json), and [original release base file](https://github.com/unionizing/project-rain-oss/blob/fd8f8acb3e24ba47326273cfe57e0e3d5559f8bc/assets/base.json). These sources cannot supply a missing private base timing database. Existing extra/source timings remain, with incomplete and uncalibrated coverage.

The staff-map stub and original hooking implementation were deliberately left unchanged. This follow-up restores ordinary public lookup data, not detection or evasion behavior.

## Local checks

The tests compare both moved maps against their baseline JSON objects, check consumer key shapes and the mesh alias, reject malformed lookup entries, and round-trip every bundled asset byte-for-byte. The Luau decoder tests use buffer/encoding mocks; actual Roblox EncodingService decoding remains a live acceptance gate.
