// ═══════════════════════════════════════════════════════════════════
//  Audio – סאונד דיזיין פרוצדורלי מלא (WebAudio). כל צליל ומוזיקה נוצרים בקוד = מקורי לחלוטין.
//  Buses: music / sfx / amb / voice → master. Reverb send (convolver) לפי מרחב. HRTF למיקום תלת־ממדי.
// ═══════════════════════════════════════════════════════════════════
import { Settings } from './settings.js';

let ctx = null;
const SR = () => ctx.sampleRate;
const buffers = {};
const rnd = (a = 0, b = 1) => a + Math.random() * (b - a);
const mtof = m => 440 * Math.pow(2, (m - 69) / 12);

function makeBuffer(seconds, fn, channels = 1) {
  const len = Math.max(1, Math.floor(seconds * SR()));
  const b = ctx.createBuffer(channels, len, SR());
  for (let c = 0; c < channels; c++) {
    const d = b.getChannelData(c);
    fn(d, len, SR(), c);
  }
  return b;
}
// פילטרים פשוטים בזמן יצירה
function onePoleLP(d, cutoff, sr) { const a = Math.exp(-2 * Math.PI * cutoff / sr); let y = 0; for (let i = 0; i < d.length; i++) { y = (1 - a) * d[i] + a * y; d[i] = y; } }
function onePoleHP(d, cutoff, sr) { const a = Math.exp(-2 * Math.PI * cutoff / sr); let y = 0, px = 0; for (let i = 0; i < d.length; i++) { const x = d[i]; y = a * (y + x - px); px = x; d[i] = y; } }
function bandpass(d, f, q, sr) { // biquad BP
  const w = 2 * Math.PI * f / sr, al = Math.sin(w) / (2 * q), cw = Math.cos(w);
  const b0 = al, b2 = -al, a0 = 1 + al, a1 = -2 * cw, a2 = 1 - al;
  let x1 = 0, x2 = 0, y1 = 0, y2 = 0;
  for (let i = 0; i < d.length; i++) { const x = d[i]; const y = (b0 * x + b2 * x2 - a1 * y1 - a2 * y2) / a0; x2 = x1; x1 = x; y2 = y1; y1 = y; d[i] = y; }
}
function normalize(d, peak = 0.9) { let m = 0; for (let i = 0; i < d.length; i++) m = Math.max(m, Math.abs(d[i])); if (m > 0) for (let i = 0; i < d.length; i++) d[i] *= peak / m; }

