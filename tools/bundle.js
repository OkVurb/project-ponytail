
'use strict';
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const { root, inventory, walk } = require('./project');
function bundle(base = root) {
  if (typeof zlib.zstdCompressSync !== 'function') throw new Error('Build requires Node.js 24 with Zstandard support.');
  const modules = inventory(base);
  const parts = ['-- Generated Project Ponytail bundle. Source provenance: see INSTALL.md.',
    'local factories, assets = {}, {};'];
  for (const item of modules) parts.push(`factories[${JSON.stringify(item.id)}] = function()\n${fs.readFileSync(item.file, 'utf8')}\nend;`);
  for (const file of walk(path.join(base, 'assets'))) {
    const id = '@assets/' + path.relative(path.join(base, 'assets'), file).replaceAll('\\', '/');
    const encoded = zlib.zstdCompressSync(fs.readFileSync(file)).toString('base64');
    parts.push(`assets[${JSON.stringify(id)}] = ${JSON.stringify(encoded)};`);
  }
  const runtime = fs.readFileSync(path.join(base, 'tools/runtime.lua'), 'utf8');
  parts.push(`local create_runtime = (function()\n${runtime}\nend)();`);
  parts.push(`local runtime = create_runtime({\nmodules = {${modules.map(m => JSON.stringify(m.id)).join(',')}},\nresolve = function(id) return factories[id]; end,\nasset = function(id) assert(assets[id], 'Missing asset: ' .. id); return assets[id]; end,\n});\nreturn runtime.require("@src/init");`);
  const output = path.join(base, 'dist/project_ponytail_bundle.lua');
  fs.mkdirSync(path.dirname(output), { recursive: true });
  fs.writeFileSync(output, parts.join('\n') + '\n');
  return { output, modules: modules.length, bytes: fs.statSync(output).size };
}
if (require.main === module) console.log(bundle());
module.exports = { bundle };
