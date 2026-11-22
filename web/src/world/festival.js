// ═══════════════════════════════════════════════════════════════════
//  מתחם מסיבת הטבע – משותף לפרק 1 (לילה) ולפרק 2 (זריחה ובריחה)
//  מזרח = +x (הזריחה). במה בצפון (z שלילי), מתחם אוהלים בדרום, חניה במערב, פרדס/חורשה במזרח.
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { Terrain, scatterGrass, fbm } from './terrain.js';
import { Materials } from './materials.js';
import * as P from './props.js';

export const LAYOUT = {
  stage: new THREE.Vector3(0, 0, -34),
  dance: new THREE.Vector3(0, 0, -14),
  bar: new THREE.Vector3(-26, 0, -8),
  drums: new THREE.Vector3(27, 0, 2),
  chill: new THREE.Vector3(-30, 0, 18),
  rocks: new THREE.Vector3(40, 0, -26),
  medic: new THREE.Vector3(-12, 0, 28),
  toilets: new THREE.Vector3(22, 0, 32),
  camp: new THREE.Vector3(6, 0, 56),
  ourTent: new THREE.Vector3(10, 0, 60),
  parking: new THREE.Vector3(-58, 0, 50),
  roadStart: new THREE.Vector3(-70, 0, 20),
  orchard: new THREE.Vector3(95, 0, 30),
  ditch: new THREE.Vector3(60, 0, 70),
  container: new THREE.Vector3(-20, 0, 82),
};

