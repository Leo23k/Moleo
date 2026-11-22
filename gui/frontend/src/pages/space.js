import {
  QuickItems, RunQuick, IsAdmin, RelaunchAsAdmin, ListDrives, PickFolder,
  FindLargeFiles, FindDuplicates, CancelFiles, RecycleFiles, Reveal,
  MoveCandidates, MoveFolder, UndoMove, MoveCustomCandidate, HomeDir,
} from '../../wailsjs/go/main/App';
import {EventsOn} from '../../wailsjs/runtime/runtime';
import {fmt, esc, confirmBox, hero, warnIcon} from '../util.js';

let sub = 'quick';
const st = {
  drives: null, admin: false,
  quick: null, quickRun: '', quickLog: [], quickMsg: '',
  large: null, largeRoot: 'C:\\', largeMin: 200, largeSel: new Set(), largeBusy: false, largeMsg: '',
  dup: null, dupRoot: '', dupSel: new Set(), dupBusy: false, dupMsg: '',
  move: null, moveDrive: '', moveBusy: '', moveMsg: '',
  progress: 0,
};

const onThisTab = () => document.querySelector('.topnav button.active')?.dataset.page === 'space';
const SUBS = [['quick', 'Quick free-up'], ['large', 'Large files'], ['move', 'Move to another drive'], ['dup', 'Duplicates']];
const when = d => new Date(d).toLocaleDateString();

export async function render(el) {
  if (!st.drives) {
    [st.drives, st.admin] = await Promise.all([ListDrives(), IsAdmin()]);
    st.drives = st.drives || [];
    const other = st.drives.find(d => !d.path.startsWith('C'));
    st.moveDrive = other ? other.path.slice(0, 2) : '';
  }
  const sys = st.drives.find(d => d.path.startsWith('C')) || st.drives[0];
  const used = sys ? 100 * (sys.total - sys.free) / sys.total : 0;
  el.innerHTML = `<div class="apps">
    <div class="subnav">${SUBS.map(([k, t]) => `<button data-sub="${k}" class="${k === sub ? 'active' : ''}">${t}</button>`).join('')}
      <div class="grow"></div>
      ${sys ? `<div class="drivepill"><b>${esc(sys.path.slice(0, 2))}</b> <span class="muted">${fmt(sys.free)} free</span>
        <div class="bar ${used >= 90 ? 'bad' : used >= 75 ? 'warn' : ''}" style="width:120px;margin:0"><div style="width:${used.toFixed(1)}%"></div></div></div>` : ''}
    </div>
    <div id="body" class="appsbody"></div></div>`;
  el.querySelectorAll('[data-sub]').forEach(b => b.onclick = () => { sub = b.dataset.sub; render(el); });
  const body = el.querySelector('#body');
  ({quick: drawQuick, large: drawLarge, move: drawMove, dup: drawDup})[sub](body, el);
}

const refreshDrives = async () => { st.drives = (await ListDrives()) || st.drives; };
const adminBtn = () => st.admin ? '' : `<button class="btn ghost small" id="admin">Run as administrator</button>`;
const bindAdmin = body => body.querySelector('#admin')?.addEventListener('click', () => RelaunchAsAdmin().catch(() => {}));

// ---- Quick free-up -----------------------------------------------------

