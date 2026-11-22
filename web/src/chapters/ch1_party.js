// ═══════════════════════════════════════════════════════════════════
//  פרק 1 – המסיבה (לילה)
//  קאטסין פתיחה → גוף ראשון חופשי: ריקוד, שיחות, בר, סלפי, תופים, די־ג'יי → שחר והצמיד → פיזור → אוהל → שינה
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Chapter } from '../core/game.js';
import { buildFestival, LAYOUT } from '../world/festival.js';
import { buildNightSky } from '../world/props.js';
import { Materials } from '../world/materials.js';
import { NPC, Marker, sunRig, FRIENDS } from './common.js';
import { randomLook } from '../core/character.js';
import { Audio, Music, Body } from '../core/audio.js';
import { UI } from '../core/ui.js';
import { Input } from '../core/input.js';
import { Net } from '../core/net.js';
import { CH1, HUD } from '../config/texts.he.js';
import { djGame, drumGame, selfie } from './minigames.js';

const V3 = (x, y, z) => new THREE.Vector3(x, y, z);

export class Chapter1 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['intro', 'free', 'shachar', 'disperse', 'tent']; this.activities = new Set(); this.timeOfDay = 1; }
  async build() {
    const g = this.game, s = this.scene, eng = this.eng;
    const F = this.F = buildFestival({ dawn: false });
    this.add(F.root);
    g.world.colliders = F.colliders; g.world.heightFn = (x, z) => F.terrain.heightAt(x, z);
    g.world.surfaceFn = (x, z) => { const d = Math.hypot(x - LAYOUT.dance.x, z - LAYOUT.dance.z); if (d < 18) return 'dirt'; if (Math.hypot(x - LAYOUT.ourTent.x, z - LAYOUT.ourTent.z) < 2) return 'carpet'; return Math.random() < 0.5 ? 'grass' : 'dirt'; };
    g.world.bounds = { minX: -240, maxX: 240, minZ: -240, maxZ: 240 };
    this.sky = this.add(buildNightSky());
    s.environment = Materials.env('night'); s.environmentIntensity = 0.18;
    s.fog = new THREE.FogExp2(0x140d26, 0.011);
    this.add(new THREE.HemisphereLight(0x5a5aa0, 0x2a1d10, 0.55));
    this.moon = sunRig(s, { color: 0x9fb4ff, intensity: 0.45, dir: [-0.4, 0.75, 0.35], size: 45 }); this.objects.push(this.moon, this.moon.target);
    // תאורת במה: שטיפות צבע על הרחבה
    this.stageLights = [];
    for (const [c, x, k] of [[0xff2e88, -8, 520], [0x19e3ff, 8, 520], [0x9b5bff, 0, 480], [0xffd2a0, -3, 240], [0xffd2a0, 3, 240]]) {
      const sp = new THREE.SpotLight(c, k, 80, 0.7, 0.7, 1.5); sp.position.set(x, 12, LAYOUT.stage.z + 6); sp.target.position.set(x * 0.6, 0, LAYOUT.dance.z + 6); this.add(sp); this.add(sp.target); sp.userData.base = k; this.stageLights.push(sp);
    }
    for (const t of F.towers) { const sp = new THREE.SpotLight(0xfff1d6, 160, 40, 0.8, 0.6, 1.6); sp.position.set(t.position.x, 7, t.position.z); sp.target.position.set(t.position.x * 0.8, 0, t.position.z * 0.8 + 2); this.add(sp); this.add(sp.target); }
    // ─ דמויות ─
    this.npcs = [];
    const mk = (opts, pos, ry, idle = 'idle') => { const n = new NPC(g, opts, pos, ry); n.idleState = idle; n.ch.setState(idle); this.add(n.root); this.npcs.push(n); return n; };
    const dz = LAYOUT.dance;
    this.yoni = mk(FRIENDS.yoni, V3(-6, 0, dz.z + 4), Math.PI, 'dance'); this.yoni.ch.danceStyle = 1;
    this.maya = mk(FRIENDS.maya, V3(-4.8, 0, dz.z + 4.8), Math.PI + 0.5, 'dance'); this.maya.ch.danceStyle = 2;
    this.shachar = mk(FRIENDS.shachar, V3(LAYOUT.rocks.x - 1, 0, LAYOUT.rocks.z + 1.5), -Math.PI / 2, 'sitGround'); this.shachar.ch.smile = true;
    this.dj = mk({ ...randomLook(7), gender: 'm', hair: 4, acc: ['cap'], capColor: '#111', outfit: ['#111', '#222', '#111', '#ff2e88', 0.3, 1] }, V3(0, 1.4, LAYOUT.stage.z - 0.2), 0, 'dance'); this.dj.ch.danceStyle = 3; this.dj.collide = false; this.dj.groundFn = () => 1.4;
    this.bartender = mk({ ...randomLook(11), gender: 'm', acc: ['beard'], outfit: ['#c94f3a', '#2d3e57', '#222', '#fff', 0.3, 1] }, V3(LAYOUT.bar.x - 1.0, 0, LAYOUT.bar.z), Math.PI / 2);
    this.drummer = mk({ ...randomLook(13), gender: 'm', hair: 1, acc: ['beard'], outfit: ['#e8d27c', '#6b5b45', '#5a4632', '#c94f3a', 0.3, 1] }, V3(LAYOUT.drums.x + 3.2, 0, LAYOUT.drums.z), -Math.PI / 2, 'drum');
    for (let i = 0; i < 5; i++) { const a = i / 6 * Math.PI * 2 + 0.6; mk(randomLook(40 + i), V3(LAYOUT.drums.x + Math.cos(a) * 3.3, 0, LAYOUT.drums.z + Math.sin(a) * 3.3), Math.atan2(-Math.cos(a), -Math.sin(a)), 'drum'); }
    this.medic = mk({ ...randomLook(17), gender: 'f', outfit: ['#ff7a1a', '#2d3e57', '#222', '#fff', 0.3, 1] }, V3(LAYOUT.medic.x + 1, 0, LAYOUT.medic.z + 1.2), Math.PI);
    this.strangers = [];
    const sp = [[LAYOUT.chill.x - 2, LAYOUT.chill.z + 1, 'sitGround'], [LAYOUT.chill.x + 2, LAYOUT.chill.z - 1, 'sitGround'], [14, dz.z + 8, 'dance'], [-14, dz.z - 2, 'dance']];
    sp.forEach(([x, z, st], i) => this.strangers.push(mk(randomLook(60 + i), V3(x, 0, z), Math.random() * 6, st)));
    // רוקדים
    this.dancers = [];
    for (let i = 0; i < 74; i++) {
      const near = i < 30; const look = randomLook(100 + i, { detail: near });
      const x = (Math.random() - 0.5) * (near ? 22 : 34), z = dz.z + (near ? -6 + Math.random() * 13 : -12 + Math.random() * 6);
      if (Math.hypot(x + 5.5, z - dz.z - 4) < 2.5) continue;
      const n = mk(look, V3(x, 0, z), Math.PI + (Math.random() - 0.5) * 0.8, 'dance'); n.ch.setShadows(near); n.collide = false; this.dancers.push(n);
    }
    // יושבים בצ'יל ומשוטטים
    this.wanderers = [];
    for (let i = 0; i < 10; i++) { const n = mk(randomLook(200 + i), V3((Math.random() - 0.5) * 60, 0, -10 + Math.random() * 50), 0); n.speed = 1.2; this.wanderers.push(n); }
    for (let i = 0; i < 6; i++) mk(randomLook(220 + i), V3(LAYOUT.chill.x - 4 + i * 1.6, 0, LAYOUT.chill.z + (i % 2) * 3 - 1), Math.random() * 6, 'sitGround');
    this.marker = new Marker(s); this.objects.push(this.marker.sprite);
    // ─ אמביינט ─
    Music.setDiegetic(true, V3(0, 5, LAYOUT.stage.z + 5));
    this.crickets = this.loop('cricketLoop', { vol: 0.5 });
    this.crowdL = this.loop('crowdLoop', { vol: 0.6, pos: V3(0, 1, dz.z), ref: 10 });
    this.windL = this.loop('windLoop', { vol: 0.12 });
    Audio.setSpace('field');
    eng.setGrade('party');
    // ─ אינטראקציות ─
    this._interactions();
  }

  _interactions() {
    const p = this.player, P = CH1.prompts;
    const head = (n) => () => n.root.position.clone().add(V3(0, 1.6, 0));
    const talk = (n, id, extra = {}) => p.addInteract({ getPos: head(n), prompt: P.talk, radius: 2.6, enabled: () => !this.busy && (extra.enabled ? extra.enabled() : true), onUse: () => this.talkTo(n, id, extra) });
    talk(this.yoni, 'yoni_hello', { after: () => { this.flags.metFriends = true; } });
    talk(this.maya, 'maya_talk', { enabled: () => this.flags.metFriends, after: () => this.activities.add('maya') });
    p.addInteract({ getPos: () => this.maya.root.position.clone().add(V3(0, 1.2, 0)), prompt: P.selfie, key: 'F', radius: 2.8, enabled: () => this.flags.metFriends && !this.busy && !this.activities.has('selfie'), onUse: () => {} });
    talk(this.bartender, 'bartender', { onAct: async (a) => { if (a === 'drink') await this.drink(); } });
    talk(this.drummer, 'drummer', { onAct: async (a) => { if (a === 'drum') { this.busy = true; await this.lockedActivity(() => drumGame()); this.activities.add('drum'); this.game.addPuzzle(); } } });
    talk(this.dj, 'dj', { onAct: async (a) => { if (a === 'djgame') { await this.lockedActivity(() => djGame()); this.activities.add('dj'); this.game.addPuzzle(); } } });
    talk(this.medic, 'medic');
    this.strangers.forEach((n, i) => talk(n, 'stranger' + (i + 1), { after: () => this.activities.add('s' + i) }));
    talk(this.shachar, 'shachar_main', { enabled: () => this.stage === 'shachar', onAct: async (a) => { if (a === 'bracelet') await this.braceletMoment(); }, after: () => this.afterShachar() });
    // שינה
    this.sleepIt = p.addInteract({ getPos: () => this.F.ourTent.localToWorld(V3(0.4, 0.2, 0.2)), prompt: P.sleep, radius: 2.4, cone: 0.6, enabled: () => this.stage === 'tent' && !this.busy, onUse: () => this.sleep() });
  }

  async talkTo(n, id, extra = {}) {
    if (this.busy) return; this.busy = true;
    const p = this.player; p.moveLocked = true;
    n.ch.lookAt(this.eng.camera.position); const prevIdle = n.idleState; n.idleState = n.idleState === 'dance' ? 'idle' : n.idleState; n.ch.setState(n.idleState);
    n.face(p.pos);
    const speakers = { yoni: this.yoni.ch, maya: this.maya.ch, shachar: this.shachar.ch, bartender: this.bartender.ch, dj: this.dj.ch, drummer: this.drummer.ch, medic: this.medic.ch, '': n.ch };
    try { await UI.dialog(CH1.dlg, id, speakers, extra.onAct, (tr) => { for (const k in tr) this.game.trust[k] = (this.game.trust[k] || 0) + tr[k]; }); }
    finally { n.idleState = prevIdle; n.ch.setState(prevIdle); n.ch.lookAt(null); n.faceTarget = null; p.moveLocked = false; this.busy = false; Input.lock(); }
    extra.after && extra.after();
  }
  async lockedActivity(fn) { this.busy = true; this.player.locked = true; try { return await fn(); } finally { this.player.locked = false; this.busy = false; } }
  async drink() {
    const vm = this.game.vm; Audio.play('cloth', { vol: 0.4 });
    const cup = new THREE.Mesh(new THREE.CylinderGeometry(0.035, 0.028, 0.1, 14), new THREE.MeshStandardMaterial({ color: 0xf2f2f2, roughness: 0.5 }));
    const juice = new THREE.Mesh(new THREE.CylinderGeometry(0.031, 0.031, 0.06, 14), new THREE.MeshStandardMaterial({ color: 0xb6e04a, roughness: 0.2, emissive: 0x2a3a10 })); juice.position.y = 0.015; cup.add(juice);
    cup.position.set(0, -0.11, 0.035); vm.arms.R.ha.add(cup);
    this.game.chapter.handlesArms = true; vm.setPose('reach', false, 'R');
    await this.wait(1.2); this.player.extraPitch = 0.25; Audio.play('swoosh', { vol: 0.2 }); await this.wait(1.2); this.player.extraPitch = 0;
    vm.arms.R.ha.remove(cup); this.handlesArms = false; this.activities.add('drink');
  }

  start(cp) {
    const p = this.player, g = this.game;
    UI.ctx = { name: g.myName, gender: g.myGender };
    this.stage = 'free';
    if (cp === 'shachar') { this.flags.metFriends = true; this.activities.add('a').add('b'); this.goShachar(); p.place(LAYOUT.rocks.x - 12, LAYOUT.rocks.z + 6, Math.PI / 2 + 0.3); this.begin(); return; }
    if (cp === 'disperse' || cp === 'tent') { g.hasBracelet = true; g.vm.bracelet.visible = true; this.flags.metFriends = true; p.place(0, LAYOUT.dance.z + 10, 0); this.begin(); this.disperse(); return; }
    if (cp === 'free') { p.place(-2, LAYOUT.dance.z + 9, 0.3); this.begin(); UI.objective(CH1.objectives.findFriends); return; }
    this.intro();
  }
  begin() { Music.set('party'); this.eng.set('fade', 0, 0.8); Input.lock(); this.started = true; this.t0 = this.eng.time; this.freeT = performance.now() / 1000; }

  async intro() {
    const e = this.eng, d = this.game.director, L = LAYOUT, p = this.player;
    p.place(-2, L.dance.z + 9, 0.3);
    Music.set('party'); e.set('fade', 1); e.set('fade', 0, 0.5);
    const dz = L.dance.z;
    const shots = [
      { dur: 7, from: { pos: [60, 38, 60], look: [0, 2, -20], fov: 50 }, to: { pos: [34, 18, 30], look: [0, 3, -24], fov: 45 }, ease: 'inOut', hand: 0, at: [{ t: 1.2, fn: () => UI.chapterCard(1) }] }, // crane פנורמי
      { dur: 4.5, from: { pos: [-14, 2.2, dz + 8], look: [-2, 2.5, dz - 4], fov: 42 }, to: { pos: [10, 2.6, dz + 7], look: [2, 2.6, dz - 6], fov: 42 }, hand: 0.4 }, // דולי לאורך הקהל
      { dur: 3.5, from: { pos: [2.5, 3.0, L.stage.z + 3.2], look: [0, 3.0, L.stage.z - 0.2], fov: 32 }, to: { pos: [-2.2, 3.1, L.stage.z + 3.0], look: [0, 3.0, L.stage.z - 0.2], fov: 30 }, dof: { focus: 3.4, aperture: 0.008 }, hand: 0.3 }, // די־ג'יי
      { dur: 2.6, from: { pos: () => this.dancers[1].root.position.clone().add(V3(0.4, 1.62, 1.0)), look: () => this.dancers[1].root.position.clone().add(V3(0, 1.6, 0)), fov: 28 }, dof: { focus: 1.1, aperture: 0.01 }, hand: 0.5 }, // קלוז־אפ פנים
      { dur: 2.6, from: { pos: () => this.dancers[4].root.position.clone().add(V3(-0.5, 1.55, 1.0)), look: () => this.dancers[4].root.position.clone().add(V3(0, 1.62, 0)), fov: 28 }, dof: { focus: 1.1, aperture: 0.01 }, hand: 0.5 },
      { dur: 4.2, from: { pos: () => this.yoni.root.position.clone().add(V3(1.6, 1.5, 2.4)), look: () => this.yoni.root.position.clone().add(V3(-0.6, 1.4, 0)), fov: 38 }, to: { pos: () => this.yoni.root.position.clone().add(V3(0.3, 1.6, 2.6)), look: () => this.maya.root.position.clone().add(V3(0, 1.4, 0)), fov: 36 }, dof: { focus: 2.6, aperture: 0.006 }, hand: 0.4 }, // החברים
      { dur: 3.2, from: { pos: [0, 30, dz + 30], look: [0, 0, dz], fov: 50 }, to: { pos: [p.pos.x, p.pos.y + 1.65, p.pos.z], look: [p.pos.x - Math.sin(p.yaw) * 5, 1.6, p.pos.z - Math.cos(p.yaw) * 5], fov: 72 }, ease: 'inOut', hand: 0 }, // צלילה לגוף ראשון
    ];
    this.dancers[1].ch.smile = this.dancers[4].ch.smile = true;
    await d.play(shots, { skippable: true });
    if (!this.alive) return;
    this.begin();
    UI.objective(CH1.objectives.findFriends);
    this.marker.set(this.yoni.root);
  }

  async braceletMoment() {
    const vm = this.game.vm, p = this.player;
    this.handlesArms = true;
    Music.setIntensity(0); const prevMode = Music.mode;
    Music.setDiegetic(true, V3(0, 5, LAYOUT.stage.z + 5));
    this.crowdL.setVol(0.25, 1);
    vm.setPose('wrist'); p.extraPitch = -0.35;
    await this.wait(0.9);
    vm.bracelet.visible = true; this.game.hasBracelet = true; Audio.play('latch', { vol: 0.6 }); Audio.play('cloth', { vol: 0.4 });
    Music.playTheme(0.4, 'pluck', 0.35);
    await this.wait(3.2);
    vm.setPose('idle'); p.extraPitch = 0; this.handlesArms = false;
  }
  goShachar() { this.stage = 'shachar'; UI.objective(CH1.objectives.shachar); this.marker.set(this.shachar.root); }
  async afterShachar() {
    this.flags.promised = true; this.marker.set(null);
    this.shachar.idleState = 'idle'; this.shachar.ch.setState('idle');
    this.shachar.goTo(LAYOUT.dance.clone().add(V3(-3, 0, 6))).then(() => { this.shachar.idleState = 'dance'; this.shachar.ch.setState('dance'); });
    this.crowdL.setVol(0.6, 1);
    this.game.setCheckpoint('disperse');
    UI.objective(CH1.objectives.explore);
  }
  onEvent(e, d) { if (e === 'disperse' && this.stage !== 'disperse' && this.stage !== 'tent') this.disperse(); if (e === 'sleep' && Net.isHost) { this.sleepers = (this.sleepers || 0) + 1; if (this.sleepers >= Net.count()) this.game.goChapter(2); } }

  async disperse() {
    this.stage = 'disperse'; this.marker.set(null);
    const L = LAYOUT;
    // המוזיקה דועכת, הקהל מתפזר לאוהלים/רכבים/שקי שינה
    Music.set('hope'); Music.setDiegetic(true, V3(0, 5, L.stage.z + 5));
    for (const sl of this.stageLights) sl.intensity = sl.userData.base * 0.35;
    this.crowdL.setVol(0.15, 3);
    this.dancers.forEach((n, i) => { setTimeout(() => { if (!this.alive) return; n.collide = true; n.idleState = 'idle'; const t = i % 3 === 0 ? V3(L.parking.x + (Math.random() - 0.5) * 40, 0, L.parking.z + (Math.random() - 0.5) * 50) : V3(L.camp.x + (Math.random() - 0.5) * 50, 0, L.camp.z + (Math.random() - 0.5) * 26); n.goTo(t, { speed: 1.1 + Math.random() * 0.4 }).then(() => { n.ch.setState(Math.random() < 0.5 ? 'sitGround' : 'idle'); n.idleState = n.ch.state; }); }, i * 180); });
    // החברים מתכנסים
    for (const [n, off] of [[this.yoni, -1], [this.maya, 0], [this.shachar, 1]]) { n.idleState = 'idle'; n.ch.setState('idle'); n.goTo(this.player.pos.clone().add(V3(off * 1.2, 0, -2.2))); }
    await this.wait(5);
    this.busy = true; this.player.moveLocked = true;
    for (const n of [this.yoni, this.maya, this.shachar]) n.ch.lookAt(this.eng.camera.position);
    await UI.lines(CH1.dlg.tent_time.lines, { yoni: this.yoni.ch, maya: this.maya.ch, shachar: this.shachar.ch });
    this.busy = false; this.player.moveLocked = false;
    for (const n of [this.yoni, this.maya, this.shachar]) n.ch.lookAt(null);
    // שחר הולכת לרכב להביא סוודר (זרע לבוקר)
    this.shachar.goTo(V3(L.parking.x + 12, 0, L.parking.z - 10), { speed: 1.3 });
    this.stage = 'tent'; this.game.setCheckpoint('tent');
    UI.objective(CH1.objectives.tent);
    const tentDoor = this.F.ourTent.localToWorld(V3(0, 0, 3));
    this.yoni.goTo(tentDoor.clone().add(V3(-1, 0, 0)), { speed: 1.3 }).then(() => this.yoni.goTo(this.F.ourTent.localToWorld(V3(-0.8, 0, 0.2))).then(() => { this.yoni.idleState = 'lying'; this.yoni.ch.setState('lying'); this.yoni.root.rotation.y = Math.PI; }));
    this.maya.goTo(tentDoor.clone().add(V3(1, 0, 0)), { speed: 1.3 }).then(() => this.maya.goTo(this.F.ourTent.localToWorld(V3(0.0, 0, 0.2))).then(() => { this.maya.idleState = 'sitGround'; this.maya.ch.setState('sitGround'); }));
    this.marker.set(this.yoni.root);
    await this.until(() => this.player.pos.distanceTo(this.F.ourTent.position) < 6);
    this.marker.set(null);
    UI.objective(CH1.objectives.sleep);
    this.busy = true; await UI.lines(CH1.dlg.tent_sleep.lines, { yoni: this.yoni.ch, maya: this.maya.ch }); this.busy = false;
    this.maya.idleState = 'lying'; this.maya.ch.setState('lying');
  }

  async sleep() {
    if (this.sleeping) return; this.sleeping = true; this.busy = true;
    const p = this.player, e = this.eng, vm = this.game.vm;
    p.locked = true; UI.objective(null);
    Audio.play('zip', { vol: 0.6 });
    const bag = this.F.ourTent.localToWorld(V3(0.4, 0, 0.2));
    // שכיבה: המצלמה יורדת לשק השינה ומביטה לתקרת האוהל
    const from = e.camera.position.clone();
    const to = V3(bag.x, bag.y + 0.35, bag.z + 0.4);
    const t0 = e.time; vm.setPose('hidden');
    await this.until(() => { const k = Math.min(1, (e.time - t0) / 2.2); const s = k * k * (3 - 2 * k); p.camOffset.copy(to.clone().sub(from).multiplyScalar(s)); p.pos.y = from.y - p.eyeCur; p.extraPitch = s * 1.25; return k >= 1; });
    Music.set('silence'); this.crickets.setVol(0.25, 2); this.crowdL.setVol(0.05, 2);
    Music.playTheme(0.2, 'piano', 0.18);
    await this.wait(2.5);
    // עין נסגרת – ויניטה שחורה שנסגרת
    e.set('eyelid', 0.55, 0.6); await this.wait(1.4); e.set('eyelid', 0.2, 1.2); await this.wait(1.0); e.set('eyelid', 0.8, 0.5); await this.wait(1.4); e.set('eyelid', 1, 0.6);
    Audio.setMuffle(0.6, 2);
    await this.wait(1.2); e.set('fade', 1, 0.8); await this.wait(2.0);
    this.crickets.setVol(0, 1);
    e.set('eyelid', 0);
    if (Net.online) { Net.event('sleep'); UI.toast(HUD.waitingOthers, 60000); } else this.game.goChapter(2);
  }

  update(dt, t, beat) {
    if (!this.alive) return;
    const p = this.player;
    this.moon.userData.follow(p.pos);
    this.sky.material.uniforms.uTime.value = t;
    const intensity = this.stage === 'disperse' || this.stage === 'tent' ? 0.35 : 1;
    for (const u of this.F.updaters) u(t, beat, intensity);
    for (const n of this.npcs) { const d = n.root.position.distanceTo(p.pos); if (d < 70 || n.target) n.update(dt, beat); }
    for (const sl of this.stageLights) sl.intensity = sl.userData.base * intensity * (0.85 + 0.15 * Math.pow(Math.max(0, Math.sin(beat * Math.PI)), 4));
    this.marker.update(dt, this.eng.camera.position, t);
    // משוטטים
    for (const w of this.wanderers) if (!w.target && Math.random() < dt * 0.2) w.goTo(V3((Math.random() - 0.5) * 70, 0, -20 + Math.random() * 60));
    if (!this.started) return;
    // מציאת החברים
    if (!this.flags.metFriends && p.pos.distanceTo(this.yoni.root.position) < 8 && !this.flags.saw) { this.flags.saw = true; this.yoni.ch.setState('wave'); setTimeout(() => this.yoni.ch.setState('dance'), 2500); }
    if (this.flags.metFriends && !this.flags.freeSet) { this.flags.freeSet = true; this.marker.set(null); UI.objective(CH1.objectives.explore); this.game.setCheckpoint('free'); }
    // ציר זמן קצר: ~20 שניות חופשי → שחר מגיעה אל השחקן; ~45 שניות → פיזור לאוהלים ושינה
    const free = performance.now() / 1000 - this.freeT; // זמן אמיתי – לא תלוי ב-FPS
    if (this.stage === 'free' && free > 20 && !this.flags.promised && !this.busy) {
      this.stage = 'shachar'; UI.objective(CH1.objectives.shachar); this.marker.set(this.shachar.root); this.game.setCheckpoint('shachar');
      this.shachar.idleState = 'idle'; this.shachar.ch.setState('idle');
      const dir = this.shachar.root.position.clone().sub(p.pos).setY(0).normalize();
      this.shachar.goTo(p.pos.clone().addScaledVector(dir, 1.8), { speed: 2.6 }).then(() => this.shachar.face(this.player.pos));
    }
    if ((this.stage === 'free' || this.stage === 'shachar') && ((free > 45 && this.flags.promised) || free > 75) && !this.busy) {
      this.stage = 'pre';
      if (Net.isHost || !Net.online) Net.event('disperse');
    }
    // ריקוד (Q)
    const onFloor = Math.hypot(p.pos.x - LAYOUT.dance.x, p.pos.z - LAYOUT.dance.z) < 16 && this.stage !== 'tent' && this.stage !== 'disperse';
    if (!this.dancing && !this.busy) UI.note(onFloor && !p.focus ? CH1.prompts.danceHint : null);
    if (Input.hit('KeyQ') && !this.busy && Math.hypot(p.pos.x - LAYOUT.dance.x, p.pos.z - LAYOUT.dance.z) < 16 && this.stage !== 'tent') this.toggleDance();
    if (this.dancing) {
      const ph = beat * Math.PI * 2; p.camOffset.y = -Math.abs(Math.sin(ph / 2)) * 0.08; p.extraYaw = Math.sin(ph / 4) * 0.05; p.extraPitch = 0.12 + Math.sin(ph) * 0.02;
      const vm = this.game.vm; vm.arms.L.sh.rotation.x = 2.6 + Math.sin(ph) * 0.25; vm.arms.R.sh.rotation.x = 2.6 - Math.sin(ph) * 0.25;
      this.danceTime = (this.danceTime || 0) + dt; if (this.danceTime > 8) this.activities.add('dance');
      if (Input.hit('Space') || Input.hit('KeyW')) this.toggleDance();
    }
    // סלפי (F)
    if (Input.hit('KeyF') && this.flags.metFriends && !this.busy && !this.activities.has('selfie') && p.pos.distanceTo(this.maya.root.position) < 3) this.doSelfie();
    this.myAnim = this.dancing ? 'dance' : 'idle';
  }
  async toggleDance() {
    const vm = this.game.vm;
    if (!this.dancing) { this.dancing = true; this.player.moveLocked = true; this.handlesArms = true; vm.setPose('climb'); UI.prompt(null); UI.note(CH1.prompts.stopDance); }
    else { this.dancing = false; this.player.moveLocked = false; this.handlesArms = false; vm.setPose('idle'); this.player.camOffset.set(0, 0, 0); this.player.extraYaw = 0; this.player.extraPitch = 0; UI.note(null); }
  }
  async doSelfie() {
    this.busy = true; const p = this.player;
    const d = this.game.director;
    await UI.lines(CH1.dlg.maya_selfie.lines.slice(0, 1), { maya: this.maya.ch });
    // מצלמת סלפי: החברים מסביב, אנחנו בפריים
    const center = p.pos.clone();
    this.yoni.root.position.copy(center).add(V3(-0.7, 0, -0.3)); this.maya.root.position.copy(center).add(V3(0.7, 0, -0.3));
    const meCh = this.game.selfieChar || (this.game.selfieChar = new (await import('../core/character.js')).Character(this.game.myCharacterOpts()));
    meCh.root.position.copy(center); meCh.root.rotation.y = Math.PI + p.yaw + Math.PI; this.add(meCh.root); meCh.smile = true; meCh.setState('idle'); meCh.update(0.016);
    const camPos = center.clone().add(new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw)).multiplyScalar(0.9)).add(V3(0, 1.75, 0));
    for (const n of [this.yoni, this.maya]) { n.ch.setState('idle'); n.root.rotation.y = Math.atan2(camPos.x - n.root.position.x, camPos.z - n.root.position.z); n.ch.smile = true; n.ch.poseOverride = (b) => { b.shR.rotation.z = -2.2; b.elR.rotation.z = 0.8; }; }
    meCh.root.rotation.y = Math.atan2(camPos.x - center.x, camPos.z - center.z);
    const shotP = d.play([{ dur: 60, from: { pos: camPos, look: center.clone().add(V3(0, 1.55, 0)), fov: 55 }, hand: 0.2 }], { letterbox: false });
    p.locked = true;
    await selfie(this.eng.renderer);
    d.stop();
    this.scene.remove(meCh.root);
    for (const n of [this.yoni, this.maya]) { n.ch.poseOverride = null; n.ch.setState(n.idleState); }
    p.locked = false;
    await UI.lines(CH1.dlg.maya_selfie.lines.slice(1), { maya: this.maya.ch });
    this.activities.add('selfie'); this.busy = false; this.game.addPuzzle();
  }
}
