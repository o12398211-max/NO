// ═══════════════════════════════════════════════════════════════════
//  Props – אביזרים פרוצדורליים מפורטים: במה, אוהלים, צלונים, רכבים, עצים, שיחים, סלעים, דוכנים, תאורה
//  כולם נבנים מצורות מעוגלות/מוחלקות ו-PBR. אין קוביות גולמיות.
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { RoundedBoxGeometry } from 'three/examples/jsm/geometries/RoundedBoxGeometry.js';
import { Materials, canvasTex } from './materials.js';
import { fbm } from './terrain.js';

export const M = {
  std: (color, rough = 0.8, metal = 0, extra = {}) => new THREE.MeshStandardMaterial({ color, roughness: rough, metalness: metal, ...extra }),
  emit: (color, intensity = 2) => new THREE.MeshStandardMaterial({ color: 0x000000, emissive: color, emissiveIntensity: intensity, roughness: 0.4 }),
};
const metal = M.std(0x6d7075, 0.35, 0.85);
const darkMetal = M.std(0x23252a, 0.45, 0.7);
const rubber = M.std(0x141414, 0.9);
const glass = new THREE.MeshPhysicalMaterial({ color: 0x0b1015, roughness: 0.05, metalness: 0.2, transparent: true, opacity: 0.75, envMapIntensity: 1.5 });

export function rbox(w, h, d, mat, r = 0.04) { const m = new THREE.Mesh(new RoundedBoxGeometry(w, h, d, 3, Math.min(r, w / 2.1, h / 2.1, d / 2.1)), mat); m.castShadow = m.receiveShadow = true; return m; }
export function cyl(rt, rb, h, mat, seg = 16) { const m = new THREE.Mesh(new THREE.CylinderGeometry(rt, rb, h, seg), mat); m.castShadow = m.receiveShadow = true; return m; }
function shadow(o) { o.traverse(c => { if (c.isMesh) { c.castShadow = true; c.receiveShadow = true; } }); return o; }