// ───────────── יצירת כל הבאפרים ─────────────
function genAll() {
  const B = buffers;
  // ירי קרוב: טרנזיינט חד + רעש דועך + "בום" נמוך
  for (let v = 0; v < 3; v++) B['shot' + v] = makeBuffer(0.9, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * (28 + v * 6)) + Math.sin(2 * Math.PI * (70 - t * 40) * t) * Math.exp(-t * 12) * 1.2 + (t < 0.004 ? (Math.random() * 2 - 1) * 2.5 : 0); }
    onePoleLP(d, 5200 - v * 600, sr); normalize(d, 0.95);
  });
  // ירי רחוק: מסונן, זנב ארוך (הד בעמק)
  for (let v = 0; v < 3; v++) B['shotFar' + v] = makeBuffer(2.2, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; const e = Math.exp(-t * 18) + 0.25 * Math.exp(-Math.max(0, t - 0.35 - v * 0.1) * 4) * (t > 0.35 + v * 0.1 ? 1 : 0); d[i] = (Math.random() * 2 - 1) * e; }
    onePoleLP(d, 900 + v * 200, sr); onePoleLP(d, 1400, sr); normalize(d, 0.8);
  });
  // ריקושט – "זינג"
  for (let v = 0; v < 3; v++) B['ricochet' + v] = makeBuffer(0.7, (d, n, sr) => {
    let ph = 0; const f0 = rnd(2200, 3400), f1 = rnd(500, 900);
    for (let i = 0; i < n; i++) { const t = i / sr; const f = f0 + (f1 - f0) * Math.min(1, t / 0.6); ph += 2 * Math.PI * f / sr; d[i] = Math.sin(ph) * Math.exp(-t * 5) * 0.6 + (t < 0.02 ? (Math.random() * 2 - 1) * (1 - t / 0.02) : 0); }
    normalize(d, 0.7);
  });
  // פגיעה בעפר/קיר
  for (let v = 0; v < 3; v++) B['impact' + v] = makeBuffer(0.35, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * 30); }
    onePoleLP(d, 2500, sr); normalize(d, 0.8);
  });
  B.crack = makeBuffer(0.12, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * 90); } onePoleHP(d, 1500, sr); normalize(d, 0.9); });
  // פיצוץ / יירוט רחוק
  B.boom = makeBuffer(3.5, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * (Math.exp(-t * 1.6) * (1 - Math.exp(-t * 60))) + Math.sin(2 * Math.PI * (45 - t * 8) * t) * Math.exp(-t * 2.5); }
    onePoleLP(d, 380, sr); onePoleLP(d, 500, sr); normalize(d, 0.95);
  });
  B.boomFar = makeBuffer(4, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * 1.2) * (1 - Math.exp(-t * 20)); }
    onePoleLP(d, 180, sr); onePoleLP(d, 220, sr); normalize(d, 0.9);
  });
  // פוטסטפים לפי משטח (4 וריאציות לכל אחד)
  const surf = {
    dirt: { len: 0.22, lp: 1800, hp: 200, clicks: 6, decay: 26 },
    gravel: { len: 0.28, lp: 4200, hp: 500, clicks: 26, decay: 20 },
    asphalt: { len: 0.16, lp: 2600, hp: 120, clicks: 2, decay: 40 },
    concrete: { len: 0.18, lp: 3400, hp: 250, clicks: 3, decay: 42 },
    water: { len: 0.4, lp: 2200, hp: 300, clicks: 0, decay: 9, splash: true },
    carpet: { len: 0.14, lp: 700, hp: 60, clicks: 0, decay: 45 },
    metal: { len: 0.35, lp: 6000, hp: 300, clicks: 1, decay: 22, ring: 640 },
    grass: { len: 0.25, lp: 3000, hp: 700, clicks: 12, decay: 18 },
  };
  for (const s in surf) for (let v = 0; v < 4; v++) {
    const p = surf[s];
    B['step_' + s + v] = makeBuffer(p.len, (d, n, sr) => {
      for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * p.decay) * 0.5 + Math.sin(2 * Math.PI * 80 * t) * Math.exp(-t * 60) * 0.6; }
      for (let c = 0; c < p.clicks; c++) { const at = Math.floor(rnd(0, n * 0.7)); const amp = rnd(0.3, 1); for (let k = 0; k < 120 && at + k < n; k++) d[at + k] += (Math.random() * 2 - 1) * amp * Math.exp(-k / 25); }
      if (p.splash) for (let i = 0; i < n; i++) { const t = i / sr; d[i] += Math.sin(2 * Math.PI * (300 + 900 * t) * t) * Math.exp(-t * 10) * 0.3 * Math.random(); }
      if (p.ring) for (let i = 0; i < n; i++) { const t = i / sr; d[i] += Math.sin(2 * Math.PI * (p.ring + v * 40) * t) * Math.exp(-t * 14) * 0.25; }
      onePoleHP(d, p.hp, sr); onePoleLP(d, p.lp + v * 200, sr); normalize(d, 0.7);
    });
  }
  // לב (לאב-דאב)
  B.heart = makeBuffer(0.6, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; const a = Math.sin(2 * Math.PI * (58 - t * 30) * t) * Math.exp(-t * 22); const t2 = t - 0.2; const b = t2 > 0 ? Math.sin(2 * Math.PI * (50 - t2 * 30) * t2) * Math.exp(-t2 * 26) * 0.7 : 0; d[i] = a + b; }
    normalize(d, 0.95);
  });
  // נשימות (שאיפה/נשיפה), 3 וריאציות
  for (let v = 0; v < 3; v++) {
    B['breathIn' + v] = makeBuffer(0.75, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / n; d[i] = (Math.random() * 2 - 1) * Math.sin(Math.PI * t) ** 1.5; } bandpass(d, 1500 + v * 250, 0.8, sr); normalize(d, 0.5); });
    B['breathOut' + v] = makeBuffer(0.7, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / n; d[i] = (Math.random() * 2 - 1) * Math.pow(1 - t, 1.4) * Math.min(1, t * 12); } bandpass(d, 900 + v * 200, 0.7, sr); normalize(d, 0.55); });
  }
  B.ring = makeBuffer(2, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 3900 * t) * 0.3 + Math.sin(2 * Math.PI * 4130 * t) * 0.12; } });
  // אגרוף / מכה
  B.punch = makeBuffer(0.5, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * (95 - t * 120) * t) * Math.exp(-t * 14) * 1.4 + (Math.random() * 2 - 1) * Math.exp(-t * 50) * 0.8; } onePoleLP(d, 2200, sr); normalize(d, 1); });
  // סטינגר ג'אמפסקייר: אשכול דיסוננטי + רעש + בום
  B.stinger = makeBuffer(2.4, (d, n, sr) => {
    const fr = [233, 247, 311, 349, 466, 523, 698, 740];
    for (let i = 0; i < n; i++) { const t = i / sr; let s = 0; for (let k = 0; k < fr.length; k++) s += ((t * fr[k] * (1 + 0.004 * k)) % 1) * 2 - 1; s /= fr.length; const env = Math.min(1, t * 400) * Math.exp(-t * 1.6); d[i] = s * env * 1.1 + (Math.random() * 2 - 1) * Math.exp(-t * 9) * 0.9 + Math.sin(2 * Math.PI * 38 * t) * Math.exp(-t * 2.2) * 1.2; }
    onePoleLP(d, 7000, sr); normalize(d, 1);
  });
  // שבירת זכוכית
  B.glass = makeBuffer(1.4, (d, n, sr) => {
    for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * Math.exp(-t * 14) * 0.6; }
    for (let c = 0; c < 90; c++) { const at = Math.floor(Math.pow(Math.random(), 2) * n * 0.9); const f = rnd(2500, 9000); const a = rnd(0.2, 0.8) * (1 - at / n); for (let k = 0; k < 2500 && at + k < n; k++) d[at + k] += Math.sin(2 * Math.PI * f * k / sr) * a * Math.exp(-k / (sr * 0.02)); }
    onePoleHP(d, 1500, sr); normalize(d, 0.95);
  });
  // טפטוף
  for (let v = 0; v < 3; v++) B['drip' + v] = makeBuffer(0.3, (d, n, sr) => { let ph = 0; const f0 = rnd(700, 1300); for (let i = 0; i < n; i++) { const t = i / sr; ph += 2 * Math.PI * (f0 + 2200 * t) / sr; d[i] = Math.sin(ph) * Math.exp(-t * 26); } normalize(d, 0.5); });
  // דפיקה (קוד טפיחות): בטון/מתכת
  B.knock = makeBuffer(0.25, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 190 * t) * Math.exp(-t * 35) + (Math.random() * 2 - 1) * Math.exp(-t * 120) * 0.6; } onePoleLP(d, 1800, sr); normalize(d, 0.9); });
  B.pipe = makeBuffer(1.2, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.sin(2 * Math.PI * 523 * t) + 0.5 * Math.sin(2 * Math.PI * 1310 * t) + 0.25 * Math.sin(2 * Math.PI * 2790 * t)) * Math.exp(-t * 4) + (Math.random() * 2 - 1) * Math.exp(-t * 200) * 0.5; } normalize(d, 0.8); });
  B.clank = makeBuffer(0.6, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.sin(2 * Math.PI * 410 * t) + Math.sin(2 * Math.PI * 1033 * t) * 0.6 + Math.sin(2 * Math.PI * 1870 * t) * 0.3) * Math.exp(-t * 9) + (Math.random() * 2 - 1) * Math.exp(-t * 80); } normalize(d, 0.8); });
  B.creak = makeBuffer(1.5, (d, n, sr) => { let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const f = 90 + 40 * Math.sin(t * 7) + 20 * Math.sin(t * 23); ph += 2 * Math.PI * f / sr; d[i] = (((ph / (2 * Math.PI)) % 1) * 2 - 1) * Math.sin(Math.PI * t / 1.5) * (0.5 + 0.5 * Math.random()); } bandpass(d, 700, 2, sr); normalize(d, 0.6); });
  B.rustle = makeBuffer(0.8, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / n; d[i] = (Math.random() * 2 - 1) * Math.sin(Math.PI * t) * (0.4 + 0.6 * Math.random()); } onePoleHP(d, 1200, sr); onePoleLP(d, 6000, sr); normalize(d, 0.6); });
  B.cloth = makeBuffer(0.5, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / n; d[i] = (Math.random() * 2 - 1) * Math.sin(Math.PI * t); } bandpass(d, 2500, 0.6, sr); normalize(d, 0.4); });
  B.zip = makeBuffer(0.7, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * (0.5 + 0.5 * Math.sin(2 * Math.PI * 70 * t)) * Math.sin(Math.PI * t / 0.7); } bandpass(d, 3500, 1.2, sr); normalize(d, 0.5); });
  B.shutter = makeBuffer(0.25, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * (Math.exp(-t * 80) + (t > 0.09 ? Math.exp(-(t - 0.09) * 90) : 0)); } onePoleHP(d, 800, sr); normalize(d, 0.6); });
  B.click = makeBuffer(0.05, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 1800 * t) * Math.exp(-t * 160); } normalize(d, 0.35); });
  B.hover = makeBuffer(0.06, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 2600 * t) * Math.exp(-t * 200); } normalize(d, 0.15); });
  B.swoosh = makeBuffer(0.9, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / n; d[i] = (Math.random() * 2 - 1) * Math.sin(Math.PI * t) ** 2; } bandpass(d, 900, 0.5, sr); normalize(d, 0.6); });
  B.thud = makeBuffer(0.6, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * (60 - t * 30) * t) * Math.exp(-t * 9) + (Math.random() * 2 - 1) * Math.exp(-t * 40) * 0.4; } onePoleLP(d, 600, sr); normalize(d, 0.9); });
  B.djembeLow = makeBuffer(0.5, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * (110 - 30 * t) * t) * Math.exp(-t * 9) + (Math.random() * 2 - 1) * Math.exp(-t * 70) * 0.3; } normalize(d, 0.9); });
  B.djembeSlap = makeBuffer(0.3, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 420 * t) * Math.exp(-t * 25) * 0.6 + (Math.random() * 2 - 1) * Math.exp(-t * 45); } onePoleHP(d, 300, sr); normalize(d, 0.85); });
  B.ding = makeBuffer(2.0, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 988 * t) * Math.exp(-t * 2.5) * (t < 0.6 ? 1 : 0.4) + (t > 0.6 ? Math.sin(2 * Math.PI * 784 * (t - 0.6)) * Math.exp(-(t - 0.6) * 2.5) : 0); } normalize(d, 0.5); });
  B.beep = makeBuffer(0.18, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 1750 * t) * (t < 0.14 ? 1 : Math.exp(-(t - 0.14) * 80)); } normalize(d, 0.4); });
  B.chuteOpen = makeBuffer(1.6, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * (t < 0.35 ? t / 0.35 : Math.exp(-(t - 0.35) * 3)) + (t > 0.35 && t < 0.42 ? (Math.random() * 2 - 1) * 2 : 0); } onePoleLP(d, 1600, sr); normalize(d, 0.95); });
  B.pistol = makeBuffer(1.2, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.random() * 2 - 1) * (Math.exp(-t * 40) + 0.2 * Math.exp(-t * 5)) + Math.sin(2 * Math.PI * (120 - 80 * t) * t) * Math.exp(-t * 18) + (t < 0.003 ? 3 * (Math.random() * 2 - 1) : 0); } onePoleLP(d, 6000, sr); normalize(d, 1); });
  B.doorSlam = makeBuffer(0.8, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = Math.sin(2 * Math.PI * 75 * t) * Math.exp(-t * 10) + (Math.random() * 2 - 1) * Math.exp(-t * 30) * 0.7 + Math.sin(2 * Math.PI * 340 * t) * Math.exp(-t * 18) * 0.3; } onePoleLP(d, 2500, sr); normalize(d, 0.9); });
  B.latch = makeBuffer(0.2, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.sin(2 * Math.PI * 2100 * t) * 0.5 + (Math.random() * 2 - 1)) * Math.exp(-t * 70); } normalize(d, 0.6); });
  B.bird = makeBuffer(0.5, (d, n, sr) => { let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const seg = Math.floor(t * 10) % 3; const f = 3200 + seg * 600 + Math.sin(t * 90) * 400; ph += 2 * Math.PI * f / sr; d[i] = Math.sin(ph) * Math.sin(Math.PI * ((t * 10) % 1)) * Math.exp(-t * 2); } normalize(d, 0.35); });
  B.dog = makeBuffer(0.4, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; const e = t < 0.18 ? Math.sin(Math.PI * t / 0.18) : 0; d[i] = ((((t * (380 - 400 * t)) % 1) * 2 - 1) * 0.6 + (Math.random() * 2 - 1) * 0.5) * e; } bandpass(d, 800, 1.2, sr); normalize(d, 0.6); });
  B.shoutFar = makeBuffer(1.2, (d, n, sr) => { let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const f = 260 + 80 * Math.sin(t * 5) + 30 * Math.sin(t * 31); ph += 2 * Math.PI * f / sr; d[i] = ((ph / (2 * Math.PI)) % 1 * 2 - 1) * Math.sin(Math.PI * t / 1.2) * (0.7 + 0.3 * Math.random()); } bandpass(d, 900, 1.5, sr); bandpass(d, 1200, 1, sr); normalize(d, 0.6); });
  B.crowdPanic = makeBuffer(4, (d, n, sr, c) => {
    for (let k = 0; k < 14; k++) { const st = Math.floor(rnd(0, n * 0.8)); const ln = Math.floor(rnd(0.4, 1.4) * sr); let ph = 0; const f0 = rnd(220, 520); for (let i = 0; i < ln && st + i < n; i++) { const t = i / sr; ph += 2 * Math.PI * (f0 + 60 * Math.sin(t * 6 + k)) / sr; d[st + i] += ((ph / (2 * Math.PI)) % 1 * 2 - 1) * Math.sin(Math.PI * i / ln) * 0.3; } }
    for (let i = 0; i < n; i++) d[i] += (Math.random() * 2 - 1) * 0.15;
    bandpass(d, 1000, 0.7, sr); normalize(d, 0.6);
  }, 2);
  B.whistle = makeBuffer(1.8, (d, n, sr) => { const notes = [76, 79, 81, 79, 76]; let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const k = Math.min(notes.length - 1, Math.floor(t / 0.34)); const f = mtof(notes[k]) * (1 + 0.012 * Math.sin(t * 34)); ph += 2 * Math.PI * f / sr; const lt = (t % 0.34) / 0.34; d[i] = Math.sin(ph) * Math.min(1, lt * 8) * (1 - lt * 0.3) + (Math.random() * 2 - 1) * 0.02; } normalize(d, 0.35); });
  B.engineStart = makeBuffer(1.2, (d, n, sr) => { let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const f = t < 0.6 ? 18 + 8 * Math.sin(t * 60) : 30 + 20 * (t - 0.6); ph += 2 * Math.PI * f / sr; d[i] = (((ph / (2 * Math.PI)) % 1) * 2 - 1) * 0.7 + (Math.random() * 2 - 1) * 0.2; } onePoleLP(d, 700, sr); normalize(d, 0.7); });
  // לופים של אמביינט (stereo, 6 שניות, נטען בלולאה)
  B.windLoop = makeBuffer(6, (d, n, sr, c) => { for (let i = 0; i < n; i++) d[i] = Math.random() * 2 - 1; onePoleLP(d, 500, sr); onePoleLP(d, 700, sr); for (let i = 0; i < n; i++) { const t = i / sr; d[i] *= 0.6 + 0.4 * Math.sin(2 * Math.PI * t / 6 + c); } normalize(d, 0.6); }, 2);
  B.roarLoop = makeBuffer(4, (d, n, sr, c) => { for (let i = 0; i < n; i++) d[i] = Math.random() * 2 - 1; onePoleLP(d, 1800, sr); for (let i = 0; i < n; i++) { const t = i / sr; d[i] *= 0.8 + 0.2 * Math.sin(2 * Math.PI * t * 1.5 + c * 2); } normalize(d, 0.8); }, 2);
  B.cricketLoop = makeBuffer(6, (d, n, sr, c) => {
    for (let k = 0; k < 9; k++) { const f = rnd(4200, 5600); const rate = rnd(14, 22); const off = rnd(0, 6); for (let i = 0; i < n; i++) { const t = i / sr; const g = Math.sin(2 * Math.PI * rate * t) > 0.3 && ((t + off) % 1.8) < 0.9 ? 1 : 0; d[i] += Math.sin(2 * Math.PI * f * t) * g * 0.05; } }
    onePoleLP(d, 7000, sr);
  }, 2);
  B.cabinLoop = makeBuffer(6, (d, n, sr, c) => { let b = 0; for (let i = 0; i < n; i++) { b = (b + 0.02 * (Math.random() * 2 - 1)) / 1.02; const t = i / sr; d[i] = b * 3 + Math.sin(2 * Math.PI * 118 * t) * 0.05 + Math.sin(2 * Math.PI * 236 * t) * 0.02; } onePoleLP(d, 900, sr); normalize(d, 0.7); }, 2);
  B.tunnelLoop = makeBuffer(6, (d, n, sr, c) => { let b = 0; for (let i = 0; i < n; i++) { b = (b + 0.02 * (Math.random() * 2 - 1)) / 1.02; const t = i / sr; d[i] = b * 2 + Math.sin(2 * Math.PI * 50 * t) * 0.03 + Math.sin(2 * Math.PI * 100 * t + c) * 0.015; } onePoleLP(d, 300, sr); normalize(d, 0.5); }, 2);
  B.crowdLoop = makeBuffer(6, (d, n, sr, c) => {
    for (let k = 0; k < 40; k++) { const st = Math.floor(rnd(0, n)); const ln = Math.floor(rnd(0.2, 0.7) * sr); let ph = 0; const f0 = rnd(140, 320); for (let i = 0; i < ln; i++) { const idx = (st + i) % n; const t = i / sr; ph += 2 * Math.PI * (f0 + 30 * Math.sin(t * 9 + k)) / sr; d[idx] += ((ph / (2 * Math.PI)) % 1 * 2 - 1) * Math.sin(Math.PI * i / ln) * 0.12; } }
    bandpass(d, 700, 0.6, sr); normalize(d, 0.5);
  }, 2);
  B.sirenLoop = makeBuffer(8, (d, n, sr) => { // אזעקה עולה ויורדת
    let ph = 0; for (let i = 0; i < n; i++) { const t = i / sr; const f = 420 + 380 * (0.5 - 0.5 * Math.cos(2 * Math.PI * t / 8)); ph += 2 * Math.PI * f / sr; const s = Math.sin(ph); d[i] = Math.tanh(s * 2.2) * 0.8 + Math.sin(ph * 2) * 0.1; }
    onePoleLP(d, 2600, sr); normalize(d, 0.75);
  });
  B.heliLoop = makeBuffer(2, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; const p = (t * 5.5) % 1; d[i] = (Math.random() * 2 - 1) * Math.exp(-p * 9) * 0.9 + Math.sin(2 * Math.PI * 22 * t) * 0.2; } onePoleLP(d, 600, sr); normalize(d, 0.7); });
  B.crackleLoop = makeBuffer(5, (d, n, sr) => { for (let c = 0; c < 200; c++) { const at = Math.floor(Math.random() * n); const a = rnd(0.1, 1); for (let k = 0; k < 300 && at + k < n; k++) d[at + k] += (Math.random() * 2 - 1) * a * Math.exp(-k / 40); } for (let i = 0; i < n; i++) d[i] += (Math.random() * 2 - 1) * 0.05; onePoleLP(d, 3000, sr); normalize(d, 0.5); });
}

