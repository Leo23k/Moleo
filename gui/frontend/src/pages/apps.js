import {AppIcons, ListApps, UninstallApps, ListUpdates, UpdateApp, ListStartup, SetStartup, OpenBackups} from '../../wailsjs/go/main/App';
import {fmt, esc, confirmBox, hero, warnIcon} from '../util.js';

let sub = 'uninstall';

// Components other apps or Windows depend on.
const DEPENDENCY_RULES = [
  [/visual c\+\+.*redistributable|vcredist|\.net (runtime|desktop runtime|framework)|asp\.net core|windows desktop runtime|webview2|directx|java\(tm\)|java .*runtime|openjdk|python launcher|microsoft (ui xaml|vclibs|.net native)/i,
    'Shared runtime: other apps may stop working without it.'],
  [/driver|chipset|realtek|rtkaud|igfx|nvdisplay|nvbackend|intel\(r\)|nvidia (graphics|physx|hd audio|frameview)|amd (software|chipset)|synaptics|elan|bluetooth|thunderbolt|dolby|waves maxx/i,
    'Driver or hardware software: a device may stop working.'],
  [/security|securityhealth|antivirus|defender|vanguard|easy ?anti-?cheat|battleye/i,
    'Security or anti-cheat software: games or protection may stop working.'],
  [/microsoft edge$|microsoft edge update|windows sdk|windows software development kit|microsoft update health|windows pc health/i,
    'Part of Windows or its tools: Windows may reinstall or need it.'],
];
const appWarning = name => (DEPENDENCY_RULES.find(([re]) => re.test(name)) || [])[1] || '';
const state = {
  apps: null, sel: new Set(), q: '', sort: 'size', busy: '',
  updates: null, updating: new Map(),
  startup: null, startupErr: '',
};

let icons = null;      // lowercase name -> base64 PNG
let iconsLoading = false;
function loadIcons(el) {
  if (icons || iconsLoading) return;
  iconsLoading = true;
  AppIcons(false).then(m => { icons = m || {}; if (document.querySelector('.topnav button.active')?.dataset.page === 'apps') render(el); })
    .catch(() => { icons = {}; }).finally(() => { iconsLoading = false; });
}
function findIcon(name) {
  if (!icons) return null;
  const k = name.trim().toLowerCase();
  if (icons[k]) return icons[k];
  // "Cursor (User)", "Antigravity 2.28.2": try without version/suffix.
  const short = k.replace(/\s*\(.*?\)\s*$/, '').replace(/\s+v?\d[\d.]*$/, '');
  if (icons[short]) return icons[short];
  const hit = Object.keys(icons).find(n => n.startsWith(short + ' ') || short.startsWith(n + ' '));
  return hit ? icons[hit] : null;
}

const tile = name => {
  const img = findIcon(name);
  if (img) return `<img class="appicon" src="data:image/png;base64,${img}" alt="">`;
  const h = [...name].reduce((s, c) => (s * 31 + c.charCodeAt(0)) >>> 0, 7) % 360;
  return `<div class="apptile" style="background:hsl(${h} 35% 32%)">${esc((name.trim()[0] || '?').toUpperCase())}</div>`;
};

export function render(el) {
  el.innerHTML = `<div class="apps">
    <div class="subnav">
      ${['uninstall', 'updates', 'startup'].map(s => `<button data-sub="${s}" class="${s === sub ? 'active' : ''}">${s[0].toUpperCase() + s.slice(1)}</button>`).join('')}
      <button class="iconbtn" id="reload" title="Refresh">⟳</button>
      <div class="grow"></div><div id="tools"></div>
    </div>
    <div id="body" class="appsbody"></div></div>`;
  el.querySelectorAll('[data-sub]').forEach(b => b.onclick = () => { sub = b.dataset.sub; render(el); });
  el.querySelector('#reload').onclick = () => {
    if (state.busy) return;
    if (sub === 'uninstall') state.apps = null;
    if (sub === 'updates') state.updates = null;
    if (sub === 'startup') state.startup = null;
    render(el);
  };
  const body = el.querySelector('#body');
  loadIcons(el);
  ({uninstall: drawUninstall, updates: drawUpdates, startup: drawStartup})[sub](body, el);
}

const loading = (body, text) => hero(body, {orb: '#b37a6f', line: text, spin: true});

// ---- Uninstall -------------------------------------------------------