// ─────────────── במה ───────────────
export function buildStage(opts = {}) {
  const g = new THREE.Group(); g.name = 'stage';
  const wood = Materials.pbr('wood_planks', 4, { color: 0x8a7a6a });
  const deck = rbox(18, 1.4, 10, wood, 0.06); deck.position.y = 0.7; g.add(deck);
  const skirt = rbox(18.2, 1.2, 0.1, M.std(0x111015, 0.95), 0.03); skirt.position.set(0, 0.6, 5.05); g.add(skirt);
  // מדרגות
  for (let i = 0; i < 4; i++) { const st = rbox(2, 0.35, 0.5, wood, 0.03); st.position.set(-7.5, 0.17 + i * 0.35 * 0.0, 5.5 - i * 0.0); st.position.set(-7.5, 0.175 + i * 0.35, 6.6 - i * 0.5); g.add(st); }
  // טראס: עמודים + קורות במבנה משולש
  const trussMat = M.std(0xb8bcc2, 0.3, 0.9);
  const truss = (len, horizontal) => {
    const t = new THREE.Group(); const r = 0.22;
    for (let k = 0; k < 3; k++) { const a = k / 3 * Math.PI * 2; const p = cyl(0.03, 0.03, len, trussMat, 8); p.position.set(Math.cos(a) * r, 0, Math.sin(a) * r); t.add(p); }
    const n = Math.floor(len / 0.5);
    for (let i = 0; i < n; i++) { const y = -len / 2 + (i + 0.5) * (len / n); for (let k = 0; k < 3; k++) { const a = k / 3 * Math.PI * 2, b = (k + 1) / 3 * Math.PI * 2; const s = cyl(0.012, 0.012, 0.46, trussMat, 5); s.position.set((Math.cos(a) + Math.cos(b)) * r / 2, y, (Math.sin(a) + Math.sin(b)) * r / 2); s.rotation.set(0.6, -(a + b) / 2, Math.PI / 2); t.add(s); } }
    if (horizontal) t.rotation.z = Math.PI / 2;
    return t;
  };
  for (const x of [-8.5, 8.5]) for (const z of [-4.5, 3.5]) { const p = truss(9, false); p.position.set(x, 1.4 + 4.5, z); g.add(p); }
  for (const z of [-4.5, 3.5]) { const b = truss(17.4, true); b.position.set(0, 10.2, z); g.add(b); }
  for (const x of [-8.5, 8.5]) { const b = truss(8.4, true); b.rotation.set(0, Math.PI / 2, Math.PI / 2); b.position.set(x, 10.2, -0.5); g.add(b); }
  // מסך LED מאחור עם אמנות מנדלה מונפשת (ללא שם/לוגו)
  const ledCanvas = document.createElement('canvas'); ledCanvas.width = 512; ledCanvas.height = 256;
  const ledTex = new THREE.CanvasTexture(ledCanvas); ledTex.colorSpace = THREE.SRGBColorSpace;
  const led = new THREE.Mesh(new THREE.PlaneGeometry(14, 6.5), new THREE.MeshBasicMaterial({ map: ledTex, toneMapped: false }));
  led.position.set(0, 5.2, -4.2); g.add(led);
  const ledFrame = rbox(14.4, 6.9, 0.3, darkMetal, 0.05); ledFrame.position.set(0, 5.2, -4.4); g.add(ledFrame);
  // דק די־ג'יי
  const booth = new THREE.Group();
  const table = rbox(3.2, 1.05, 1.1, M.std(0x16161b, 0.6, 0.2), 0.05); table.position.y = 0.52; booth.add(table);
  const front = new THREE.Mesh(new THREE.PlaneGeometry(3.1, 0.9), M.emit(0x7a2cff, 1.2)); front.position.set(0, 0.52, 0.56); booth.add(front);
  for (const x of [-0.9, 0, 0.9]) { const dk = rbox(0.7, 0.07, 0.6, M.std(0x2a2b30, 0.4, 0.6), 0.02); dk.position.set(x, 1.09, 0); booth.add(dk); const pl = cyl(0.22, 0.22, 0.02, M.std(0x111111, 0.3, 0.3), 24); pl.position.set(x, 1.135, 0); pl.userData.spin = true; booth.add(pl); }
  booth.position.set(0, 1.4, -0.5); g.add(booth);
  // רמקולים
  const spkMat = M.std(0x0f0f12, 0.85);
  const speaker = () => {
    const s = new THREE.Group(); const box = rbox(1.3, 1.6, 1.0, spkMat, 0.05); s.add(box);
    for (const [y, r] of [[0.35, 0.36], [-0.3, 0.26]]) { const cone = new THREE.Mesh(new THREE.ConeGeometry(r, 0.12, 24, 1, true), M.std(0x1c1c1c, 0.7)); cone.rotation.x = -Math.PI / 2; cone.position.set(0, y, 0.52); s.add(cone); const ring = new THREE.Mesh(new THREE.TorusGeometry(r, 0.025, 8, 28), darkMetal); ring.position.set(0, y, 0.51); s.add(ring); }
    return s;
  };
  for (const x of [-11, 11]) for (let k = 0; k < 3; k++) { const s = speaker(); s.position.set(x + (k % 2) * 0.1, 0.8 + k * 1.62, 3.0); s.rotation.y = -Math.sign(x) * 0.15; g.add(s); }
  // מנורות מסתובבות (moving heads) – קונוסי אור נפחיים
  g.userData.beams = [];
  const beamMat = (col) => new THREE.ShaderMaterial({
    uniforms: { uColor: { value: new THREE.Color(col) }, uOpacity: { value: 0.22 } },
    vertexShader: `varying float vY; varying vec3 vN; varying vec3 vV; void main(){ vY = uv.y; vec4 mv = modelViewMatrix*vec4(position,1.); vN = normalize(normalMatrix*normal); vV = normalize(-mv.xyz); gl_Position = projectionMatrix*mv; }`,
    fragmentShader: `uniform vec3 uColor; uniform float uOpacity; varying float vY; varying vec3 vN; varying vec3 vV; void main(){ float rim = pow(abs(dot(vN, vV)), 1.5); float a = uOpacity * pow(vY, 1.6) * rim; gl_FragColor = vec4(uColor * a * 2.0, a); }`,
    transparent: true, depthWrite: false, blending: THREE.AdditiveBlending, side: THREE.DoubleSide,
  });
  const cols = [0xff2e88, 0x19e3ff, 0x9b5bff, 0xffb347, 0x19e3ff, 0xff2e88];
  cols.forEach((c, i) => {
    const head = new THREE.Group(); head.position.set(-7 + i * 2.8, 9.8, 3.5); g.add(head);
    const body = rbox(0.35, 0.45, 0.35, darkMetal, 0.08); head.add(body);
    const cone = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 2.6, 22, 24, 1, true), beamMat(c)); cone.geometry.translate(0, -11, 0);
    head.add(cone);
    const lens = new THREE.Mesh(new THREE.CircleGeometry(0.12, 16), M.emit(c, 6)); lens.rotation.x = Math.PI / 2; lens.position.y = -0.24; head.add(lens);
    g.userData.beams.push({ head, cone, phase: i * 1.3, color: c });
  });
  // לייזרים
  g.userData.lasers = [];
  for (let i = 0; i < 10; i++) {
    const l = new THREE.Mesh(new THREE.CylinderGeometry(0.012, 0.012, 80, 4, 1, true), new THREE.MeshBasicMaterial({ color: i % 2 ? 0x22ff88 : 0xff2266, transparent: true, opacity: 0.5, blending: THREE.AdditiveBlending, depthWrite: false, toneMapped: false }));
    l.geometry.translate(0, 40, 0); l.position.set(0, 9.5, -3.5); g.add(l); g.userData.lasers.push({ l, ph: i * 0.6 });
  }
  g.userData.ledCanvas = ledCanvas; g.userData.ledTex = ledTex;
  g.userData.update = (t, beat, intensity = 1) => {
    // LED – מנדלה פסיכדלית מקורית
    const c = ledCanvas.getContext('2d'); const W = 512, H = 256;
    c.fillStyle = '#050208'; c.fillRect(0, 0, W, H);
    c.save(); c.translate(W / 2, H / 2);
    const pulse = 1 + 0.15 * Math.pow(Math.max(0, Math.sin(beat * Math.PI * 2)), 4);
    for (let ring = 0; ring < 7; ring++) {
      const n = 6 + ring * 3; const r = (18 + ring * 17) * pulse;
      c.strokeStyle = `hsla(${(t * 30 + ring * 35) % 360}, 90%, 60%, ${0.9 - ring * 0.1})`; c.lineWidth = 3;
      for (let k = 0; k < n; k++) { const a = k / n * Math.PI * 2 + t * (ring % 2 ? 0.3 : -0.3); c.beginPath(); c.ellipse(Math.cos(a) * r, Math.sin(a) * r * 0.9, 9 + ring, 4 + ring * 0.6, a, 0, Math.PI * 2); c.stroke(); }
    }
    c.restore();
    // פסי EQ
    for (let i = 0; i < 32; i++) { const h = (0.3 + 0.7 * Math.abs(Math.sin(beat * Math.PI + i * 0.7))) * 40; c.fillStyle = `hsl(${180 + i * 4},90%,55%)`; c.fillRect(i * 16 + 2, H - h, 12, h); }
    ledTex.needsUpdate = true;
    for (const b of g.userData.beams) { b.head.rotation.z = Math.sin(t * 0.7 + b.phase) * 0.7; b.head.rotation.x = Math.sin(t * 0.5 + b.phase * 2) * 0.45 + 0.35; b.cone.material.uniforms.uOpacity.value = 0.12 * intensity + 0.1 * Math.pow(Math.max(0, Math.sin(beat * Math.PI)), 6) * intensity; }
    for (const L of g.userData.lasers) { L.l.rotation.z = Math.sin(t * 0.9 + L.ph) * 1.1; L.l.rotation.x = -1.1 + Math.sin(t * 0.6 + L.ph) * 0.25; L.l.visible = intensity > 0.3 && (Math.floor(beat / 8) % 2 === 0); }
    booth.children.forEach(ch => { if (ch.userData.spin) ch.rotation.y += 0.1; });
  };
  return shadow(g);
}

