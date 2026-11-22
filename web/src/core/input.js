// קלט: מקלדת, עכבר (Pointer Lock)
export const Input = {
  keys: new Set(), pressed: new Set(), released: new Set(), _pp: new Set(), _pr: new Set(), _click: false, _rclick: false, _dx: 0, _dy: 0,
  mouse: { dx: 0, dy: 0, down: false, clicked: false, rclicked: false },
  locked: false, enabled: true, el: null,
  init(el) {
    this.el = el;
    addEventListener('keydown', e => {
      if (e.target && (e.target.tagName === 'INPUT' || e.target.tagName === 'TEXTAREA')) return;
      if (!this.keys.has(e.code)) this._pp.add(e.code);
      this.keys.add(e.code);
      if (['Space', 'Tab', 'F9', 'ArrowUp', 'ArrowDown'].includes(e.code) || (e.ctrlKey && e.code === 'KeyW')) e.preventDefault();
    });
    addEventListener('keyup', e => { this.keys.delete(e.code); this._pr.add(e.code); });
    addEventListener('blur', () => this.keys.clear());
    addEventListener('mousemove', e => { if (this.locked) { this._dx += e.movementX || 0; this._dy += e.movementY || 0; } });
    addEventListener('mousedown', e => { if (e.button === 0) { this.mouse.down = true; this._click = true; } if (e.button === 2) this._rclick = true; });
    addEventListener('mouseup', e => { if (e.button === 0) this.mouse.down = false; });
    addEventListener('contextmenu', e => { if (this.locked) e.preventDefault(); });
    document.addEventListener('pointerlockchange', () => { this.locked = document.pointerLockElement === this.el; });
  },
  lock() { if (!this.locked && this.el && this.el.requestPointerLock) { try { const p = this.el.requestPointerLock(); if (p && p.catch) p.catch(() => {}); } catch (e) {} } },
  unlock() { if (document.exitPointerLock) document.exitPointerLock(); },
  down(code) { return this.enabled && this.keys.has(code); },
  hit(code) { return this.enabled && this.pressed.has(code); },
  /** נקרא פעם אחת בתחילת כל פריים: קלט שנאסף מאז הפריים הקודם זמין לכל הצרכנים בפריים הזה */
  beginFrame() { this.pressed = this._pp; this._pp = new Set(); this.released = this._pr; this._pr = new Set(); this.mouse.dx = this._dx; this.mouse.dy = this._dy; this._dx = this._dy = 0; this.mouse.clicked = this._click; this.mouse.rclicked = this._rclick; this._click = this._rclick = false; },
  endFrame() { },
  axis() {
    if (!this.enabled) return { x: 0, z: 0 };
    let x = 0, z = 0;
    if (this.keys.has('KeyW') || this.keys.has('ArrowUp')) z += 1;
    if (this.keys.has('KeyS') || this.keys.has('ArrowDown')) z -= 1;
    if (this.keys.has('KeyA') || this.keys.has('ArrowLeft')) x -= 1;
    if (this.keys.has('KeyD') || this.keys.has('ArrowRight')) x += 1;
    return { x, z };
  },
};
