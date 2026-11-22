-- ═══════════════════════════════════════════════════════════════════
--  Effects – תאורה ופוסט לכל פרק (Future, Atmosphere, ColorCorrection, Bloom, DOF, SunRays, Blur),
--  רעידות מצלמה (trauma), הבזק, טשטוש, פגיעה, מנהרת פחד – עם הגבלות "הפחתת הבהובים"
-- ═══════════════════════════════════════════════════════════════════
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))

local E = {}
E.Settings = nil -- מוזרק מ-UI
local function get(cls, name)
	local e = Lighting:FindFirstChild(name)
	if not e then e = Instance.new(cls); e.Name = name; e.Parent = Lighting end
	return e
end
local atmo = get("Atmosphere", "Atmo")
local cc = get("ColorCorrectionEffect", "Grade")
local fx = get("ColorCorrectionEffect", "Fx")
local bloom = get("BloomEffect", "Bloom")
local dof = get("DepthOfFieldEffect", "DOF")
local rays = get("SunRaysEffect", "Rays")
local blur = get("BlurEffect", "Blur")
local sky = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky", Lighting)
sky.StarCount = 3000
sky.CelestialBodiesShown = true
dof.Enabled = false
blur.Size = 0
bloom.Size = 36
E.Atmo, E.CC, E.Bloom, E.DOF, E.Rays, E.Blur = atmo, cc, bloom, dof, rays, blur

local function tw(o, t, p) local x = TweenService:Create(o, TweenInfo.new(t, Enum.EasingStyle.Sine), p); x:Play(); return x end
E.tw = tw

function E.Grade(name, t)
	local g = Config.Grades[name]
	if not g then return end
	t = t or 2
	Lighting.Technology = Enum.Technology.Future
	tw(Lighting, t, { ClockTime = g.Clock, Ambient = g.Ambient, OutdoorAmbient = g.Ambient, Brightness = g.Brightness, ExposureCompensation = g.Bright * 4 })
	tw(cc, t, { TintColor = g.Tint, Saturation = g.Sat, Contrast = g.Contrast, Brightness = g.Bright })
	tw(bloom, t, { Intensity = g.Bloom * (E.Settings and E.Settings.ReduceFlash and 0.6 or 1), Threshold = 0.92 })
	tw(atmo, t, { Color = g.AtmoColor, Decay = g.AtmoDecay, Density = g.Density, Haze = g.Haze, Glare = name == "Dawn" and 1.4 or 0.3 })
	rays.Intensity = (name == "Dawn" or name == "Home") and 0.12 or 0.02
	Lighting.EnvironmentDiffuseScale = name == "Tunnel" and 0.1 or 1
	Lighting.EnvironmentSpecularScale = name == "Tunnel" and 0.1 or 1
	Lighting.FogEnd = name == "Tunnel" and 140 or 100000
	Lighting.FogColor = Color3.new(0, 0, 0)
	E.Current = name
end

function E.SetDOF(on, focus, radius, near, far)
	dof.Enabled = on
	if on then dof.FocusDistance = focus or 8; dof.InFocusRadius = radius or 4; dof.NearIntensity = near or 0.5; dof.FarIntensity = far or 0.6 end
end
function E.BlurTo(s, t) return tw(blur, t or 0.5, { Size = s }) end
--- הבזק לבן (מוגבל בהפחתת הבהובים – WCAG)
function E.Flash(a, t)
	if E.Settings and E.Settings.ReduceFlash then a = math.min(a, 0.12) end
	fx.Brightness = a; fx.Contrast = -a * 0.5
	tw(fx, t or 0.6, { Brightness = 0, Contrast = 0 })
end
function E.Desat(a, t) tw(fx, t or 1, { Saturation = -a }) end
function E.Tint(c, t) tw(fx, t or 1, { TintColor = c }) end

-- ─────────────── רעידות מצלמה ───────────────
E.Trauma = 0
function E.Shake(a)
	if E.Settings and E.Settings.ReduceScare then a *= 0.5 end
	E.Trauma = math.min(1, E.Trauma + a)
end
local tt = 0
--- מחזיר CFrame היסט רעידה. נקרא כל פריים
function E.ShakeOffset(dt)
	E.Trauma = math.max(0, E.Trauma - dt * 0.9)
	tt += dt * 22
	local s = E.Trauma * E.Trauma
	if s <= 0.0001 then return CFrame.new() end
	local n = function(o) return math.noise(tt, o) end
	return CFrame.Angles(n(1) * 0.06 * s, n(2) * 0.06 * s, n(3) * 0.05 * s)
end

return E
