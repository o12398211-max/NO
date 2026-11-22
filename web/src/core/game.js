// ═══════════════════════════════════════════════════════════════════
//  Game – מנהל המשחק: לולאה ראשית, טעינת פרקים, צ'קפוינטים, כישלון/חזרה, שחקנים מרוחקים, ניקוד, השהיה
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Input } from './input.js';
import { Audio, Music, Body } from './audio.js';
import { UI } from './ui.js';
import { Player, World } from './player.js';
import { ViewModel } from './viewmodel.js';
import { Director } from './director.js';
import { Character, SKIN, HAIR_COL, OUTFITS } from './character.js';
import { Net } from './net.js';
import { Settings } from './settings.js';
import { CONFIG } from '../config/game.config.js';
import { HUD } from '../config/texts.he.js';

export class Chapter {
  constructor(game) { this.game = game; this.objects = []; this.timers = []; this.alive = true; this.flags = {}; }
  get eng() { return this.game.eng; } get scene() { return this.game.eng.scene; } get player() { return this.game.player; }
  add(o) { this.scene.add(o); this.objects.push(o); return o; }
  /** המתנה שמתבטלת אם הפרק הוחלף */
  wait(s) { return new Promise((res, rej) => { const id = setTimeout(() => (this.alive ? res() : rej(new Error('chapter-ended'))), s * 1000); this.timers.push(id); }); }
  /** המתנה לתנאי */
  until(fn, timeout = 1e9) { return new Promise((res, rej) => { const t0 = performance.now(); const tick = () => { if (!this.alive) return rej(new Error('chapter-ended')); if (fn() || performance.now() - t0 > timeout * 1000) res(); else requestAnimationFrame(tick); }; tick(); }); }
  dispose() {
    this.alive = false; for (const t of this.timers) clearTimeout(t);
    for (const o of this.objects) { this.scene.remove(o); o.traverse && o.traverse(c => { if (c.geometry && !c.geometry.userData.shared) c.geometry.dispose(); }); }
    this.objects.length = 0;
    if (this.loops) for (const l of this.loops) l.stop(0.3);
  }
  loop(name, o) { const l = Audio.loop(name, o); (this.loops = this.loops || []).push(l); return l; }
  async build() {} start() {} update() {}
}

export class Game {
  constructor(eng) {
    this.eng = eng; this.world = new World();
    this.player = new Player(eng.camera, this.world);
    this.vm = new ViewModel(eng.camera, {});
    this.director = new Director(eng);
    this.chapter = null; this.chapterN = 0; this.checkpoint = null;
    this.remotes = new Map(); this.ghostMode = false;
    this.score = { time: 0, puzzles: 0, chapter: 1 }; this.chapterStart = 0;
    this.paused = false; this.running = false; this.netT = 0;
    this.trust = { shachar: 0, maya: 0, yoni: 0, esther: 0, ido: 0, meir: 0 };
    this.hasBracelet = false;
    this.chapters = {};
    this.enemiesDisabled = false;
    this._setupNet();
  }
  registerChapter(n, cls) { this.chapters[n] = cls; }
  look() { return { skin: Settings.get('skin'), hair: Settings.get('hair'), hairColor: Settings.get('hairColor'), outfit: Settings.get('outfit'), gender: Settings.get('gender') }; }
  myCharacterOpts(extra = {}) { const L = this.look(); return { skin: SKIN[L.skin], hair: L.hair, hairColor: HAIR_COL[L.hairColor], outfit: OUTFITS[L.outfit], gender: L.gender, acc: this.hasBracelet ? ['bracelet'] : [], ...extra }; }