async function drawQuick(body, el) {
  if (!st.quick) {
    hero(body, {orb: '#fff', line: 'Measuring what can be freed…', spin: true});
    st.quick = (await QuickItems()) || [];
    if (onThisTab() && sub === 'quick') render(el);
    return;
  }
  const total = st.quick.filter(q => q.available).reduce((s, q) => s + q.bytes, 0);
  body.innerHTML = `<div class="muted listhead"><span>The biggest wins on the system drive, each fixed with one click by a built-in Windows tool.</span>
      <span>Measured:</span> <b>${fmt(total)}</b> <span>${st.admin ? '' : '· these need administrator'}</span> ${adminBtn()}</div>
    ${st.quickMsg ? `<div class="listhead">${st.quickMsg}</div>` : ''}
    <div class="applist">${st.quick.map(q => `<div class="approw ${q.available ? '' : 'dim'}">
      <div class="grow"><div class="name">${esc(q.name)}${warnIcon(q.warn)}</div>
      <div class="qdesc">${esc(q.desc)}</div>
      ${(q.paths || []).length ? `<div class="path">${q.paths.map(esc).join(' · ')}</div>` : ''}</div>
      <span class="size">${q.available ? (q.bytes ? fmt(q.bytes) : esc(q.estimate)) : 'Nothing to free'}</span>
      ${q.available ? `<button class="btn ${st.quickRun === q.id ? 'ghost' : ''} small" data-q="${q.id}" ${st.quickRun ? 'disabled' : ''}>${st.quickRun === q.id ? 'Working…' : 'Free up'}</button>` : ''}
    </div>`).join('')}</div>
    ${st.quickLog.length ? `<pre class="details" id="qlog">${esc(st.quickLog.slice(-200).join('\n'))}</pre>` : ''}`;
  bindAdmin(body);
  const log = body.querySelector('#qlog');
  if (log) log.scrollTop = log.scrollHeight;
  body.querySelectorAll('[data-q]').forEach(b => b.onclick = async () => {
    const q = st.quick.find(x => x.id === b.dataset.q);
    if (!st.admin) { st.quickMsg = '<span class="bad">Run Moleo as administrator first.</span>'; return render(el); }
    const ok = await confirmBox(q.name + '?', esc(q.desc) + (q.warn ? `<br><br><span class="warntext">⚠ ${esc(q.warn)}</span>` : ''), 'Free up');
    if (!ok) return;
    const before = st.drives.find(d => d.path.startsWith('C'))?.free || 0;
    st.quickRun = q.id; st.quickLog = []; st.quickMsg = '';
    const off = EventsOn('space:line', l => {
      st.quickLog.push(l);
      const lg = document.getElementById('qlog');
      if (lg) { lg.textContent = st.quickLog.slice(-200).join('\n'); lg.scrollTop = lg.scrollHeight; }
      else if (onThisTab() && sub === 'quick') render(el);
    });
    render(el);
    try {
      const free = await RunQuick(q.id);
      st.quickMsg = `<span class="ok">Done. Freed about ${fmt(Math.max(0, free - before))}.</span>`;
    } catch (e) { st.quickMsg = `<span class="bad">${esc(e)}</span>`; }
    off();
    st.quickRun = ''; st.quick = null;
    await refreshDrives();
    if (onThisTab()) render(el);
  });
}

// ---- Large files -------------------------------------------------------

function scanning(body, text) {
  body.innerHTML = `<div class="hero"><div class="orb spin"></div><div class="muted" id="prog">${text}</div>
    <button class="btn ghost" id="cancel">Cancel</button></div>`;
  body.querySelector('#cancel').onclick = () => CancelFiles();
  return EventsOn('files:progress', n => {
    const p = document.getElementById('prog');
    if (p) p.textContent = `${text} ${Number(n).toLocaleString()} files checked`;
  });
}

