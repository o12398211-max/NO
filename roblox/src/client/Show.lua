-- ═══════════════════════════════════════════════════════════════════
--  Show – מופע הבמה במסיבה (מסונכרן לכל השחקנים לפי זמן השרת):
--  קיר LED מונפש (מנדלה, גלים, פסי EQ), ראשים נעים עם קרני אור, לייזרים, ובכל "דרופ":
--  זיקוקים, קונפטי, להבות, עמודי CO2, והקהל צוהל יחד. כולל אירועי אדמין (דיסקו, זיקוקים, החשכה)
-- ═══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))
local Audio = require(script.Parent.Audio)
local Effects = require(script.Parent.Effects)
local UI = require(script.Parent.UI)

local Show = {}
local conn
local BPM = 142
Show.Intensity = 1
Show.Disco = 0

local function now() return workspace:GetServerTimeNow() end

local function hsv(h, s, v) return Color3.fromHSV(h % 1, s, v) end

--- זיקוק בשמיים
function Show.Firework(pos, color)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Size = Vector3.one; p.Position = pos; p.Parent = workspace
	local att = Instance.new("Attachment", p)
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Color = ColorSequence.new(color or hsv(math.random(), 0.8, 1))
	pe.LightEmission = 1; pe.LightInfluence = 0
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) })
	pe.Speed = NumberRange.new(45, 70); pe.SpreadAngle = Vector2.new(180, 180); pe.Lifetime = NumberRange.new(1.2, 2.0)
	pe.Drag = 2.5; pe.Acceleration = Vector3.new(0, -18, 0); pe.Rate = 0; pe.Parent = att
	local l = Instance.new("PointLight"); l.Color = pe.Color.Keypoints[1].Value; l.Range = 80; l.Brightness = UI.Settings.ReduceFlash and 1 or 6; l.Parent = p
	pe:Emit(160)
	TweenService:Create(l, TweenInfo.new(1.2), { Brightness = 0 }):Play()
	Audio.Play(Config.Sfx.BoomFar, { pos = pos, vol = 0.6, speed = 1.4, minDist = 80, maxDist = 1500 })
	Debris:AddItem(p, 4)
end

--- תותח קונפטי / CO2 / להבה מנקודה
function Show.Burst(pos, kind)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Size = Vector3.one; p.Position = pos; p.Parent = workspace
	local att = Instance.new("Attachment", p)
	local pe = Instance.new("ParticleEmitter")
	if kind == "confetti" then
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 46, 136)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(25, 227, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 210, 90)) })
		pe.Size = NumberSequence.new(0.5); pe.Speed = NumberRange.new(60, 90); pe.SpreadAngle = Vector2.new(25, 25)
		pe.Lifetime = NumberRange.new(4, 6); pe.Acceleration = Vector3.new(0, -8, 0); pe.Drag = 1.5; pe.RotSpeed = NumberRange.new(-200, 200)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Rate = 0; pe.Parent = att; pe:Emit(220)
	elseif kind == "co2" then
		pe.Texture = "rbxasset://textures/particles/smoke_main.dds"
		pe.Color = ColorSequence.new(Color3.fromRGB(240, 240, 255)); pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) })
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2), NumberSequenceKeypoint.new(1, 14) }); pe.Speed = NumberRange.new(70, 90); pe.SpreadAngle = Vector2.new(6, 6)
		pe.Lifetime = NumberRange.new(1.2, 1.8); pe.Drag = 3; pe.EmissionDirection = Enum.NormalId.Top; pe.Rate = 160; pe.Parent = att
		task.delay(1.4, function() pe.Enabled = false end)
		Audio.Play(Config.Sfx.FallWind, { pos = pos, vol = 0.4, speed = 2, life = 3 })
	else -- flame
		local f = Instance.new("Fire"); f.Size = 18; f.Heat = 25; f.Color = Color3.fromRGB(255, 140, 40); f.SecondaryColor = Color3.fromRGB(255, 60, 10); f.Parent = p
		local l = Instance.new("PointLight"); l.Color = Color3.fromRGB(255, 140, 50); l.Range = 50; l.Brightness = UI.Settings.ReduceFlash and 1 or 4; l.Parent = p
		task.delay(1.0, function() f.Enabled = false; l.Enabled = false end)
	end
	Debris:AddItem(p, 8)
end

