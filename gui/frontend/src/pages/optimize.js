import {OptimizeCatalog, RunOptimizeTask, IsAdmin, RelaunchAsAdmin} from '../../wailsjs/go/main/App';
import {esc, hero} from '../util.js';

let tasks = null;
let chosen = null;
let results = new Map();   // id -> {State, Details} or {State:'running'}
let running = false;
let admin = false;
let choosing = false;

const ICON = {success: '✓', preview: '•', unavailable: '–', error: '✕', running: '…', queued: '·'};
const CLS = {success: 'ok', error: 'bad'};

export async function render(el) {
  if (!tasks) {
    hero(el, {orb: '#9a9a9a', line: 'Loading tasks…', spin: true});
    try {
      [tasks, admin] = await Promise.all([OptimizeCatalog(), IsAdmin()]);
    } catch (e) {
      return hero(el, {orb: '#b36f6f', line: 'Could not load Optimize tasks: ' + esc(e)});
    }
    chosen = new Set(tasks.filter(t => admin || !t.needsAdmin).map(t => t.Id));
    if (!onThisTab()) return;
  }
  if (results.size || choosing) return drawList(el);
  hero(el, {
    orb: '#9a9a9a',
    line: `Refresh DNS and network caches, optimize the drive, and check disk, update and system health.<br>
      <a class="link" id="choose">${chosen.size} of ${tasks.length} tasks</a>${admin ? '' : ' · some need administrator'}`,
    buttons: [
      ...(admin ? [] : [{text: 'Run as administrator', ghost: true, onClick: relaunch}]),
      {text: 'Optimize', onClick: () => runAll(el)},
    ],
  });
  el.querySelector('#choose').onclick = () => { choosing = true; render(el); };
}

const onThisTab = () => document.querySelector('.topnav button.active')?.dataset.page === 'optimize';

async function relaunch() {
  try { await RelaunchAsAdmin(); } catch (e) { /* user cancelled UAC */ }
}

function drawList(el) {
  el.innerHTML = `<div class="result" style="max-width:720px">
    <h2>${running ? 'Optimizing…' : results.size ? 'Optimize results' : 'Choose tasks'}</h2>
    ${tasks.map(t => {
      const r = results.get(t.Id);
      const st = r ? r.State : '';
      const left = r ? `<span class="${CLS[st] || 'muted'}" style="width:16px;text-align:center">${ICON[st] || '·'}</span>`
        : `<input type="checkbox" data-id="${t.Id}" ${chosen.has(t.Id) ? 'checked' : ''} ${running ? 'disabled' : ''}>`;
      const details = r && r.Details ? `<pre class="details">${esc(r.Details)}</pre>` : '';
      return `<div class="item" style="align-items:flex-start">${left}
        <div class="grow"><div class="name">${esc(t.Name)} ${t.Kind === 'Check' ? '<span class="tag">check</span>' : ''}
        ${t.needsAdmin && !admin ? '<span class="tag">admin</span>' : ''}</div>
        <div class="path" style="white-space:normal">${esc(t.Description)}</div>${details}</div></div>`;
    }).join('')}
    <div style="display:flex;gap:10px;margin-top:14px">
      ${running ? '' : results.size
        ? '<button class="btn small" id="again">Done</button>'
        : '<button class="btn ghost small" id="back">Back</button><button class="btn small" id="go">Optimize</button>'}
    </div></div>`;
  el.querySelectorAll('input[data-id]').forEach(cb => cb.onchange = () => {
    cb.checked ? chosen.add(cb.dataset.id) : chosen.delete(cb.dataset.id);
  });
  el.querySelector('#back')?.addEventListener('click', () => { choosing = false; render(el); });
  el.querySelector('#go')?.addEventListener('click', () => runAll(el));
  el.querySelector('#again')?.addEventListener('click', () => { results.clear(); choosing = false; render(el); });
}

async function runAll(el) {
  if (running || !chosen.size) return;
  running = true;
  choosing = false;
  results = new Map(tasks.filter(t => chosen.has(t.Id)).map(t => [t.Id, {State: 'queued'}]));
  for (const id of results.keys()) {
    results.set(id, {State: 'running'});
    if (onThisTab()) drawList(el);
    try { results.set(id, await RunOptimizeTask(id)); }
    catch (e) { results.set(id, {State: 'error', Details: String(e)}); }
  }
  running = false;
  if (onThisTab()) drawList(el);
}
