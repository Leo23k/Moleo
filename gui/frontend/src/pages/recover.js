import {
  ListBin, RestoreBin, FindLostMedia, PickSaveFolder, SaveCopies, FindPreviousVersions,
  WinfrInstalled, OpenWinfrStore, StartDeepScan, StopDeepScan, ListDrives, IsAdmin, RelaunchAsAdmin, Reveal,
} from '../../wailsjs/go/main/App';
import {EventsOn} from '../../wailsjs/runtime/runtime';
import {fmt, esc, confirmBox, hero} from '../util.js';

let sub = 'bin';
const st = {
  bin: null, binSel: new Set(), binQ: '',
  lost: null, lostSel: new Set(),
  versions: null, versionsPath: '', versionsErr: '',
  deep: {running: false, lines: [], done: '', drive: 'C:', dest: '', mode: 'regular', filter: '*.mp4'},
  msg: '',
};

const onThisTab = () => document.querySelector('.topnav button.active')?.dataset.page === 'recover';
const when = d => new Date(d).toLocaleString();
const SUBS = [['bin', 'Recycle Bin'], ['lost', 'Lost recordings'], ['versions', 'Previous versions'], ['deep', 'Deep scan']];

export function render(el) {
  el.innerHTML = `<div class="apps">
    <div class="subnav">${SUBS.map(([k, t]) => `<button data-sub="${k}" class="${k === sub ? 'active' : ''}">${t}</button>`).join('')}
      <button class="iconbtn" id="reload" title="Refresh">⟳</button><div class="grow"></div><div id="tools"></div></div>
    ${st.msg ? `<div class="listhead">${st.msg}</div>` : ''}
    <div id="body" class="appsbody"></div></div>`;
  el.querySelectorAll('[data-sub]').forEach(b => b.onclick = () => { sub = b.dataset.sub; st.msg = ''; render(el); });
  el.querySelector('#reload').onclick = () => { st.msg = ''; if (sub === 'bin') st.bin = null; if (sub === 'lost') st.lost = null; render(el); };
  ({bin: drawBin, lost: drawLost, versions: drawVersions, deep: drawDeep})[sub](el.querySelector('#body'), el);
}

const loading = (body, text) => hero(body, {orb: '#7aa6b3', line: text, spin: true});

function resultMsg(r, verb) {
  const ok = (r.restored || []).length, bad = (r.errors || []).length;
  return `<span class="ok">${verb} ${ok} item${ok === 1 ? '' : 's'}</span>` +
    (bad ? ` · <span class="bad">${bad} failed: ${esc(r.errors.slice(0, 3).join('; '))}</span>` : '');
}

// ---- Recycle Bin ------------------------------------------------------

async function drawBin(body, el) {
  if (!st.bin) {
    loading(body, 'Reading the Recycle Bin…');
    st.bin = (await ListBin()) || [];
    if (onThisTab() && sub === 'bin') render(el);
    return;
  }
  const tools = el.querySelector('#tools');
  tools.innerHTML = `<input id="q" placeholder="Search" value="${esc(st.binQ)}">`;
  const q = tools.querySelector('#q');
  const list = () => st.bin.filter(b => !st.binQ || b.original.toLowerCase().includes(st.binQ.toLowerCase()));
  const draw = () => {
    const items = list();
    body.innerHTML = `<div class="muted listhead">${st.bin.length} items in the Recycle Bin · newest first.
      Restored items go back where they were; if a file with that name exists, the restored one gets a new name.</div>
      <div class="applist">${items.map(b => `<label class="approw ${st.binSel.has(b.id) ? 'sel' : ''}">
        <div class="apptile" style="background:#4f6470">${b.isDir ? '📁' : '📄'}</div>
        <div class="grow"><div class="name">${esc(b.name)}</div><div class="path">${esc(b.original)} · deleted ${when(b.deleted)}</div></div>
        <span class="size">${fmt(b.size)}</span><input type="checkbox" data-id="${b.id}" ${st.binSel.has(b.id) ? 'checked' : ''}></label>`).join('')
        || '<div class="muted">The Recycle Bin is empty. For files deleted from it, use Deep scan.</div>'}</div>
      <div class="bottombar"><span id="info"></span><button class="btn" id="restore">Restore</button></div>`;
    body.querySelectorAll('input[data-id]').forEach(cb => cb.onchange = () => {
      cb.checked ? st.binSel.add(cb.dataset.id) : st.binSel.delete(cb.dataset.id);
      cb.closest('.approw').classList.toggle('sel', cb.checked); bar();
    });
    bar();
  };
  const bar = () => {
    const n = st.binSel.size;
    body.querySelector('#info').textContent = `${n} selected`;
    const b = body.querySelector('#restore');
    b.textContent = n ? `Restore ${n}` : 'Restore';
    b.disabled = !n;
    b.onclick = async () => {
      const r = await RestoreBin([...st.binSel]);
      st.msg = resultMsg(r, 'Restored');
      st.binSel.clear(); st.bin = null; render(el);
    };
  };
  q.oninput = () => { st.binQ = q.value; draw(); };
  draw();
}

