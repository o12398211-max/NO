// מיני־משחקים קצרים בפרק 1: קצב (די־ג'יי), מעגל תופים (זיכרון קצב), סלפי
import { Audio, Music } from '../core/audio.js';
import { Input } from '../core/input.js';
import { CH1 } from '../config/texts.he.js';
import { Settings } from '../core/settings.js';

const sleep = (ms) => new Promise(r => setTimeout(r, ms));
function overlay(html) { const o = document.createElement('div'); o.style.cssText = 'position:fixed;inset:0;z-index:30;display:flex;align-items:center;justify-content:center;pointer-events:none;opacity:0;transition:opacity .4s'; o.innerHTML = html; document.body.appendChild(o); requestAnimationFrame(() => (o.style.opacity = 1)); return o; }
async function close(o) { o.style.opacity = 0; await sleep(400); o.remove(); }

/** קצב: 4 מסלולים (D F J K), תווים נופלים על הביט של המוזיקה. מחזיר ניקוד 0..1 */
export async function djGame() {
  const keys = ['KeyD', 'KeyF', 'KeyJ', 'KeyK'], labels = ['D', 'F', 'J', 'K'], cols = ['#ff2e88', '#19e3ff', '#9b5bff', '#ffb347'];
  const W = 360, H = 460;
  const o = overlay(`<div style="text-align:center"><div style="font-family:var(--serif);font-size:30px;margin-bottom:6px">${CH1.djGame.title}</div><div style="color:var(--muted);font-size:13px;margin-bottom:10px">${CH1.djGame.hint}</div><canvas width="${W}" height="${H}" style="background:rgba(8,6,14,.72);border:1px solid rgba(255,255,255,.12);border-radius:16px;backdrop-filter:blur(8px)"></canvas><div class="fb" style="height:30px;font-size:20px;font-weight:700;margin-top:8px"></div></div>`);
  const cv = o.querySelector('canvas'), g = cv.getContext('2d'), fb = o.querySelector('.fb');
  const beat = 60 / Music.bpm; const notes = []; const dur = 22;
  let tt = 0; for (let b = 4; tt < dur; b++) { tt = b * beat; if (Math.random() < 0.7) notes.push({ t: tt, lane: Math.floor(Math.random() * 4), hit: false }); if (Math.random() < 0.15) notes.push({ t: tt + beat / 2, lane: Math.floor(Math.random() * 4), hit: false }); }
  let score = 0, total = notes.length, start = performance.now() / 1000, combo = 0;
  const hitY = H - 60, speed = 260;
  await new Promise(res => {
    const frame = () => {
      const now = performance.now() / 1000 - start;
      g.clearRect(0, 0, W, H);
      for (let l = 0; l < 4; l++) { g.fillStyle = 'rgba(255,255,255,0.03)'; g.fillRect(l * 90 + 5, 0, 80, H); g.strokeStyle = cols[l]; g.globalAlpha = Input.down(keys[l]) ? 1 : 0.4; g.lineWidth = 3; g.beginPath(); g.arc(l * 90 + 45, hitY, 26, 0, 7); g.stroke(); g.globalAlpha = 1; g.fillStyle = '#fff'; g.font = 'bold 14px Heebo'; g.textAlign = 'center'; g.fillText(labels[l], l * 90 + 45, H - 18); }
      for (const n of notes) {
        if (n.hit) continue; const y = hitY - (n.t - now) * speed;
        if (y > H + 30) { n.hit = 'miss'; combo = 0; continue; }
        if (y < -30) continue;
        g.fillStyle = cols[n.lane]; g.shadowColor = cols[n.lane]; g.shadowBlur = 18; g.beginPath(); g.arc(n.lane * 90 + 45, y, 20, 0, 7); g.fill(); g.shadowBlur = 0;
      }
      for (let l = 0; l < 4; l++) if (Input.pressed.has(keys[l])) {
        let best = null, bd = 1e9; for (const n of notes) if (!n.hit && n.lane === l) { const d = Math.abs(n.t - now); if (d < bd) { bd = d; best = n; } }
        if (best && bd < 0.16) { best.hit = true; combo++; const perfect = bd < 0.06; score += perfect ? 1 : 0.6; fb.textContent = (perfect ? CH1.djGame.perfect : CH1.djGame.good) + (combo > 3 ? ` ×${combo}` : ''); fb.style.color = cols[l]; Audio.play('djembeSlap', { vol: 0.35, rate: 1.5 + l * 0.2 }); }
        else { combo = 0; fb.textContent = CH1.djGame.miss; fb.style.color = '#888'; }
      }
      if (now > dur + 1.5 || Input.pressed.has('Escape')) return res();
      requestAnimationFrame(frame);
    };
    frame();
  });
  await close(o);
  return score / Math.max(1, total);
}