async function drawLarge(body, el) {
  if (st.largeBusy) return;
  const drives = st.drives.map(d => `<option value="${esc(d.path)}" ${d.path === st.largeRoot ? 'selected' : ''}>${esc(d.path.slice(0, 2))}</option>`).join('');
  const head = `<div class="toolbar">
      <label>Drive <select id="lroot">${drives}${st.drives.some(d => d.path === st.largeRoot) ? '' : `<option selected>${esc(st.largeRoot)}</option>`}</select></label>
      <button class="btn ghost small" id="lfolder">Folder…</button>
      <label>At least <select id="lmin">${[100, 200, 500, 1000, 5000].map(m => `<option value="${m}" ${m === st.largeMin ? 'selected' : ''}>${m >= 1000 ? m / 1000 + ' GB' : m + ' MB'}</option>`).join('')}</select></label>
      <button class="btn small" id="lscan">Find large files</button></div>`;
  if (!st.large) {
    body.innerHTML = head + `<div class="hero" style="height:auto;flex:1"><div class="orb"></div>
      <div class="muted hero-line">Finds the biggest files: old installers, disk images, videos and archives.<br>Removed files go to the Recycle Bin.</div></div>`;
  } else {
    const sel = st.large.filter(f => st.largeSel.has(f.path));
    body.innerHTML = head + `${st.largeMsg ? `<div class="listhead">${st.largeMsg}</div>` : ''}
      <div class="muted listhead">${st.large.length} files · ${fmt(st.large.reduce((s, f) => s + f.size, 0))}</div>
      <div class="applist">${st.large.map(f => `<label class="approw ${st.largeSel.has(f.path) ? 'sel' : ''}">
        <div class="grow"><div class="name">${esc(f.name)}${f.kind ? ` <span class="tag">${esc(f.kind)}</span>` : ''}${warnIcon(f.warn)}</div>
        <div class="path">${esc(f.path)} · ${when(f.modified)}</div></div>
        <span class="size">${fmt(f.size)}</span>
        <button class="iconbtn" style="font-size:13px" data-reveal="${esc(f.path)}" title="Show in Explorer">↗</button>
        <input type="checkbox" data-p="${esc(f.path)}" ${st.largeSel.has(f.path) ? 'checked' : ''}></label>`).join('') || '<div class="muted">No files that large.</div>'}</div>
      <div class="bottombar"><span>${sel.length} selected · ${fmt(sel.reduce((s, f) => s + f.size, 0))}</span>
        <button class="btn" id="lrm" ${sel.length ? '' : 'disabled'}>Move to Recycle Bin</button></div>`;
  }
  const read = () => { st.largeRoot = body.querySelector('#lroot').value; st.largeMin = +body.querySelector('#lmin').value; };
  body.querySelector('#lfolder').onclick = async () => { read(); const p = await PickFolder(); if (p) { st.largeRoot = p; render(el); } };
  body.querySelector('#lscan').onclick = async () => {
    read();
    st.largeBusy = true; st.largeMsg = ''; st.largeSel.clear();
    const off = scanning(body, 'Looking for large files…');
    try { st.large = (await FindLargeFiles(st.largeRoot, st.largeMin, 200)) || []; }
    catch (e) { st.largeMsg = `<span class="bad">${esc(e)}</span>`; }
    off(); st.largeBusy = false;
    if (onThisTab() && sub === 'large') render(el);
  };
  body.querySelectorAll('[data-reveal]').forEach(b => b.onclick = ev => { ev.preventDefault(); Reveal(b.dataset.reveal); });
  body.querySelectorAll('input[data-p]').forEach(cb => cb.onchange = () => {
    cb.checked ? st.largeSel.add(cb.dataset.p) : st.largeSel.delete(cb.dataset.p); render(el);
  });
  body.querySelector('#lrm')?.addEventListener('click', async () => {
    const sel = st.large.filter(f => st.largeSel.has(f.path));
    const warns = sel.filter(f => f.warn).map(f => `<br><span class="warntext">⚠ ${esc(f.name)}: ${esc(f.warn)}</span>`).join('');
    if (!(await confirmBox(`Move ${sel.length} files to the Recycle Bin?`, fmt(sel.reduce((s, f) => s + f.size, 0)) + warns +
      '<br><br>Empty the Recycle Bin afterwards to get the space back.', 'Move to Recycle Bin'))) return;
    try {
      await RecycleFiles(sel.map(f => f.path));
      st.large = st.large.filter(f => !st.largeSel.has(f.path));
      st.largeMsg = `<span class="ok">Moved ${sel.length} files to the Recycle Bin.</span>`;
      st.largeSel.clear();
    } catch (e) { st.largeMsg = `<span class="bad">${esc(e)}</span>`; }
    render(el);
  });
}

// ---- Move to another drive ----------------------------------------------