// Karplus-Strong (גיטרה אקוסטית) – מטמון לפי תו
const ksCache = {};
function pluck(midi, dur = 2.6, bright = 0.5) {
  const key = midi + '_' + bright;
  if (ksCache[key]) return ksCache[key];
  const f = mtof(midi);
  const b = makeBuffer(dur, (d, n, sr) => {
    const p = Math.floor(sr / f); const buf = new Float32Array(p);
    for (let i = 0; i < p; i++) buf[i] = (Math.random() * 2 - 1);
    let last = 0;
    for (let i = 0; i < n; i++) { const idx = i % p; const nx = (idx + 1) % p; const v = (buf[idx] * (0.5 + bright * 0.5) + buf[nx] * (0.5 - bright * 0.5)) * 0.996; d[i] = buf[idx]; buf[idx] = v * 0.5 + last * 0.5 + (v - last) * bright * 0.2; last = v; }
    normalize(d, 0.6);
  });
  ksCache[key] = b; return b;
}
// "פסנתר" רך – חיבור הרמוניות
const pianoCache = {};
function piano(midi) {
  if (pianoCache[midi]) return pianoCache[midi];
  const f = mtof(midi);
  pianoCache[midi] = makeBuffer(3.5, (d, n, sr) => { for (let i = 0; i < n; i++) { const t = i / sr; d[i] = (Math.sin(2 * Math.PI * f * t) + 0.45 * Math.sin(4 * Math.PI * f * t) * Math.exp(-t * 2) + 0.2 * Math.sin(6 * Math.PI * f * t) * Math.exp(-t * 3)) * Math.exp(-t * 1.1) * Math.min(1, t * 300); } normalize(d, 0.5); });
  return pianoCache[midi];
}

