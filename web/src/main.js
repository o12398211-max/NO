// ═══════════════════════════════════════════════════════════════════
//  עד הזריחה – נקודת כניסה
//  אזהרת טריגר → טעינה → לובי (רקע קולנועי) → פרקים
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Engine } from './core/engine.js';
import { Input } from './core/input.js';
import { Audio, Music } from './core/audio.js';
import { UI } from './core/ui.js';
import { Game, Chapter } from './core/game.js';
import { Net } from './core/net.js';
import { Settings } from './core/settings.js';
import { Materials } from './world/materials.js';
import { buildFestival, LAYOUT } from './world/festival.js';
import { buildNightSky } from './world/props.js';
import { NPC } from './chapters/common.js';
import { randomLook } from './core/character.js';
import { warningScreen, loadingScreen, lobbyScreen, pauseMenu, scoreboard, creditsScreen } from './ui/screens.js';
import { setupAdmin } from './ui/admin.js';
import { Chapter1 } from './chapters/ch1_party.js';
import { Chapter2 } from './chapters/ch2_escape.js';
import { HUD } from './config/texts.he.js';
import { register as registerMore } from './chapters/more.js';

/** רקע קולנועי ללובי: המסיבה בלילה, מצלמה מרחפת לאט */
class LobbyScene extends Chapter {
  async build() {
    const F = this.F = buildFestival({});
    this.add(F.root); this.sky = this.add(buildNightSky());
    this.scene.environment = Materials.env('night'); this.scene.environmentIntensity = 0.18;
    this.scene.fog = new THREE.FogExp2(0x140d26, 0.012);
    this.add(new THREE.HemisphereLight(0x5a5aa0, 0x2a1d10, 0.55));
    for (const [c, x] of [[0xff2e88, -8], [0x19e3ff, 8], [0x9b5bff, 0]]) { const sp = new THREE.SpotLight(c, 500, 80, 0.7, 0.7, 1.5); sp.position.set(x, 12, LAYOUT.stage.z + 6); sp.target.position.set(x * 0.6, 0, LAYOUT.dance.z + 6); this.add(sp); this.add(sp.target); }
    this.npcs = [];
    for (let i = 0; i < 50; i++) { const n = new NPC(this.game, randomLook(i, { detail: i < 12 }), new THREE.Vector3((Math.random() - 0.5) * 30, 0, LAYOUT.dance.z - 8 + Math.random() * 16), Math.PI); n.idleState = 'dance'; n.ch.setState('dance'); n.collide = false; n.ch.setShadows(false); this.add(n.root); this.npcs.push(n); }
    this.game.world.heightFn = (x, z) => F.terrain.heightAt(x, z);
    this.eng.setGrade('lobby');
  }
  start() { Music.set('party'); Music.setDiegetic(true, new THREE.Vector3(0, 5, LAYOUT.stage.z + 5)); this.game.director.active = false; this.eng.set('fade', 0, 0.6); this.noPrompts = true; this.player.locked = true; this.game.hideViewmodel = true; }
  update(dt, t, beat) {
    const c = this.eng.camera; const a = t * 0.04;
    c.position.set(Math.sin(a) * 46, 9 + Math.sin(t * 0.1) * 2, LAYOUT.dance.z + Math.cos(a) * 40); c.lookAt(0, 3, LAYOUT.dance.z - 8);
    for (const u of this.F.updaters) u(t, beat, 1);
    for (const n of this.npcs) n.update(dt, beat);
    this.sky.material.uniforms.uTime.value = t;
    this.game.player.fxSuspended = true;
  }
  get camOverride() { return true; }
}

