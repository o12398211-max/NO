// ═══════════════════════════════════════════════════════════════════
//  UI – שכבת DOM בעברית (RTL): כתוביות, דיאלוגים עם בחירות, הנחיות, כרטיסי פרק, מטרה, תפריטים
// ═══════════════════════════════════════════════════════════════════
import { T, NAMES, HUD, CHAPTERS } from '../config/texts.he.js';
import { Audio } from './audio.js';
import { Input } from './input.js';

const $ = (sel) => document.querySelector(sel);
function el(tag, cls, html) { const e = document.createElement(tag); if (cls) e.className = cls; if (html != null) e.innerHTML = html; return e; }
const esc = (s) => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const sleep = (ms) => new Promise(r => setTimeout(r, ms));

export const UI = {
  ctx: { name: '', gender: 'm' },
  init() {
    const hud = this.hud = el('div', '', ''); hud.id = 'hud'; document.body.appendChild(hud);
    hud.innerHTML = `
      <div id="crosshair"></div>
      <div id="prompt"><span class="key">E</span><span class="txt"></span></div>
      <div id="objective"><div class="lbl"></div><div class="txt"></div></div>
      <div id="subs"></div>
      <div id="dialog"></div>
      <div id="chapterCard"><div class="num"></div><div class="name"></div><div class="sub"></div></div>
      <div id="smallNote"></div>
      <div id="toast"></div>
      <canvas id="minimap" width="260" height="260"></canvas>
      <div id="fps"></div>`;
    this.subs = $('#subs'); this.promptEl = $('#prompt'); this.dialogEl = $('#dialog');
    this.objEl = $('#objective'); this.cardEl = $('#chapterCard'); this.noteEl = $('#smallNote');
    this.toastEl = $('#toast'); this.fpsEl = $('#fps'); this.minimap = $('#minimap');
    this.hidden = false; this.subQueue = Promise.resolve();
  },
  t(s) { return T(s, this.ctx); },
  setHidden(h) { this.hidden = h; this.hud.style.display = h ? 'none' : ''; },
  /** הנחיית אינטראקציה (E + טקסט). null = הסתרה */
  prompt(text, key = 'E') {
    if (!text) { this.promptEl.classList.remove('on'); return; }
    this.promptEl.querySelector('.txt').textContent = this.t(text);
    this.promptEl.querySelector('.key').textContent = key;
    this.promptEl.classList.add('on');
  },
  crosshair(on) { $('#crosshair').classList.toggle('on', !!on); },
  objective(text) {
    if (!text) { this.objEl.classList.remove('on'); return; }
    this.objEl.querySelector('.lbl').textContent = HUD.objective;
    this.objEl.querySelector('.txt').textContent = this.t(text);
    this.objEl.classList.remove('on'); void this.objEl.offsetWidth; this.objEl.classList.add('on');
    clearTimeout(this._objT); this._objT = setTimeout(() => this.objEl.classList.add('dim'), 7000);
    this.objEl.classList.remove('dim');
  },
  note(text) { // טקסט קטן ודיסקרטי (למשל "צריך לשירותים")
    if (!text) { this.noteEl.classList.remove('on'); return; }
    this.noteEl.textContent = this.t(text); this.noteEl.classList.add('on');
  },
  toast(text, ms = 2500) { this.toastEl.textContent = this.t(text); this.toastEl.classList.add('on'); clearTimeout(this._tt); this._tt = setTimeout(() => this.toastEl.classList.remove('on'), ms); },
  /** כתובית בודדת */
  async sub(who, text, ms) {
    const name = who ? (NAMES[who] ?? who) : '';
    const str = this.t(text);
    const dur = ms ?? Math.max(1800, 900 + str.length * 55);
    const line = el('div', 'line', (name ? `<span class="who">${esc(name)}</span>` : '') + `<span class="t">${esc(str)}</span>`);
    this.subs.appendChild(line);
    requestAnimationFrame(() => line.classList.add('on'));
    await sleep(dur);
    line.classList.remove('on'); setTimeout(() => line.remove(), 400);
  },
  /** כתובית ברקע (לא חוסמת) */
  bark(who, text, ms) { this.sub(who, text, ms); },
  /** שורות דיאלוג ברצף (עם דילוג ב-E/קליק) */
  async lines(lines, speakers = {}) {
    for (const [who, text] of lines) {
      const ch = speakers[who]; if (ch) ch.talking = true;
      const name = who ? (NAMES[who] ?? who) : '';
      const str = this.t(text);
      const box = el('div', 'line on big', (name ? `<span class="who">${esc(name)}</span>` : '') + `<span class="t">${esc(str)}</span><span class="next">E ›</span>`);
      this.subs.appendChild(box);
      Audio.play('click', { vol: 0.15 });
      const dur = Math.max(2200, 1000 + str.length * 60);
      await this._waitSkip(dur);
      if (ch) ch.talking = false;
      box.classList.remove('on'); setTimeout(() => box.remove(), 300);
      await sleep(120);
    }
  },
  _waitSkip(ms) {
    return new Promise(res => {
      const start = performance.now(); let done = false;
      const tick = () => { if (done) return; const el2 = performance.now() - start; if (el2 > ms || (el2 > 350 && (Input.pressed.has('KeyE') || Input.pressed.has('Space') || Input.mouse.clicked))) { done = true; res(); } else requestAnimationFrame(tick); };
      tick();
    });
  },
  /** בחירה מתוך אפשרויות – מחזיר אינדקס */
  choose(choices) {
    return new Promise(res => {
      const d = this.dialogEl; d.innerHTML = ''; d.classList.add('on');
      const wasLocked = Input.locked; Input.unlock();
      choices.forEach((c, i) => {
        const b = el('button', 'choice', `<span class="n">${i + 1}</span><span>${esc(this.t(c.text))}</span>`);
        b.onmouseenter = () => Audio.play('hover');
        b.onclick = () => finish(i);
        d.appendChild(b);
      });
      const onKey = (e) => { const n = parseInt(e.key, 10); if (n >= 1 && n <= choices.length) finish(n - 1); };
      addEventListener('keydown', onKey);
      const finish = (i) => { removeEventListener('keydown', onKey); Audio.play('click', { vol: 0.5 }); d.classList.remove('on'); setTimeout(() => (d.innerHTML = ''), 250); if (wasLocked) Input.lock(); res(i); };
    });
  },
  /** הרצת עץ שיחה מ-texts. onAct(act) לאירועים, מחזיר רשימת בחירות שנעשו */
  async dialog(tree, startId, speakers, onAct, onTrust) {
    let id = startId; const picked = [];
    while (id) {
      const node = tree[id]; if (!node) break;
      await this.lines(node.lines, speakers);
      if (node.choices) {
        const i = await this.choose(node.choices); const c = node.choices[i]; picked.push(i);
        if (c.trust && onTrust) onTrust(c.trust);
        if (c.act && onAct) await onAct(c.act);
        id = c.next;
      } else id = node.next || null;
    }
    return picked;
  },
  async chapterCard(n) {
    const c = CHAPTERS[n - 1]; if (!c) return;
    this.cardEl.querySelector('.num').textContent = `${HUD.chapter} ${['', 'ראשון', 'שני', 'שלישי', 'רביעי', 'חמישי', 'שישי'][n]}`;
    this.cardEl.querySelector('.name').textContent = c.name;
    this.cardEl.querySelector('.sub').textContent = c.sub;
    this.cardEl.classList.add('on'); await sleep(4200); this.cardEl.classList.remove('on'); await sleep(900);
  },
  showFps(on) { this.fpsEl.style.display = on ? 'block' : 'none'; },
  setFps(v) { if (this.fpsEl.style.display === 'block') this.fpsEl.textContent = Math.round(v) + ' FPS'; },
  clearSubs() { this.subs.innerHTML = ''; },
  sleep,
  el, esc,
};