async function drawUninstall(body, el) {
  if (state.busy) return loading(body, state.busy);
  if (!state.apps) {
    loading(body, 'Reading installed apps…');
    try { state.apps = (await ListApps()) || []; } catch (e) { return hero(body, {orb: '#b36f6f', line: 'Could not list apps: ' + esc(e)}); }
    if (sub === 'uninstall') render(el);
    return;
  }
  const tools = el.querySelector('#tools');
  tools.innerHTML = `<span class="sorts">${[['name', 'Name'], ['size', 'App size']].map(([k, t]) =>
    `<a data-sort="${k}" class="${state.sort === k ? 'on' : ''}">${t}${state.sort === k && k === 'size' ? ' ↓' : ''}</a>`).join('')}</span>
    <input id="q" placeholder="Search" value="${esc(state.q)}">`;
  tools.querySelectorAll('[data-sort]').forEach(a => a.onclick = () => { state.sort = a.dataset.sort; render(el); });
  const q = tools.querySelector('#q');
  q.oninput = () => { state.q = q.value; drawList(); };

  const drawList = () => {
    const ql = state.q.toLowerCase();
    let list = state.apps.filter(a => !ql || a.Name.toLowerCase().includes(ql) || (a.Publisher || '').toLowerCase().includes(ql));
    list = list.sort(state.sort === 'size' ? (a, b) => b.SizeKB - a.SizeKB : (a, b) => a.Name.localeCompare(b.Name));
    const total = state.apps.reduce((s, a) => s + a.SizeKB * 1024, 0);
    body.innerHTML = `<div class="muted listhead">Installed Apps · ${state.apps.length} apps · ${fmt(total)}</div>
      <div class="applist">${list.map(a => `<label class="approw ${state.sel.has(a.Id) ? 'sel' : ''}">
        ${tile(a.Name)}<div class="grow"><div class="name">${esc(a.Name)}${warnIcon(appWarning(a.Name))}</div>
        <div class="path">${esc([a.Version, a.SizeKB ? fmt(a.SizeKB * 1024) : '', a.Source === 'WindowsStore' ? 'Store app' : ''].filter(Boolean).join(' · '))}</div></div>
        <input type="checkbox" data-id="${esc(a.Id)}" ${state.sel.has(a.Id) ? 'checked' : ''}></label>`).join('')}</div>
      <div class="bottombar"><span id="selinfo"></span><a id="clear" class="link">Clear selection</a><button class="btn" id="remove"></button></div>`;
    body.querySelectorAll('.approw input').forEach(cb => cb.onchange = () => {
      cb.checked ? state.sel.add(cb.dataset.id) : state.sel.delete(cb.dataset.id);
      cb.closest('.approw').classList.toggle('sel', cb.checked); bar();
    });
    body.querySelector('#clear').onclick = () => { state.sel.clear(); drawList(); };
    bar();
  };
  const bar = () => {
    const sel = state.apps.filter(a => state.sel.has(a.Id));
    body.querySelector('#selinfo').textContent = `${sel.length} apps · ${fmt(sel.reduce((s, a) => s + a.SizeKB * 1024, 0))}`;
    const btn = body.querySelector('#remove');
    btn.textContent = `Remove ${sel.length || ''}`.trim();
    btn.disabled = !sel.length;
    btn.onclick = () => doUninstall(sel, el);
  };
  drawList();
}

async function doUninstall(sel, el) {
  const ok = await confirmBox(`Remove ${sel.length} app${sel.length > 1 ? 's' : ''}?`,
    esc(sel.map(a => a.Name).join(', ')) + sel.filter(a => appWarning(a.Name)).map(a => `<br><br><span class="warntext">⚠ ${esc(a.Name)}: ${esc(appWarning(a.Name))}</span>`).join('') + '<br><br>Each uninstaller runs (some show their own window). Leftover files go to the Recycle Bin, and registry entries are backed up first.',
    'Remove');
  if (!ok) return;
  state.busy = `Removing ${sel.length} app${sel.length > 1 ? 's' : ''}… follow any uninstaller windows that open.`;
  render(el);
  let results = [], err = '';
  try { results = (await UninstallApps(sel.map(a => a.Id))) || []; } catch (e) { err = String(e); }
  state.busy = ''; state.sel.clear(); state.apps = null;
  const body = document.getElementById('body');
  if (sub !== 'uninstall' || !body) return;
  const rows = results.map(r => `<div class="item"><span class="${r.State === 'success' ? 'ok' : 'bad'}">${r.State === 'success' ? '✓' : '✕'}</span>
    <div class="grow"><div class="name">${esc(r.Name)}</div><div class="path">${esc(r.Details)}</div></div></div>`).join('');
  body.innerHTML = `<div class="result"><h2>${err ? 'Uninstall stopped' : 'Done'}</h2>${err ? `<div class="bad">${esc(err)}</div>` : ''}${rows}
    <button class="btn small" id="back">Back to apps</button></div>`;
  body.querySelector('#back').onclick = () => render(el);
}