// ─────────────── אוהלים וצלונים ───────────────
export function buildDomeTent(color = 0x3d6f8a, size = 1) {
  const g = new THREE.Group();
  const fabric = M.std(color, 0.85, 0, { side: THREE.DoubleSide });
  const dome = new THREE.Mesh(new THREE.SphereGeometry(1.4, 24, 12, 0, Math.PI * 2, 0, Math.PI / 2), fabric);
  dome.scale.set(1.1, 0.85, 1.0); g.add(dome);
  // מוטות קשת
  for (const r of [0.7, -0.7]) { const arc = new THREE.Mesh(new THREE.TorusGeometry(1.42, 0.015, 6, 32, Math.PI), M.std(0x222222, 0.4, 0.5)); arc.rotation.y = r; arc.scale.set(1.1, 0.85, 1); g.add(arc); }
  // פתח (דלת) כהה
  const door = new THREE.Mesh(new THREE.CircleGeometry(0.55, 20, 0, Math.PI), M.std(0x0b0b0b, 1)); door.position.set(0, 0.01, 1.38); g.add(door);
  const flap = new THREE.Mesh(new THREE.PlaneGeometry(0.6, 0.7, 4, 4), M.std(new THREE.Color(color).multiplyScalar(0.8), 0.9, 0, { side: THREE.DoubleSide })); flap.position.set(0.45, 0.3, 1.32); flap.rotation.set(-0.3, 0.6, 0.1); g.add(flap);
  // יתדות וחבלים
  for (let i = 0; i < 4; i++) { const a = i / 4 * Math.PI * 2 + 0.78; const rope = cyl(0.005, 0.005, 1.4, M.std(0xddd7c5, 0.9), 4); rope.position.set(Math.cos(a) * 1.75, 0.45, Math.sin(a) * 1.6); rope.rotation.set(Math.sin(a) * 0.9, 0, -Math.cos(a) * 0.9); g.add(rope); }
  g.scale.setScalar(size);
  return shadow(g);
}
/** צלון מתוח (מפרש בד) – אופייני למסיבות טבע */
export function buildShadeSail(w = 8, d = 8, color = 0xe8d9b8) {
  const g = new THREE.Group();
  const geo = new THREE.PlaneGeometry(w, d, 16, 16); geo.rotateX(-Math.PI / 2);
  const p = geo.attributes.position;
  for (let i = 0; i < p.count; i++) { const x = p.getX(i) / (w / 2), z = p.getZ(i) / (d / 2); p.setY(i, 3.4 - (1 - x * x) * (1 - z * z) * 0.6 + (x * z) * 0.7); }
  geo.computeVertexNormals();
  const sail = new THREE.Mesh(geo, M.std(color, 0.9, 0, { side: THREE.DoubleSide })); g.add(sail);
  const pole = M.std(0x5a4632, 0.8);
  for (const [x, z] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) { const h = 3.4 + x * z * 0.7; const c = cyl(0.06, 0.07, h, pole, 8); c.position.set(x * w / 2, h / 2, z * d / 2); g.add(c); }
  return shadow(g);
}
export function buildRug(w = 3, d = 2, hue = 0) {
  const tex = canvasTex(256, 192, (c, W, H) => {
    c.fillStyle = `hsl(${hue},55%,30%)`; c.fillRect(0, 0, W, H);
    c.strokeStyle = `hsl(${hue + 30},60%,60%)`; c.lineWidth = 6; c.strokeRect(10, 10, W - 20, H - 20);
    for (let i = 0; i < 6; i++) { c.fillStyle = `hsl(${hue + i * 25},60%,${40 + i * 5}%)`; c.beginPath(); c.moveTo(W / 2, 30 + i * 10); c.lineTo(W - 40 - i * 12, H / 2); c.lineTo(W / 2, H - 30 - i * 10); c.lineTo(40 + i * 12, H / 2); c.closePath(); c.fill(); }
  });
  const m = new THREE.Mesh(new THREE.PlaneGeometry(w, d), new THREE.MeshStandardMaterial({ map: tex, roughness: 1 })); m.rotation.x = -Math.PI / 2; m.position.y = 0.02; m.receiveShadow = true;
  return m;
}
export function buildBeanbag(color) { const m = new THREE.Mesh(new THREE.SphereGeometry(0.5, 16, 12), M.std(color, 0.9)); m.scale.set(1, 0.55, 1.1); m.position.y = 0.25; m.castShadow = m.receiveShadow = true; return m; }
export function buildSleepingBag(color = 0x2f5d8a) {
  const g = new THREE.Group();
  const bag = new THREE.Mesh(new THREE.CapsuleGeometry(0.32, 1.5, 4, 14), M.std(color, 0.75)); bag.rotation.x = Math.PI / 2; bag.scale.set(1, 1, 0.42); bag.position.y = 0.13; g.add(bag);
  const pillow = new THREE.Mesh(new THREE.SphereGeometry(0.25, 12, 8), M.std(0xd8d2c4, 0.9)); pillow.scale.set(1.1, 0.35, 0.7); pillow.position.set(0, 0.2, -0.85); g.add(pillow);
  return shadow(g);
}
export function buildCooler(color = 0x2b7bd6) {
  const g = new THREE.Group(); const b = rbox(0.6, 0.4, 0.38, M.std(color, 0.5), 0.05); b.position.y = 0.2; g.add(b);
  const lid = rbox(0.62, 0.08, 0.4, M.std(0xf0f0f0, 0.5), 0.03); lid.position.y = 0.43; g.add(lid);
  return g;
}
export function buildCampChair(color = 0x2a6b4f) {
  const g = new THREE.Group(); const f = M.std(color, 0.85, 0, { side: THREE.DoubleSide });
  const seat = new THREE.Mesh(new THREE.PlaneGeometry(0.5, 0.45, 4, 4), f); seat.rotation.x = -Math.PI / 2 + 0.1; seat.position.y = 0.42; g.add(seat);
  const back = new THREE.Mesh(new THREE.PlaneGeometry(0.5, 0.55, 4, 4), f); back.position.set(0, 0.72, -0.24); back.rotation.x = -0.2; g.add(back);
  for (const x of [-0.24, 0.24]) for (const z of [-0.22, 0.22]) { const l = cyl(0.012, 0.012, 0.6, metal, 6); l.position.set(x, 0.3, z); l.rotation.x = z > 0 ? 0.25 : -0.25; g.add(l); }
  return shadow(g);
}

