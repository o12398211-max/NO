// ═══════════════════════════════════════════════════════════════════
//  Net – מולטיפלייר שיתופי ב-WebRTC דרך PeerJS (עובד מאחסון סטטי, בלי שרת משלנו).
//  טופולוגיית כוכב: המארח הוא הסמכות (דגלי עלילה, פאזלים, מעברי פרק). חדר לפי קוד בן 5 תווים.
//  "חברים בלבד" = חדר נעול בקוד נעילה (PIN) שנשלח רק בקישור ההזמנה.
// ═══════════════════════════════════════════════════════════════════
import { Peer } from 'peerjs';
import { CONFIG } from '../config/game.config.js';

const ALPH = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
const code = (n) => Array.from({ length: n }, () => ALPH[Math.floor(Math.random() * ALPH.length)]).join('');
const VERSION = 1;

export const Net = {
  peer: null, isHost: false, online: false, id: null, conns: new Map(), hostConn: null,
  players: new Map(), handlers: {}, room: null, pin: null, size: 4, locked: false, started: false,
  on(t, fn) { (this.handlers[t] = this.handlers[t] || []).push(fn); },
  off(t) { delete this.handlers[t]; },
  _emit(t, ...a) { for (const f of this.handlers[t] || []) f(...a); },

  /** יצירת חדר. מחזיר {code, pin, link} */
  host({ size = 4, locked = false, me }) {
    return new Promise((res, rej) => {
      this.leave();
      const room = code(CONFIG.roomCodeLength);
      this.isHost = true; this.size = size; this.locked = locked; this.room = room; this.pin = locked ? String(Math.floor(1000 + Math.random() * 9000)) : null;
      const peer = this.peer = new Peer(CONFIG.peerPrefix + room, { debug: 0 });
      const to = setTimeout(() => rej(new Error('timeout')), 15000);
      peer.on('open', id => {
        clearTimeout(to); this.online = true; this.id = id;
        this.players.clear(); this.players.set(id, { id, ...me, host: true, score: { time: 0, puzzles: 0, chapter: 1 } });
        this._emit('roster', this.roster());
        res({ code: room, pin: this.pin, link: this.inviteLink() });
      });
      peer.on('connection', c => this._hostConn(c));
      peer.on('error', e => { if (e.type === 'unavailable-id') { clearTimeout(to); this.host({ size, locked, me }).then(res, rej); } else { this._emit('error', e); } });
      peer.on('disconnected', () => { try { peer.reconnect(); } catch (e) {} });
    });
  },
  inviteLink() {
    const u = new URL(location.href); u.hash = `room=${this.room}` + (this.pin ? `&k=${this.pin}` : ''); u.search = '';
    return u.toString();
  },
  _hostConn(c) {
    c.on('data', d => {
      if (d.t === 'hello') {
        const reason = d.v !== VERSION ? 'version' : this.players.size >= this.size ? 'full' : (this.locked && d.pin !== this.pin) ? 'locked' : this.started ? 'started' : null;
        if (reason) { c.send({ t: 'reject', reason }); setTimeout(() => c.close(), 300); return; }
        this.conns.set(c.peer, c);
        this.players.set(c.peer, { id: c.peer, name: d.name, look: d.look, gender: d.gender, host: false, score: { time: 0, puzzles: 0, chapter: 1 } });
        c.send({ t: 'welcome', id: c.peer, size: this.size });
        this.broadcast({ t: 'roster', players: this.roster() });
        this._emit('roster', this.roster());
        return;
      }
      if (!this.conns.has(c.peer)) return;
      if (d.t === 'st') { d.id = c.peer; this.broadcast(d, c.peer); this._emit('st', d); return; }
      if (d.t === 'score') { const p = this.players.get(c.peer); if (p) p.score = d.score; this.broadcast({ t: 'roster', players: this.roster() }); this._emit('roster', this.roster()); return; }
      this._emit('msg', d, c.peer);
      this._emit(d.t, d, c.peer);
    });
    c.on('close', () => { if (this.conns.delete(c.peer)) { this.players.delete(c.peer); this.broadcast({ t: 'roster', players: this.roster() }); this._emit('roster', this.roster()); this._emit('left', c.peer); } });
  },
  /** הצטרפות לחדר */
  join({ room, pin, me }) {
    return new Promise((res, rej) => {
      this.leave();
      this.isHost = false; this.room = room.toUpperCase().trim(); this.pin = pin || null;
      const peer = this.peer = new Peer(undefined, { debug: 0 });
      const to = setTimeout(() => { rej(new Error('connect')); }, 15000);
      peer.on('open', id => {
        this.id = id;
        const c = this.hostConn = peer.connect(CONFIG.peerPrefix + this.room, { reliable: true });
        c.on('open', () => c.send({ t: 'hello', v: VERSION, name: me.name, look: me.look, gender: me.gender, pin: this.pin }));
        c.on('data', d => {
          if (d.t === 'reject') { clearTimeout(to); rej(new Error(d.reason)); this.leave(); return; }
          if (d.t === 'welcome') { clearTimeout(to); this.online = true; res(d); return; }
          if (d.t === 'roster') { this.players = new Map(d.players.map(p => [p.id, p])); this._emit('roster', d.players); return; }
          if (d.t === 'kick') { this._emit('kicked'); this.leave(); return; }
          if (d.t === 'st') { this._emit('st', d); return; }
          this._emit('msg', d); this._emit(d.t, d);
        });
        c.on('close', () => { if (this.online) { this.online = false; this._emit('hostLeft'); } });
      });
      peer.on('error', e => { clearTimeout(to); if (!this.online) rej(e); else this._emit('error', e); });
    });
  },
  roster() { return [...this.players.values()]; },
  /** שליחה: מארח → כולם; לקוח → מארח */
  send(msg) {
    if (!this.online) return;
    if (this.isHost) { this.broadcast(msg); } else if (this.hostConn && this.hostConn.open) this.hostConn.send(msg);
  },
  broadcast(msg, except) { for (const [id, c] of this.conns) if (id !== except && c.open) c.send(msg); },
  /** אירוע עלילה סמכותי: המארח משדר ומפעיל מקומית; לקוח מבקש מהמארח */
  event(e, data = {}) {
    if (!this.online) { this._emit('ev', { e, ...data }); return; }
    if (this.isHost) { this.broadcast({ t: 'ev', e, ...data }); this._emit('ev', { e, ...data }); }
    else this.hostConn && this.hostConn.send({ t: 'req', e, ...data });
  },
  kick(id) { const c = this.conns.get(id); if (c) { c.send({ t: 'kick' }); setTimeout(() => c.close(), 200); } },
  sendScore(score) { const me = this.players.get(this.id); if (me) me.score = score; if (this.isHost) { this.broadcast({ t: 'roster', players: this.roster() }); this._emit('roster', this.roster()); } else this.send({ t: 'score', score }); },
  count() { return this.online ? this.players.size : 1; },
  leave() {
    this.online = false; this.started = false;
    try { for (const c of this.conns.values()) c.close(); this.hostConn && this.hostConn.close(); this.peer && this.peer.destroy(); } catch (e) {}
    this.conns.clear(); this.hostConn = null; this.peer = null; this.players.clear();
  },
};
