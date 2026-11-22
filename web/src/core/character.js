// ═══════════════════════════════════════════════════════════════════
//  Character – דמויות אנושיות פרוצדורליות כ-SkinnedMesh רציף עם שלד אמיתי.
//  גוף חלק אחד (טורסו, גפיים, ראש מפוסל, שיער, נעליים, אביזרים) = draw call אחד.
//  פנים: עיניים, עפעפיים (מצמוץ), פה (דיבור). אנימציות פרוצדורליות.
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';

export const SKIN = ['#f1d1b5', '#e2b48f', '#c99169', '#a4704a', '#7a4e33', '#5b3826'];
export const HAIR_COL = ['#1d1410', '#3b2517', '#6b4426', '#a8743d', '#d9b47a', '#5a5a5a', '#d8d8d8'];
export const OUTFITS = [ // [top, bottom, shoes, accent, sleeve(0..1), pants(0 shorts..1 long)]
  ['#f2efe9', '#2d3e57', '#e9e4da', '#ff6b4a', 0.25, 1],
  ['#ff4f8b', '#3a3f45', '#2a2a2a', '#39e0ff', 0.0, 0.35],
  ['#ffcf4a', '#6b5b45', '#5a4632', '#2c8f7a', 0.3, 1],
  ['#3d4a5c', '#232629', '#cfcac0', '#ffb347', 1, 1],
  ['#5b6b3e', '#4b4033', '#3a2c20', '#e8d27c', 0.3, 1],
];
const BONES = ['hips', 'spine', 'chest', 'neck', 'head', 'shL', 'elL', 'haL', 'shR', 'elR', 'haR', 'thL', 'knL', 'ftL', 'thR', 'knR', 'ftR'];
const BI = Object.fromEntries(BONES.map((b, i) => [b, i]));

// ───── טקסטורת פרטים (בד/עור) – normal map פרוצדורלי ─────
let detailNormal = null;
function getDetailNormal() {
  if (detailNormal) return detailNormal;
  const N = 128; const c = document.createElement('canvas'); c.width = c.height = N; const g = c.getContext('2d');
  const h = new Float32Array(N * N);
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) h[y * N + x] = (Math.sin(x * 0.8) * 0.5 + Math.sin(y * 0.8) * 0.5) * 0.35 + Math.random() * 0.5;
  const id = g.createImageData(N, N);
  for (let y = 0; y < N; y++) for (let x = 0; x < N; x++) {
    const dx = h[y * N + (x + 1) % N] - h[y * N + (x - 1 + N) % N], dy = h[((y + 1) % N) * N + x] - h[((y - 1 + N) % N) * N + x];
    const i = (y * N + x) * 4; id.data[i] = 128 + dx * 40; id.data[i + 1] = 128 + dy * 40; id.data[i + 2] = 255; id.data[i + 3] = 255;
  }
  g.putImageData(id, 0, 0);
  detailNormal = new THREE.CanvasTexture(c); detailNormal.wrapS = detailNormal.wrapT = THREE.RepeatWrapping; detailNormal.repeat.set(40, 40);
  return detailNormal;
}
function bodyMaterial() {
  const m = new THREE.MeshStandardMaterial({ vertexColors: true, roughness: 0.72, metalness: 0, normalMap: getDetailNormal(), normalScale: new THREE.Vector2(0.25, 0.25) });
  // אור "רך" על עור: מעט wrap lighting לתחושת subsurface
  m.onBeforeCompile = sh => {
    sh.fragmentShader = sh.fragmentShader.replace('#include <lights_fragment_end>', `#include <lights_fragment_end>
      float skinMask = smoothstep(0.35, 0.6, vColor.r - vColor.b);
      reflectedLight.directDiffuse += reflectedLight.directDiffuse * vec3(0.1, 0.03, 0.02) * skinMask;
      reflectedLight.indirectDiffuse += vec3(0.006, 0.003, 0.002) * skinMask;`);
  };
  return m;
}

const tmpC = new THREE.Color();
const hex = (h) => tmpC.set(h).clone();
function mixC(a, b, t) { return a.clone().lerp(b, t); }

/** בונה גיאומטריה מעור עם משקלי שלד וצבעים מפונקציות */
function finalize(geo, colorFn, weightFn) {
  if (geo.index) geo = geo.toNonIndexed();
  for (const k of Object.keys(geo.attributes)) if (!['position', 'normal'].includes(k)) geo.deleteAttribute(k);
  const p = geo.attributes.position, n = p.count;
  const col = new Float32Array(n * 3), si = new Uint16Array(n * 4), sw = new Float32Array(n * 4);
  const v = new THREE.Vector3();
  for (let i = 0; i < n; i++) {
    v.fromBufferAttribute(p, i);
    const c = colorFn(v); const jit = 1 + (Math.sin(v.x * 91 + v.y * 37 + v.z * 53) * 0.5) * 0.03;
    col[i * 3] = c.r * jit; col[i * 3 + 1] = c.g * jit; col[i * 3 + 2] = c.b * jit;
    const w = weightFn(v);
    for (let k = 0; k < 4; k++) { si[i * 4 + k] = w[k] ? w[k][0] : 0; sw[i * 4 + k] = w[k] ? w[k][1] : 0; }
  }
  geo.setAttribute('color', new THREE.BufferAttribute(col, 3));
  geo.setAttribute('skinIndex', new THREE.BufferAttribute(si, 4));
  geo.setAttribute('skinWeight', new THREE.BufferAttribute(sw, 4));
  return geo;
}
const rigid = (b) => () => [[BI[b], 1]];
const solid = (c) => () => c;
/** טיובה לאורך רשימת נקודות אנכיות-בעיקר, rFn(s) → [rx, rz] */
function tube(points, rFn, seg = 14, rings = 24, capTop = true, capBot = true) {
  const pos = []; const idx = [];
  const total = points.reduce((a, p, i) => i ? a + p.distanceTo(points[i - 1]) : 0, 0);
  const at = (s) => { let d = s * total; for (let i = 1; i < points.length; i++) { const L = points[i].distanceTo(points[i - 1]); if (d <= L || i === points.length - 1) return points[i - 1].clone().lerp(points[i], Math.min(1, d / L)); d -= L; } return points[points.length - 1].clone(); };
  const ringList = [];
  const capN = 4;
  if (capTop) for (let k = 0; k < capN; k++) ringList.push({ s: 0, f: Math.sin((k / capN) * Math.PI / 2), off: Math.cos((k / capN) * Math.PI / 2) });
  for (let r = 0; r <= rings; r++) ringList.push({ s: r / rings, f: 1, off: 0 });
  if (capBot) for (let k = capN - 1; k >= 0; k--) ringList.push({ s: 1, f: Math.sin((k / capN) * Math.PI / 2), off: -Math.cos((k / capN) * Math.PI / 2) });
  ringList.forEach((R, ri) => {
    const c = at(R.s); const [rx, rz, ox = 0, oz = 0] = rFn(R.s);
    const dir = at(Math.min(1, R.s + 0.01)).sub(at(Math.max(0, R.s - 0.01))).normalize();
    c.addScaledVector(dir, -R.off * Math.min(rx, rz) * 0.9);
    for (let k = 0; k < seg; k++) { const a = k / seg * Math.PI * 2; pos.push(c.x + ox + Math.cos(a) * rx * R.f, c.y, c.z + oz + Math.sin(a) * rz * R.f); }
    if (ri > 0) { const b = (ri - 1) * seg, t = ri * seg; for (let k = 0; k < seg; k++) { const k2 = (k + 1) % seg; idx.push(b + k, t + k, b + k2, b + k2, t + k, t + k2); } }
  });
  const g = new THREE.BufferGeometry(); g.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); g.setIndex(idx); g.computeVertexNormals();
  return g;
}
function ellipsoid(c, r, ws = 16, hs = 12) { const g = new THREE.SphereGeometry(1, ws, hs); g.scale(r[0], r[1], r[2]); g.translate(c[0], c[1], c[2]); return g; }
function rboxGeo(c, s, rot) { const g = new THREE.CapsuleGeometry(Math.min(s[0], s[2]) / 2, Math.max(0.001, s[1] - Math.min(s[0], s[2])), 3, 10); g.scale(s[0] / Math.min(s[0], s[2]), 1, s[2] / Math.min(s[0], s[2])); if (rot) g.rotateX(rot[0] || 0).rotateY(rot[1] || 0).rotateZ(rot[2] || 0); g.translate(...c); return g; }
function lerpW(y, stops) { // stops: [[y, bone], ...] עולה
  if (y <= stops[0][0]) return [[BI[stops[0][1]], 1]];
  for (let i = 1; i < stops.length; i++) if (y <= stops[i][0]) { const t = (y - stops[i - 1][0]) / (stops[i][0] - stops[i - 1][0]); const s = t * t * (3 - 2 * t); return [[BI[stops[i - 1][1]], 1 - s], [BI[stops[i][1]], s]]; }
  return [[BI[stops[stops.length - 1][1]], 1]];
}

