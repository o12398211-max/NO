// ═══════════════════════════════════════════════════════════════════
//  כלים משותפים לפרקים: NPC עם תנועה, סמן מטרה עדין, המון נמלט (מאות אנשים), תאורה
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Character, randomLook } from '../core/character.js';
import { Audio } from '../core/audio.js';

const _v = new THREE.Vector3();

export class NPC {
  constructor(game, opts, pos, ry = 0) {
    this.game = game; this.ch = new Character(opts); this.root = this.ch.root;
    this.root.position.copy(pos); this.root.rotation.y = ry;
    this.target = null; this.speed = 1.4; this.run = false; this.onArrive = null; this.path = [];
    this.idleState = 'idle'; this.ch.setState('idle');
    this.faceTarget = null; this.groundFn = (x, z) => game.world.height(x, z); this.collide = true;
    this.step = 0;
  }
  goTo(p, { run = false, speed } = {}) {
    return new Promise(res => { this.target = p.clone ? p.clone() : new THREE.Vector3(p.x, 0, p.z); this.run = run; this.speed = speed ?? (run ? 4.8 : 1.4); this.onArrive = res; });
  }
  async follow(points, opts) { for (const p of points) await this.goTo(p, opts); }
  face(p) { this.faceTarget = p; }
  update(dt, beat) {
    const r = this.root;
    if (this.target) {
      _v.set(this.target.x - r.position.x, 0, this.target.z - r.position.z);
      const d = _v.length();
      if (d < 0.4) { this.target = null; this.ch.setState(this.idleState); const f = this.onArrive; this.onArrive = null; f && f(); }
      else {
        _v.normalize();
        r.position.x += _v.x * this.speed * dt; r.position.z += _v.z * this.speed * dt;
        if (this.collide) { const p = { x: r.position.x, z: r.position.z }; this.game.world.resolve(p, 0.3, r.position.y, { passBush: true }); r.position.x = p.x; r.position.z = p.z; }
        const yaw = Math.atan2(_v.x, _v.z); let dy = yaw - r.rotation.y; dy = Math.atan2(Math.sin(dy), Math.cos(dy)); r.rotation.y += dy * Math.min(1, dt * 8);
        this.ch.setState(this.run ? 'run' : this.sneak ? 'sneak' : 'walk', this.speed);
        this.step += this.speed * dt; if (this.step > (this.run ? 1.4 : 0.8) && this.footsteps) { this.step = 0; Audio.footstep(this.surface || 'dirt', this.run ? 0.7 : 0.35, r.position); }
      }
    } else if (this.faceTarget) {
      const yaw = Math.atan2(this.faceTarget.x - r.position.x, this.faceTarget.z - r.position.z); let dy = yaw - r.rotation.y; dy = Math.atan2(Math.sin(dy), Math.cos(dy)); r.rotation.y += dy * Math.min(1, dt * 4);
    }
    r.position.y = this.groundFn(r.position.x, r.position.z);
    this.ch.update(dt, beat);
  }
}

/** סמן מטרה עדין: אור רך שנראה רק מרחוק ונעלם כשמתקרבים */
export class Marker {
  constructor(scene) {
    const tex = (() => { const c = document.createElement('canvas'); c.width = c.height = 64; const g = c.getContext('2d'); const gr = g.createRadialGradient(32, 32, 0, 32, 32, 32); gr.addColorStop(0, 'rgba(255,230,180,1)'); gr.addColorStop(0.25, 'rgba(255,200,120,0.5)'); gr.addColorStop(1, 'rgba(255,180,90,0)'); g.fillStyle = gr; g.fillRect(0, 0, 64, 64); const t = new THREE.CanvasTexture(c); return t; })();
    this.sprite = new THREE.Sprite(new THREE.SpriteMaterial({ map: tex, transparent: true, depthTest: false, depthWrite: false, opacity: 0, toneMapped: false }));
    this.sprite.scale.setScalar(0.6); this.sprite.renderOrder = 999; scene.add(this.sprite);
    this.target = null; this.op = 0;
  }
  set(t) { this.target = t; }
  update(dt, camPos, time) {
    let want = 0;
    if (this.target) {
      const p = this.target.isVector3 ? this.target : this.target.getWorldPosition(_v);
      this.sprite.position.set(p.x, p.y + (this.target.isVector3 ? 0 : 2.3) + Math.sin(time * 2) * 0.05, p.z);
      const d = camPos.distanceTo(this.sprite.position);
      want = THREE.MathUtils.clamp((d - 6) / 10, 0, 0.75);
      this.sprite.scale.setScalar(0.35 + d * 0.012);
    }
    this.op += (want - this.op) * Math.min(1, dt * 3); this.sprite.material.opacity = this.op;
  }
  dispose() { this.sprite.parent && this.sprite.parent.remove(this.sprite); }
}

