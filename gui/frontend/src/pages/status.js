import {Status} from '../../wailsjs/go/main/App';
import {fmt, esc} from '../util.js';

const HISTORY = 60;
const hist = {cpu: [], mem: [], rx: [], tx: []};
let timer = null;
let last = null;

const onThisTab = () => document.querySelector('.topnav button.active')?.dataset.page === 'status';
const pct = v => Math.round(v) + '%';
const rate = v => fmt(v) + '/s';
const push = (a, v) => { a.push(v); if (a.length > HISTORY) a.shift(); };
const level = p => (p >= 90 ? 'bad' : p >= 70 ? 'warn' : '');

function uptime(s) {
  const d = Math.floor(s / 86400), h = Math.floor((s % 86400) / 3600), m = Math.floor((s % 3600) / 60);
  return (d ? d + 'd ' : '') + h + 'h ' + m + 'm';
}

// Line chart as inline SVG; series values in 0..max.
function spark(series, max, colors) {
  const w = 300, h = 60;
  const paths = series.map((s, k) => {
    if (s.length < 2) return '';
    const pts = s.map((v, i) => `${(i / (HISTORY - 1)) * w},${h - (Math.min(v, max) / max) * (h - 2) - 1}`);
    const offset = (HISTORY - s.length) / (HISTORY - 1) * w;
    const line = pts.map(p => { const [x, y] = p.split(','); return `${+x + offset},${y}`; }).join(' ');
    return `<polyline points="${line}" fill="none" stroke="${colors[k]}" stroke-width="1.6" vector-effect="non-scaling-stroke"/>`;
  }).join('');
  return `<svg class="spark" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none">${paths}</svg>`;
}

function card(title, value, sub, body, cls = '') {
  return `<div class="scard ${cls}"><div class="stitle">${title}</div>
    <div class="svalue">${value}</div><div class="ssub">${sub}</div>${body || ''}</div>`;
}

function procTable(list, key) {
  return `<div class="ptable">${(list || []).map(p => `<div class="prow"><span class="grow">${esc(p.name)}</span>
    <span class="size">${key === 'cpu' ? p.cpu.toFixed(1) + '%' : fmt(p.mem)}</span></div>`).join('')}</div>`;
}

function draw(el) {
  const s = last;
  if (!s) return;
  const memP = 100 * s.memUsed / s.memTotal;
  const maxNet = Math.max(64 * 1024, ...hist.rx, ...hist.tx) * 1.15;
  const cores = (s.perCore || []).map(v => `<div class="core" title="${pct(v)}"><div style="height:${Math.max(2, v)}%"></div></div>`).join('');
  el.innerHTML = `<div class="status">
    <div class="clean-head"><div><h1>${esc(s.host)}</h1>
      <div class="muted">${esc(s.os)} · ${esc(s.cpuModel)} · up ${uptime(s.uptime)}${s.battery >= 0 ? ` · battery ${s.battery}%${s.charging ? ' ⚡' : ''}` : ''}</div></div></div>
    <div class="sgrid">
      ${card('CPU', pct(s.cpu), `${s.cores} logical cores`, spark([hist.cpu], 100, ['#8fc1ff']) + `<div class="cores">${cores}</div>`, level(s.cpu))}
      ${card('Memory', pct(memP), `${fmt(s.memUsed)} of ${fmt(s.memTotal)}${s.swapTotal ? ` · page file ${fmt(s.swapUsed)}` : ''}`,
        spark([hist.mem], 100, ['#c99bff']), level(memP))}
      ${card('Network', `↓ ${rate(s.netRx)}`, `↑ ${rate(s.netTx)}`, spark([hist.rx, hist.tx], maxNet, ['#7fd69a', '#f0b86e']))}
      ${card('Disks', '', '', (s.drives || []).map(d => {
        const used = d.total - d.free, p = 100 * used / d.total;
        return `<div class="dk"><div class="dkrow"><b>${esc(d.path.slice(0, 2))}</b> <span class="muted">${esc(d.label)}</span>
          <span class="grow"></span><span class="size">${fmt(d.free)} free</span></div>
          <div class="bar ${level(p)}"><div style="width:${p.toFixed(1)}%"></div></div></div>`;
      }).join(''))}
      ${card('Top CPU', '', '', procTable(s.topCpu, 'cpu'))}
      ${card('Top memory', '', '', procTable(s.topMem, 'mem'))}
    </div></div>`;
}

async function tick(el) {
  if (!onThisTab()) { clearInterval(timer); timer = null; return; }
  try {
    last = await Status();
    push(hist.cpu, last.cpu);
    push(hist.mem, 100 * last.memUsed / last.memTotal);
    push(hist.rx, last.netRx);
    push(hist.tx, last.netTx);
    if (onThisTab()) draw(el);
  } catch (e) {
    el.innerHTML = `<div class="hero"><div class="muted">Could not read system status: ${esc(e)}</div></div>`;
  }
}

export function render(el) {
  if (last) draw(el);
  else el.innerHTML = '<div class="hero"><div class="orb spin" style="--orb:#6fb38a"></div><div class="muted">Reading system status…</div></div>';
  clearInterval(timer);
  tick(el);
  timer = setInterval(() => tick(el), 1500);
}