// ─────────────── דוכן בר ───────────────
export function buildBarStall() {
  const g = new THREE.Group();
  const wood = Materials.pbr('wood_planks', 1.5, { color: 0xb08a62 });
  const counter = rbox(4, 1.1, 0.8, wood, 0.05); counter.position.set(0, 0.55, 0); g.add(counter);
  const top = rbox(4.2, 0.08, 1.0, M.std(0x5a3b22, 0.5), 0.03); top.position.set(0, 1.14, 0.05); g.add(top);
  for (const x of [-2, 2]) for (const z of [-1.4, 0.3]) { const p = cyl(0.05, 0.05, 2.8, M.std(0x5a4632, 0.8), 8); p.position.set(x, 1.4, z); g.add(p); }
  const roof = new THREE.Mesh(new THREE.PlaneGeometry(4.8, 2.6, 8, 4), M.std(0xc94f3a, 0.9, 0, { side: THREE.DoubleSide }));
  roof.rotation.x = -Math.PI / 2 + 0.15; roof.position.set(0, 2.85, -0.55); g.add(roof);
  // שוליים מסולסלים לגג
  for (let i = 0; i < 12; i++) { const f = new THREE.Mesh(new THREE.CircleGeometry(0.2, 10, Math.PI, Math.PI), M.std(i % 2 ? 0xf4e7c9 : 0xc94f3a, 0.9, 0, { side: THREE.DoubleSide })); f.position.set(-2.2 + i * 0.4, 2.7, 0.72); g.add(f); }
  const shelf = rbox(3.6, 0.05, 0.35, wood, 0.02); shelf.position.set(0, 1.7, -1.3); g.add(shelf);
  // כדים ובקבוקי מיץ עם צבעים (לא אלכוהול): לימונענע, אבטיח, מים
  const juiceCols = [0xb6e04a, 0xff5a6e, 0x9fd8ff, 0xffb347];
  for (let i = 0; i < 4; i++) {
    const jar = new THREE.Mesh(new THREE.CylinderGeometry(0.16, 0.16, 0.45, 18), new THREE.MeshPhysicalMaterial({ color: 0xffffff, transmission: 0.0, transparent: true, opacity: 0.35, roughness: 0.05 })); jar.position.set(-1.3 + i * 0.85, 1.42, 0); g.add(jar);
    const juice = cyl(0.145, 0.145, 0.34, M.std(juiceCols[i], 0.2, 0, { emissive: juiceCols[i], emissiveIntensity: 0.15 }), 18); juice.position.set(-1.3 + i * 0.85, 1.38, 0); g.add(juice);
    const tap = cyl(0.02, 0.02, 0.08, metal, 6); tap.rotation.x = Math.PI / 2; tap.position.set(-1.3 + i * 0.85, 1.26, 0.18); g.add(tap);
  }
  for (let i = 0; i < 10; i++) { const cup = cyl(0.04, 0.03, 0.1, M.std(0xf2f2f2, 0.6), 10); cup.position.set(1.2 + (i % 5) * 0.1, 1.23 + Math.floor(i / 5) * 0.1, 0.25); g.add(cup); }
  // פנסים תלויים
  g.userData.lamps = [];
  for (const x of [-1.5, 0, 1.5]) { const l = new THREE.Mesh(new THREE.SphereGeometry(0.12, 12, 10), M.emit(0xffb347, 3)); l.position.set(x, 2.45, 0.2); g.add(l); g.userData.lamps.push(l); }
  const light = new THREE.PointLight(0xffb36a, 6, 9, 2); light.position.set(0, 2.3, 0.8); g.add(light);
  return shadow(g);
}

// ─────────────── שרשרת נורות ───────────────
export function buildStringLights(points, color = 0xffc47a, bulbs = 14, sag = 0.6) {
  const g = new THREE.Group();
  const bulbGeo = new THREE.SphereGeometry(0.05, 8, 6);
  let total = 0; for (let i = 0; i < points.length - 1; i++) total += bulbs;
  const inst = new THREE.InstancedMesh(bulbGeo, new THREE.MeshBasicMaterial({ color, toneMapped: false }), total);
  const wireMat = new THREE.LineBasicMaterial({ color: 0x111111 });
  let n = 0; const m = new THREE.Matrix4(); const cols = [0xffc47a, 0xff7ab0, 0x7ad7ff, 0xfff1a0];
  for (let i = 0; i < points.length - 1; i++) {
    const a = points[i], b = points[i + 1];
    const pts = [];
    for (let k = 0; k <= 20; k++) { const t = k / 20; pts.push(new THREE.Vector3().lerpVectors(a, b, t).add(new THREE.Vector3(0, -Math.sin(t * Math.PI) * sag, 0))); }
    g.add(new THREE.Line(new THREE.BufferGeometry().setFromPoints(pts), wireMat));
    for (let k = 0; k < bulbs; k++) { const t = (k + 0.5) / bulbs; const p = new THREE.Vector3().lerpVectors(a, b, t).add(new THREE.Vector3(0, -Math.sin(t * Math.PI) * sag - 0.06, 0)); m.makeTranslation(p.x, p.y, p.z); inst.setMatrixAt(n, m); inst.setColorAt(n, new THREE.Color(cols[n % 4]).multiplyScalar(2.2)); n++; }
  }
  g.add(inst);
  return g;
}

