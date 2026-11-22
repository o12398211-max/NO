-- ═══════════════════════════════════════════════════════════════════
--  פרק 2 – הבוקר, הבריחה והתפיסה (לקוח). אין טקסט על המסך בזמן הבריחה והתפיסה.
--  התעוררות → המון נמלט → שחר נעלמת → חפירה בחול ואקדח → 3 מחבלים → האקדח עף →
--  חלון בריחה מוגן (תחושת "הצלחתי") → תפיסה מבהילה לפי המסלול (רגלית / רכב / מסתור)
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Shared.Texts)
local Config = require(RS.Shared.Config)
local Ctl = script.Parent.Parent
local UI = require(Ctl.UI)
local Audio = require(Ctl.Audio)
local Effects = require(Ctl.Effects)
local Cinematic = require(Ctl.Cinematic)
local FP = require(Ctl.FirstPerson)
local Crowd = require(Ctl.Crowd)

local Ch = {}
local plr = Players.LocalPlayer
local R, P
local conns = {}
local state = {}
local gunModel
local scared = function() return not UI.Settings.ReduceScare end

local function hrp() local c = plr.Character; return c and c:FindFirstChild("HumanoidRootPart") end

-- ─────────────── רקטות ויירוטים בשמיים ───────────────
local function rocket(from, to, dur, intercept)
	local p = Instance.new("Part")
	p.Anchored = true; p.CanCollide = false; p.Size = Vector3.new(0.6, 0.6, 2); p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 210, 140)
	p.CFrame = CFrame.lookAt(from, to); p.Parent = workspace
	local a0 = Instance.new("Attachment", p); a0.Position = Vector3.new(0, 0.3, 1)
	local a1 = Instance.new("Attachment", p); a1.Position = Vector3.new(0, -0.3, 1)
	local tr = Instance.new("Trail"); tr.Attachment0 = a0; tr.Attachment1 = a1; tr.Lifetime = 8; tr.Color = ColorSequence.new(Color3.fromRGB(235, 228, 218)); tr.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }); tr.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 4) }); tr.LightEmission = 0.3; tr.Parent = p
	local t = 0
	local c
	c = RunService.Heartbeat:Connect(function(dt)
		t += dt
		local k = math.min(1, t / dur)
		local pos = from:Lerp(to, k) + Vector3.new(0, math.sin(k * math.pi) * (to.Y - from.Y) * 0.35, 0)
		p.CFrame = CFrame.lookAt(pos, pos + (to - from).Unit)
		if k >= 1 then
			c:Disconnect()
			p.Transparency = 1
			if intercept then
				local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(220, 214, 205)); pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 6), NumberSequenceKeypoint.new(1, 20) }); pe.Speed = NumberRange.new(10, 30); pe.SpreadAngle = Vector2.new(180, 180); pe.Lifetime = NumberRange.new(6, 10); pe.Drag = 1; pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }); pe.Rate = 0; pe.Parent = a0; pe:Emit(30)
				local l = Instance.new("PointLight"); l.Range = 200; l.Brightness = UI.Settings.ReduceFlash and 1 or 8; l.Color = Color3.fromRGB(255, 220, 160); l.Parent = p
				TweenService:Create(l, TweenInfo.new(0.6), { Brightness = 0 }):Play()
				task.delay((p.Position - workspace.CurrentCamera.CFrame.Position).Magnitude / 1100, function() Audio.Play(Config.Sfx.BoomFar, { vol = 0.9, pos = pos, minDist = 200, maxDist = 4000 }) end)
			end
			Debris:AddItem(p, 12)
		end
	end)
end
local function rocketSalvo(n)
	local o = P.origin
	for i = 1, n do
		task.delay(i * 0.9, function()
			rocket(o + Vector3.new(-900 + math.random(-80, 80), 10, math.random(-300, 300)), o + Vector3.new(math.random(-200, 300), 380 + math.random(0, 120), math.random(-200, 300)), 5 + math.random() * 2, math.random() < 0.85)
		end)
	end
end