  async loadChapter(n, cp = null) {
    UI.clearSubs(); UI.prompt(null); UI.objective(null); UI.note(null);
    this.eng.set('fade', 1);
    if (this.chapter) { this.chapter.dispose(); this.chapter = null; }
    // ניקוי סצנה (מלבד מצלמה)
    for (const c of [...this.eng.scene.children]) if (c !== this.eng.camera) this.eng.scene.remove(c);
    this.eng.scene.fog = null; this.eng.scene.background = null; this.eng.scene.environment = null;
    this.world.colliders = []; this.world.bounds = null;
    this.player.clearInteract(); this.player.vehicle = null; this.player.locked = false; this.player.lookLimit = null; this.player.speedMul = 1;
    this.player.fearTarget = 0; this.player.fear = 0; this.player.canSprint = true; this.player.canJump = true; this.player.crouch = false; this.player.moveLocked = false; this.player.lookLocked = false;
    this.player.camOffset.set(0, 0, 0); this.player.extraPitch = 0; this.player.extraYaw = 0; this.player.breathOverride = null; this.player.fxSuspended = false;
    this.vm.setPose('idle', true); this.vm.group.visible = true; this.vm.pistol.visible = false; this.vm.bracelet.visible = this.hasBracelet;
    Music.set('silence'); Music.setDiegetic(false); Audio.setMuffle(0, 0.1);
    for (const r of this.remotes.values()) r.ch && this.eng.scene.add(r.ch.root);
    this.chapterN = n; this.checkpoint = cp; this.score.chapter = n; this.chapterStart = this.eng.time;
    Settings.get('progress') < n && Settings.set('progress', n);
    const Cls = this.chapters[n];
    this.chapter = new Cls(this);
    await this.chapter.build();
    this.ghostMode = !!this.chapter.ghosts;
    for (const r of this.remotes.values()) r.ch && r.ch.setGhost(this.ghostMode);
    this.chapter.start(cp);
  }
  async restartCheckpoint() { if (this.chapter && this.chapter.restart) this.chapter.restart(this.checkpoint); else await this.loadChapter(this.chapterN, this.checkpoint); }
  setCheckpoint(name) { this.checkpoint = name; }
  addPuzzle() { this.score.puzzles++; Net.sendScore(this.score); }

  /** כישלון בבריחה: אדום בקצה, צליל חד, האטה, חיתוך לשחור עם דופק ונשימה – בלי טקסט */
  async fail({ delay } = {}) {
    if (this.failing || this.player.god) return; this.failing = true;
    const e = this.eng, p = this.player;
    p.locked = true;
    Audio.play('punch', { vol: 0.8 }); Audio.play('crack', { vol: 0.5 });
    e.set('hit', 1); p.addTrauma(0.7); e.set('desat', 0.8, 2);
    Audio.setMuffle(0.7, 0.2); Body.ring(0.8);
    p.breathOverride = 1;
    await UI.sleep(450);
    e.set('fade', 1, 1.6);
    await UI.sleep(800);
    p.fearTarget = 1;
    await UI.sleep((delay ?? (Net.count() > 1 ? CONFIG.respawnDelay : 2.2)) * 1000);
    e.set('hit', 0); e.set('desat', 0); p.breathOverride = null; Audio.setMuffle(0, 1);
    this.failing = false; p.locked = false;
    await this.restartCheckpoint();
    e.set('fade', 0, 0.8);
  }

