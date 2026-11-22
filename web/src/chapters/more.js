// ═══════════════════════════════════════════════════════════════════
//  פרקים 3–6: המנהרה · בחוץ · המטוס · הקפיצה והבית (גרסה דחוסה ומשחקית מקצה לקצה)
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Chapter } from '../core/game.js';
import { Materials } from '../world/materials.js';
import * as P from '../world/props.js';
import { NPC, sunRig, Marker } from './common.js';
import { Character, randomLook } from '../core/character.js';
import { Vehicle } from '../core/player.js';
import { Audio, Music, Body } from '../core/audio.js';
import { UI } from '../core/ui.js';
import { Input } from '../core/input.js';
import { STORY, ENDING } from '../config/texts.he.js';
import { Terrain } from '../world/terrain.js';

const V3 = (x, y, z) => new THREE.Vector3(x, y, z);
const box = (w, x, z, ww, d, h = 3) => w.colliders.push({ type: 'box', x, z, w: ww, d, h, cover: true });

// ─────────────────────── פרק 3 – המנהרה ───────────────────────
class Chapter3 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['wake', 'sneak']; }
  async build() {
    const g = this.game, s = this.scene, W = g.world;
    W.heightFn = () => 0; W.surfaceFn = (x, z) => (z < -40 ? 'water' : 'concrete'); W.colliders = [];
    s.fog = new THREE.FogExp2(0x050607, 0.09); s.background = new THREE.Color(0x020203);
    this.add(new THREE.HemisphereLight(0x1a2025, 0x050505, 0.15));
    const conc = Materials.pbr('rough_concrete', 2, { color: 0x8a8e90 });
    // מנהרה: תא + מסדרון ארוך עם קשת
    const tunnel = (x, z, len, w = 2.6) => { for (let i = 0; i < len; i += 2) { const arch = new THREE.Mesh(new THREE.CylinderGeometry(w / 2 + 0.2, w / 2 + 0.2, 2, 18, 1, true, -Math.PI / 2, Math.PI), conc); arch.material.side = THREE.BackSide; arch.rotation.x = Math.PI / 2; arch.rotation.z = Math.PI / 2; arch.rotation.set(Math.PI / 2, 0, 0); arch.position.set(x, 1.2, z - i); arch.rotateZ(0); this.add(arch); const fl = new THREE.Mesh(new THREE.PlaneGeometry(w, 2), conc); fl.rotation.x = -Math.PI / 2; fl.position.set(x, 0, z - i); this.add(fl); } box(W, x - w / 2 - 0.2, z - len / 2, 0.3, len + 2); box(W, x + w / 2 + 0.2, z - len / 2, 0.3, len + 2); };
    tunnel(0, 4, 8, 4.5); tunnel(0, -4, 48);
    box(W, 0, 6, 6, 0.4); box(W, 0, -54, 6, 0.4);
    // נורה מהבהבת + פנס חלש
    this.bulb = new THREE.PointLight(0xa8c49a, 3, 9, 2); this.bulb.position.set(0, 2.2, 2); this.add(this.bulb);
    this.torch = new THREE.SpotLight(0xffd9a0, 6, 14, 0.5, 0.6, 1.5); this.add(this.torch); this.add(this.torch.target);
    for (let i = 0; i < 4; i++) { const m = P.buildSleepingBag([0x3a3a3a, 0x4a3a2a, 0x2a3a4a, 0x3a2a2a][i]); m.position.set(-1.6 + i * 1.1, 0, 4); this.add(m); }
    // דמויות
    this.esther = new NPC(g, { skin: '#e2b48f', hair: 3, hairColor: '#d8d8d8', gender: 'f', outfit: ['#6b5b7a', '#3a3a3a', '#222', '#c9a24a', 1, 1], acc: ['glasses'], build: 1.05 }, V3(-1.6, 0, 3.4), Math.PI, 0); this.add(this.esther.root); this.esther.idleState = 'sitGround';
    this.ido = new NPC(g, { skin: '#c99169', hair: 1, hairColor: '#1d1410', gender: 'm', outfit: ['#3d4a5c', '#232629', '#cfcac0', '#ffb347', 1, 1], height: 0.97 }, V3(1.4, 0, 3.4), Math.PI); this.add(this.ido.root); this.ido.idleState = 'sitGround';
    this.meir = new NPC(g, { skin: '#a4704a', hair: 0, hairColor: '#3b2517', gender: 'm', outfit: ['#7a6a5a', '#3a3f45', '#222', '#fff', 1, 1], acc: ['beard'] }, V3(0.2, 0, 4.4), Math.PI); this.add(this.meir.root); this.meir.idleState = 'holdPhoto'; this.meir.ch.setHold('photo');
    for (const n of [this.esther, this.ido, this.meir]) n.ch.setState(n.idleState);
    // שומרים עם פנסים
    this.guards = [];
    for (const [z, x0, x1] of [[-16, -1, 1], [-30, 1, -1]]) { const c = new Character({ terrorist: true, skin: '#a4704a' }); c.setHold('flashlight'); c.root.position.set(x0, 0, z); this.add(c.root); const L = new THREE.SpotLight(0xfff0c8, 14, 10, 0.4, 0.4, 1.4); this.add(L); this.add(L.target); this.guards.push({ c, L, z, x0, x1, t: Math.random() * 6 }); }
    this.drip = this.loop('tunnelLoop', { vol: 0.6 }); Audio.setSpace('tunnel'); this.eng.setGrade('tunnel');
    this.marker = new Marker(s); this.objects.push(this.marker.sprite);
    const p = this.player, T = STORY.ch3;
    p.addInteract({ pos: V3(2.2, 1.2, 2), prompt: T.prompts.knock, enabled: () => this.step === 0, onUse: () => this.decode() });
    p.addInteract({ pos: V3(0.2, 0.3, 4.4), prompt: T.prompts.tool, enabled: () => this.step === 1, onUse: () => this.findTool() });
    p.addInteract({ getPos: () => this.ido.root.position.clone().add(V3(0, 1, 0)), prompt: T.prompts.ido, enabled: () => this.step === 2, onUse: () => this.distraction() });
    p.addInteract({ pos: V3(0, 0.3, -48), prompt: T.prompts.grate, enabled: () => this.step === 3, onUse: () => this.escape() });
  }
  start(cp) {
    const p = this.player, e = this.eng;
    p.place(0, 2.5, Math.PI); this.step = 0; p.crouch = true;
    e.set('fade', 1); e.set('blur', 1); e.set('eyelid', 1);
    Music.set('tunnel', 0.35);
    (async () => {
      UI.chapterCard(3); e.set('fade', 0, 0.5); await this.wait(1); e.set('eyelid', 0, 0.4); e.set('blur', 0, 0.25);
      this.game.vm.setPose('wrist'); p.extraPitch = -0.3; await this.wait(2.5); this.game.vm.setPose('idle'); p.extraPitch = 0; // הצמיד של שחר עדיין על היד
      Input.lock(); await UI.lines(STORY.ch3.wake, { esther: this.esther.ch, meir: this.meir.ch, ido: this.ido.ch });
      for (let i = 0; i < 3; i++) Audio.play('knock', { pos: V3(2.4, 1.2, 2), delay: i * 0.4 });
      UI.objective(STORY.ch3.obj.listen); this.marker.set(V3(2.2, 1.4, 2));
    })().catch(() => {});
  }
  async decode() {
    this.busy = true; await UI.lines(STORY.ch3.knock, { esther: this.esther.ch });
    const grid = ['אבגדה', 'וזחטי', 'כלמנס', 'עפצקר', 'שת'];
    const word = 'מים'; const code = [...word].map(ch => { for (let r = 0; r < grid.length; r++) { const c = grid[r].indexOf(ch); if (c >= 0) return [r + 1, c + 1]; } });
    let delay = 0; for (const [r, c] of code) { for (let i = 0; i < r; i++) { Audio.play('knock', { pos: V3(2.4, 1.2, 2), delay }); delay += 0.32; } delay += 0.6; for (let i = 0; i < c; i++) { Audio.play('knock', { pos: V3(2.4, 1.2, 2), delay }); delay += 0.32; } delay += 1.2; }
    Input.unlock();
    const o = document.createElement('div'); o.className = 'overlay on'; o.innerHTML = `<div class="panel"><div class="menu"><h3 style="font-size:24px">${STORY.ch3.decodeTitle}</h3><div style="color:var(--muted);font-size:13px">${STORY.ch3.decodeHint}</div><div style="font-family:var(--serif);font-size:22px;line-height:1.8;direction:rtl">${grid.map((r, i) => `<div><b style="color:var(--accent)">${i + 1}</b> ${[...r].map((ch, j) => `<span style="margin:0 8px">${ch}<sub style="color:var(--dim)">${j + 1}</sub></span>`).join('')}</div>`).join('')}</div><div style="direction:ltr;color:var(--accent);font-size:20px">${code.map(([r, c]) => `${r}·${c}`).join('   ')}</div><input type="text" id="dw" maxlength="6" style="font-size:22px;text-align:center"><button class="btn primary" id="dok">✓</button></div></div>`;
    document.body.appendChild(o);
    await new Promise(res => { const go = () => { if (o.querySelector('#dw').value.trim() === word) { o.remove(); res(); } else o.querySelector('#dw').style.borderColor = 'var(--warn)'; }; o.querySelector('#dok').onclick = go; o.querySelector('#dw').onkeydown = (e) => { e.stopPropagation(); if (e.key === 'Enter') go(); }; });
    Input.lock(); this.game.addPuzzle(); await UI.lines(STORY.ch3.decoded, { esther: this.esther.ch });
    this.step = 1; UI.objective(STORY.ch3.obj.tool); this.marker.set(V3(0.2, 0.5, 4.4)); this.busy = false;
  }
  async findTool() { Audio.play('cloth', { vol: 0.7 }); Audio.play('clank', { vol: 0.4 }); await UI.lines(STORY.ch3.tool, { meir: this.meir.ch }); this.game.trust.meir++; this.step = 2; UI.objective(STORY.ch3.obj.ido); this.marker.set(this.ido.root); }
  async distraction() {
    await UI.lines(STORY.ch3.ido, { ido: this.ido.ch, esther: this.esther.ch });
    this.ido.ch.setState('drum'); Music.playTheme(0.2, 'pluck', 0.4, V3(1.4, 1, 3)); // הנושא של שחר – עידו מכיר אותו
    for (let i = 0; i < 8; i++) Audio.play('pipe', { pos: V3(0, 1.5, -40), delay: 1 + i * 0.7, vol: 0.7, rate: 0.8 + (i % 4) * 0.1 });
    await UI.lines(STORY.ch3.plan, { esther: this.esther.ch });
    for (const gd of this.guards) gd.lured = true;
    this.step = 3; this.game.addPuzzle(); this.game.setCheckpoint('sneak'); UI.objective(STORY.ch3.obj.sneak); this.marker.set(V3(0, 0.6, -48));
  }
  async escape() {
    this.step = 4; UI.objective(STORY.ch3.obj.exit); this.marker.set(null); Audio.play('clank', { vol: 0.8 }); Audio.play('drip', { vol: 0.6 });
    this.game.vm.setPose('climb'); this.player.locked = true;
    const e = this.eng; const t0 = e.time; await this.until(() => { const k = Math.min(1, (e.time - t0) / 3); this.player.camOffset.y = k * 3; this.player.extraPitch = k * 1.2; return k >= 1; });
    e.set('flash', 0.7, 0); e.set('flash', 0, 1); e.set('fade', 1, 0.8); await this.wait(1.5); this.game.goChapter(4);
  }
  restart() { const p = this.player; p.place(0, -6, Math.PI); p.locked = false; this.eng.set('fade', 0, 1); }
  update(dt, t, beat) {
    const p = this.player;
    this.bulb.intensity = Math.random() < 0.03 ? 0.2 : 2.5 + Math.sin(t * 40) * 0.2;
    this.torch.position.copy(this.eng.camera.position); const f = new THREE.Vector3(); this.eng.camera.getWorldDirection(f); this.torch.target.position.copy(this.eng.camera.position).addScaledVector(f, 5);
    for (const n of [this.esther, this.ido, this.meir]) n.update(dt, beat);
    if (Math.random() < dt * 0.4) Audio.play('drip', { pos: V3((Math.random() - 0.5) * 3, 2.2, -Math.random() * 40), vol: 0.5 });
    for (const gd of this.guards) {
      gd.t += dt * (gd.lured ? 0.25 : 0.5); const x = gd.lured ? (gd.x0 > 0 ? 1.1 : -1.1) : gd.x0 + (gd.x1 - gd.x0) * (0.5 + 0.5 * Math.sin(gd.t)); const z = gd.z + Math.sin(gd.t * 0.7) * 3;
      gd.c.root.position.set(x, 0, z); gd.c.root.rotation.y = gd.lured ? (x > 0 ? Math.PI / 2 : -Math.PI / 2) : Math.PI * (Math.sin(gd.t) > 0 ? 0 : 1); gd.c.setState('walk', 1); gd.c.update(dt);
      gd.L.position.copy(gd.c.root.position).add(V3(0, 1.4, 0)); const dir = new THREE.Vector3(Math.sin(gd.c.root.rotation.y), -0.15, Math.cos(gd.c.root.rotation.y)); gd.L.target.position.copy(gd.L.position).addScaledVector(dir, 6);
      // נתפס באור → ירי אזהרה מרחוק → חזרה לצ'קפוינט
      if (this.step >= 3 && !this.game.failing && !this.game.enemiesDisabled) { const to = p.pos.clone().sub(gd.c.root.position); const d = to.length(); to.y = 0; to.normalize(); if (d < 7 && to.dot(new THREE.Vector3(dir.x, 0, dir.z).normalize()) > 0.85 && !p.crouch) { Audio.gunshot(gd.c.root.position, p.pos, { vol: 0.6 }); this.game.fail({ delay: 1.5 }); } }
    }
    this.marker.update(dt, this.eng.camera.position, t);
  }
}