export function buildFestival({ dawn = false } = {}) {
  const root = new THREE.Group(); root.name = 'festival';
  const colliders = [];
  const updaters = [];
  const box = (x, z, w, d, h = 2, rot = 0) => { colliders.push({ type: 'box', x, z, w, d, h, rot, cover: h > 0.9 }); };
  const circ = (x, z, r, h = 3, cover = true) => colliders.push({ type: 'circle', x, z, r, h, cover });

  // ─ שטח ─
  const flat = [
    { x: 0, z: -18, w: 70, d: 50, h: 0, blend: 25 },
    { x: LAYOUT.camp.x, z: LAYOUT.camp.z, w: 60, d: 34, h: 0.2, blend: 20 },
    { x: LAYOUT.parking.x, z: LAYOUT.parking.z, w: 40, d: 50, h: 0.1, blend: 15 },
    { x: -30, z: 18, w: 26, d: 20, h: 0, blend: 12 },
  ];
  const terrain = new Terrain({
    size: 560, res: 200, tex: 'dry_ground_01', repeat: 110, flatZones: flat, color: dawn ? 0xc8b8a0 : 0x8c7c6c,
    heightFn: (x, z) => {
      let h = (fbm(x * 0.008 + 3, z * 0.008) - 0.5) * 10 + (fbm(x * 0.04, z * 0.04) - 0.5) * 1.0;
      h += Math.max(0, 1 - Math.hypot(x - LAYOUT.rocks.x, z - LAYOUT.rocks.z) / 22) * 4; // גבעת הסלעים
      const dd = Math.hypot(x - LAYOUT.ditch.x, z - LAYOUT.ditch.z); // ואדי/תעלה
      h -= Math.max(0, 1 - Math.abs((z - LAYOUT.ditch.z) - (x - LAYOUT.ditch.x) * 0.3) / 3) * Math.max(0, 1 - dd / 45) * 2.2;
      h += Math.max(0, (Math.hypot(x, z) - 200) * 0.06); // הרים רחוקים קלים
      return h;
    },
  });
  root.add(terrain.mesh);
  // דרך עפר
  const roadPts = [new THREE.Vector3(-260, 0, 10), new THREE.Vector3(-90, 0, 18), LAYOUT.roadStart, new THREE.Vector3(-58, 0, 26), new THREE.Vector3(-40, 0, 30), new THREE.Vector3(-25, 0, 40), new THREE.Vector3(0, 0, 44), new THREE.Vector3(40, 0, 42), new THREE.Vector3(80, 0, 50), new THREE.Vector3(150, 0, 60), new THREE.Vector3(260, 0, 64)];
  const road = buildRoadMesh(roadPts, terrain, 6, 'sandy_gravel');
  root.add(road);
  // ─ צמחייה ─
  const avoid = (x, z) => (Math.abs(x) < 34 && z > -44 && z < 8) || (Math.abs(x - LAYOUT.camp.x) < 34 && Math.abs(z - LAYOUT.camp.z) < 20) || (Math.abs(x - LAYOUT.parking.x) < 22 && Math.abs(z - LAYOUT.parking.z) < 28);
  const grass = scatterGrass(terrain, { count: 9000, area: 220, avoid, color: dawn ? 0xa89764 : 0x8a7d55, height: 0.55 });
  root.add(grass); updaters.push(t => grass.userData.tick(t));
  // שיחים
  for (let i = 0; i < 170; i++) {
    const x = (Math.random() - 0.5) * 420, z = (Math.random() - 0.5) * 420;
    if (avoid(x, z) || Math.hypot(x, z) < 20) continue;
    const b = P.buildBush(i, [0x6b6a45, 0x5f6a40, 0x7a7350][i % 3], 0.8 + Math.random() * 1.2);
    b.position.set(x, terrain.heightAt(x, z) - 0.1, z); b.rotation.y = Math.random() * 6; root.add(b);
    circ(x, z, 0.9 * b.scale.x, 1.4, true); colliders[colliders.length - 1].bush = true;
  }
  // סלעים – כולל "הסלעים של שחר"
  for (let i = 0; i < 9; i++) {
    const a = i / 9 * Math.PI * 2; const x = LAYOUT.rocks.x + Math.cos(a) * (3 + (i % 3) * 2.5), z = LAYOUT.rocks.z + Math.sin(a) * (3 + (i % 2) * 3);
    const r = P.buildRock(i + 3, 1.2 + (i % 3) * 0.6); r.position.set(x, terrain.heightAt(x, z) - 0.2, z); r.rotation.y = i; root.add(r); circ(x, z, 1.1 * (1.2 + (i % 3) * 0.6), 1.2);
  }
  for (let i = 0; i < 40; i++) { const x = (Math.random() - 0.5) * 400, z = (Math.random() - 0.5) * 400; if (avoid(x, z)) continue; const s = 0.4 + Math.random() * 1.5; const r = P.buildRock(i, s); r.position.set(x, terrain.heightAt(x, z) - 0.15 * s, z); root.add(r); if (s > 0.8) circ(x, z, s, 1); }
  // עצים: אקליפטוסים לאורך הדרך, חורשה/פרדס במזרח
  for (let i = 0; i < 26; i++) { const p = roadPts[2 + (i % 7)].clone().lerp(roadPts[3 + (i % 7)], Math.random()); const x = p.x + (Math.random() < 0.5 ? -9 : 9) + Math.random() * 4, z = p.z + (Math.random() - 0.5) * 6; if (avoid(x, z)) continue; const t = P.buildTree('eucalyptus', i); t.position.set(x, terrain.heightAt(x, z), z); t.rotation.y = Math.random() * 6; t.scale.setScalar(0.8 + Math.random() * 0.5); root.add(t); circ(x, z, 0.5, 6); }
  for (let ix = 0; ix < 9; ix++) for (let iz = 0; iz < 7; iz++) { const x = LAYOUT.orchard.x + ix * 7 + (Math.random() - 0.5), z = LAYOUT.orchard.z - 20 + iz * 7 + (Math.random() - 0.5); const t = P.buildTree('olive', ix * 7 + iz); t.position.set(x, terrain.heightAt(x, z), z); t.rotation.y = Math.random() * 6; root.add(t); circ(x, z, 0.4, 4); }
  // ─ במה ─
  const stage = P.buildStage(); stage.position.copy(LAYOUT.stage); root.add(stage);
  box(LAYOUT.stage.x, LAYOUT.stage.z, 18.4, 10.4, 1.4); box(-11, LAYOUT.stage.z + 3, 1.5, 1.2, 5); box(11, LAYOUT.stage.z + 3, 1.5, 1.2, 5);
  updaters.push((t, beat, k) => stage.userData.update(t, beat, k));
  // גדר במה (מחסום קהל)
  const fenceMat = P.M.std(0x2a2c30, 0.5, 0.7);
  for (let i = 0; i < 9; i++) { const f = P.rbox(1.9, 1.1, 0.5, fenceMat, 0.05); f.position.set(-8 + i * 2, 0.55, LAYOUT.stage.z + 7.5); root.add(f); }
  box(0, LAYOUT.stage.z + 7.5, 18, 0.6, 1.1);
  // עמוד FOH (עמדת סאונד)
  const foh = new THREE.Group(); const tent = P.buildShadeSail(5, 4, 0x1d1d24); foh.add(tent); const desk = P.rbox(2.8, 1.0, 1.0, P.M.std(0x111114, 0.6), 0.05); desk.position.y = 0.5; foh.add(desk);
  const screens = new THREE.Mesh(new THREE.PlaneGeometry(1.6, 0.5), P.M.emit(0x2a8cff, 1.4)); screens.position.set(0, 1.25, 0.2); screens.rotation.x = -0.5; foh.add(screens);
  foh.position.set(0, 0, 4); root.add(foh); box(0, 4, 3, 1.2, 1);
  // ─ דגלים ותאורה סביב רחבת הריקודים ─
  const flagCols = [0xff6b4a, 0xffd25a, 0x39e0ff, 0xff4f8b, 0x8a5bff, 0x2fd68a];
  for (let i = 0; i < 14; i++) { const a = -Math.PI * 0.95 + i / 13 * Math.PI * 0.9; const x = Math.cos(a) * 32, z = LAYOUT.dance.z - 8 - Math.sin(a) * 20; const f = P.buildFlagPole(flagCols[i % flagCols.length], 6 + (i % 3)); f.position.set(x, terrain.heightAt(x, z), z); root.add(f); updaters.push(t => f.userData.update(t)); }
  // שרשראות נורות מעל הרחבה ובמתחם הצ'יל
  const sl = (pts, col) => { const s = P.buildStringLights(pts.map(p => new THREE.Vector3(p[0], p[1], p[2])), col, 12, 0.9); root.add(s); };
  for (let i = 0; i < 5; i++) sl([[-28, 5.5, -30 + i * 7], [-10, 6.5, -26 + i * 7], [10, 6.5, -26 + i * 7], [28, 5.5, -30 + i * 7]]);
  for (let i = -1; i <= 1; i++) { const pole = P.cyl(0.05, 0.06, 6.6, P.M.std(0x5a4632, 0.8), 6); pole.position.set(-28, 3.3, -30 + (i + 1) * 14); root.add(pole); const p2 = pole.clone(); p2.position.x = 28; root.add(p2); }
  // מגדלי תאורה
  const towers = [];
  for (const [x, z, ry] of [[-38, -2, 0.8], [38, -2, -0.8], [-20, 40, 2.5], [30, 46, -2.5], [-50, 40, 1.5]]) { const t = P.buildLightTower(!dawn); t.position.set(x, terrain.heightAt(x, z), z); t.rotation.y = ry; root.add(t); towers.push(t); box(x, z, 2, 1.4, 1.2, ry); }
  // ─ בר ─
  const bar = P.buildBarStall(); bar.position.copy(LAYOUT.bar); bar.rotation.y = Math.PI / 2; root.add(bar); box(LAYOUT.bar.x, LAYOUT.bar.z, 1.2, 4.4, 1.2);
  // דוכן אוכל
  const food = P.buildBarStall(); food.position.set(-26, 0, -20); food.rotation.y = Math.PI / 2; root.add(food); box(-26, -20, 1.2, 4.4, 1.2);
  // ─ מתחם צ'יל ─
  const sail = P.buildShadeSail(12, 10, 0xe8d9b8); sail.position.copy(LAYOUT.chill); root.add(sail);
  for (let i = 0; i < 4; i++) { const r = P.buildRug(3.2, 2.2, i * 60 + 10); r.position.set(LAYOUT.chill.x - 3 + (i % 2) * 5, 0.03, LAYOUT.chill.z - 2 + Math.floor(i / 2) * 4); r.rotation.z = i * 0.3; root.add(r); }
  for (let i = 0; i < 6; i++) { const b = P.buildBeanbag([0xd9483b, 0x2b7bd6, 0xf2c12e, 0x2fa36b, 0x9b5bff, 0xff8a3d][i]); b.position.set(LAYOUT.chill.x - 4 + i * 1.6, 0, LAYOUT.chill.z + (i % 2) * 3 - 1); root.add(b); }
  for (const [x, z] of [[-6, -5], [6, -5], [-6, 5], [6, 5]]) circ(LAYOUT.chill.x + x, LAYOUT.chill.z + z, 0.15, 3.4, false);
  // ─ מעגל תופים ─
  for (let i = 0; i < 8; i++) { const a = i / 8 * Math.PI * 2; const log = P.cyl(0.25, 0.28, 1.8, Materials.pbr('wood_planks', 0.5, { color: 0x8a6a48 }), 10); log.rotation.z = Math.PI / 2; log.rotation.y = a; log.position.set(LAYOUT.drums.x + Math.cos(a) * 4, 0.25, LAYOUT.drums.z + Math.sin(a) * 4); root.add(log); }
  const lantern = new THREE.PointLight(0xff9a4a, 8, 12, 2); lantern.position.set(LAYOUT.drums.x, 1.2, LAYOUT.drums.z); root.add(lantern);
  const lanternMesh = new THREE.Mesh(new THREE.SphereGeometry(0.25, 14, 10), P.M.emit(0xffa24a, 5)); lanternMesh.position.copy(lantern.position); root.add(lanternMesh);
  updaters.push(t => { lantern.intensity = 7 + Math.sin(t * 9) * 0.6 + Math.sin(t * 23) * 0.3; });
  // ─ עזרה ראשונה (דגל כתום) ─
  const medic = P.buildShadeSail(5, 4, 0xf2f2f2); medic.position.copy(LAYOUT.medic); root.add(medic);
  const mflag = P.buildFlagPole(0xff7a1a, 5); mflag.position.set(LAYOUT.medic.x + 3, 0, LAYOUT.medic.z); root.add(mflag); updaters.push(t => mflag.userData.update(t));
  const cot = P.rbox(0.8, 0.45, 1.9, P.M.std(0x3d5a7a, 0.8), 0.05); cot.position.set(LAYOUT.medic.x, 0.25, LAYOUT.medic.z); root.add(cot);
  for (let i = 0; i < 6; i++) { const w = P.cyl(0.04, 0.04, 0.26, new THREE.MeshPhysicalMaterial({ color: 0xbfe6ff, transparent: true, opacity: 0.6, roughness: 0.1 }), 10); w.position.set(LAYOUT.medic.x - 1.5 + i * 0.15, 0.95, LAYOUT.medic.z + 1.5); root.add(w); }
  const mtable = P.rbox(1.4, 0.8, 0.6, P.M.std(0xe8e8e8, 0.5), 0.03); mtable.position.set(LAYOUT.medic.x - 1.2, 0.4, LAYOUT.medic.z + 1.5); root.add(mtable); box(LAYOUT.medic.x - 1.2, LAYOUT.medic.z + 1.5, 1.4, 0.6, 0.8);
  // ─ שירותים ─
  for (let i = 0; i < 6; i++) { const t = P.buildPortaToilet([0x2b7bd6, 0x2fa36b][i % 2]); t.position.set(LAYOUT.toilets.x + i * 1.3, 0, LAYOUT.toilets.z); root.add(t); }
  box(LAYOUT.toilets.x + 3.25, LAYOUT.toilets.z, 8, 1.3, 2.4);
  // ─ מתחם אוהלים ─
  const tentCols = [0x3d6f8a, 0x8a3d3d, 0x4f7a3a, 0xd9a032, 0x5a4f8a, 0x2e6b6b, 0xb5552e, 0x7a7a7a];
  const tents = [];
  for (let ix = -4; ix <= 4; ix++) for (let iz = -2; iz <= 2; iz++) {
    const x = LAYOUT.camp.x + ix * 6 + (Math.random() - 0.5) * 2, z = LAYOUT.camp.z + iz * 6 + (Math.random() - 0.5) * 2;
    if (Math.hypot(x - LAYOUT.ourTent.x, z - LAYOUT.ourTent.z) < 4) continue;
    if (Math.random() < 0.18) continue;
    const t = P.buildDomeTent(tentCols[(ix * 5 + iz + 20) % tentCols.length], 0.85 + Math.random() * 0.35);
    t.position.set(x, terrain.heightAt(x, z), z); t.rotation.y = Math.random() * 6; root.add(t); tents.push(t);
    circ(x, z, 1.4 * t.scale.x, 1.2);
    if (Math.random() < 0.4) { const c = P.buildCampChair([0x2a6b4f, 0x8a2d2d, 0x2d4a8a][(ix + iz + 9) % 3]); c.position.set(x + 2, 0, z + 1); c.rotation.y = Math.random() * 6; root.add(c); }
    if (Math.random() < 0.3) { const c = P.buildCooler([0x2b7bd6, 0xd9483b, 0xf2c12e][(ix + 9) % 3]); c.position.set(x - 1.8, terrain.heightAt(x, z), z + 0.8); root.add(c); }
  }
  // האוהל שלנו – גדול, עם צלון, שקי שינה ונורות
  const ourTent = new THREE.Group(); ourTent.position.copy(LAYOUT.ourTent); root.add(ourTent);
  const bigTent = P.buildDomeTent(0x2e6b8a, 1.7); ourTent.add(bigTent);
  const bags = [];
  for (let i = 0; i < 4; i++) { const b = P.buildSleepingBag([0x2f5d8a, 0x8a2f4f, 0x3a7a3a, 0xd9a032][i]); b.position.set(-1.3 + i * 0.85, 0.02, 0.2); ourTent.add(b); bags.push(b); }
  const tentLight = new THREE.PointLight(0xffc98a, 2.2, 6, 2); tentLight.position.set(0, 1.6, 0); ourTent.add(tentLight);
  const tentLamp = new THREE.Mesh(new THREE.SphereGeometry(0.08, 10, 8), P.M.emit(0xffc98a, 4)); tentLamp.position.copy(tentLight.position); ourTent.add(tentLamp);
  const rugT = P.buildRug(3, 2, 200); rugT.position.set(0, 0.04, 3.2); ourTent.add(rugT);
  const chairs = []; for (let i = 0; i < 3; i++) { const c = P.buildCampChair([0x2a6b4f, 0x8a2d2d, 0x2d4a8a][i]); c.position.set(-1.5 + i * 1.5, 0, 4.5); c.rotation.y = Math.PI; ourTent.add(c); chairs.push(c); }
  ourTent.add(P.buildStringLights([new THREE.Vector3(-2.5, 2.4, 2.4), new THREE.Vector3(2.5, 2.4, 2.4)], 0xffc47a, 10, 0.3));
  // קירות האוהל: מסביב (שהשחקן ייכנס מהפתח בלבד)
  for (let i = 0; i < 12; i++) { const a = i / 12 * Math.PI * 2; if (Math.abs(Math.atan2(Math.sin(a - Math.PI / 2), Math.cos(a - Math.PI / 2))) < 0.5) continue; circ(LAYOUT.ourTent.x + Math.cos(a) * 2.25, LAYOUT.ourTent.z + Math.sin(a) * 2.1, 0.35, 1.2, false); }
  // ─ חניה ─
  const carTypes = ['sedan', 'hatch', 'pickup', 'van', 'sedan', 'hatch'];
  const carCols = [0x9aa3ad, 0xe8e8e8, 0x1f2a44, 0x8a1d1d, 0x2b2b2b, 0xc9a24a, 0x3d6b4f, 0x5a6b7a];
  const cars = [];
  // רכבים מפוזרים בשדה – בלי שורות, כל אחד בזווית אחרת (חניה אופיינית למסיבת טבע)
  const carSpots = [];
  const tryCar = (x, z) => { for (const q of carSpots) if (Math.hypot(q[0] - x, q[1] - z) < 5.2) return false; for (const t of tents) if (Math.hypot(t.position.x - x, t.position.z - z) < 4) return false; return true; };
  let made = 0;
  for (let i = 0; i < 400 && made < 46; i++) {
    // אזור עיקרי: שדה מערבי/דרומי-מערבי, ועוד רכבים בודדים בין האוהלים ובשולי הדרך
    const zone = i % 5;
    let x, z;
    if (zone < 3) { x = LAYOUT.parking.x + (Math.random() - 0.5) * 70; z = LAYOUT.parking.z + (Math.random() - 0.5) * 80; }
    else if (zone === 3) { x = LAYOUT.camp.x + (Math.random() - 0.5) * 70; z = LAYOUT.camp.z + 14 + Math.random() * 20; }
    else { const p = roadPts[2 + Math.floor(Math.random() * 6)]; x = p.x + (Math.random() < 0.5 ? -6 : 6) + (Math.random() - 0.5) * 3; z = p.z + (Math.random() - 0.5) * 10; }
    if (Math.abs(x) < 36 && z < 10) continue;
    if (!tryCar(x, z)) continue;
    const type = carTypes[made % carTypes.length];
    const car = P.buildCar(type, carCols[(made * 7 + 3) % carCols.length], { bulletHoles: dawn && Math.random() < 0.25 ? 6 : 0 });
    car.position.set(x, terrain.heightAt(x, z), z); car.rotation.y = Math.random() * Math.PI * 2; root.add(car);
    box(x, z, car.userData.len, car.userData.width, 1.5, -car.rotation.y); car.userData.collider = colliders[colliders.length - 1];
    carSpots.push([x, z]); cars.push(car); made++;
  }
  // מכולה/מבנה בטון (מסתור במסלול ג')
  const cont = new THREE.Group(); cont.position.copy(LAYOUT.container);
  const contMat = Materials.pbr('damaged_plaster', 2, { color: 0xb8b0a0 });
  const walls = [[0, 0, 6, 0.3, 2.6, 2.2], [-2.85, 2, 0.3, 4.3, 2.6, 0], [2.85, 2, 0.3, 4.3, 2.6, 0], [1.9, 4.15, 2.2, 0.3, 2.6, 0], [-1.9, 4.15, 2.2, 0.3, 2.6, 0]];
  for (const [x, z, w, d, h] of walls) { const m = P.rbox(w, h, d, contMat, 0.03); m.position.set(x, h / 2, z); cont.add(m); box(LAYOUT.container.x + x, LAYOUT.container.z + z, w, d, h); }
  const roof = P.rbox(6.2, 0.25, 4.6, contMat, 0.03); roof.position.set(0, 2.72, 2.1); cont.add(roof);
  root.add(cont);
  // ─ אמביינט לילה: ערפל נמוך (ספרייטים) ─
  const fogTex = P.M && fogSpriteTex();
  const fogGroup = new THREE.Group(); root.add(fogGroup);
  if (dawn) for (let i = 0; i < 40; i++) { const s = new THREE.Sprite(new THREE.SpriteMaterial({ map: fogTex, color: dawn ? 0xd8c0a8 : 0x6a4a8a, transparent: true, opacity: dawn ? 0.08 : 0.12, depthWrite: false })); const x = (Math.random() - 0.5) * 120, z = -40 + Math.random() * 110; s.position.set(x, 1.2 + Math.random(), z); s.scale.set(18, 6, 1); fogGroup.add(s); }
  updaters.push(t => fogGroup.children.forEach((s, i) => { s.position.x += Math.sin(t * 0.1 + i) * 0.004; }));

  return { root, terrain, colliders, updaters, stage, bar, tents, ourTent, bags, cars, chairs, towers, roadPts, road, grass, container: cont, tentLight };
}

