// ═══════════════════════════════════════════════════════════════════
//  Director – קאטסינס קולנועיים: דולי, פאן, קריין, קלוז־אפ, מצלמת יד, חיתוכים, Letterbox ו-DOF
//  shot = { dur, from:{pos,look,fov}, to:{pos,look,fov}, ease, hand(0..1), dof:{focus|follow,aperture}, at:[{t,fn}] }
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';

const EASE = {
  linear: t => t,
  inOut: t => t * t * (3 - 2 * t),
  out: t => 1 - Math.pow(1 - t, 3),
  in: t => t * t * t,
  slowOut: t => 1 - Math.pow(1 - t, 5),
};
const V = (a) => (a instanceof THREE.Vector3 ? a.clone() : new THREE.Vector3(...a));

export class Director {
  constructor(engine) {
    this.eng = engine; this.cam = engine.camera; this.active = false; this.shot = null; this.t = 0;
    this._look = new THREE.Vector3(); this.skipRequested = false;
  }
  /** מנגן רשימת שוטים ברצף. letterbox=true כברירת מחדל */
  play(shots, { letterbox = true, skippable = false } = {}) {
    return new Promise(res => {
      this.queue = shots.slice(); this.active = true; this.done = res; this.letterbox = letterbox; this.skippable = skippable; this.skipRequested = false;
      if (letterbox) this.eng.set('letterbox', 1, 2.5);
      this._next();
    });
  }
  skip() { if (this.active && this.skippable) this.skipRequested = true; }
  _next() {
    if (this.skipRequested) { this.queue.forEach(s => (s.at || []).forEach(a => { if (a.always) a.fn(); })); this.queue.length = 0; }
    const s = this.queue.shift();
    if (!s) { this.stop(); return; }
    this.shot = s; this.t = 0; s._fired = new Set();
    s._from = { pos: V(typeof s.from.pos === 'function' ? s.from.pos() : s.from.pos), look: V(typeof s.from.look === 'function' ? s.from.look() : s.from.look), fov: s.from.fov ?? 45 };
    const to = s.to || s.from;
    s._to = { pos: V(typeof to.pos === 'function' ? to.pos() : to.pos), look: V(typeof to.look === 'function' ? to.look() : to.look), fov: to.fov ?? s._from.fov };
    if (s.dof) this.eng.setDOF(true, s.dof.focus ?? 3, s.dof.aperture ?? 0.006, s.dof.maxblur ?? 0.012); else this.eng.setDOF(false);
    if (s.onStart) s.onStart();
  }
  stop() {
    this.active = false; this.shot = null; this.eng.setDOF(false);
    if (this.letterbox) this.eng.set('letterbox', 0, 2.5);
    const d = this.done; this.done = null; d && d();
  }
  update(dt, time) {
    if (!this.active || !this.shot) return;
    const s = this.shot; this.t += dt;
    const k = Math.min(1, this.t / s.dur), e = (EASE[s.ease] || EASE.inOut)(k);
    for (const a of s.at || []) if (!s._fired.has(a) && this.t >= a.t) { s._fired.add(a); a.fn(); }
    // מעקב אחרי אובייקט נע
    const fromLook = s.from.track ? s.from.track() : s._from.look, toLook = (s.to && s.to.track) ? s.to.track() : s._to.look;
    const fromPos = s.from.follow ? s.from.follow() : s._from.pos, toPos = (s.to && s.to.follow) ? s.to.follow() : s._to.pos;
    this.cam.position.lerpVectors(fromPos, toPos, e);
    this._look.lerpVectors(fromLook, toLook, e);
    // מצלמת יד
    const h = s.hand ?? 0.15;
    if (h > 0) { this.cam.position.x += Math.sin(time * 1.3) * 0.012 * h + Math.sin(time * 3.7) * 0.004 * h; this.cam.position.y += Math.sin(time * 1.7 + 1) * 0.01 * h; }
    this.cam.lookAt(this._look);
    if (s.roll) this.cam.rotateZ(s.roll * (s.rollEase ? e : 1));
    if (s.shake) { const sh = typeof s.shake === 'function' ? s.shake(k) : s.shake; this.cam.rotateX((Math.random() - 0.5) * sh * 0.06); this.cam.rotateY((Math.random() - 0.5) * sh * 0.06); }
    const fov = s._from.fov + (s._to.fov - s._from.fov) * e;
    if (Math.abs(this.cam.fov - fov) > 0.01) { this.cam.fov = fov; this.cam.updateProjectionMatrix(); }
    if (s.dof && s.dof.follow) { const d = this.cam.position.distanceTo(s.dof.follow()); this.eng.bokeh.uniforms.focus.value = d; }
    if (this.t >= s.dur) this._next();
  }
}
export { EASE };
