'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
function walk(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name, 'en'))
    .flatMap(entry => entry.isDirectory() ? walk(path.join(dir, entry.name)) : [path.join(dir, entry.name)]);
}
function inventory(base = root) {
  return walk(path.join(base, 'src')).filter(file => file.endsWith('.lua'))
    .map(file => ({ id: '@src/' + path.relative(path.join(base, 'src'), file).replaceAll('\\', '/').slice(0, -4), file }));
}
function isFeature(id) {
  const name = id.replace(/^@src\//, '');
  if (!name.startsWith('features/') || name.split('/').length < 3) return false;
  if (/^features\/auto-parry\/(data|util|services|fallbacks)\//.test(name)) return false;
  if (name === 'features/auto-parry/handlers/animator-handler') return false;
  return true;
}
// Tokenize strings and comments, rather than treating commented-out requires as dependencies.
function tokens(source) {
  const out = [];
  let i = 0;
  while (i < source.length) {
    const start = i;
    if (/\s/.test(source[i])) { i++; continue; }
    const comment = source.startsWith('--', i);
    if (comment) i += 2;
    const long = source.slice(i).match(/^\[(=*)\[/);
    if (long) {
      const end = source.indexOf(']' + long[1] + ']', i + long[0].length);
      if (end < 0) throw new Error('Unterminated long string/comment');
      if (!comment) out.push({ kind: 'string', value: source.slice(i + long[0].length, end), offset: start });
      i = end + long[1].length + 2; continue;
    }
    if (comment) { const end = source.indexOf('\n', i); i = end < 0 ? source.length : end + 1; continue; }
    if (source[i] === '"' || source[i] === "'") {
      const quote = source[i++]; let value = '';
      while (i < source.length && source[i] !== quote) {
        if (source[i] === '\\') { i++; value += source[i++] ?? ''; }
        else value += source[i++];
      }
      if (i >= source.length) throw new Error('Unterminated quoted string');
      i++; out.push({ kind: 'string', value, offset: start }); continue;
    }
    const word = source.slice(i).match(/^[A-Za-z_][A-Za-z_0-9]*/);
    const value = word ? word[0] : source[i];
    out.push({ kind: word ? 'word' : 'symbol', value, offset: start }); i += value.length;
  }
  return out;
}
function dependencies(source) {
  const ts = tokens(source); const result = [];
  for (let i = 0; i < ts.length; i++) {
    if (!['require', 'inline_asset_b96'].includes(ts[i].value) || ts[i + 1]?.value !== '(') continue;
    const kind = ts[i].value; let j = i + 2;
    while (ts[j]?.value === '(' || (ts[j]?.value === 'LPH_ENCSTR' && ts[j + 1]?.value === '(')) {
      j += ts[j].value === '(' ? 1 : 2;
    }
    if (ts[j]?.kind === 'string') result.push({ kind, target: ts[j].value, offset: ts[i].offset });
    else result.push({ kind, target: null, offset: ts[i].offset });
  }
  return result;
}
function resolveTarget(target, base = root) {
  if (target.startsWith('@assets/')) return path.join(base, 'assets', target.slice(8));
  if (!target.startsWith('@src/')) return null;
  const name = path.join(base, 'src', target.slice(5).replace(/\.lua$/, ''));
  return fs.existsSync(name + '.lua') ? name + '.lua' : path.join(name, 'init.lua');
}
module.exports = { root, walk, inventory, isFeature, tokens, dependencies, resolveTarget };
