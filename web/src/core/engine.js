// ═══════════════════════════════════════════════════════════════════
//  Engine – רנדרר, סצנה, מצלמה ושרשרת פוסט־פרוססינג קולנועית
//  Render → GTAO (SSAO) → Bloom → Bokeh (DOF) → Output(ACES+sRGB) → Cinematic(Grade/Grain/Vignette/CA/MotionBlur/Eyelids)
// ═══════════════════════════════════════════════════════════════════
import * as THREE from 'three';
import { EffectComposer } from 'three/examples/jsm/postprocessing/EffectComposer.js';
import { RenderPass } from 'three/examples/jsm/postprocessing/RenderPass.js';
import { UnrealBloomPass } from 'three/examples/jsm/postprocessing/UnrealBloomPass.js';
import { BokehPass } from 'three/examples/jsm/postprocessing/BokehPass.js';
import { GTAOPass } from 'three/examples/jsm/postprocessing/GTAOPass.js';
import { OutputPass } from 'three/examples/jsm/postprocessing/OutputPass.js';
import { ShaderPass } from 'three/examples/jsm/postprocessing/ShaderPass.js';
import { GRADES } from '../config/grades.js';
import { Settings } from './settings.js';

const CinematicShader = {
  uniforms: {
    tDiffuse: { value: null },
    uTime: { value: 0 },
    uRes: { value: new THREE.Vector2(1, 1) },
    uSat: { value: 1 }, uContrast: { value: 1 }, uExposure: { value: 1 },
    uLift: { value: new THREE.Vector3() }, uGamma: { value: new THREE.Vector3(1, 1, 1) }, uGain: { value: new THREE.Vector3(1, 1, 1) },
    uShadowTint: { value: new THREE.Vector3() }, uHighTint: { value: new THREE.Vector3(1, 1, 1) },
    uVignette: { value: 0.4 }, uGrain: { value: 0.05 }, uCA: { value: 0.001 },
    uRadialBlur: { value: 0 }, uTunnel: { value: 0 }, uHit: { value: 0 }, uFade: { value: 0 },
    uEyelid: { value: 0 }, uBlur: { value: 0 }, uFlash: { value: 0 }, uDesat: { value: 0 },
    uLetterbox: { value: 0 }, uFadeColor: { value: new THREE.Vector3(0, 0, 0) }, uBreath: { value: 0 },
  },
  vertexShader: /* glsl */`varying vec2 vUv; void main(){ vUv=uv; gl_Position=projectionMatrix*modelViewMatrix*vec4(position,1.); }`,
  fragmentShader: /* glsl */`
    uniform sampler2D tDiffuse; uniform float uTime; uniform vec2 uRes;
    uniform float uSat,uContrast,uExposure; uniform vec3 uLift,uGamma,uGain,uShadowTint,uHighTint;
    uniform float uVignette,uGrain,uCA,uRadialBlur,uTunnel,uHit,uFade,uEyelid,uBlur,uFlash,uDesat,uLetterbox,uBreath;
    uniform vec3 uFadeColor;
    varying vec2 vUv;
    float hash(vec2 p){ return fract(sin(dot(p, vec2(12.9898,78.233))) * 43758.5453); }
    vec3 sampleCA(vec2 uv, float amt){
      vec2 d = (uv-0.5) * amt;
      return vec3(texture2D(tDiffuse, uv - d).r, texture2D(tDiffuse, uv).g, texture2D(tDiffuse, uv + d).b);
    }
    void main(){
      vec2 uv = vUv;
      vec2 c = uv - 0.5;
      float r = length(c * vec2(uRes.x/uRes.y, 1.0));
      float caAmt = uCA * (1.0 + uTunnel*3.0 + uHit*4.0) * (0.5 + r*2.0);
      vec3 col = sampleCA(uv, caAmt);
      // Radial motion blur (קצוות בלבד) + טשטוש התעוררות
      float rb = uRadialBlur * smoothstep(0.15, 0.75, r) + uTunnel*0.03;
      if (rb > 0.0005 || uBlur > 0.001) {
        vec3 acc = col; float wsum = 1.0;
        for (int i = 1; i <= 8; i++) {
          float f = float(i) / 8.0;
          vec2 o = c * rb * f;
          float ang = f * 6.2831 + uTime;
          vec2 bo = vec2(cos(ang), sin(ang)) * uBlur * 0.012 * f;
          acc += texture2D(tDiffuse, uv - o + bo).rgb; wsum += 1.0;
        }
        col = acc / wsum;
      }
      // ─ Grade ─
      col *= uExposure;
      col = pow(max(col, 0.0), 1.0/uGamma);
      col = col * uGain + uLift * (1.0 - col);
      float l = dot(col, vec3(0.2126,0.7152,0.0722));
      col += uShadowTint * (1.0 - smoothstep(0.0, 0.45, l)) * 0.6;
      col *= mix(vec3(1.0), uHighTint, smoothstep(0.55, 1.0, l) * 0.35);
      col = (col - 0.5) * uContrast + 0.5;
      l = dot(col, vec3(0.2126,0.7152,0.0722));
      col = mix(vec3(l), col, uSat * (1.0 - uDesat));
      // ─ Vignette + tunnel vision ─
      float v = smoothstep(0.85, 0.2, r * (1.0 + uVignette*0.6 + uTunnel*1.4 + uBreath*0.25));
      col *= mix(1.0 - uVignette*0.9, 1.0, v);
      col *= 1.0 - smoothstep(0.32, 0.9, r) * uTunnel;
      // ─ Hit (קצה אדום) ─
      float edge = smoothstep(0.25, 0.85, r);
      col = mix(col, vec3(0.45, 0.02, 0.02), edge * uHit * 0.85);
      // ─ Grain ─
      float g = hash(uv * uRes + fract(uTime*7.13)*100.0) - 0.5;
      col += g * uGrain * (0.6 + (1.0-l)*0.8);
      // ─ Flash ─
      col = mix(col, vec3(1.0, 0.97, 0.92), uFlash);
      // ─ Eyelids (עין נסגרת/נפתחת) ─
      float lid = uEyelid;
      if (lid > 0.001) {
        float curve = (uv.x - 0.5); curve = curve*curve*0.9;
        float top = 1.0 - lid*0.62 - curve*(1.0-lid);
        float bot = lid*0.62 + curve*(1.0-lid);
        float soft = 0.05 + 0.08*(1.0-lid);
        float open = smoothstep(top, top - soft, uv.y) * smoothstep(bot, bot + soft, uv.y);
        if (lid > 0.995) open = 0.0;
        col *= open;
      }
      // ─ Letterbox 2.35:1 ─
      float bar = uLetterbox * 0.12;
      if (uv.y < bar || uv.y > 1.0 - bar) col = vec3(0.0);
      // ─ Fade ─
      col = mix(col, uFadeColor, uFade);
      gl_FragColor = vec4(col, 1.0);
    }`,
};

