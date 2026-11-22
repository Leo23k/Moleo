import './style.css';
import {startI18n} from './i18n.js';
import * as clean from './pages/clean.js';
import * as apps from './pages/apps.js';
import * as analyze from './pages/analyze.js';
import * as optimize from './pages/optimize.js';
import * as recover from './pages/recover.js';
import * as status from './pages/status.js';

const pages = {
  clean,
  apps,
  optimize,
  analyze,
  recover,
  status,
};

let show = function (name) {
  document.querySelectorAll('.topnav button').forEach(b => b.classList.toggle('active', b.dataset.page === name));
  pages[name].render(document.getElementById('page'));
};

document.querySelectorAll('.topnav button').forEach(b => b.addEventListener('click', () => show(b.dataset.page)));
let current = 'clean';
const _show = show;
show = n => { current = n; _show(n); };
show('clean');
startI18n();
