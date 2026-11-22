// ═══════════════════════════════════════════════════════════════════
//  Player – בקר גוף ראשון: תנועה, התנגשויות, head bob, רעידות (trauma), FOV,
//  "סטמינה" נסתרת שמתבטאת רק דרך נשימה/האטה/טשטוש, פחד → דופק ומנהרה, צעדים לפי משטח.
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Input } from './input.js';
import { Audio, Body } from './audio.js';
import { Settings } from './settings.js';

const _v = new THREE.Vector3();
function noise1(t) { return Math.sin(t * 1.7) * 0.5 + Math.sin(t * 3.1 + 1.3) * 0.3 + Math.sin(t * 7.3 + 2.1) * 0.2; }

/** עולם התנגשויות */
export class World {
  constructor() { this.colliders = []; this.heightFn = () => 0; this.surfaceFn = () => 'dirt'; this.bounds = null; this.ceil = null; }
  height(x, z) { return this.heightFn(x, z); }
  /** דוחף מעגל (x,z,r) מחוץ למכשולים. מחזיר האם התנגש */
  resolve(p, r, feetY, opts = {}) {
    let hit = false;
    for (const c of this.colliders) {
      if (c.disabled) continue;
      if (c.bush && opts.passBush) continue;
      if (c.h !== undefined && c.h < 0.45) continue;
      if (c.y0 !== undefined && feetY > c.y0 + c.h - 0.3) continue;
      if (c.type === 'circle') {
        const dx = p.x - c.x, dz = p.z - c.z, d = Math.hypot(dx, dz), m = r + c.r;
        if (d < m && d > 1e-5) { if (c.bush) continue; p.x = c.x + dx / d * m; p.z = c.z + dz / d * m; hit = true; }
      } else {
        const cs = Math.cos(-(c.rot || 0)), sn = Math.sin(-(c.rot || 0));
        const lx = (p.x - c.x) * cs - (p.z - c.z) * sn, lz = (p.x - c.x) * sn + (p.z - c.z) * cs;
        const hw = c.w / 2, hd = c.d / 2;
        const cx = Math.max(-hw, Math.min(hw, lx)), cz = Math.max(-hd, Math.min(hd, lz));
        let dx = lx - cx, dz = lz - cz, d = Math.hypot(dx, dz);
        if (d < r) {
          if (d < 1e-5) { const px = hw - Math.abs(lx), pz = hd - Math.abs(lz); if (px < pz) { dx = Math.sign(lx) || 1; dz = 0; d = 0; } else { dz = Math.sign(lz) || 1; dx = 0; d = 0; } const nlx = dx ? Math.sign(lx) * (hw + r) : lx, nlz = dz ? Math.sign(lz) * (hd + r) : lz; this._back(p, c, nlx, nlz); }
          else { const k = r / d; this._back(p, c, cx + dx * k, cz + dz * k); }
          hit = true;
        }
      }
    }
    if (this.bounds) { const b = this.bounds; p.x = Math.max(b.minX + r, Math.min(b.maxX - r, p.x)); p.z = Math.max(b.minZ + r, Math.min(b.maxZ - r, p.z)); }
    return hit;
  }
  _back(p, c, lx, lz) { const cs = Math.cos(c.rot || 0), sn = Math.sin(c.rot || 0); p.x = c.x + lx * cs - lz * sn; p.z = c.z + lx * sn + lz * cs; }
  /** האם יש קו ראייה בין שתי נקודות (לא חסום ע"י מכשולים עם cover) */
  los(a, b, ignoreBush = false) {
    const dx = b.x - a.x, dz = b.z - a.z, L = Math.hypot(dx, dz); const steps = Math.ceil(L / 0.5);
    for (let i = 1; i < steps; i++) {
      const t = i / steps, x = a.x + dx * t, z = a.z + dz * t, y = a.y + (b.y - a.y) * t;
      for (const c of this.colliders) {
        if (c.disabled || !c.cover) continue;
        if (c.bush && ignoreBush) continue;
        const top = (c.y0 || this.height(c.x, c.z)) + (c.h || 2);
        if (y > top) continue;
        if (c.type === 'circle') { if (Math.hypot(x - c.x, z - c.z) < c.r * (c.bush ? 0.9 : 1)) return false; }
        else { const cs = Math.cos(-(c.rot || 0)), sn = Math.sin(-(c.rot || 0)); const lx = (x - c.x) * cs - (z - c.z) * sn, lz = (x - c.x) * sn + (z - c.z) * cs; if (Math.abs(lx) < c.w / 2 && Math.abs(lz) < c.d / 2) return false; }
      }
    }
    return true;
  }
  inBush(p) { for (const c of this.colliders) if (c.bush && Math.hypot(p.x - c.x, p.z - c.z) < c.r) return true; return false; }
}

