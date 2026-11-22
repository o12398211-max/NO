// ═══════════════════════════════════════════════════════════════════
//  מסכים: אזהרת טריגר, טעינה, לובי (יחיד/מולטיפלייר), הגדרות, השהיה, טבלת ניקוד, קרדיטים
// ═══════════════════════════════════════════════════════════════════
import { WARNING, SETTINGS, LOADING, LOBBY, HUD, TITLE, SUBTITLE, CHAPTERS, ENDING, CREDITS } from '../config/texts.he.js';
import { Settings } from '../core/settings.js';
import { SKIN, HAIR_COL, OUTFITS } from '../core/character.js';
import { Audio } from '../core/audio.js';
import { Net } from '../core/net.js';
import { CONFIG } from '../config/game.config.js';

const h = (html) => { const t = document.createElement('template'); t.innerHTML = html.trim(); return t.content.firstElementChild; };
const esc = (s) => String(s ?? '').replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const sleep = (ms) => new Promise(r => setTimeout(r, ms));
const show = (e, on = true) => e.classList.toggle('on', on);

function toggle(key, label, desc) {
  const e = h(`<div class="toggle ${Settings.get(key) ? 'on' : ''}" role="switch" tabindex="0"><div><div class="lbl">${label}</div>${desc ? `<div class="desc">${desc}</div>` : ''}</div><div class="switch"></div></div>`);
  const flip = () => { const v = !Settings.get(key); Settings.set(key, v); e.classList.toggle('on', v); Audio.play('click', { vol: 0.4 }); };
  e.onclick = flip; e.onkeydown = (ev) => { if (ev.key === 'Enter' || ev.key === ' ') { ev.preventDefault(); flip(); } };
  return e;
}
function range(key, label, min, max, step) {
  const e = h(`<div class="range"><span>${label}</span><input type="range" min="${min}" max="${max}" step="${step}" value="${Settings.get(key)}"></div>`);
  e.querySelector('input').oninput = (ev) => Settings.set(key, parseFloat(ev.target.value));
  return e;
}

// ───────────── אזהרה ─────────────
export function warningScreen() {
  return new Promise(res => {
    const s = h(`<div id="warning" class="screen"><div class="wrap">
      <h1>${WARNING.heading}</h1>
      ${WARNING.body.map(p => `<p>${esc(p)}</p>`).join('')}
      <div class="quick"><div class="t">${WARNING.quickSettings}</div></div>
      <div class="actions"><button class="btn primary" id="wAccept">${WARNING.accept}</button><button class="btn ghost" id="wExit">${WARNING.exit}</button></div>
    </div></div>`);
    const q = s.querySelector('.quick');
    q.append(toggle('reduceScare', SETTINGS.reduceScare, SETTINGS.reduceScareDesc), toggle('reduceFlash', SETTINGS.reduceFlash, SETTINGS.reduceFlashDesc), toggle('bigSubs', SETTINGS.bigSubs, SETTINGS.bigSubsDesc));
    document.body.appendChild(s); requestAnimationFrame(() => show(s));
    s.querySelector('#wAccept').onclick = async () => { Audio.init(); Audio.play('click', { vol: 0.5 }); show(s, false); await sleep(700); s.remove(); res(true); };
    s.querySelector('#wExit').onclick = () => { s.querySelector('.wrap').innerHTML = `<p style="text-align:center;margin-top:30vh">${WARNING.exited}</p>`; res(false); };
  });
}

// ───────────── טעינה ─────────────
export function loadingScreen() {
  const s = h(`<div id="loading" class="screen on"><div class="sunrise"></div><div class="title">${TITLE}</div><div class="sub">${SUBTITLE}</div><div class="bar"><i></i></div><div class="step"></div><div class="tip"></div></div>`);
  document.body.appendChild(s);
  let tipI = Math.floor(Math.random() * LOADING.tips.length);
  const tip = s.querySelector('.tip'); tip.textContent = LOADING.tips[tipI];
  const iv = setInterval(() => { tipI = (tipI + 1) % LOADING.tips.length; tip.textContent = LOADING.tips[tipI]; }, 4500);
  return {
    set(p, step) { s.querySelector('.bar i').style.width = Math.round(p * 100) + '%'; if (step) s.querySelector('.step').textContent = LOADING.steps[step] || step; },
    async done() { clearInterval(iv); show(s, false); await sleep(800); s.remove(); },
  };
}