// ---- Lost recordings --------------------------------------------------

async function drawLost(body, el) {
  if (!st.lost) {
    loading(body, 'Looking for unsaved recordings and captures…');
    st.lost = (await FindLostMedia()) || [];
    if (onThisTab() && sub === 'lost') render(el);
    return;
  }
  const groups = [...new Set(st.lost.map(f => f.source))];
  body.innerHTML = `<div class="muted listhead">Videos, audio and images left in app temp folders in the last 60 days —
    for example a Snipping Tool recording cut off by a shutdown. Files are copied, never moved.
    A cut-off recording may need a video repair tool to play.</div>
    <div class="applist">${groups.map(g => {
      const files = st.lost.filter(f => f.source === g);
      return `<div class="name" style="margin:10px 4px 4px">${esc(g)} <span class="muted">· ${files.length}</span></div>` +
        files.slice(0, 300).map(f => `<label class="approw ${st.lostSel.has(f.path) ? 'sel' : ''}">
          <div class="grow"><div class="name">${esc(f.name)}</div><div class="path">${esc(f.path)} · ${when(f.modified)}</div></div>
          <span class="size">${fmt(f.size)}</span>
          <button class="iconbtn" style="font-size:13px" data-reveal="${esc(f.path)}">↗</button>
          <input type="checkbox" data-p="${esc(f.path)}" ${st.lostSel.has(f.path) ? 'checked' : ''}></label>`).join('');
    }).join('') || '<div class="muted">Nothing found. If the file was deleted, try Deep scan.</div>'}</div>
    <div class="bottombar"><span id="info"></span><button class="btn" id="save">Save copies…</button></div>`;
  body.querySelectorAll('[data-reveal]').forEach(b => b.onclick = ev => { ev.preventDefault(); Reveal(b.dataset.reveal); });
  const bar = () => {
    body.querySelector('#info').textContent = `${st.lostSel.size} selected`;
    const b = body.querySelector('#save');
    b.disabled = !st.lostSel.size;
    b.onclick = async () => {
      const dest = await PickSaveFolder();
      if (!dest) return;
      const r = await SaveCopies([...st.lostSel], dest);
      st.msg = resultMsg(r, 'Saved') + ` to ${esc(dest)}`;
      st.lostSel.clear(); render(el);
    };
  };
  body.querySelectorAll('input[data-p]').forEach(cb => cb.onchange = () => {
    cb.checked ? st.lostSel.add(cb.dataset.p) : st.lostSel.delete(cb.dataset.p);
    cb.closest('.approw').classList.toggle('sel', cb.checked); bar();
  });
  bar();
}

// ---- Previous versions ------------------------------------------------

async function adminGate(body, what) {
  if (await IsAdmin()) return false;
  hero(body, {orb: '#7aa6b3', line: `${what} needs administrator rights.`,
    buttons: [{text: 'Run as administrator', onClick: () => RelaunchAsAdmin().catch(() => {})}]});
  return true;
}

async function drawVersions(body, el) {
  if (await adminGate(body, 'Reading previous versions')) return;
  body.innerHTML = `<div class="muted listhead">Windows keeps older copies of files in restore points (shadow copies) when System Protection is on.
    Enter the full path of a file or folder — it can be one you already deleted.</div>
    <div style="display:flex;gap:8px;margin-bottom:10px"><input id="vp" class="field" placeholder="C:\\Users\\you\\Documents\\report.docx" value="${esc(st.versionsPath)}">
    <button class="btn small" id="find">Find versions</button></div>
    ${st.versionsErr ? `<div class="bad listhead">${esc(st.versionsErr)}</div>` : ''}
    <div class="applist">${(st.versions || []).map((v, i) => `<div class="approw">
      <div class="apptile" style="background:#4f6470">${v.isDir ? '📁' : '📄'}</div>
      <div class="grow"><div class="name">${esc(v.created)}</div><div class="path">${esc(v.path)}</div></div>
      ${v.isDir ? '' : `<span class="size">${fmt(v.size)}</span>`}
      <button class="btn ghost small" data-i="${i}">Save copy…</button></div>`).join('')
      || (st.versions ? '<div class="muted">No older copies of this path were found.</div>' : '')}</div>`;
  const vp = body.querySelector('#vp');
  body.querySelector('#find').onclick = async () => {
    st.versionsPath = vp.value.trim().replace(/^"|"$/g, '');
    st.versionsErr = '';
    loading(body, 'Searching restore points…');
    try { st.versions = (await FindPreviousVersions(st.versionsPath)) || []; }
    catch (e) { st.versions = null; st.versionsErr = String(e); }
    if (onThisTab() && sub === 'versions') render(el);
  };
  body.querySelectorAll('[data-i]').forEach(b => b.onclick = async () => {
    const dest = await PickSaveFolder();
    if (!dest) return;
    const r = await SaveCopies([st.versions[+b.dataset.i].path], dest);
    st.msg = resultMsg(r, 'Saved') + ` to ${esc(dest)}`;
    render(el);
  });
}