// ─────────────────────── פרק 4 – בחוץ ───────────────────────
class Chapter4 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['exit', 'route']; }
  async build() {
    const g = this.game, s = this.scene, W = g.world;
    const terr = this.terr = new Terrain({ size: 600, res: 140, tex: 'burned_ground_01', repeat: 80, color: 0xb0a58f }); this.add(terr.mesh);
    W.heightFn = (x, z) => terr.heightAt(x, z); W.colliders = []; W.surfaceFn = () => 'gravel'; W.bounds = { minX: -280, maxX: 280, minZ: -280, maxZ: 280 };
    s.environment = Materials.env('dawn'); s.environmentIntensity = 0.4; s.fog = new THREE.FogExp2(0x8fa3b3, 0.012); s.background = new THREE.Color(0x8fa3b3);
    this.add(new THREE.HemisphereLight(0xa8b8c8, 0x5a5040, 0.8)); this.sun = sunRig(s, { color: 0xffd8b0, intensity: 1.2, dir: [0.6, 0.35, -0.3] }); this.objects.push(this.sun, this.sun.target);
    // הריסות: מבנים שבורים
    const plaster = Materials.pbr('damaged_plaster', 2, { color: 0xb5a58a });
    for (let i = 0; i < 40; i++) { const x = (Math.random() - 0.5) * 300, z = (Math.random() - 0.5) * 300; if (Math.hypot(x, z) < 8 || Math.abs(x - z * 0.3) < 6) continue; const w = 4 + Math.random() * 8, d = 4 + Math.random() * 8, h = 1.5 + Math.random() * 5; const b = P.rbox(w, h, d, plaster, 0.1); b.position.set(x, terr.heightAt(x, z) + h / 2 - 0.3, z); b.rotation.z = (Math.random() - 0.5) * 0.15; this.add(b); box(W, x, z, w, d, h); }
    for (let i = 0; i < 60; i++) { const x = (Math.random() - 0.5) * 300, z = (Math.random() - 0.5) * 300; const r = P.buildRock(i, 0.5 + Math.random(), plaster); r.position.set(x, terr.heightAt(x, z), z); this.add(r); }
    for (let i = 0; i < 50; i++) { const x = (Math.random() - 0.5) * 300, z = (Math.random() - 0.5) * 300; const b = P.buildBush(i, 0x6b6a45, 1 + Math.random()); b.position.set(x, terr.heightAt(x, z), z); this.add(b); W.colliders.push({ type: 'circle', x, z, r: 1.1, h: 1.4, bush: true, cover: true }); }
    // המפה על שולחן ליד היציאה
    const table = P.rbox(1.4, 0.8, 0.8, Materials.pbr('wood_planks', 1), 0.03); table.position.set(2, terr.heightAt(2, -3) + 0.4, -3); this.add(table);
    const mapTex = Materials.canvasTex(256, 192, (c, Wd, H) => { c.fillStyle = '#d8ccae'; c.fillRect(0, 0, Wd, H); c.strokeStyle = '#7a6a50'; for (let i = 0; i < 30; i++) { c.beginPath(); c.moveTo(Math.random() * Wd, Math.random() * H); c.lineTo(Math.random() * Wd, Math.random() * H); c.stroke(); } c.strokeStyle = '#c0392b'; c.lineWidth = 4; c.beginPath(); c.moveTo(40, 150); c.bezierCurveTo(90, 60, 160, 140, 220, 40); c.stroke(); c.fillStyle = '#c0392b'; c.beginPath(); c.arc(220, 40, 8, 0, 7); c.fill(); });
    this.map = new THREE.Mesh(new THREE.PlaneGeometry(0.7, 0.5), new THREE.MeshStandardMaterial({ map: mapTex })); this.map.rotation.x = -Math.PI / 2; this.map.position.set(2, table.position.y + 0.42, -3); this.add(this.map);
    this.goal = V3(150, 0, -170);
    // רכבים
    this.vehicles = [];
    for (const [t, x, z] of [['sedan', -4, -8], ['pickup', 6, -10], [null, 3, -12]]) { const m = t ? P.buildCar(t, 0x8a8a7a) : P.buildMotorbike(); m.position.set(x, terr.heightAt(x, z), z); m.rotation.y = 0.6; this.add(m); this.vehicles.push(new Vehicle(m, W, s)); }
    // סיורים
    this.patrols = [];
    for (let i = 0; i < 7; i++) { const c = new Character({ terrorist: true, skin: '#a4704a', detail: false }); const cx = 20 + i * 18, cz = -20 - i * 22; c.root.position.set(cx, 0, cz); this.add(c.root); const L = new THREE.SpotLight(0xfff0c8, 0, 20, 0.35, 0.5, 1.4); this.add(L); this.add(L.target); this.patrols.push({ c, L, cx, cz, t: Math.random() * 6, r: 6 + Math.random() * 6 }); }
    this.eng.setGrade('outside'); Audio.setSpace('open'); this.loop('windLoop', { vol: 0.4 });
    const p = this.player;
    p.addInteract({ pos: this.map.position, prompt: STORY.ch4.map, enabled: () => !this.hasMap, onUse: () => this.readMap() });
    for (const v of this.vehicles) p.addInteract({ getPos: () => v.model.localToWorld(V3(0, 1.1, 0.8)), prompt: STORY.ch4.car, radius: 3, enabled: () => this.hasMap && !p.vehicle, onUse: () => v.enter(p) });
  }
  start(cp) {
    const p = this.player; p.place(0, 0, Math.PI); Music.set('tension', 0.3);
    this.eng.set('fade', 0, 0.6); UI.chapterCard(4); UI.objective(STORY.ch4.obj.map); Input.lock();
    if (cp === 'route') this.readMap(true);
  }
  async readMap(skip) {
    this.hasMap = true;
    if (!skip) { // קאטסין בגוף שלישי: הדמות קוראת את המפה
      const me = new Character(this.game.myCharacterOpts()); me.root.position.set(2, this.terr.heightAt(2, -2.3), -2.3); me.root.rotation.y = Math.PI; me.setState('holdPhoto'); this.add(me.root); me.update(0.016);
      const head = me.root.position.clone().add(V3(0, 1.62, 0));
      await this.game.director.play([
        { dur: 3, from: { pos: head.clone().add(V3(1.6, 0.4, 1.6)), look: head, fov: 40 }, to: { pos: head.clone().add(V3(0.6, 0.1, 0.9)), look: head, fov: 32 } },
        { dur: 2.5, from: { pos: head.clone().add(V3(0, 0.05, -0.55)), look: head.clone().add(V3(0, 0, 0)), fov: 26 }, dof: { focus: 0.55, aperture: 0.012 } },
        { dur: 2.5, from: { pos: this.map.position.clone().add(V3(0, 0.6, 0.15)), look: this.map.position, fov: 35 } },
        { dur: 2, from: { pos: head.clone().add(V3(1.2, 0.2, 1.2)), look: head, fov: 38 }, at: [{ t: 0.5, fn: () => { this.map.visible = false; Audio.play('cloth', { vol: 0.6 }); } }] },
      ]);
      this.scene.remove(me.root);
    } else this.map.visible = false;
    this.game.setCheckpoint('route'); UI.objective(STORY.ch4.obj.go); UI.minimap.classList.add('on');
  }
  drawMinimap() {
    const cv = UI.minimap, g = cv.getContext('2d'), p = this.player, S = 260, sc = 1.2;
    g.save(); g.clearRect(0, 0, S, S); g.beginPath(); g.arc(S / 2, S / 2, S / 2, 0, 7); g.clip();
    g.fillStyle = 'rgba(20,24,28,0.82)'; g.fillRect(0, 0, S, S);
    g.translate(S / 2, S / 2); g.rotate(p.yaw);
    const tx = (x, z) => [(x - p.pos.x) * sc, (z - p.pos.z) * sc];
    g.strokeStyle = 'rgba(255,255,255,0.08)'; for (let i = -10; i <= 10; i++) { g.beginPath(); g.moveTo(i * 30, -300); g.lineTo(i * 30, 300); g.stroke(); g.beginPath(); g.moveTo(-300, i * 30); g.lineTo(300, i * 30); g.stroke(); }
    const [gx, gz] = tx(this.goal.x, this.goal.z); g.strokeStyle = '#ffb35c'; g.lineWidth = 4; g.setLineDash([8, 6]); g.beginPath(); g.moveTo(0, 0); g.lineTo(gx, gz); g.stroke(); g.setLineDash([]);
    g.fillStyle = '#ff6a5a'; for (const pt of this.patrols) { const [x, z] = tx(pt.c.root.position.x, pt.c.root.position.z); g.beginPath(); g.arc(x, z, 3, 0, 7); g.fill(); }
    g.fillStyle = '#ffb35c'; g.beginPath(); g.arc(Math.max(-120, Math.min(120, gx)), Math.max(-120, Math.min(120, gz)), 7, 0, 7); g.fill();
    g.restore(); g.fillStyle = '#fff'; g.beginPath(); g.moveTo(S / 2, S / 2 - 9); g.lineTo(S / 2 - 6, S / 2 + 6); g.lineTo(S / 2 + 6, S / 2 + 6); g.fill();
  }
  async surprise() {
    this.done = true; const p = this.player, e = this.eng; UI.minimap.classList.remove('on'); UI.objective(null);
    p.locked = true; Music.set('silence'); Audio.play('bird', { vol: 0.4 }); await this.wait(2.5);
    // פנסי רכב נדלקים בבת אחת + ירי פתאומי
    const ring = [];
    for (let i = 0; i < 4; i++) { const a = i / 4 * Math.PI * 2; const L = new THREE.SpotLight(0xfff2d8, 0, 50, 0.5, 0.4, 1.3); L.position.copy(p.pos).add(V3(Math.cos(a) * 14, 1.2, Math.sin(a) * 14)); L.target.position.copy(p.pos); this.add(L); this.add(L.target); ring.push(L); }
    ring.forEach(L => (L.intensity = 300)); Audio.play('stinger', { vol: 0.9 }); Audio.burst(p.pos.clone().add(V3(10, 2, 0)), p.pos, 8, 0.07); p.addTrauma(1); e.set('flash', 0.5); e.set('flash', 0, 3);
    await this.wait(2); e.set('fade', 1, 1); await this.wait(1.5);
    Audio.play('doorSlam', { vol: 0.8 }); Audio.play('engineStart', { vol: 0.6, delay: 1 }); await this.wait(3); this.game.goChapter(5);
  }
  restart() { const p = this.player; if (p.vehicle) p.vehicle.exit(p); p.place(0, 0, Math.PI); p.locked = false; this.eng.set('fade', 0, 1); }
  update(dt, t) {
    const p = this.player; this.sun.userData.follow(p.pos);
    if (this.hasMap && !this.done) this.drawMinimap();
    for (const pt of this.patrols) {
      pt.t += dt * 0.3; const x = pt.cx + Math.cos(pt.t) * pt.r, z = pt.cz + Math.sin(pt.t) * pt.r;
      pt.c.root.position.set(x, this.terr.heightAt(x, z), z); pt.c.root.rotation.y = pt.t + Math.PI; pt.c.setState('walk', 1); pt.c.update(dt);
      const dir = new THREE.Vector3(Math.sin(pt.c.root.rotation.y), 0, Math.cos(pt.c.root.rotation.y));
      pt.L.intensity = 40; pt.L.position.copy(pt.c.root.position).add(V3(0, 1.5, 0)); pt.L.target.position.copy(pt.L.position).addScaledVector(dir, 8).add(V3(0, -1.5, 0));
      const to = p.pos.clone().sub(pt.c.root.position); const d = to.length(); to.normalize();
      const lights = p.vehicle && p.vehicle.lightsOn;
      if (!this.game.failing && !this.done && !this.game.enemiesDisabled && ((d < 16 && to.dot(dir) > 0.7 && !p.hidden && this.game.world.los(pt.c.root.position.clone().add(V3(0, 1.5, 0)), p.pos.clone().add(V3(0, 1.2, 0)))) || (lights && d < 40))) { Audio.gunshot(pt.c.root.position, p.pos, { vol: 0.7 }); this.game.fail({ delay: 1.5 }); }
    }
    if (!this.done && this.hasMap && Math.hypot(p.pos.x - this.goal.x, p.pos.z - this.goal.z) < 14) this.surprise();
  }
}

