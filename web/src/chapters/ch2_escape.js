// ═══════════════════════════════════════════════════════════════════
//  פרק 2 – הבוקר, הבריחה והתפיסה
//  אין טקסט על המסך בזמן הבריחה. הכול דרך סביבה, סאונד ומצלמה.
//  מסלולים: רגלית (פרדס/ואדי) · רכב (דרך העפר) · מסתור (שיח/מבנה). התפיסה קורית תמיד, מותאמת למסלול.
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Sky } from 'three/examples/jsm/objects/Sky.js';
import { Chapter } from '../core/game.js';
import { buildFestival, LAYOUT } from '../world/festival.js';
import * as P from '../world/props.js';
import { Materials } from '../world/materials.js';
import { FX } from '../world/fx.js';
import { NPC, sunRig, FleeCrowd, FRIENDS } from './common.js';
import { Character } from '../core/character.js';
import { Vehicle } from '../core/player.js';
import { Audio, Music, Body } from '../core/audio.js';
import { UI } from '../core/ui.js';
import { Input } from '../core/input.js';
import { Net } from '../core/net.js';
import { Settings } from '../core/settings.js';
import { CH2 } from '../config/texts.he.js';

const V3 = (x, y, z) => new THREE.Vector3(x, y, z);
const scare = () => !Settings.get('reduceScare');

class Terrorist {
  constructor(ch, pos, ry) {
    this.c = new Character({ terrorist: true, skin: '#a4704a', detail: true });
    this.c.root.position.copy(pos); this.c.root.rotation.y = ry; this.pos = this.c.root.position; this.active = true;
    this.fireT = 2 + Math.random() * 3; this.path = null; this.speed = 1.3; this.aim = null; this.burst = 0;
    ch.add(this.c.root);
  }
}

