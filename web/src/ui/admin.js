// ═══════════════════════════════════════════════════════════════════
//  פאנל אדמין (F9) – לבדיקות בלבד. מוגן בסיסמה (CONFIG.adminPassword ב-src/config/game.config.js)
// ═══════════════════════════════════════════════════════════════════
import { ADMIN, CHAPTERS } from '../config/texts.he.js';
import { CONFIG } from '../config/game.config.js';
import { Net } from '../core/net.js';
import { UI } from '../core/ui.js';
import { Input } from '../core/input.js';

export function setupAdmin(game) {
  const p = document.createElement('div'); p.id = 'admin'; document.body.appendChild(p);
  let authed = false; const logs = [];
  const log = (s) => { logs.unshift(new Date().toLocaleTimeString() + ' ' + s); const l = p.querySelector('.log'); if (l) l.textContent = logs.slice(0, 30).join('\n'); };
  const login = () => {
    p.innerHTML = `<h4>${ADMIN.title}</h4><div class="r"><input type="password" id="aPass" placeholder="${ADMIN.pass}"><button id="aGo">${ADMIN.enter}</button></div><div id="aErr" style="color:#f66"></div>`;
    const go = () => { if (p.querySelector('#aPass').value === CONFIG.adminPassword) { authed = true; render(); } else p.querySelector('#aErr').textContent = ADMIN.wrong; };
    p.querySelector('#aGo').onclick = go; p.querySelector('#aPass').onkeydown = (e) => { if (e.key === 'Enter') go(); e.stopPropagation(); };
    setTimeout(() => p.querySelector('#aPass').focus(), 50);
  };
  const render = () => {
    const pl = game.player, cps = (game.chapter && game.chapter.checkpoints) || [];
    p.innerHTML = `<h4>${ADMIN.title}</h4>
      <div class="r"><span>${ADMIN.chapter}</span><select id="aCh">${CHAPTERS.map(c => `<option value="${c.n}" ${c.n === game.chapterN ? 'selected' : ''}>${c.n}. ${c.name}</option>`).join('')}</select><button id="aChGo">${ADMIN.go}</button></div>
      <div class="r"><span>${ADMIN.checkpoint}</span><select id="aCp">${cps.map(c => `<option>${c}</option>`).join('')}</select><button id="aCpGo">${ADMIN.go}</button></div>
      <div class="r"><span>${ADMIN.teleport}</span><input id="aTp" style="direction:ltr" placeholder="${pl.pos.x.toFixed(0)}, ${pl.pos.y.toFixed(0)}, ${pl.pos.z.toFixed(0)}"><button id="aTpGo">${ADMIN.go}</button></div>
      <div class="r"><span>${ADMIN.speed}</span><input type="range" id="aSpd" min="0.5" max="5" step="0.1" value="${pl.speedMul}"></div>
      <div class="r"><span>${ADMIN.time}</span><input type="range" id="aTime" min="0" max="24" step="0.25" value="${game.chapter && game.chapter.timeOfDay != null ? game.chapter.timeOfDay : 12}"></div>
      <div class="r">
        <button data-t="fly">${ADMIN.fly}: ${pl.noclip ? 'ON' : 'OFF'}</button>
        <button data-t="jump">${ADMIN.jump}: ${pl.jumpMul > 1 ? 'ON' : 'OFF'}</button>
        <button data-t="enemies">${ADMIN.noEnemies}: ${game.enemiesDisabled ? 'ON' : 'OFF'}</button>
        <button data-t="god">${ADMIN.god}: ${pl.god ? 'ON' : 'OFF'}</button>
        <button data-t="fx">${ADMIN.fx}: ${game.eng.postEnabled ? 'ON' : 'OFF'}</button>
        <button data-t="fps">${ADMIN.fps}</button>
        <button data-t="ui">${ADMIN.hideUI}</button>
      </div>
      ${Net.online && Net.isHost ? `<div class="r"><span>${ADMIN.kick}</span><select id="aKick">${Net.roster().filter(x => !x.host).map(x => `<option value="${x.id}">${x.name}</option>`).join('')}</select><button id="aKickGo">${ADMIN.go}</button></div>` : ''}
      <div class="r"><button id="aClose">${ADMIN.close}</button></div>
      <div class="log"></div>`;
    log('ready');
    const $ = (q) => p.querySelector(q);
    $('#aChGo').onclick = () => { const n = +$('#aCh').value; log('chapter ' + n); game.goChapter(n); };
    $('#aCpGo') && ($('#aCpGo').onclick = () => { const c = $('#aCp').value; log('checkpoint ' + c); game.loadChapter(game.chapterN, c); });
    $('#aTpGo').onclick = () => { const v = $('#aTp').value.split(',').map(Number); if (v.length >= 2) { pl.pos.set(v[0], v.length > 2 ? v[1] : pl.pos.y, v.length > 2 ? v[2] : v[1]); log('tp ' + v); } };
    $('#aSpd').oninput = (e) => { pl.speedMul = +e.target.value; };
    $('#aTime').oninput = (e) => { game.chapter && game.chapter.setTime && game.chapter.setTime(+e.target.value); };
    p.querySelectorAll('[data-t]').forEach(b => b.onclick = () => {
      const t = b.dataset.t;
      if (t === 'fly') pl.noclip = !pl.noclip;
      if (t === 'jump') pl.jumpMul = pl.jumpMul > 1 ? 1 : 3;
      if (t === 'enemies') game.enemiesDisabled = !game.enemiesDisabled;
      if (t === 'god') pl.god = !pl.god;
      if (t === 'fx') game.eng.postEnabled = !game.eng.postEnabled;
      if (t === 'fps') { game.showFps = !game.showFps; UI.showFps(game.showFps); }
      if (t === 'ui') UI.setHidden(!UI.hidden);
      log(t); render();
    });
    $('#aKickGo') && ($('#aKickGo').onclick = () => { Net.kick($('#aKick').value); log('kick'); setTimeout(render, 500); });
    $('#aClose').onclick = () => toggle(false);
    p.querySelectorAll('input').forEach(i => i.onkeydown = (e) => e.stopPropagation());
  };
  const toggle = (on) => {
    p.classList.toggle('on', on);
    if (on) { Input.unlock(); game.adminOpen = true; authed ? render() : login(); }
    else { game.adminOpen = false; }
  };
  addEventListener('keydown', (e) => { if (e.code === CONFIG.adminKey) { e.preventDefault(); toggle(!p.classList.contains('on')); } });
  return { log };
}
