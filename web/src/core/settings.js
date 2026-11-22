// הגדרות שחקן – נשמרות ב-localStorage (עטוף ב-try/catch)
const DEFAULTS = {
  reduceScare: false, reduceFlash: false, bigSubs: false,
  master: 0.85, music: 0.7, sfx: 0.9, sens: 1.0, invertY: false, quality: 'auto',
  name: '', gender: 'm', skin: 2, hair: 0, hairColor: 0, outfit: 0,
  progress: 1,
};
const KEY = 'ad-hazricha-settings';
let data = { ...DEFAULTS };
try { Object.assign(data, JSON.parse(localStorage.getItem(KEY) || '{}')); } catch (e) { /* פרטיות / אין אחסון */ }
const listeners = new Set();

export const Settings = {
  get(k) { return data[k]; },
  set(k, v) {
    data[k] = v;
    try { localStorage.setItem(KEY, JSON.stringify(data)); } catch (e) { /* ignore */ }
    for (const l of listeners) l(k, v);
    applyBodyClasses();
  },
  all() { return { ...data }; },
  on(fn) { listeners.add(fn); return () => listeners.delete(fn); },
};

function applyBodyClasses() {
  if (typeof document === 'undefined') return;
  document.body.classList.toggle('big-subs', !!data.bigSubs);
  document.body.classList.toggle('reduce-flash', !!data.reduceFlash);
}
if (typeof document !== 'undefined') document.addEventListener('DOMContentLoaded', applyBodyClasses);