const MAT_EYE = new THREE.MeshStandardMaterial({ color: 0xf2eee6, roughness: 0.12 });
const MAT_PUPIL = new THREE.MeshStandardMaterial({ color: 0x050505, roughness: 0.05 });
const MAT_MOUTH = new THREE.MeshStandardMaterial({ color: 0x3a1414, roughness: 0.7 });
export const MAT_GHOST = new THREE.MeshStandardMaterial({ color: 0x9fd8ff, transparent: true, opacity: 0.28, roughness: 0.3, emissive: 0x2a5a80, emissiveIntensity: 0.5, depthWrite: false });
const sharedBodyMat = { v: null };

export class Character {
  constructor(o = {}) {
    this.o = o = Object.assign({ skin: SKIN[2], hair: 0, hairColor: HAIR_COL[1], outfit: OUTFITS[0], build: 1, height: 1, gender: 'm', detail: true, acc: [], terrorist: false, eyes: '#3a2414', age: 0 }, o);
    const fem = o.gender === 'f', B = o.build, T = o.terrorist;
    const out = o.outfit;
    const C = {
      skin: hex(o.skin), hair: hex(o.hairColor),
      top: hex(T ? '#2a2c25' : out[0]), bottom: hex(T ? '#26281f' : out[1]), shoes: hex(T ? '#1a1916' : out[2]), accent: hex(T ? '#1d7a33' : out[3]),
      lips: hex(o.skin).lerp(new THREE.Color('#8f3f3e'), 0.55), brow: hex(o.hairColor).multiplyScalar(0.8),
      mask: hex('#121212'), green: hex('#1f7a34'), vest: hex('#33362b'), pouch: hex('#3b3e31'), glove: hex('#1e1e1b'),
    };
    const sleeve = T ? 1 : out[4], pants = T ? 1 : out[5];
    // ─ מיקומי מנוחה של העצמות ─
    const sw = (fem ? 0.175 : 0.195) * B, hw = 0.092 * B;
    const RP = {
      hips: [0, 0.94, 0], spine: [0, 1.04, 0], chest: [0, 1.24, 0], neck: [0, 1.47, 0], head: [0, 1.56, 0],
      shL: [sw, 1.425, 0], elL: [sw + 0.01, 1.15, -0.005], haL: [sw + 0.015, 0.9, 0.01],
      shR: [-sw, 1.425, 0], elR: [-sw - 0.01, 1.15, -0.005], haR: [-sw - 0.015, 0.9, 0.01],
      thL: [hw, 0.92, 0], knL: [hw, 0.5, 0.01], ftL: [hw, 0.08, 0],
      thR: [-hw, 0.92, 0], knR: [-hw, 0.5, 0.01], ftR: [-hw, 0.08, 0],
    };
    const V = (k, dx = 0, dy = 0, dz = 0) => new THREE.Vector3(RP[k][0] + dx, RP[k][1] + dy, RP[k][2] + dz);
    const parts = [];
    const seg = o.detail ? 1 : 0.6;
    const S = (n) => Math.max(6, Math.round(n * seg));

    // ─ טורסו ─
    const torsoProfile = (y) => { // [rx, rz, oz]
      const k = [
        [0.80, 0.09, 0.07, 0], [0.84, 0.15 * B, 0.1, 0], [0.9, (fem ? 0.172 : 0.162) * B, 0.11, 0], [0.96, (fem ? 0.165 : 0.152) * B, 0.105, 0], [1.03, (fem ? 0.138 : 0.145) * B, 0.095, 0.005],
        [1.12, (fem ? 0.128 : 0.145) * B, 0.098, 0.01], [1.24, (fem ? 0.15 : 0.165) * B, 0.11, 0.012], [1.34, (fem ? 0.165 : 0.182) * B, 0.112, 0.008],
        [1.41, (fem ? 0.188 : 0.212) * B, 0.098, 0], [1.445, (fem ? 0.17 : 0.19) * B, 0.085, -0.005], [1.47, (fem ? 0.125 : 0.14) * B, 0.075, -0.005], [1.49, 0.085, 0.062, -0.004], [1.505, 0.055, 0.048, 0],
      ];
      for (let i = 1; i < k.length; i++) if (y <= k[i][0]) { const t = (y - k[i - 1][0]) / (k[i][0] - k[i - 1][0]); const s = t * t * (3 - 2 * t); return [k[i - 1][1] + (k[i][1] - k[i - 1][1]) * s, k[i - 1][2] + (k[i][2] - k[i - 1][2]) * s, k[i - 1][3] + (k[i][3] - k[i - 1][3]) * s]; }
      return [0.05, 0.05, 0];
    };
    {
      const g = tube([new THREE.Vector3(0, 1.505, 0), new THREE.Vector3(0, 0.8, 0)], s => { const y = 1.505 - s * 0.705; const [rx, rz, oz] = torsoProfile(y); return [rx, rz, 0, oz]; }, S(22), S(30), false, true);
      // חזה נשי / שרירי חזה – עיוות רך
      const p = g.attributes.position; const v = new THREE.Vector3();
      for (let i = 0; i < p.count; i++) { v.fromBufferAttribute(p, i); if (v.z > 0) { const bump = Math.exp(-(((v.y - 1.29) / 0.06) ** 2)) * Math.exp(-(((Math.abs(v.x) - 0.075) / 0.06) ** 2)); v.z += bump * (fem ? 0.045 : 0.012); } if (v.z < 0 && v.y > 1.3) v.z -= Math.exp(-(((Math.abs(v.x) - 0.08) / 0.07) ** 2)) * 0.01; p.setXYZ(i, v.x, v.y, v.z); }
      g.computeVertexNormals();
      const beltY = 0.95;
      parts.push(finalize(g, v => {
        if (T) { if (v.y > 1.0 && v.y < 1.4) return C.vest; return v.y > beltY ? C.top : C.bottom; }
        if (v.y > 1.43) return C.skin.clone().multiplyScalar(0.97);
        if (v.y > beltY + 0.02) { if (out === OUTFITS[2] && v.z > 0.08 && Math.abs(v.x) < 0.09 && v.y > 1.15 && v.y < 1.35) return (Math.sin(v.x * 80) * Math.sin(v.y * 80) > 0.2) ? C.accent : C.top; return C.top; }
        if (v.y > beltY - 0.01) return C.bottom.clone().multiplyScalar(0.8);
        return C.bottom;
      }, v => lerpW(v.y, [[0.9, 'hips'], [1.06, 'spine'], [1.3, 'chest'], [1.49, 'neck']])));
    }
    // ─ צוואר ─
    parts.push(finalize(tube([new THREE.Vector3(0, 1.585, -0.008), new THREE.Vector3(0, 1.45, 0.0)], s => [0.05 + s * 0.012, 0.053 + s * 0.012], S(14), 6, false, false), v => (T ? C.mask : C.skin), v => lerpW(v.y, [[1.5, 'neck'], [1.6, 'head']])));
    // ─ זרועות ─
    const armR = (fem ? 0.04 : 0.046) * B;
    for (const side of ['L', 'R']) {
      const sh = 'sh' + side, el = 'el' + side, ha = 'ha' + side;
      const sxa = side === 'L' ? 1 : -1;
      const pts = [V(sh, -sxa * 0.02, 0.0, 0), V(el), V(ha, 0, 0.02, 0)];
      const g = tube(pts, s => { const r = s < 0.5 ? armR * (1.1 - s * 0.3) : armR * (0.95 - (s - 0.5) * 0.45); return [r, r * 0.92]; }, S(12), S(18), false, false);
      const elbowY = RP[el][1], wristY = RP[ha][1] + 0.02, shY = RP[sh][1];
      parts.push(finalize(g, v => {
        const t = (shY - v.y) / (shY - wristY); // 0 כתף → 1 שורש כף יד
        if (T) return t > 0.92 ? C.glove : C.top;
        if (t < sleeve * 0.98 + 0.02 || (sleeve === 0 && t < 0.03)) return sleeve === 0 ? C.skin : C.top;
        return C.skin;
      }, v => { const w = lerpW(-v.y, [[-shY - 0.02, 'chest'], [-shY + 0.06, sh], [-elbowY - 0.04, sh], [-elbowY + 0.04, el], [-wristY - 0.03, el], [-wristY + 0.02, ha]]); return w; }));
      const sx = side === 'L' ? 1 : -1;
      // כף יד: כף + אצבעות
      const hp = [];
      const hc = RP[ha];
      hp.push(ellipsoid([hc[0] + sx * 0.003, hc[1] - 0.04, hc[2] + 0.004], [0.022, 0.045, 0.035], S(10), S(8)));
      for (let f = 0; f < 4; f++) {
        const fz = -0.022 + f * 0.0148, len = [0.065, 0.075, 0.07, 0.056][f];
        const fg = new THREE.CapsuleGeometry(0.0085, len, 3, 6); fg.translate(0, -len / 2, 0); fg.rotateZ(sx * 0.08); fg.rotateX(-0.12);
        fg.translate(hc[0] + sx * 0.004, hc[1] - 0.075, hc[2] + fz + 0.004); hp.push(fg);
      }
      const th = new THREE.CapsuleGeometry(0.01, 0.045, 3, 6); th.rotateX(-0.6); th.rotateZ(sx * 0.15); th.translate(hc[0] - sx * 0.002, hc[1] - 0.05, hc[2] + 0.035); hp.push(th);
      for (const g2 of hp) parts.push(finalize(g2, v => (T ? C.glove : C.skin), rigid(ha)));
    }
    // ─ רגליים ─
    const legR = (fem ? 0.068 : 0.072) * B;
    for (const side of ['L', 'R']) {
      const th = 'th' + side, kn = 'kn' + side, ft = 'ft' + side;
      const pts = [V(th, 0, 0.02, 0), V(kn), V(ft, 0, 0.03, 0)];
      const g = tube(pts, s => { const r = s < 0.5 ? legR * (1.12 - s * 0.55) : legR * (0.86 - (s - 0.5) * 0.55); const calf = s > 0.55 && s < 0.8 ? Math.sin((s - 0.55) / 0.25 * Math.PI) * 0.008 : 0; return [r, r * 0.95 + calf, 0, -calf * 0.5]; }, S(14), S(22), false, false);
      const kneeY = RP[kn][1], ankY = RP[ft][1] + 0.03, hipY = RP[th][1] + 0.02;
      parts.push(finalize(g, v => {
        const t = (hipY - v.y) / (hipY - ankY);
        if (T) return t > 0.82 ? C.shoes : C.bottom;
        return t < pants * 0.92 + 0.08 ? C.bottom : C.skin;
      }, v => lerpW(-v.y, [[-hipY, 'hips'], [-hipY + 0.07, th], [-kneeY - 0.05, th], [-kneeY + 0.05, kn], [-ankY - 0.04, kn], [-ankY + 0.02, ft]])));
      // נעל
      const fc = RP[ft];
      const shoe = rboxGeo([fc[0], fc[1] - 0.035, fc[2] + 0.045], [0.095, 0.09, 0.25], [Math.PI / 2, 0, 0]);
      parts.push(finalize(shoe, v => (v.y < fc[1] - 0.07 ? C.shoes.clone().multiplyScalar(T ? 0.8 : 0.55) : C.shoes), rigid(ft)));
      if (T) parts.push(finalize(tube([new THREE.Vector3(fc[0], fc[1] + 0.2, fc[2]), new THREE.Vector3(fc[0], fc[1] - 0.03, fc[2])], () => [0.058, 0.06], S(12), 4, true, false), solid(C.shoes), v => lerpW(v.y, [[fc[1], ft], [fc[1] + 0.15, kn]])));
    }
    // ─ ראש מפוסל ─
    const HC = new THREE.Vector3(0, 1.66, 0.008);
    const HR = new THREE.Vector3(fem ? 0.094 : 0.099, 0.12, fem ? 0.106 : 0.11);
    {
      const g = new THREE.SphereGeometry(1, S(34), S(26));
      const p = g.attributes.position; const v = new THREE.Vector3();
      for (let i = 0; i < p.count; i++) {
        v.fromBufferAttribute(p, i); // יחידתי
        let { x, y, z } = v;
        // לסת וסנטר: צמצום ברוחב בחלק התחתון הקדמי
        const lower = Math.max(0, -y);
        x *= 1 - lower * (fem ? 0.38 : 0.3) * (0.6 + 0.4 * Math.max(0, z));
        if (y < -0.55 && z > 0.2) z += (fem ? 0.04 : 0.07) * (1 - Math.abs(x) * 2);
        // עצמות לחיים
        const cheek = Math.exp(-(((y + 0.1) / 0.18) ** 2)) * Math.exp(-(((Math.abs(x) - 0.62) / 0.2) ** 2)) * Math.max(0, z);
        x += Math.sign(x) * cheek * 0.04; z += cheek * 0.03;
        // שקעי עיניים + קשת גבות
        const eyeS = Math.exp(-(((y - 0.12) / 0.12) ** 2)) * Math.exp(-(((Math.abs(x) - 0.36) / 0.16) ** 2)) * Math.max(0, z);
        z -= eyeS * 0.08;
        const brow = Math.exp(-(((y - 0.3) / 0.08) ** 2)) * Math.exp(-(((Math.abs(x) - 0.33) / 0.25) ** 2)) * Math.max(0, z);
        z += brow * (fem ? 0.025 : 0.05);
        // מצח שטוח יותר מאחור, עורף
        if (z < 0) z *= 1.04;
        if (y > 0.6) { x *= 1 + (y - 0.6) * 0.05; }
        // שפתיים
        const lips = Math.exp(-(((y + 0.42) / 0.07) ** 2)) * Math.exp(-((x / 0.28) ** 2)) * Math.max(0, z);
        z += lips * 0.05;
        p.setXYZ(i, HC.x + x * HR.x, HC.y + y * HR.y, HC.z + z * HR.z);
      }
      g.computeVertexNormals();
      const hairline = (vv) => { // האם בתחום השיער (למגולח/כיפה)
        const ly = (vv.y - HC.y) / HR.y, lz = (vv.z - HC.z) / HR.z, lx = (vv.x - HC.x) / HR.x;
        if (o.hair === 4) return false;
        const front = lz > 0.35 ? 0.62 + (Math.abs(lx) > 0.6 ? -0.25 : 0) : lz > -0.2 ? 0.25 - Math.max(0, Math.abs(lx) - 0.85) : -0.35;
        return ly > front;
      };
      parts.push(finalize(g, vv => {
        const ly = (vv.y - HC.y) / HR.y, lx = (vv.x - HC.x) / HR.x, lz = (vv.z - HC.z) / HR.z;
        if (T) { const eyeBand = ly > 0.02 && ly < 0.26 && lz > 0.55 && Math.abs(lx) < 0.62; if (eyeBand) return C.skin.clone().multiplyScalar(0.85); if (ly > 0.33 && ly < 0.5) return C.green; return C.mask; }
        if (ly > 0.24 && ly < 0.34 && lz > 0.6 && Math.abs(lx) > 0.12 && Math.abs(lx) < 0.6) return C.brow; // גבות
        if (ly > -0.52 && ly < -0.33 && lz > 0.7 && Math.abs(lx) < 0.33 - Math.abs(ly + 0.42) * 0.8) return C.lips;
        if (o.acc.includes('beard') && ly < -0.2 && lz > -0.1) return mixC(C.skin, C.hair, 0.85);
        const blush = Math.exp(-(((ly + 0.12) / 0.15) ** 2)) * Math.exp(-(((Math.abs(lx) - 0.55) / 0.2) ** 2)) * Math.max(0, lz);
        return mixC(C.skin, new THREE.Color('#d0806a'), blush * 0.25);
      }, rigid('head')));
      // אף
      if (!T) {
        const nose = new THREE.SphereGeometry(1, S(12), S(10)); const np = nose.attributes.position;
        for (let i = 0; i < np.count; i++) { v.fromBufferAttribute(np, i); const yy = v.y; v.x *= 0.55 + (1 - yy) * 0.35; v.z *= 0.6 + (1 - yy) * 0.5; np.setXYZ(i, v.x * 0.012, v.y * 0.024, v.z * 0.0135 + (v.y < -0.3 ? 0.002 : 0)); }
        nose.computeVertexNormals(); nose.rotateX(0.3); nose.translate(HC.x, HC.y - 0.014, HC.z + HR.z * 0.9);
        parts.push(finalize(nose, () => C.skin.clone().multiplyScalar(1.02), rigid('head')));
        // אוזניים
        for (const sx of [1, -1]) parts.push(finalize(ellipsoid([HC.x + sx * HR.x * 0.98, HC.y - 0.005, HC.z - 0.01], [0.012, 0.03, 0.02], S(10), S(8)), () => C.skin.clone().multiplyScalar(0.95), rigid('head')));
      }
      // שיער
      if (!T) this._hair(parts, o, HC, HR, C, S);
      // אביזרי ראש
      if (T) {
        parts.push(finalize(new THREE.TorusGeometry(HR.x * 0.955, 0.011, 6, S(28)).rotateX(Math.PI / 2).scale(1, 1, HR.z / HR.x).translate(HC.x, HC.y + 0.042, HC.z), solid(C.green), rigid('head')));
        parts.push(finalize(rboxGeo([HC.x + 0.02, HC.y + 0.03, HC.z - HR.z - 0.01], [0.03, 0.07, 0.012], [0.3, 0, 0.3]), solid(C.green), rigid('head')));
      }
      if (o.acc.includes('cap')) { parts.push(finalize(ellipsoid([HC.x, HC.y + 0.045, HC.z - 0.005], [HR.x * 1.08, HR.y * 0.62, HR.z * 1.08], S(20), S(10)), v => (v.y > HC.y + 0.04 ? hex(o.capColor || out[3]) : C.hair), rigid('head'))); parts.push(finalize(new THREE.CylinderGeometry(0.075, 0.08, 0.008, S(18), 1, false, -Math.PI / 2, Math.PI).rotateX(0.18).translate(HC.x, HC.y + 0.05, HC.z + HR.z * 0.92), solid(hex(o.capColor || out[3]).multiplyScalar(0.85)), rigid('head'))); }
      if (o.acc.includes('beanie')) parts.push(finalize(ellipsoid([HC.x, HC.y + 0.055, HC.z - 0.008], [HR.x * 1.1, HR.y * 0.78, HR.z * 1.1], S(20), S(12)), solid(hex(o.capColor || '#d9483b')), rigid('head')));
      if (o.acc.includes('headband')) parts.push(finalize(new THREE.TorusGeometry(HR.x * 0.99, 0.008, 6, S(28)).rotateX(Math.PI / 2).scale(1, 1, HR.z / HR.x).translate(HC.x, HC.y + 0.045, HC.z), solid(C.accent), rigid('head')));
      if (o.acc.includes('flower')) parts.push(finalize(ellipsoid([HC.x + 0.07, HC.y + 0.07, HC.z + 0.05], [0.022, 0.022, 0.012]), solid(hex('#ff6fb0')), rigid('head')));
      if (o.acc.includes('glasses')) for (const sx of [1, -1]) parts.push(finalize(new THREE.TorusGeometry(0.021, 0.0035, 6, 16).translate(HC.x + sx * 0.035, HC.y + 0.016, HC.z + HR.z * 0.99), solid(hex('#111')), rigid('head')));
    }
    // ─ אביזרי גוף ─
    if (T) { // אפוד: פאוצ'ים ורצועות
      for (let i = -1; i <= 1; i++) parts.push(finalize(rboxGeo([i * 0.075, 1.12, 0.115], [0.065, 0.09, 0.045]), solid(C.pouch), rigid('spine')));
      for (const sx of [1, -1]) parts.push(finalize(rboxGeo([sx * 0.09, 1.33, 0.1], [0.05, 0.22, 0.03], [0, 0, sx * 0.08]), solid(C.vest), rigid('chest')));
      parts.push(finalize(new THREE.TorusGeometry(0.15, 0.02, 6, S(24)).rotateX(Math.PI / 2).scale(1.02, 1, 0.72).translate(0, 0.96, 0.005), solid(hex('#3b3a2c')), rigid('hips')));
    }
    if (o.acc.includes('backpack')) { const pc = hex(o.packColor || '#c2501f'); parts.push(finalize(rboxGeo([0, 1.25, -0.17], [0.28, 0.42, 0.14]), solid(pc), rigid('chest'))); parts.push(finalize(rboxGeo([0, 1.13, -0.25], [0.2, 0.13, 0.05]), solid(pc.clone().multiplyScalar(0.8)), rigid('chest'))); for (const sx of [1, -1]) parts.push(finalize(rboxGeo([sx * 0.09, 1.3, 0.09], [0.04, 0.3, 0.02]), solid(hex('#222')), rigid('chest'))); }
    if (o.acc.includes('packLogo')) { const wc = hex('#f2e9d0'); for (const r of [0.28, -0.28]) parts.push(finalize(rboxGeo([0, 1.33, -0.245], [0.17, 0.028, 0.01], [0, 0, r]), solid(wc), rigid('chest'))); parts.push(finalize(ellipsoid([0, 1.32, -0.245], [0.028, 0.028, 0.01]), solid(wc), rigid('chest'))); }
    if (o.acc.includes('scarf')) parts.push(finalize(new THREE.TorusGeometry(0.08, 0.032, 8, S(20)).rotateX(Math.PI / 2 + 0.15).translate(0, 1.47, 0.01), solid(C.accent), v => [[BI.neck, 0.5], [BI.chest, 0.5]]));
    if (o.acc.includes('bracelet')) { const hc = RP.haL; parts.push(finalize(new THREE.TorusGeometry(0.036, 0.007, 6, 20).rotateX(Math.PI / 2).translate(hc[0], hc[1] + 0.03, hc[2]), solid(hex('#e8c07a')), rigid('elL'))); for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; parts.push(finalize(ellipsoid([hc[0] + Math.cos(a) * 0.039, hc[1] + 0.03, hc[2] + Math.sin(a) * 0.039], [0.009, 0.009, 0.009], 8, 6), solid(hex(['#ff6b8b', '#4ac7ff', '#ffd25a', '#ffffff'][i % 4])), rigid('elL'))); } }

