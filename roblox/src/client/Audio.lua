-- ═══════════════════════════════════════════════════════════════════
--  Audio – סאונד דיזיין: קבוצות (מוזיקה/אפקטים/אמביינט/גוף), קול תלת־ממדי, מוזיקה דינמית
--  עם קרוספייד, צעדים לפי משטח, נשימה/דופק/צלצול באוזניים, הד לפי מרחב, עמעום (Muffle)
-- ═══════════════════════════════════════════════════════════════════
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))

local A = {}
local plr = Players.LocalPlayer
local groups = {}
for _, n in ipairs({ "Music", "Sfx", "Amb", "Body" }) do
	local g = Instance.new("SoundGroup"); g.Name = n; g.Volume = 1; g.Parent = SoundService; groups[n] = g
end
local eq = Instance.new("EqualizerSoundEffect"); eq.HighGain = 0; eq.MidGain = 0; eq.LowGain = 0; eq.Priority = 1; eq.Parent = groups.Sfx
local eq2 = eq:Clone(); eq2.Parent = groups.Amb
local eq3 = eq:Clone(); eq3.Parent = groups.Music
local reverb = Instance.new("ReverbSoundEffect"); reverb.DecayTime = 1.5; reverb.Density = 1; reverb.Diffusion = 1; reverb.DryLevel = 0; reverb.WetLevel = -14; reverb.Parent = groups.Sfx
A.Groups = groups