// ───────────── הגדרות ─────────────
export function settingsOverlay(onQuality) {
  const o = h(`<div class="overlay"><div class="panel"><div class="menu"><h3>${SETTINGS.title}</h3></div></div></div>`);
  const m = o.querySelector('.menu');
  m.append(toggle('reduceScare', SETTINGS.reduceScare, SETTINGS.reduceScareDesc), toggle('reduceFlash', SETTINGS.reduceFlash, SETTINGS.reduceFlashDesc), toggle('bigSubs', SETTINGS.bigSubs, SETTINGS.bigSubsDesc), toggle('invertY', SETTINGS.invertY));
  m.append(range('master', SETTINGS.master, 0, 1, 0.01), range('music', SETTINGS.music, 0, 1, 0.01), range('sfx', SETTINGS.sfx, 0, 1, 0.01), range('sens', SETTINGS.sens, 0.2, 3, 0.05));
  const q = h(`<div class="range"><span>${SETTINGS.quality}</span><select>${Object.entries(SETTINGS.qualityOpts).map(([k, v]) => `<option value="${k}" ${Settings.get('quality') === k ? 'selected' : ''}>${v}</option>`).join('')}</select></div>`);
  q.querySelector('select').onchange = (e) => { Settings.set('quality', e.target.value); onQuality && onQuality(e.target.value); };
  m.append(q);
  const close = h(`<button class="btn primary" style="margin-top:10px">${SETTINGS.close}</button>`); m.append(close);
  document.body.appendChild(o);
  return new Promise(res => { requestAnimationFrame(() => show(o)); close.onclick = async () => { show(o, false); await sleep(300); o.remove(); res(); }; });
}