/** מעגל תופים: המתופף מנגן רצף, השחקן חוזר עליו ב-Q W E R. 3 סיבובים */
export async function drumGame() {
  const keys = ['KeyQ', 'KeyW', 'KeyE', 'KeyR'], labels = ['Q', 'W', 'E', 'R'], snd = [['djembeLow', 1], ['djembeLow', 1.3], ['djembeSlap', 1], ['djembeSlap', 1.25]];
  const o = overlay(`<div style="text-align:center"><div style="font-family:var(--serif);font-size:30px">${CH1.drumGame.title}</div><div style="color:var(--muted);font-size:13px;margin:6px 0 16px">${CH1.drumGame.hint}</div><div class="drums" style="display:flex;gap:14px;direction:ltr">${labels.map((l, i) => `<div data-i="${i}" style="width:84px;height:84px;border-radius:50%;background:radial-gradient(circle at 40% 35%,#c9a070,#7a5534);display:grid;place-items:center;font-weight:800;font-size:20px;color:#2a1a0a;box-shadow:0 8px 24px rgba(0,0,0,.5);transition:transform .1s,box-shadow .1s">${l}</div>`).join('')}</div><div class="st" style="margin-top:14px;font-size:16px;height:22px"></div></div>`);
  const pads = [...o.querySelectorAll('[data-i]')], st = o.querySelector('.st');
  const flash = (i) => { pads[i].style.transform = 'scale(1.12)'; pads[i].style.boxShadow = '0 0 40px rgba(255,180,90,.9)'; Audio.play(snd[i][0], { vol: 0.8, rate: snd[i][1] }); setTimeout(() => { pads[i].style.transform = ''; pads[i].style.boxShadow = '0 8px 24px rgba(0,0,0,.5)'; }, 160); };
  let ok = 0; const seq = [];
  for (let round = 0; round < 3; round++) {
    seq.push(Math.floor(Math.random() * 4), Math.floor(Math.random() * 4));
    st.textContent = '♪'; await sleep(700);
    for (const i of seq) { flash(i); await sleep(420); }
    st.textContent = '…';
    let idx = 0, fail = false;
    await new Promise(res => { const f = () => { for (let k = 0; k < 4; k++) if (Input.pressed.has(keys[k])) { flash(k); if (k !== seq[idx]) { fail = true; } idx++; } if (fail || idx >= seq.length) return res(); requestAnimationFrame(f); }; f(); });
    if (!fail) { ok++; st.textContent = '✓'; } else { st.textContent = '~'; }
    await sleep(600);
  }
  await close(o);
  return ok / 3;
}

/** סלפי: מסגרת טלפון, קליק לצילום. מחזיר dataURL של התמונה */
export async function selfie(renderer) {
  const o = overlay(`<div style="width:min(340px,70vw);aspect-ratio:9/16;border-radius:34px;border:10px solid #111;box-shadow:0 0 0 2px #333,0 30px 80px rgba(0,0,0,.6);position:relative;overflow:hidden"><div style="position:absolute;top:8px;left:50%;transform:translateX(-50%);width:80px;height:20px;border-radius:12px;background:#111"></div><div style="position:absolute;bottom:18px;left:50%;transform:translateX(-50%);width:58px;height:58px;border-radius:50%;border:4px solid #fff"></div></div><div style="position:fixed;bottom:40px;color:var(--muted);font-size:14px">${CH1.selfieGame.hint}</div>`);
  await new Promise(res => { const f = () => { if (Input.mouse.clicked || Input.pressed.has('KeyE')) return res(); requestAnimationFrame(f); }; setTimeout(f, 300); });
  Audio.play('shutter', { vol: 0.8 });
  const flash = document.createElement('div'); flash.style.cssText = `position:fixed;inset:0;background:#fff;z-index:31;opacity:${Settings.get('reduceFlash') ? 0.15 : 0.85};transition:opacity .5s`; document.body.appendChild(flash);
  let url = ''; try { url = renderer.domElement.toDataURL('image/jpeg', 0.7); } catch (e) {}
  requestAnimationFrame(() => (flash.style.opacity = 0)); setTimeout(() => flash.remove(), 600);
  await close(o);
  if (url) { const pol = document.createElement('div'); pol.style.cssText = 'position:fixed;top:12%;left:6%;z-index:31;background:#f4efe6;padding:10px 10px 34px;transform:rotate(-6deg) translateY(-20px);box-shadow:0 20px 50px rgba(0,0,0,.6);opacity:0;transition:all .6s cubic-bezier(.2,.8,.2,1)'; pol.innerHTML = `<img src="${url}" style="width:200px;display:block;filter:saturate(1.1) contrast(1.05)">`; document.body.appendChild(pol); requestAnimationFrame(() => { pol.style.opacity = 1; pol.style.transform = 'rotate(-6deg)'; }); setTimeout(() => { pol.style.opacity = 0; setTimeout(() => pol.remove(), 700); }, 4200); }
  return url;
}
