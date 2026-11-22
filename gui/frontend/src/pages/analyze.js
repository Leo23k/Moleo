import {ListDrives, PickFolder, StartAnalyze, CancelAnalyze, AnalyzeLevel, RecyclePaths, Reveal} from '../../wailsjs/go/main/App';
import {EventsOn} from '../../wailsjs/runtime/runtime';
import {fmt, esc, confirmBox, hero, warnIcon} from '../util.js';

let view = 'home';        // home | drives | scanning | map
let level = null;
let scanInfo = '';
let selected = new Set();
let error = '';

const PALETTE = ['#c98b5a', '#5f8fb8', '#7aa66b', '#b0739e', '#c2a755', '#5ea3a0', '#b86b5f', '#8579b8'];

export function render(el) {
  if (view === 'scanning') return drawScanning(el);
  if (view === 'map' && level) return drawMap(el);
  if (view === 'drives') return drawDrives(el);
  hero(el, {
    orb: '#d9a066',
    line: (error ? `<span class="bad">${esc(error)}</span><br>` : '') + 'A treemap shows what fills the disk.<br>Click a block to look inside.',
    buttons: [
      {text: 'Choose a drive', ghost: true, onClick: () => { view = 'drives'; render(el); }},
      {text: 'Choose a folder', ghost: true, onClick: () => pickFolder(el)},
      {text: 'Map your disk', onClick: () => scan(el, 'C:\\')},
    ],
  });
}

async function drawDrives(el) {
  const drives = (await ListDrives()) || [];
  el.innerHTML = `<div class="result"><h2>Choose a drive</h2>${drives.map(d => {
    const used = d.total - d.free;
    return `<div class="approw drive" data-path="${esc(d.path)}" style="cursor:pointer">
      <div class="apptile" style="background:#5f6f80">${esc(d.path[0])}</div>
      <div class="grow"><div class="name">${esc(d.label || 'Local Disk')} (${esc(d.path.slice(0, 2))})</div>
      <div class="bar"><div style="width:${(100 * used / d.total).toFixed(1)}%"></div></div>
      <div class="path">${fmt(used)} used of ${fmt(d.total)} · ${fmt(d.free)} free</div></div></div>`;
  }).join('')}<button class="btn ghost small" id="back">Back</button></div>`;
  el.querySelectorAll('.drive').forEach(d => d.onclick = () => scan(el, d.dataset.path));
  el.querySelector('#back').onclick = () => { view = 'home'; render(el); };
}

async function pickFolder(el) {
  const p = await PickFolder();
  if (p) scan(el, p);
}

const onThisTab = () => document.querySelector('.topnav button.active')?.dataset.page === 'analyze';

let offs = [];
async function scan(el, path) {
  error = '';
  view = 'scanning';
  scanInfo = 'Starting…';
  offs.forEach(f => f());
  offs = [
    EventsOn('analyze:progress', (files, bytes, cur) => {
      scanInfo = `${files.toLocaleString()} files · ${fmt(bytes)}<br><span class="path">${esc(cur)}</span>`;
      const m = document.getElementById('scaninfo');
      if (m) m.innerHTML = scanInfo;
    }),
    EventsOn('analyze:done', async (root) => {
      offs.forEach(f => f()); offs = [];
      await open(root);
      view = 'map';
      if (onThisTab()) render(el);
    }),
    EventsOn('analyze:error', msg => {
      offs.forEach(f => f()); offs = [];
      error = msg; view = 'home';
      if (onThisTab()) render(el);
    }),
  ];
  try { await StartAnalyze(path); } catch (e) { error = String(e); view = 'home'; }
  render(el);
}

function drawScanning(el) {
  el.innerHTML = `<div class="hero"><div class="orb spin" style="--orb:#d9a066"></div>
    <div class="muted hero-line" id="scaninfo" style="max-width:560px">${scanInfo}</div>
    <button class="btn ghost" id="cancel">Cancel</button></div>`;
  el.querySelector('#cancel').onclick = () => CancelAnalyze();
}

async function open(path) {
  level = await AnalyzeLevel(path);
  level.items = level.items || [];
  selected.clear();
}

// Squarified treemap (Bruls et al.). Returns [{item, x, y, w, h}].
function squarify(items, x, y, w, h) {
  const total = items.reduce((s, i) => s + i.size, 0);
  if (!total || w <= 0 || h <= 0) return [];
  const scale = (w * h) / total;
  const nodes = items.map(i => ({item: i, area: i.size * scale}));
  const out = [];
  let row = [];
  const worst = (r, side) => {
    const s = r.reduce((a, n) => a + n.area, 0);
    let mx = 0, mn = Infinity;
    for (const n of r) { mx = Math.max(mx, n.area); mn = Math.min(mn, n.area); }
    return Math.max((side * side * mx) / (s * s), (s * s) / (side * side * mn));
  };
  const layout = r => {
    const s = r.reduce((a, n) => a + n.area, 0);
    if (w >= h) {
      const cw = s / h; let cy = y;
      for (const n of r) { const nh = n.area / cw; out.push({item: n.item, x, y: cy, w: cw, h: nh}); cy += nh; }
      x += cw; w -= cw;
    } else {
      const rh = s / w; let cx = x;
      for (const n of r) { const nw = n.area / rh; out.push({item: n.item, x: cx, y, w: nw, h: rh}); cx += nw; }
      y += rh; h -= rh;
    }
  };
  for (const n of nodes) {
    const side = Math.min(w, h);
    if (!row.length || worst([...row, n], side) <= worst(row, side)) row.push(n);
    else { layout(row); row = [n]; }
  }
  if (row.length) layout(row);
  return out;
}