    // ─ שלד ו-SkinnedMesh ─
    const geo = mergeGeometries(parts, false); geo.computeBoundingSphere(); geo.computeBoundingBox();
    // UV לפרטי normal map (הקרנה פשוטה)
    const pp = geo.attributes.position; const uv = new Float32Array(pp.count * 2);
    for (let i = 0; i < pp.count; i++) { uv[i * 2] = Math.atan2(pp.getX(i), pp.getZ(i)) * 0.3; uv[i * 2 + 1] = pp.getY(i); }
    geo.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
    this.bones = {}; const boneArr = [];
    const parentOf = { spine: 'hips', chest: 'spine', neck: 'chest', head: 'neck', shL: 'chest', elL: 'shL', haL: 'elL', shR: 'chest', elR: 'shR', haR: 'elR', thL: 'hips', knL: 'thL', ftL: 'knL', thR: 'hips', knR: 'thR', ftR: 'knR' };
    for (const name of BONES) { const b = new THREE.Bone(); b.name = name; this.bones[name] = b; boneArr.push(b); }
    for (const name of BONES) { const b = this.bones[name]; const par = parentOf[name]; const wp = RP[name]; if (par) { const pp2 = RP[par]; b.position.set(wp[0] - pp2[0], wp[1] - pp2[1], wp[2] - pp2[2]); this.bones[par].add(b); } else b.position.set(...wp); }
    this.root = new THREE.Group(); this.root.name = 'character'; this.root.userData.character = this;
    if (!sharedBodyMat.v) sharedBodyMat.v = bodyMaterial();
    const mesh = new THREE.SkinnedMesh(geo, sharedBodyMat.v);
    mesh.add(this.bones.hips); mesh.bind(new THREE.Skeleton(boneArr));
    mesh.castShadow = true; mesh.receiveShadow = true; mesh.frustumCulled = false;
    this.root.add(mesh); this.mesh = mesh; this.meshes = [mesh];
    this.root.scale.setScalar(o.height);
    this.restHipsY = RP.hips[1];
    // ─ פנים מונפשות ─
    const head = this.bones.head; const hOff = (x, y, z) => new THREE.Vector3(x - RP.head[0], y - RP.head[1], z - RP.head[2]);
    if (o.detail) {
      this.eyes = []; this.lids = [];
      const irisMat = new THREE.MeshStandardMaterial({ color: o.eyes, roughness: 0.15 });
      for (const sx of [1, -1]) {
        const ep = hOff(HC.x + sx * 0.031, HC.y + 0.012, HC.z + HR.z * 0.8);
        const e = new THREE.Mesh(new THREE.SphereGeometry(T ? 0.011 : 0.013, 14, 10), MAT_EYE); e.position.copy(ep); head.add(e);
        const ir = new THREE.Mesh(new THREE.CircleGeometry(T ? 0.0055 : 0.007, 16), irisMat); ir.position.set(0, 0, T ? 0.0111 : 0.0131); e.add(ir);
        const pu = new THREE.Mesh(new THREE.CircleGeometry(0.0034, 12), MAT_PUPIL); pu.position.z = 0.0002; ir.add(pu);
        this.eyes.push(e);
        if (!T) {
          const lid = new THREE.Mesh(new THREE.SphereGeometry(0.0142, 14, 8, 0, Math.PI * 2, 0, Math.PI / 2), new THREE.MeshStandardMaterial({ color: o.skin, roughness: 0.6 }));
          lid.position.copy(ep); lid.rotation.x = -0.5; head.add(lid); this.lids.push(lid);
          const lash = new THREE.Mesh(new THREE.TorusGeometry(0.014, 0.0013, 4, 16, Math.PI), new THREE.MeshBasicMaterial({ color: 0x1a120c })); lash.rotation.x = -0.15; lid.add(lash);
        }
      }
      if (!T) { this.mouth = new THREE.Mesh(new THREE.SphereGeometry(1, 12, 8), MAT_MOUTH); this.mouth.scale.set(0.02, 0.002, 0.006); this.mouth.position.copy(hOff(HC.x, HC.y - 0.052, HC.z + HR.z * 0.99)); head.add(this.mouth); }
    }
    if (T && o.weapon !== false) this.setHold('rifle');
    this.state = 'idle'; this.speed = 0; this.phase = Math.random() * 10; this.t = Math.random() * 100;
    this.blinkT = Math.random() * 3; this.talking = false; this.danceStyle = o.danceStyle ?? Math.floor(Math.random() * 4);
    this.lookTarget = null; this.headYaw = 0; this.headPitch = 0; this.poseOverride = null;
  }

  _hair(parts, o, HC, HR, C, S) {
    const st = o.hair;
    const base = new THREE.SphereGeometry(1, S(30), S(20)); const p = base.attributes.position; const v = new THREE.Vector3();
    const thick = st === 1 ? 1.16 : st === 4 ? 1.012 : 1.07;
    for (let i = 0; i < p.count; i++) {
      v.fromBufferAttribute(p, i); let { x, y, z } = v;
      // קו שיער: מתחת – נכנס פנימה (מוסתר)
      const ax = Math.abs(x); const sideDrop = Math.min(1, Math.max(0, (ax - 0.35) / 0.45)); const zf = Math.min(1, Math.max(0, (z + 0.2) / 0.6));
      const front = (0.64 - sideDrop * sideDrop * 0.55) * zf + (st === 2 || st === 3 ? -0.62 : -0.42) * (1 - zf) + (st === 0 && zf > 0.5 ? 0.05 : 0);
      const sm = Math.min(1, Math.max(0, (y - front + 0.12) / 0.16)); let k = 0.9 + (thick - 0.9) * sm * sm * (3 - 2 * sm);
      if (st === 1) k += (Math.sin(x * 23) * Math.sin(y * 19) * Math.sin(z * 21)) * 0.06;
      if (st === 0 && y > 0.5) k += 0.03 + Math.sin(x * 30 + z * 20) * 0.01;
      p.setXYZ(i, HC.x + x * HR.x * k, HC.y + 0.006 + y * HR.y * k, HC.z - 0.004 + z * HR.z * k);
    }
    base.computeVertexNormals();
    const hcol = (vv) => C.hair.clone().multiplyScalar(0.9 + 0.2 * Math.sin(vv.x * 300 + vv.y * 120));
    parts.push(finalize(base, hcol, rigid('head')));
    if (st === 2) { // ארוך – לוח אחורי וקווצות
      const back = tube([new THREE.Vector3(HC.x, HC.y + 0.02, HC.z - 0.045), new THREE.Vector3(HC.x, HC.y - 0.22, HC.z - 0.07)], s => [HR.x * (1.08 - s * 0.12), 0.06 * (1 - s * 0.3)], S(16), 10, false, true);
      parts.push(finalize(back, hcol, v => lerpW(v.y, [[HC.y - 0.2, 'chest'], [HC.y - 0.08, 'neck'], [HC.y, 'head']])));
      if (false) for (const sx of [1, -1]) parts.push(finalize(tube([new THREE.Vector3(HC.x + sx * HR.x * 0.95, HC.y + 0.0, HC.z + 0.02), new THREE.Vector3(HC.x + sx * HR.x * 0.85, HC.y - 0.2, HC.z + 0.0)], s => [0.02, 0.03 * (1 - s * 0.4)], 8, 8, false, true), hcol, v => lerpW(v.y, [[HC.y - 0.18, 'chest'], [HC.y - 0.05, 'head']])));
    }
    if (st === 3) { // קוקו
      parts.push(finalize(ellipsoid([HC.x, HC.y + 0.03, HC.z - HR.z * 1.05], [0.035, 0.035, 0.035]), hcol, rigid('head')));
      parts.push(finalize(tube([new THREE.Vector3(HC.x, HC.y + 0.02, HC.z - HR.z * 1.12), new THREE.Vector3(HC.x, HC.y - 0.16, HC.z - HR.z * 1.3)], s => [0.032 * (1 - s * 0.5), 0.032 * (1 - s * 0.5)], 10, 10, false, true), hcol, v => lerpW(v.y, [[HC.y - 0.14, 'neck'], [HC.y - 0.02, 'head']])));
    }
  }

  setHold(kind) {
    if (this.held) { this.held.parent && this.held.parent.remove(this.held); this.held = null; }
    this.hold = kind;
    if (kind === 'rifle') { const r = buildRifle(); r.position.set(-0.01, -0.07, 0.05); r.rotation.set(-Math.PI / 2 + 0.1, 0, Math.PI / 2 - 0.1); this.bones.haR.add(r); this.held = r; }
    if (kind === 'flashlight') { const f = buildFlashlight(); f.position.set(0, -0.08, 0.03); f.rotation.x = -Math.PI / 2; this.bones.haR.add(f); this.held = f; }
    if (kind === 'photo') { const m = new THREE.Mesh(new THREE.PlaneGeometry(0.09, 0.12), new THREE.MeshStandardMaterial({ color: 0xe9e2d0, side: THREE.DoubleSide, roughness: 0.6 })); m.position.set(0, -0.1, 0.04); m.rotation.x = -1.2; this.bones.haL.add(m); this.held = m; }
  }
  setGhost(on) { const m = this.mesh; if (on) { m.userData.mat = m.userData.mat || m.material; m.material = MAT_GHOST; m.castShadow = false; } else if (m.userData.mat) { m.material = m.userData.mat; m.castShadow = true; } }
  setShadows(on) { this.mesh.castShadow = on; }
  setState(s, speed) { this.state = s; if (speed !== undefined) this.speed = speed; }
  lookAt(v) { this.lookTarget = v; }

  update(dt, beat = 0) {
    this.t += dt;
    const b = this.bones, s = this.state, t = this.t;
    for (const k in b) b[k].rotation.set(0, 0, 0);
    let hipsY = this.restHipsY, hipsX = 0, hipsZ = 0, hipsRY = 0;
    const br = Math.sin(t * 2.2) * 0.015;
    b.chest.rotation.x = br; b.shL.rotation.z = 0.1; b.shR.rotation.z = -0.1; b.elL.rotation.x = -0.12; b.elR.rotation.x = -0.12;
    b.haL.rotation.z = -0.1; b.haR.rotation.z = 0.1;
    if (s === 'walk' || s === 'run' || s === 'sneak') {
      const run = s === 'run', sneak = s === 'sneak';
      this.phase += dt * (run ? 10.5 : sneak ? 4.5 : 6.5) * Math.max(0.4, Math.min(1.4, this.speed / (run ? 5 : 1.6)));
      const p = this.phase, amp = run ? 0.9 : sneak ? 0.45 : 0.48;
      b.thL.rotation.x = -Math.sin(p) * amp - (sneak ? 0.5 : 0); b.thR.rotation.x = Math.sin(p) * amp - (sneak ? 0.5 : 0);
      b.knL.rotation.x = Math.max(0, Math.sin(p - 1.3)) * (run ? 1.7 : 0.95) + (sneak ? 0.8 : 0) + 0.05;
      b.knR.rotation.x = Math.max(0, -Math.sin(p - 1.3)) * (run ? 1.7 : 0.95) + (sneak ? 0.8 : 0) + 0.05;
      b.ftL.rotation.x = -b.knL.rotation.x * 0.25; b.ftR.rotation.x = -b.knR.rotation.x * 0.25;
      b.shL.rotation.x = Math.sin(p) * amp * 0.75; b.shR.rotation.x = -Math.sin(p) * amp * 0.75;
      b.elL.rotation.x = -(run ? 1.5 : 0.3); b.elR.rotation.x = -(run ? 1.5 : 0.3);
      b.spine.rotation.x = run ? 0.22 : sneak ? 0.35 : 0.04; b.chest.rotation.y = -Math.sin(p) * 0.1;
      hipsY = this.restHipsY - (sneak ? 0.2 : 0) + Math.abs(Math.cos(p)) * (run ? 0.06 : 0.025) - (run ? 0.05 : 0.01);
      hipsRY = Math.sin(p) * 0.08;
      if (this.panic) { b.shL.rotation.x = -0.3 + Math.sin(p) * 0.6; b.shR.rotation.x = -0.3 - Math.sin(p) * 0.6; b.neck.rotation.y = Math.sin(t * 3) * 0.3; }
    } else if (s === 'dance') {
      const ph = beat * Math.PI * 2, st = this.danceStyle;
      const bounce = Math.abs(Math.sin(ph / 2));
      hipsY = this.restHipsY - bounce * 0.06;
      b.knL.rotation.x = bounce * 0.32; b.knR.rotation.x = bounce * 0.32; b.thL.rotation.x = -bounce * 0.17; b.thR.rotation.x = -bounce * 0.17; b.ftL.rotation.x = -bounce * 0.15; b.ftR.rotation.x = -bounce * 0.15;
      if (st === 0) { b.shL.rotation.z = 2.7 + Math.sin(ph) * 0.15; b.shR.rotation.z = -2.7 - Math.sin(ph) * 0.15; b.elL.rotation.x = -0.35; b.elR.rotation.x = -0.35; b.shL.rotation.x = -0.2; b.shR.rotation.x = -0.2; }
      else if (st === 1) { b.shL.rotation.x = -0.9 + Math.sin(ph) * 0.45; b.shR.rotation.x = -0.9 - Math.sin(ph) * 0.45; b.elL.rotation.x = -1.3; b.elR.rotation.x = -1.3; b.chest.rotation.y = Math.sin(ph / 2) * 0.3; hipsRY = -Math.sin(ph / 2) * 0.18; b.thL.rotation.x = -Math.max(0, Math.sin(ph / 2)) * 0.55; b.knL.rotation.x = Math.max(0, Math.sin(ph / 2)) * 0.85; }
      else if (st === 2) { hipsZ = Math.sin(ph / 2) * 0.07; b.chest.rotation.z = -Math.sin(ph / 2) * 0.1; b.shL.rotation.z = 1.3 + Math.sin(ph / 2 + 1) * 0.5; b.shR.rotation.z = -1.3 + Math.sin(ph / 2) * 0.5; b.elL.rotation.z = Math.sin(ph / 2) * 0.6; b.elR.rotation.z = Math.sin(ph / 2 + 2) * 0.6; }
      else { hipsY = this.restHipsY + Math.max(0, Math.sin(ph)) * 0.05; b.shR.rotation.z = -2.85; b.elR.rotation.x = Math.sin(ph) * 0.3; b.shL.rotation.x = -0.7; b.elL.rotation.x = -1.4; }
      b.neck.rotation.x = Math.sin(ph) * 0.12;
    } else if (s === 'sit') {
      hipsY = 0.5; b.thL.rotation.x = -1.5; b.thR.rotation.x = -1.5; b.knL.rotation.x = 1.5; b.knR.rotation.x = 1.5;
      b.shL.rotation.x = -0.45; b.shR.rotation.x = -0.45; b.elL.rotation.x = -0.9; b.elR.rotation.x = -0.9;
    } else if (s === 'sitGround') {
      hipsY = 0.17; b.thL.rotation.set(-1.4, 0, 0.35); b.thR.rotation.set(-1.4, 0, -0.35); b.knL.rotation.x = 2.2; b.knR.rotation.x = 2.2;
      b.shL.rotation.x = -0.7; b.shR.rotation.x = -0.7; b.elL.rotation.x = -1.0; b.elR.rotation.x = -1.0; b.spine.rotation.x = 0.25;
    } else if (s === 'crouch' || s === 'cower') {
      hipsY = 0.5; b.thL.rotation.x = -1.9; b.thR.rotation.x = -1.9; b.knL.rotation.x = 2.3; b.knR.rotation.x = 2.3; b.ftL.rotation.x = -0.4; b.ftR.rotation.x = -0.4; b.spine.rotation.x = 0.5;
      if (s === 'cower') { b.shL.rotation.set(-2.4, 0, -0.4); b.shR.rotation.set(-2.4, 0, 0.4); b.elL.rotation.x = -1.8; b.elR.rotation.x = -1.8; b.neck.rotation.x = 0.6; b.chest.rotation.z = Math.sin(t * 20) * 0.01; }
    } else if (s === 'handsUp') { b.shL.rotation.z = 2.75; b.shR.rotation.z = -2.75; b.elL.rotation.z = -0.4; b.elR.rotation.z = 0.4; }
    else if (s === 'lying') { hipsY = 0.12; hipsX = -Math.PI / 2; }
    else if (s === 'wave') { b.shR.rotation.z = -2.5; b.elR.rotation.z = Math.sin(t * 9) * 0.5; }
    else if (s === 'drum') {
      hipsY = 0.48; b.thL.rotation.x = -1.5; b.thR.rotation.x = -1.5; b.knL.rotation.x = 1.5; b.knR.rotation.x = 1.5;
      const ph = beat * Math.PI * 2;
      b.shL.rotation.x = -0.9 + Math.max(0, Math.sin(ph)) * 0.4; b.shR.rotation.x = -0.9 + Math.max(0, Math.sin(ph + Math.PI)) * 0.4; b.elL.rotation.x = -0.6; b.elR.rotation.x = -0.6; b.spine.rotation.x = 0.3;
    } else if (s === 'hug') { b.shL.rotation.set(-1.4, 0, -0.5); b.shR.rotation.set(-1.4, 0, 0.5); b.elL.rotation.set(0, -1.2, 0); b.elR.rotation.set(0, 1.2, 0); }
    else if (s === 'point') { b.shR.rotation.x = -1.5; b.elR.rotation.x = -0.1; }
    else if (s === 'holdPhoto') { b.shL.rotation.x = -0.9; b.elL.rotation.x = -1.2; b.neck.rotation.x = 0.35; }
    if (this.hold === 'rifle' && s !== 'lying') {
      b.shR.rotation.set(-1.1, 0.0, -0.15); b.elR.rotation.set(-0.55, 0, 0); b.shL.rotation.set(-1.15, 0, 0.5); b.elL.rotation.set(-0.95, -0.5, 0);
      if (this.aim) { b.shR.rotation.x = -1.45; b.shL.rotation.x = -1.4; b.neck.rotation.y = 0.15; }
    }
    if (this.hold === 'flashlight' && s !== 'lying') { b.shR.rotation.set(-1.2, 0, -0.1); b.elR.rotation.x = -0.3; }
    if (this.talking && s !== 'dance') { b.shL.rotation.x += Math.sin(t * 3.1) * 0.15 - 0.2; b.elL.rotation.x -= 0.6 + Math.sin(t * 4.3) * 0.2; b.neck.rotation.x += Math.sin(t * 4.0) * 0.05; }
    if (this.poseOverride) this.poseOverride(b, t);
    b.hips.position.y = hipsY; b.hips.rotation.x += hipsX; b.hips.rotation.z += hipsZ; b.hips.rotation.y += hipsRY;
    if (this.lookTarget) {
      const wp = new THREE.Vector3(); this.root.getWorldPosition(wp);
      const dx = this.lookTarget.x - wp.x, dz = this.lookTarget.z - wp.z, dy = this.lookTarget.y - (wp.y + 1.6 * this.root.scale.y);
      const yaw = Math.atan2(dx, dz) - this.root.rotation.y;
      let yy = Math.atan2(Math.sin(yaw), Math.cos(yaw)); yy = Math.max(-1.1, Math.min(1.1, yy));
      const pitch = Math.max(-0.5, Math.min(0.5, -Math.atan2(dy, Math.hypot(dx, dz))));
      this.headYaw += (yy - this.headYaw) * Math.min(1, dt * 5); this.headPitch += (pitch - this.headPitch) * Math.min(1, dt * 5);
    } else { this.headYaw *= 0.92; this.headPitch *= 0.92; }
    b.neck.rotation.y += this.headYaw * 0.4; b.head.rotation.y += this.headYaw * 0.6; b.head.rotation.x += this.headPitch;
    this.blinkT -= dt;
    if (this.lids && this.lids.length) {
      let lid = -0.5;
      if (this.blinkT < 0.13) lid = -0.5 + 1.75 * Math.sin(Math.max(0, this.blinkT) / 0.13 * Math.PI);
      if (this.blinkT < 0) this.blinkT = 2 + Math.random() * 4;
      if (this.eyesClosed) lid = 1.25;
      for (const l of this.lids) l.rotation.x = lid;
    }
    if (this.mouth) { const open = this.talking ? 0.003 + Math.abs(Math.sin(t * 13) * Math.sin(t * 5.3)) * 0.011 : 0.002; this.mouth.scale.y += (open - this.mouth.scale.y) * 0.5; this.mouth.scale.x = this.smile ? 0.024 : 0.02; }
  }
}