-- ─────────────── אפקטי ירי מהשרת ───────────────
local function dustAt(pos)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Transparency = 1; p.Size = Vector3.one; p.Position = pos; p.Parent = workspace
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(181, 156, 120)); pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 3) }); pe.Speed = NumberRange.new(6, 14); pe.SpreadAngle = Vector2.new(35, 35); pe.EmissionDirection = Enum.NormalId.Top; pe.Lifetime = NumberRange.new(0.8, 1.6); pe.Acceleration = Vector3.new(0, -10, 0); pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }); pe.Rate = 0; pe.Parent = p
	pe:Emit(10)
	Debris:AddItem(p, 3)
end
local function muzzle(pos)
	local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 192, 112); p.Size = Vector3.new(0.6, 0.6, 0.6); p.Shape = Enum.PartType.Ball; p.Position = pos; p.Parent = workspace
	local l = Instance.new("PointLight"); l.Range = 22; l.Brightness = 5; l.Color = p.Color; l.Parent = p
	Debris:AddItem(p, 0.06)
end
function Ch.OnFx(kind, a, b, c)
	if kind == "burst" then
		local from, to, n = a, b, c
		for i = 1, n do
			task.delay(i * 0.09 + math.random() * 0.03, function()
				muzzle(from)
				Audio.Gunshot(from, false)
				local root = hrp()
				local hit = to + Vector3.new(math.random(-20, 20) / 10, 0, math.random(-20, 20) / 10)
				local rp = RaycastParams.new(); rp.FilterType = Enum.RaycastFilterType.Include; rp.FilterDescendantsInstances = { workspace.Terrain }
				local r = workspace:Raycast(hit + Vector3.new(0, 30, 0), Vector3.new(0, -80, 0), rp)
				if r then hit = r.Position end
				if root and (hit - root.Position).Magnitude < 40 then
					dustAt(hit)
					Audio.Play(Config.Sfx.Impact, { pos = hit, vol = 0.8 })
					if math.random() < 0.35 then Audio.Play(Config.Sfx.Ricochet, { pos = hit, vol = 0.7 }) end
					local d = (hit - root.Position).Magnitude
					Effects.Shake(math.clamp(0.25 - d / 160, 0.03, 0.25))
					if d < 8 then Audio.Ring(0.15) end
				end
			end)
		end
	elseif kind == "pshot" then
		local from, to, uid = a, b, c
		Audio.Play(Config.Sfx.Pistol, { pos = from, vol = 1, minDist = 20 })
		dustAt(to)
		if uid == plr.UserId then Effects.Shake(0.18); Effects.Flash(0.12, 0.15) end
	elseif kind == "down" then
		Audio.Play(Config.Sfx.BodyFall, { pos = a and a:FindFirstChild("HumanoidRootPart") and a.HumanoidRootPart.Position, vol = 0.8 })
	end
end

-- ─────────────── התעוררות ───────────────
local function wake()
	local cam = workspace.CurrentCamera
	FP.SetEnabled(false)
	Cinematic.Take()
	UI.FadeTo(1, 0)
	UI.Eyelid(1, 0)
	Effects.BlurTo(24, 0)
	local spot = P.sleep
	cam.CFrame = CFrame.lookAt(spot + Vector3.new(0, 0.8, 0), spot + Vector3.new(0, 6, -0.5))
	task.wait(0.8)
	state.siren = Audio.Loop(Config.Sfx.Siren, { vol = scared() and 0.9 or 0.5, pos = P.origin + Vector3.new(-80, 40, 100), minDist = 300, maxDist = 3000, group = "Sfx" })
	Audio.Play(Config.Sfx.BoomFar, { vol = 0.9, delay = 0.3 })
	UI.FadeTo(0, 1.2)
	UI.Eyelid(0.75, 0.9)
	FP.Fear = 0.7; FP.BreathOverride = 0.6
	task.wait(1.2)
	UI.Bark("", T.CH2.Alarm, 2600)
	UI.Eyelid(0.95, 2); task.wait(0.5); UI.Eyelid(0.3, 0.8); task.wait(1)
	UI.Bark("yoni", T.CH2.Yoni1, 2200)
	UI.Eyelid(0, 1.2); Effects.BlurTo(6, 1)
	task.wait(1.4)
	rocketSalvo(6)
	-- קימה
	Cinematic.MoveTo(CFrame.lookAt(spot + Vector3.new(0, 4.5, 0), spot + Vector3.new(0, 4, -12)), 1.6, "inOut")
	Effects.BlurTo(0, 0.4)
	UI.Bark("maya", T.CH2.Maya1, 2200)
	Audio.Play(Config.Sfx.Boom, { vol = scared() and 0.8 or 0.4, delay = 0.6 })
	task.delay(0.7, function() Effects.Shake(0.5); Audio.Ring(0.4) end)
	task.wait(2.2)
	UI.Bark("yoni", T.CH2.Yoni2, 2600)
	task.wait(2.6)
	FP.BreathOverride = nil
	Cinematic.Release()
	FP.SetEnabled(true)