// ─────────────── רכבים ───────────────
const CAR_PROFILES = {
  sedan: { len: 4.5, w: 1.78, pts: [[-2.25, 0.35], [-2.25, 0.8], [-2.0, 0.92], [-1.1, 0.98], [-0.55, 1.42], [0.75, 1.44], [1.35, 1.0], [2.15, 0.88], [2.25, 0.62], [2.2, 0.35]], win: [[-0.92, 1.0], [-0.5, 1.37], [0.7, 1.39], [1.18, 1.02]], wheels: [-1.4, 1.35], r: 0.33 },
  hatch: { len: 3.9, w: 1.72, pts: [[-1.95, 0.35], [-1.95, 0.9], [-1.75, 1.42], [0.45, 1.45], [1.15, 1.0], [1.9, 0.86], [1.95, 0.35]], win: [[-1.68, 1.02], [-1.55, 1.38], [0.4, 1.4], [0.98, 1.02]], wheels: [-1.25, 1.2], r: 0.32 },
  pickup: { len: 5.1, w: 1.85, pts: [[-2.55, 0.45], [-2.55, 1.05], [-0.55, 1.05], [-0.5, 1.75], [0.8, 1.78], [1.3, 1.15], [2.45, 1.02], [2.55, 0.45]], win: [[-0.42, 1.12], [-0.4, 1.7], [0.75, 1.72], [1.18, 1.14]], wheels: [-1.6, 1.6], r: 0.4, bed: true },
  van: { len: 4.8, w: 1.9, pts: [[-2.4, 0.4], [-2.4, 1.95], [1.3, 1.98], [2.25, 1.15], [2.4, 0.4]], win: [[1.05, 1.2], [1.2, 1.9], [-2.2, 1.9], [-2.2, 1.3]], wheels: [-1.5, 1.5], r: 0.34 },
};
export function buildCar(type = 'sedan', color = 0x9aa3ad, opts = {}) {
  const P = CAR_PROFILES[type];
  const g = new THREE.Group(); g.name = 'car_' + type;
  const burned = opts.burned;
  const paint = burned ? M.std(0x1f1b18, 0.95, 0.3) : new THREE.MeshPhysicalMaterial({ color, roughness: 0.32, metalness: 0.55, clearcoat: 0.8, clearcoatRoughness: 0.15, envMapIntensity: 1.1 });
  const shape = new THREE.Shape(); P.pts.forEach(([x, y], i) => i ? shape.lineTo(x, y) : shape.moveTo(x, y));
  const body = new THREE.Mesh(new THREE.ExtrudeGeometry(shape, { depth: P.w - 0.24, bevelEnabled: true, bevelSize: 0.1, bevelThickness: 0.12, bevelSegments: 5, curveSegments: 6 }), paint);
  body.position.z = -(P.w - 0.24) / 2; g.add(body);
  // חלונות
  const ws = new THREE.Shape(); P.win.forEach(([x, y], i) => i ? ws.lineTo(x, y) : ws.moveTo(x, y));
  const winMat = burned ? M.std(0x050505, 1) : glass;
  const win = new THREE.Mesh(new THREE.ExtrudeGeometry(ws, { depth: P.w + 0.012, bevelEnabled: true, bevelSize: 0.015, bevelThickness: 0.01, bevelSegments: 1 }), winMat); win.position.z = -(P.w + 0.012) / 2; win.scale.set(1, 1, 1); g.add(win);
  if (!burned) { // שמשה קדמית
    const [a, b] = [P.win[P.win.length - 1], P.win[P.win.length - 2]];
    const wsGeo = new THREE.PlaneGeometry(Math.hypot(b[0] - a[0], b[1] - a[1]), P.w - 0.3);
    const wsM = new THREE.Mesh(wsGeo, glass); wsM.position.set((a[0] + b[0]) / 2 + 0.03, (a[1] + b[1]) / 2 + 0.02, 0); wsM.rotation.set(-Math.PI / 2, Math.atan2(b[1] - a[1], b[0] - a[0]) - Math.PI / 2, 0, 'YXZ');
    wsM.rotation.set(0, Math.PI / 2, 0); wsM.rotateX(-(Math.PI / 2 - Math.atan2(b[1] - a[1], a[0] - b[0])));
    g.add(wsM); g.userData.windshield = wsM;
  }
  // גלגלים
  g.userData.wheels = [];
  const tireGeo = new THREE.CylinderGeometry(P.r, P.r, 0.24, 24); tireGeo.rotateX(Math.PI / 2);
  const rimGeo = new THREE.CylinderGeometry(P.r * 0.6, P.r * 0.6, 0.25, 12); rimGeo.rotateX(Math.PI / 2);
  for (const x of P.wheels) for (const s of [1, -1]) {
    const w = new THREE.Group(); w.position.set(x, P.r, s * (P.w / 2 - 0.08));
    w.add(new THREE.Mesh(tireGeo, burned ? M.std(0x0a0a0a, 1) : rubber));
    if (!burned) { const rim = new THREE.Mesh(rimGeo, metal); w.add(rim); for (let k = 0; k < 5; k++) { const sp = rbox(0.05, P.r * 1.1, 0.03, metal, 0.01); sp.rotation.z = k / 5 * Math.PI * 2; sp.position.z = s * 0.12; w.add(sp); } }
    g.add(w); g.userData.wheels.push(w);
    const arch = new THREE.Mesh(new THREE.TorusGeometry(P.r + 0.07, 0.05, 6, 16, Math.PI), burned ? M.std(0x111, 1) : M.std(0x151515, 0.8)); arch.position.set(x, P.r, s * (P.w / 2 - 0.02)); g.add(arch);
  }
  // פנסים
  const front = P.pts.reduce((a, p) => (p[0] > a ? p[0] : a), -9);
  const back = P.pts.reduce((a, p) => (p[0] < a ? p[0] : a), 9);
  const hlMat = burned ? M.std(0x111, 1) : M.emit(0xfff2d8, opts.lights ? 4 : 0.15);
  const tlMat = burned ? M.std(0x111, 1) : M.emit(0xff2a1a, opts.lights ? 3 : 0.4);
  g.userData.headMats = [hlMat]; g.userData.tailMats = [tlMat];
  for (const s of [1, -1]) {
    const hl = new THREE.Mesh(new THREE.SphereGeometry(0.12, 12, 8), hlMat); hl.scale.set(0.4, 0.7, 1.4); hl.position.set(front + 0.02, 0.72, s * (P.w / 2 - 0.28)); g.add(hl);
    const tl = new THREE.Mesh(new THREE.SphereGeometry(0.1, 10, 8), tlMat); tl.scale.set(0.4, 0.8, 1.6); tl.position.set(back - 0.02, 0.8, s * (P.w / 2 - 0.25)); g.add(tl);
    const mirror = rbox(0.06, 0.12, 0.2, paint, 0.02); mirror.position.set(P.win[P.win.length - 1][0] - 0.05, 1.08, s * (P.w / 2 + 0.06)); g.add(mirror);
  }
  const bumperF = rbox(0.15, 0.22, P.w, M.std(0x1a1a1a, 0.7), 0.06); bumperF.position.set(front + 0.04, 0.42, 0); g.add(bumperF);
  const bumperB = rbox(0.15, 0.22, P.w, M.std(0x1a1a1a, 0.7), 0.06); bumperB.position.set(back - 0.04, 0.42, 0); g.add(bumperB);
  const plate = new THREE.Mesh(new THREE.PlaneGeometry(0.5, 0.12), M.std(0xf2d22e, 0.5)); plate.position.set(back - 0.12, 0.55, 0); plate.rotation.y = -Math.PI / 2; g.add(plate);
  if (P.bed) { const rail = rbox(1.95, 0.08, 0.08, paint, 0.03); for (const s of [1, -1]) { const r = rail.clone(); r.position.set(-1.55, 1.08, s * (P.w / 2 - 0.05)); g.add(r); } }
  // פנים: הגה, דשבורד, מושבים (לנהיגה בגוף ראשון)
  const dashX = P.win[P.win.length - 1][0] - 0.2;
  const dash = rbox(0.55, 0.25, P.w - 0.3, M.std(0x1b1b1d, 0.7), 0.06); dash.position.set(dashX, 0.98, 0); g.add(dash);
  const wheel = new THREE.Mesh(new THREE.TorusGeometry(0.18, 0.022, 8, 24), M.std(0x111111, 0.6)); wheel.position.set(dashX - 0.35, 1.05, 0.38); wheel.rotation.set(0, Math.PI / 2, 0); wheel.rotateX(0.35); g.add(wheel); g.userData.steering = wheel;
  const col = cyl(0.025, 0.025, 0.3, darkMetal, 6); col.position.set(dashX - 0.22, 1.0, 0.38); col.rotation.z = Math.PI / 2 - 0.35; g.add(col);
  const seatMat = M.std(burned ? 0x0e0d0c : 0x2b2b2e, 0.9);
  for (const z of [0.38, -0.38]) { const s1 = rbox(0.5, 0.15, 0.5, seatMat, 0.06); s1.position.set(dashX - 0.85, 0.65, z); g.add(s1); const s2 = rbox(0.12, 0.7, 0.48, seatMat, 0.05); s2.position.set(dashX - 1.12, 1.0, z); s2.rotation.z = -0.15; g.add(s2); }
  g.userData.seat = new THREE.Vector3(dashX - 0.85, 1.32, 0.38);
  g.userData.len = P.len; g.userData.width = P.w; g.userData.type = type;
  if (burned) { for (let i = 0; i < 5; i++) { const s = new THREE.Mesh(new THREE.SphereGeometry(0.3 + Math.random() * 0.2, 8, 6), M.std(0x2a1d14, 1)); s.scale.y = 0.3; s.position.set((Math.random() - 0.5) * P.len, 0.6 + Math.random() * 0.5, (Math.random() - 0.5) * P.w); g.add(s); } }
  // חורי כדורים (דקאלים קטנים כהים)
  if (opts.bulletHoles) for (let i = 0; i < opts.bulletHoles; i++) { const h = new THREE.Mesh(new THREE.CircleGeometry(0.025, 8), M.std(0x050505, 1)); const s = Math.random() < 0.5 ? 1 : -1; h.position.set((Math.random() - 0.5) * P.len * 0.7, 0.6 + Math.random() * 0.5, s * (P.w / 2 + 0.081)); h.rotation.y = s > 0 ? 0 : Math.PI; g.add(h); }
  return shadow(g);
}