function impulse(seconds, decay) {
  return makeBuffer(seconds, (d, n, sr) => { for (let i = 0; i < n; i++) d[i] = (Math.random() * 2 - 1) * Math.pow(1 - i / n, decay); }, 2);
}

// ═════════════ מנהל אודיו ═════════════
export const Audio = {
  ready: false,
  init() {
    if (ctx) { if (ctx.state === 'suspended') ctx.resume(); return; }
    ctx = new (window.AudioContext || window.webkitAudioContext)();
    this.ctx = ctx;
    this.master = ctx.createGain();
    this.comp = ctx.createDynamicsCompressor(); this.comp.threshold.value = -10; this.comp.ratio.value = 4;
    this.master.connect(this.comp).connect(ctx.destination);
    this.buses = {};
    for (const b of ['music', 'sfx', 'amb', 'voice']) { const g = ctx.createGain(); g.connect(this.master); this.buses[b] = g; }
    // Reverb
    this.reverb = ctx.createConvolver();
    this.reverbGain = ctx.createGain(); this.reverbGain.gain.value = 0.25;
    this.reverb.connect(this.reverbGain).connect(this.master);
    this.impulses = { open: impulse(2.6, 3.5), tunnel: impulse(3.2, 2.2), cabin: impulse(0.6, 4), small: impulse(0.4, 5), field: impulse(4.5, 4) };
    this.reverb.buffer = this.impulses.open;
    // Muffle (טשטוש שמיעה אחרי פיצוץ/בהתעלפות)
    this.muffle = ctx.createBiquadFilter(); this.muffle.type = 'lowpass'; this.muffle.frequency.value = 20000;
    this.master.disconnect(); this.master.connect(this.muffle).connect(this.comp);
    genAll();
    this.applyVolumes();
    Settings.on(() => this.applyVolumes());
    this.ready = true;
    Music.init();
    Body.init();
  },
  applyVolumes() {
    if (!ctx) return;
    this.master.gain.value = Settings.get('master');
    this.buses.music.gain.value = Settings.get('music');
    this.buses.sfx.gain.value = Settings.get('sfx');
    this.buses.amb.gain.value = Settings.get('sfx') * 0.9;
    this.buses.voice.gain.value = 1;
  },
  now() { return ctx ? ctx.currentTime : 0; },
  setSpace(name, wet) {
    if (!ctx) return;
    this.reverb.buffer = this.impulses[name] || this.impulses.open;
    this.reverbGain.gain.setTargetAtTime(wet ?? ({ open: 0.2, tunnel: 0.55, cabin: 0.15, small: 0.2, field: 0.3 }[name] || 0.2), ctx.currentTime, 0.5);
  },
  setMuffle(amount, time = 0.3) { // 0 = רגיל, 1 = עמום מאוד
    if (!ctx) return;
    this.muffle.frequency.setTargetAtTime(20000 * Math.pow(0.012, amount), ctx.currentTime, time);
  },
  setListener(pos, fwd, up) {
    if (!ctx) return;
    const L = ctx.listener;
    if (L.positionX) {
      const t = ctx.currentTime;
      L.positionX.setTargetAtTime(pos.x, t, 0.02); L.positionY.setTargetAtTime(pos.y, t, 0.02); L.positionZ.setTargetAtTime(pos.z, t, 0.02);
      L.forwardX.setTargetAtTime(fwd.x, t, 0.02); L.forwardY.setTargetAtTime(fwd.y, t, 0.02); L.forwardZ.setTargetAtTime(fwd.z, t, 0.02);
      L.upX.setTargetAtTime(up.x, t, 0.02); L.upY.setTargetAtTime(up.y, t, 0.02); L.upZ.setTargetAtTime(up.z, t, 0.02);
    } else { L.setPosition(pos.x, pos.y, pos.z); L.setOrientation(fwd.x, fwd.y, fwd.z, up.x, up.y, up.z); }
  },
  _panner(pos, ref = 3, rolloff = 1, max = 400) {
    const p = ctx.createPanner();
    p.panningModel = 'HRTF'; p.distanceModel = 'inverse'; p.refDistance = ref; p.rolloffFactor = rolloff; p.maxDistance = max;
    if (p.positionX) { p.positionX.value = pos.x; p.positionY.value = pos.y; p.positionZ.value = pos.z; } else p.setPosition(pos.x, pos.y, pos.z);
    return p;
  },
  /** צליל חד־פעמי. name יכול להיות בסיס עם וריאציות (shot → shot0..2) */
  play(name, o = {}) {
    if (!ctx) return null;
    let buf = buffers[name];
    if (!buf) { const vars = []; for (let i = 0; i < 4; i++) if (buffers[name + i]) vars.push(buffers[name + i]); if (vars.length) buf = vars[Math.floor(Math.random() * vars.length)]; }
    if (o.buffer) buf = o.buffer;
    if (!buf) return null;
    const src = ctx.createBufferSource(); src.buffer = buf;
    src.playbackRate.value = (o.rate || 1) * (o.vary ? rnd(1 - o.vary, 1 + o.vary) : 1);
    const g = ctx.createGain(); g.gain.value = o.vol ?? 1;
    let node = src.connect(g);
    if (o.lp) { const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = o.lp; node = node.connect(f); }
    if (o.pos) { const p = this._panner(o.pos, o.ref || 3, o.rolloff ?? 1); node = node.connect(p); }
    node.connect(this.buses[o.bus || 'sfx']);
    if (o.reverb !== 0) { const s = ctx.createGain(); s.gain.value = o.reverb ?? 0.5; node.connect(s).connect(this.reverb); }
    src.start(ctx.currentTime + (o.delay || 0));
    return src;
  },
  /** לופ מתמשך עם שליטה */
  loop(name, o = {}) {
    if (!ctx) return { setVol() {}, setPos() {}, setRate() {}, stop() {} };
    const src = ctx.createBufferSource(); src.buffer = o.buffer || buffers[name]; src.loop = true;
    src.playbackRate.value = o.rate || 1;
    const g = ctx.createGain(); g.gain.value = 0;
    let node = src.connect(g); let pan = null; let filt = null;
    if (o.lp) { filt = ctx.createBiquadFilter(); filt.type = 'lowpass'; filt.frequency.value = o.lp; node = node.connect(filt); }
    if (o.pos) { pan = this._panner(o.pos, o.ref || 4, o.rolloff ?? 1); node = node.connect(pan); }
    node.connect(this.buses[o.bus || 'amb']);
    if (o.reverb) { const s = ctx.createGain(); s.gain.value = o.reverb; node.connect(s).connect(this.reverb); }
    src.start(ctx.currentTime, Math.random() * (src.buffer.duration || 1));
    g.gain.setTargetAtTime(o.vol ?? 1, ctx.currentTime, o.fade ?? 0.5);
    return {
      src, gain: g,
      setVol(v, t = 0.3) { g.gain.setTargetAtTime(v, ctx.currentTime, t); },
      setRate(r) { src.playbackRate.setTargetAtTime(r, ctx.currentTime, 0.1); },
      setLP(f) { if (filt) filt.frequency.setTargetAtTime(f, ctx.currentTime, 0.1); },
      setPos(p) { if (pan && pan.positionX) { pan.positionX.value = p.x; pan.positionY.value = p.y; pan.positionZ.value = p.z; } },
      stop(t = 0.5) { g.gain.setTargetAtTime(0, ctx.currentTime, t); setTimeout(() => { try { src.stop(); } catch (e) {} }, t * 5000 + 100); },
    };
  },
  /** מנוע רכב – מתנד חי */
  engine(pos) {
    if (!ctx) return { set() {}, stop() {}, setPos() {} };
    const o1 = ctx.createOscillator(); o1.type = 'sawtooth';
    const o2 = ctx.createOscillator(); o2.type = 'square';
    const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = 500; f.Q.value = 3;
    const g = ctx.createGain(); g.gain.value = 0;
    o1.connect(f); o2.connect(f); f.connect(g);
    let out = g; let pan = null;
    if (pos) { pan = this._panner(pos, 4, 1); g.connect(pan); out = pan; }
    out.connect(this.buses.sfx);
    o1.start(); o2.start();
    return {
      set(rpm, load) { const t = ctx.currentTime; const fr = 28 + rpm * 90; o1.frequency.setTargetAtTime(fr, t, 0.05); o2.frequency.setTargetAtTime(fr * 0.5, t, 0.05); f.frequency.setTargetAtTime(300 + rpm * 1400 + load * 400, t, 0.05); g.gain.setTargetAtTime(0.08 + load * 0.12, t, 0.08); },
      setPos(p) { if (pan && pan.positionX) { pan.positionX.value = p.x; pan.positionY.value = p.y; pan.positionZ.value = p.z; } },
      stop() { g.gain.setTargetAtTime(0, ctx.currentTime, 0.2); setTimeout(() => { try { o1.stop(); o2.stop(); } catch (e) {} }, 1500); },
    };
  },
  pluck, piano, mtof,
  footstep(surface, intensity = 1, pos) {
    this.play('step_' + (surface || 'dirt'), { vol: 0.25 + 0.45 * intensity, vary: 0.08, pos, reverb: 0.25 });
  },
  /** ירי – קרוב או רחוק לפי מרחק מהמאזין */
  gunshot(pos, listenerPos, opts = {}) {
    const dist = listenerPos ? Math.hypot(pos.x - listenerPos.x, pos.z - listenerPos.z) : 50;
    const scared = Settings.get('reduceScare');
    if (dist < 35) {
      this.play('shot', { pos, vol: (scared ? 0.55 : 1) * (opts.vol ?? 1), vary: 0.06, ref: 6, rolloff: 0.8, reverb: 0.8 });
      if (dist < 12) this.play('crack', { vol: scared ? 0.3 : 0.6, reverb: 0.2 });
    } else this.play('shotFar', { pos, vol: (opts.vol ?? 1) * 0.9, vary: 0.1, ref: 30, rolloff: 0.4, reverb: 1.0 });
  },
  burst(pos, listenerPos, count = 5, gap = 0.09, o = {}) {
    for (let i = 0; i < count; i++) setTimeout(() => this.gunshot(pos, listenerPos, o), (i * gap + Math.random() * gap * 0.4) * 1000);
  },
};

