'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const { spawnSync, execFileSync } = require('node:child_process');
const { root, dependencies, isFeature, inventory, walk, resolveTarget } = require('../project');
const { audit } = require('../audit-requires');
const { generate } = require('../gen-registry');
const { bundle } = require('../bundle');
test('audit understands wrapped literals, macros, comments and native imports', () => {
  const source = `-- require("@src/missing")\n--[=[require("@src/also_missing")]=]\nrequire(("@src/one")); require(LPH_ENCSTR(("@src/two")));\nrequire(services.Modules); inline_asset_b96("@assets/x.json");`;
  assert.deepEqual(dependencies(source).map(item => item.target), ['@src/one', '@src/two', null, '@assets/x.json']);
});
test('feature manifest excludes data and bootstrap modules but includes nested features', () => {
  for (const id of ['@src/features/hooking', '@src/features/loader', '@src/features/auto-parry/data/base',
    '@src/features/auto-parry/util/latency', '@src/features/auto-parry/handlers/animator-handler']) assert.equal(isFeature(id), false, id);
  for (const id of ['@src/features/movement/fly', '@src/features/removals/mantra_revealer/mantra_revealer',
    '@src/features/misc/mod_detector/mod_detector', '@src/features/buttons/teleports/aratel']) assert.equal(isFeature(id), true, id);
});
test('no missing static requires or assets', () => assert.deepEqual(audit().missing, []));
test('registry is current, sorted and includes every source module', () => {
  const actual = JSON.parse(fs.readFileSync(path.join(root, 'module-manifest.json')));
  assert.deepEqual(actual.modules, inventory().map(item => item.id).sort());
  const manifest = fs.readFileSync(path.join(root, 'src/features/manifest.lua'), 'utf8');
  const ids = [...manifest.matchAll(/"(@src\/[^"\n]+)"/g)].map(match => match[1]);
  assert.deepEqual(ids, actual.modules.filter(isFeature));
});
test('regeneration preserves loader code and is deterministic', () => {
  const toolsRoot = path.join(root, '.tools'); fs.mkdirSync(toolsRoot, { recursive: true });
  const dir = fs.mkdtempSync(path.join(toolsRoot, 'build-test-'));
  try {
    fs.mkdirSync(path.join(dir, 'src/features'), { recursive: true });
    fs.mkdirSync(path.join(dir, 'assets'));
    fs.mkdirSync(path.join(dir, 'tools'));
    fs.writeFileSync(path.join(dir, 'src/init.lua'), 'return true;');
    fs.writeFileSync(path.join(dir, 'src/features/loader.lua'), '-- preserve me\nreturn {};');
    fs.copyFileSync(path.join(root, 'tools/runtime.lua'), path.join(dir, 'tools/runtime.lua'));
    fs.writeFileSync(path.join(dir, 'assets/binary.bin'), Buffer.from([0, 255, 128, 10, 0]));
    generate(dir);
    const first = fs.readFileSync(path.join(dir, 'module-manifest.json'));
    generate(dir);
    assert.deepEqual(fs.readFileSync(path.join(dir, 'module-manifest.json')), first);
    assert.equal(fs.readFileSync(path.join(dir, 'src/features/loader.lua'), 'utf8'), '-- preserve me\nreturn {};');
    assert.equal(resolveTarget('@src/init', dir), path.join(dir, 'src/init.lua'));
    const built = bundle(dir);
    const before = fs.readFileSync(built.output);
    const encoded = before.toString().match(/assets\["@assets\/binary.bin"\] = "([^"]+)"/)[1];
    assert.deepEqual(zlib.zstdDecompressSync(Buffer.from(encoded, 'base64')), fs.readFileSync(path.join(dir, 'assets/binary.bin')));
    bundle(dir);
    assert.deepEqual(fs.readFileSync(built.output), before);
  } finally {
    assert.ok(dir.startsWith(toolsRoot + path.sep));
    fs.rmSync(dir, { recursive: true });
  }
});
test('bundle includes every source body and byte-exact decoded asset', () => {
  const source = fs.readFileSync(path.join(root, 'dist/project_rain_bundle.lua'), 'utf8');
  for (const { id, file } of inventory()) assert.ok(source.includes(`factories[${JSON.stringify(id)}] = function()\n${fs.readFileSync(file, 'utf8')}\nend;`), id);
  for (const file of walk(path.join(root, 'assets'))) {
    const id = '@assets/' + path.relative(path.join(root, 'assets'), file).replaceAll('\\', '/');
    const prefix = `assets[${JSON.stringify(id)}] = `;
    const start = source.indexOf(prefix);
    assert.ok(start >= 0, id);
    const end = source.indexOf(';', start);
    const encoded = JSON.parse(source.slice(start + prefix.length, end));
    assert.deepEqual(zlib.zstdDecompressSync(Buffer.from(encoded, 'base64')), fs.readFileSync(file), id);
  }
});
test('hook implementation remains byte-for-byte unchanged from HEAD', () => {
  const original = execFileSync('git', ['show', 'HEAD:src/features/hooking.lua'], { cwd: root });
  const current = fs.readFileSync(path.join(root, 'src/features/hooking.lua'));
  // Git may check out CRLF; compare logical text, not platform line endings.
  assert.equal(current.toString().replaceAll('\r\n', '\n'), original.toString().replaceAll('\r\n', '\n'));
  const init = fs.readFileSync(path.join(root, 'src/init.lua'), 'utf8');
  assert.ok(init.includes('if not success or not result then'));
  assert.ok(init.includes('LocalPlayer:Kick('));
});
test('actual Luau runtime, initialization, features and timing storage with explicit Roblox mocks', t => {
  const executable = process.env.LUAU || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau.exe' : 'luau');
  if (!fs.existsSync(executable)) { t.skip('Install official Luau or set LUAU to run mock runtime tests.'); return; }
  const dir = fs.mkdtempSync(path.join(root, '.tools/runtime-test-'));
  try {
    const files = ['globals', 'luarmor_init_script', 'features/generic_feature', 'features/loader', 'utility/profiler',
      'features/auto-parry/data/timing_schema', 'features/auto-parry/data/custom_timings', 'features/buttons/refresh'];
    const parts = ['local factories = {};'];
    for (const id of files) parts.push(`factories["@src/${id}"] = function()\n${fs.readFileSync(path.join(root, 'src', id + '.lua'), 'utf8')}\nend;`);
    parts.push(`local create_runtime = (function()\n${fs.readFileSync(path.join(root, 'tools/runtime.lua'), 'utf8')}\nend)();`);
    parts.push(fs.readFileSync(path.join(__dirname, 'runtime.luau'), 'utf8'));
    const script = path.join(dir, 'run.luau'); fs.writeFileSync(script, parts.join('\n'));
    const result = spawnSync(executable, [script], { cwd: root, encoding: 'utf8', timeout: 30000 });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout, /Runtime mock checks passed/);
  } finally {
    assert.ok(dir.startsWith(path.join(root, '.tools') + path.sep));
    fs.rmSync(dir, { recursive: true });
  }
});