export class Player {
  constructor(camera, world) {
    this.camera = camera; this.world = world;
    this.pos = new THREE.Vector3(); this.vel = new THREE.Vector3();
    this.yaw = 0; this.pitch = 0; this.roll = 0;
    this.eye = 1.65; this.eyeCur = 1.65; this.radius = 0.32;
    this.onGround = true; this.vy = 0;
    this.stamina = 1; this.fear = 0; this.fearTarget = 0; this.exhaust = 0;
    this.trauma = 0; this.shakeT = 0; this.bob = 0; this.bobAmt = 0; this.landShake = 0;
    this.fovBase = 72; this.fov = 72; this.fovKick = 0;
    this.locked = false; this.lookLocked = false; this.moveLocked = false;
    this.speedMul = 1; this.canSprint = true; this.canJump = true;
    this.crouch = false; this.hidden = false; this.running = false;
    this.stepDist = 0; this.interactables = []; this.focus = null;
    this.noclip = false; this.flySpeed = 10; this.jumpMul = 1; this.god = false;
    this.lookLimit = null; // {yaw, pitch, range}
    this.camOffset = new THREE.Vector3(); this.extraPitch = 0; this.extraYaw = 0;
    this.vehicle = null;
    this.breathOverride = null;
    this.walkSpeed = 2.5; this.runSpeed = 5.8; this.crouchSpeed = 1.25;
    this.movedRecently = 0;
  }
  place(x, z, yaw = 0, y) { this.pos.set(x, y ?? this.world.height(x, z), z); this.yaw = yaw; this.pitch = 0; this.vel.set(0, 0, 0); this.vy = 0; }
  addTrauma(a) { this.trauma = Math.min(1, this.trauma + a * (Settings.get('reduceScare') ? 0.5 : 1)); }
  lookAtPoint(p, instant = true) { const dx = p.x - this.pos.x, dz = p.z - this.pos.z, dy = p.y - (this.pos.y + this.eye); this.yaw = Math.atan2(-dx, -dz); this.pitch = Math.atan2(dy, Math.hypot(dx, dz)); }
  addInteract(o) { this.interactables.push(o); return o; }
  removeInteract(o) { const i = this.interactables.indexOf(o); if (i >= 0) this.interactables.splice(i, 1); }
  clearInteract() { this.interactables.length = 0; this.focus = null; }