// ─────────────────────── פרק 5 – המטוס ───────────────────────
function buildCabin(ch) {
  const s = ch.scene, W = ch.game.world;
  W.heightFn = () => 0; W.surfaceFn = () => 'carpet'; W.colliders = []; W.bounds = { minX: -1.7, maxX: 1.7, minZ: -16, maxZ: 12 };
  s.background = new THREE.Color(0x0a0c10); s.fog = null; s.environment = Materials.env('day'); s.environmentIntensity = 0.5;
  ch.add(new THREE.HemisphereLight(0xdfe8ef, 0x404040, 0.9));
  const hull = new THREE.Mesh(new THREE.CylinderGeometry(2.1, 2.1, 30, 28, 1, true), P.M.std(0xd8dde0, 0.7, 0, { side: THREE.BackSide })); hull.rotation.x = Math.PI / 2; hull.position.set(0, 1.3, -2); ch.add(hull);
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(4, 30), Materials.pbr('fabric_pattern_07', 6, { color: 0x6a7080 })); floor.rotation.x = -Math.PI / 2; floor.position.set(0, 0, -2); ch.add(floor);
  for (let r = 0; r < 12; r++) for (const x of [-1.25, -0.75, 0.75, 1.25]) { const z = 8 - r * 1.6; const seat = new THREE.Group(); const b = P.rbox(0.5, 0.15, 0.5, P.M.std(0x1f2a44, 0.8), 0.06); b.position.y = 0.45; seat.add(b); const back = P.rbox(0.5, 0.75, 0.12, P.M.std(0x1f2a44, 0.8), 0.06); back.position.set(0, 0.9, 0.25); seat.add(back); seat.position.set(x, 0, z); ch.add(seat); W.colliders.push({ type: 'box', x, z, w: 0.5, d: 0.6, h: 1.2 }); }
  for (let i = 0; i < 10; i++) { const L = new THREE.PointLight(0xe8f0ff, 2, 4, 2); L.position.set(0, 2.4, 8 - i * 2.6); ch.add(L); }
  const curtain = new THREE.Mesh(new THREE.PlaneGeometry(3.6, 2.4), P.M.std(0x2a3350, 0.9, 0, { side: THREE.DoubleSide })); curtain.position.set(0, 1.2, -12); ch.add(curtain);
  for (const z of [-11.5, 10.5]) { const ex = new THREE.Mesh(new THREE.PlaneGeometry(0.4, 0.15), P.M.emit(0xff3b30, 3)); ex.position.set(0, 2.2, z); ch.add(ex); }
  Audio.setSpace('cabin'); ch.loop('cabinLoop', { vol: 0.7 }); ch.eng.setGrade('plane');
}
class Chapter5 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['seat']; this.ghosts = true; }
  async build() {
    buildCabin(this);
    const g = this.game;
    this.pass = []; for (let i = 0; i < 26; i++) { const r = Math.floor(i / 3), x = [-1.25, -0.75, 1.25][i % 3]; if (r === 3 && x === -0.75) continue; const n = new NPC(g, randomLook(500 + i), V3(x, 0, 8.2 - r * 1.6), Math.PI); n.ch.setState('sit'); n.idleState = 'sit'; this.add(n.root); this.pass.push(n); }
    this.shachar = this.pass[4]; this.scene.remove(this.shachar.root); this.shachar = new NPC(g, { skin: '#e2b48f', hair: 2, hairColor: '#3b2517', outfit: ['#f6e6c8', '#3a4a6a', '#e9e4da', '#ff6b8b', 0, 1], gender: 'f', acc: ['bracelet', 'flower'] }, this.pass[4].root.position.clone(), Math.PI); this.shachar.ch.setState('sit'); this.shachar.idleState = 'sit'; this.add(this.shachar.root);
    this.guard = new NPC(g, { terrorist: true, skin: '#a4704a' }, V3(0.75, 0, 3.4), Math.PI); this.guard.ch.setState('sit'); this.guard.idleState = 'sit'; this.add(this.guard.root);
    for (const z of [-10, -11]) { const t = new Character({ terrorist: true, skin: '#a4704a' }); t.root.position.set(z === -10 ? -0.4 : 0.4, 0, z); t.root.rotation.y = 0; this.add(t.root); t.update(0.016); }
    const p = this.player;
    p.addInteract({ getPos: () => this.guard.root.position.clone().add(V3(0, 1.3, 0)), prompt: STORY.ch5.ask, enabled: () => this.stage === 'ask', onUse: () => this.ask() });
    p.addInteract({ pos: V3(0, 1.2, 11.2), prompt: STORY.ch5.door, enabled: () => this.stage === 'go', onUse: () => this.toilet() });
    p.addInteract({ pos: V3(-0.75, 0.8, 3.4), prompt: STORY.ch5.back, enabled: () => this.stage === 'back', onUse: () => this.sitBack() });
  }
  start() {
    const p = this.player; p.place(-0.75, 3.4, Math.PI); p.locked = true; p.camOffset.y = -0.45; this.stage = 'board';
    Music.set('plane', 0.4); this.eng.set('fade', 0, 1);
    (async () => {
      UI.chapterCard(5);
      // קאטסין: שחר בין החטופים – קלוז־אפ על הצמיד שלה
      const sh = this.shachar.root.position.clone();
      await this.game.director.play([
        { dur: 4, from: { pos: [0, 1.9, -9], look: [0, 1.0, 6], fov: 45 }, to: { pos: [0, 1.7, -2], look: [0, 1.0, 8], fov: 45 } },
        { dur: 3, from: { pos: sh.clone().add(V3(0.5, 1.1, -0.7)), look: sh.clone().add(V3(0, 1.1, 0)), fov: 30 }, dof: { focus: 0.9, aperture: 0.01 }, at: [{ t: 0.3, fn: () => UI.bark('', STORY.ch5.shachar, 2200) }] },
        { dur: 3, from: { pos: sh.clone().add(V3(0.45, 0.85, -0.35)), look: sh.clone().add(V3(0.2, 0.75, 0.05)), fov: 22 }, dof: { focus: 0.45, aperture: 0.014 } },
      ]);
      Input.lock(); p.locked = false; p.moveLocked = true; this.stage = 'ask'; UI.note(STORY.ch5.note);
    })().catch(() => {});
  }
  async ask() { this.guard.ch.poseOverride = (b, t) => { b.neck.rotation.x = Math.sin(t * 6) * 0.2; }; await this.wait(1.4); this.guard.ch.poseOverride = null; UI.note(null); this.player.moveLocked = false; this.player.camOffset.y = 0; this.stage = 'go'; }
  async toilet() {
    this.stage = 'cut'; const p = this.player; p.locked = true; Audio.play('latch', { vol: 0.7 });
    const me = new Character(this.game.myCharacterOpts()); me.root.position.set(0, 0, 11.4); this.add(me.root);
    const sink = P.rbox(0.6, 0.8, 0.4, P.M.std(0xe8e8e8, 0.3, 0.2), 0.04); sink.position.set(0.5, 0.4, 11.6); this.add(sink);
    const win = new THREE.Mesh(new THREE.CircleGeometry(0.12, 20), new THREE.MeshBasicMaterial({ color: 0x9fd0ff })); win.position.set(-0.9, 1.7, 11.6); win.rotation.y = Math.PI / 2; this.add(win);
    const gun = (await import('../core/character.js')).buildPistol(); gun.position.set(0.5, 0.65, 11.45); gun.visible = false; this.add(gun);
    const d = this.game.director;
    await d.play([
      { dur: 3, from: { pos: [0.6, 1.9, 10.6], look: [-0.6, 1.5, 11.6], fov: 40 }, onStart: () => { me.root.rotation.y = -Math.PI / 2; me.setState('handsUp'); me.root.position.y = 0.45; me.update(0.016); Audio.play('creak', { vol: 0.5 }); } }, // מנסה את החלון – קטן ולא נפתח
      { dur: 3, from: { pos: [-0.3, 1.4, 10.8], look: [0.5, 0.5, 11.6], fov: 38 }, onStart: () => { me.root.position.y = 0; me.root.rotation.y = Math.PI / 2; me.setState('crouch'); me.update(0.016); Audio.play('click', { vol: 0.5 }); }, at: [{ t: 1.2, fn: () => { gun.visible = true; Audio.play('clank', { vol: 0.3 }); } }] }, // המגירה
      { dur: 2.5, from: { pos: [0.6, 0.9, 11.0], look: [0.5, 0.65, 11.45], fov: 24 }, dof: { focus: 0.5, aperture: 0.012 } },
      { dur: 3, from: { pos: [0.5, 1.6, 10.6], look: [0, 1.4, 11.4], fov: 35 }, onStart: () => { gun.visible = false; me.setState('idle'); me.update(0.016); Audio.play('cloth', { vol: 0.6 }); Audio.play('breathOut', { vol: 0.6 }); } },
      { dur: 2.5, from: { pos: [0, 1.7, 9.6], look: [0, 1.5, 11.2], fov: 40 }, onStart: () => { Audio.play('latch', { vol: 0.6 }); Audio.play('whistle', { vol: 0.5 }); } },
    ]);
    this.scene.remove(me.root); this.scene.remove(gun); p.place(0, 10.4, 0); p.locked = false; this.stage = 'back';
  }
  async sitBack() { const p = this.player; p.place(-0.75, 3.4, Math.PI); p.camOffset.y = -0.45; p.locked = true; Music.setIntensity(0.8); await this.wait(2.5); this.eng.set('fade', 1, 0.3); await this.wait(3); this.game.goChapter(6); }
  update(dt, t, beat) { for (const n of this.pass) n.update(dt, beat); this.shachar.update(dt, beat); this.guard.update(dt, beat); this.player.addTrauma(dt * 0.02); }
}