local function pick(v) if typeof(v) == "table" then return v[math.random(1, #v)] end return v end
local anchor = Instance.new("Part")
anchor.Anchored = true; anchor.CanCollide = false; anchor.Transparency = 1; anchor.Size = Vector3.one; anchor.Name = "SoundAnchor"
anchor.Parent = workspace

function A.SetVolumes(music, sfx)
	groups.Music.Volume = music
	groups.Sfx.Volume = sfx
	groups.Amb.Volume = sfx
end

--- אפקט חד־פעמי. opts: pos (Vector3), vol, speed, group, maxDist, delay
function A.Play(id, opts)
	opts = opts or {}
	id = pick(id)
	if not id then return end
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = opts.vol or 0.8
	s.PlaybackSpeed = (opts.speed or 1) * (opts.vary and (1 + (math.random() - 0.5) * opts.vary) or 1)
	s.SoundGroup = groups[opts.group or "Sfx"]
	if opts.pos then
		local a = Instance.new("Attachment"); a.WorldPosition = opts.pos; a.Parent = workspace.Terrain
		s.RollOffMode = Enum.RollOffMode.InverseTapered
		s.RollOffMinDistance = opts.minDist or 10
		s.RollOffMaxDistance = opts.maxDist or 400
		s.Parent = a
		task.delay((opts.life or 12) + (opts.delay or 0), function() a:Destroy() end)
	else
		s.Parent = SoundService
		task.delay((opts.life or 12) + (opts.delay or 0), function() s:Destroy() end)
	end
	if opts.delay then task.delay(opts.delay, function() s:Play() end) else s:Play() end
	return s
end

--- לופ מתמשך עם שליטה
function A.Loop(id, opts)
	opts = opts or {}
	local s = Instance.new("Sound")
	s.SoundId = pick(id); s.Looped = true; s.Volume = 0
	s.SoundGroup = groups[opts.group or "Amb"]
	s.PlaybackSpeed = opts.speed or 1
	if opts.pos then
		local a = Instance.new("Attachment"); a.WorldPosition = opts.pos; a.Parent = workspace.Terrain
		s.RollOffMode = Enum.RollOffMode.InverseTapered; s.RollOffMinDistance = opts.minDist or 30; s.RollOffMaxDistance = opts.maxDist or 600
		s.Parent = a
	else s.Parent = SoundService end
	s:Play()
	TweenService:Create(s, TweenInfo.new(opts.fade or 1), { Volume = opts.vol or 0.6 }):Play()
	local h = { Sound = s }
	function h:SetVol(v, t) TweenService:Create(s, TweenInfo.new(t or 0.5), { Volume = v }):Play() end
	function h:Stop(t)
		TweenService:Create(s, TweenInfo.new(t or 1), { Volume = 0 }):Play()
		task.delay((t or 1) + 0.1, function() if s.Parent and s.Parent:IsA("Attachment") then s.Parent:Destroy() else s:Destroy() end end)
	end
	A._loops = A._loops or {}
	table.insert(A._loops, h)
	return h
end
function A.StopAll(t)
	for _, h in ipairs(A._loops or {}) do pcall(function() h:Stop(t or 1) end) end
	A._loops = {}
end

-- ─────────────── מוזיקה דינמית (קרוספייד בין רצועות) ───────────────
local music = { current = nil, sound = nil }
function A.Music(key, vol, fade)
	if music.current == key then if music.sound and vol then TweenService:Create(music.sound, TweenInfo.new(1), { Volume = vol }):Play() end return end
	local old = music.sound
	if old then
		TweenService:Create(old, TweenInfo.new(fade or 2), { Volume = 0 }):Play()
		task.delay((fade or 2) + 0.1, function() old:Destroy() end)
	end
	music.current = key
	music.sound = nil
	if not key or not Config.Music[key] then return end
	local s = Instance.new("Sound")
	s.SoundId = Config.Music[key]; s.Looped = true; s.Volume = 0; s.SoundGroup = groups.Music; s.Parent = SoundService
	s:Play()
	TweenService:Create(s, TweenInfo.new(fade or 2), { Volume = vol or 0.5 }):Play()
	music.sound = s
end
function A.MusicVolume(v, t) if music.sound then TweenService:Create(music.sound, TweenInfo.new(t or 1), { Volume = v }):Play() end end
--- מוזיקה "דיאגטית" – יוצאת מהרמקולים בבמה
function A.MusicAt(pos, on)
	if not music.sound then return end
	if on then
		local a = workspace.Terrain:FindFirstChild("MusicAnchor") or Instance.new("Attachment")
		a.Name = "MusicAnchor"; a.WorldPosition = pos; a.Parent = workspace.Terrain
		music.sound.RollOffMode = Enum.RollOffMode.InverseTapered; music.sound.RollOffMinDistance = 80; music.sound.RollOffMaxDistance = 900
		music.sound.Parent = a
	else
		music.sound.Parent = SoundService
	end
end

-- ─────────────── מרחב/עמעום ───────────────
function A.Space(kind)
	local t = { open = { 1.5, -18 }, field = { 2.8, -16 }, tunnel = { 4.5, -4 }, cabin = { 0.6, -14 }, small = { 0.4, -12 } }
	local v = t[kind] or t.open
	reverb.DecayTime = v[1]; reverb.WetLevel = v[2]
end
function A.Muffle(a, t)
	for _, e in ipairs({ eq, eq2, eq3 }) do
		TweenService:Create(e, TweenInfo.new(t or 0.3), { HighGain = -40 * a, MidGain = -15 * a }):Play()
	end
end

-- ─────────────── ירי ───────────────
function A.Gunshot(pos, near)
	local cam = workspace.CurrentCamera
	local d = (cam.CFrame.Position - pos).Magnitude
	if d < 110 then A.Play(Config.Sfx.Rifle, { pos = pos, vol = near and 1 or 0.85, vary = 0.08, minDist = 20, maxDist = 700 })
	else A.Play(Config.Sfx.GunFar, { pos = pos, vol = 1, vary = 0.1, minDist = 60, maxDist = 2000 }) end
end

-- ─────────────── גוף: נשימה, דופק, צלצול ───────────────
local body = { breath = 0, heart = 0, ring = 0 }
local breathS, breath2S, heartS, ringS
function A.InitBody()
	breathS = Instance.new("Sound"); breathS.SoundId = Config.Sfx.Breath; breathS.Looped = true; breathS.Volume = 0; breathS.SoundGroup = groups.Body; breathS.Parent = SoundService; breathS:Play()
	breath2S = Instance.new("Sound"); breath2S.SoundId = Config.Sfx.Breath2; breath2S.Looped = true; breath2S.Volume = 0; breath2S.SoundGroup = groups.Body; breath2S.Parent = SoundService; breath2S:Play()
	heartS = Instance.new("Sound"); heartS.SoundId = Config.Sfx.Heart; heartS.Looped = true; heartS.Volume = 0; heartS.SoundGroup = groups.Body; heartS.Parent = SoundService; heartS:Play()
	ringS = Instance.new("Sound"); ringS.SoundId = Config.Sfx.Ring; ringS.Looped = true; ringS.Volume = 0; ringS.SoundGroup = groups.Body; ringS.Parent = SoundService; ringS:Play()
end
function A.Ring(a) body.ring = math.min(1, body.ring + a) end
--- breath 0..1, heart 0..1 – נקרא כל פריים
function A.Body(dt, breath, heart, scareReduced)
	if not breathS then return end
	body.breath += (breath - body.breath) * math.min(1, dt * 2)
	body.heart += (heart - body.heart) * math.min(1, dt * 1.5)
	body.ring = math.max(0, body.ring - dt * 0.12)
	breathS.Volume = math.clamp((body.breath - 0.15) * 0.9, 0, 0.7)
	breathS.PlaybackSpeed = 0.9 + body.breath * 0.25
	breath2S.Volume = math.clamp((body.breath - 0.6) * 1.2, 0, 0.5)
	heartS.Volume = math.clamp(body.heart * 0.9, 0, 0.9)
	heartS.PlaybackSpeed = 0.9 + body.heart * 0.7
	ringS.Volume = body.ring * (scareReduced and 0.15 or 0.4)
end

-- ─────────────── צעדים לפי משטח ───────────────
local stepMap = {
	[Enum.Material.Sand] = "Dirt", [Enum.Material.Ground] = "Dirt", [Enum.Material.Grass] = "Dirt", [Enum.Material.LeafyGrass] = "Dirt", [Enum.Material.Mud] = "Dirt",
	[Enum.Material.Rock] = "Gravel", [Enum.Material.Slate] = "Gravel", [Enum.Material.Pebble] = "Gravel", [Enum.Material.Basalt] = "Gravel",
	[Enum.Material.Concrete] = "Concrete", [Enum.Material.Marble] = "Concrete", [Enum.Material.Asphalt] = "Concrete", [Enum.Material.Brick] = "Concrete", [Enum.Material.WoodPlanks] = "Concrete", [Enum.Material.Wood] = "Concrete",
	[Enum.Material.Water] = "Water", [Enum.Material.Fabric] = "Carpet", [Enum.Material.Carpet] = "Carpet",
	[Enum.Material.Metal] = "Metal", [Enum.Material.DiamondPlate] = "Metal", [Enum.Material.CorrodedMetal] = "Metal",
}
function A.Footstep(material, intensity)
	local k = stepMap[material] or "Dirt"
	A.Play(Config.Sfx.Step[k], { vol = 0.25 + 0.45 * (intensity or 0.5), vary = 0.1, group = "Sfx", life = 3 })
end

-- מוזיקה מקומית בכל מצב
A.InitBody()
return A