// ───────────── לובי ─────────────
export function lobbyScreen({ onQuality }) {
  return new Promise(resolve => {
    const ribbon = `<svg viewBox="0 0 24 24" fill="none"><path d="M12 3c-2 0-3.5 1.6-3.5 3.6 0 2.7 3.5 6.4 3.5 6.4s3.5-3.7 3.5-6.4C15.5 4.6 14 3 12 3z" stroke="#f2d25a" stroke-width="1.6"/><path d="M10 11l-4 10 3-1.5L10.5 22 12 13M14 11l4 10-3-1.5-1.5 2.5L12 13" stroke="#f2d25a" stroke-width="1.6" stroke-linejoin="round"/></svg>`;
    const s = h(`<div id="lobby" class="screen"><div class="shell">
      <div class="brand"><div><div class="logo">${TITLE}</div><div class="tag">${SUBTITLE}</div></div><div class="ribbon">${ribbon}<span>${ENDING.dedication}</span></div></div>
      <div class="panel" id="pChar">
        <h2>${LOBBY.look.toUpperCase()}</h2>
        <div class="field"><label>${LOBBY.name}</label><input type="text" id="lName" maxlength="16" placeholder="${LOBBY.namePh}"></div>
        <div class="field"><label>${LOBBY.address}</label><div class="seg" id="lGender"><button data-v="m">${LOBBY.addressM}</button><button data-v="f">${LOBBY.addressF}</button></div></div>
        <div class="field"><label>${LOBBY.skin}</label><div class="swatches" id="lSkin"></div></div>
        <div class="field"><label>${LOBBY.hair}</label><div class="seg" id="lHair"></div><div class="swatches" id="lHairC" style="margin-top:8px"></div></div>
        <div class="field"><label>${LOBBY.outfit}</label><div class="seg" id="lOutfit" style="flex-wrap:wrap"></div></div>
        <div class="row" style="margin-top:6px"><button class="btn small" id="lSettings">${LOBBY.settings}</button><button class="btn small ghost" id="lCredits">${LOBBY.credits}</button></div>
      </div>
      <div class="panel" id="pPlay">
        <h2>${LOBBY.play.toUpperCase()}</h2>
        <div id="modeMain">
          <div class="row" style="margin-bottom:14px"><button class="btn primary" id="lSolo">${LOBBY.solo}</button><button class="btn" id="lCreate">${LOBBY.create}</button></div>
          <div class="field"><label>${LOBBY.roomSize}</label><div class="seg" id="lSize">${CONFIG.roomSizes.map(n => `<button data-v="${n}">${n}</button>`).join('')}</div></div>
          <div id="lLockWrap"></div>
          <div class="field" style="margin-top:12px"><label>${LOBBY.join}</label><div class="row"><input type="text" id="lCode" placeholder="${LOBBY.codePh}" style="flex:1;direction:ltr;text-transform:uppercase;letter-spacing:3px" maxlength="6"><input type="text" id="lPin" placeholder="${LOBBY.pinPh}" style="flex:1;direction:ltr" maxlength="4"><button class="btn" id="lJoin">${LOBBY.joinBtn}</button></div></div>
          <div class="field"><label>${LOBBY.chapterSelect}</label><div class="chapters" id="lChapters"></div></div>
        </div>
        <div id="modeRoom" class="hidden">
          <div class="code" id="rCode">-----</div>
          <div class="field" style="margin-top:12px"><label>${LOBBY.invite}</label><div class="invite"><input type="text" id="rLink" readonly><button class="btn small" id="rCopy">${LOBBY.copy}</button></div></div>
          <div id="rPinRow" class="field hidden"><label>${LOBBY.pinPh}</label><div class="code" style="font-size:22px" id="rPin"></div></div>
          <h2 style="margin-top:14px">${LOBBY.players.toUpperCase()}</h2><ul class="plist" id="rList"></ul>
          <div class="row" style="margin-top:14px"><button class="btn primary" id="rStart">${LOBBY.start}</button><button class="btn ghost" id="rLeave">${LOBBY.leave}</button></div>
          <div id="rWait" class="hidden" style="color:var(--muted);margin-top:10px">${LOBBY.waitingHost}</div>
        </div>
        <div class="err" id="lErr"></div>
        <div style="color:var(--dim);font-size:12px;margin-top:6px">${LOBBY.netNote}</div>
      </div>
      <div class="foot">${LOBBY.footer}</div>
    </div></div>`);
    document.body.appendChild(s); requestAnimationFrame(() => show(s));
    const $ = (q) => s.querySelector(q);
    const err = (t) => { $('#lErr').textContent = t || ''; };
    // דמות
    const name = $('#lName'); name.value = Settings.get('name') || ''; name.oninput = () => Settings.set('name', name.value.trim());
    const seg = (id, items, key, label = (x) => x) => { const e = $(id); e.innerHTML = ''; items.forEach((it, i) => { const b = h(`<button data-v="${i}">${esc(label(it, i))}</button>`); if (Settings.get(key) === i) b.classList.add('on'); b.onclick = () => { Settings.set(key, i); [...e.children].forEach(c => c.classList.toggle('on', c === b)); Audio.play('click', { vol: 0.3 }); }; e.appendChild(b); }); };
    const sw = (id, cols, key) => { const e = $(id); cols.forEach((c, i) => { const d = h(`<div class="sw" style="background:${c}"></div>`); if (Settings.get(key) === i) d.classList.add('on'); d.onclick = () => { Settings.set(key, i); [...e.children].forEach(x => x.classList.toggle('on', x === d)); Audio.play('click', { vol: 0.3 }); }; e.appendChild(d); }); };
    sw('#lSkin', SKIN, 'skin'); sw('#lHairC', HAIR_COL, 'hairColor');
    seg('#lHair', LOBBY.hairStyles, 'hair'); seg('#lOutfit', LOBBY.outfits, 'outfit');
    const g = $('#lGender'); [...g.children].forEach(b => { b.classList.toggle('on', b.dataset.v === Settings.get('gender')); b.onclick = () => { Settings.set('gender', b.dataset.v); [...g.children].forEach(c => c.classList.toggle('on', c === b)); }; });
    $('#lSettings').onclick = () => settingsOverlay(onQuality);
    $('#lCredits').onclick = () => creditsOnly();
    // גודל + נעילה
    let size = 4; const sz = $('#lSize'); [...sz.children].forEach(b => { b.classList.toggle('on', +b.dataset.v === size); b.onclick = () => { size = +b.dataset.v; [...sz.children].forEach(c => c.classList.toggle('on', c === b)); }; });
    let locked = false; const lockT = h(`<div class="toggle"><div><div class="lbl">${LOBBY.friendsOnly}</div><div class="desc">${LOBBY.friendsOnlyDesc}</div></div><div class="switch"></div></div>`);
    lockT.onclick = () => { locked = !locked; lockT.classList.toggle('on', locked); }; $('#lLockWrap').appendChild(lockT);
    // פרקים
    const prog = Settings.get('progress') || 1; let chosen = 1;
    CHAPTERS.forEach(c => { const b = h(`<button ${c.n > prog ? 'disabled' : ''}><span>${LOBBY.chapterSelect} ${c.n}</span><b>${c.name}</b></button>`); b.onclick = () => { chosen = c.n; [...$('#lChapters').children].forEach(x => (x.style.borderColor = '')); b.style.borderColor = 'var(--accent)'; }; $('#lChapters').appendChild(b); });
    $('#lChapters').children[0].style.borderColor = 'var(--accent)';
    const me = () => ({ name: Settings.get('name') || (Settings.get('gender') === 'f' ? 'נועה' : 'נועם'), look: { skin: Settings.get('skin'), hair: Settings.get('hair'), hairColor: Settings.get('hairColor'), outfit: Settings.get('outfit'), gender: Settings.get('gender') }, gender: Settings.get('gender') });
    const finish = async (r) => { show(s, false); await sleep(600); s.remove(); resolve(r); };
    $('#lSolo').onclick = () => { if (!Settings.get('name')) Settings.set('name', me().name); finish({ mode: 'solo', chapter: chosen }); };
    // חדר
    const colors = ['#ffb35c', '#7ec8f0', '#ff6a8a', '#7fd6a4', '#c59bff', '#f2d25a', '#ff8a5c', '#9fe3ff'];
    const renderList = (list) => { $('#rList').innerHTML = list.map((p, i) => `<li><span class="dot" style="background:${colors[i % 8]}"></span>${esc(p.name)}${p.id === Net.id ? ` (${LOBBY.you})` : ''}${p.host ? `<span class="tag">${LOBBY.host}</span>` : ''}</li>`).join(''); };
    const enterRoom = (info, isHost) => {
      $('#modeMain').classList.add('hidden'); $('#modeRoom').classList.remove('hidden');
      $('#rCode').textContent = Net.room; $('#rLink').value = Net.isHost ? info.link : location.href;
      if (Net.pin && Net.isHost) { $('#rPinRow').classList.remove('hidden'); $('#rPin').textContent = Net.pin; }
      $('#rStart').classList.toggle('hidden', !isHost); $('#rWait').classList.toggle('hidden', isHost);
      renderList(Net.roster());
    };
    Net.on('roster', renderList);
    Net.on('start', (d) => { if (!Net.isHost) finish({ mode: 'mp', chapter: d.chapter }); });
    Net.on('hostLeft', () => { err(LOBBY.hostLeft); leaveRoom(); });
    Net.on('kicked', () => { err(LOBBY.kicked); leaveRoom(); });
    const leaveRoom = () => { Net.leave(); $('#modeMain').classList.remove('hidden'); $('#modeRoom').classList.add('hidden'); };
    $('#lCreate').onclick = async () => { err(LOBBY.connecting); try { const info = await Net.host({ size, locked, me: me() }); err(''); enterRoom(info, true); } catch (e) { err(LOBBY.connectFail); } };
    const doJoin = async (room, pin) => {
      err(LOBBY.connecting);
      try { await Net.join({ room, pin, me: me() }); err(''); enterRoom({}, false); }
      catch (e) { err({ full: LOBBY.roomFull, locked: LOBBY.roomLocked, started: LOBBY.roomStarted }[e.message] || LOBBY.connectFail); }
    };
    $('#lJoin').onclick = () => doJoin($('#lCode').value, $('#lPin').value);
    $('#rCopy').onclick = async () => { try { await navigator.clipboard.writeText($('#rLink').value); } catch (e) { $('#rLink').select(); document.execCommand('copy'); } $('#rCopy').textContent = LOBBY.copied; setTimeout(() => ($('#rCopy').textContent = LOBBY.copy), 1500); };
    $('#rLeave').onclick = leaveRoom;
    $('#rStart').onclick = () => { Net.started = true; Net.broadcast({ t: 'start', chapter: chosen }); finish({ mode: 'mp', chapter: chosen }); };
    // קישור הזמנה בכתובת
    const m = location.hash.match(/room=([A-Z0-9]+)(?:&k=(\d+))?/i);
    if (m) { $('#lCode').value = m[1]; if (m[2]) $('#lPin').value = m[2]; setTimeout(() => doJoin(m[1], m[2]), 400); }
  });
}