end

-- ─────────────── שחר מרחוק נבלעת בהמון ───────────────
local function seeShachar()
	local tmpl = RS:FindFirstChild("Templates") and RS.Templates:FindFirstChild("Shachar")
	local root = hrp()
	if not tmpl or not root then return end
	local m = tmpl:Clone(); m:SetAttribute("Local", true); m:SetAttribute("NPC", true); m.HumanoidRootPart.Anchored = true
	local fwd = root.CFrame.LookVector
	local pos = root.Position + fwd * 120 + root.CFrame.RightVector * -30
	m:PivotTo(CFrame.lookAt(pos, root.Position)); m.Parent = workspace
	local an = m.Humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", m.Humanoid)
	local a = Instance.new("Animation"); a.AnimationId = Config.Anim.Wave
	task.wait(1.8)
	local tr = an:LoadAnimation(a); tr:Play()
	UI.Bark("shachar", T.CH2.ShacharFar, 1600)
	task.wait(1.6)
	local run = Instance.new("Animation"); run.AnimationId = Config.Anim.Run
	tr:Stop(); local rt = an:LoadAnimation(run); rt.Looped = true; rt:Play()
	local t0 = os.clock()
	while os.clock() - t0 < 2.4 do
		local dt = RunService.Heartbeat:Wait()
		m:PivotTo(m:GetPivot() * CFrame.new(0, 0, -20 * dt) * CFrame.Angles(0, dt * 0.6, 0))
	end
	m:Destroy()
end

