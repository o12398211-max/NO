// ידיים בגוף ראשון – זרועות פרוצדורליות מחוברות למצלמה, עם פוזות ומעברים חלקים
import * as THREE from 'three';
import { mergeGeometries } from 'three/examples/jsm/utils/BufferGeometryUtils.js';
import { buildPistol } from './character.js';

const POSES = {
  //            [shoulder rot x,y,z], [elbow x,y,z], [hand x,y,z], shoulder offset [x,y,z]
  hidden:  { L: [[0.6, 0, 0.2], [-0.2, 0, 0], [0, 0, 0], [0.2, -0.55, 0.0]], R: [[0.6, 0, -0.2], [-0.2, 0, 0], [0, 0, 0], [-0.2, -0.55, 0.0]] },
  idle:    { L: [[0.9, 0.1, 0.25], [-1.0, 0, 0], [0.2, 0, 0], [0.2, -0.38, -0.05]], R: [[0.9, -0.1, -0.25], [-1.0, 0, 0], [0.2, 0, 0], [-0.2, -0.38, -0.05]] },
  run:     { L: [[1.2, 0.2, 0.3], [-1.7, 0, 0], [0.1, 0, 0], [0.2, -0.33, -0.02]], R: [[1.2, -0.2, -0.3], [-1.7, 0, 0], [0.1, 0, 0], [-0.2, -0.33, -0.02]] },
  reach:   { L: [[0.9, 0.1, 0.25], [-1.0, 0, 0], [0.2, 0, 0], [0.2, -0.4, -0.05]], R: [[1.75, -0.3, -0.1], [-0.25, 0, 0], [-0.2, 0, 0], [-0.17, -0.27, -0.08]] },
  push:    { L: [[1.7, 0.45, 0.05], [-0.35, 0, 0], [-0.9, 0, 0.3], [0.17, -0.28, -0.05]], R: [[0.9, -0.1, -0.25], [-1.0, 0, 0], [0.2, 0, 0], [-0.2, -0.38, -0.05]] },
  shield:  { L: [[2.0, 0.9, 0.3], [-1.9, 0, 0], [-0.4, 0, 0], [0.14, -0.24, -0.12]], R: [[2.0, -0.9, -0.3], [-1.9, 0, 0], [-0.4, 0, 0], [-0.14, -0.24, -0.12]] },
  wrist:   { L: [[1.45, 0.5, 0.55], [-1.45, 0, 0], [0.3, 0, -1.4], [0.14, -0.3, -0.1]], R: [[0.6, 0, -0.2], [-0.2, 0, 0], [0, 0, 0], [-0.2, -0.55, 0.0]] },
  map:     { L: [[1.4, 0.35, 0.3], [-1.0, 0, 0], [-0.2, 0, 0], [0.16, -0.3, -0.06]], R: [[1.4, -0.35, -0.3], [-1.0, 0, 0], [-0.2, 0, 0], [-0.16, -0.3, -0.06]] },
  drive:   { L: [[1.25, 0.25, 0.35], [-0.75, 0, 0], [0, 0, -0.5], [0.2, -0.33, -0.05]], R: [[1.25, -0.25, -0.35], [-0.75, 0, 0], [0, 0, 0.5], [-0.2, -0.33, -0.05]] },
  pistol:  { L: [[1.55, 0.3, 0.1], [-0.45, 0, 0], [0, 0, 0.6], [0.14, -0.3, -0.06]], R: [[1.6, -0.1, -0.05], [-0.3, 0, 0], [0.05, 0, 0], [-0.1, -0.27, -0.06]] },
  climb:   { L: [[2.6, 0.2, 0.2], [-0.6, 0, 0], [-0.3, 0, 0], [0.22, -0.2, -0.05]], R: [[2.6, -0.2, -0.2], [-0.6, 0, 0], [-0.3, 0, 0], [-0.22, -0.2, -0.05]] },
  knock:   { L: [[0.6, 0, 0.2], [-0.2, 0, 0], [0, 0, 0], [0.2, -0.55, 0.0]], R: [[1.6, -0.2, -0.1], [-0.9, 0, 0], [0.4, 0, 0], [-0.17, -0.28, -0.06]] },
  bound:   { L: [[0.9, 0.6, 0.0], [-1.2, 0, 0], [0, 0, 0], [0.1, -0.42, -0.05]], R: [[0.9, -0.6, 0.0], [-1.2, 0, 0], [0, 0, 0], [-0.1, -0.42, -0.05]] },
};