// ═════════════ גוף: נשימה, דופק, צלצול ═════════════
export const Body = {
  breath: 0, heartBpm: 70, heartVol: 0, ringAmt: 0, _nb: 0, _nh: 0, _phase: 0,
  init() { this.ringLoop = Audio.loop('ring', { vol: 0, bus: 'sfx' }); },
  /** breath 0..1 עוצמת נשימה, heart 0..1 עוצמת דופק */
  update(dt, state) {
    if (!ctx) return;
    const t = ctx.currentTime;
    this.breath += ((state.breath ?? 0) - this.breath) * Math.min(1, dt * 2);
    const rate = 0.25 + this.breath * 0.65; // נשימות בשנייה
    if (t > this._nb) {
      const v = 0.05 + this.breath * 0.4;
      if (v > 0.07 || state.forceBreath) {
        const isIn = this._phase++ % 2 === 0;
        Audio.play(isIn ? 'breathIn' : 'breathOut', { vol: v, rate: 0.9 + this.breath * 0.3, bus: 'voice', reverb: 0.1 });
      }
      this._nb = t + (1 / rate) * 0.5 * rnd(0.85, 1.15);
    }
    const hv = state.heart ?? 0; this.heartVol += (hv - this.heartVol) * Math.min(1, dt * 1.5);
    this.heartBpm = 70 + this.heartVol * 85;
    if (this.heartVol > 0.05 && t > this._nh) { Audio.play('heart', { vol: this.heartVol * 0.8, bus: 'voice', reverb: 0 }); this._nh = t + 60 / this.heartBpm; }
    this.ringAmt = Math.max(0, this.ringAmt - dt * 0.12);
    if (this.ringLoop) this.ringLoop.setVol(this.ringAmt * 0.18 * (Settings.get('reduceScare') ? 0.5 : 1), 0.1);
  },
  ring(amount = 1) { this.ringAmt = Math.min(1, this.ringAmt + amount); },
};