export function buildMotorbike(color = 0x8a1d1d) {
  const g = new THREE.Group();
  const paint = new THREE.MeshPhysicalMaterial({ color, roughness: 0.35, metalness: 0.5, clearcoat: 0.6 });
  for (const x of [-0.7, 0.7]) { const t = new THREE.Mesh(new THREE.TorusGeometry(0.3, 0.08, 10, 24), rubber); t.position.set(x, 0.38, 0); g.add(t); const hub = cyl(0.08, 0.08, 0.12, metal, 10); hub.rotation.x = Math.PI / 2; hub.position.set(x, 0.38, 0); g.add(hub); }
  const tank = new THREE.Mesh(new THREE.CapsuleGeometry(0.16, 0.35, 4, 10), paint); tank.rotation.z = Math.PI / 2 + 0.1; tank.position.set(0.15, 0.9, 0); tank.scale.set(1, 1, 0.8); g.add(tank);
  const seat = new THREE.Mesh(new THREE.CapsuleGeometry(0.12, 0.45, 4, 10), M.std(0x151515, 0.8)); seat.rotation.z = Math.PI / 2; seat.position.set(-0.3, 0.88, 0); seat.scale.set(0.6, 1, 0.9); g.add(seat);
  const eng = rbox(0.4, 0.3, 0.28, darkMetal, 0.05); eng.position.set(0.05, 0.55, 0); g.add(eng);
  const fork = cyl(0.025, 0.025, 0.8, metal, 6); fork.position.set(0.6, 0.75, 0); fork.rotation.z = 0.35; g.add(fork);
  const bar = cyl(0.02, 0.02, 0.7, darkMetal, 6); bar.rotation.x = Math.PI / 2; bar.position.set(0.48, 1.12, 0); g.add(bar);
  const hl = new THREE.Mesh(new THREE.SphereGeometry(0.09, 12, 8), M.emit(0xfff2d8, 0.2)); hl.position.set(0.62, 1.0, 0); g.add(hl);
  const frame = cyl(0.03, 0.03, 1.1, darkMetal, 6); frame.rotation.z = Math.PI / 2 - 0.2; frame.position.set(-0.05, 0.65, 0); g.add(frame);
  g.userData.headMats = [hl.material]; g.userData.wheels = []; g.userData.seat = new THREE.Vector3(-0.25, 1.55, 0); g.userData.len = 1.9; g.userData.width = 0.6; g.userData.type = 'bike';
  return shadow(g);
}