export class ViewModel {
  constructor(camera, look = {}) {
    this.camera = camera;
    this.group = new THREE.Group(); this.group.name = 'viewmodel';
    camera.add(this.group);
    this.skin = look.skin || '#c99169'; this.sleeve = look.sleeve || '#f2efe9';
    const skinMat = new THREE.MeshStandardMaterial({ color: this.skin, roughness: 0.55 });
    const sleeveMat = new THREE.MeshStandardMaterial({ color: this.sleeve, roughness: 0.85 });
    this.arms = {};
    for (const side of ['L', 'R']) {
      const sx = side === 'L' ? 1 : -1;
      const sh = new THREE.Group(), el = new THREE.Group(), ha = new THREE.Group();
      sh.add(el); el.add(ha); this.group.add(sh);
      el.position.set(0, -0.27, 0); ha.position.set(0, -0.25, 0);
      const ua = new THREE.Mesh(new THREE.CapsuleGeometry(0.045, 0.2, 4, 12), sleeveMat); ua.position.y = -0.13; sh.add(ua);
      const fa = new THREE.Mesh(new THREE.CapsuleGeometry(0.037, 0.19, 4, 12), skinMat); fa.position.y = -0.12; el.add(fa);
      // כף יד מפורטת עם אצבעות מכופפות מעט
      const parts = [];
      const palm = new THREE.SphereGeometry(1, 14, 10); palm.scale(0.036, 0.05, 0.018); palm.translate(0, -0.045, 0.004); parts.push(palm.toNonIndexed());
      for (let f = 0; f < 4; f++) {
        const len = [0.04, 0.047, 0.044, 0.035][f];
        const p1 = new THREE.CapsuleGeometry(0.0088, len * 0.55, 2, 6); p1.translate(0, -len * 0.3, 0); p1.rotateX(0.3); p1.translate((-0.022 + f * 0.0148) * sx, -0.09, 0.006); parts.push(p1.toNonIndexed());
        const p2 = new THREE.CapsuleGeometry(0.0078, len * 0.45, 2, 6); p2.translate(0, -len * 0.25, 0); p2.rotateX(0.7); p2.translate((-0.022 + f * 0.0148) * sx, -0.118 - len * 0.2, 0.016); parts.push(p2.toNonIndexed());
      }
      const th = new THREE.CapsuleGeometry(0.0105, 0.035, 2, 6); th.rotateZ(0.8 * sx); th.rotateX(0.5); th.translate(0.032 * sx, -0.05, 0.022); parts.push(th.toNonIndexed());
      const nail = new THREE.SphereGeometry(0.004, 6, 4); // ציפורניים קטנות לא נחוצות – שמור על פשטות
      for (const p of parts) for (const k of Object.keys(p.attributes)) if (!['position', 'normal'].includes(k)) p.deleteAttribute(k);
      const hand = new THREE.Mesh(mergeGeometries(parts), skinMat); ha.add(hand);
      for (const m of [ua, fa, hand]) { m.castShadow = false; m.receiveShadow = true; m.renderOrder = 10; }
      this.arms[side] = { sh, el, ha, cur: null, fa };
    }
    // צמיד (מוסתר עד שמקבלים מהשחר)
    this.bracelet = new THREE.Group();
    const band = new THREE.Mesh(new THREE.TorusGeometry(0.04, 0.0055, 8, 32), new THREE.MeshStandardMaterial({ color: 0xe8c07a, roughness: 0.35, metalness: 0.6 }));
    band.rotation.x = Math.PI / 2; this.bracelet.add(band);
    const beadCols = [0xff6b8b, 0x4ac7ff, 0xffd25a, 0xffffff, 0xff6b8b, 0x4ac7ff, 0xffd25a, 0xffffff, 0x9b7bff, 0xffffff];
    for (let i = 0; i < 10; i++) { const a = i / 10 * Math.PI * 2; const b = new THREE.Mesh(new THREE.SphereGeometry(0.0085, 10, 8), new THREE.MeshStandardMaterial({ color: beadCols[i], roughness: 0.25 })); b.position.set(Math.cos(a) * 0.042, 0, Math.sin(a) * 0.042); this.bracelet.add(b); }
    const charm = new THREE.Mesh(new THREE.CircleGeometry(0.011, 16), new THREE.MeshStandardMaterial({ color: 0xffd27a, metalness: 0.8, roughness: 0.3, side: THREE.DoubleSide })); charm.position.set(0, -0.012, 0.05); this.bracelet.add(charm);
    this.bracelet.position.y = -0.215; this.bracelet.visible = false;
    this.arms.L.el.add(this.bracelet);
    // אקדח (פרק 6)
    this.pistol = buildPistol(); this.pistol.scale.setScalar(1.15); this.pistol.position.set(0, -0.09, 0.03); this.pistol.rotation.set(-Math.PI / 2, Math.PI / 2, 0); this.pistol.visible = false;
    this.arms.R.ha.add(this.pistol);
    // פנס (פרק 3)
    this.held = null;
    this.pose = 'idle'; this.poseL = 'idle'; this.poseR = 'idle';
    this.blend = { L: 1, R: 1 };
    this.t = 0; this.bobPhase = 0; this.sway = new THREE.Vector2();
    this.recoil = 0;
    this.setPose('idle', true);
  }
  setLook(look) {
    this.arms.L.fa.material.color.set(look.skin); this.arms.L.sh.children[1].material.color.set(look.sleeve);
  }
  setPose(name, instant = false, side = null) {
    const p = POSES[name] || POSES.idle;
    for (const s of side ? [side] : ['L', 'R']) {
      const a = this.arms[s];
      const [sh, el, ha, off] = p[s];
      a.target = { sh: new THREE.Quaternion().setFromEuler(new THREE.Euler(...sh)), el: new THREE.Quaternion().setFromEuler(new THREE.Euler(...el)), ha: new THREE.Quaternion().setFromEuler(new THREE.Euler(...ha)), off: new THREE.Vector3(...off) };
      if (instant || !a.cur) { a.sh.quaternion.copy(a.target.sh); a.el.quaternion.copy(a.target.el); a.ha.quaternion.copy(a.target.ha); a.sh.position.copy(a.target.off); a.cur = true; }
      if (s === 'L') this.poseL = name; else this.poseR = name;
    }
    this.pose = name;
  }
  /** move: 0..1 מהירות, run: bool, look: דלתא עכבר */
  update(dt, st = {}) {
    this.t += dt;
    const k = Math.min(1, dt * (st.fast ? 18 : 9));
    for (const s of ['L', 'R']) {
      const a = this.arms[s]; if (!a.target) continue;
      a.sh.quaternion.slerp(a.target.sh, k); a.el.quaternion.slerp(a.target.el, k); a.ha.quaternion.slerp(a.target.ha, k);
      a.sh.position.lerp(a.target.off, k);
    }
    // תנועה: סווי לפי עכבר, בוב לפי הליכה/ריצה
    this.sway.x += ((st.lookDX || 0) * -0.0006 - this.sway.x) * Math.min(1, dt * 8);
    this.sway.y += ((st.lookDY || 0) * 0.0006 - this.sway.y) * Math.min(1, dt * 8);
    const sp = st.speed || 0;
    this.bobPhase += dt * (st.run ? 11 : 7) * Math.min(1, sp);
    const bx = Math.sin(this.bobPhase) * 0.012 * sp * (st.run ? 2 : 1);
    const by = Math.abs(Math.cos(this.bobPhase)) * 0.012 * sp * (st.run ? 2.2 : 1);
    const breathe = Math.sin(this.t * 1.6) * 0.004 * (1 + (st.breath || 0) * 2);
    this.recoil *= Math.exp(-dt * 10);
    this.group.position.set(this.sway.x + bx, this.sway.y - by + breathe - (st.crouch ? 0.02 : 0) + this.recoil * 0.02, -this.recoil * 0.05);
    this.group.rotation.set(this.recoil * 0.25, 0, bx * 2);
    if (st.run && (this.poseL === 'run' || this.poseL === 'push')) {
      const p = Math.sin(this.bobPhase);
      this.arms.L.sh.rotation.x += p * 0.25 * k; this.arms.R.sh.rotation.x -= p * 0.25 * k;
    }
  }
}
export { POSES };