// ───────────── השהיה ─────────────
export function pauseMenu({ onResume, onCheckpoint, onLobby, onQuality }) {
  const o = h(`<div class="overlay" id="pause"><div class="panel"><div class="menu">
    <h3>${HUD.pause}</h3>
    <button class="btn primary" data-a="resume">${HUD.resume}</button>
    <button class="btn" data-a="cp">${HUD.restartCp}</button>
    <button class="btn" data-a="settings">${SETTINGS.title}</button>
    <button class="btn ghost" data-a="lobby">${HUD.toLobby}</button>
  </div></div></div>`);
  document.body.appendChild(o);
  o.querySelectorAll('button').forEach(b => b.onclick = async () => {
    const a = b.dataset.a; Audio.play('click', { vol: 0.4 });
    if (a === 'settings') { await settingsOverlay(onQuality); return; }
    show(o, false);
    if (a === 'resume') onResume(); if (a === 'cp') onCheckpoint(); if (a === 'lobby') onLobby();
  });
  return { open() { show(o, true); }, close() { show(o, false); }, get isOpen() { return o.classList.contains('on'); } };
}

// ───────────── טבלת ניקוד ─────────────
export function scoreboard() {
  const o = h(`<div class="overlay" id="score" style="background:rgba(4,3,8,.35)"><div class="panel"><h2>${HUD.scoreboard}</h2><table class="score"><thead><tr>${HUD.scoreCols.map(c => `<th>${c}</th>`).join('')}</tr></thead><tbody></tbody></table></div></div>`);
  document.body.appendChild(o);
  const fmt = (s) => `${Math.floor(s / 60)}:${String(Math.floor(s % 60)).padStart(2, '0')}`;
  return {
    show(on, rows) {
      if (on) o.querySelector('tbody').innerHTML = rows.map(r => `<tr><td>${esc(r.name)}</td><td>${fmt(r.score?.time || 0)}</td><td>${r.score?.puzzles || 0}</td><td>${r.score?.chapter || 1}</td></tr>`).join('');
      show(o, on);
    },
  };
}