// ───────────── כלי נשק (ויזואלי בלבד, ללא פירוט טכני) ─────────────
const WMAT = new THREE.MeshStandardMaterial({ color: 0x1c1d1f, roughness: 0.5, metalness: 0.6 });
const WMAT2 = new THREE.MeshStandardMaterial({ color: 0x4a3a28, roughness: 0.7, metalness: 0.05 });
export function buildRifle() {
  const g = new THREE.Group();
  const add = (geo, mat, pos, rot, scl) => { const m = new THREE.Mesh(geo, mat); if (pos) m.position.set(...pos); if (rot) m.rotation.set(...rot); if (scl) m.scale.set(...scl); m.castShadow = true; g.add(m); return m; };
  add(new THREE.CapsuleGeometry(0.028, 0.32, 3, 8), WMAT, [0, 0, 0], [0, 0, Math.PI / 2], [1, 1, 0.75]);
  add(new THREE.CylinderGeometry(0.011, 0.011, 0.38, 8), WMAT, [0.34, 0, 0], [0, 0, Math.PI / 2]);
  add(new THREE.CapsuleGeometry(0.024, 0.16, 3, 8), WMAT2, [0.22, -0.005, 0], [0, 0, Math.PI / 2]);
  add(new THREE.CapsuleGeometry(0.026, 0.2, 3, 8), WMAT2, [-0.3, -0.03, 0], [0, 0, Math.PI / 2 + 0.12], [1.3, 1, 0.7]);
  add(new THREE.TorusGeometry(0.12, 0.018, 6, 12, 0.9), WMAT, [0.05, -0.12, 0], [0, 0, 0.9], [1, 1, 0.9]);
  add(new THREE.CapsuleGeometry(0.016, 0.06, 2, 6), WMAT, [-0.08, -0.06, 0], [0, 0, -0.3]);
  g.userData.muzzle = new THREE.Vector3(0.53, 0, 0);
  return g;
}
export function buildPistol() {
  const g = new THREE.Group();
  const add = (geo, pos, rot, scl) => { const m = new THREE.Mesh(geo, WMAT); if (pos) m.position.set(...pos); if (rot) m.rotation.set(...rot); if (scl) m.scale.set(...scl); m.castShadow = true; g.add(m); };
  add(new THREE.CapsuleGeometry(0.016, 0.13, 3, 8), [0, 0.02, 0], [0, 0, Math.PI / 2], [1, 1, 0.7]);
  add(new THREE.CapsuleGeometry(0.017, 0.07, 3, 8), [-0.045, -0.035, 0], [0, 0, 0.25], [1, 1, 0.75]);
  add(new THREE.TorusGeometry(0.018, 0.004, 4, 10, Math.PI), [0, -0.005, 0], [0, 0, Math.PI]);
  return g;
}
export function buildFlashlight() {
  const g = new THREE.Group();
  const b = new THREE.Mesh(new THREE.CylinderGeometry(0.018, 0.016, 0.16, 10), WMAT); b.rotation.x = Math.PI / 2; g.add(b);
  const h = new THREE.Mesh(new THREE.CylinderGeometry(0.026, 0.019, 0.04, 12), WMAT); h.rotation.x = Math.PI / 2; h.position.z = 0.09; g.add(h);
  const lens = new THREE.Mesh(new THREE.CircleGeometry(0.023, 12), new THREE.MeshBasicMaterial({ color: 0xfff2d0 })); lens.position.z = 0.111; g.add(lens);
  return g;
}

/** מאגר דמויות אקראיות מגוונות */
export function randomLook(i, extra = {}) {
  const r = (n, k = 1) => Math.abs(Math.floor(Math.sin(i * 12.9898 * k + 4.1) * 43758.5453)) % n;
  const gender = r(2) ? 'f' : 'm';
  const accs = [[], ['cap'], ['headband'], ['flower'], ['glasses'], ['beanie'], [], ['scarf']];
  return { skin: SKIN[r(6, 2)], hair: gender === 'f' ? [2, 3, 1, 0][r(4, 3)] : [0, 1, 4, 0][r(4, 3)], hairColor: HAIR_COL[r(5, 5)], outfit: OUTFITS[r(5, 7)], gender, build: 0.92 + r(10, 11) * 0.02, height: 0.94 + r(10, 13) * 0.012, acc: gender === 'm' && r(4, 17) === 0 ? ['beard'] : accs[r(8, 19)], capColor: ['#d9483b', '#2b7bd6', '#f2c12e', '#222'][r(4, 23)], ...extra };
}