function crumbs() {
  const root = level.root.replace(/\\$/, '');
  const rel = level.path.replace(/\\$/, '').slice(root.length).split('\\').filter(Boolean);
  const parts = [{name: root || level.root, path: level.root}];
  let acc = root;
  for (const r of rel) { acc += '\\' + r; parts.push({name: r, path: acc}); }
  return parts.map((p, i) => i === parts.length - 1 ? `<b>${esc(p.name)}</b>` : `<a class="link" data-go="${esc(p.path)}">${esc(p.name)}</a>`).join(' › ');
}

function drawMap(el) {
  const items = level.items.filter(i => i.size > 0);
  el.innerHTML = `<div class="analyze">
    <div class="clean-head"><div><h1>${fmt(level.size)}</h1><div class="muted crumbs">${crumbs()} · ${level.files.toLocaleString()} files</div></div>
      <div style="display:flex;gap:6px"><button class="iconbtn" id="up" title="Up one level">↑</button>
      <button class="iconbtn" id="rescan" title="Scan again">⟳</button><button class="iconbtn" id="home" title="Close">✕</button></div></div>
    <div class="amain"><div class="treemap" id="tm"></div>
      <div class="alist">${items.map((it, i) => `<div class="arow ${it.isDir ? 'dir' : ''}" data-i="${i}">
        ${it.other ? '<span style="width:16px"></span>' : `<input type="checkbox" data-i="${i}" ${selected.has(it.path) ? 'checked' : ''}>`}
        <span class="sw" style="background:${PALETTE[i % PALETTE.length]}"></span>
        <div class="grow"><div class="name">${it.isDir ? '📁 ' : ''}${esc(it.name)}${warnIcon(it.warn)}</div>
        <div class="path">${(100 * it.size / level.size).toFixed(1)}%${it.isDir ? ' · ' + it.files.toLocaleString() + ' files' : ''}</div></div>
        <span class="size">${fmt(it.size)}</span>
        ${it.other ? '' : `<button class="iconbtn" style="font-size:13px" data-reveal="${i}" title="Show in Explorer">↗</button>`}</div>`).join('')}</div></div>
    <div class="bottombar"><span id="selinfo" class="muted">Select items to move them to the Recycle Bin</span>
      <button class="btn" id="del" disabled>Move to Recycle Bin</button></div></div>`;

  const tm = el.querySelector('#tm');
  const draw = () => {
    const r = tm.getBoundingClientRect();
    tm.innerHTML = squarify(items, 0, 0, r.width, r.height).map(b => {
      const i = items.indexOf(b.item);
      const big = b.w > 70 && b.h > 34;
      return `<div class="tile ${b.item.isDir ? 'dir' : ''}" data-i="${i}" title="${esc(b.item.name)} · ${fmt(b.item.size)}${b.item.warn ? ' — ⚠ ' + esc(b.item.warn) : ''}"
        style="left:${b.x}px;top:${b.y}px;width:${b.w}px;height:${b.h}px;background:${PALETTE[i % PALETTE.length]}">
        ${big ? `<div class="tname">${b.item.warn ? '⚠ ' : ''}${esc(b.item.name)}</div><div class="tsize">${fmt(b.item.size)}</div>` : ''}</div>`;
    }).join('');
    tm.querySelectorAll('.tile').forEach(t => t.onclick = () => go(el, items[+t.dataset.i]));
  };
  requestAnimationFrame(draw);
  window.onresize = () => { if (el.querySelector('#tm')) draw(); };

  el.querySelectorAll('[data-go]').forEach(a => a.onclick = () => openAndDraw(el, a.dataset.go));
  el.querySelectorAll('.arow').forEach(r => r.onclick = ev => {
    if (ev.target.closest('input,button')) return;
    go(el, items[+r.dataset.i]);
  });
  el.querySelectorAll('.arow input').forEach(cb => cb.onchange = () => {
    const p = items[+cb.dataset.i].path;
    cb.checked ? selected.add(p) : selected.delete(p);
    bar(el, items);
  });
  el.querySelectorAll('[data-reveal]').forEach(b => b.onclick = () => Reveal(items[+b.dataset.reveal].path));
  el.querySelector('#up').onclick = () => {
    if (level.path.replace(/\\$/, '') === level.root.replace(/\\$/, '')) return;
    openAndDraw(el, level.path.replace(/\\[^\\]+\\?$/, '') || level.root);
  };
  el.querySelector('#rescan').onclick = () => scan(el, level.root);
  el.querySelector('#home').onclick = () => { view = 'home'; level = null; render(el); };
  bar(el, items);
}

function bar(el, items) {
  const sel = items.filter(i => selected.has(i.path));
  const btn = el.querySelector('#del');
  btn.disabled = !sel.length;
  el.querySelector('#selinfo').textContent = sel.length ? `${sel.length} selected · ${fmt(sel.reduce((s, i) => s + i.size, 0))}` : 'Select items to move them to the Recycle Bin';
  btn.onclick = async () => {
    const ok = await confirmBox(`Move ${sel.length} item${sel.length > 1 ? 's' : ''} to the Recycle Bin?`,
      esc(sel.map(i => i.name).join(', ')) + sel.filter(i => i.warn).map(i => `<br><br><span class="warntext">⚠ ${esc(i.name)}: ${esc(i.warn)}</span>`).join('') + '<br><br>You can restore them from the Recycle Bin.', 'Move to Recycle Bin');
    if (!ok) return;
    try { await RecyclePaths(sel.map(i => i.path)); } catch (e) { await confirmBox('Could not remove', esc(e), 'OK'); }
    openAndDraw(el, level.path);
  };
}

function go(el, item) {
  if (item.isDir) openAndDraw(el, item.path);
}

async function openAndDraw(el, path) {
  try { await open(path); } catch (e) { error = String(e); view = 'home'; }
  render(el);
}
