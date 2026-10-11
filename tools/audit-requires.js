'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { root, inventory, dependencies, resolveTarget } = require('./project');
function audit(base = root) {
  const missing = []; const dynamic = []; let checked = 0;
  for (const { file } of inventory(base)) {
    const source = fs.readFileSync(file, 'utf8');
    for (const dep of dependencies(source)) {
      const location = `${path.relative(base, file)}:${source.slice(0, dep.offset).split('\n').length}`;
      if (!dep.target || !dep.target.startsWith('@')) { dynamic.push(location); continue; }
      checked++;
      const target = resolveTarget(dep.target, base);
      if (!target || !fs.existsSync(target)) missing.push(`${location} -> ${dep.target}`);
    }
  }
  return { checked, missing, dynamic };
}
if (require.main === module) {
  const result = audit();
  console.log(`Checked ${result.checked} static module/asset references. ${result.dynamic.length} dynamic/native calls require runtime verification.`);
  for (const item of result.missing) console.error('MISSING ' + item);
  if (result.missing.length) process.exitCode = 1;
  else console.log('No missing static targets.');
}
module.exports = { audit };