  update(dt, eng) {
    const sens = 0.0022 * Settings.get('sens');
    if (!this.locked && !this.lookLocked && Input.locked) {
      this.yaw -= Input.mouse.dx * sens;
      this.pitch -= Input.mouse.dy * sens * (Settings.get('invertY') ? -1 : 1);
      this.pitch = Math.max(-1.45, Math.min(1.45, this.pitch));
      if (this.lookLimit) { const L = this.lookLimit; let d = Math.atan2(Math.sin(this.yaw - L.yaw), Math.cos(this.yaw - L.yaw)); d = Math.max(-L.range, Math.min(L.range, d)); this.yaw = L.yaw + d; this.pitch = Math.max(L.pitch - L.prange, Math.min(L.pitch + L.prange, this.pitch)); }
    }
    if (this.vehicle) { this.vehicle.updateDriver(dt, this); this._effects(dt, eng, this.vehicle.speedAbs / 25); return; }
    // ─ תנועה ─
    const ax = this.locked || this.moveLocked ? { x: 0, z: 0 } : Input.axis();
    const wantRun = !this.locked && Input.down('ShiftLeft') && ax.z > 0 && this.canSprint && !this.crouch;
    if (!this.locked && !this.noclip && (Input.hit('ControlLeft') || Input.hit('KeyC'))) this.crouch = !this.crouch;
    if (wantRun) this.crouch = false;
    // סטמינה נסתרת: ריצה מרוקנת; כשנגמרת – האטה + נשימה + טשטוש (בלי מד)
    const running = wantRun && (ax.x || ax.z) && this.stamina > 0.02;
    this.stamina += (running ? -dt / 9 : dt / (this.crouch ? 4 : 6)) ;
    this.stamina = Math.max(0, Math.min(1, this.stamina));
    this.exhaust += ((running && this.stamina < 0.25 ? 1 : running ? 0.4 : 0) - this.exhaust) * Math.min(1, dt * 1.5);
    let speed = this.crouch ? this.crouchSpeed : running ? this.runSpeed * (0.7 + 0.3 * Math.min(1, this.stamina * 3)) : this.walkSpeed;
    speed *= this.speedMul;
    this.running = running;
    const fx = Math.sin(this.yaw), fz = Math.cos(this.yaw);
    const wish = new THREE.Vector3(-fx * ax.z + fz * ax.x, 0, -fz * ax.z - fx * ax.x);
    if (wish.lengthSq() > 0) wish.normalize().multiplyScalar(speed);
    if (this.noclip) {
      const up = (Input.down('Space') ? 1 : 0) - (Input.down('ControlLeft') ? 1 : 0);
      const f = new THREE.Vector3(); this.camera.getWorldDirection(f);
      this.pos.addScaledVector(f, ax.z * this.flySpeed * dt).add(new THREE.Vector3(fz, 0, -fx).multiplyScalar(ax.x * this.flySpeed * dt));
      this.pos.y += up * this.flySpeed * dt;
    } else {
      const acc = this.onGround ? 12 : 3;
      this.vel.x += (wish.x - this.vel.x) * Math.min(1, dt * acc);
      this.vel.z += (wish.z - this.vel.z) * Math.min(1, dt * acc);
      this.pos.x += this.vel.x * dt; this.pos.z += this.vel.z * dt;
      this.world.resolve(this.pos, this.radius, this.pos.y, { passBush: true });
      const gh = this.world.height(this.pos.x, this.pos.z);
      if (!this.locked && this.canJump && this.onGround && Input.hit('Space')) { this.vy = 4.2 * this.jumpMul; this.onGround = false; Audio.play('cloth', { vol: 0.4 }); }
      this.vy -= 13 * dt; this.pos.y += this.vy * dt;
      if (this.pos.y <= gh) {
        if (!this.onGround && this.vy < -3.5) { this.landShake = Math.min(1, -this.vy / 9); Audio.footstep(this.world.surfaceFn(this.pos.x, this.pos.z), 1.2); this.addTrauma(this.landShake * 0.3); }
        this.pos.y = gh; this.vy = 0; this.onGround = true;
      } else if (this.pos.y - gh > 0.25) this.onGround = false; else if (this.vy <= 0) { this.pos.y = gh; this.onGround = true; }
    }
    const hs = Math.hypot(this.vel.x, this.vel.z);
    this.movedRecently = hs > 0.5 ? 1 : Math.max(0, this.movedRecently - dt);
    // ─ צעדים ─
    if (this.onGround && hs > 0.3) {
      this.stepDist += hs * dt;
      const stride = running ? 1.45 : this.crouch ? 0.65 : 0.85;
      if (this.stepDist > stride) { this.stepDist = 0; Audio.footstep(this.world.surfaceFn(this.pos.x, this.pos.z), running ? 1 : this.crouch ? 0.25 : 0.55); if (running && Math.random() < 0.3) Audio.play('cloth', { vol: 0.15, vary: 0.2 }); }
    }
    this.hidden = this.crouch && this.world.inBush(this.pos);
    if (this.hidden && hs > 0.2 && Math.random() < dt * 2) Audio.play('rustle', { vol: 0.3, vary: 0.2 });
    this._effects(dt, eng, hs / this.runSpeed);
    this._interact();
  }