-- ─────────────── חפירה בחול: האקדח ───────────────
local function digForGun()
	local root = hrp()
	if not root then return end
	FP.LockMove(true)
	FP.SetEnabled(false)
	Cinematic.Take()
	local cam = workspace.CurrentCamera
	-- מעידה ונפילה לחול
	local base = root.CFrame
	Audio.Play(Config.Sfx.BodyFall, { vol = 0.9 })
	Effects.Shake(0.6)
	Cinematic.MoveTo(base * CFrame.new(0, -1.6, -1.2) * CFrame.Angles(math.rad(-70), 0, math.rad(8)), 0.35, "inn")
	task.wait(0.5)
	-- הידיים חופרות (גוף ראשון, מבט למטה), חול עף
	local groundPos = (base * CFrame.new(0, -3, -3.2)).Position
	local sand = Instance.new("Part"); sand.Anchored = true; sand.CanCollide = false; sand.Transparency = 1; sand.Size = Vector3.one; sand.Position = groundPos; sand.Parent = workspace
	local pe = Instance.new("ParticleEmitter"); pe.Texture = "rbxasset://textures/particles/smoke_main.dds"; pe.Color = ColorSequence.new(Color3.fromRGB(196, 170, 130)); pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1.6) }); pe.Speed = NumberRange.new(5, 12); pe.SpreadAngle = Vector2.new(50, 50); pe.EmissionDirection = Enum.NormalId.Top; pe.Acceleration = Vector3.new(0, -25, 0); pe.Lifetime = NumberRange.new(0.6, 1.1); pe.Rate = 0; pe.Parent = sand
	local char = plr.Character
	local la, ra = char:FindFirstChild("LeftHand"), char:FindFirstChild("RightHand")
	Cinematic.MoveTo(CFrame.lookAt(base.Position + Vector3.new(0, -0.6, 0) + base.LookVector * 0.6, groundPos), 0.6, "inOut", 60)
	for i = 1, 6 do
		pe:Emit(14)
		Audio.Play(Config.Sfx.Step.Dirt, { vol = 0.7, speed = 0.8 + math.random() * 0.3 })
		Effects.Shake(0.05)
		task.wait(0.32)
	end
	-- מתגלה אקדח
	local gun = Instance.new("Model"); gun.Name = "SandGun"
	local function gp(size, off) local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Size = size; p.Color = Color3.fromRGB(28, 29, 31); p.Material = Enum.Material.Metal; p.CFrame = CFrame.new(groundPos + Vector3.new(0, 0.15, 0)) * off; p.Parent = gun; return p end
	gp(Vector3.new(0.35, 0.3, 1.2), CFrame.Angles(0, math.rad(30), 0))
	gp(Vector3.new(0.3, 0.7, 0.35), CFrame.Angles(0, math.rad(30), 0) * CFrame.new(0, -0.3, 0.4) * CFrame.Angles(math.rad(-15), 0, 0))
	gun.Parent = workspace
	Audio.Play(Config.Sfx.Stinger2, { vol = 0.35 })
	Effects.SetDOF(true, 3, 1.5, 0.4, 0.8)
	Cinematic.MoveTo(CFrame.lookAt(groundPos + Vector3.new(0.6, 1.6, 1.2), groundPos), 0.9, "inOut", 40)
	task.wait(1.0)
	Audio.Play(Config.Sfx.Cloth, { vol = 0.7 })
	gun:Destroy()
	Effects.SetDOF(false)
	-- קימה עם האקדח
	Cinematic.MoveTo(base, 0.7, "inOut", 72)
	sand:Destroy()
	Cinematic.Release()
	FP.SetEnabled(true)
	FP.LockMove(false)
	-- אקדח ביד (מקומי) + כוונת
	gunModel = Instance.new("Part")
	gunModel.Name = "HeldPistol"; gunModel.Size = Vector3.new(0.3, 0.35, 1.1); gunModel.Color = Color3.fromRGB(28, 29, 31); gunModel.Material = Enum.Material.Metal; gunModel.CanCollide = false; gunModel.Massless = true
	if ra then gunModel.CFrame = ra.CFrame * CFrame.new(0, -0.3, -0.5); local w = Instance.new("WeldConstraint"); w.Part0 = ra; w.Part1 = gunModel; w.Parent = gunModel end
	gunModel.Parent = char
	state.armed = true
	state.cross = UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(5, 5), BackgroundTransparency = 0.2, ZIndex = 20, Parent = UI.Gui }, { UI.corner(3) })
	R.Progress:FireServer("gun")
	Audio.Music("Danger", 0.5, 2)
end

local function shoot()
	if not state.armed then return end
	if state.cool and os.clock() - state.cool < 0.35 then return end
	state.cool = os.clock()
	local cam = workspace.CurrentCamera
	R.Shoot:FireServer(cam.CFrame.Position, cam.CFrame.LookVector)
	Effects.Shake(0.15)
end

