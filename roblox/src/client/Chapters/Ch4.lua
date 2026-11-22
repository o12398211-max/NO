-- ═══════════════════════════════════════════════════════════════════
--  פרק 4 – בחוץ (לקוח): המפה (קאטסין בגוף שלישי), מיני־מפה עגולה עם מסלול,
--  רכבים ופנסים (L), הסתתרות מסיורים, והתפיסה המפתיעה: פנסים נדלקים בבת אחת ומטח
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

local Ch = {}
local plr = Players.LocalPlayer
local R, P
local conns = {}
local hasMap = false
local lightsOn = false
local dots = {}

local function readMap(pp)
	if hasMap then return end
	hasMap = true
	pp.Enabled = false
	FP.LockMove(true)
	FP.SetEnabled(false)
	local char = plr.Character
	local head = char.Head.Position
	local map = P.map
	-- הדמות מסתכלת על המפה – גוף שלישי קולנועי
	char:SetAttribute("Pose", "aim")
	Cinematic.Play({
		{ dur = 3, from = { pos = head + Vector3.new(6, 1.5, 6), look = head, fov = 40 }, to = { pos = head + Vector3.new(2.5, 0.4, 3.2), look = head, fov = 32 } },
		{ dur = 2.4, from = { pos = head + (head - map).Unit * -1.2 + Vector3.new(0, 0.2, 0), look = head, fov = 24 }, dof = { focus = 1.4, radius = 0.8 } },
		{ dur = 2.6, from = { pos = map + Vector3.new(0.3, 2.4, 0.6), look = map, fov = 34 }, at = { { t = 1.2, fn = function() Audio.Play(Config.Sfx.Cloth, { vol = 0.5 }) end } } },
		{ dur = 2.2, from = { pos = head + Vector3.new(4, 0.8, 4), look = head, fov = 38 }, at = { { t = 0.5, fn = function() Audio.Play(Config.Sfx.Cloth, { vol = 0.6 }) end } } },
	})
	char:SetAttribute("Pose", nil)
	FP.SetEnabled(true)
	FP.LockMove(false)
	UI.Objective(T.CH4.Obj.Go)
	UI.MiniOn = true
	UI.Mini.Visible = true
	R.Progress:FireServer("puzzle")
end

local function dot(color, size)
	return UI.new("Frame", { BackgroundColor3 = color, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(size, size), ZIndex = 23, Parent = UI.MiniWorld }, { UI.corner(size) })
end

local function updateMini()
	if not UI.MiniOn then return end
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	local cam = workspace.CurrentCamera
	local yaw = math.atan2(-cam.CFrame.LookVector.X, -cam.CFrame.LookVector.Z)
	UI.MiniWorld.Rotation = -math.deg(yaw)
	local scale = 0.32
	local function place(f, pos)
		local d = pos - hrp.Position
		f.Position = UDim2.new(0.5, d.X * scale, 0.5, d.Z * scale)
	end
	-- קו המסלול אל היעד
	dots.route = dots.route or UI.new("Frame", { BackgroundColor3 = UI.Colors.Accent, AnchorPoint = Vector2.new(0.5, 0.5), BorderSizePixel = 0, ZIndex = 22, Parent = UI.MiniWorld })
	local d = P.goal - hrp.Position
	local len = Vector2.new(d.X, d.Z).Magnitude * scale
	dots.route.Size = UDim2.fromOffset(len, 4)
	dots.route.Position = UDim2.new(0.5, d.X * scale / 2, 0.5, d.Z * scale / 2)
	dots.route.Rotation = math.deg(math.atan2(d.Z, d.X))
	dots.goal = dots.goal or dot(UI.Colors.Accent, 14)
	local gx, gz = math.clamp(d.X * scale, -100, 100), math.clamp(d.Z * scale, -100, 100)
	dots.goal.Position = UDim2.new(0.5, gx, 0.5, gz)
	-- סיורים
	local i = 0
	for _, m in ipairs(workspace.Map:GetChildren()) do
		if m:GetAttribute("Terrorist") and m:FindFirstChild("HumanoidRootPart") then
			i += 1
			dots["p" .. i] = dots["p" .. i] or dot(Color3.fromRGB(255, 106, 90), 7)
			place(dots["p" .. i], m.HumanoidRootPart.Position)
		end
	end
