-- ═══════════════════════════════════════════════════════════════════
--  פרק 1 – המסיבה (לקוח): קאטסין פתיחה → ~45 שניות חופשי → שחר והצמיד → פיזור → אוהל → שינה
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Shared.Texts)
local Config = require(RS.Shared.Config)
local Ctl = script.Parent.Parent
local UI = require(Ctl.UI)
local Audio = require(Ctl.Audio)
local Effects = require(Ctl.Effects)
local Cinematic = require(Ctl.Cinematic)
local FP = require(Ctl.FirstPerson)
local Show = require(Ctl.Show)
local Mini = require(Ctl.Minigames)

local Ch = {}
local plr = Players.LocalPlayer
local conns = {}
local R, P
local busy = false
local done = {}

local function npcModel(name)
	local map = workspace:FindFirstChild("Map")
	if not map then return end
	for _, m in ipairs(map:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("NPC") and m.Name == "NPC" then
			-- זיהוי לפי ProximityPrompt
		end
	end
end
local function speakersFor(prompt)
	local model = prompt and prompt.Parent and prompt.Parent.Parent
	return setmetatable({}, { __index = function(_, k)
		if k == "" then return model end
		local map = workspace:FindFirstChild("Map")
		if not map then return nil end
		for _, d in ipairs(map:GetDescendants()) do
			if d:IsA("ProximityPrompt") then
				local id = d:GetAttribute("Id")
				if id and id:sub(1, #k) == k then return d.Parent.Parent end
			end
		end
	end })
end

local function lockLook(model)
	if not model or not model:FindFirstChild("Head") then return end
	local cam = workspace.CurrentCamera
	local head = model.Head.Position
	-- מסובב בעדינות את המבט אל הדובר
	local char = plr.Character
	if char and char:FindFirstChild("HumanoidRootPart") then
		local hrp = char.HumanoidRootPart
		hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(head.X, hrp.Position.Y, head.Z))
	end
end

local function talk(prompt, id)
	if busy then return end
	busy = true
	FP.LockMove(true)
	local model = prompt.Parent.Parent
	lockLook(model)
	local function onAct(act)
		if act == "bracelet" then Ch.Bracelet()
		elseif act == "drink" then Ch.Drink()
		elseif act == "drum" then Mini.Drums(); R.Progress:FireServer("puzzle")
		elseif act == "djgame" then Mini.Rhythm(); R.Progress:FireServer("puzzle") end
	end
	UI.Dialog(T.CH1.Dlg, id, speakersFor(prompt), onAct, function() end)
	if id == "shachar_main" then
		R.Progress:FireServer("Bracelet")
		prompt.Enabled = false
		done.shachar = true
		UI.Objective(T.CH1.Obj.Explore)
	end
	if id == "yoni_hello" then done.friends = true; UI.Objective(T.CH1.Obj.Explore) end
	FP.LockMove(false)
	busy = false
end

function Ch.Bracelet()
	local char = plr.Character
	local cam = workspace.CurrentCamera
	Audio.MusicVolume(0.15, 1.5)
	Cinematic.Take()
	-- גוף ראשון: היד השמאלית עולה אל מול העיניים, הצמיד נענד
	local la = char and char:FindFirstChild("LeftLowerArm")
	local base = cam.CFrame
	local look = la and la.Position or (base.Position + base.LookVector * 2)
	Cinematic.MoveTo(CFrame.lookAt(base.Position, look), 1.2, "inOut", 50)
	Audio.Play(Config.Sfx.Cloth, { vol = 0.6 })
	task.wait(0.6)
	R.Progress:FireServer("Bracelet")
	Audio.Play(Config.Sfx.Latch, { vol = 0.5 })
	Audio.Music("Theme", 0.55, 2)
	Cinematic.Hold(2.6)
	Cinematic.MoveTo(base, 1, "inOut", 72)
	Cinematic.Release()
end

function Ch.Drink()
	Audio.Play(Config.Sfx.Cloth, { vol = 0.4 })
	task.wait(0.8)
	Effects.Shake(0.05)
end

local function selfie(prompt)
	if busy or done.selfie then return end
	busy = true
	FP.LockMove(true)
	local maya = prompt.Parent.Parent
	UI.Lines(T.CH1.Dlg.maya_selfie.lines, { maya = maya })
	local char = plr.Character
	local hrp = char.HumanoidRootPart
	local camPos = hrp.Position + hrp.CFrame.LookVector * 3.4 + Vector3.new(0, 2.4, 0)
	Cinematic.Take()
	FP.SetEnabled(false)
	workspace.CurrentCamera.CFrame = CFrame.lookAt(camPos, hrp.Position + Vector3.new(0, 1.6, 0))
	workspace.CurrentCamera.FieldOfView = 60
	Mini.Selfie()
	FP.SetEnabled(true)
	Cinematic.Release()
	UI.Lines(T.CH1.Dlg.maya_selfie2.lines, { maya = maya })
	R.Progress:FireServer("puzzle")
	done.selfie = true
	FP.LockMove(false)
	busy = false
end

local function sleep(prompt)
	if busy or done.sleep then return end
	done.sleep = true
	busy = true
	prompt.Enabled = false
	UI.Objective(nil)
	FP.LockMove(true)
	Audio.Play(Config.Sfx.Zip, { vol = 0.6 })
	Cinematic.Take()
	local cam = workspace.CurrentCamera
	local spot = P.sleep
	Cinematic.MoveTo(CFrame.lookAt(spot + Vector3.new(0, 0.8, 0), spot + Vector3.new(0, 6, -0.5)), 2.2, "inOut")
	Audio.Music("Piano", 0.3, 3)
	task.wait(2.5)
	-- העין נסגרת – ויניטה שחורה שנסגרת
	UI.Eyelid(0.55, 0.6); task.wait(1.4); UI.Eyelid(0.2, 1.2); task.wait(1.0); UI.Eyelid(0.85, 0.5); task.wait(1.4); UI.Eyelid(1, 0.6)
	Audio.Muffle(0.6, 2)
	task.wait(1.2)
	UI.FadeTo(1, 1)
	task.wait(1.2)
	R.Progress:FireServer("Asleep")
	UI.Eyelid(0, 0.1)
	if #Players:GetPlayers() > 1 then UI.Toast(T.Hud.Waiting, 30) end
end

local function intro()
	local d = P.dance
	local st = P.stage
	UI.FadeTo(1, 0)
	task.wait(0.3)
	UI.FadeTo(0, 1.2)
	task.spawn(function() task.wait(1.2); UI.ChapterCard(1) end)
	local shots = {
		{ dur = 7, from = { pos = d + Vector3.new(170, 110, 170), look = d + Vector3.new(0, 10, -40), fov = 55 }, to = { pos = d + Vector3.new(90, 45, 80), look = d + Vector3.new(0, 12, -50), fov = 50 }, hand = 0 },
		{ dur = 4.5, from = { pos = d + Vector3.new(-45, 7, 26), look = d + Vector3.new(-5, 8, -20), fov = 45 }, to = { pos = d + Vector3.new(30, 8, 22), look = d + Vector3.new(5, 8, -25), fov = 45 }, hand = 0.5 },
		{ dur = 3.5, from = { pos = st + Vector3.new(7, 9, 12), look = st + Vector3.new(0, 8.5, 1.5), fov = 32 }, to = { pos = st + Vector3.new(-6, 9.5, 11), look = st + Vector3.new(0, 8.5, 1.5), fov = 30 }, dof = { focus = 11, radius = 3 }, hand = 0.4 },
		{ dur = 2.8, from = { pos = d + Vector3.new(4, 6, 20), look = d + Vector3.new(0, 6, 0), fov = 30 }, dof = { focus = 18, radius = 4 }, hand = 0.6 },
		{ dur = 3.2, from = { pos = d + Vector3.new(-30, 4.5, 30), look = d + Vector3.new(-14, 5, 13), fov = 36 }, to = { pos = d + Vector3.new(-20, 5, 28), look = d + Vector3.new(-13, 5, 13), fov = 34 }, dof = { focus = 15, radius = 3 }, hand = 0.4 },
		{ dur = 3, from = { pos = d + Vector3.new(0, 80, 80), look = d, fov = 55 }, to = { pos = P.spawn + Vector3.new(0, 2, 0), look = P.spawn + Vector3.new(0, 2, -20), fov = 72 }, hand = 0 },
	}
	Cinematic.Play(shots, { skippable = true })
end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	busy, done = false, {}
	Effects.Grade("Party", 0.1)
	Audio.Space("field")
	Audio.StopAll(0.5)
	Audio.Music("Party", 0.6, 1)
	task.delay(0.5, function() Audio.MusicAt(P.stage + Vector3.new(0, 10, 15), true) end)
	Audio.Loop(Config.Sfx.Crickets, { vol = 0.35 })
	Audio.Loop(Config.Sfx.CrowdParty, { vol = 0.4, pos = P.dance, minDist = 60, maxDist = 400 })
	Show.Start({ led = P.led, heads = P.heads, lasers = P.lasers, stage = P.stage })
	table.insert(conns, PPS.PromptTriggered:Connect(function(pp)
		local id = pp:GetAttribute("Id")
		if not id then return end
		if id == "selfie" then task.spawn(selfie, pp)
		elseif id == "sleep" then task.spawn(sleep, pp)
		else task.spawn(talk, pp, id) end
	end))
	-- ריקוד (Q) על הרחבה
	local dancing = false
	table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
		if gp or busy then return end
		if i.KeyCode == Enum.KeyCode.Q then
			local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - P.dance).Magnitude < 75 then
				dancing = not dancing
				local hum = plr.Character.Humanoid
				local an = hum:FindFirstChildOfClass("Animator")
				if dancing then
					local a = Instance.new("Animation"); a.AnimationId = Config.Anim["Dance" .. math.random(1, 3)]
					Ch.DanceTrack = an:LoadAnimation(a); Ch.DanceTrack.Looped = true; Ch.DanceTrack:Play()
					UI.Note(T.CH1.Prompt.StopDance); FP.LockMove(true)
				else
					if Ch.DanceTrack then Ch.DanceTrack:Stop() end
					UI.Note(nil); FP.LockMove(false)
				end
			end
		elseif i.KeyCode == Enum.KeyCode.Space and dancing then
			dancing = false
			if Ch.DanceTrack then Ch.DanceTrack:Stop() end
			UI.Note(nil); FP.LockMove(false)
		end
	end))
	task.spawn(function()
		if cp ~= "tent" then
			if not cp then intro() else UI.FadeTo(0, 1) end
			R.Progress:FireServer("Awake")
			FP.SetEnabled(true)
			UI.Objective(T.CH1.Obj.FindFriends)
		else
			UI.FadeTo(0, 1); FP.SetEnabled(true); R.Progress:FireServer("Awake")
		end
	end)
end

function Ch.OnStory(name, ...)
	if name == "shacharComes" then
		local uid = ...
		if uid == plr.UserId and not done.shachar then UI.Objective(T.CH1.Obj.Shachar) end
	elseif name == "disperse" then
		Show.Intensity = 0.3
		Audio.Music("Lobby", 0.35, 6)
		UI.Objective(nil)
	elseif name == "tentTime" then
		task.spawn(function()
			while busy do task.wait(0.2) end
			busy = true
			FP.LockMove(true)
			UI.Lines(T.CH1.Dlg.tent_time.lines, speakersFor(nil))
			FP.LockMove(false)
			busy = false
			UI.Objective(T.CH1.Obj.Tent)
			task.wait(14)
			UI.Lines(T.CH1.Dlg.tent_sleep.lines, speakersFor(nil))
			UI.Objective(T.CH1.Obj.Sleep)
		end)
	end
end

function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	Show.Stop()
	Audio.MusicAt(nil, false)
	if Ch.DanceTrack then Ch.DanceTrack:Stop() end
end

return Ch
