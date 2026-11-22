// ═══════════════════════════════════════════════════════════════════
//  FX – עמודי עשן, אבק פגיעה, הבזקי לוע, שובלי רקטות ויירוטים בשמיים, חלקיקי אבק באוויר
//  מבוסס Points עם שיידר (מעט draw calls) – מתאים ל-60FPS
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';

let smokeTex = null;
function getSmokeTex() {
  if (smokeTex) return smokeTex;
  const c = document.createElement('canvas'); c.width = c.height = 128; const g = c.getContext('2d');
  for (let i = 0; i < 26; i++) { const x = 64 + (Math.random() - 0.5) * 50, y = 64 + (Math.random() - 0.5) * 50, r = 18 + Math.random() * 26; const gr = g.createRadialGradient(x, y, 0, x, y, r); gr.addColorStop(0, 'rgba(255,255,255,0.22)'); gr.addColorStop(1, 'rgba(255,255,255,0)'); g.fillStyle = gr; g.fillRect(0, 0, 128, 128); }
  const gr = g.createRadialGradient(64, 64, 20, 64, 64, 64); gr.addColorStop(0, 'rgba(0,0,0,0)'); gr.addColorStop(1, 'rgba(0,0,0,1)'); g.globalCompositeOperation = 'destination-out'; g.fillStyle = gr; g.fillRect(0, 0, 128, 128);
  smokeTex = new THREE.CanvasTexture(c); return smokeTex;
}

/** מערכת חלקיקים כללית: כל חלקיק {p, v, life, max, size, grow, color, alpha} */
export class Particles {
  constructor(max = 2000, { additive = false, tex = getSmokeTex(), depthWrite = false } = {}) {
    this.max = max; this.list = [];
    const geo = new THREE.BufferGeometry();
    this.pos = new Float32Array(max * 3); this.col = new Float32Array(max * 4); this.siz = new Float32Array(max); this.rot = new Float32Array(max);
    geo.setAttribute('position', new THREE.BufferAttribute(this.pos, 3)); geo.setAttribute('color', new THREE.BufferAttribute(this.col, 4)); geo.setAttribute('size', new THREE.BufferAttribute(this.siz, 1)); geo.setAttribute('rot', new THREE.BufferAttribute(this.rot, 1));
    this.mat = new THREE.ShaderMaterial({
      uniforms: { uTex: { value: tex }, uScale: { value: 500 }, fogColor: { value: new THREE.Color() }, fogDensity: { value: 0 } },
      vertexShader: `attribute float size; attribute float rot; attribute vec4 color; varying vec4 vC; varying float vR; varying float vFog; uniform float uScale; uniform float fogDensity;
        void main(){ vC = color; vR = rot; vec4 mv = modelViewMatrix * vec4(position,1.); gl_PointSize = size * uScale / -mv.z; gl_Position = projectionMatrix * mv; float d = -mv.z; vFog = 1.0 - exp(-fogDensity*fogDensity*d*d); }`,
      fragmentShader: `uniform sampler2D uTex; uniform vec3 fogColor; varying vec4 vC; varying float vR; varying float vFog;
        void main(){ vec2 uv = gl_PointCoord - 0.5; float c = cos(vR), s = sin(vR); uv = mat2(c,-s,s,c)*uv + 0.5; vec4 t = texture2D(uTex, uv); vec3 col = mix(vC.rgb, fogColor, vFog*0.85); gl_FragColor = vec4(col, t.a * vC.a); }`,
      transparent: true, depthWrite, blending: additive ? THREE.AdditiveBlending : THREE.NormalBlending,
    });
    this.points = new THREE.Points(geo, this.mat); this.points.frustumCulled = false; this.points.renderOrder = 5;
  }
  emit(o) { if (this.list.length >= this.max) this.list.shift(); this.list.push({ p: o.p.clone(), v: o.v ? o.v.clone() : new THREE.Vector3(), life: 0, max: o.life || 3, size: o.size || 1, grow: o.grow || 1, c: new THREE.Color(o.color ?? 0x888888), a: o.alpha ?? 0.6, drag: o.drag ?? 0.98, rise: o.rise ?? 0, r: Math.random() * 6, rs: (Math.random() - 0.5) * 0.6, fadeIn: o.fadeIn ?? 0.1 }); }
  update(dt, scene, cam) {
    if (scene && scene.fog && scene.fog.density !== undefined) { this.mat.uniforms.fogColor.value.copy(scene.fog.color); this.mat.uniforms.fogDensity.value = scene.fog.density; }
    if (cam) this.mat.uniforms.uScale.value = window.innerHeight / (2 * Math.tan(cam.fov * Math.PI / 360));
    let n = 0;
    for (let i = this.list.length - 1; i >= 0; i--) {
      const q = this.list[i]; q.life += dt;
      if (q.life > q.max) { this.list.splice(i, 1); continue; }
      q.v.multiplyScalar(Math.pow(q.drag, dt * 60)); q.v.y += q.rise * dt; q.p.addScaledVector(q.v, dt); q.r += q.rs * dt;
    }
    for (const q of this.list) {
      const k = q.life / q.max;
      this.pos[n * 3] = q.p.x; this.pos[n * 3 + 1] = q.p.y; this.pos[n * 3 + 2] = q.p.z;
      const a = q.a * Math.min(1, k / q.fadeIn) * (1 - k);
      this.col[n * 4] = q.c.r; this.col[n * 4 + 1] = q.c.g; this.col[n * 4 + 2] = q.c.b; this.col[n * 4 + 3] = a;
      this.siz[n] = q.size * (1 + k * q.grow); this.rot[n] = q.r; n++;
    }
    const g = this.points.geometry; g.setDrawRange(0, n);
    for (const k of ['position', 'color', 'size', 'rot']) g.attributes[k].needsUpdate = true;
  }
}