// ═════════════ מוזיקה דינמית ═════════════
// מצבים: silence, party (טראנס פסיכדלי מקורי), tension (שכבות מתח 0..1), tunnel, plane, hope (גיטרה), theme (נושא של שחר), memorial
const THEME = [[64, 1], [69, 1], [71, 1], [72, 2], [71, 1], [69, 1], [67, 2], [64, 2], [62, 1], [64, 1], [67, 1], [69, 3], [0, 1]]; // הנושא של "עד הזריחה"
export const THEME_NOTES = THEME;
const CHORDS = { Am: [57, 60, 64, 69], F: [53, 57, 60, 65], C: [48, 55, 60, 64], G: [55, 59, 62, 67], Em: [52, 55, 59, 64], Dm: [50, 57, 62, 65] };

export const Music = {
  mode: 'silence', intensity: 0, bpm: 142, nextTime: 0, step: 0, out: null,
  init() {
    this.out = ctx.createGain(); this.out.gain.value = 1;
    this.direct = ctx.createGain(); this.direct.gain.value = 1;
    this.out.connect(this.direct).connect(Audio.buses.music);
    this.diegetic = ctx.createGain(); this.diegetic.gain.value = 0;
    this.dpan = Audio._panner({ x: 0, y: 4, z: 0 }, 18, 0.6, 600);
    this.out.connect(this.diegetic).connect(this.dpan).connect(Audio.buses.music);
    this.delay = ctx.createDelay(1); this.delay.delayTime.value = 60 / 142 * 0.75;
    this.fb = ctx.createGain(); this.fb.gain.value = 0.35;
    this.delayOut = ctx.createGain(); this.delayOut.gain.value = 0.3;
    this.delay.connect(this.fb).connect(this.delay); this.delay.connect(this.delayOut).connect(this.out);
    // שכבות מתח (דרונים מתמשכים)
    this.layers = {};
    const mk = (type, freq, lp, det = 0) => { const o = ctx.createOscillator(); o.type = type; o.frequency.value = freq; o.detune.value = det; const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.frequency.value = lp; const g = ctx.createGain(); g.gain.value = 0; o.connect(f).connect(g).connect(this.out); o.start(); return { o, f, g }; };
    this.layers.drone1 = mk('sawtooth', 36.7, 180, -8);
    this.layers.drone2 = mk('sawtooth', 36.7, 160, 9);
    this.layers.high = mk('triangle', 587, 1200, 0);
    this.layers.high2 = mk('triangle', 622, 1200, 0); // מינור שני – אי נוחות
    const n = ctx.createBufferSource(); n.buffer = buffers.windLoop; n.loop = true; const nf = ctx.createBiquadFilter(); nf.type = 'bandpass'; nf.frequency.value = 400; nf.Q.value = 0.7; const ng = ctx.createGain(); ng.gain.value = 0; n.connect(nf).connect(ng).connect(this.out); n.start(); this.layers.air = { g: ng, f: nf };
    this._tick = this._tick.bind(this);
    setInterval(this._tick, 25);
  },
  setDiegetic(on, pos) {
    if (!ctx) return;
    const t = ctx.currentTime;
    this.diegetic.gain.setTargetAtTime(on ? 1 : 0, t, 0.5);
    this.direct.gain.setTargetAtTime(on ? 0.12 : 1, t, 0.5);
    if (pos && this.dpan.positionX) { this.dpan.positionX.value = pos.x; this.dpan.positionY.value = pos.y; this.dpan.positionZ.value = pos.z; }
  },
  set(mode, intensity = this.intensity) {
    if (!ctx) { this.mode = mode; return; }
    if (mode !== this.mode) { this.mode = mode; this.step = 0; this.nextTime = ctx.currentTime + 0.05; if (mode === 'theme' || mode === 'hope' || mode === 'memorial') this.themePos = 0; }
    this.intensity = intensity;
    this.bpm = mode === 'party' ? 142 : mode === 'hope' || mode === 'theme' ? 84 : mode === 'memorial' ? 66 : 70;
    this.delay.delayTime.setTargetAtTime(60 / this.bpm * 0.75, ctx.currentTime, 0.1);
    this._layers();
  },
  setIntensity(v) { this.intensity = v; this._layers(); },
  _layers() {
    const t = ctx.currentTime, L = this.layers, i = this.intensity;
    const tens = this.mode === 'tension' || this.mode === 'tunnel' || this.mode === 'plane';
    const base = tens ? 1 : 0;
    L.drone1.g.gain.setTargetAtTime(base * (0.05 + 0.07 * i), t, 1.2);
    L.drone2.g.gain.setTargetAtTime(base * (0.05 + 0.07 * i), t, 1.2);
    L.drone1.f.frequency.setTargetAtTime(140 + 500 * i, t, 1);
    L.drone2.f.frequency.setTargetAtTime(120 + 450 * i, t, 1);
    L.high.g.gain.setTargetAtTime(base * Math.max(0, i - 0.3) * 0.02, t, 1.5);
    L.high2.g.gain.setTargetAtTime(base * Math.max(0, i - 0.55) * 0.025, t, 1.5);
    L.air.g.gain.setTargetAtTime((tens ? 0.08 + 0.15 * i : 0) + (this.mode === 'memorial' ? 0.03 : 0), t, 1.5);
    L.air.f.frequency.setTargetAtTime(this.mode === 'tunnel' ? 220 : 500 + i * 800, t, 1);
    const droneHz = this.mode === 'plane' ? 41.2 : this.mode === 'tunnel' ? 32.7 : 36.7;
    L.drone1.o.frequency.setTargetAtTime(droneHz, t, 2); L.drone2.o.frequency.setTargetAtTime(droneHz, t, 2);
  },
  _note(buf, time, vol, rate = 1, toDelay = 0) {
    const s = ctx.createBufferSource(); s.buffer = buf; s.playbackRate.value = rate;
    const g = ctx.createGain(); g.gain.value = vol; s.connect(g).connect(this.out);
    if (toDelay) { const d = ctx.createGain(); d.gain.value = toDelay; g.connect(d).connect(this.delay); }
    s.start(time);
  },
  _synth(time, freq, dur, vol, type = 'sawtooth', lp = 1200, attack = 0.005, toDelay = 0, lpEnv = 0) {
    const o = ctx.createOscillator(); o.type = type; o.frequency.value = freq;
    const f = ctx.createBiquadFilter(); f.type = 'lowpass'; f.Q.value = 6;
    f.frequency.setValueAtTime(lp + lpEnv, time); f.frequency.exponentialRampToValueAtTime(Math.max(60, lp), time + dur);
    const g = ctx.createGain(); g.gain.setValueAtTime(0, time); g.gain.linearRampToValueAtTime(vol, time + attack); g.gain.exponentialRampToValueAtTime(0.0005, time + dur);
    o.connect(f).connect(g).connect(this.out);
    if (toDelay) { const d = ctx.createGain(); d.gain.value = toDelay; g.connect(d).connect(this.delay); }
    o.start(time); o.stop(time + dur + 0.05);
  },
  _kick(time, vol = 0.9) {
    const o = ctx.createOscillator(); const g = ctx.createGain();
    o.frequency.setValueAtTime(150, time); o.frequency.exponentialRampToValueAtTime(42, time + 0.12);
    g.gain.setValueAtTime(vol, time); g.gain.exponentialRampToValueAtTime(0.001, time + 0.38);
    o.connect(g).connect(this.out); o.start(time); o.stop(time + 0.4);
  },
  _hat(time, vol = 0.1, open = false) {
    const s = ctx.createBufferSource(); s.buffer = buffers.crack; const f = ctx.createBiquadFilter(); f.type = 'highpass'; f.frequency.value = 7000;
    const g = ctx.createGain(); g.gain.setValueAtTime(vol, time); g.gain.exponentialRampToValueAtTime(0.001, time + (open ? 0.2 : 0.05));
    s.connect(f).connect(g).connect(this.out); s.start(time);
  },
  _tick() {
    if (!ctx || this.mode === 'silence') return;
    const look = 0.12;
    while (this.nextTime < ctx.currentTime + look) { this._schedule(this.nextTime, this.step); this.nextTime += 60 / this.bpm / 4; this.step++; }
  },
  _schedule(t, s) {
    const m = this.mode, i = this.intensity;
    const bar = Math.floor(s / 16), st = s % 16;
    if (m === 'party') {
      // טראנס פסיכדלי מקורי, 142BPM, F# מינור
      const sect = Math.floor(bar / 8) % 4; // build / drop / break / drop
      const breakdown = sect === 2;
      if (st % 4 === 0 && !breakdown) this._kick(t, 0.85);
      if (st % 4 !== 0 && !breakdown) { const root = [42, 42, 42, 45, 42, 42, 40, 42][bar % 8]; this._synth(t, mtof(root), 0.09, 0.16, 'sawtooth', 220, 0.003, 0, 900); }
      if (st % 4 === 2) this._hat(t, 0.08, true);
      if (st % 2 === 1 && sect !== 0) this._hat(t, 0.035);
      if ((st === 4 || st === 12) && !breakdown) { const s2 = ctx.createBufferSource(); s2.buffer = buffers.shutter; const g = ctx.createGain(); g.gain.value = 0.12; s2.connect(g).connect(this.out); s2.start(t); }
      const arp = [66, 69, 73, 76, 73, 69, 78, 73];
      if (sect !== 0 || bar % 2 === 1) if (st % 2 === 0) this._synth(t, mtof(arp[(s / 2) % 8 | 0] + (bar % 4 === 3 ? 2 : 0)), 0.16, breakdown ? 0.05 : 0.035, 'square', 1800 + 1200 * Math.sin(s * 0.05), 0.002, 0.6, 2200);
      if (st === 0 && bar % 2 === 0) { for (const n of [54, 57, 61]) this._synth(t, mtof(n), 60 / this.bpm * 8, breakdown ? 0.035 : 0.018, 'sawtooth', 900, 0.8, 0.2); }
      return;
    }
    if (m === 'tension' || m === 'tunnel' || m === 'plane') {
      // פולס נמוך שמאיץ עם העוצמה
      const every = i > 0.75 ? 4 : i > 0.45 ? 8 : 16;
      if (st % every === 0 && i > 0.2) this._kick(t, 0.15 + i * 0.25);
      if (i > 0.8 && st % 2 === 0) this._hat(t, 0.02);
      if (st === 0 && bar % 4 === 0 && i > 0.3) this._synth(t, mtof(m === 'tunnel' ? 38 : 41), 4.5, 0.04 + i * 0.04, 'sawtooth', 300 + i * 600, 1.5);
      if (st === 8 && bar % 8 === 6 && i > 0.5) this._synth(t, mtof(75 + (bar % 3)), 3, 0.012, 'sine', 3000, 1.2, 0.5);
      return;
    }
    if (m === 'hope' || m === 'theme' || m === 'memorial') {
      // גיטרה אקוסטית (Karplus-Strong) + נושא בפסנתר
      const prog = m === 'memorial' ? ['Am', 'F', 'C', 'G', 'Am', 'Dm', 'Em', 'Am'] : ['Am', 'F', 'C', 'G'];
      const ch = CHORDS[prog[bar % prog.length]];
      const pattern = [0, 2, 1, 3, 2, 1, 3, 2];
      if (st % 2 === 0) this._note(pluck(ch[pattern[(st / 2) | 0]], 2.6, 0.35), t + Math.random() * 0.01, m === 'memorial' ? 0.32 : 0.42, 1, 0.1);
      if (st === 0) this._note(pluck(ch[0] - 12, 3, 0.2), t, 0.35);
      if ((m === 'theme' || (m === 'memorial' && bar >= 4)) && st % 4 === 0) {
        this._tp = this._tp ?? 0; this._tl = this._tl ?? 0;
        if (this._tl <= 0) { const [note, len] = THEME[this._tp % THEME.length]; if (note) this._note(piano(note), t, 0.4, 1, 0.25); this._tl = len; this._tp++; }
        this._tl--;
      }
    }
  },
  /** ניגון נושא בודד (עידו בפרק 3, שחר בפרק 1) */
  playTheme(startTime = 0, voice = 'piano', vol = 0.4, pos) {
    if (!ctx) return 0;
    let t = ctx.currentTime + startTime; const beat = 60 / 84;
    for (const [n, l] of THEME) { if (n) { const buf = voice === 'pluck' ? pluck(n, 2) : piano(n); Audio.play(null, { buffer: buf, vol, pos, delay: t - ctx.currentTime, bus: 'music', reverb: 0.4 }); } t += l * beat; }
    return t - ctx.currentTime;
  },
};
