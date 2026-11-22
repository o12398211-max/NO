// Color grading לכל פרק – נגזר מ-docs/ART_DIRECTION.md
// lift/gamma/gain: [r,g,b]; sat, contrast; tint: צבע להטמעה בצללים/היילייטים
export const GRADES = {
  lobby:   { exposure: 1.0, sat: 0.9, contrast: 1.08, lift: [0.0, 0.0, 0.02], gamma: [1, 1, 1], gain: [1.0, 0.98, 0.96], shadowTint: [0.05, 0.06, 0.12], highTint: [1.0, 0.85, 0.7], vignette: 0.45, grain: 0.05, ca: 0.0015, bloom: [0.6, 0.6, 0.85] },
  party:   { exposure: 1.15, sat: 1.15, contrast: 1.1, lift: [0.0, 0.01, 0.03], gamma: [1.0, 1.0, 0.98], gain: [1.05, 0.98, 1.02], shadowTint: [0.0, 0.08, 0.12], highTint: [1.0, 0.75, 0.6], vignette: 0.42, grain: 0.04, ca: 0.0012, bloom: [0.75, 0.5, 0.86] },
  dawn:    { exposure: 1.0, sat: 0.7, contrast: 1.22, lift: [0.02, 0.015, 0.01], gamma: [1.0, 1.02, 1.05], gain: [1.06, 0.98, 0.92], shadowTint: [0.06, 0.05, 0.05], highTint: [1.0, 0.7, 0.5], vignette: 0.58, grain: 0.07, ca: 0.002, bloom: [0.5, 0.5, 0.85] },
  tunnel:  { exposure: 1.1, sat: 0.72, contrast: 1.25, lift: [-0.01, -0.005, 0.0], gamma: [1.02, 1.0, 1.0], gain: [1.0, 1.0, 0.95], shadowTint: [0.02, 0.04, 0.05], highTint: [1.0, 0.85, 0.65], vignette: 0.65, grain: 0.11, ca: 0.0025, bloom: [0.55, 0.45, 0.8] },
  outside: { exposure: 1.0, sat: 0.78, contrast: 1.12, lift: [0.01, 0.015, 0.025], gamma: [1.0, 1.0, 1.0], gain: [0.98, 1.0, 1.04], shadowTint: [0.04, 0.06, 0.09], highTint: [1.0, 0.86, 0.72], vignette: 0.5, grain: 0.06, ca: 0.0015, bloom: [0.5, 0.5, 0.85] },
  plane:   { exposure: 1.0, sat: 0.82, contrast: 1.12, lift: [0.0, 0.01, 0.02], gamma: [1, 1, 1], gain: [0.97, 1.0, 1.04], shadowTint: [0.03, 0.05, 0.08], highTint: [0.95, 0.97, 1.0], vignette: 0.55, grain: 0.05, ca: 0.0015, bloom: [0.45, 0.4, 0.85] },
  home:    { exposure: 1.05, sat: 1.05, contrast: 1.05, lift: [0.01, 0.01, 0.0], gamma: [1, 1, 1], gain: [1.05, 1.02, 0.95], shadowTint: [0.04, 0.05, 0.08], highTint: [1.0, 0.9, 0.7], vignette: 0.35, grain: 0.035, ca: 0.0008, bloom: [0.6, 0.6, 0.8] },
  memorial:{ exposure: 1.0, sat: 0.85, contrast: 1.1, lift: [0.0, 0.0, 0.03], gamma: [1, 1, 1], gain: [1.06, 0.98, 0.9], shadowTint: [0.03, 0.04, 0.1], highTint: [1.0, 0.75, 0.45], vignette: 0.55, grain: 0.05, ca: 0.001, bloom: [0.85, 0.6, 0.6] },
};