// ---- Updates ---------------------------------------------------------

async function drawUpdates(body, el) {
  if (!state.updates) {
    loading(body, 'Checking for updates with winget…');
    try { state.updates = (await ListUpdates()) || []; } catch (e) { return hero(body, {orb: '#b36f6f', line: esc(e) + '<br>winget (App Installer) is required.'}); }
    if (sub === 'updates') render(el);
    return;
  }
  const list = state.updates;
  const pending = list.filter(u => !['done', 'running'].includes(state.updating.get(u.id)?.state));
  body.innerHTML = `<div class="muted listhead">${list.length} updates available</div>
    <div class="applist">${list.map(u => {
      const st = state.updating.get(u.id) || {};
      const right = st.state === 'running' ? '<span class="muted">Updating…</span>'
        : st.state === 'done' ? '<span class="ok">Updated ✓</span>'
        : `${st.state === 'error' ? `<span class="bad" title="${esc(st.msg)}">Failed</span>` : ''}<button class="btn ghost small" data-up="${esc(u.id)}">Update</button>`;
      return `<div class="approw">${tile(u.name)}<div class="grow"><div class="name">${esc(u.name)}</div>
        <div class="path">${esc(u.version)} → ${esc(u.available)} · ${esc(u.id)}</div></div>${right}</div>`;
    }).join('')}</div>
    <div class="bottombar"><span class="muted">Updates install silently through winget. An app that is open may be closed by its installer: save your work first.</span><button class="btn" id="upall" ${pending.length ? '' : 'disabled'}>Update all ${pending.length}</button></div>`;
  body.querySelectorAll('[data-up]').forEach(b => b.onclick = () => runUpdates([b.dataset.up], el));
  body.querySelector('#upall').onclick = () => runUpdates(pending.map(u => u.id), el);
}

async function runUpdates(ids, el) {
  for (const id of ids) state.updating.set(id, {state: 'queued'});
  for (const id of ids) {
    state.updating.set(id, {state: 'running'});
    if (sub === 'updates') render(el);
    try { await UpdateApp(id); state.updating.set(id, {state: 'done'}); }
    catch (e) { state.updating.set(id, {state: 'error', msg: String(e)}); }
  }
  if (sub === 'updates') render(el);
}

// ---- Startup ---------------------------------------------------------

async function drawStartup(body, el) {
  if (!state.startup) {
    try { state.startup = (await ListStartup()) || []; } catch (e) { return hero(body, {orb: '#b36f6f', line: esc(e)}); }
  }
  const on = state.startup.filter(s => s.enabled).length;
  body.innerHTML = `<div class="muted listhead">${state.startup.length} startup items · ${on} enabled
      · a backup is saved before every change · <a class="link" id="backups">Open backups</a></div>
    ${state.startupErr ? `<div class="bad listhead">${esc(state.startupErr)}</div>` : ''}
    <div class="applist">${state.startup.map(s => `<div class="approw">${tile(s.name)}
      <div class="grow"><div class="name">${esc(s.name)}${warnIcon(appWarning(s.name))}${s.needAdmin ? ' <span class="tag">All users</span>' : ''}</div>
      <div class="path" title="${esc(s.command)}">${esc(s.command)}</div></div>
      <label class="switch"><input type="checkbox" data-id="${s.id}" ${s.enabled ? 'checked' : ''}><span></span></label></div>`).join('')}</div>`;
  body.querySelector('#backups').onclick = () => OpenBackups();
  body.querySelectorAll('.switch input').forEach(cb => cb.onchange = async () => {
    state.startupErr = '';
    try { await SetStartup(cb.dataset.id, cb.checked); }
    catch (e) { state.startupErr = String(e); }
    state.startup = null;
    render(el);
  });
}