export class Engine {
  constructor(container) {
    this.container = container;
    const r = this.renderer = new THREE.WebGLRenderer({ antialias: false, powerPreference: 'high-performance', stencil: false });
    r.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
    r.setSize(window.innerWidth, window.innerHeight);
    r.outputColorSpace = THREE.SRGBColorSpace;
    r.toneMapping = THREE.ACESFilmicToneMapping;
    r.toneMappingExposure = 1.0;
    r.shadowMap.enabled = true;
    r.shadowMap.type = THREE.PCFSoftShadowMap;
    container.appendChild(r.domElement);
    r.domElement.id = 'gl';

    this.scene = new THREE.Scene();
    this.camera = new THREE.PerspectiveCamera(72, window.innerWidth / window.innerHeight, 0.03, 1500);
    this.scene.add(this.camera);
    this.clock = new THREE.Clock();
    this.time = 0;
    this.pixelScale = 1;
    this.quality = 'high';
    this.fx = { radialBlur: 0, tunnel: 0, hit: 0, fade: 0, eyelid: 0, blur: 0, flash: 0, desat: 0, letterbox: 0, breath: 0 };
    this.fxTarget = {};
    this.grade = { ...GRADES.lobby };
    this.gradeTarget = GRADES.lobby;
    this.postEnabled = true;
    this.fpsSamples = [];
    this.updaters = new Set();

    this._buildComposer();
    window.addEventListener('resize', () => this.resize());
  }

  _buildComposer() {
    const w = window.innerWidth, h = window.innerHeight;
    const c = this.composer = new EffectComposer(this.renderer);
    this.renderPass = new RenderPass(this.scene, this.camera);
    c.addPass(this.renderPass);
    this.gtao = new GTAOPass(this.scene, this.camera, Math.floor(w / 2), Math.floor(h / 2));
    this.gtao.output = GTAOPass.OUTPUT.Default;
    this.gtao.blendIntensity = 0.9;
    this.gtao.updateGtaoMaterial({ radius: 0.5, distanceExponent: 1.4, thickness: 1.2, scale: 1.0, samples: 12 });
    c.addPass(this.gtao);
    this.bloom = new UnrealBloomPass(new THREE.Vector2(w / 2, h / 2), 0.7, 0.6, 0.82);
    c.addPass(this.bloom);
    this.bokeh = new BokehPass(this.scene, this.camera, { focus: 3.0, aperture: 0.004, maxblur: 0.008 });
    this.bokeh.enabled = false;
    c.addPass(this.bokeh);
    c.addPass(new OutputPass());
    this.cine = new ShaderPass(CinematicShader);
    c.addPass(this.cine);
    this.setQuality(Settings.get('quality'));
  }

  setQuality(q) {
    this.qualitySetting = q;
    if (q === 'auto') q = this.quality || 'high';
    this.quality = q;
    this.gtao.enabled = q === 'high';
    this.renderer.shadowMap.enabled = q !== 'low';
    this.bloom.enabled = true;
    this.pixelScale = q === 'low' ? 0.7 : q === 'medium' ? 0.85 : 1;
    this.resize();
    this.scene.traverse(o => { if (o.material) o.material.needsUpdate = true; });
  }

