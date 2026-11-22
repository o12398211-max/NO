// חומרים: PBR מ-Poly Haven (CC0) עם נפילה לטקסטורות פרוצדורליות אם הטעינה נכשלה
import * as THREE from 'three';
import { RGBELoader } from 'three/examples/jsm/loaders/RGBELoader.js';
import { CONFIG } from '../config/game.config.js';

const loader = new THREE.TextureLoader();
const tex = {};
const hdr = {};
let renderer = null, pmrem = null;
const matCache = {};

function canvasTex(w, h, draw, srgb = true) {
  const c = document.createElement('canvas'); c.width = w; c.height = h;
  const g = c.getContext('2d'); draw(g, w, h);
  const t = new THREE.CanvasTexture(c);
  t.wrapS = t.wrapT = THREE.RepeatWrapping; if (srgb) t.colorSpace = THREE.SRGBColorSpace;
  t.anisotropy = 4;
  return t;
}
export { canvasTex };

function noiseCanvas(base, vary, speck = 0) {
  return canvasTex(256, 256, (g, w, h) => {
    g.fillStyle = base; g.fillRect(0, 0, w, h);
    const id = g.getImageData(0, 0, w, h); const d = id.data;
    for (let i = 0; i < d.length; i += 4) { const n = (Math.random() - 0.5) * vary; d[i] += n; d[i + 1] += n; d[i + 2] += n; }
    g.putImageData(id, 0, 0);
    for (let i = 0; i < speck; i++) { g.fillStyle = `rgba(0,0,0,${Math.random() * 0.2})`; g.beginPath(); g.arc(Math.random() * w, Math.random() * h, Math.random() * 3, 0, 7); g.fill(); }
  });
}

export const Materials = {
  async load(onProgress) {
    const names = CONFIG.textures; let done = 0; const total = names.length * 3 + Object.keys(CONFIG.hdris).length;
    const step = () => onProgress && onProgress(++done / total);
    const loadOne = (url, srgb) => new Promise(res => {
      loader.load(url, t => { t.wrapS = t.wrapT = THREE.RepeatWrapping; t.anisotropy = 8; if (srgb) t.colorSpace = THREE.SRGBColorSpace; step(); res(t); }, undefined, () => { step(); res(null); });
    });
    await Promise.all(names.map(async n => {
      const [d, nr, arm] = await Promise.all([
        loadOne(`${CONFIG.assetBase}tex/${n}_diff.jpg`, true),
        loadOne(`${CONFIG.assetBase}tex/${n}_nor.jpg`, false),
        loadOne(`${CONFIG.assetBase}tex/${n}_arm.jpg`, false),
      ]);
      tex[n] = { d, n: nr, arm };
    }));
    const rl = new RGBELoader();
    await Promise.all(Object.entries(CONFIG.hdris).map(([k, n]) => new Promise(res => {
      rl.load(`${CONFIG.assetBase}hdri/${n}.hdr`, t => { t.mapping = THREE.EquirectangularReflectionMapping; hdr[k] = t; step(); res(); }, undefined, () => { step(); res(); });
    })));
  },
  setRenderer(r) { renderer = r; pmrem = new THREE.PMREMGenerator(r); },
  /** סביבת HDRI לתאורה (envMap) + אופציונלית רקע */
  env(name) {
    const t = hdr[name]; if (!t || !pmrem) return null;
    if (!t._pm) t._pm = pmrem.fromEquirectangular(t).texture;
    return t._pm;
  },
  hdrRaw(name) { return hdr[name] || null; },
  /** חומר PBR לפי שם טקסטורה. repeat = חזרות */
  pbr(name, repeat = 1, opts = {}) {
    const key = name + '_' + repeat + '_' + JSON.stringify(opts);
    if (matCache[key]) return matCache[key];
    const t = tex[name];
    const m = new THREE.MeshStandardMaterial({ color: opts.color ?? 0xffffff, roughness: opts.roughness ?? 1, metalness: 0, envMapIntensity: opts.env ?? 0.6 });
    const clone = (x) => { if (!x) return null; const c = x.clone(); c.needsUpdate = true; c.repeat.set(repeat, repeat * (opts.ratio || 1)); return c; };
    if (t && t.d) {
      m.map = clone(t.d);
      if (t.n) { m.normalMap = clone(t.n); m.normalScale = new THREE.Vector2(opts.normal ?? 1, opts.normal ?? 1); }
      if (t.arm) { m.roughnessMap = clone(t.arm); m.aoMap = m.roughnessMap; m.aoMapIntensity = 0.8; }
    } else {
      const fall = { dry_ground_01: ['#8a7356', 50], sandy_gravel: ['#9c8a6c', 60], asphalt_02: ['#3b3b3d', 40], burned_ground_01: ['#2e2824', 50], rough_concrete: ['#6d6e6c', 40], damaged_plaster: ['#b3a891', 30], wood_planks: ['#7a5636', 40], fabric_pattern_07: ['#2a3550', 30] }[name] || ['#888', 30];
      m.map = noiseCanvas(fall[0], fall[1], 300); m.map.repeat.set(repeat, repeat);
    }
    matCache[key] = m; return m;
  },
  canvasTex, noiseCanvas,
};
