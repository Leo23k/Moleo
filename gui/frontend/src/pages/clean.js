import {ScanClean, RunClean, Reveal} from '../../wailsjs/go/main/App';
import {EventsOn} from '../../wailsjs/runtime/runtime';
import {fmt, esc, confirmBox, hero} from '../util.js';

// Developer caches and the Recycle Bin cost something to clear, so
// "Recommended" leaves them out.
const NOT_RECOMMENDED = new Set(['dev', 'bin']);
let scan = null;
let selected = new Set();
const open = new Set();

export function render(el) {
  if (scan) return drawList(el);
  hero(el, {
    orb: '#6f8fb3',
    line: '200+ cache locations, checked one by one.<br>Nothing is deleted until you choose.',
    buttons: [{text: 'Scan', onClick: () => startScan(el)}],
  });
}

const recommended = () => scan.entries.filter(e => !NOT_RECOMMENDED.has(e.category)).map(e => e.id);

async function startScan(el) {
  el.innerHTML = `<div class="hero"><div class="orb spin" style="--orb:#6f8fb3"></div>
    <div class="muted" id="scanmsg">Scanning…</div><div class="progress"><div id="scanbar"></div></div></div>`;
  const off = EventsOn('clean:progress', (n, total, name) => {
    const bar = document.getElementById('scanbar');
    const msg = document.getElementById('scanmsg');
    if (bar) bar.style.width = (100 * n / total) + '%';
    if (msg) msg.textContent = `Checked ${n} of ${total} · ${name}`;
  });
  try {
    scan = await ScanClean();
    scan.entries = scan.entries || [];
    selected = new Set(recommended());
  } catch (e) {
    scan = null;
    hero(el, {orb: '#b36f6f', line: 'Scan failed: ' + esc(e), buttons: [{text: 'Try again', onClick: () => startScan(el)}]});
    return;
  } finally {
    off();
  }
  drawList(el);
}

function catHtml(c) {
  const sel = c.items.filter(e => selected.has(e.id));
  const selBytes = sel.reduce((s, e) => s + e.bytes, 0);
  const all = c.items.reduce((s, e) => s + e.bytes, 0);
  const full = sel.length === c.items.length;
  const items = c.items.map(e => `<div class="item">
      <input type="checkbox" data-id="${e.id}" ${selected.has(e.id) ? 'checked' : ''}>
      <div class="grow"><div class="name">${esc(e.name)}</div><div class="path">${esc(e.path)}</div></div>
      <span class="size">${fmt(e.bytes)}</span>
      <button class="iconbtn" style="font-size:13px" data-reveal="${esc(e.path.split('  (+')[0])}" title="Show in Explorer">📁</button>
    </div>`).join('');
  return `<div class="cat ${open.has(c.id) ? 'open' : ''}" data-cat="${c.id}">
    <div class="cat-row"><input type="checkbox" ${full ? 'checked' : ''} ${sel.length && !full ? 'data-mixed' : ''}>
      <div class="grow"><span class="title">${esc(c.name)}</span><span class="count">${sel.length}/${c.items.length} selected</span>
      <div class="desc">${esc(c.description)}</div></div>
      <span class="size">${selBytes === all ? fmt(all) : fmt(selBytes) + ' / ' + fmt(all)}</span><span class="chev">⌄</span></div>
    <div class="items">${items}</div></div>`;
}

function drawList(el) {
  const byCat = scan.categories
    .map(c => ({...c, items: scan.entries.filter(e => e.category === c.id)}))
    .filter(c => c.items.length);
  const total = scan.entries.reduce((s, e) => s + e.bytes, 0);
  const scrollTop = el.querySelector('.cats')?.scrollTop || 0;
  el.innerHTML = `<div class="clean">
    <div class="clean-head"><div><h1>Ready to clean</h1>
      <div class="muted">${fmt(total)} cleanable · ${scan.entries.length} items · ${byCat.length} categories · ${scan.locations} locations checked</div></div>
      <button class="iconbtn" id="rescan" title="Scan again">⟳</button></div>
    <div class="cats">${byCat.map(catHtml).join('')}</div>
    <div class="bottombar"><span id="selcount"></span>
      <span class="links"><a data-sel="all">All</a> · <a data-sel="none">None</a> · <a data-sel="rec">Recommended</a></span>
      <button class="btn" id="go"></button></div></div>`;
  el.querySelector('.cats').scrollTop = scrollTop;

  el.querySelector('#rescan').onclick = () => { scan = null; startScan(el); };
  el.querySelectorAll('[data-sel]').forEach(a => a.onclick = () => {
    const m = a.dataset.sel;
    selected = new Set(m === 'none' ? [] : m === 'all' ? scan.entries.map(e => e.id) : recommended());
    drawList(el);
  });
  el.querySelectorAll('.cat').forEach(catEl => {
    const id = catEl.dataset.cat;
    const items = scan.entries.filter(e => e.category === id);
    catEl.querySelector('.cat-row').onclick = ev => {
      if (ev.target.type === 'checkbox') return;
      if (open.has(id)) open.delete(id); else open.add(id);
      catEl.classList.toggle('open');
    };
    catEl.querySelector('.cat-row input').onchange = ev => {
      items.forEach(e => (ev.target.checked ? selected.add(e.id) : selected.delete(e.id)));
      drawList(el);
    };
  });
  el.querySelectorAll('.item input').forEach(cb => cb.onchange = () => {
    if (cb.checked) selected.add(cb.dataset.id); else selected.delete(cb.dataset.id);
    drawList(el);
  });
  el.querySelectorAll('[data-reveal]').forEach(b => b.onclick = () => Reveal(b.dataset.reveal));
  el.querySelectorAll('[data-mixed]').forEach(cb => (cb.indeterminate = true));
  updateBar(el);
}

function updateBar(el) {
  const sel = scan.entries.filter(e => selected.has(e.id));
  const bytes = sel.reduce((s, e) => s + e.bytes, 0);
  const hasBin = sel.some(e => e.category === 'bin');
  el.querySelector('#selcount').textContent = `${sel.length} selected`;
  const go = el.querySelector('#go');
  go.textContent = `${hasBin ? 'Permanently clean' : 'Clean'} · ${fmt(bytes)}`;
  go.disabled = !sel.length;
  go.onclick = async () => {
    const ok = await confirmBox('Clean ' + fmt(bytes) + '?',
      `${sel.length} items will be deleted. Files that are in use are skipped.` +
      (hasBin ? '<br><b>Recycle Bin items are removed permanently.</b>' : ''), 'Clean');
    if (!ok) return;
    hero(el, {orb: '#6f8fb3', line: 'Cleaning…', spin: true});
    const again = [{text: 'Scan again', onClick: () => startScan(el)}];
    try {
      const r = await RunClean([...selected]);
      scan = null;
      hero(el, {orb: '#6fb38a', buttons: again,
        line: `Freed <b>${fmt(r.removedBytes)}</b> · ${r.removedFiles} files removed` +
          (r.skipped ? `<br>${r.skipped} files in use or protected were skipped` : '')});
    } catch (e) {
      scan = null;
      hero(el, {orb: '#b36f6f', line: 'Clean failed: ' + esc(e), buttons: again});
    }
  };
}