-- ─────────────── האקדח עף ונעלם ───────────────
local function loseGun()
	state.armed = false
	if state.cross then state.cross:Destroy() end
	FP.LockMove(true)
	FP.SetEnabled(false)
	Cinematic.Take()
	local cam = workspace.CurrentCamera
	local base = cam.CFrame
	-- פיצוץ קרוב: הבזק, רעידה, צלצול
	Audio.Play(Config.Sfx.Boom, { vol = scared() and 1 or 0.5 })
	Effects.Flash(0.7, 0.8)
	Effects.Shake(1)
	Audio.Ring(0.8)
	Audio.Muffle(0.6, 0.1)
	-- האקדח עף מהיד ונעלם באבק
	if gunModel then
		local w = gunModel:FindFirstChildOfClass("WeldConstraint"); if w then w:Destroy() end
		gunModel.Anchored = false
		gunModel.Parent = workspace
		gunModel.AssemblyLinearVelocity = base.LookVector * 40 + base.RightVector * 25 + Vector3.new(0, 35, 0)
		gunModel.AssemblyAngularVelocity = Vector3.new(15, 25, 8)
		task.delay(0.9, function()
			if gunModel then dustAt(gunModel.Position); Debris:AddItem(gunModel, 0.6); gunModel.Transparency = 0.5 end
		end)
	end
	Cinematic.MoveTo(base * CFrame.new(-1.5, -2.2, 0.5) * CFrame.Angles(math.rad(20), math.rad(35), math.rad(-25)), 0.35, "out")
	task.wait(0.4)
	-- המבט עוקב אחרי האקדח שמתרחק
	local t0 = os.clock()
	while os.clock() - t0 < 1.6 do
		RunService.RenderStepped:Wait()
		if gunModel and gunModel.Parent then cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, gunModel.Position), 0.12) end
	end
	Audio.Muffle(0, 2)
	Cinematic.MoveTo(base, 0.8, "inOut")
	Cinematic.Release()
	FP.SetEnabled(true)
	FP.LockMove(false)
	gunModel = nil
	Audio.Music("Tension", 0.5, 3)
end