async function boot() {
  // מצב בדיקה: ?dev=2&cp=escape (מדלג על אזהרה ולובי – לבדיקות/צילומי מסך בלבד)
  const params = new URLSearchParams(location.search); const dev = params.get('dev');
  const ok = dev ? true : await warningScreen();
  if (!ok) return;
  const L = loadingScreen();
  L.set(0.05, 'engine');
  await new Promise(r => setTimeout(r, 50));
  const app = document.getElementById('app');
  const eng = new Engine(app);
  Input.init(eng.renderer.domElement);
  Materials.setRenderer(eng.renderer);
  L.set(0.1, 'textures');
  await Materials.load(p => L.set(0.1 + p * 0.6, p < 0.85 ? 'textures' : 'hdri'));
  L.set(0.75, 'audio'); await new Promise(r => setTimeout(r, 30));
  UI.init();
  const game = window.__game = new Game(eng);
  game.registerChapter(0, LobbyScene); game.registerChapter(1, Chapter1); game.registerChapter(2, Chapter2);
  registerMore(game);
  L.set(0.85, 'world');
  game.start();
  await game.loadChapter(0);
  L.set(1, 'ready');
  await L.done();
  setupAdmin(game);
  const sb = scoreboard();
  game.onScoreboard = (on) => { const rows = Net.online ? Net.roster() : [{ name: Settings.get('name'), score: { ...game.score, time: game.score.time + (eng.time - game.chapterStart) } }]; sb.show(on, rows); };
  // ─ השהיה ─
  const ctp = document.createElement('div'); ctp.className = 'click-to-play'; ctp.innerHTML = `<span>${HUD.clickToPlay}</span>`; document.body.appendChild(ctp);
  let inGame = false;
  const pm = pauseMenu({
    onResume: () => { game.paused = false; Input.lock(); },
    onCheckpoint: () => { game.paused = false; Input.lock(); game.restartCheckpoint(); },
    onLobby: () => { game.paused = false; inGame = false; Net.leave(); toLobby(); },
    onQuality: (q) => eng.setQuality(q),
  });
  eng.renderer.domElement.addEventListener('click', () => { if (inGame && !game.paused) Input.lock(); });
  ctp.onclick = () => { ctp.classList.remove('on'); Input.lock(); };
  document.addEventListener('pointerlockchange', () => {
    if (!inGame) return;
    const locked = document.pointerLockElement === eng.renderer.domElement;
    const dialogOpen = document.querySelector('#dialog.on') || document.querySelector('.overlay.on:not(#pause):not(#score)') || game.adminOpen;
    if (!locked && !dialogOpen && !game.paused) {
      if (Net.online) { pm.open(); } else { game.paused = true; pm.open(); }
    }
  });
  addEventListener('keydown', (e) => { if (e.code === 'Escape' && inGame && game.paused && pm.isOpen) { /* Esc נוסף סוגר בתפריט */ } });
  // ─ מעבר לפרק שלא קיים עדיין → קרדיטים ─
  const origLoad = game.loadChapter.bind(game);
  game.loadChapter = async (n, cp) => {
    if (n >= 1 && !game.chapters[n]) { inGame = false; Input.unlock(); Music.set('memorial'); await creditsScreen({}); Net.leave(); return toLobby(); }
    if (n >= 1) { inGame = true; game.hideViewmodel = false; game.player.fxSuspended = false; }
    return origLoad(n, cp);
  };
  game.onCredits = async () => { inGame = false; Input.unlock(); await creditsScreen({}); Net.leave(); toLobby(); };

  async function toLobby() {
    inGame = false; Input.unlock(); UI.setHidden(true);
    await game.loadChapter(0);
    const r = await lobbyScreen({ onQuality: (q) => eng.setQuality(q) });
    UI.setHidden(false);
    game.myName = Settings.get('name'); game.myGender = Settings.get('gender');
    UI.ctx = { name: game.myName, gender: game.myGender };
    game.vm.setLook({ skin: ['#f1d1b5', '#e2b48f', '#c99169', '#a4704a', '#7a4e33', '#5b3826'][Settings.get('skin')], sleeve: ['#f2efe9', '#ff4f8b', '#ffcf4a', '#3d4a5c', '#5b6b3e'][Settings.get('outfit')] });
    Audio.init();
    inGame = true;
    if (r.chapter > 1) game.hasBracelet = true;
    await game.loadChapter(r.chapter);
    Input.lock();
    if (!Input.locked) setTimeout(() => { if (!Input.locked) ctp.classList.add('on'); }, 600);
  }
  if (dev) { UI.setHidden(false); game.myName = Settings.get('name') || 'נועם'; game.myGender = Settings.get('gender'); UI.ctx = { name: game.myName, gender: game.myGender }; if (+dev > 1) game.hasBracelet = true; await game.loadChapter(+dev, params.get('cp')); window.__ready = true; return; }
  toLobby();
}

boot().catch(e => { console.error(e); const d = document.createElement('div'); d.style.cssText = 'position:fixed;inset:0;display:grid;place-items:center;color:#fff;background:#000;font:16px Heebo;padding:20px;text-align:center'; d.textContent = 'אירעה שגיאה בטעינת המשחק. נסו לרענן את הדף. (' + e.message + ')'; document.body.appendChild(d); });