let _fogTex = null;
export function fogSpriteTex() {
  if (_fogTex) return _fogTex;
  _fogTex = Materials.canvasTex(128, 128, (c, W, H) => { const g = c.createRadialGradient(W / 2, H / 2, 0, W / 2, H / 2, W / 2); g.addColorStop(0, 'rgba(255,255,255,0.9)'); g.addColorStop(0.5, 'rgba(255,255,255,0.35)'); g.addColorStop(1, 'rgba(255,255,255,0)'); c.fillStyle = g; c.fillRect(0, 0, W, H); });
  return _fogTex;
}

/** כביש/דרך לאורך spline על פני השטח */
export function buildRoadMesh(points, terrain, width = 6, tex = 'asphalt_02') {
  const curve = new THREE.CatmullRomCurve3(points);
  const N = 400; const pos = [], uv = [], idx = [];
  let acc = 0; let prev = curve.getPoint(0);
  for (let i = 0; i <= N; i++) {
    const t = i / N; const p = curve.getPoint(t); const tan = curve.getTangent(t); const n = new THREE.Vector3(-tan.z, 0, tan.x).normalize();
    acc += p.distanceTo(prev); prev = p;
    for (const s of [-1, 1]) { const q = p.clone().addScaledVector(n, s * width / 2); pos.push(q.x, terrain.heightAt(q.x, q.z) + 0.05, q.z); uv.push(s < 0 ? 0 : 1, acc / width); }
    if (i < N) { const a = i * 2; idx.push(a, a + 2, a + 1, a + 1, a + 2, a + 3); }
  }
  const geo = new THREE.BufferGeometry(); geo.setAttribute('position', new THREE.Float32BufferAttribute(pos, 3)); geo.setAttribute('uv', new THREE.Float32BufferAttribute(uv, 2)); geo.setIndex(idx); geo.computeVertexNormals();
  const mat = Materials.pbr(tex, 1, { color: tex === 'sandy_gravel' ? 0xc8b48e : 0xffffff }).clone();
  mat.polygonOffset = true; mat.polygonOffsetFactor = -1;
  const m = new THREE.Mesh(geo, mat); m.receiveShadow = true; m.userData.curve = curve;
  return m;
}