  // ───────────── רשת ─────────────
  _setupNet() {
    Net.on('st', d => {
      let r = this.remotes.get(d.id);
      if (!r) { r = { pos: new THREE.Vector3(...d.p), ry: d.ry, ch: null }; this.remotes.set(d.id, r); }
      if (!r.ch) { const pl = Net.players.get(d.id); const L = pl ? pl.look : {}; r.ch = new Character({ skin: SKIN[L?.skin ?? 2], hair: L?.hair ?? 0, hairColor: HAIR_COL[L?.hairColor ?? 1], outfit: OUTFITS[L?.outfit ?? 0], gender: L?.gender || 'm', acc: ['bracelet'] }); this.eng.scene.add(r.ch.root); r.ch.setGhost(this.ghostMode); r.ch.root.position.set(...d.p); }
      r.target = new THREE.Vector3(...d.p); r.ry = d.ry; r.anim = d.a; r.chN = d.c; r.seen = performance.now();
    });
    Net.on('left', id => this._removeRemote(id));
    Net.on('roster', list => { for (const id of [...this.remotes.keys()]) if (!list.find(p => p.id === id)) this._removeRemote(id); });
    // המארח מאשר בקשות אירוע של לקוחות
    Net.on('req', (d) => { if (Net.isHost) { const { t, ...rest } = d; Net.event(d.e, rest); } });
    Net.on('ev', d => { if (this.chapter && this.chapter.onEvent) this.chapter.onEvent(d.e, d); if (d.e === 'chapter' && !Net.isHost) this.loadChapter(d.n, d.cp || null); });
  }
  _removeRemote(id) { const r = this.remotes.get(id); if (r && r.ch) this.eng.scene.remove(r.ch.root); this.remotes.delete(id); }
  /** מעבר פרק מסונכרן (המארח מחליט) */
  goChapter(n, cp = null) {
    this.score.time += this.eng.time - this.chapterStart; Net.sendScore(this.score);
    if (Net.online) { if (Net.isHost) Net.event('chapter', { n, cp }); if (Net.isHost) this.loadChapter(n, cp); }
    else this.loadChapter(n, cp);
  }
  _netTick(dt) {
    if (!Net.online) return;
    this.netT += dt; if (this.netT < 1 / CONFIG.netTickHz) return; this.netT = 0;
    const p = this.player; const anim = p.running ? 'run' : (Math.hypot(p.vel.x, p.vel.z) > 0.4 ? (p.crouch ? 'sneak' : 'walk') : (p.crouch ? 'crouch' : (this.chapter && this.chapter.myAnim) || 'idle'));
    Net.send({ t: 'st', id: Net.id, p: [+p.pos.x.toFixed(2), +p.pos.y.toFixed(2), +p.pos.z.toFixed(2)], ry: +(p.yaw + Math.PI).toFixed(2), a: anim, c: this.chapterN });
  }
  _updateRemotes(dt, beat) {
    for (const [id, r] of this.remotes) {
      if (!r.ch) continue;
      const vis = r.chN === this.chapterN && performance.now() - r.seen < 5000;
      r.ch.root.visible = vis; if (!vis) continue;
      r.ch.root.position.lerp(r.target, Math.min(1, dt * 10));
      let d = r.ry - r.ch.root.rotation.y; d = Math.atan2(Math.sin(d), Math.cos(d)); r.ch.root.rotation.y += d * Math.min(1, dt * 10);
      r.ch.setState(r.anim || 'idle', r.anim === 'run' ? 5 : 1.5); r.ch.update(dt, beat);
    }
  }

  // ───────────── לולאה ─────────────
  start() {
    this.running = true;
    const loop = () => {
      requestAnimationFrame(loop);
      Input.beginFrame();
      if (!this.running) return;
      this.eng.frame();
    };
    this.eng.onUpdate((dt, t) => this.tick(dt, t));
    loop();
  }
  tick(dt, t) {
    if (this.paused || !this.chapter) return;
    const beat = this.beat = (this.beat || 0) + dt * (Music.bpm / 60) * (Music.mode === 'party' ? 1 : 0.5);
    if (this.chapter.update) this.chapter.update(dt, t, beat);
    if (!this.director.active && !this.chapter.camOverride) this.player.update(dt, this.eng);
    else Body.update(dt, { breath: this.player.breathOverride ?? this.player.fear * 0.5, heart: this.player.fear });
    this.director.update(dt, t);
    this.vm.group.visible = !this.director.active && !this.player.vehicle && !this.hideViewmodel;
    this.vm.update(dt, { speed: Math.min(1, Math.hypot(this.player.vel.x, this.player.vel.z) / 5), run: this.player.running, lookDX: Input.mouse.dx, lookDY: Input.mouse.dy, breath: this.player.exhaust, crouch: this.player.crouch });
    if (!this.chapter.handlesArms && !this.director.active && !this.player.vehicle) {
      const want = this.player.running ? 'run' : this.player.focus ? 'reach' : 'idle';
      if (this.vm.pose !== want && ['run', 'reach', 'idle'].includes(this.vm.pose)) this.vm.setPose(want);
    }
    const f = this.player.focus;
    UI.prompt(f && !this.director.active && !this.chapter.noPrompts ? f.prompt : null, f && f.key);
    this._updateRemotes(dt, beat);
    this._netTick(dt);
    UI.setFps(this.eng.fps);
    if (Input.hit('Tab')) this.onScoreboard && this.onScoreboard(true);
    if (Input.released.has('Tab')) this.onScoreboard && this.onScoreboard(false);
  }
}