// ---- Deep scan --------------------------------------------------------

let offs = [];
async function drawDeep(body, el) {
  const d = st.deep;
  if (!(await WinfrInstalled())) {
    return hero(body, {orb: '#7aa6b3',
      line: 'Deep scan finds files deleted from the Recycle Bin or long ago, using Microsoft\'s free <b>Windows File Recovery</b>.<br>Install it from the Microsoft Store, then come back.',
      buttons: [{text: 'Open Microsoft Store', onClick: () => OpenWinfrStore()}, {text: 'I installed it', ghost: true, onClick: () => render(el)}]});
  }
  if (await adminGate(body, 'Deep scan')) return;
  const drives = (await ListDrives()) || [];
  body.innerHTML = `<div class="muted listhead"><b>Stop using the drive</b> you want to recover from: new files can overwrite deleted ones.
    On SSDs, Windows usually wipes deleted data within minutes (TRIM), so results there are limited; HDDs, USB sticks and SD cards recover best.</div>
    <div class="deepform">
      <label>Scan drive<select id="drive" ${d.running ? 'disabled' : ''}>${drives.map(x => `<option ${x.path.slice(0, 2) === d.drive ? 'selected' : ''}>${x.path.slice(0, 2)}</option>`).join('')}</select></label>
      <label>Find<input id="filter" class="field" value="${esc(d.filter)}" ${d.running ? 'disabled' : ''} title="*.mp4, *.docx, or a folder like \\Users\\you\\Videos\\"></label>
      <label>Mode<select id="mode" ${d.running ? 'disabled' : ''}>
        <option value="regular" ${d.mode === 'regular' ? 'selected' : ''}>Regular — recently deleted (NTFS)</option>
        <option value="extensive" ${d.mode === 'extensive' ? 'selected' : ''}>Extensive — older, formatted, FAT/exFAT</option></select></label>
      <label>Save to (other drive)<div style="display:flex;gap:6px"><input id="dest" class="field" value="${esc(d.dest)}" readonly placeholder="Choose a folder on another drive">
        <button class="btn ghost small" id="pick" ${d.running ? 'disabled' : ''}>Choose…</button></div></label>
    </div>
    <pre class="details" id="log" style="flex:1;max-height:none;min-height:120px">${esc(d.lines.slice(-400).join('\n')) || 'Output appears here.'}</pre>
    <div class="bottombar"><span>${d.done ? esc(d.done) : d.running ? 'Scanning… this can take a long time.' : ''}</span>
      ${d.running ? '<button class="btn ghost" id="stop">Stop</button>' : '<button class="btn" id="go">Start deep scan</button>'}</div>`;
  const log = body.querySelector('#log');
  log.scrollTop = log.scrollHeight;
  const read = () => {
    d.drive = body.querySelector('#drive').value;
    d.filter = body.querySelector('#filter').value.trim();
    d.mode = body.querySelector('#mode').value;
  };
  body.querySelector('#pick')?.addEventListener('click', async () => { read(); const p = await PickSaveFolder(); if (p) d.dest = p; render(el); });
  body.querySelector('#stop')?.addEventListener('click', () => StopDeepScan());
  body.querySelector('#go')?.addEventListener('click', async () => {
    read();
    const ok = await confirmBox('Start deep scan?', `Scan ${esc(d.drive)} for <b>${esc(d.filter)}</b> and copy what is found to ${esc(d.dest || '(choose a folder)')}.`, 'Start');
    if (!ok) return;
    d.lines = []; d.done = '';
    offs.forEach(f => f());
    offs = [
      EventsOn('recover:line', l => {
        d.lines.push(l);
        const lg = document.getElementById('log');
        if (lg && sub === 'deep') { lg.textContent = d.lines.slice(-400).join('\n'); lg.scrollTop = lg.scrollHeight; }
      }),
      EventsOn('recover:done', (err, dest) => {
        offs.forEach(f => f()); offs = [];
        d.running = false;
        d.done = err ? 'Stopped: ' + err : 'Finished. Recovered files are in ' + dest;
        if (!err) Reveal(dest);
        if (onThisTab() && sub === 'deep') render(el);
      }),
    ];
    try { await StartDeepScan(d.drive, d.dest, d.mode, d.filter); d.running = true; }
    catch (e) { d.done = String(e); offs.forEach(f => f()); offs = []; }
    render(el);
  });
}
