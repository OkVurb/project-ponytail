'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { spawnSync } = require('node:child_process');
const { root, inventory, walk } = require('./project');
const executable = process.env.LUAU_COMPILE || path.join(root, '.tools/luau', process.platform === 'win32' ? 'luau-compile.exe' : 'luau-compile');
if (!fs.existsSync(executable)) {
  console.error('Set LUAU_COMPILE to an official luau-compile executable, or place it in .tools/luau. See INSTALL.md.');
  process.exit(1);
}
const files = [...inventory().map(item => item.file), path.join(root, 'loader.lua'), path.join(root, 'tools/runtime.lua'),
  ...walk(path.join(root, 'assets')).filter(file => file.endsWith('.lua'))];
const output = path.join(root, 'dist/project_ponytail_bundle.lua');
if (fs.existsSync(output)) files.push(output);
let failures = 0;
for (const file of files) {
  const result = spawnSync(executable, ['--null', file], { encoding: 'utf8', timeout: 30000 });
  if (result.status !== 0) { failures++; console.error(path.relative(root, file), result.stderr || result.error); }
}
console.log(`Luau syntax: ${files.length} files checked, ${failures} failures. Not a Roblox runtime test.`);
if (failures) process.exitCode = 1;