-- ─────────────── התפיסה (ג'אמפסקייר) ───────────────
local function capture(route)
	state.capturing = true
	local cam = workspace.CurrentCamera
	local calm = not scared()
	Crowd.SetVisible(false)
	-- 1) ביטחון שווא – רק סביבה: מוזיקה נרגעת, נשימה מאטה, ציפור, רוח
	Audio.Music(nil, 0, 2)
	if state.siren then state.siren:SetVol(0.06, 3) end
	if state.panic then state.panic:SetVol(0.04, 2) end
	local wind = Audio.Loop(Config.Sfx.Wind, { vol = 0.4 })
	FP.Fear = 0.05; FP.BreathOverride = 0.5
	task.wait(1.6); FP.BreathOverride = 0.25
	Audio.Play(Config.Sfx.Birds, { vol = 0.35, life = 6 })
	task.wait(2.2); FP.BreathOverride = 0.1
	task.wait(2)
	-- 2) שקט מוחלט
	wind:Stop(0.3)
	FP.BreathOverride = 0
	task.wait(calm and 1.2 or 0.9)
	-- 3) המכה – לפי המסלול
	FP.SetEnabled(false)
	Cinematic.Take()
	local base = cam.CFrame
	local tmpl = RS.Templates:FindFirstChild("Terrorist")
	local tr = tmpl and tmpl:Clone()
	if tr then tr:SetAttribute("Local", true); tr:SetAttribute("NPC", true); tr.HumanoidRootPart.Anchored = true end
	local function hit(vol)
		if calm then Audio.Play(Config.Sfx.BodyFall, { vol = 0.3 }) return end
		Audio.Play(Config.Sfx.Stinger, { vol = vol or 1 }); Audio.Play(Config.Sfx.Punch, { vol = 0.9 })
		Effects.Flash(0.6, 0.5); Effects.Shake(1)
	end
	local fwd = Vector3.new(base.LookVector.X, 0, base.LookVector.Z).Unit
	if route == "car" then
		Audio.Play(Config.Sfx.Skid, { vol = 0.9 }); Effects.Shake(0.9)
		if tr then tr:PivotTo(CFrame.lookAt(base.Position + fwd * 9 - Vector3.new(0, 1.5, 0), base.Position)); tr.Parent = workspace; tr:SetAttribute("Pose", "aim") end
		task.wait(calm and 1.2 or 0.25)
		hit(1)
		Audio.Play(Config.Sfx.Glass, { vol = calm and 0.4 or 1 })
		local crack = UI.new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 15, Parent = UI.Gui })
		for i = 1, 24 do
			local a = math.random() * 360
			UI.new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.3, AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0.5, 0.42), Size = UDim2.new(0, math.random(120, 520), 0, 1), Rotation = a, ZIndex = 15, Parent = crack })
		end
		task.wait(0.7)
		-- יד מוציאה מהרכב
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		if hum then hum.Sit = false end
		Cinematic.MoveTo(base * CFrame.new(-3, -2.8, 0) * CFrame.Angles(0, 0, math.rad(55)), 0.5, "inn")
		crack:Destroy()
	elseif route == "hide" then
		if tr then tr:PivotTo(CFrame.lookAt(base.Position + fwd * (calm and 4 or 1.9) - Vector3.new(0, 2.6, 0), base.Position - Vector3.new(0, 2.6, 0))); tr.Parent = workspace; tr:SetAttribute("Pose", "crouch") end
		if calm then UI.FadeTo(0.4, 0); UI.FadeTo(0, 0.6) end
		Audio.Play(Config.Sfx.Rustle, { vol = 1 })
		hit(1)
		task.wait(0.9)
		Audio.Play(Config.Sfx.Cloth, { vol = 1 }); Effects.Shake(0.6)
		Cinematic.MoveTo(base * CFrame.new(0, 1.2, -1.2), 0.4, "inn")
	else
		-- ברגל: מכה מאחור, האופק מתהפך, קלוז־אפ
		if tr then tr:PivotTo(CFrame.lookAt(base.Position - fwd * 2.5 - Vector3.new(0, 1.5, 0), base.Position + fwd)); tr.Parent = workspace end
		hit(1); Audio.Ring(calm and 0.2 or 0.7); Audio.Muffle(0.5, 0.1)
		Cinematic.MoveTo(base * CFrame.new(0, -3.6, -2) * CFrame.Angles(math.rad(-60), 0, math.rad(80)), calm and 1.2 or 0.45, "inn")
		Audio.Play(Config.Sfx.BodyFall, { vol = 0.9 }); Effects.Shake(0.7)
		task.wait(0.7)
		local camPos = cam.CFrame.Position
		if tr then tr:PivotTo(CFrame.lookAt(camPos + fwd * 2.2 + Vector3.new(0, 1.0, 0), camPos)); tr:SetAttribute("Pose", "aim") end
		cam.CFrame = CFrame.lookAt(camPos, (tr and tr.Head.Position) or (camPos + Vector3.new(0, 3, 0)))
		if not calm then Audio.Play(Config.Sfx.Stinger2, { vol = 0.6 }) end
		task.wait(1.2)
	end
	Audio.Muffle(0.35, 0.3)
	-- 4) מרים את השחקן, אגרוף ישיר, חיתוך לשחור
	if tr then
		local head = tr.Head.Position
		local look = (cam.CFrame.Position - head)
		look = Vector3.new(look.X, 0, look.Z).Unit
		tr:SetAttribute("Pose", "")
		Cinematic.MoveTo(CFrame.lookAt(head + look * 2.6 + Vector3.new(0, -0.1, 0), head), calm and 1 or 0.55, "out")
		Audio.Play(Config.Sfx.Cloth, { vol = 0.8 })
		task.wait(calm and 1.2 or 0.6)
		-- אגרוף: היד הימנית אל המצלמה
		local ra = tr:FindFirstChild("RightHand")
		if ra then
			local t0 = os.clock()
			local from = ra.Position
			local dur = calm and 0.6 or 0.18
			while os.clock() - t0 < dur do
				RunService.RenderStepped:Wait()
				local k = (os.clock() - t0) / dur
				local sh = tr.RightUpperArm:FindFirstChild("RightShoulder")
				if sh then sh.Transform = CFrame.Angles(math.rad(90 * k), 0, 0) end
				cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, ra.Position), 0.3)
			end
		end
	end
	Audio.Play(Config.Sfx.Punch, { vol = calm and 0.4 or 1 }); Audio.Play(Config.Sfx.BodyFall, { vol = calm and 0.3 or 0.9 })
	UI.FadeTo(1, 0)
	Audio.Ring(calm and 0.3 or 1)
	Audio.Muffle(0.85, 0.05)
	if tr then tr:Destroy() end
	-- 5) שחור, צלילים מבולבלים
	if state.siren then state.siren:Stop(1) end
	if state.panic then state.panic:Stop(1) end
	FP.BreathOverride = 0.8; FP.Fear = 1
	task.wait(1.2)
	Audio.Play(Config.Sfx.CrowdPanic, { vol = 0.15, speed = 0.7 }); task.wait(1.4)
	Audio.Play(Config.Sfx.CarDoor, { vol = 0.4 }); task.wait(1.6)
	Audio.Play(Config.Sfx.Engine, { vol = 0.25, life = 4 })
	task.wait(2.2)
	FP.BreathOverride = nil; FP.Fear = 0; Audio.Muffle(0, 2)
	Crowd.Stop()
	R.Progress:FireServer("Captured")
	if #Players:GetPlayers() > 1 then UI.Toast(T.Hud.Waiting, 30) end