async function drawMove(body, el) {
  const others = st.drives.filter(d => !d.path.startsWith('C'));
  if (!others.length) return hero(body, {orb: '#fff', line: 'There is no other drive to move folders to.'});
  if (!st.move) {
    hero(body, {orb: '#fff', line: 'Measuring folders…', spin: true});
    st.move = (await MoveCandidates()) || [];
    if (onThisTab() && sub === 'move') render(el);
    return;
  }
  const groups = [...new Set(st.move.map(c => c.group))];
  body.innerHTML = `<div class="toolbar"><label>Move to <select id="mdrive">${others.map(d =>
      `<option value="${d.path.slice(0, 2)}" ${d.path.startsWith(st.moveDrive) ? 'selected' : ''}>${d.path.slice(0, 2)} · ${fmt(d.free)} free</option>`).join('')}</select></label>
      <button class="btn ghost small" id="mcustom">Add a folder…</button>
      <span class="muted">Personal folders move like Properties › Location; others leave a link behind so apps keep working.</span></div>
    ${st.moveMsg ? `<div class="listhead">${st.moveMsg}</div>` : ''}
    <div class="applist">${groups.map(g => `<div class="name" style="margin:10px 4px 4px">${esc(g)}</div>` +
      st.move.filter(c => c.group === g).map(c => `<div class="approw">
        <div class="grow"><div class="name">${esc(c.name)}${c.note ? warnIcon(c.note) : ''}</div>
        <div class="path">${c.moved ? '→ ' + esc(c.movedTo) : esc(c.path)}</div></div>
        <span class="size">${c.elsewhere ? '<span class="muted">Already on another drive</span>' : c.moved ? '<span class="ok">Moved</span>' : fmt(c.bytes)}</span>
        ${c.elsewhere ? '' : st.moveBusy === c.id ? '<span class="muted">Moving…</span>'
          : c.moved ? `<button class="btn ghost small" data-undo="${esc(c.id)}" ${st.moveBusy ? 'disabled' : ''}>Move back</button>`
          : `<button class="btn small" data-mv="${esc(c.id)}" ${st.moveBusy || !c.bytes ? 'disabled' : ''}>Move</button>`}
      </div>`).join('')).join('')}</div>`;
  body.querySelector('#mdrive').onchange = e => { st.moveDrive = e.target.value; };
  body.querySelector('#mcustom').onclick = async () => {
    const p = await PickFolder();
    if (!p) return;
    try { st.move.push(await MoveCustomCandidate(p)); } catch (e) { st.moveMsg = `<span class="bad">${esc(e)}</span>`; }
    render(el);
  };
  const act = async (id, undo) => {
    const c = st.move.find(x => x.id === id);
    const text = undo ? `Move ${esc(c.name)} back to ${esc(c.path)}?`
      : `Move <b>${esc(c.name)}</b> (${fmt(c.bytes)}) to ${esc(st.moveDrive)}?<br><br>Close programs that use it first.` +
        (c.kind === 'known' ? ' Windows will open it from the new place.' : ' A link stays at the old path.');
    if (!(await confirmBox(undo ? 'Move back?' : 'Move folder?', text, undo ? 'Move back' : 'Move'))) return;
    st.moveBusy = id; st.moveMsg = ''; render(el);
    try {
      if (undo) { await UndoMove(id); st.moveMsg = `<span class="ok">${esc(c.name)} is back on the system drive.</span>`; }
      else { const dst = await MoveFolder(id, st.moveDrive); st.moveMsg = `<span class="ok">${esc(c.name)} moved to ${esc(dst)}.</span>`; }
    } catch (e) { st.moveMsg = `<span class="bad">${esc(e)}</span>`; }
    st.moveBusy = ''; st.move = null;
    await refreshDrives();
    if (onThisTab() && sub === 'move') render(el);
  };
  body.querySelectorAll('[data-mv]').forEach(b => b.onclick = () => act(b.dataset.mv, false));
  body.querySelectorAll('[data-undo]').forEach(b => b.onclick = () => act(b.dataset.undo, true));
}

// ---- Duplicates -------------------------------------------------------