/** אור ירח/שמש עם צל שעוקב אחרי השחקן */
export function sunRig(scene, { color = 0xffffff, intensity = 1, dir = [-0.5, 1, 0.3], size = 50, mapSize = 2048 } = {}) {
  const L = new THREE.DirectionalLight(color, intensity);
  L.castShadow = true; L.shadow.mapSize.set(mapSize, mapSize); L.shadow.bias = -0.0004; L.shadow.normalBias = 0.03;
  Object.assign(L.shadow.camera, { left: -size, right: size, top: size, bottom: -size, near: 1, far: 400 });
  L.userData.dir = new THREE.Vector3(...dir).normalize();
  scene.add(L, L.target);
  L.userData.follow = (p) => { const snap = 2; const x = Math.round(p.x / snap) * snap, z = Math.round(p.z / snap) * snap; L.target.position.set(x, 0, z); L.position.set(x + L.userData.dir.x * 150, L.userData.dir.y * 150, z + L.userData.dir.z * 150); };
  return L;
}

// ═══════════════ המון נמלט – מאות אנשים, כל אחד לכיוון אחר ═══════════════
// התנהגויות: בורח לנקודת מטרה אישית, רץ לרכב, מתחבא בשיח, עוצר ומחפש מישהו, נופל וקם, מושך חבר ביד
export class FleeCrowd {
  constructor(game, { count = 240, center, spread = 90, goals = [], threats = [], avoidFn } = {}) {
    this.game = game; this.people = []; this.goals = goals; this.threats = threats; this.group = new THREE.Group();
    this.center = center.clone(); this.spread = spread; this.active = true; this.avoidFn = avoidFn;
    for (let i = 0; i < count; i++) {
      const near = i < 70;
      const c = new Character({ ...randomLook(i + 300), detail: near });
      c.setShadows(i < 30); c.panic = true;
      const p = { ch: c, pos: new THREE.Vector3(), dir: new THREE.Vector3(), speed: 0, mode: 'flee', t: 0, goal: null, wait: 0, buddy: null, phase: Math.random() * 10 };
      this._spawn(p, true);
      this.group.add(c.root); this.people.push(p);
    }
    // זוגות – אחד מושך את השני ביד
    for (let i = 0; i < 24; i += 2) { const a = this.people[i], b = this.people[i + 1]; b.buddy = a; b.pos.copy(a.pos).add(new THREE.Vector3(0.7, 0, 0.4)); }
  }
  _spawn(p, initial) {
    const W = this.game.world;
    const pl = this.game.player.pos;
    let x, z;
    if (initial) { x = this.center.x + (Math.random() - 0.5) * this.spread * 2; z = this.center.z + (Math.random() - 0.5) * this.spread * 2; }
    else { const a = Math.random() * Math.PI * 2, r = 35 + Math.random() * 30; x = pl.x + Math.cos(a) * r; z = pl.z + Math.sin(a) * r; }
    if (this.avoidFn && this.avoidFn(x, z)) { x += 8; z += 8; }
    p.pos.set(x, W.height(x, z), z);
    // מטרה אישית: מתוך רשימת יעדים + פיזור גדול, או כיוון אקראי הרחק מהאיום
    const r = Math.random();
    if (r < 0.62 && this.goals.length) { const g = this.goals[Math.floor(Math.random() * this.goals.length)]; p.goal = new THREE.Vector3(g.x + (Math.random() - 0.5) * 60, 0, g.z + (Math.random() - 0.5) * 60); p.mode = 'flee'; }
    else if (r < 0.75) { p.mode = 'hide'; p.goal = new THREE.Vector3(x + (Math.random() - 0.5) * 30, 0, z + (Math.random() - 0.5) * 30); }
    else if (r < 0.85) { p.mode = 'search'; p.wait = 2 + Math.random() * 4; p.goal = new THREE.Vector3(x + (Math.random() - 0.5) * 40, 0, z + (Math.random() - 0.5) * 40); }
    else { const a = Math.random() * Math.PI * 2; p.mode = 'flee'; p.goal = new THREE.Vector3(x + Math.cos(a) * 150, 0, z + Math.sin(a) * 150); }
    p.speed = p.mode === 'search' ? 2.2 : 4.2 + Math.random() * 2.3;
    p.t = 0; p.fallen = 0;
  }
  update(dt, t) {
    if (!this.active) return;
    const pl = this.game.player.pos, W = this.game.world;
    for (const p of this.people) {
      const c = p.ch; p.t += dt;
      // נשאר בצפיפות סביב השחקן: מי שמתרחק – חוזר מכיוון אחר
      const dpl = Math.hypot(p.pos.x - pl.x, p.pos.z - pl.z);
      if (dpl > 85) { this._spawn(p, false); }
      if (p.buddy && p.mode !== 'down') { // נמשך ביד ע"י חבר
        _v.copy(p.buddy.pos).sub(p.pos); _v.y = 0; const d = _v.length();
        if (d > 0.9) { _v.normalize(); p.pos.addScaledVector(_v, Math.min(d - 0.8, (p.buddy.speed + 0.5) * dt)); }
        c.root.rotation.y = Math.atan2(_v.x, _v.z); c.setState('run', p.buddy.speed);
        c.poseOverride = (b) => { b.shR.rotation.x = -1.3; b.elR.rotation.x = -0.1; };
      } else if (p.fallen > 0) { // נפל – קם
        p.fallen -= dt; c.setState(p.fallen > 0.8 ? 'lying' : 'crouch');
        if (p.fallen <= 0) c.setState('run', p.speed);
      } else if (p.mode === 'hide' && p.goal && Math.hypot(p.goal.x - p.pos.x, p.goal.z - p.pos.z) < 1) {
        c.setState('cower'); if (p.t > 8 + Math.random() * 6) { p.mode = 'flee'; p.goal.set(p.pos.x + (Math.random() - 0.5) * 200, 0, p.pos.z + (Math.random() - 0.5) * 200); p.t = 0; }
      } else if (p.mode === 'search' && p.wait > 0) {
        p.wait -= dt; c.setState('idle'); c.poseOverride = (b, tt) => { b.neck.rotation.y = Math.sin(tt * 2.2 + p.phase) * 0.9; b.shR.rotation.z = -0.4; };
        if (p.wait <= 0) { c.poseOverride = null; p.mode = 'flee'; }
      } else if (p.goal) {
        _v.set(p.goal.x - p.pos.x, 0, p.goal.z - p.pos.z); const d = _v.length();
        if (d < 1) { if (p.mode !== 'hide') { p.mode = Math.random() < 0.4 ? 'search' : 'flee'; p.wait = 2 + Math.random() * 3; p.goal.set(p.pos.x + (Math.random() - 0.5) * 120, 0, p.pos.z + (Math.random() - 0.5) * 120); } }
        else {
          _v.normalize();
          // סטייה מאיומים (מחבלים) – בורחים מהם
          for (const th of this.threats) { if (!th.active) continue; const tx = p.pos.x - th.pos.x, tz = p.pos.z - th.pos.z, td = Math.hypot(tx, tz); if (td < 40) { _v.x += tx / td * (40 - td) / 25; _v.z += tz / td * (40 - td) / 25; } }
          _v.x += Math.sin(t * 1.3 + p.phase) * 0.25; _v.normalize();
          p.dir.lerp(_v, Math.min(1, dt * 4));
          p.pos.x += p.dir.x * p.speed * dt; p.pos.z += p.dir.z * p.speed * dt;
          const q = { x: p.pos.x, z: p.pos.z }; if (W.resolve(q, 0.3, p.pos.y, { passBush: true })) { p.goal.x += (Math.random() - 0.5) * 20; p.goal.z += (Math.random() - 0.5) * 20; } p.pos.x = q.x; p.pos.z = q.z;
          let yaw = Math.atan2(p.dir.x, p.dir.z), dy = yaw - c.root.rotation.y; dy = Math.atan2(Math.sin(dy), Math.cos(dy)); c.root.rotation.y += dy * Math.min(1, dt * 7);
          c.setState(p.speed > 3 ? 'run' : 'walk', p.speed); c.poseOverride = null;
          if (Math.random() < dt * 0.012 && dpl < 50) p.fallen = 1.6 + Math.random();
        }
      }
      p.pos.y = W.height(p.pos.x, p.pos.z);
      c.root.position.copy(p.pos);
      // LOD: עדכון אנימציה לרחוקים בתדירות נמוכה
      if (dpl < 40 || Math.random() < 0.35) c.update(dpl < 40 ? dt : dt / 0.35);
      c.root.visible = dpl < 90;
    }
  }
  dispose() { this.group.parent && this.group.parent.remove(this.group); }
}

/** בונה דמות חבר/ה מהקבוצה */
export const FRIENDS = {
  shachar: { skin: '#e2b48f', hair: 2, hairColor: '#3b2517', outfit: ['#f6e6c8', '#3a4a6a', '#e9e4da', '#ff6b8b', 0.0, 1], gender: 'f', acc: ['bracelet', 'flower'], eyes: '#5a3a1a' },
  yoni: { skin: '#c99169', hair: 1, hairColor: '#1d1410', outfit: ['#2fa36b', '#3a3f45', '#2a2a2a', '#ffd25a', 0.3, 0.35], gender: 'm', acc: ['headband'], build: 1.05, height: 1.04 },
  maya: { skin: '#f1d1b5', hair: 3, hairColor: '#a8743d', outfit: ['#ff4f8b', '#232629', '#cfcac0', '#39e0ff', 0.0, 1], gender: 'f', acc: ['glasses', 'scarf'] },
};