end

local function surprise()
	UI.MiniOn = false; UI.Mini.Visible = false
	UI.Objective(nil)
	FP.LockMove(true)
	Audio.Music(nil, 0, 2)
	Audio.Play(Config.Sfx.Birds, { vol = 0.3 })
	task.wait(2.5)
	-- פנסי רכב נדלקים בבת אחת + מטח פתאומי
	local hrp = plr.Character.HumanoidRootPart
	local lights = {}
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2
		local p = Instance.new("Part"); p.Anchored = true; p.CanCollide = false; p.Size = Vector3.new(1.2, 0.6, 0.3); p.Material = Enum.Material.Neon; p.Color = Color3.fromRGB(255, 242, 216)
		p.CFrame = CFrame.lookAt(hrp.Position + Vector3.new(math.cos(a) * 40, 1, math.sin(a) * 40), hrp.Position); p.Parent = workspace
		local s = Instance.new("SpotLight"); s.Face = Enum.NormalId.Front; s.Range = 80; s.Angle = 50; s.Brightness = 0; s.Parent = p
		table.insert(lights, s)
	end
	local calm = UI.Settings.ReduceScare
	for _, s in ipairs(lights) do s.Brightness = 6 end
	if not calm then Audio.Play(Config.Sfx.Stinger, { vol = 1 }) end
	Audio.Play(Config.Sfx.Battle, { vol = calm and 0.4 or 0.9, life = 4 })
	Effects.Flash(0.5, 0.8); Effects.Shake(1); Audio.Ring(0.6)
	task.wait(2)
	UI.FadeTo(1, 1)
	task.wait(1.2)
	for _, s in ipairs(lights) do s.Parent:Destroy() end
	Audio.Play(Config.Sfx.CarDoor, { vol = 0.8 })
	task.wait(1)
	Audio.Play(Config.Sfx.Engine, { vol = 0.4, life = 4 })
	task.wait(2.5)
	R.Progress:FireServer("Captured")
	if #Players:GetPlayers() > 1 then UI.Toast(T.Hud.Waiting, 30) end
end

function Ch.Start(remotes, payload, cp)
	R, P = remotes, payload
	hasMap, lightsOn, dots = false, false, {}
	Effects.Grade("Outside", 0.1)
	Audio.StopAll(0.5)
	Audio.Space("open")
	Audio.Music("Ominous", 0.4, 2)
	Audio.Loop(Config.Sfx.Wind, { vol = 0.35 })
	task.spawn(function() while R do task.wait(20 + math.random() * 20); Audio.Play(Config.Sfx.Dog, { pos = P.origin + Vector3.new(math.random(-400, 400), 0, math.random(-600, 0)), vol = 0.8, minDist = 80, maxDist = 1200 }) end end)
	table.insert(conns, PPS.PromptTriggered:Connect(function(pp) if pp:GetAttribute("Id") == "map" then task.spawn(readMap, pp) end end))
	table.insert(conns, UIS.InputBegan:Connect(function(i, gp)
		if gp then return end
		if i.KeyCode == Enum.KeyCode.L then
			local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
			if hum and hum.SeatPart then lightsOn = not lightsOn; R.State:FireServer({ lights = lightsOn }); Audio.Play(Config.Sfx.Latch, { vol = 0.4 }) end
		end
	end))
	table.insert(conns, RunService.RenderStepped:Connect(updateMini))
	task.spawn(function()
		UI.FadeTo(0, 1.5)
		FP.SetEnabled(true)
		UI.ChapterCard(4)
		UI.Objective(T.CH4.Obj.Map)
		R.Progress:FireServer("Awake")
	end)
end

function Ch.OnStory(name)
	if name == "surprise" then task.spawn(surprise) end
end
function Ch.OnFx(kind, a, b)
	if kind == "spotted" and a == plr.UserId then FP.Fear = 1; Effects.Shake(0.3); task.delay(2, function() FP.Fear = 0.3 end) end
	if kind == "burst" then Audio.Gunshot(a, false) end
end
function Ch.Stop()
	for _, c in ipairs(conns) do c:Disconnect() end
	conns = {}
	UI.MiniOn = false; UI.Mini.Visible = false
	UI.MiniWorld:ClearAllChildren()
	R = nil
end

return Ch