--- מפעיל את המופע. payload: led (Model), heads (Folder), lasers (Folder), stage (Vector3)
function Show.Start(payload)
	Show.Stop()
	local led = payload.led
	local pixels = {}
	if led then for _, p in ipairs(led:GetChildren()) do local x, y = p.Name:match("(%d+)_(%d+)"); if x then table.insert(pixels, { p = p, x = tonumber(x), y = tonumber(y) }) end end end
	local heads = {}
	if payload.heads then for _, h in ipairs(payload.heads:GetChildren()) do if h.Name:match("^Head") then local i = tonumber(h.Name:match("%d+")); heads[i] = { h = h, base = h.CFrame, tgt = payload.heads:FindFirstChild("Target" .. i), phase = h:GetAttribute("Phase") or i } end end end
	local lasers = {}
	if payload.lasers then for _, t in ipairs(payload.lasers:GetChildren()) do if t.Name:match("^T") then table.insert(lasers, { t = t, base = t.Position, i = tonumber(t.Name:match("%d+")) }) end end end
	local stage = payload.stage
	local lastDrop = -1
	local acc = 0
	local cheerTargets = payload.crowd
	conn = RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 / 30 then return end
		acc = 0
		local t = now()
		local beat = t * BPM / 60
		local bar = math.floor(beat / 4)
		local section = math.floor(bar / 8) % 4 -- build / drop / break / drop
		local inten = Show.Intensity
		local pulse = math.max(0, math.sin(beat * math.pi)) ^ 6
		-- קיר LED: מצבים מתחלפים לפי חלק בשיר
		local mode = (bar % 16 < 8) and 1 or 2
		if Show.Disco > 0 then mode = 3 end
		for _, px in ipairs(pixels) do
			local cx, cy = px.x - 11.5, px.y - 5
			local c
			if inten < 0.3 then c = hsv(0.75, 0.6, 0.12 + 0.05 * math.sin(t + px.x * 0.3))
			elseif mode == 1 then -- מנדלה רדיאלית
				local r = math.sqrt(cx * cx + cy * cy * 2.2)
				local a = math.atan2(cy, cx)
				c = hsv(t * 0.08 + r * 0.05, 0.85, math.clamp(0.55 + 0.45 * math.sin(r * 1.1 - t * 4 + math.sin(a * 6 + t) * 1.5) + pulse * 0.4, 0, 1))
			elseif mode == 2 then -- גלים + EQ
				local h = (math.sin(px.x * 0.6 + beat * math.pi) * 0.5 + 0.5) * 10 * (0.4 + 0.6 * math.abs(math.sin(beat * 0.5 + px.x)))
				c = px.y < h and hsv(0.5 + px.y * 0.03, 0.9, 1) or hsv(0.8, 0.8, 0.08 + pulse * 0.2)
			else -- דיסקו
				c = hsv(math.random(), 1, math.random() < 0.5 and 1 or 0.1)
			end
			px.p.Color = c
		end
		-- ראשים נעים
		for _, hd in pairs(heads) do
			local a = t * 0.7 + hd.phase
			if hd.tgt then hd.tgt.Position = stage + Vector3.new(math.sin(a) * 70, 0.3, 60 + math.cos(a * 0.8) * 40) end
			local beam = hd.h:FindFirstChildOfClass("Attachment") and hd.h:FindFirstChildOfClass("Beam")
			if beam then
				beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, math.clamp(0.75 - pulse * 0.35 - inten * 0.15, 0, 1)), NumberSequenceKeypoint.new(1, 1) })
				if Show.Disco > 0 then beam.Color = ColorSequence.new(hsv(t * 0.5 + hd.phase, 1, 1)) end
			end
		end
		-- לייזרים: מופיעים בחלקי הדרופ
		local lasersOn = inten > 0.5 and (section == 1 or section == 3 or Show.Disco > 0)
		for _, L in ipairs(lasers) do
			L.t.Position = L.base + Vector3.new(math.sin(t * 0.9 + L.i) * 120, math.sin(t * 0.6 + L.i * 0.7) * 40, 0)
			local b = L.t:FindFirstChildOfClass("Attachment")
			for _, bm in ipairs(L.t.Parent:GetDescendants()) do
				if bm:IsA("Beam") and bm.Attachment1 == b then bm.Enabled = lasersOn end
			end
		end
		-- "דרופ": זיקוקים, קונפטי, להבות, CO2 – פעם בכל תחילת חלק דרופ
		local dropId = math.floor(bar / 8)
		if (section == 1 or section == 3) and dropId ~= lastDrop and inten > 0.5 then
			lastDrop = dropId
			Show.Drop(stage)
		end
		if Show.Disco > 0 then Show.Disco -= 1 / 30 end
	end)
end

function Show.Drop(stage)
	for i = -2, 2 do Show.Burst(stage + Vector3.new(i * 9, 4, 14), "co2") end
	task.delay(0.4, function() for _, x in ipairs({ -22, 22 }) do Show.Burst(stage + Vector3.new(x, 6, 10), "flame") end end)
	task.delay(0.8, function() for _, x in ipairs({ -14, 0, 14 }) do Show.Burst(stage + Vector3.new(x, 25, 6), "confetti") end end)
	for i = 1, 7 do task.delay(1 + i * 0.35, function() Show.Firework(stage + Vector3.new(math.random(-90, 90), 110 + math.random(0, 50), math.random(-60, 20))) end) end
	Audio.Play(Config.Sfx.CrowdParty, { vol = 0.5, life = 8 })
	if Show.OnDrop then Show.OnDrop() end
end

function Show.Stop() if conn then conn:Disconnect(); conn = nil end end

return Show