// ─────────────── צמחייה וסלעים ───────────────
function displacedBlob(radius, detail, amp, seed) {
  const geo = new THREE.IcosahedronGeometry(radius, detail);
  const p = geo.attributes.position; const v = new THREE.Vector3();
  for (let i = 0; i < p.count; i++) { v.fromBufferAttribute(p, i); const n = fbm(v.x * 2 + seed, v.z * 2 + v.y * 1.7 + seed, 3); v.multiplyScalar(1 + (n - 0.5) * amp); p.setXYZ(i, v.x, v.y, v.z); }
  geo.computeVertexNormals(); return geo;
}
const treeCache = {};
/** עץ אקליפטוס/אשל: גזע מתפצל + אשכולות עלווה */
export function buildTree(kind = 'eucalyptus', seed = 1) {
  const key = kind + (seed % 4);
  if (!treeCache[key]) {
    const trunkMat = M.std(kind === 'eucalyptus' ? 0xb9ad98 : 0x5a4a3a, 0.9);
    const leafMat = M.std(kind === 'eucalyptus' ? 0x5d7350 : kind === 'olive' ? 0x7d8a5f : 0x6b7655, 0.85, 0, { flatShading: false });
    const parts = { trunk: [], leaf: [] };
    const rnd = (() => { let s = seed * 9301 + 49297; return () => ((s = (s * 9301 + 49297) % 233280) / 233280); })();
    const H = kind === 'eucalyptus' ? 9 + rnd() * 3 : kind === 'olive' ? 3.5 : 5;
    const branch = (start, dir, len, rad, depth) => {
      const end = start.clone().add(dir.clone().multiplyScalar(len));
      const mid = start.clone().lerp(end, 0.5).add(new THREE.Vector3((rnd() - 0.5) * 0.4, 0, (rnd() - 0.5) * 0.4));
      const curve = new THREE.CatmullRomCurve3([start, mid, end]);
      parts.trunk.push(new THREE.TubeGeometry(curve, 6, rad, 7, false));
      if (depth >= 3 || len < 0.6) { parts.leaf.push(displacedBlob(0.9 + rnd() * 0.9, 1, 0.6, rnd() * 10).translate(end.x, end.y, end.z)); return; }
      const n = 2 + (rnd() < 0.4 ? 1 : 0);
      for (let i = 0; i < n; i++) { const d = dir.clone().add(new THREE.Vector3((rnd() - 0.5) * 1.4, 0.35 + rnd() * 0.3, (rnd() - 0.5) * 1.4)).normalize(); branch(end, d, len * (0.6 + rnd() * 0.15), rad * 0.62, depth + 1); }
    };
    branch(new THREE.Vector3(0, 0, 0), new THREE.Vector3(0, 1, 0), H * 0.42, kind === 'eucalyptus' ? 0.22 : 0.18, 0);
    const merge = arr => { const { mergeSimple } = TERR; return mergeSimple(arr); };
    treeCache[key] = { trunk: new THREE.Mesh(merge(parts.trunk), trunkMat), leaf: new THREE.Mesh(merge(parts.leaf), leafMat) };
  }
  const g = new THREE.Group(); const c = treeCache[key];
  const t = c.trunk.clone(), l = c.leaf.clone(); t.castShadow = l.castShadow = true; t.receiveShadow = l.receiveShadow = true; g.add(t, l);
  g.userData.leaf = l;
  return g;
}
import * as TERR from './terrain.js';
export function buildBush(seed = 1, color = 0x6b6a45, size = 1) {
  const g = new THREE.Group();
  const mat = M.std(color, 0.9);
  for (let i = 0; i < 4; i++) { const b = new THREE.Mesh(displacedBlob(0.45 + (i % 2) * 0.2, 1, 0.8, seed + i), mat); b.position.set(Math.cos(i * 2.1 + seed) * 0.4, 0.35 + (i % 2) * 0.15, Math.sin(i * 2.1 + seed) * 0.4); b.scale.y = 0.8; g.add(b); }
  g.scale.setScalar(size);
  return shadow(g);
}
export function buildRock(seed = 1, size = 1, mat) {
  const m = new THREE.Mesh(displacedBlob(1, 2, 0.7, seed), mat || Materials.pbr('dry_ground_01', 1, { color: 0xc8b89a }));
  m.scale.set(size * (1 + (seed % 3) * 0.2), size * 0.6, size); m.castShadow = m.receiveShadow = true;
  return m;
}