export class FX {
  constructor(scene) {
    this.scene = scene;
    this.smoke = new Particles(2600); scene.add(this.smoke.points);
    this.glow = new Particles(300, { additive: true }); scene.add(this.glow.points);
    this.columns = []; this.trails = []; this.flashes = [];
    this.flashLight = new THREE.PointLight(0xffb060, 0, 12, 2); scene.add(this.flashLight);
    this.motes = null;
  }
  /** עמוד עשן מתמשך (שריפה רחוקה / רכב בוער) */
  column(pos, { color = 0x2a2624, rate = 6, size = 6, height = 1, fire = false } = {}) { const c = { pos: pos.clone(), color, rate, size, acc: 0, fire, height }; this.columns.push(c); return c; }
  /** אבק מפגיעת כדור */
  impact(p, { color = 0xb59c78, n = 7 } = {}) {
    for (let i = 0; i < n; i++) this.smoke.emit({ p: p.clone().add(new THREE.Vector3((Math.random() - 0.5) * 0.2, 0.05, (Math.random() - 0.5) * 0.2)), v: new THREE.Vector3((Math.random() - 0.5) * 2, 1.5 + Math.random() * 2.5, (Math.random() - 0.5) * 2), life: 0.8 + Math.random() * 0.8, size: 0.25 + Math.random() * 0.3, grow: 3, color, alpha: 0.8, drag: 0.92, rise: -2 });
  }
  dust(p, n = 12, color = 0xc2a882) { for (let i = 0; i < n; i++) this.smoke.emit({ p: p.clone().add(new THREE.Vector3((Math.random() - 0.5) * 1.5, 0.1, (Math.random() - 0.5) * 1.5)), v: new THREE.Vector3((Math.random() - 0.5) * 1.5, 0.4 + Math.random(), (Math.random() - 0.5) * 1.5), life: 2 + Math.random() * 2, size: 0.8 + Math.random(), grow: 2.5, color, alpha: 0.35, drag: 0.97 }); }
  /** הבזק לוע + אור רגעי */
  muzzle(p, dir) {
    this.glow.emit({ p, v: dir.clone().multiplyScalar(2), life: 0.06, size: 0.5, grow: 0.5, color: 0xffc070, alpha: 1, fadeIn: 0.01 });
    this.smoke.emit({ p: p.clone().addScaledVector(dir, 0.2), v: dir.clone().multiplyScalar(1.5).add(new THREE.Vector3(0, 0.5, 0)), life: 1.2, size: 0.25, grow: 3, color: 0x9a9690, alpha: 0.35 });
    this.flashLight.position.copy(p); this.flashLight.intensity = 25; this.flashT = 0.05;
  }
  /** רקטה שעולה מהאופק ונעלמת / מיורטת */
  rocket(from, to, dur = 6, intercept = true, onBoom) { this.trails.push({ from: from.clone(), to: to.clone(), t: 0, dur, intercept, onBoom, done: false }); }
  /** חלקיקי אבק מרחפים באוויר (קרני שמש) */
  addMotes(center, count = 600, radius = 25, color = 0xffe2b0) {
    const geo = new THREE.BufferGeometry(); const p = new Float32Array(count * 3);
    for (let i = 0; i < count; i++) { p[i * 3] = (Math.random() - 0.5) * radius * 2; p[i * 3 + 1] = Math.random() * 6; p[i * 3 + 2] = (Math.random() - 0.5) * radius * 2; }
    geo.setAttribute('position', new THREE.BufferAttribute(p, 3));
    const m = new THREE.PointsMaterial({ color, size: 0.035, transparent: true, opacity: 0.55, depthWrite: false, blending: THREE.AdditiveBlending });
    this.motes = new THREE.Points(geo, m); this.motes.frustumCulled = false; this.scene.add(this.motes); this.motesR = radius;
  }
  update(dt, t, cam) {
    for (const c of this.columns) {
      c.acc += dt * c.rate;
      while (c.acc > 1) { c.acc--; this.smoke.emit({ p: c.pos.clone().add(new THREE.Vector3((Math.random() - 0.5) * c.size * 0.3, 0, (Math.random() - 0.5) * c.size * 0.3)), v: new THREE.Vector3(1.2 + Math.random() * 0.6, (2.5 + Math.random() * 1.5) * c.height, 0.3 + (Math.random() - 0.5)), life: 14 + Math.random() * 6, size: c.size * (0.6 + Math.random() * 0.5), grow: 3.5, color: c.color, alpha: 0.55, drag: 0.995, fadeIn: 0.08 });
        if (c.fire && Math.random() < 0.6) this.glow.emit({ p: c.pos.clone().add(new THREE.Vector3((Math.random() - 0.5) * 1.2, 0.3, (Math.random() - 0.5) * 1.2)), v: new THREE.Vector3(0, 1.5 + Math.random(), 0), life: 0.7, size: 0.9, grow: -0.5, color: 0xff7a2a, alpha: 0.9 }); }
    }
    for (const r of this.trails) {
      if (r.done) continue; r.t += dt; const k = Math.min(1, r.t / r.dur);
      const p = new THREE.Vector3().lerpVectors(r.from, r.to, k); p.y += Math.sin(k * Math.PI) * (r.to.y - r.from.y) * 0.4;
      this.smoke.emit({ p, v: new THREE.Vector3((Math.random() - 0.5) * 0.3, 0, (Math.random() - 0.5) * 0.3), life: 9, size: 2.2, grow: 2, color: 0xe8e2da, alpha: 0.5, drag: 0.99 });
      this.glow.emit({ p, life: 0.08, size: 1.2, color: 0xffd090, alpha: 1 });
      if (k >= 1) { r.done = true; if (r.intercept) { for (let i = 0; i < 30; i++) this.smoke.emit({ p: p.clone(), v: new THREE.Vector3((Math.random() - 0.5) * 14, (Math.random() - 0.5) * 14, (Math.random() - 0.5) * 14), life: 10, size: 4, grow: 2, color: 0xd8d2ca, alpha: 0.55, drag: 0.94 }); this.glow.emit({ p, life: 0.25, size: 30, grow: 1, color: 0xffe0a0, alpha: 1, fadeIn: 0.01 }); } r.onBoom && r.onBoom(p); }
    }
    this.trails = this.trails.filter(r => !r.done);
    if (this.flashT > 0) { this.flashT -= dt; if (this.flashT <= 0) this.flashLight.intensity = 0; }
    if (this.motes && cam) { this.motes.position.set(Math.round(cam.position.x / 10) * 10, cam.position.y - 2, Math.round(cam.position.z / 10) * 10); this.motes.rotation.y = t * 0.01; }
    this.smoke.update(dt, this.scene, cam); this.glow.update(dt, this.scene, cam);
  }
}
