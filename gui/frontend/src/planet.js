// Slowly rotating planets, one per tab: real surface maps wrapped on a
// lit sphere, drawn pixel by pixel on a canvas.
// Textures: Solar System Scope (https://www.solarsystemscope.com/textures/),
// CC BY 4.0, based on NASA data.

import earthUrl from './assets/planets/2k_earth_daymap.jpg';
import cloudsUrl from './assets/planets/2k_earth_clouds.jpg';
import marsUrl from './assets/planets/2k_mars.jpg';
import mercuryUrl from './assets/planets/2k_mercury.jpg';
import jupiterUrl from './assets/planets/2k_jupiter.jpg';
import neptuneUrl from './assets/planets/2k_neptune.jpg';
import moonUrl from './assets/planets/2k_moon.jpg';

const TEX_W = 1024, TEX_H = 512;

const PLANETS = {
  earth:   {url: earthUrl, clouds: cloudsUrl, glow: [120, 180, 255], tilt: 0.41},
  mars:    {url: marsUrl, glow: [255, 150, 110], tilt: 0.44},
  mercury: {url: mercuryUrl, glow: [200, 200, 210], tilt: 0.05},
  jupiter: {url: jupiterUrl, glow: [255, 205, 160], tilt: 0.05},
  neptune: {url: neptuneUrl, glow: [110, 160, 255], tilt: 0.49},
  moon:    {url: moonUrl, glow: [200, 210, 225], tilt: 0.1},
};

export const PLANET_FOR_TAB = {clean: 'earth', space: 'neptune', apps: 'mars', optimize: 'mercury', analyze: 'jupiter', status: 'neptune', recover: 'moon'};

const cache = {};
function loadTexture(url) {
  if (!cache[url]) {
    cache[url] = new Promise((resolve, reject) => {
      const img = new Image();
      img.onload = () => {
        const c = document.createElement('canvas');
        c.width = TEX_W; c.height = TEX_H;
        const g = c.getContext('2d');
        g.drawImage(img, 0, 0, TEX_W, TEX_H);
        resolve(g.getImageData(0, 0, TEX_W, TEX_H).data); // RGBA
      };
      img.onerror = reject;
      img.src = url;
    });
  }
  return cache[url];
}

export function planetCanvas(name, size = 220) {
  const pl = PLANETS[name] || PLANETS.moon;
  const dpr = Math.min(window.devicePixelRatio || 1, 2);
  const pad = 0.18;                                  // room for the atmosphere halo
  const full = Math.round(size * (1 + pad * 2));
  const W = Math.round(full * dpr), R = (size * dpr) / 2, C = W / 2;
  const canvas = document.createElement('canvas');
  canvas.width = canvas.height = W;
  canvas.style.width = canvas.style.height = full + 'px';
  canvas.style.margin = `${-size * pad}px`;
  canvas.className = 'planet';
  const ctx = canvas.getContext('2d');

  // Per-pixel geometry, computed once.
  const n = W * W;
  const row = new Int32Array(n).fill(-1), col = new Float32Array(n), light = new Float32Array(n);
  const ct = Math.cos(pl.tilt * 0.6), st = Math.sin(pl.tilt * 0.6);
  const L = [-0.62, 0.3, 0.72];                      // sun from the upper left
  const ll = Math.hypot(...L);
  for (let py = 0; py < W; py++) {
    for (let px = 0; px < W; px++) {
      const dx = (px - C + 0.5) / R, dy = (C - py - 0.5) / R, d2 = dx * dx + dy * dy;
      if (d2 > 1) continue;
      const k = py * W + px, dz = Math.sqrt(1 - d2);
      const y = dy * ct + dz * st, z = -dy * st + dz * ct;     // tilt the axis
      const lat = Math.asin(Math.max(-1, Math.min(1, y)));
      row[k] = Math.min(TEX_H - 1, Math.floor((0.5 - lat / Math.PI) * TEX_H)) * TEX_W;
      col[k] = ((Math.atan2(z, dx) / (Math.PI * 2)) + 1) * TEX_W;
      const lambert = (dx * L[0] + dy * L[1] + dz * L[2]) / ll;
      // soft terminator, faint night side, darker limb
      const day = Math.max(0, Math.min(1, lambert * 1.6 + 0.35));
      light[k] = (0.05 + 1.05 * day * day) * (1 - Math.pow(1 - dz, 4) * 0.35);
    }
  }

  const img = ctx.createImageData(W, W);
  const [gr, gg, gb] = pl.glow;
  const drawGlow = () => {
    ctx.globalCompositeOperation = 'destination-over';
    const halo = ctx.createRadialGradient(C, C, R * 0.98, C, C, R * (1 + pad * 0.9));
    halo.addColorStop(0, `rgba(${gr},${gg},${gb},0.16)`);
    halo.addColorStop(1, `rgba(${gr},${gg},${gb},0)`);
    ctx.fillStyle = halo;
    ctx.beginPath(); ctx.arc(C, C, R * (1 + pad * 0.9), 0, Math.PI * 2); ctx.fill();
    ctx.globalCompositeOperation = 'source-over';
    const rim = ctx.createRadialGradient(C - R * 0.35, C - R * 0.2, R * 0.8, C, C, R);
    rim.addColorStop(0, `rgba(${gr},${gg},${gb},0)`);
    rim.addColorStop(1, `rgba(${gr},${gg},${gb},0.18)`);
    ctx.fillStyle = rim;
    ctx.beginPath(); ctx.arc(C, C, R, 0, Math.PI * 2); ctx.fill();
  };

  Promise.all([loadTexture(pl.url), pl.clouds ? loadTexture(pl.clouds) : null]).then(([tex, clouds]) => {
    let offset = Math.random() * TEX_W, cloudOffset = offset, last = performance.now();
    const frame = now => {
      if (!canvas.isConnected) return;               // stop when the page changes
      const dt = Math.min(64, now - last); last = now;
      const speed = canvas.dataset.fast ? 5 : 1;
      offset = (offset + dt * 0.012 * speed) % TEX_W;
      cloudOffset = (cloudOffset + dt * 0.016 * speed) % TEX_W;
      const out = img.data;
      for (let k = 0, o = 0; k < n; k++, o += 4) {
        const r = row[k];
        if (r < 0) { out[o + 3] = 0; continue; }
        const t = (r + (Math.floor(col[k] + offset) % TEX_W)) * 4, l = light[k];
        let cr = tex[t], cg = tex[t + 1], cb = tex[t + 2];
        if (clouds) {
          const a = clouds[(r + (Math.floor(col[k] + cloudOffset) % TEX_W)) * 4] / 255;
          cr += (255 - cr) * a; cg += (255 - cg) * a; cb += (255 - cb) * a;
        }
        out[o] = cr * l; out[o + 1] = cg * l; out[o + 2] = cb * l; out[o + 3] = 255;
      }
      ctx.putImageData(img, 0, 0);
      drawGlow();
      requestAnimationFrame(frame);
    };
    requestAnimationFrame(frame);
  }).catch(() => { /* texture failed: leave the halo-less canvas empty */ });
  return canvas;
}

// Replace every .orb placeholder under root with the current tab's planet.
export function mountPlanets(root, tab) {
  root.querySelectorAll('.orb:not([data-planet])').forEach(orb => {
    orb.dataset.planet = '1';
    const c = planetCanvas(PLANET_FOR_TAB[tab] || 'moon', 220);
    if (orb.classList.contains('spin')) c.dataset.fast = '1';
    orb.replaceWith(c);
  });
}
