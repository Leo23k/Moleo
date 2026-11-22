export function fmt(b) {
  if (!b) return '0 B';
  const u = ['B', 'KB', 'MB', 'GB', 'TB'];
  let i = 0;
  while (b >= 1000 && i < u.length - 1) { b /= 1000; i++; }
  return (i < 2 ? Math.round(b) : b.toFixed(b < 10 ? 2 : 1)) + ' ' + u[i];
}

const ESC = {'&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;'};
export const esc = s => String(s ?? '').replace(/[&<>"]/g, c => ESC[c]);

export function confirmBox(title, body, okText) {
  return new Promise(res => {
    const bg = document.createElement('div');
    bg.className = 'modal-bg';
    bg.innerHTML = `<div class="modal"><h2>${esc(title)}</h2><div class="muted">${body}</div>
      <div class="row"><button class="btn ghost small" data-v="0">Cancel</button>
      <button class="btn small" data-v="1">${esc(okText)}</button></div></div>`;
    bg.onclick = e => {
      const v = e.target.dataset && e.target.dataset.v;
      if (v !== undefined) { bg.remove(); res(v === '1'); }
    };
    document.body.appendChild(bg);
  });
}

export function hero(el, {orb, line, buttons = [], spin = false}) {
  el.innerHTML = `<div class="hero"><div class="orb ${spin ? 'spin' : ''}" style="--orb:${orb}"></div>
    <div class="muted hero-line">${line}</div><div class="hero-btns" style="display:flex;gap:12px"></div></div>`;
  const box = el.querySelector('.hero-btns');
  for (const b of buttons) {
    const btn = document.createElement('button');
    btn.className = 'btn' + (b.ghost ? ' ghost' : '');
    btn.textContent = b.text;
    btn.onclick = b.onClick;
    box.appendChild(btn);
  }
}

// ⚠ with an explanation on hover; empty when there is nothing to warn about.
export const warnIcon = text => (text ? `<span class="warnico" title="${esc(text)}">⚠</span>` : '');
