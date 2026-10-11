'use strict';
const test = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
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
test('restored public lookup maps are unchanged and match consumer key shapes', () => {
  const specs = [
    ['assets/mantras.json', 'src/features/removals/mantra_revealer/mantras.json', 229, 'Smash:Ice', 'Ice Smash'],
    ['assets/deepwoken_meshes.json', 'src/utility/deepwoken/deepwoken_meshes.json', 534, '5707296382', 'Training Vest'],
  ];
  for (const [file, originalPath, count, key, value] of specs) {
    const data = JSON.parse(fs.readFileSync(path.join(root, file), 'utf8'));
    const original = JSON.parse(execFileSync('git', ['show', `6633f27:${originalPath}`], { cwd: root, encoding: 'utf8' }));
    assert.deepEqual(data, original, file);
    assert.equal(Object.keys(data).length, count);
    assert.equal(data[key], value);
    for (const [id, name] of Object.entries(data)) {
      assert.equal(typeof name, 'string'); assert.ok(name.length);
      if (file.includes('meshes') && id !== '%202877143560%20') assert.match(id, /^\d+$/);
    }
  }
  assert.equal(crypto.createHash('sha256').update(fs.readFileSync(path.join(root, 'assets/base.json'))).digest('hex'),
    '4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945');
});
test('Project Ponytail branding preserves save paths and loader settings', () => {
  const read = file => fs.readFileSync(path.join(root, file), 'utf8');
  assert.equal(JSON.parse(read('package.json')).name, 'project-ponytail');
  const project = JSON.parse(read('default.project.json'));
  assert.equal(project.name, 'ProjectPonytail');
  assert.equal(project.tree.ReplicatedStorage.ProjectPonytail.$path, 'src');
  for (const file of ['src/main_menu/loader.lua', 'src/features/auto-parry/builder.lua',
    'src/features/misc/linoria_watermark.lua', 'src/ui/ui.lua', 'src/utility/ui/wrapper.lua']) {
    assert.match(read(file), /Project Ponytail|Ponytail<\/font>/, file);
    assert.doesNotMatch(read(file), /project rain(?![\/\\])|pr <font|nextgen/i, file);
  }
  for (const file of ['src/utility/webhook.lua', 'src/automation/persistent_tasks/soup_echofarm.lua',
    'src/automation/persistent_tasks/titus_relicfarm.lua']) {
    assert.ok(read(file).includes('username = "Project Ponytail"'), file);
    assert.doesNotMatch(read(file), /project-rain|PRLOGO/, file);
  }
  const paths = source => source.match(/["']Project Rain[/\\][^"'\r\n]*["']/g) || [];
  for (const file of ['src/init.lua', 'src/ui/ui.lua', 'src/ui/tos.lua', 'src/utility/deepwoken/servers.lua',
    'src/utility/librarys/managers/SaveManager.lua', 'src/features/misc/build_stealer.lua',
    'src/features/auto-parry/data/custom_timings.lua']) {
    const original = execFileSync('git', ['show', `HEAD:${file}`], { cwd: root, encoding: 'utf8' });
    assert.deepEqual(paths(read(file)), paths(original), file);
  }
  assert.ok(read('src/init.lua').includes('isfolder("Project Rain")'));
  for (const file of ['loader.lua', 'src/utility/setup_auto_load.lua']) {
    assert.ok(read(file).includes('PROJECT_RAIN_SOURCE_URL'), file);
    assert.ok(read(file).includes('PROJECT_RAIN_LOADER_URL'), file);
  }
  assert.doesNotMatch(read('CLAUDE.md'), /Tell the user to include credits/);
});

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
  const source = fs.readFileSync(path.join(root, 'dist/project_ponytail_bundle.lua'), 'utf8');
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
      'features/auto-parry/data/timing_schema', 'features/auto-parry/data/custom_timings', 'features/buttons/refresh',
      'features/auto-parry/data/timeline', 'features/auto-parry/util/animation_watcher', 'features/auto-parry/builder',
      'utility/string_map', 'features/removals/mantra_revealer/mantras', 'utility/deepwoken/deepwoken_meshes'];
    const parts = ['local factories = {};'];
    for (const id of files) parts.push(`factories["@src/${id}"] = function()\n${fs.readFileSync(path.join(root, 'src', id + '.lua'), 'utf8')}\nend;`);
    parts.push(`local create_runtime = (function()\n${fs.readFileSync(path.join(root, 'tools/runtime.lua'), 'utf8')}\nend)();`);
    parts.push(fs.readFileSync(path.join(__dirname, 'runtime.luau'), 'utf8'));
    parts.push(fs.readFileSync(path.join(__dirname, 'builder.luau'), 'utf8'));
    parts.push(`local launcher = function()\n${fs.readFileSync(path.join(root, 'executor.lua'), 'utf8')}\nend;
local loaded, waits, ran = false, 0, false;
local launcher_env = setmetatable({
  game = { IsLoaded = function() return loaded; end },
  task = { wait = function() waits += 1; loaded = true; end },
  readfile = function(file) assert(file == "project_ponytail_bundle.lua"); return "fixture bundle"; end,
  loadstring = function(source, name)
    assert(source == "fixture bundle" and name == "@ProjectPonytail");
    return function() ran = true; return "launched"; end;
  end,
}, { __index = getfenv() });
setfenv(launcher, launcher_env);
assert(launcher() == "launched" and ran and waits == 1);
launcher_env.loadstring = function() return nil, "invalid bundle fixture"; end;
local ok, err = pcall(launcher); assert(not ok and tostring(err):find("invalid bundle fixture", 1, true));
launcher_env.readfile = function() error("missing bundle fixture"); end;
ok, err = pcall(launcher); assert(not ok and tostring(err):find("missing bundle fixture", 1, true));
launcher_env.readfile = false;
ok, err = pcall(launcher); assert(not ok and tostring(err):find("filesystem access", 1, true));
print("Executor launcher mock checks passed");`);
    const script = path.join(dir, 'run.luau'); fs.writeFileSync(script, parts.join('\n'));
    const result = spawnSync(executable, [script], { cwd: root, encoding: 'utf8', timeout: 30000 });
    assert.equal(result.status, 0, result.stdout + result.stderr);
    assert.match(result.stdout, /Runtime mock checks passed/);
    assert.match(result.stdout, /Builder and watcher mock checks passed/);
    assert.match(result.stdout, /Executor launcher mock checks passed/);
  } finally {
    assert.ok(dir.startsWith(path.join(root, '.tools') + path.sep));
    fs.rmSync(dir, { recursive: true });
  }
});