  _effects(dt, eng, speedN) {
    // head bob דינמי
    const run = this.running;
    this.bobAmt += ((this.onGround ? speedN : 0) - this.bobAmt) * Math.min(1, dt * 6);
    this.bob += dt * (run ? 13 : 8.5) * Math.min(1.2, 0.3 + this.bobAmt * 1.4);
    const bobY = Math.abs(Math.sin(this.bob)) * 0.06 * this.bobAmt * (run ? 1.6 : 1);
    const bobX = Math.sin(this.bob) * 0.035 * this.bobAmt * (run ? 1.5 : 1);
    // trauma shake
    this.trauma = Math.max(0, this.trauma - dt * 0.8); this.shakeT += dt * 22;
    const sh = this.trauma * this.trauma;
    const runShake = run ? 0.004 : 0;
    // נשימה (סיבוב קל) ופחד
    this.fear += (this.fearTarget - this.fear) * Math.min(1, dt * 0.8);
    const breath = this.breathOverride ?? Math.min(1, this.exhaust * 0.9 + this.fear * 0.5 + (run ? 0.35 : 0));
    const t = eng.time;
    const breathSway = Math.sin(t * (1.2 + breath * 2)) * 0.004 * (1 + breath * 2);
    this.landShake = Math.max(0, this.landShake - dt * 3);
    this.eyeCur += ((this.crouch ? 1.05 : this.eye) - this.eyeCur) * Math.min(1, dt * 9);
    // מצלמה
    const cam = this.camera;
    const yawFinal = this.yaw + this.extraYaw + noise1(this.shakeT * 0.9) * 0.04 * sh + bobX * 0.15;
    const pitchFinal = this.pitch + this.extraPitch + noise1(this.shakeT + 10) * 0.05 * sh + breathSway - this.landShake * 0.08 + noise1(t * 30) * runShake;
    this.roll += ((this.vehicle ? 0 : -bobX * 0.6 + (this.strafeRoll || 0)) - this.roll) * Math.min(1, dt * 6);
    cam.position.set(this.pos.x + this.camOffset.x, this.pos.y + this.eyeCur - bobY - this.landShake * 0.12 + this.camOffset.y, this.pos.z + this.camOffset.z);
    if (this.vehicle) cam.position.copy(this.vehicle.seatWorld());
    cam.rotation.set(pitchFinal, yawFinal, this.roll + noise1(this.shakeT + 20) * 0.03 * sh, 'YXZ');
    // FOV: ספרינט מרחיב, פחד מצמצם
    const targetFov = this.fovBase + (run ? 7 : 0) - this.fear * 6 + this.fovKick;
    this.fov += (targetFov - this.fov) * Math.min(1, dt * 4);
    this.fovKick *= Math.exp(-dt * 3);
    if (Math.abs(cam.fov - this.fov) > 0.01) { cam.fov = this.fov; cam.updateProjectionMatrix(); }
    // אפקטי פוסט – ריצה ופחד
    if (!this.fxSuspended) {
      eng.fx.radialBlur = (run ? 0.03 + speedN * 0.04 : 0) + this.exhaust * 0.03 + (this.vehicle ? Math.min(0.06, speedN * 0.06) : 0);
      eng.fx.breath = this.exhaust;
      eng.fx.tunnel = Math.max(eng.fxTarget.tunnel ? eng.fx.tunnel : 0, Math.max(0, this.fear - 0.55) * 0.9 + this.exhaust * 0.25);
      eng.fx.blur = Math.max(eng.fxTarget.blur ? eng.fx.blur : 0, this.exhaust > 0.7 ? (this.exhaust - 0.7) * 0.5 : 0);
    }
    Body.update(dt, { breath, heart: Math.max(this.fear, this.exhaust * 0.6), forceBreath: breath > 0.15 });
    // מאזין
    const f = new THREE.Vector3(); cam.getWorldDirection(f);
    Audio.setListener(cam.position, f, new THREE.Vector3(0, 1, 0));
  }

  _interact() {
    if (this.locked) { this.focus = null; return; }
    const cam = this.camera; const f = new THREE.Vector3(); cam.getWorldDirection(f);
    let best = null, bestScore = 0;
    for (const it of this.interactables) {
      if (it.enabled && !it.enabled()) continue;
      const p = it.getPos ? it.getPos() : it.pos;
      _v.copy(p).sub(cam.position); const d = _v.length();
      if (d > (it.radius || 2.2)) continue;
      const dot = _v.normalize().dot(f);
      if (dot < (it.cone ?? 0.8)) continue;
      const score = dot - d * 0.05;
      if (score > bestScore) { bestScore = score; best = it; }
    }
    this.focus = best;
    if (best && (Input.hit('KeyE') || (best.click && Input.mouse.clicked))) best.onUse && best.onUse(best);
  }
}