async function drawDup(body, el) {
  if (st.dupBusy) return;
  const head = `<div class="toolbar"><input class="field" id="droot" readonly value="${esc(st.dupRoot)}" placeholder="Your user folder (without AppData)">
    <button class="btn ghost small" id="dfolder">Folder…</button><button class="btn small" id="dscan">Find duplicates</button></div>`;
  if (!st.dup) {
    body.innerHTML = head + `<div class="hero" style="height:auto;flex:1"><div class="orb"></div>
      <div class="muted hero-line">Finds files with exactly the same content (checked by SHA-256), 1 MB or larger.<br>The oldest copy in each group is kept by default.</div></div>`;
  } else {
    const all = st.dup.flatMap(g => g.files);
    const sel = all.filter(f => st.dupSel.has(f.path));
    body.innerHTML = head + `${st.dupMsg ? `<div class="listhead">${st.dupMsg}</div>` : ''}
      <div class="muted listhead">${st.dup.length} groups · ${fmt(st.dup.reduce((s, g) => s + g.waste, 0))} in extra copies</div>
      <div class="applist">${st.dup.map((g, gi) => `<div class="dupgroup"><div class="name" style="margin:8px 4px 2px">${fmt(g.size)} × ${g.files.length}</div>` +
        g.files.map(f => `<label class="approw ${st.dupSel.has(f.path) ? 'sel' : ''}">
          <div class="grow"><div class="name">${esc(f.name)}${warnIcon(f.warn)}</div><div class="path">${esc(f.path)} · ${when(f.modified)}</div></div>
          <button class="iconbtn" style="font-size:13px" data-reveal="${esc(f.path)}" title="Show in Explorer">↗</button>
          <input type="checkbox" data-p="${esc(f.path)}" data-g="${gi}" ${st.dupSel.has(f.path) ? 'checked' : ''}></label>`).join('') + '</div>').join('')
        || '<div class="muted">No duplicates found.</div>'}</div>
      <div class="bottombar"><span>${sel.length} selected · ${fmt(sel.reduce((s, f) => s + f.size, 0))}</span>
        <button class="btn" id="drm" ${sel.length ? '' : 'disabled'}>Move to Recycle Bin</button></div>`;
  }
  body.querySelector('#dfolder').onclick = async () => { const p = await PickFolder(); if (p) { st.dupRoot = p; render(el); } };
  body.querySelector('#dscan').onclick = async () => {
    st.dupBusy = true; st.dupMsg = ''; st.dupSel.clear();
    const off = scanning(body, 'Comparing files…');
    try {
      st.dup = (await FindDuplicates([st.dupRoot || await HomeDir()], 1024)) || [];
      // keep the oldest copy, select the rest
      st.dup.forEach(g => g.files.slice(1).forEach(f => st.dupSel.add(f.path)));
    } catch (e) { st.dupMsg = `<span class="bad">${esc(e)}</span>`; }
    off(); st.dupBusy = false;
    if (onThisTab() && sub === 'dup') render(el);
  };
  body.querySelectorAll('[data-reveal]').forEach(b => b.onclick = ev => { ev.preventDefault(); Reveal(b.dataset.reveal); });
  body.querySelectorAll('input[data-p]').forEach(cb => cb.onchange = () => {
    const g = st.dup[+cb.dataset.g];
    if (cb.checked && g.files.every(f => f.path === cb.dataset.p || st.dupSel.has(f.path))) {
      cb.checked = false;                       // never select every copy
      st.dupMsg = '<span class="warntext">⚠ At least one copy in each group is kept.</span>';
    } else if (cb.checked) st.dupSel.add(cb.dataset.p);
    else st.dupSel.delete(cb.dataset.p);
    render(el);
  });
  body.querySelector('#drm')?.addEventListener('click', async () => {
    const sel = st.dup.flatMap(g => g.files).filter(f => st.dupSel.has(f.path));
    if (!(await confirmBox(`Move ${sel.length} files to the Recycle Bin?`, `${fmt(sel.reduce((s, f) => s + f.size, 0))} of extra copies. One copy of each file is kept.`, 'Move to Recycle Bin'))) return;
    try {
      await RecycleFiles(sel.map(f => f.path));
      st.dup = st.dup.map(g => ({...g, files: g.files.filter(f => !st.dupSel.has(f.path))})).filter(g => g.files.length > 1);
      st.dupMsg = `<span class="ok">Moved ${sel.length} files to the Recycle Bin.</span>`;
      st.dupSel.clear();
    } catch (e) { st.dupMsg = `<span class="bad">${esc(e)}</span>`; }
    render(el);
  });
}
