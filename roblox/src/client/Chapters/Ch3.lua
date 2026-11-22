-- ═══════════════════════════════════════════════════════════════════
--  פרק 3 – המנהרה (לקוח): התעוררות, הצמיד על היד, קוד הטפיחות, מאיר והכלי (בחירת אמון),
--  עידו והמנגינה (שיתוף פעולה בצינורות), התוכנית של אסתר, סטלת' בין פנסים, הסורג והפיר
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Shared.Texts)
local Config = require(RS.Shared.Config)
local Ctl = script.Parent.Parent
local UI = require(Ctl.UI)
local Audio = require(Ctl.Audio)
local Effects = require(Ctl.Effects)
local Cinematic = require(Ctl.Cinematic)
local FP = require(Ctl.FirstPerson)
local Mini = require(Ctl.Minigames)

local Ch = {}
local plr = Players.LocalPlayer
local R, P
local conns = {}
local busy = false
local GRID = { "אבגדה", "וזחטי", "כלמנס", "עפצקר", "שת" }

local function speakers()
	local s = {}
	for _, m in ipairs(workspace.Map:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("NPC") then
			for _, d in ipairs(m:GetDescendants()) do
				if d:IsA("ProximityPrompt") then local id = d:GetAttribute("Id"); if id then s[id] = m end end
			end
		end
	end
	-- אסתר: הדמות הקרובה לתא בלי הנחיה
	for _, m in ipairs(workspace.Map:GetChildren()) do
		if m:IsA("Model") and m:GetAttribute("NPC") and not s.esther then
			local has = false
			for _, d in ipairs(m:GetDescendants()) do if d:IsA("ProximityPrompt") then has = true end end
			if not has and not m:GetAttribute("Terrorist") then s.esther = m end
		end
	end
	return s
end

local function lockBusy(fn)
	if busy then return end
	busy = true
	FP.LockMove(true)
	local ok, err = pcall(fn)
	if not ok then warn(err) end
	FP.LockMove(false)
	busy = false
end

local function onPrompt(pp)
	local id = pp:GetAttribute("Id")
	if id == "knock" then
		task.spawn(lockBusy, function()
			UI.Lines(T.CH3.Knock, speakers())
			Mini.Decode("מים", GRID, P.knock)
			pp.Enabled = false
			UI.Lines(T.CH3.Decoded, speakers())
			R.Progress:FireServer("decoded")
		end)
	elseif id == "meir" then
		task.spawn(lockBusy, function()
			local s = speakers()
			UI.Lines(T.CH3.ToolAsk, s)
			local i = UI.Choose(T.CH3.ToolChoices)
			UI.Lines(i == 1 and T.CH3.ToolYes or T.CH3.ToolHonest, s)
			Audio.Play(Config.Sfx.Cloth, { vol = 0.7 })
			pp.Enabled = false
			R.Progress:FireServer("tool")
		end)
	elseif id == "ido" then
		task.spawn(lockBusy, function()
			local s = speakers()
			UI.Lines(T.CH3.Ido, s)
			-- עידו מזמזם את המנגינה של שחר – הוא שמע אותה במסיבה
			Audio.Music("Theme", 0.25, 2)
			UI.Lines(T.CH3.IdoTheme, s)
			UI.Lines(T.CH3.Plan, s)
			Audio.Music("Tunnel", 0.4, 3)
			pp.Enabled = false
			R.Progress:FireServer("plan")
			UI.Objective(T.CH3.Obj.Pipe)
		end)
	elseif id == "pipe1" or id == "pipe2" then
		task.spawn(lockBusy, function()
			local idx = id == "pipe1" and 1 or 2
			Mini.PipeMelody(function(n) R.Progress:FireServer("pipeNote", n) end)
			R.Progress:FireServer("pipesDone", idx)
			pp.Enabled = false
			if #Players:GetPlayers() > 1 then UI.Note(T.Hud.PartnerNeeded); task.delay(6, function() UI.Note(nil) end) end
		end)
	elseif id == "grate" then
		task.spawn(lockBusy, function()
			pp.Enabled = false
			Audio.Play(Config.Sfx.Pipe, { vol = 0.6, speed = 0.6 })
			Audio.Play(Config.Sfx.Drip, { vol = 0.8 })
			UI.Objective(T.CH3.Obj.Exit)
			FP.SetEnabled(false)
			Cinematic.Take()
			local cam = workspace.CurrentCamera
			-- טיפוס בפיר צר אל האור
			local start = P.exit
			cam.CFrame = CFrame.lookAt(start + Vector3.new(0, 2, 1), start + Vector3.new(0, 60, -0.5))
			for i = 1, 10 do
				Audio.Play(Config.Sfx.Step.Metal, { vol = 0.5 })
				Cinematic.MoveTo(cam.CFrame + Vector3.new(0, 5, 0), 0.45, "inOut")
			end
			Effects.Flash(0.7, 1.4)
			UI.FadeTo(1, 0.8)
			task.wait(1)
			Cinematic.Release()
			R.Progress:FireServer("Exited")
			if #Players:GetPlayers() > 1 then UI.Toast(T.Hud.Waiting, 30) end
		end)
	end
end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	busy = false
	Effects.Grade("Tunnel", 0.1)
	Audio.StopAll(0.5)
	Audio.Space("tunnel")
	Audio.Music("Tunnel", 0.4, 2)
	Audio.Loop(Config.Sfx.Drip, { vol = 0.3 })
	table.insert(conns, PPS.PromptTriggered:Connect(onPrompt))
	task.spawn(function()
		while R do
			task.wait(1 + math.random() * 3)
			if workspace:FindFirstChild("Map") then Audio.Play(Config.Sfx.Drip, { pos = P.cell + Vector3.new(math.random(-8, 8), 6, math.random(-60, 8)), vol = 0.6 }) end
		end
	end)
	task.spawn(function()
		UI.FadeTo(1, 0)
		UI.Eyelid(1, 0)
		Effects.BlurTo(24, 0)
		FP.SetEnabled(true)
		FP.LockMove(true)
		task.wait(0.5)
		UI.ChapterCard(3)
		UI.FadeTo(0, 0.5)
		UI.Eyelid(0, 2)
		Effects.BlurTo(0, 3)
		-- הצמיד של שחר עדיין על היד – נקודת העוגן הרגשית
		Cinematic.Take()
		local cam = workspace.CurrentCamera
		local la = plr.Character and plr.Character:FindFirstChild("LeftLowerArm")
		local base = cam.CFrame
		if la then Cinematic.MoveTo(CFrame.lookAt(base.Position, la.Position), 1.4, "inOut", 45) end
		Cinematic.Hold(2.2)
		Cinematic.MoveTo(base, 1, "inOut", 72)
		Cinematic.Release()
		FP.LockMove(false)
		if not cp then
			busy = true; FP.LockMove(true)
			UI.Lines(T.CH3.Wake, speakers())
			FP.LockMove(false); busy = false
			for _ = 1, 3 do Audio.Play(Config.Sfx.Knock, { pos = P.knock, vol = 0.9 }); task.wait(0.4) end
			UI.Objective(T.CH3.Obj.Listen)
		else
			UI.Objective(T.CH3.Obj.Sneak)
		end
		R.Progress:FireServer("Awake")
	end)
end

function Ch.OnStory(name, a, b)
	if name == "flag3" then
		if a == "decoded" then UI.Objective(T.CH3.Obj.Tool)
		elseif a == "tool" then UI.Objective(T.CH3.Obj.Ido)
		elseif a == "sneak" then UI.Objective(T.CH3.Obj.Sneak); Audio.Music("Danger", 0.35, 2) end
	elseif name == "pipeNote" and a ~= plr.UserId then
		Audio.Play(Config.Sfx.Pipe, { vol = 0.7, speed = ({ 0.8, 0.95, 1.1, 1.3 })[b] or 1, pos = P.pipes[1] })
	end
end
function Ch.OnFx(kind, a)
	if kind == "spotted" and a == plr.UserId then FP.Fear = 1; Effects.Shake(0.3); task.delay(2, function() FP.Fear = 0.3 end) end
	if kind == "burst" then local from = a; Audio.Gunshot(from, true) end
end

function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	R = nil
end

return Ch
