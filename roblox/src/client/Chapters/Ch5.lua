-- ═══════════════════════════════════════════════════════════════════
--  פרק 5 – המטוס (לקוח): עלייה (קאטסין, שחר והצמיד התאום), "צריך לשירותים", בקשת אישור,
--  השירותים (קאטסין: החלון, המגירה, האקדח, השריקה), חזרה למושב. שחקנים אחרים = רוחות שקופות.
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
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

local Ch = {}
local plr = Players.LocalPlayer
local R, P
local conns = {}
local stage = "board"

--- שחקנים אחרים כרוחות שקופות (מונע בלבול ברצפים המקבילים)
function Ch.Ghosts(on)
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= plr and p.Character then
			for _, d in ipairs(p.Character:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = on and 0.75 or 0 end end
		end
	end
end

local function myGuard()
	for _, m in ipairs(workspace.Map:GetDescendants()) do
		if m:IsA("Model") and m:GetAttribute("GuardOf") == plr.UserId then return m end
	end
end

local function toilet()
	stage = "cut"
	Audio.Play(Config.Sfx.Latch, { vol = 0.7 })
	FP.LockMove(true)
	FP.SetEnabled(false)
	local lav = P.lav
	-- דמות מקומית של השחקן לקאטסין בגוף שלישי
	local me = plr.Character
	me.Archivable = true
	local clone = me:Clone()
	clone:SetAttribute("Local", true); clone:SetAttribute("NPC", true)
	for _, s in ipairs(clone:GetDescendants()) do if s:IsA("Script") or s:IsA("LocalScript") then s:Destroy() end end
	clone.HumanoidRootPart.Anchored = true
	clone:PivotTo(CFrame.new(lav + Vector3.new(-0.5, 3, 0.5)) * CFrame.Angles(0, math.rad(90), 0))
	clone.Parent = workspace
	local gun = Instance.new("Part"); gun.Anchored = true; gun.CanCollide = false; gun.Size = Vector3.new(0.3, 0.35, 1.0); gun.Color = Color3.fromRGB(28, 29, 31); gun.Material = Enum.Material.Metal; gun.CFrame = CFrame.new(lav + Vector3.new(2, 1.6, -0.4)); gun.Transparency = 1; gun.Parent = workspace
	Cinematic.Play({
		-- מנסה לעלות על האסלה ולצאת מהחלון – קטן ולא נפתח
		{ dur = 3.2, from = { pos = lav + Vector3.new(3, 6, -3), look = lav + Vector3.new(-3, 5.5, 1), fov = 42 }, onStart = function() clone:PivotTo(CFrame.new(lav + Vector3.new(-2, 4.7, 1)) * CFrame.Angles(0, math.rad(90), 0)); clone:SetAttribute("Pose", "handsUp"); Audio.Play(Config.Sfx.Pipe, { vol = 0.3, speed = 0.5 }) end },
		{ dur = 1.6, from = { pos = lav + Vector3.new(-1.5, 6, 0), look = lav + Vector3.new(-3.6, 6, 1), fov = 30 }, dof = { focus = 2.2, radius = 1 } },
		-- המגירה מתחת לכיור – אקדח
		{ dur = 3, from = { pos = lav + Vector3.new(-1, 4, -2), look = lav + Vector3.new(2, 1.4, 0), fov = 38 }, onStart = function() clone:PivotTo(CFrame.new(lav + Vector3.new(0.6, 3, 0)) * CFrame.Angles(0, math.rad(-90), 0)); clone:SetAttribute("Pose", "crouch"); Audio.Play(Config.Sfx.Latch, { vol = 0.4, speed = 1.3 }) end, at = { { t = 1.3, fn = function() gun.Transparency = 0; Audio.Play(Config.Sfx.Pipe, { vol = 0.2, speed = 2 }) end } } },
		{ dur = 2.4, from = { pos = lav + Vector3.new(1.4, 2.6, -1.2), look = gun.Position, fov = 22 }, dof = { focus = 1.6, radius = 0.6 } },
		-- מחביא, נושם, יוצא בשריקה קלה
		{ dur = 3, from = { pos = lav + Vector3.new(2.5, 5.5, -3.2), look = lav + Vector3.new(0, 4.5, 0), fov = 36 }, onStart = function() gun.Transparency = 1; clone:SetAttribute("Pose", ""); Audio.Play(Config.Sfx.Cloth, { vol = 0.6 }); Audio.Play(Config.Sfx.Breath, { vol = 0.5, life = 3 }) end },
		{ dur = 2.6, from = { pos = lav + Vector3.new(0, 5.5, -9), look = lav + Vector3.new(0, 4.5, -4), fov = 42 }, onStart = function() Audio.Play(Config.Sfx.Latch, { vol = 0.6 }); Audio.Play(Config.Sfx.Whistle, { vol = 0.5 }) end },
	})
	clone:Destroy(); gun:Destroy()
	plr.Character:PivotTo(CFrame.new(lav + Vector3.new(0, 3, -8)) * CFrame.Angles(0, 0, 0))
	FP.SetEnabled(true)
	FP.LockMove(false)
	stage = "back"
	UI.Objective(T.CH5.Back)
end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	stage = "board"
	Effects.Grade("Plane", 0.1)
	Audio.StopAll(0.5)
	Audio.Space("cabin")
	Audio.Loop(Config.Sfx.Cabin, { vol = 0.6 })
	Audio.Music("Drone", 0.3, 3)
	table.insert(conns, RunService.Heartbeat:Connect(function() Ch.Ghosts(true); if math.random() < 0.01 then Effects.Shake(0.06) end end))
	table.insert(conns, PPS.PromptTriggered:Connect(function(pp)
		local id = pp:GetAttribute("Id")
		if id == "guard" and stage == "ask" then
			stage = "go"
			UI.Note(nil)
			local g = myGuard()
			-- המחבל מהנהן
			if g and g:FindFirstChild("Head") then
				local neck = g.Head:FindFirstChild("Neck")
				for _ = 1, 2 do if neck then neck.Transform = CFrame.Angles(math.rad(-18), 0, 0) end; task.wait(0.3); if neck then neck.Transform = CFrame.new() end; task.wait(0.3) end
			end
			local hum = plr.Character:FindFirstChildOfClass("Humanoid")
			if hum then hum.Sit = false end
			FP.LockMove(false)
			local lavDoor = workspace.Map:FindFirstChild("LavDoor", true)
			if lavDoor then local lp = lavDoor:FindFirstChildOfClass("ProximityPrompt"); if lp then lp.Enabled = true end end
		elseif id == "lav" and stage == "go" then
			pp.Enabled = false
			task.spawn(toilet)
		end
	end))
	task.spawn(function()
		UI.FadeTo(0, 1.5)
		FP.SetEnabled(true)
		FP.LockMove(true)
		task.wait(0.4)
		local o = P.origin
		local sh = P.shachar
		task.spawn(function() task.wait(0.5); UI.ChapterCard(5) end)
		-- עלייה למטוס: שחר בין החטופים, הצמיד התאום בקלוז־אפ
		local shots = {
			{ dur = 4.5, from = { pos = o + Vector3.new(0, 8, -40), look = o + Vector3.new(0, 3, 30), fov = 50 }, to = { pos = o + Vector3.new(0, 7, -10), look = o + Vector3.new(0, 3, 40), fov = 48 } },
		}
		if sh and sh:FindFirstChild("Head") then
			local hp = sh.Head.Position
			local la = sh:FindFirstChild("LeftLowerArm")
			table.insert(shots, { dur = 3, from = { pos = hp + Vector3.new(2.2, 0.4, -2.4), look = hp, fov = 30 }, dof = { focus = 3.2, radius = 1 }, at = { { t = 0.4, fn = function() UI.Bark("", T.CH5.Shachar, 2200) end } } })
			if la then table.insert(shots, { dur = 3, from = { pos = la.Position + Vector3.new(1.4, 0.8, -1.2), look = la.Position, fov = 22 }, dof = { focus = 2, radius = 0.6 }, onStart = function() Audio.Music("Theme", 0.3, 1.5) end }) end
		end
		Cinematic.Play(shots)
		Audio.Music("Drone", 0.3, 3)
		stage = "ask"
		UI.Note(T.CH5.Note)
		R.Progress:FireServer("Awake")
	end)
	-- חזרה למושב
	task.spawn(function()
		while R do
			task.wait(0.3)
			if stage == "back" and P.seat then
				local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
				if hrp and (hrp.Position - P.seat).Magnitude < 7 then
					stage = "end"
					UI.Objective(nil)
					plr.Character:PivotTo(CFrame.new(P.seat + Vector3.new(0, 2.5, 0)) * CFrame.Angles(0, math.rad(180), 0))
					FP.LockMove(true)
					Audio.Music("Danger", 0.35, 2)
					task.wait(2.5)
					UI.FadeTo(1, 3)
					task.wait(3.2)
					R.Progress:FireServer("Done")
					if #Players:GetPlayers() > 1 then UI.Toast(T.Hud.Waiting, 30) end
				end
			end
		end
	end)
end

function Ch.OnStory() end
function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	Ch.Ghosts(false)
	R = nil
end

return Ch