// ═══════════════ רכב – נהיגה ארקייד בגוף ראשון ═══════════════
export class Vehicle {
  constructor(model, world, scene) {
    this.model = model; this.world = world; this.scene = scene;
    this.speed = 0; this.speedAbs = 0; this.steer = 0; this.heading = model.rotation.y; this.lightsOn = false;
    this.maxSpeed = model.userData.type === 'bike' ? 26 : model.userData.type === 'van' ? 18 : 22;
    this.radius = (model.userData.len || 4.5) * 0.42;
    this.engine = null; this.disabled = false;
    // פנסים (SpotLights) – כבויים בהתחלה
    this.lights = [];
    const len = model.userData.len || 4.5;
    for (const s of model.userData.type === 'bike' ? [0] : [0.55, -0.55]) {
      const L = new THREE.SpotLight(0xfff2d8, 0, 45, 0.45, 0.5, 1.5); L.position.set(len / 2, 0.75, s); L.target.position.set(len / 2 + 10, 0, s); model.add(L, L.target); this.lights.push(L);
    }
  }
  seatWorld() { return this.model.localToWorld(this.model.userData.seat.clone().add(new THREE.Vector3(0, this.model.userData.type === 'bike' ? 0 : 0.0, 0))); }
  setLights(on) { this.lightsOn = on; for (const L of this.lights) L.intensity = on ? 60 : 0; for (const m of this.model.userData.headMats || []) m.emissiveIntensity = on ? 4 : 0.1; Audio.play('click', { vol: 0.6 }); }
  enter(player) {
    this.driver = player; player.vehicle = this; player.yaw = this.heading - Math.PI / 2; player.pitch = -0.05;
    this.engine = Audio.engine(); Audio.play('engineStart', { vol: 0.6 }); Audio.play('doorSlam', { vol: 0.5, delay: 0.05 });
  }
  exit(player) {
    player.vehicle = null; this.driver = null; if (this.engine) { this.engine.stop(); this.engine = null; }
    const side = new THREE.Vector3(0, 0, -1.6).applyAxisAngle(new THREE.Vector3(0, 1, 0), this.heading);
    player.pos.copy(this.model.position).add(side); player.pos.y = this.world.height(player.pos.x, player.pos.z);
    this.world.resolve(player.pos, player.radius, player.pos.y);
    Audio.play('doorSlam', { vol: 0.5 });
  }
  updateDriver(dt, player) {
    const ax = player.locked || this.disabled ? { x: 0, z: 0 } : Input.axis();
    const brake = Input.down('Space');
    const target = ax.z * this.maxSpeed * (ax.z < 0 ? 0.35 : 1);
    const accel = ax.z !== 0 ? (Math.sign(target - this.speed) === Math.sign(this.speed) || this.speed === 0 ? 7 : 14) : 4;
    this.speed += Math.sign(target - this.speed) * Math.min(Math.abs(target - this.speed), accel * dt);
    if (brake) this.speed *= Math.exp(-dt * 3);
    this.steer += ((-ax.x) * 0.6 - this.steer) * Math.min(1, dt * 5);
    this.heading += this.steer * this.speed * dt * 0.12;
    const fwd = new THREE.Vector3(Math.cos(this.heading), 0, -Math.sin(this.heading));
    const m = this.model;
    const prev = m.position.clone();
    m.position.addScaledVector(fwd, this.speed * dt);
    const p = new THREE.Vector3(m.position.x, 0, m.position.z);
    if (this.world.resolve(p, this.radius * 0.6, m.position.y)) { const impact = Math.abs(this.speed); if (impact > 4) { player.addTrauma(Math.min(0.8, impact / 20)); Audio.play('thud', { vol: Math.min(1, impact / 15) }); } this.speed *= -0.25; m.position.x = p.x; m.position.z = p.z; }
    // גובה ושיפוע לפי השטח
    const front = m.position.clone().addScaledVector(fwd, 1.6), back = m.position.clone().addScaledVector(fwd, -1.6);
    const hf = this.world.height(front.x, front.z), hb = this.world.height(back.x, back.z);
    m.position.y = (hf + hb) / 2;
    m.rotation.set(0, this.heading, 0); m.rotateZ(Math.atan2(hf - hb, 3.2));
    this.speedAbs = Math.abs(this.speed);
    for (const w of m.userData.wheels || []) w.children[0] && (w.rotation.z -= this.speed * dt / 0.35);
    if (m.userData.steering) m.userData.steering.rotation.x = this.steer * 1.5;
    if (this.engine) this.engine.set(this.speedAbs / this.maxSpeed, Math.abs(ax.z));
    // רעידות מהשטח
    player.addTrauma(this.speedAbs > 6 ? dt * 0.15 * (this.speedAbs / this.maxSpeed) : 0);
    // מבט הנהג – יחסי לרכב (עם חופש סיבוב ראש)
    const rel = Math.atan2(Math.sin(player.yaw - (this.heading - Math.PI / 2)), Math.cos(player.yaw - (this.heading - Math.PI / 2)));
    const lim = 1.6; const clamped = Math.max(-lim, Math.min(lim, rel));
    player.yaw = this.heading - Math.PI / 2 + clamped;
    if (!player.locked && Input.hit('KeyL')) this.setLights(!this.lightsOn);
    player.pos.copy(m.position);
  }
}
