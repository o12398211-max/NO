// שטח: heightfield עם רעש, PBR, דשא/שיחים יבשים מפוזרים (Instanced)
import * as THREE from 'three';
import { Materials } from './materials.js';

// רעש ערך חלק (deterministic)
function hash(x, z) { const s = Math.sin(x * 127.1 + z * 311.7) * 43758.5453; return s - Math.floor(s); }
function vnoise(x, z) {
  const xi = Math.floor(x), zi = Math.floor(z), xf = x - xi, zf = z - zi;
  const u = xf * xf * (3 - 2 * xf), v = zf * zf * (3 - 2 * zf);
  const a = hash(xi, zi), b = hash(xi + 1, zi), c = hash(xi, zi + 1), d = hash(xi + 1, zi + 1);
  return a + (b - a) * u + (c - a) * v + (a - b - c + d) * u * v;
}
export function fbm(x, z, oct = 4) { let s = 0, a = 0.5, f = 1; for (let i = 0; i < oct; i++) { s += a * vnoise(x * f, z * f); f *= 2; a *= 0.5; } return s; }

export class Terrain {
  /** size: אורך צלע, res: רזולוציה, heightFn(x,z) */
  constructor({ size = 400, res = 160, heightFn, tex = 'dry_ground_01', repeat = 60, color = 0xffffff, flatZones = [] }) {
    this.size = size; this.flatZones = flatZones;
    this.baseFn = heightFn || ((x, z) => (fbm(x * 0.012, z * 0.012) - 0.5) * 8 + (fbm(x * 0.05, z * 0.05) - 0.5) * 1.2);
    const geo = new THREE.PlaneGeometry(size, size, res, res); geo.rotateX(-Math.PI / 2);
    const pos = geo.attributes.position;
    for (let i = 0; i < pos.count; i++) pos.setY(i, this.heightAt(pos.getX(i), pos.getZ(i)));
    geo.computeVertexNormals();
    const mat = Materials.pbr(tex, repeat, { color, normal: 1.2 }).clone();
    this.mesh = new THREE.Mesh(geo, mat); this.mesh.receiveShadow = true; this.mesh.name = 'terrain';
  }
  heightAt(x, z) {
    let h = this.baseFn(x, z);
    for (const f of this.flatZones) { // אזורים שטוחים (במה, חניה, כביש)
      const d = f.r ? Math.hypot(x - f.x, z - f.z) - f.r : Math.max(Math.abs(x - f.x) - f.w / 2, Math.abs(z - f.z) - f.d / 2);
      const k = THREE.MathUtils.clamp(1 - d / (f.blend || 10), 0, 1);
      h = h * (1 - k * k * (3 - 2 * k)) + (f.h ?? 0) * (k * k * (3 - 2 * k));
    }
    return h;
  }
}

/** פיזור צמחייה מדברית: שיחי מלוח, עשב יבש – Instanced עם רוח בשיידר */
export function scatterGrass(terrain, { count = 6000, area = 180, avoid = () => false, color = 0x9a8a5a, height = 0.5 } = {}) {
  const blade = new THREE.PlaneGeometry(0.08, height, 1, 3); blade.translate(0, height / 2, 0);
  const pos = blade.attributes.position; for (let i = 0; i < pos.count; i++) { const y = pos.getY(i) / height; pos.setX(i, pos.getX(i) * (1 - y * 0.85)); }
  // 3 להבים בצרור
  const geos = [];
  for (let k = 0; k < 3; k++) { const b = blade.clone(); b.rotateZ((k - 1) * 0.35); b.rotateY(k * 2.1); geos.push(b); }
  const geo = mergeSimple(geos);
  const mat = new THREE.MeshStandardMaterial({ color, roughness: 0.9, side: THREE.DoubleSide });
  mat.onBeforeCompile = sh => {
    sh.uniforms.uTime = mat.userData.uTime = { value: 0 };
    sh.vertexShader = 'uniform float uTime;\n' + sh.vertexShader.replace('#include <begin_vertex>', `#include <begin_vertex>
      vec4 wp = instanceMatrix * vec4(position,1.0);
      float sway = sin(uTime*1.7 + wp.x*0.3 + wp.z*0.2) * 0.12 * position.y;
      transformed.x += sway; transformed.z += sway*0.5;`);
  };
  const mesh = new THREE.InstancedMesh(geo, mat, count);
  const m = new THREE.Matrix4(), q = new THREE.Quaternion(), s = new THREE.Vector3(), p = new THREE.Vector3(), c = new THREE.Color();
  let n = 0;
  for (let i = 0; i < count * 3 && n < count; i++) {
    const x = (Math.random() - 0.5) * area * 2, z = (Math.random() - 0.5) * area * 2;
    if (avoid(x, z)) continue;
    if (fbm(x * 0.08, z * 0.08) < 0.42) continue; // אשכולות
    p.set(x, terrain.heightAt(x, z), z); q.setFromAxisAngle(new THREE.Vector3(0, 1, 0), Math.random() * 6.28);
    const sc = 0.6 + Math.random() * 0.9; s.set(sc, sc * (0.7 + Math.random() * 0.6), sc);
    m.compose(p, q, s); mesh.setMatrixAt(n, m);
    c.set(color).offsetHSL((Math.random() - 0.5) * 0.04, (Math.random() - 0.5) * 0.1, (Math.random() - 0.5) * 0.12); mesh.setColorAt(n, c);
    n++;
  }
  mesh.count = n; mesh.receiveShadow = true;
  mesh.userData.tick = t => { if (mat.userData.uTime) mat.userData.uTime.value = t; };
  return mesh;
}

export function mergeSimple(list) {
  // מיזוג גיאומטריות פשוט ללא תלות (position/normal/uv)
  let total = 0; const nonIdx = list.map(g => (g.index ? g.toNonIndexed() : g)); for (const g of nonIdx) total += g.attributes.position.count;
  const P = new Float32Array(total * 3), N = new Float32Array(total * 3), U = new Float32Array(total * 2); let o = 0;
  for (const g of nonIdx) { const c = g.attributes.position.count; P.set(g.attributes.position.array, o * 3); if (g.attributes.normal) N.set(g.attributes.normal.array, o * 3); if (g.attributes.uv) U.set(g.attributes.uv.array, o * 2); o += c; }
  const out = new THREE.BufferGeometry(); out.setAttribute('position', new THREE.BufferAttribute(P, 3)); out.setAttribute('normal', new THREE.BufferAttribute(N, 3)); out.setAttribute('uv', new THREE.BufferAttribute(U, 2));
  return out;
}