// ───────────── קרדיטים והקדשה ─────────────
export function creditsScreen({ dedicationFirst = true } = {}) {
  return new Promise(res => {
    const s = h(`<div id="credits" class="screen"><div class="candle"></div><div class="ded">${ENDING.dedication}</div><div class="roll"><div class="inner"><div class="c"><div class="v" style="font-family:var(--serif);font-size:44px">${TITLE}</div></div>${CREDITS.map(([k, v]) => `<div class="c"><div class="k">${esc(k)}</div><div class="v">${esc(v)}</div></div>`).join('')}<div class="c"><div class="v" style="font-family:var(--serif);font-size:26px;margin-top:80px">${ENDING.dedication}</div></div></div></div></div>`);
    document.body.appendChild(s); requestAnimationFrame(() => show(s));
    const ded = s.querySelector('.ded'), inner = s.querySelector('.inner'), candle = s.querySelector('.candle');
    (async () => {
      if (dedicationFirst) { await sleep(800); ded.classList.add('on'); await sleep(9000); ded.classList.remove('on'); candle.style.opacity = 0; await sleep(2500); }
      ded.style.display = 'none'; candle.style.display = 'none'; inner.classList.add('go');
    })();
    const end = async () => { show(s, false); await sleep(700); s.remove(); res(); };
    inner.addEventListener('animationend', end);
    s.addEventListener('click', () => { if (inner.classList.contains('go')) end(); });
  });
}
async function creditsOnly() { await creditsScreen({ dedicationFirst: false }); }