// ─────────────── שונות ───────────────
export function buildLightTower(on = true) {
  const g = new THREE.Group();
  const trailer = rbox(1.8, 0.9, 1.2, M.std(0xe0b020, 0.6, 0.2), 0.08); trailer.position.y = 0.75; g.add(trailer);
  const mast = cyl(0.06, 0.08, 6, metal, 8); mast.position.y = 4.2; g.add(mast);
  const lamps = new THREE.Group(); lamps.position.y = 7.2; g.add(lamps);
  for (const [x, y] of [[-0.35, 0.2], [0.35, 0.2], [-0.35, -0.2], [0.35, -0.2]]) { const h = rbox(0.5, 0.35, 0.18, darkMetal, 0.04); h.position.set(x, y, 0); lamps.add(h); const lens = new THREE.Mesh(new THREE.PlaneGeometry(0.44, 0.3), M.emit(0xfff1d6, on ? 5 : 0.05)); lens.position.set(x, y, 0.1); lamps.add(lens); }
  lamps.rotation.x = 0.5;
  for (const x of [-0.6, 0.6]) { const w = new THREE.Mesh(new THREE.TorusGeometry(0.25, 0.08, 8, 16), rubber); w.position.set(x, 0.3, 0.62); g.add(w); }
  return shadow(g);
}
export function buildFlagPole(color = 0xff6b4a, h = 6) {
  const g = new THREE.Group(); const p = cyl(0.03, 0.04, h, M.std(0xd9d9d9, 0.4, 0.6), 6); p.position.y = h / 2; g.add(p);
  const geo = new THREE.PlaneGeometry(0.7, 2.6, 4, 12); geo.translate(0.35, 0, 0);
  const flag = new THREE.Mesh(geo, M.std(color, 0.8, 0, { side: THREE.DoubleSide })); flag.position.y = h - 1.4; g.add(flag);
  g.userData.flag = flag; g.userData.base = geo.attributes.position.array.slice();
  g.userData.update = (t) => { const p = geo.attributes.position, b = g.userData.base; for (let i = 0; i < p.count; i++) { const x = b[i * 3], y = b[i * 3 + 1]; p.setZ(i, Math.sin(t * 3 + x * 4 + y * 0.8) * 0.12 * x); } p.needsUpdate = true; };
  return g;
}
export function buildFence(len = 10, mat) {
  const g = new THREE.Group(); const pm = mat || M.std(0x7a7a72, 0.6, 0.6);
  const n = Math.max(2, Math.round(len / 2.5));
  for (let i = 0; i <= n; i++) { const p = cyl(0.03, 0.03, 1.9, pm, 6); p.position.set(-len / 2 + i * len / n, 0.95, 0); g.add(p); }
  const meshTex = canvasTex(64, 64, (c, W, H) => { c.clearRect(0, 0, W, H); c.strokeStyle = '#9a9a92'; c.lineWidth = 2; for (let i = -64; i < 128; i += 12) { c.beginPath(); c.moveTo(i, 0); c.lineTo(i + 64, 64); c.stroke(); c.beginPath(); c.moveTo(i + 64, 0); c.lineTo(i, 64); c.stroke(); } });
  meshTex.repeat.set(len / 0.8, 2.2);
  const net = new THREE.Mesh(new THREE.PlaneGeometry(len, 1.8), new THREE.MeshStandardMaterial({ map: meshTex, transparent: true, alphaTest: 0.3, side: THREE.DoubleSide, metalness: 0.5, roughness: 0.5 })); net.position.y = 0.95; g.add(net);
  return g;
}
export function buildPortaToilet(color = 0x2b7bd6) {
  const g = new THREE.Group(); const b = rbox(1.15, 2.3, 1.15, M.std(color, 0.6), 0.08); b.position.y = 1.15; g.add(b);
  const roof = new THREE.Mesh(new THREE.SphereGeometry(0.72, 16, 8, 0, Math.PI * 2, 0, Math.PI / 2), M.std(0xf2f2f2, 0.5)); roof.scale.y = 0.25; roof.position.y = 2.3; g.add(roof);
  const door = rbox(0.8, 1.9, 0.04, M.std(new THREE.Color(color).multiplyScalar(0.85), 0.6), 0.02); door.position.set(0, 1.05, 0.58); g.add(door);
  return shadow(g);
}
/** דקאל כתם (דם כהה וקרוש / פיח) – לא גרפי, רחוק וחלקי */
const decalTexCache = {};
export function buildStain(kind = 'blood', size = 1, seed = 1) {
  const key = kind + (seed % 5);
  if (!decalTexCache[key]) decalTexCache[key] = canvasTex(256, 256, (c, W, H) => {
    c.clearRect(0, 0, W, H);
    const col = kind === 'blood' ? [68, 12, 10] : kind === 'soot' ? [15, 12, 10] : [40, 30, 20];
    let s = seed * 17; const r = () => ((s = (s * 9301 + 49297) % 233280) / 233280);
    for (let i = 0; i < 40; i++) { const x = W / 2 + (r() - 0.5) * W * 0.6, y = H / 2 + (r() - 0.5) * H * 0.6, rad = 8 + r() * 45; const gr = c.createRadialGradient(x, y, 0, x, y, rad); gr.addColorStop(0, `rgba(${col},${0.55 + r() * 0.3})`); gr.addColorStop(1, `rgba(${col},0)`); c.fillStyle = gr; c.beginPath(); c.arc(x, y, rad, 0, 7); c.fill(); }
  });
  const m = new THREE.Mesh(new THREE.PlaneGeometry(size, size), new THREE.MeshStandardMaterial({ map: decalTexCache[key], transparent: true, depthWrite: false, roughness: kind === 'blood' ? 0.5 : 1, polygonOffset: true, polygonOffsetFactor: -2 }));
  m.rotation.x = -Math.PI / 2; m.rotation.z = seed; m.receiveShadow = true; m.renderOrder = 2;
  return m;
}
export function buildBulletHoles(n = 6, spread = 1) {
  const g = new THREE.Group(); const mat = new THREE.MeshBasicMaterial({ color: 0x080606 }); const ring = new THREE.MeshStandardMaterial({ color: 0x6b6458, roughness: 1 });
  for (let i = 0; i < n; i++) { const h = new THREE.Mesh(new THREE.CircleGeometry(0.02 + Math.random() * 0.012, 8), mat); const r = new THREE.Mesh(new THREE.RingGeometry(0.025, 0.05, 10), ring); const x = (Math.random() - 0.5) * spread, y = (Math.random() - 0.5) * spread * 0.6; h.position.set(x, y, 0.002); r.position.set(x, y, 0.001); g.add(h, r); }
  return g;
}
export function buildJerrycan(color = 0x3f5d2a) { const m = rbox(0.35, 0.45, 0.17, M.std(color, 0.6), 0.04); m.position.y = 0.23; return m; }
export function buildPallet() { const g = new THREE.Group(); const w = Materials.pbr('wood_planks', 0.5, { color: 0xa88a62 }); for (let i = 0; i < 5; i++) { const b = rbox(1.2, 0.03, 0.16, w, 0.01); b.position.set(0, 0.13, -0.5 + i * 0.25); g.add(b); } for (const x of [-0.5, 0, 0.5]) { const b = rbox(0.1, 0.1, 1.2, w, 0.01); b.position.set(x, 0.06, 0); g.add(b); } return shadow(g); }

// ─────────────── שמיים ───────────────
export function buildNightSky() {
  const geo = new THREE.SphereGeometry(900, 32, 16);
  const mat = new THREE.ShaderMaterial({
    side: THREE.BackSide, depthWrite: false,
    uniforms: { uTime: { value: 0 }, uDawn: { value: 0 } },
    vertexShader: `varying vec3 vP; void main(){ vP = normalize(position); gl_Position = projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
    fragmentShader: `varying vec3 vP; uniform float uTime; uniform float uDawn;
      float h(vec3 p){ return fract(sin(dot(p, vec3(12.9898,78.233,37.719)))*43758.5453); }
      void main(){
        float y = vP.y;
        vec3 top = mix(vec3(0.012,0.01,0.04), vec3(0.18,0.22,0.42), uDawn);
        vec3 hor = mix(vec3(0.07,0.045,0.14), vec3(0.95,0.55,0.35), uDawn);
        vec3 col = mix(hor, top, smoothstep(-0.05, 0.5, y));
        // שביל החלב
        float band = exp(-pow(dot(vP, normalize(vec3(0.6,0.5,-0.6)))*3.2, 2.0));
        col += vec3(0.08,0.07,0.12) * band * (1.0-uDawn) * smoothstep(0.0,0.3,y);
        // כוכבים
        vec3 g = floor(vP*420.0); float s = h(g); float star = step(0.9965, s) * (0.6+0.4*sin(uTime*2.0+s*50.0));
        col += vec3(star) * (1.0-uDawn) * smoothstep(0.02, 0.2, y) * (0.5 + band);
        // הילה ירוקה-סגולה של אורות המסיבה באופק
        col += vec3(0.25,0.05,0.25) * exp(-max(y,0.0)*18.0) * 0.35 * (1.0-uDawn);
        gl_FragColor = vec4(col, 1.0);
      }`,
  });
  const m = new THREE.Mesh(geo, mat); m.name = 'sky'; m.frustumCulled = false; m.renderOrder = -10;
  return m;
}