  setDOF(on, focus = 3, aperture = 0.004, maxblur = 0.01) {
    this.bokeh.enabled = on && this.quality !== 'low';
    const u = this.bokeh.uniforms;
    u.focus.value = focus; u.aperture.value = aperture; u.maxblur.value = maxblur;
  }

  setGrade(name, instant = false) {
    this.gradeTarget = GRADES[name] || GRADES.lobby;
    if (instant) this.grade = JSON.parse(JSON.stringify(this.gradeTarget));
  }

  /** קובע ערך אפקט. אם speed ניתן – מתקרב אליו בהדרגה */
  set(k, v, speed) { if (speed) this.fxTarget[k] = { v, speed }; else { this.fx[k] = v; delete this.fxTarget[k]; } }

  resize() {
    const w = window.innerWidth, h = window.innerHeight;
    this.camera.aspect = w / h; this.camera.updateProjectionMatrix();
    const pr = Math.min(window.devicePixelRatio, 1.5) * this.pixelScale;
    this.renderer.setPixelRatio(pr);
    this.renderer.setSize(w, h);
    this.composer.setPixelRatio(pr);
    this.composer.setSize(w, h);
    this.cine.uniforms.uRes.value.set(w * pr, h * pr);
  }

  onUpdate(fn) { this.updaters.add(fn); return () => this.updaters.delete(fn); }

  _lerpGrade(dt) {
    const a = Math.min(1, dt * 1.2), g = this.grade, t = this.gradeTarget;
    for (const k in t) {
      if (Array.isArray(t[k])) { g[k] = g[k] || [...t[k]]; for (let i = 0; i < t[k].length; i++) g[k][i] += (t[k][i] - g[k][i]) * a; }
      else g[k] += (t[k] - g[k]) * a;
    }
    const u = this.cine.uniforms;
    u.uSat.value = g.sat; u.uContrast.value = g.contrast; u.uExposure.value = g.exposure;
    u.uLift.value.fromArray(g.lift); u.uGamma.value.fromArray(g.gamma); u.uGain.value.fromArray(g.gain);
    u.uShadowTint.value.fromArray(g.shadowTint); u.uHighTint.value.fromArray(g.highTint);
    u.uVignette.value = g.vignette; u.uGrain.value = this.postEnabled ? g.grain : 0; u.uCA.value = this.postEnabled ? g.ca : 0;
    this.bloom.strength = g.bloom[0] * (Settings.get('reduceFlash') ? 0.7 : 1); this.bloom.radius = g.bloom[1]; this.bloom.threshold = g.bloom[2];
  }

  _autoQuality(dt) {
    if (this.qualitySetting !== 'auto') return;
    this.fpsSamples.push(1 / Math.max(dt, 1e-4));
    if (this.fpsSamples.length < 120) return;
    const avg = this.fpsSamples.reduce((a, b) => a + b, 0) / this.fpsSamples.length;
    this.fpsSamples.length = 0;
    if (avg < 48 && this.quality !== 'low') { this.quality = this.quality === 'high' ? 'medium' : 'low'; this.setQuality('auto'); this.qualitySetting = 'auto'; }
    else if (avg > 70 && this.quality !== 'high' && this.pixelScale < 1) { this.quality = this.quality === 'low' ? 'medium' : 'high'; this.setQuality('auto'); this.qualitySetting = 'auto'; }
  }

  frame() {
    const dt = Math.min(this.clock.getDelta(), 0.1);
    this.time += dt;
    this.fps = this.fps ? this.fps * 0.95 + (1 / Math.max(dt, 1e-4)) * 0.05 : 60;
    for (const fn of this.updaters) fn(dt, this.time);
    for (const k in this.fxTarget) {
      const t = this.fxTarget[k]; const d = t.v - this.fx[k];
      const step = t.speed * dt;
      if (Math.abs(d) <= step) { this.fx[k] = t.v; delete this.fxTarget[k]; } else this.fx[k] += Math.sign(d) * step;
    }
    // הפחתת הבהובים: מגביל flash ושינויי בהירות (WCAG – פחות מ-3 הבהובים לשנייה, עוצמה נמוכה)
    const rf = Settings.get('reduceFlash');
    const u = this.cine.uniforms, f = this.fx;
    u.uTime.value = this.time;
    u.uRadialBlur.value = this.postEnabled ? f.radialBlur : 0;
    u.uTunnel.value = f.tunnel; u.uHit.value = f.hit; u.uFade.value = f.fade; u.uEyelid.value = f.eyelid;
    u.uBlur.value = f.blur; u.uFlash.value = rf ? Math.min(f.flash, 0.15) : f.flash; u.uDesat.value = f.desat;
    u.uLetterbox.value = f.letterbox; u.uBreath.value = f.breath;
    this._lerpGrade(dt);
    this._autoQuality(dt);
    if (this.postEnabled) this.composer.render(dt);
    else { this.renderer.setRenderTarget(null); this.renderer.render(this.scene, this.camera); }
    return dt;
  }
}