end

local function surprise() end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	state = {}
	Effects.Grade("Dawn", 0.1)
	Audio.StopAll(0.5)
	Audio.Space("field")
	Audio.Music(nil)
	table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 then shoot() end
	end))
	task.spawn(function()
		if not cp then wake() else UI.FadeTo(0, 1); FP.SetEnabled(true) end
		R.Progress:FireServer("Awake")
	end)
end

function Ch.OnStory(name, ...)
	if name == "escape" then
		FP.Fear = 0.6
		Audio.Music("Tension", 0.55, 2)
		state.panic = Audio.Loop(Config.Sfx.CrowdPanic, { vol = 0.5 })
		if not state.siren then state.siren = Audio.Loop(Config.Sfx.Siren, { vol = 0.4, pos = P.origin + Vector3.new(-80, 40, 100), minDist = 300, maxDist = 3000, group = "Sfx" }) end
		local threats = {}
		for _, m in ipairs(workspace.Map:GetChildren()) do if m:GetAttribute("Terrorist") then table.insert(threats, m) end end
		Crowd.Start(P.escape, 150, { P.origin + Vector3.new(380, 0, 120), P.origin + Vector3.new(340, 0, -120), P.origin + Vector3.new(180, 0, 420), P.origin + Vector3.new(-60, 0, 480), P.parking }, threats)
		task.spawn(seeShachar)
		task.delay(1.5, function() UI.Bark("yoni", T.CH2.Yoni3, 1800) end)
		task.delay(5, function() UI.Bark("", T.CH2.Shout2, 1800) end)
		task.spawn(function() while not state.capturing and R do task.wait(18 + math.random() * 10); if not state.capturing then rocketSalvo(3) end end end)
		-- אחרי כמה שניות של ריצה: החפירה בחול
		task.spawn(function()
			local runT = 0
			while runT < 7 and not state.capturing do
				local dt = task.wait(0.1)
				if FP.Running or (hrp() and hrp().AssemblyLinearVelocity.Magnitude > 14) then runT += dt end
			end
			if not state.capturing then digForGun() end
		end)
	elseif name == "gunLost" then
		task.spawn(loseGun)
	elseif name == "capture" then
		task.spawn(capture, ...)
	elseif name == "fail" then
		Ch.Fail()
	elseif name == "respawn" then
		Ch.Respawn()
	end
end

--- פגיעה: אדום בקצה, צליל חד, האטה, חיתוך לשחור עם דופק ונשימה – בלי טקסט
function Ch.Fail()
	Audio.Play(Config.Sfx.Punch, { vol = 0.8 })
	UI.Hit(1); Effects.Shake(0.7); Effects.Desat(0.8, 2)
	Audio.Muffle(0.7, 0.2); Audio.Ring(0.8)
	FP.BreathOverride = 1; FP.LockMove(true)
	task.wait(0.45)
	UI.FadeTo(1, 1.6)
	task.wait(1)
	FP.Fear = 1
end
function Ch.Respawn()
	UI.Hit(0); Effects.Desat(0, 0.5); FP.BreathOverride = nil; Audio.Muffle(0, 1); FP.LockMove(false)
	UI.FadeTo(0, 0.8)
end

function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	Crowd.Stop()
	if state.cross then state.cross:Destroy() end
	if gunModel then gunModel:Destroy(); gunModel = nil end
	state = {}
end

return Ch
