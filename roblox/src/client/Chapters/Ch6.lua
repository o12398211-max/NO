-- ═══════════════════════════════════════════════════════════════════
--  פרק 6 – הקפיצה והבית (לקוח): שליפה וירייה בגוף ראשון (המצלמה מסיטה מבט, לא גרפי),
--  הנוסעים מתכופפים, מרוץ נגד הזמן, צביקה והמצנח (בהסכמה), המשואה, הדלת, הצניחה,
--  הנחיתה בישראל, האיחוד עם שחר והמשפחה, אפילוג בכיכר, הקדשה וקרדיטים
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Shared.Texts)
local Config = require(RS.Shared.Config)
local Ctl = script.Parent.Parent
local UI = require(Ctl.UI)
local Audio = require(Ctl.Audio)
local Effects = require(Ctl.Effects)
local Cinematic = require(Ctl.Cinematic)
local FP = require(Ctl.FirstPerson)
local Ch5 = require(script.Parent.Ch5)

local Ch = {}
local plr = Players.LocalPlayer
local R, P
local conns = {}
local stage = "draw"
local pistol
local timer = 0

local function myGuard()
	for _, m in ipairs(workspace.Map:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("GuardOf") == plr.UserId then return m end
	end
end

local function shoot()
	if stage ~= "draw" then return end
	stage = "shot"
	UI.Note(nil)
	local cam = workspace.CurrentCamera
	Audio.Play(Config.Sfx.Pistol, { vol = 1 })
	Effects.Flash(0.5, 0.25)
	Effects.Shake(0.6)
	Audio.Ring(0.6)
	-- המצלמה מסיטה מבט – לא מראים את הפגיעה
	FP.SetEnabled(false)
	Cinematic.Take()
	local base = cam.CFrame
	Cinematic.MoveTo(base * CFrame.Angles(math.rad(-10), math.rad(70), 0), 0.25, "out")
	local g = myGuard()
	if g then for _, d in ipairs(g:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end end
	R.Progress:FireServer("guardDown")
	-- הנוסעים צועקים ומתכופפים מתחת לכיסאות
	for _, m in ipairs(workspace.Map:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("NPC") and not m:GetAttribute("Terrorist") and m:GetAttribute("Pose") == "sit" then m:SetAttribute("Pose", "cower") end
	end
	Audio.Play(Config.Sfx.CrowdPanic, { vol = 0.6 })
	task.wait(0.8)
	Cinematic.MoveTo(base, 0.5, "inOut")
	Cinematic.Release()
	FP.SetEnabled(true)
	if pistol then pistol:Destroy(); pistol = nil end
	local hum = plr.Character:FindFirstChildOfClass("Humanoid")
	if hum then hum.Sit = false end
	FP.LockMove(false)
	stage = "find"
	timer = 0
	Audio.Music("Danger", 0.6, 1)
	-- צביקה: רמז ויזואלי – הסוודר הכתום, סמל הכנפיים, והוא מסמן בעיניים
	if P.zvika and P.zvika:FindFirstChild("Head") then
		local zp = P.zvika.Head:FindFirstChildOfClass("ProximityPrompt")
		if zp then zp.Enabled = true end
		P.zvika:SetAttribute("Talking", true)
		task.delay(1.2, function() if P.zvika then P.zvika:SetAttribute("Talking", false) end end)
	end
end

local function gearUp()
	stage = "gear"
	FP.LockMove(true)
	UI.Lines(T.CH6.ZvikaLine, { zvika = P.zvika })
	-- קלוז־אפ: הרצועות על החזה
	Cinematic.Take()
	local cam = workspace.CurrentCamera
	local base = cam.CFrame
	Cinematic.MoveTo(base * CFrame.Angles(math.rad(-65), 0, 0), 0.6, "inOut", 60)
	Audio.Play(Config.Sfx.Zip, { vol = 0.7 }); task.wait(0.6)
	Audio.Play(Config.Sfx.Cloth, { vol = 0.7 }); task.wait(0.6)
	Audio.Play(Config.Sfx.Latch, { vol = 0.7 }); task.wait(0.5)
	-- מצנח על הגב (מקומי)
	local torso = plr.Character:FindFirstChild("UpperTorso")
	if torso then
		local pack = Instance.new("Part"); pack.Size = Vector3.new(1.6, 2, 0.8); pack.Color = Color3.fromRGB(232, 85, 31); pack.Material = Enum.Material.Fabric; pack.CanCollide = false; pack.Massless = true
		pack.CFrame = torso.CFrame * CFrame.new(0, 0, 0.8); pack.Parent = plr.Character
		local w = Instance.new("WeldConstraint"); w.Part0 = torso; w.Part1 = pack; w.Parent = pack
	end
	-- המשואה
	Cinematic.MoveTo(base * CFrame.Angles(math.rad(-30), 0, 0), 0.5, "inOut", 55)
	UI.Note("E – " .. T.CH6.Beacon)
	local pressed = false
	local c = UIS.InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.E then pressed = true end end)
	while not pressed do task.wait() end
	c:Disconnect()
	UI.Note(nil)
	Audio.Play(Config.Sfx.Beep, { vol = 0.7 })
	task.spawn(function() while R and stage ~= "end" do task.wait(1.2); Audio.Play(Config.Sfx.Beep, { vol = 0.25 }) end end)
	R.Progress:FireServer("puzzle")
	Cinematic.MoveTo(base, 0.5, "inOut", 72)
	Cinematic.Release()
	FP.LockMove(false)
	stage = "door"
	UI.Bark("zvika", T.CH6.LowSlow, 3000)
	local door = workspace.Map:FindFirstChild("MainDoor", true)
	if door then local dp = door:FindFirstChildOfClass("ProximityPrompt"); if dp then dp.Enabled = true end end
end

local function jump()
	stage = "jump"
	Audio.Play(Config.Sfx.DoorSlam, { vol = 1 })
	local roar = Audio.Loop(Config.Sfx.FallWind, { vol = 1, group = "Sfx" })
	Effects.Shake(1)
	UI.FadeTo(1, 1.2)
	task.wait(1.3)
	-- צניחה בגוף ראשון מעל שדות ישראל
	FP.SetEnabled(false)
	Cinematic.Take()
	Effects.Grade("Home", 0.1)
	local cam = workspace.CurrentCamera
	local home = P.home
	local y = 900
	UI.FadeTo(0, 1)
	local t0 = os.clock()
	local chute = false
	while os.clock() - t0 < 13 do
		local dt = RunService.RenderStepped:Wait()
		local t = os.clock() - t0
		y = math.max(40, y - dt * (chute and 10 or 75))
		cam.CFrame = CFrame.new(home + Vector3.new(-60 + t * 4, y, -60 + t * 4)) * CFrame.Angles(math.rad(-70 + math.sin(t * 2) * 3), t * 0.1, math.rad(math.sin(t * 3) * 3)) * Effects.ShakeOffset(dt)
		cam.FieldOfView = chute and 70 or 85
		if not chute and t > 7.5 then
			chute = true
			Audio.Play(Config.Sfx.Chute, { vol = 1 }); Audio.Play(Config.Sfx.Flap, { vol = 0.6 })
			Effects.Shake(1)
			roar:SetVol(0.25, 1)
		end
	end
	roar:Stop(1)
	UI.FadeTo(1, 1)
	task.wait(1.1)
	plr.Character:PivotTo(CFrame.new(home + Vector3.new(0, 4, 5)))
	Ch.Home()
end

function Ch.Home()
	stage = "home"
	local cam = workspace.CurrentCamera
	local home = P.home
	Audio.StopAll(1)
	Audio.Space("open")
	Audio.Music("Hope", 0.55, 2)
	Effects.Grade("Home", 0.1)
	-- הדמות שלי מתחבקת עם שחר (עותק מקומי)
	local me = plr.Character
	me.Archivable = true
	local clone = me:Clone()
	clone:SetAttribute("Local", true); clone:SetAttribute("NPC", true)
	for _, s in ipairs(clone:GetDescendants()) do if s:IsA("Script") or s:IsA("LocalScript") then s:Destroy() end end
	clone.HumanoidRootPart.Anchored = true
	clone:PivotTo(CFrame.new(home + Vector3.new(0, 3, 0.4)))
	clone.Parent = workspace
	clone:SetAttribute("Pose", "hug")
	local sh = P.reunion
	if sh then sh:SetAttribute("Pose", "hug") end
	UI.FadeTo(0, 1)
	Cinematic.Play({
		{ dur = 5, from = { pos = home + Vector3.new(18, 6, 14), look = home + Vector3.new(0, 4.5, 1), fov = 40 }, to = { pos = home + Vector3.new(7, 5, 7), look = home + Vector3.new(0, 4.5, 1), fov = 34 }, at = { { t = 0.8, fn = function() UI.Bark("", T.CH6.Landing, 4800) end } } },
		{ dur = 4, from = { pos = home + Vector3.new(1.6, 3.6, 3.4), look = home + Vector3.new(0.3, 3.2, 1.2), fov = 22 }, dof = { focus = 2.4, radius = 0.8 } },
		{ dur = 7, from = { pos = home + Vector3.new(4, 5.2, 5), look = home + Vector3.new(0, 4.8, 1.2), fov = 32 }, at = { { t = 0.4, fn = function() UI.Lines(T.CH6.Reunion, { shachar = sh, mom = P.mom }) end } } },
		{ dur = 6, from = { pos = home + Vector3.new(0, 9, 30), look = home + Vector3.new(0, 4, 0), fov = 45 }, to = { pos = home + Vector3.new(0, 45, 70), look = home + Vector3.new(0, 3, 0), fov = 45 } },
	})
	UI.FadeTo(1, 1.2)
	task.wait(1.3)
	clone:Destroy()
	-- אפילוג: כיכר, נרות, כיסאות
	local mem = P.memorial
	Effects.Grade("Memorial", 0.1)
	Audio.Music("Memorial", 0.45, 3)
	UI.FadeTo(0, 2)
	task.spawn(function()
		Cinematic.Play({ { dur = 22, from = { pos = mem + Vector3.new(40, 14, 40), look = mem + Vector3.new(0, 1, 0), fov = 40 }, to = { pos = mem + Vector3.new(12, 5, 12), look = mem + Vector3.new(0, 0.5, 0), fov = 36 }, hand = 0.1 } })
	end)
	task.wait(2)
	for _, l in ipairs(T.CH6.Epilogue) do UI.Sub("", l, 5.5) end
	task.wait(3)
	UI.FadeTo(1, 1)
	task.wait(1.2)
	UI.Credits()
	stage = "end"
	R.Progress:FireServer("Done")
end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	stage = "draw"
	timer = 0
	Effects.Grade("Plane", 0.1)
	Audio.StopAll(0.5)
	Audio.Space("cabin")
	Audio.Loop(Config.Sfx.Cabin, { vol = 0.6 })
	table.insert(conns, RunService.Heartbeat:Connect(function(dt)
		Ch5.Ghosts(true)
		if stage == "find" or stage == "gear" or stage == "door" then
			timer += dt
			if math.random() < dt * 0.8 then Audio.Play(Config.Sfx.Step.Metal, { pos = P.origin + Vector3.new(0, 3, -50), vol = 0.6 }) end
			if math.random() < dt * 0.4 then Audio.Play(Config.Sfx.CrowdPanic, { pos = P.origin + Vector3.new(0, 3, -50), vol = 0.3, speed = 0.8 }) end
			FP.Fear = math.min(1, 0.5 + timer / 120)
		end
	end))
	table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.UserInputType == Enum.UserInputType.MouseButton1 and stage == "draw" and pistol then shoot() end
	end))
	table.insert(conns, PPS.PromptTriggered:Connect(function(pp)
		local id = pp:GetAttribute("Id")
		if id == "zvika" and stage == "find" then pp.Enabled = false; task.spawn(gearUp)
		elseif id == "door" and stage == "door" then pp.Enabled = false; task.spawn(jump) end
	end))
	if cp == "home" then task.spawn(Ch.Home) return end
	task.spawn(function()
		UI.FadeTo(0, 1)
		FP.SetEnabled(true)
		FP.LockMove(true)
		UI.ChapterCard(6)
		-- שליפת האקדח – גוף ראשון
		local ra = plr.Character and plr.Character:FindFirstChild("RightHand")
		if ra then
			pistol = Instance.new("Part"); pistol.Size = Vector3.new(0.3, 0.35, 1.1); pistol.Color = Color3.fromRGB(28, 29, 31); pistol.Material = Enum.Material.Metal; pistol.CanCollide = false; pistol.Massless = true
			pistol.CFrame = ra.CFrame * CFrame.new(0, -0.3, -0.5); pistol.Parent = plr.Character
			local w = Instance.new("WeldConstraint"); w.Part0 = ra; w.Part1 = pistol; w.Parent = pistol
		end
		Audio.Play(Config.Sfx.Cloth, { vol = 0.7 })
		UI.Note(T.CH6.Shoot)
		R.Progress:FireServer("Awake")
	end)
end

function Ch.OnStory() end
function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	Ch5.Ghosts(false)
	if pistol then pistol:Destroy() end
	R = nil
end

return Ch