// ─────────────────────── פרק 6 – הקפיצה והבית ───────────────────────
class Chapter6 extends Chapter {
  constructor(g) { super(g); this.checkpoints = ['seat', 'jump', 'home']; this.ghosts = true; }
  async build() {
    buildCabin(this);
    const g = this.game;
    this.pass = []; for (let i = 0; i < 24; i++) { const r = Math.floor(i / 3), x = [-1.25, 1.25, -0.75][i % 3]; if (r === 3 && x === -0.75) continue; const n = new NPC(g, randomLook(500 + i), V3(x, 0, 8.2 - r * 1.6), Math.PI); n.ch.setState('sit'); n.idleState = 'sit'; this.add(n.root); this.pass.push(n); }
    this.guard = new NPC(g, { terrorist: true, skin: '#a4704a' }, V3(0.75, 0, 3.4), Math.PI); this.guard.ch.setState('sit'); this.guard.idleState = 'sit'; this.add(this.guard.root);
    this.zvika = new NPC(g, { skin: '#e2b48f', hair: 4, hairColor: '#d8d8d8', gender: 'm', outfit: ['#e8551f', '#4a4a4a', '#222', '#fff', 1, 1], acc: ['backpack', 'packLogo', 'glasses'], packColor: '#e8551f' }, V3(1.25, 0, -3), Math.PI); this.zvika.ch.setState('sit'); this.zvika.idleState = 'sit'; this.add(this.zvika.root);
    const p = this.player;
    p.addInteract({ getPos: () => this.zvika.root.position.clone().add(V3(0, 1, 0)), prompt: STORY.ch6.zvika, enabled: () => this.stage === 'find', onUse: () => this.takeChute() });
    p.addInteract({ pos: V3(-1.6, 1.2, -9.5), prompt: STORY.ch6.door, enabled: () => this.stage === 'door', onUse: () => this.openDoor() });
  }
  start(cp) {
    const p = this.player; p.place(-0.75, 3.4, Math.PI); p.camOffset.y = -0.45; p.moveLocked = true; this.stage = 'draw';
    Music.set('plane', 0.7); this.eng.set('fade', 0, 0.6); UI.chapterCard(6).then(() => { Input.lock(); this.game.vm.pistol.visible = true; this.game.vm.setPose('pistol'); this.handlesArms = true; UI.note(STORY.ch6.shoot); p.lookLimit = null; });
    if (cp === 'home') this.home();
  }
  async shoot() {
    this.stage = 'shot'; const p = this.player, e = this.eng; UI.note(null);
    Audio.play('pistol', { vol: 1, reverb: 0.3 }); e.set('flash', 0.5); e.set('flash', 0, 4); p.addTrauma(0.6); this.game.vm.recoil = 1;
    // המצלמה מסיטה מבט – לא מראים את הפגיעה
    p.extraYaw = 1.2; this.guard.root.visible = false;
    for (const n of this.pass) { n.ch.setState('cower'); n.idleState = 'cower'; }
    Audio.play('crowdPanic', { vol: 0.6 }); Body.ring(0.6);
    await this.wait(0.8); p.extraYaw = 0; this.game.vm.pistol.visible = false; this.game.vm.setPose('idle'); this.handlesArms = false;
    p.camOffset.y = 0; p.moveLocked = false; this.stage = 'find'; this.timer = 0; Music.set('tension', 0.95);
    this.zvika.ch.poseOverride = (b, t) => { b.neck.rotation.y = Math.sin(t * 2) * 0.3; b.shR.rotation.x = -0.6; };
  }
  async takeChute() {
    this.stage = 'gear'; await UI.lines(STORY.ch6.zvikaLine, { zvika: this.zvika.ch });
    const p = this.player; p.locked = true; p.extraPitch = -1.0; Audio.play('zip', { vol: 0.7 }); Audio.play('cloth', { vol: 0.7, delay: 0.5 }); Audio.play('latch', { vol: 0.7, delay: 1.2 });
    await this.wait(2); p.extraPitch = 0; p.locked = false; this.game.addPuzzle();
    UI.prompt(null);
    const it = p.addInteract({ getPos: () => this.eng.camera.position.clone().add(V3(0, -0.4, 0)).add(new THREE.Vector3(-Math.sin(p.yaw), 0, -Math.cos(p.yaw)).multiplyScalar(0.4)), prompt: STORY.ch6.beacon, cone: -1, radius: 3, onUse: () => { p.removeInteract(it); Audio.play('beep', { vol: 0.7 }); this.beeping = true; this.stage = 'door'; } });
  }
  async openDoor() {
    this.stage = 'open'; const p = this.player, e = this.eng;
    let held = 0; await this.until(() => { if (Input.down('KeyE')) { held += 0.016; p.addTrauma(0.02); } return held > 1.2; });
    Audio.play('doorSlam', { vol: 1 }); this.loop('roarLoop', { vol: 1 }); p.addTrauma(1);
    e.set('fade', 1, 1.2); await this.wait(1.2);
    // צניחה בגוף ראשון
    for (const o of [...this.objects]) this.scene.remove(o);
    const s = this.scene; s.background = new THREE.Color(0x7ec8f0); s.fog = new THREE.FogExp2(0xbfe0f5, 0.0015);
    this.add(new THREE.HemisphereLight(0xcfe8ff, 0x6a9a4a, 1.2)); const sun = new THREE.DirectionalLight(0xffe2b0, 2); sun.position.set(100, 200, 50); this.add(sun);
    const ground = new Terrain({ size: 2000, res: 120, tex: 'dry_ground_01', repeat: 200, color: 0x7aa05a, heightFn: () => 0 }); this.add(ground.mesh);
    for (let i = 0; i < 40; i++) { const f = new THREE.Mesh(new THREE.PlaneGeometry(60 + Math.random() * 80, 40 + Math.random() * 60), P.M.std([0x6a9a4a, 0xa8a050, 0x5a8a3a, 0xc8b070][i % 4], 1)); f.rotation.x = -Math.PI / 2; f.position.set((Math.random() - 0.5) * 900, 0.05, (Math.random() - 0.5) * 900); this.add(f); }
    this.game.world.bounds = null; this.game.world.colliders = []; this.game.world.heightFn = () => 0;
    p.locked = true; this.game.hideViewmodel = true; this.eng.setGrade('home');
    const cam = this.eng.camera; this.camOverride = true; cam.position.set(0, 600, 0);
    e.set('fade', 0, 1);
    const t0 = this.eng.time; let chute = false;
    await this.until(() => { const t = this.eng.time - t0; cam.position.y = Math.max(40, 600 - t * (chute ? 6 : 55)); cam.rotation.set(-1.1 + Math.sin(t * 2) * 0.05, t * 0.1, Math.sin(t * 3) * 0.05); e.fx.radialBlur = chute ? 0 : 0.06; if (!chute && t > 8) { chute = true; Audio.play('chuteOpen', { vol: 1 }); p.addTrauma(1); } return t > 13; });
    e.fx.radialBlur = 0; e.set('fade', 1, 1); await this.wait(1.2); this.home();
  }
  async home() {
    this.stage = 'home'; const e = this.eng, cam = this.eng.camera; this.camOverride = true; this.game.hideViewmodel = true;
    for (const o of [...this.objects]) this.scene.remove(o);
    const s = this.scene; s.background = new THREE.Color(0x9fd0f0); s.fog = new THREE.FogExp2(0xd8e8f0, 0.004); s.environment = Materials.env('day');
    this.add(new THREE.HemisphereLight(0xdfefff, 0x6a7a4a, 1.0)); const sun = sunRig(s, { color: 0xffd27a, intensity: 2.2, dir: [0.5, 0.4, 0.3] }); this.objects.push(sun, sun.target); sun.userData.follow(V3(0, 0, 0));
    const ground = new Terrain({ size: 600, res: 100, tex: 'dry_ground_01', repeat: 80, color: 0x8ab06a }); this.add(ground.mesh);
    const flag = P.buildFlagPole(0xffffff, 7); flag.position.set(4, 0, -6); this.add(flag); this.flag = flag;
    const me = new Character(this.game.myCharacterOpts({ acc: ['bracelet'] })); me.root.position.set(0, 0, 0); this.add(me.root);
    const sh = new Character({ skin: '#e2b48f', hair: 2, hairColor: '#3b2517', outfit: ['#f6e6c8', '#3a4a6a', '#e9e4da', '#ff6b8b', 0, 1], gender: 'f', acc: ['bracelet', 'flower'] }); sh.root.position.set(0, 0, 0.55); sh.root.rotation.y = Math.PI; sh.smile = true; this.add(sh.root);
    const fam = []; for (let i = 0; i < 6; i++) { const c = new Character(randomLook(800 + i)); c.root.position.set(-3 + i * 1.2, 0, 2 + (i % 2)); c.root.rotation.y = Math.PI; c.smile = true; c.setState(i % 3 ? 'wave' : 'idle'); this.add(c.root); fam.push(c); }
    me.setState('hug'); sh.setState('hug'); for (const c of [me, sh, ...fam]) c.update(0.016);
    this.homeChars = [me, sh, ...fam];
    Music.set('theme'); Audio.setSpace('open');
    e.set('fade', 0, 0.8);
    await this.game.director.play([
      { dur: 5, from: { pos: [6, 2, 5], look: [0, 1.4, 0.3], fov: 40 }, to: { pos: [2.5, 1.7, 2.5], look: [0, 1.5, 0.3], fov: 34 }, at: [{ t: 1, fn: () => UI.bark('', STORY.ch6.landing, 4800) }] },
      { dur: 4, from: { pos: [0.5, 1.2, 1.2], look: [0.15, 1.05, 0.3], fov: 22 }, dof: { focus: 1, aperture: 0.012 } }, // שני הצמידים
      { dur: 6, from: { pos: [1.4, 1.65, 1.6], look: [0, 1.6, 0.4], fov: 32 }, at: [{ t: 0.5, fn: () => UI.lines(STORY.ch6.reunion, { shachar: sh, mom: fam[0] }) }] },
      { dur: 6, from: { pos: [0, 3, 10], look: [0, 1.4, 0], fov: 45 }, to: { pos: [0, 14, 22], look: [0, 1, 0], fov: 45 } },
    ]);
    // אפילוג: כיכר, נרות, סרטים צהובים
    e.set('fade', 1, 1); await this.wait(1.2);
    for (const o of [...this.objects]) this.scene.remove(o);
    s.background = new THREE.Color(0x0a0d1c); s.fog = new THREE.FogExp2(0x0a0d1c, 0.04); this.eng.setGrade('memorial');
    const pl = new THREE.Mesh(new THREE.PlaneGeometry(60, 60), Materials.pbr('rough_concrete', 10, { color: 0x6a6a70 })); pl.rotation.x = -Math.PI / 2; this.add(pl);
    this.add(new THREE.HemisphereLight(0x303a60, 0x101010, 0.3));
    for (let i = 0; i < 60; i++) { const a = Math.random() * Math.PI * 2, r = 2 + Math.random() * 6; const c = P.cyl(0.03, 0.03, 0.12, P.M.std(0xf5ebd2, 0.5), 8); c.position.set(Math.cos(a) * r, 0.06, Math.sin(a) * r); this.add(c); if (i % 6 === 0) { const L = new THREE.PointLight(0xffb060, 1.5, 4, 2); L.position.set(c.position.x, 0.3, c.position.z); this.add(L); } const fl = new THREE.Mesh(new THREE.SphereGeometry(0.018, 6, 6), P.M.emit(0xffb060, 6)); fl.position.set(c.position.x, 0.15, c.position.z); this.add(fl); }
    for (let i = 0; i < 12; i++) { const chair = P.buildCampChair(0x222222); const a = i / 12 * Math.PI * 2; chair.position.set(Math.cos(a) * 9, 0, Math.sin(a) * 9); chair.rotation.y = -a - Math.PI / 2; this.add(chair); const rib = new THREE.Mesh(new THREE.TorusGeometry(0.06, 0.015, 6, 12), P.M.std(0xf2d22e, 0.5)); rib.position.set(chair.position.x, 0.95, chair.position.z); this.add(rib); }
    Music.set('memorial'); e.set('fade', 0, 1.5);
    const lines = STORY.ch6.epilogue;
    const ep = this.game.director.play([{ dur: 20, from: { pos: [12, 4, 12], look: [0, 0.3, 0], fov: 40 }, to: { pos: [4, 1.6, 4], look: [0, 0.2, 0], fov: 36 }, hand: 0.1 }]);
    for (const l of lines) { await UI.sub('', l, 5500); }
    await ep; e.set('fade', 1, 0.5); await this.wait(2.5);
    this.game.onCredits && this.game.onCredits();
  }
  update(dt, t, beat) {
    if (this.stage === 'draw' && Input.mouse.clicked && this.game.vm.pistol.visible) this.shoot();
    if (this.pass && this.stage !== 'home') for (const n of this.pass) if (n.root.parent) n.update(dt, beat);
    if (this.zvika && this.zvika.root.parent) this.zvika.update(dt, beat);
    if (this.stage === 'find' || this.stage === 'door' || this.stage === 'gear') {
      this.timer += dt; if (Math.random() < dt * 0.8) Audio.play('shoutFar', { pos: V3(0, 1.6, -13), vol: 0.5 + this.timer / 100 }); if (Math.random() < dt) Audio.footstep('metal', 0.6, V3(0, 0, -13));
      if (this.timer > 120 && !this.game.failing) { this.game.fail({ delay: 1.5 }); }
    }
    if (this.beeping && Math.random() < dt * 1.2) Audio.play('beep', { vol: 0.3 });
    if (this.flag && this.flag.parent) this.flag.userData.update(t);
    if (this.homeChars) for (const c of this.homeChars) c.update(dt, beat);
  }
  restart(cp) { this.game.loadChapter(6, cp); }
}

export function register(game) { game.registerChapter(3, Chapter3); game.registerChapter(4, Chapter4); game.registerChapter(5, Chapter5); game.registerChapter(6, Chapter6); }