export class Chapter2 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['wake', 'escape', 'capture-foot', 'capture-car', 'capture-hide']; this.timeOfDay = 6.5; this.danger = 0; }
  async build() {
    const g = this.game, s = this.scene, eng = this.eng;
    const F = this.F = buildFestival({ dawn: true });
    this.add(F.root);
    g.world.colliders = F.colliders; g.world.heightFn = (x, z) => F.terrain.heightAt(x, z);
    g.world.surfaceFn = (x, z) => (Math.random() < 0.4 ? 'gravel' : 'dirt');
    g.world.bounds = { minX: -240, maxX: 240, minZ: -240, maxZ: 240 };
    // ─ שמיים של בוקר מוקדם: שמש נמוכה במזרח ─
    const sky = this.skyObj = new Sky(); sky.scale.setScalar(4000); this.add(sky);
    const u = sky.material.uniforms; u.turbidity.value = 9; u.rayleigh.value = 2.4; u.mieCoefficient.value = 0.008; u.mieDirectionalG.value = 0.86;
    this.sunDir = new THREE.Vector3(); this.setTime(6.5);
    s.environment = Materials.env('dawn'); s.environmentIntensity = 0.55;
    s.fog = new THREE.FogExp2(0xc9a48a, 0.0065);
    this.hemi = new THREE.HemisphereLight(0xb8c4e0, 0x6a5040, 0.75); this.add(this.hemi);
    this.sun = sunRig(s, { color: 0xffb27a, intensity: 2.4, dir: [this.sunDir.x, this.sunDir.y, this.sunDir.z], size: 50 }); this.objects.push(this.sun, this.sun.target);
    eng.setGrade('dawn');
    // ─ שאריות הלילה: כוסות, תיקים, נעליים, כיסא הפוך ─
    for (let i = 0; i < 60; i++) { const x = (Math.random() - 0.5) * 60, z = -30 + Math.random() * 90; const k = i % 4; const o = k === 0 ? P.cyl(0.04, 0.03, 0.1, P.M.std(0xf2f2f2, 0.6), 8) : k === 1 ? P.rbox(0.3, 0.2, 0.15, P.M.std([0xc2501f, 0x2b7bd6, 0x2fa36b][i % 3], 0.8), 0.04) : k === 2 ? P.rbox(0.1, 0.08, 0.26, P.M.std(0xe9e4da, 0.8), 0.03) : P.buildCampChair(0x2a6b4f); o.position.set(x, F.terrain.heightAt(x, z) + (k === 3 ? 0 : 0.05), z); o.rotation.set(k === 3 ? Math.PI / 2 : Math.random(), Math.random() * 6, 0); this.add(o); }
    // ─ FX ─
    this.fx = new FX(s); this.objects.push(this.fx.smoke.points, this.fx.glow.points, this.fx.flashLight);
    this.fx.addMotes(V3(0, 0, 0), 700, 30, 0xffd8a0); this.objects.push(this.fx.motes);
    // עמודי עשן במערב ובצפון (לא קרובים מדי)
    for (const [x, z, sz] of [[-200, -60, 14], [-170, 40, 10], [-120, -150, 12], [-230, 120, 16], [-60, -170, 9]]) this.fx.column(V3(x, F.terrain.heightAt(x, z), z), { size: sz, rate: 3, color: 0x2e2a28 });
    // רכבים בוערים בכניסה המערבית
    this.burning = [];
    for (const [x, z, r] of [[-86, 16, 0.4], [-96, 22, 2.1], [-75, 30, 1.2]]) { const c = P.buildCar(['sedan', 'pickup', 'hatch'][this.burning.length], 0x333333, { burned: true }); c.position.set(x, F.terrain.heightAt(x, z), z); c.rotation.y = r; this.add(c); this.fx.column(V3(x, F.terrain.heightAt(x, z) + 1, z), { size: 2.5, rate: 8, color: 0x1c1a19, fire: true, height: 0.8 }); g.world.colliders.push({ type: 'box', x, z, w: 4.5, d: 1.9, h: 1.5, rot: -r, cover: true }); }
    const fireL = new THREE.PointLight(0xff7a2a, 40, 30, 2); fireL.position.set(-86, 2, 20); this.add(fireL); this.fireL = fireL;
    // כתמי דם (רחוקים, חלקיים, לא גרפיים) וחורי כדורים על המבנה/רכבים
    for (const [x, z, sz] of [[-60, 24, 1.4], [-48, 36, 1.1], [-70, 44, 1.8], [-30, 60, 1.0], [-88, 30, 1.6]]) { const st = P.buildStain('blood', sz, x * z); st.position.set(x, F.terrain.heightAt(x, z) + 0.03, z); this.add(st); }
    for (const [x, z] of [[-75, 20], [-90, 34], [-40, 70]]) { const st = P.buildStain('soot', 3, x); st.position.set(x, F.terrain.heightAt(x, z) + 0.025, z); this.add(st); }
    const holes = P.buildBulletHoles(14, 2.4); holes.position.set(LAYOUT.container.x, 1.4, LAYOUT.container.z - 0.17); holes.rotation.y = Math.PI; this.add(holes);
    // שלט יציאה נפול – רמז ויזואלי למזרח
    const sign = new THREE.Group(); const post = P.cyl(0.05, 0.05, 2.2, P.M.std(0x777777, 0.4, 0.6), 6); post.position.y = 1.1; sign.add(post);
    const st = Materials.canvasTex(256, 96, (c, W, H) => { c.fillStyle = '#1f6b3a'; c.fillRect(0, 0, W, H); c.strokeStyle = '#fff'; c.lineWidth = 5; c.strokeRect(6, 6, W - 12, H - 12); c.fillStyle = '#fff'; c.font = 'bold 44px Heebo, Arial'; c.textAlign = 'center'; c.direction = 'rtl'; c.fillText('יציאה  ⟵', W / 2, 64); });
    const board = new THREE.Mesh(new THREE.PlaneGeometry(1.4, 0.52), new THREE.MeshStandardMaterial({ map: st, side: THREE.DoubleSide })); board.position.set(0, 2.0, 0); sign.add(board);
    sign.position.set(30, F.terrain.heightAt(30, 44), 46); sign.rotation.set(0, Math.PI / 2, 0.35); this.add(sign);
    // ─ החברים ─
    this.yoni = new NPC(g, FRIENDS.yoni, F.ourTent.localToWorld(V3(-0.8, 0, 0.6)), 0); this.add(this.yoni.root);
    this.maya = new NPC(g, FRIENDS.maya, F.ourTent.localToWorld(V3(0.6, 0, 0.8)), 0); this.add(this.maya.root);
    this.shachar = new NPC(g, FRIENDS.shachar, V3(LAYOUT.parking.x + 26, 0, LAYOUT.parking.z - 20), Math.PI / 2); this.add(this.shachar.root); this.shachar.root.visible = false;
    for (const n of [this.yoni, this.maya]) n.ch.panic = true;
    // ─ אמביינט ─
    Audio.setSpace('field');
    this.windL = this.loop('windLoop', { vol: 0.35 });
    this.sirenL = null;
    // מחבלים
    this.terrorists = [];
    this.crowd = null;
    this.vehicles = F.cars.map(c => new Vehicle(c, g.world, s));
    this._carInteract();
  }
  setTime(h) { // 5.5..9
    this.timeOfDay = h; const el = THREE.MathUtils.degToRad(THREE.MathUtils.clamp((h - 6.2) * 14 + 3, -2, 60)); const az = THREE.MathUtils.degToRad(95);
    this.sunDir.setFromSphericalCoords(1, Math.PI / 2 - el, az);
    this.skyObj.material.uniforms.sunPosition.value.copy(this.sunDir);
    if (this.sun) { this.sun.userData.dir.copy(this.sunDir); this.sun.intensity = 1.2 + Math.sin(el) * 3; }
  }
  _carInteract() {
    const p = this.player;
    for (const v of this.vehicles) {
      p.addInteract({ getPos: () => v.model.localToWorld(V3(0, 1.2, 0.9)), prompt: 'להיכנס לרכב', radius: 3.2, cone: 0.5, enabled: () => this.phase === 'escape' && !p.vehicle, onUse: () => this.enterCar(v) });
    }
  }
  enterCar(v) {
    const p = this.player; if (v.model.userData.collider) v.model.userData.collider.disabled = true;
    v.enter(p); this.route = 'car'; this.carV = v; this.carT = 0; UI.prompt(null);
  }

  start(cp) {
    this.phase = 'wake';
    if (cp && cp.startsWith('capture')) { this.phase = 'escape'; this.begin(); this.startEscape(true); this.capture(cp.split('-')[1]); return; }
    if (cp === 'escape') { this.startEscape(true); this.begin(); return; }
    this.wake();
  }
  begin() { this.eng.set('fade', 0, 0.8); Input.lock(); }

  // ───────────── התעוררות ─────────────
  async wake() {
    const p = this.player, e = this.eng, vm = this.game.vm, F = this.F;
    const bag = F.ourTent.localToWorld(V3(0.4, 0, 0.2));
    p.place(bag.x, bag.z, Math.PI); p.locked = true; this.noPrompts = true;
    p.camOffset.set(0, -1.3, 0); p.extraPitch = 1.2; vm.setPose('hidden', true);
    e.set('fade', 1); e.set('eyelid', 1); e.set('blur', 1);
    this.yoni.ch.setState('crouch'); this.maya.ch.setState('cower');
    await this.wait(0.8);
    // אזעקה חזקה + נפילות. העין נפתחת לרעש
    this.sirenL = this.loop('sirenLoop', { vol: scare() ? 0.9 : 0.5, pos: V3(-40, 15, 30), ref: 60, rolloff: 0.2, reverb: 0.6 });
    Audio.play('boomFar', { vol: 0.9, delay: 0.3 });
    e.set('fade', 0, 1.2); e.set('eyelid', 0.75, 0.9);
    p.fearTarget = 0.7; p.breathOverride = 0.6;
    await this.wait(1.2); UI.bark('', CH2.subs.alarm, 2600);
    e.set('eyelid', 0.95, 2); await this.wait(0.5); e.set('eyelid', 0.3, 0.8); await this.wait(1.0);
    UI.bark('yoni', CH2.subs.yoni1, 2200); this.yoni.ch.talking = true;
    e.set('eyelid', 0, 1.2); e.set('blur', 0.3, 0.4);
    await this.wait(1.4); this.yoni.ch.talking = false;
    // רקטות ויירוטים בשמיים
    for (let i = 0; i < 6; i++) setTimeout(() => this.alive && this.fx.rocket(V3(-260 + Math.random() * 40, 5, -100 + Math.random() * 200), V3(-60 + Math.random() * 120, 120 + Math.random() * 40, -60 + Math.random() * 120), 5 + Math.random() * 2, Math.random() < 0.8, (pt) => { Audio.play('boomFar', { pos: pt, vol: 0.9, ref: 80, rolloff: 0.3 }); }), i * 900);
    // קימה: המצלמה עולה מהשק
    const t0 = e.time; e.set('blur', 0, 0.3);
    await this.until(() => { const k = Math.min(1, (e.time - t0) / 1.6), s2 = k * k * (3 - 2 * k); p.camOffset.y = -1.3 * (1 - s2) - 0.55 * s2; p.extraPitch = 1.2 * (1 - s2); return k >= 1; });
    UI.bark('maya', CH2.subs.maya1, 2200); this.maya.ch.talking = true;
    Audio.play('boom', { vol: scare() ? 0.8 : 0.4, delay: 0.6 }); setTimeout(() => this.alive && (p.addTrauma(0.5), Body.ring(0.4)), 700);
    await this.wait(2.2); this.maya.ch.talking = false;
    UI.bark('yoni', CH2.subs.yoni2, 2600); this.yoni.ch.talking = true; await this.wait(2.6); this.yoni.ch.talking = false;
    p.camOffset.set(0, 0, 0); p.extraPitch = 0; p.locked = false; this.noPrompts = false; vm.setPose('idle'); p.breathOverride = null;
    // החברים יוצאים מהאוהל – השחקן אחריהם
    this.yoni.goTo(F.ourTent.localToWorld(V3(-1, 0, 4)), { run: true }); this.maya.goTo(F.ourTent.localToWorld(V3(1, 0, 4.5)), { run: true });
    await this.until(() => p.pos.distanceTo(F.ourTent.position) > 2.6, 25);
    this.startEscape(false);
  }

  // ───────────── הבריחה ─────────────
  startEscape(fromCp) {
    const p = this.player, F = this.F, g = this.game;
    this.phase = 'escape'; this.escapeT = 0; this.danger = 0; this.route = 'foot'; this.hideT = 0; this.capturing = false;
    g.setCheckpoint('escape');
    if (fromCp) { const door = F.ourTent.localToWorld(V3(0, 0, 3.4)); p.place(door.x, door.z, 0); this.yoni.root.position.copy(door).add(V3(-2, 0, 2)); this.maya.root.position.copy(door).add(V3(2, 0, 2.5)); if (!this.sirenL) this.sirenL = this.loop('sirenLoop', { vol: 0.5, pos: V3(-40, 15, 30), ref: 60, rolloff: 0.2 }); }
    p.fearTarget = 0.6;
    Music.set('tension', 0.6);
    // המון של מאות אנשים, כל אחד לכיוון אחר
    if (this.crowd) this.crowd.dispose();
    const goals = [V3(120, 0, 40), V3(110, 0, -40), V3(60, 0, 140), V3(-20, 0, 160), V3(150, 0, 100), LAYOUT.orchard, V3(LAYOUT.parking.x, 0, LAYOUT.parking.z)];
    this.crowd = new FleeCrowd(g, { count: 240, center: V3(0, 0, 30), spread: 70, goals, threats: this.terrorists });
    this.add(this.crowd.group);
    this.crowdPanic = this.loop('crowdPanic', { vol: 0.55, reverb: 0.4 });
    // שחר מרחוק – רואים אותה ואז היא נבלעת בהמון
    this.seeShachar();
    // המחבלים מגיעים מהמערב ומהצפון
    for (const t of this.terrorists) this.scene.remove(t.c.root);
    this.terrorists.length = 0;
    const spawns = [[-92, 18, 1.4], [-88, 26, 1.6], [-80, 10, 1.3], [-40, -40, 2.4], [-30, -48, 2.2], [-100, 50, 1.0], [-70, 70, 0.9]];
    for (const [x, z, ry] of spawns) { const t = new Terrorist(this, V3(x, this.F.terrain.heightAt(x, z), z), ry); t.goal = V3(x + 60 + Math.random() * 40, 0, z + 20 + Math.random() * 30); this.terrorists.push(t); }
    this.crowd.threats = this.terrorists;
    // פיקאפ עם מחבלים בכביש המערבי
    if (!this.pickup) { this.pickup = P.buildCar('pickup', 0xe8e8e8, { bulletHoles: 0 }); this.add(this.pickup); }
    this.pickup.position.set(-110, F.terrain.heightAt(-110, 14), 14); this.pickup.rotation.y = 0.05; this.pickupT = 0;
    // יוני ומאיה רצים לחניה (ואז נבלעים)
    this.yoni.goTo(V3(LAYOUT.parking.x + 20, 0, LAYOUT.parking.z), { run: true }).then(() => { this.yoni.root.visible = false; });
    this.maya.goTo(V3(LAYOUT.parking.x + 24, 0, LAYOUT.parking.z + 6), { run: true }).then(() => { this.maya.root.visible = false; });
    setTimeout(() => this.alive && this.phase === 'escape' && UI.bark('yoni', CH2.subs.yoni3, 1800), 1500);
    setTimeout(() => this.alive && this.phase === 'escape' && UI.bark('', CH2.subs.shout2, 1800), 5000);
    this.nextScare = 12 + Math.random() * 8;
    this.begin();
  }
  async seeShachar() {
    const s = this.shachar, p = this.player;
    s.root.visible = true; const dir = new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw));
    const at = p.pos.clone().addScaledVector(dir, 45).add(V3(-15, 0, 0)); s.root.position.set(at.x, 0, at.z); s.ch.setState('idle'); s.face(p.pos);
    await this.wait(1.8);
    s.ch.setState('wave'); UI.bark('shachar', CH2.subs.shachar_far, 1600); Audio.play('shoutFar', { pos: s.root.position, vol: 0.7, ref: 10 });
    await this.wait(1.6);
    // גל של אנשים חוצה ביניהם – והיא נעלמת
    s.goTo(s.root.position.clone().add(V3(-25, 0, 18)), { run: true });
    await this.wait(2.2); s.root.visible = false; s.target = null;
  }

  // ───────────── מחבלים: ירי ואיום ─────────────
  updateTerrorists(dt, t) {
    const p = this.player, pp = p.pos, W = this.game.world;
    const eye = V3(pp.x, pp.y + (p.crouch ? 0.9 : 1.5), pp.z);
    let exposure = 0;
    for (const tr of this.terrorists) {
      if (!tr.active) continue;
      const c = tr.c; const d = tr.pos.distanceTo(pp);
      // הליכה איטית קדימה
      if (tr.goal && !this.game.enemiesDisabled) { const v = V3(tr.goal.x - tr.pos.x, 0, tr.goal.z - tr.pos.z); if (v.length() > 1) { v.normalize(); tr.pos.addScaledVector(v, tr.speed * dt); c.setState('walk', tr.speed); } else c.setState('idle'); tr.pos.y = W.height(tr.pos.x, tr.pos.z); }
      const head = tr.pos.clone().add(V3(0, 1.55, 0));
      const canSee = !this.game.enemiesDisabled && d < 70 && !p.hidden && W.los(head, eye);
      // פונה לשחקן כשרואה, אחרת לכיוון ההמון
      const look = canSee ? pp : (tr.goal || pp); const yaw = Math.atan2(look.x - tr.pos.x, look.z - tr.pos.z); let dy = yaw - c.root.rotation.y; dy = Math.atan2(Math.sin(dy), Math.cos(dy)); c.root.rotation.y += dy * Math.min(1, dt * 3);
      c.aim = canSee; c.update(dt);
      // ירי במטחים
      tr.fireT -= dt;
      if (tr.fireT <= 0 && !this.game.enemiesDisabled) {
        tr.fireT = 1.8 + Math.random() * 3.5;
        const n = 3 + Math.floor(Math.random() * 6);
        const muzzle = head.clone().add(new THREE.Vector3(Math.sin(c.root.rotation.y), -0.15, Math.cos(c.root.rotation.y)).multiplyScalar(0.7));
        Audio.burst(muzzle, eye, n, 0.09);
        for (let i = 0; i < n; i++) setTimeout(() => { if (!this.alive) return; this.fx.muzzle(muzzle, new THREE.Vector3(Math.sin(c.root.rotation.y), 0, Math.cos(c.root.rotation.y))); if (canSee && d < 45) this.nearMiss(eye, d); }, i * 90);
      }
      if (canSee) { const k = (1 - d / 70) * (p.running ? 0.7 : 1) * (p.vehicle ? (p.vehicle.speedAbs > 8 ? 0.35 : 0.8) : 1) * (p.crouch ? 0.55 : 1); exposure += k; }
    }
    // סכנה נסתרת – בלי מד, רק אפקטים: דופק, מנהרה, פגיעות קרובות יותר
    const inc = exposure > 0 ? exposure * dt * 0.16 : -dt * 0.07;
    this.danger = THREE.MathUtils.clamp(this.danger + inc, 0, 1);
    p.fearTarget = 0.55 + this.danger * 0.45;
    Music.setIntensity(0.55 + this.danger * 0.45);
    if (this.danger >= 1 && !p.god) { this.danger = 0; this.phase = 'dead'; this.game.fail().then(() => {}); }
  }
  nearMiss(eye, d) {
    const p = this.player;
    const spread = 1.5 + (1 - this.danger) * 5;
    const hit = V3(eye.x + (Math.random() - 0.5) * spread, 0, eye.z + (Math.random() - 0.5) * spread); hit.y = this.game.world.height(hit.x, hit.z);
    this.fx.impact(hit); Audio.play('impact', { pos: hit, vol: 0.7, ref: 4 });
    if (Math.random() < 0.35) Audio.play('ricochet', { pos: hit, vol: 0.6, ref: 5 });
    if (Math.random() < 0.5) Audio.play('crack', { vol: 0.35 + this.danger * 0.4 });
    p.addTrauma(0.08 + this.danger * 0.15);
    if (hit.distanceTo(eye) < 2.5) { Body.ring(0.15); this.game.vm.setPose('shield'); setTimeout(() => this.alive && this.game.vm.setPose('idle'), 500); }
  }
  async jumpscareAmbient() {
    if (!scare()) return;
    const p = this.player, r = Math.random();
    const side = new THREE.Vector3(Math.cos(p.yaw), 0, -Math.sin(p.yaw)).multiplyScalar(Math.random() < 0.5 ? 1 : -1);
    if (r < 0.4) { // צל שרץ קרוב
      const fig = new Character({ skin: '#5b3826', outfit: ['#222', '#222', '#111', '#222', 1, 1], detail: false });
      const start = p.pos.clone().addScaledVector(side, 6).add(new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw)).multiplyScalar(4));
      fig.root.position.copy(start); fig.setState('run', 7); this.add(fig.root);
      Audio.play('rustle', { pos: start, vol: 1 }); Audio.footstep('gravel', 1, start);
      const dir = side.clone().negate(); fig.root.rotation.y = Math.atan2(dir.x, dir.z);
      const t0 = this.eng.time; await this.until(() => { fig.root.position.addScaledVector(dir, 0.16); fig.root.position.y = this.game.world.height(fig.root.position.x, fig.root.position.z); fig.update(0.016); return this.eng.time - t0 > 1.4; });
      this.scene.remove(fig.root);
    } else if (r < 0.75) { // מטח פתאומי קרוב מאחור
      const pos = p.pos.clone().add(new THREE.Vector3(Math.sin(p.yaw), 0, Math.cos(p.yaw)).multiplyScalar(14));
      Audio.burst(pos, p.pos, 6, 0.07, { vol: 1 }); p.addTrauma(0.35); Body.ring(0.3);
    } else { // דמות במרחק על הרכס
      const pos = p.pos.clone().add(new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw)).multiplyScalar(55)); pos.y = this.game.world.height(pos.x, pos.z);
      const tr = new Terrorist(this, pos, p.yaw); tr.c.setState('idle'); tr.goal = null; tr.fireT = 99; this.terrorists.push(tr);
      setTimeout(() => { if (!this.alive) return; tr.active = false; this.scene.remove(tr.c.root); }, 3500);
    }
  }

  // ───────────── התפיסה (ג'אמפסקייר) ─────────────
  async capture(route) {
    if (this.capturing) return; this.capturing = true; this.phase = 'capture';
    const p = this.player, e = this.eng, vm = this.game.vm, g = this.game, W = g.world;
    g.setCheckpoint('capture-' + route);
    this.noPrompts = true; UI.prompt(null);
    const calm = !scare();
    // 1) ביטחון שווא – דרך הסביבה בלבד: מוזיקה נרגעת, נשימה מאטה, ציפור, רוח
    if (this.crowd) { this.crowd.active = false; this.crowd.group.visible = false; }
    if (this.crowdPanic) this.crowdPanic.setVol(0.05, 2);
    if (this.sirenL) this.sirenL.setVol(0.08, 3);
    for (const t of this.terrorists) { t.active = false; t.c.root.visible = false; }
    Music.set('silence'); this.windL.setVol(0.55, 2);
    p.fearTarget = 0.1; p.breathOverride = 0.5; this.danger = 0;
    if (route !== 'car') p.locked = true;
    await this.wait(1.6); p.breathOverride = 0.25;
    Audio.play('bird', { pos: p.pos.clone().add(V3(8, 4, -6)), vol: 0.5 });
    await this.wait(2.2); p.breathOverride = 0.1;
    Audio.play('bird', { pos: p.pos.clone().add(V3(-6, 5, -10)), vol: 0.4, rate: 1.1 });
    await this.wait(2.0);
    // 2) שקט מוחלט
    this.windL.setVol(0, 0.3); p.breathOverride = 0; Audio.setMuffle(0.0);
    await this.wait(calm ? 1.2 : 0.9);
    // 3) המכה – לפי המסלול
    p.locked = true;
    const fwd = new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw));
    const camPos = e.camera.position.clone();
    const tr = new Character({ terrorist: true, skin: '#a4704a', detail: true });
    this.add(tr.root);
    const hit = (vol = 1) => { if (calm) { Audio.play('thud', { vol: 0.35 }); return; } Audio.play('stinger', { vol: vol, reverb: 0.3 }); Audio.play('punch', { vol: 0.9 }); e.set('flash', 0.6); e.set('flash', 0, 4); p.addTrauma(1); };
    if (route === 'car') {
      const v = this.carV || p.vehicle;
      // עצירה פתאומית, שמשה נשברת, יד מוציאה את השחקן
      const pos = v ? v.model.position.clone().addScaledVector(new THREE.Vector3(Math.cos(v.heading), 0, -Math.sin(v.heading)), 3.2) : camPos.clone().addScaledVector(fwd, 2);
      tr.root.position.set(pos.x, W.height(pos.x, pos.z), pos.z); tr.root.rotation.y = Math.atan2(camPos.x - pos.x, camPos.z - pos.z); tr.aim = true; tr.update(0.016);
      if (v) { v.disabled = true; v.speed = 0; if (v.engine) v.engine.set(0, 0); }
      Audio.play('thud', { vol: 1 }); p.addTrauma(0.9);
      await this.wait(calm ? 1.2 : 0.25);
      hit(1); Audio.play('glass', { vol: calm ? 0.4 : 1 }); this.glassOverlay(true);
      if (v && v.model.userData.windshield) v.model.userData.windshield.visible = false;
      await this.wait(0.7);
      // יד מושכת החוצה – המצלמה נמשכת הצידה ונופלת
      const side = v ? new THREE.Vector3(0, 0, -1).applyAxisAngle(V3(0, 1, 0), v.heading) : V3(1, 0, 0);
      if (v) { v.exit(p); }
      const start = e.camera.position.clone();
      await this.camMove(start, start.clone().addScaledVector(side, 1.6).add(V3(0, -1.1, 0)), 0.5, (k) => { e.camera.rotateZ(k * 0.9); });
      this.glassOverlay(false);
    } else if (route === 'hide') {
      // פנים צמודות לפתח, יד תופסת
      const pos = camPos.clone().addScaledVector(fwd, calm ? 1.6 : 0.62); pos.y = W.height(pos.x, pos.z);
      tr.root.position.copy(pos); tr.root.rotation.y = Math.atan2(camPos.x - pos.x, camPos.z - pos.z);
      tr.setState('crouch'); tr.poseOverride = (b) => { b.shR.rotation.set(-1.6, 0, -0.2); b.elR.rotation.x = -0.2; b.neck.rotation.x = 0.1; };
      tr.setHold(null); tr.update(0.016);
      if (calm) { e.set('fade', 0.4); e.set('fade', 0, 0.6); }
      Audio.play('rustle', { vol: 1, pos: pos });
      hit(1);
      await this.wait(0.9);
      tr.poseOverride = (b) => { b.shR.rotation.set(-1.9, 0, -0.2); b.elR.rotation.x = -0.6; };
      Audio.play('cloth', { vol: 1 }); p.addTrauma(0.6);
      await this.camMove(e.camera.position.clone(), e.camera.position.clone().addScaledVector(fwd, 0.5).add(V3(0, 0.6, 0)), 0.4);
    } else {
      // ברגל: מכה מאחור, האופק מתהפך, קלוז־אפ
      const behind = camPos.clone().addScaledVector(fwd, -0.9); behind.y = W.height(behind.x, behind.z);
      tr.root.position.copy(behind); tr.root.rotation.y = Math.atan2(fwd.x, fwd.z); tr.update(0.016);
      hit(1); Body.ring(calm ? 0.2 : 0.7); Audio.setMuffle(0.5, 0.1);
      // האופק מתהפך – נפילה
      const start = e.camera.position.clone(); const ground = W.height(start.x, start.z);
      await this.camMove(start, V3(start.x + fwd.x * 0.8, ground + 0.25, start.z + fwd.z * 0.8), calm ? 1.2 : 0.45, (k) => { e.camera.rotateZ(k * 1.4); e.camera.rotateX(-k * 0.6); });
      Audio.play('thud', { vol: 0.9 }); p.addTrauma(0.7);
      await this.wait(0.7);
      // מתהפכים – רואים אותו מעל (קלוז־אפ)
      const cp = e.camera.position.clone();
      tr.root.position.copy(cp).addScaledVector(fwd, 0.55); tr.root.position.y = ground; tr.root.rotation.y = Math.atan2(-fwd.x, -fwd.z);
      tr.poseOverride = (b) => { b.spine.rotation.x = 0.7; b.neck.rotation.x = 0.4; }; tr.update(0.016);
      const lookAt = tr.root.position.clone().add(V3(0, 1.45, 0));
      this.camLook(cp, lookAt, calm ? 1.2 : 0.35);
      if (!calm) { Audio.play('stinger', { vol: 0.6 }); }
      await this.wait(1.2);
    }
    Audio.setMuffle(0.35, 0.3);
    // 4) מרים את השחקן, אגרוף ישיר (נקודת מבט), חיתוך מהיר לשחור
    const c0 = e.camera.position.clone();
    const face = tr.root.position.clone().add(V3(0, 1.62, 0)).addScaledVector(new THREE.Vector3(Math.sin(tr.root.rotation.y), 0, Math.cos(tr.root.rotation.y)), 0.1);
    tr.setHold(null);
    tr.setState('idle'); tr.poseOverride = (b) => { b.shL.rotation.set(-1.4, 0, 0.3); b.elL.rotation.x = -0.5; b.shR.rotation.set(-0.6, 0, -0.2); b.elR.rotation.x = -1.8; };
    const liftTo = face.clone().addScaledVector(new THREE.Vector3(Math.sin(tr.root.rotation.y), 0, Math.cos(tr.root.rotation.y)), 0.7).add(V3(0, -0.05, 0));
    await this.camMove(c0, liftTo, calm ? 1.0 : 0.55, () => { e.camera.lookAt(face); });
    Audio.play('cloth', { vol: 0.8 });
    await this.wait(calm ? 1.2 : 0.6);
    // אגרוף – היד הימנית נעה ישר למצלמה
    const t0 = e.time;
    await this.until(() => { const k = Math.min(1, (e.time - t0) / (calm ? 0.6 : 0.18)); tr.poseOverride = (b) => { b.shL.rotation.set(-1.4, 0, 0.3); b.elL.rotation.x = -0.5; b.shR.rotation.set(-0.6 - k * 1.0, 0, -0.2 + k * 0.25); b.elR.rotation.x = -1.8 + k * 1.75; }; tr.update(0.016); e.camera.lookAt(face); return k >= 1; });
    Audio.play('punch', { vol: calm ? 0.4 : 1 }); Audio.play('thud', { vol: calm ? 0.3 : 0.9 });
    e.set('fade', 1); e.set('hit', 0); p.addTrauma(1);
    Body.ring(calm ? 0.3 : 1); Audio.setMuffle(0.85, 0.05);
    // 5) מסך שחור, צלילי רקע מבולבלים, פייד לפרק הבא
    this.scene.remove(tr.root);
    if (this.sirenL) this.sirenL.stop(1); if (this.crowdPanic) this.crowdPanic.stop(1);
    p.breathOverride = 0.8; p.fearTarget = 1;
    await this.wait(1.2);
    Audio.play('shoutFar', { vol: 0.25, rate: 0.8 }); await this.wait(1.4); Audio.play('engineStart', { vol: 0.3 }); await this.wait(1.6); Audio.play('shoutFar', { vol: 0.2, rate: 0.7 });
    await this.wait(2.2);
    p.breathOverride = null; p.fearTarget = 0; Audio.setMuffle(0, 2);
    this.game.goChapter(3);
  }
  camMove(from, to, dur, extra) {
    const e = this.eng, t0 = e.time; this.camOverride = true;
    return this.until(() => { const k = Math.min(1, (e.time - t0) / dur), s = k * k * (3 - 2 * k); e.camera.position.lerpVectors(from, to, s); if (extra) extra(s); return k >= 1; });
  }
  camLook(from, at, dur) { const e = this.eng; e.camera.position.copy(from); e.camera.lookAt(at); }
  glassOverlay(on) {
    if (on) {
      const c = document.createElement('canvas'); c.width = innerWidth; c.height = innerHeight; c.id = 'glassFx'; c.style.cssText = 'position:fixed;inset:0;z-index:15;pointer-events:none;opacity:.85';
      const g = c.getContext('2d'); const cx = c.width * (0.4 + Math.random() * 0.2), cy = c.height * 0.4;
      g.strokeStyle = 'rgba(255,255,255,0.75)'; g.lineWidth = 1.3;
      for (let i = 0; i < 26; i++) { const a = Math.random() * Math.PI * 2; let x = cx, y = cy; g.beginPath(); g.moveTo(x, y); for (let k = 0; k < 8; k++) { x += Math.cos(a + (Math.random() - 0.5) * 0.6) * (40 + Math.random() * 80); y += Math.sin(a + (Math.random() - 0.5) * 0.6) * (40 + Math.random() * 80); g.lineTo(x, y); } g.stroke(); }
      for (let r = 30; r < 400; r += 50 + Math.random() * 40) { g.beginPath(); for (let a = 0; a < Math.PI * 2; a += 0.3) g.lineTo(cx + Math.cos(a) * r * (0.8 + Math.random() * 0.4), cy + Math.sin(a) * r * (0.8 + Math.random() * 0.4)); g.closePath(); g.globalAlpha = 0.35; g.stroke(); g.globalAlpha = 1; }
      document.body.appendChild(c);
    } else { const c = document.getElementById('glassFx'); if (c) c.remove(); }
  }

  restart(cp) { // חזרה לצ'קפוינט אחרי פגיעה – בונה מחדש את רצף הבריחה
    const p = this.player; if (p.vehicle) p.vehicle.exit(p);
    for (const v of this.vehicles) { v.disabled = false; }
    this.phase = 'escape'; this.startEscape(true);
  }

  update(dt, t, beat) {
    if (!this.alive) return;
    const p = this.player;
    this.sun.userData.follow(p.pos);
    for (const u of this.F.updaters) u(t, beat, 0);
    this.fx.update(dt, t, this.eng.camera);
    this.fireL.intensity = 30 + Math.sin(t * 13) * 8 + Math.sin(t * 7) * 6;
    for (const n of [this.yoni, this.maya, this.shachar]) if (n.root.visible) n.update(dt, beat);
    if (this.capturing && this.camOverride) { /* המצלמה בשליטת הקאטסין */ }
    if (this.phase !== 'escape') return;
    this.escapeT += dt;
    if (this.crowd) this.crowd.update(dt, t);
    this.updateTerrorists(dt, t);
    // פיקאפ נוסע לאט פנימה
    if (this.pickup) { this.pickupT += dt; if (this.pickupT < 30) { this.pickup.position.x += dt * 2.2; this.pickup.position.y = this.F.terrain.heightAt(this.pickup.position.x, this.pickup.position.z); } }
    // ג'אמפסקיירים אווירתיים מדי פעם
    this.nextScare -= dt; if (this.nextScare <= 0) { this.nextScare = 18 + Math.random() * 14; this.jumpscareAmbient(); }
    // רקטות ממשיכות מדי פעם
    if (Math.random() < dt * 0.15) this.fx.rocket(V3(-260, 5, -100 + Math.random() * 200), V3(-60 + Math.random() * 160, 110 + Math.random() * 50, -80 + Math.random() * 160), 5.5, Math.random() < 0.85, (pt) => Audio.play('boomFar', { pos: pt, vol: 0.8, ref: 80, rolloff: 0.3 }));
    // ─ טריגרים לתפיסה לפי מסלול ─
    if (p.vehicle) {
      this.route = 'car'; this.carT += dt;
      const far = p.pos.x > 70 || p.pos.distanceTo(V3(0, 0, 40)) > 110;
      if (far || this.carT > 40) { this.capture('car'); return; }
    } else {
      // מסתור: שיח (כפוף) או בתוך המבנה
      const inBox = Math.abs(p.pos.x - LAYOUT.container.x) < 2.6 && p.pos.z > LAYOUT.container.z + 0.3 && p.pos.z < LAYOUT.container.z + 4;
      if (p.hidden || inBox) { this.hideT += dt; this.danger = Math.max(0, this.danger - dt * 0.2); if (this.hideT > 18) { this.capture('hide'); return; } }
      else this.hideT = Math.max(0, this.hideT - dt * 2);
      // רגלית: הגעה לפרדס/ואדי או התרחקות גדולה
      const orchard = p.pos.x > LAYOUT.orchard.x - 6 && Math.abs(p.pos.z - LAYOUT.orchard.z) < 40;
      const ditch = p.pos.distanceTo(LAYOUT.ditch) < 16;
      if (orchard || ditch || p.pos.distanceTo(V3(0, 0, 40)) > 125) { this.capture('foot'); return; }
    }
    if (this.escapeT > 270) this.capture(p.vehicle ? 'car' : 'foot');
  }
  onEvent() {}
}
