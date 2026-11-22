import './style.css';
import {startI18n} from './i18n.js';
import {mountPlanets} from './planet.js';
import * as clean from './pages/clean.js';
import * as apps from './pages/apps.js';
import * as analyze from './pages/analyze.js';
import * as optimize from './pages/optimize.js';
import * as recover from './pages/recover.js';
import * as status from './pages/status.js';
import * as space from './pages/space.js';

const pages = {clean, space, apps, optimize, analyze, recover, status};
const page = document.getElementById('page');
let current = 'clean';

function show(name) {
  current = name;
  document.body.dataset.tab = name;     // per-tab background tint
  document.querySelectorAll('.topnav button').forEach(b => b.classList.toggle('active', b.dataset.page === name));
  pages[name].render(page);
  mountPlanets(page, name);
}

// Pages draw a plain .orb placeholder; swap in the tab's planet whenever one appears.
new MutationObserver(() => mountPlanets(page, current)).observe(page, {childList: true, subtree: true});

document.querySelectorAll('.topnav button').forEach(b => b.addEventListener('click', () => show(b.dataset.page)));
show('clean');
startI18n();
