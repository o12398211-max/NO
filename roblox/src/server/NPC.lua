-- ═══════════════════════════════════════════════════════════════════
--  NPC – דמויות R15 עם אנימציות רשמיות של Roblox, צבעי גוף לפי איבר (בגדים),
--  פנים מחלקים (בלי פרצוף מצויר), שיער ואביזרים, ומחבלים (מסכה + סרט ירוק בלבד, בלי שום סמל)
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local B = require(script.Parent.World.Build)

local NPC = {}
local rgb = Color3.fromRGB
local M = Enum.Material

local SKIN, HAIR, OUT = Config.Skin, Config.HairColors, Config.Outfits

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = a
	return w
end
local function attach(parent, model, size, offset, color, mat, shape, mesh)
	local p = Instance.new("Part")
	p.Size = size
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.CanCollide = false
	p.Massless = true
	p.CastShadow = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if shape then p.Shape = shape end
	if mesh then local sm = Instance.new("SpecialMesh"); sm.MeshType = Enum.MeshType.Sphere; sm.Parent = p end
	p.CFrame = parent.CFrame * offset
	p.Parent = model
	weld(parent, p)
	return p
end
NPC.attach = attach

--- מראה אקראי דטרמיניסטי
function NPC.RandomLook(i)
	local r = Random.new(i * 7919 + 13)
	local gender = r:NextInteger(0, 1) == 1 and "f" or "m"
	local accs = { {}, { "cap" }, { "headband" }, { "flower" }, { "glasses" }, { "beanie" }, {}, { "scarf" } }
	return {
		skin = SKIN[r:NextInteger(1, #SKIN)],
		hair = gender == "f" and ({ 3, 4, 2, 1 })[r:NextInteger(1, 4)] or ({ 1, 2, 5, 1 })[r:NextInteger(1, 4)],
		hairColor = HAIR[r:NextInteger(1, 5)],
		top = OUT[r:NextInteger(1, #OUT)][1]:Lerp(Color3.fromHSV(r:NextNumber(), 0.6, 0.8), 0.45),
		bottom = OUT[r:NextInteger(1, #OUT)][2],
		shortSleeve = r:NextNumber() < 0.6,
		shorts = r:NextNumber() < 0.3,
		shoes = Color3.fromHSV(0, 0, r:NextNumber() * 0.9),
		gender = gender,
		acc = (gender == "m" and r:NextInteger(1, 5) == 1) and { "beard" } or accs[r:NextInteger(1, #accs)],
		accent = Color3.fromHSV(r:NextNumber(), 0.75, 0.9),
		height = 0.94 + r:NextNumber() * 0.12,
	}
end

--- צביעה לפי איברים = בגדים
local function paint(model, look)
	local bc = model:FindFirstChildOfClass("BodyColors")
	if bc then bc:Destroy() end
	local function c(n, col, mat)
		local p = model:FindFirstChild(n)
		if p then p.Color = col; p.Material = mat or M.SmoothPlastic end
	end
	local fabric = M.Fabric
	c("Head", look.skin)
	c("UpperTorso", look.top, fabric)
	c("LowerTorso", look.bottom, fabric)
	for _, s in ipairs({ "Left", "Right" }) do
		c(s .. "UpperArm", look.shortSleeve and look.skin or look.top, look.shortSleeve and M.SmoothPlastic or fabric)
		c(s .. "LowerArm", (look.longSleeve or look.terrorist) and look.top or look.skin, (look.longSleeve or look.terrorist) and fabric or M.SmoothPlastic)
		c(s .. "Hand", look.gloves or look.skin)
		c(s .. "UpperLeg", look.bottom, fabric)
		c(s .. "LowerLeg", look.shorts and look.skin or look.bottom, look.shorts and M.SmoothPlastic or fabric)
		c(s .. "Foot", look.shoes or rgb(40, 40, 40))
	end
	if look.shortSleeve and not look.terrorist then
		-- שרוול קצר: רצועת בד על הזרוע העליונה
		for _, s in ipairs({ "Left", "Right" }) do
			local ua = model:FindFirstChild(s .. "UpperArm")
			if ua then attach(ua, model, Vector3.new(ua.Size.X + 0.08, ua.Size.Y * 0.45, ua.Size.Z + 0.08), CFrame.new(0, ua.Size.Y * 0.28, 0), look.top, fabric) end
		end
	end
end

--- פנים מחלקים: עיניים, אישונים, גבות, פה
local function face(model, look)
	local head = model:FindFirstChild("Head")
	if not head then return end
	local f = head:FindFirstChild("face")
	if f then f:Destroy() end
	if look.terrorist then
		-- בלקלבה: ראש שחור, חריץ עיניים, סרט ירוק בלבד
		head.Color = rgb(18, 18, 18)
		head.Material = M.Fabric
		attach(head, model, Vector3.new(0.75, 0.18, 0.1), CFrame.new(0, 0.15, -0.58), look.skin:Lerp(Color3.new(), 0.2))
		for _, x in ipairs({ -0.2, 0.2 }) do
			local e = attach(head, model, Vector3.new(0.12, 0.12, 0.12), CFrame.new(x, 0.16, -0.62), rgb(220, 210, 195), M.SmoothPlastic, Enum.PartType.Ball)
			e.Name = "Eye"
		end
		attach(head, model, Vector3.new(0.22, 1.32, 1.32), CFrame.new(0, 0.42, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(31, 122, 52), M.Fabric, Enum.PartType.Cylinder).Name = "Headband"
		local knot = attach(head, model, Vector3.new(0.12, 0.45, 0.25), CFrame.new(0.1, 0.3, 0.62) * CFrame.Angles(math.rad(25), 0, math.rad(20)), rgb(31, 122, 52), M.Fabric)
		knot.Name = "Knot"
		return
	end
	for _, x in ipairs({ -0.2, 0.2 }) do
		local e = attach(head, model, Vector3.new(0.17, 0.17, 0.1), CFrame.new(x, 0.12, -0.56), rgb(242, 238, 230), M.SmoothPlastic, nil, true)
		e.Name = "Eye"
		attach(head, model, Vector3.new(0.09, 0.09, 0.05), CFrame.new(x, 0.11, -0.6), rgb(40, 26, 18), M.SmoothPlastic, nil, true).Name = "Pupil"
		attach(head, model, Vector3.new(0.24, 0.05, 0.06), CFrame.new(x, 0.29, -0.57) * CFrame.Angles(0, 0, x > 0 and -0.12 or 0.12), look.hairColor:Lerp(Color3.new(), 0.25))
	end
	attach(head, model, Vector3.new(0.09, 0.16, 0.12), CFrame.new(0, -0.02, -0.6), look.skin:Lerp(Color3.new(), 0.06), M.SmoothPlastic, nil, true).Name = "Nose"
	local mouth = attach(head, model, Vector3.new(0.26, 0.05, 0.05), CFrame.new(0, -0.24, -0.57), rgb(110, 45, 42))
	mouth.Name = "Mouth"
	if table.find(look.acc or {}, "beard") then attach(head, model, Vector3.new(1.0, 0.55, 0.6), CFrame.new(0, -0.38, -0.25), look.hairColor, M.Fabric, nil, true) end
end

local function hair(model, look)
	local head = model:FindFirstChild("Head")
	if not head or look.terrorist then return end
	local hc = look.hairColor
	local st = look.hair or 1
	if st == 5 then
		attach(head, model, Vector3.new(1.22, 0.9, 1.22), CFrame.new(0, 0.2, 0.04), hc:Lerp(look.skin, 0.4), M.SmoothPlastic, nil, true)
		return
	end
	attach(head, model, Vector3.new(1.3, 1.0, 1.32), CFrame.new(0, 0.24, 0.06), hc, M.Fabric, nil, true).Name = "Hair"
	if st == 1 then attach(head, model, Vector3.new(1.0, 0.35, 0.6), CFrame.new(0, 0.55, -0.3) * CFrame.Angles(math.rad(-15), 0, 0), hc, M.Fabric, nil, true) end
	if st == 2 then
		for i = 1, 16 do
			local a, b = math.random() * math.pi * 2, math.random() * 1.1
			attach(head, model, Vector3.new(0.42, 0.42, 0.42), CFrame.new(math.cos(a) * math.sin(b) * 0.6, 0.3 + math.cos(b) * 0.45, math.sin(a) * math.sin(b) * 0.6 + 0.05), hc, M.Fabric, Enum.PartType.Ball)
		end
	end
	if st == 3 then
		attach(head, model, Vector3.new(1.35, 1.5, 0.5), CFrame.new(0, -0.35, 0.45), hc, M.Fabric, nil, true)
		for _, x in ipairs({ -0.62, 0.62 }) do attach(head, model, Vector3.new(0.25, 1.2, 0.4), CFrame.new(x, -0.25, 0.05), hc, M.Fabric, nil, true) end
	end
	if st == 4 then
		attach(head, model, Vector3.new(0.4, 0.4, 0.4), CFrame.new(0, 0.3, 0.7), hc, M.Fabric, Enum.PartType.Ball)
		attach(head, model, Vector3.new(0.3, 1.0, 0.3), CFrame.new(0, -0.15, 0.85) * CFrame.Angles(math.rad(15), 0, 0), hc, M.Fabric, nil, true)
	end
end

local function accessories(model, look)
	local head, torso = model:FindFirstChild("Head"), model:FindFirstChild("UpperTorso")
	local acc = look.acc or {}
	local has = function(n) return table.find(acc, n) ~= nil end
	if head then
		if has("cap") then attach(head, model, Vector3.new(1.38, 0.6, 1.4), CFrame.new(0, 0.45, 0.05), look.capColor or look.accent, M.Fabric, nil, true); attach(head, model, Vector3.new(1.0, 0.06, 0.7), CFrame.new(0, 0.4, -0.75), look.capColor or look.accent, M.Fabric) end
		if has("beanie") then attach(head, model, Vector3.new(1.4, 0.95, 1.42), CFrame.new(0, 0.42, 0.05), look.capColor or rgb(217, 72, 59), M.Fabric, nil, true) end
		if has("headband") then attach(head, model, Vector3.new(0.14, 1.34, 1.34), CFrame.new(0, 0.38, 0.04) * CFrame.Angles(0, 0, math.rad(90)), look.accent, M.Fabric, Enum.PartType.Cylinder) end
		if has("flower") then attach(head, model, Vector3.new(0.3, 0.3, 0.15), CFrame.new(0.45, 0.55, -0.3), rgb(255, 111, 176), M.SmoothPlastic, nil, true) end
		if has("glasses") then for _, x in ipairs({ -0.2, 0.2 }) do attach(head, model, Vector3.new(0.05, 0.28, 0.28), CFrame.new(x, 0.12, -0.62) * CFrame.Angles(0, math.rad(90), 0), rgb(15, 15, 15), M.SmoothPlastic, Enum.PartType.Cylinder) end end
	end
	if torso then
		if has("backpack") then
			local pc = look.packColor or rgb(194, 80, 31)
			attach(torso, model, Vector3.new(1.4, 1.7, 0.75), CFrame.new(0, 0, 0.75), pc, M.Fabric)
			attach(torso, model, Vector3.new(1.0, 0.6, 0.25), CFrame.new(0, -0.45, 1.2), pc:Lerp(Color3.new(), 0.2), M.Fabric)
			if has("packLogo") then
				-- סמל כנפיים לבן (מדריך צניחה) – רמז ויזואלי ברור
				for _, r in ipairs({ 0.35, -0.35 }) do attach(torso, model, Vector3.new(0.8, 0.12, 0.05), CFrame.new(0, 0.35, 1.14) * CFrame.Angles(0, 0, r), rgb(242, 233, 208), M.Neon) end
				attach(torso, model, Vector3.new(0.18, 0.18, 0.05), CFrame.new(0, 0.33, 1.15), rgb(242, 233, 208), M.Neon, Enum.PartType.Ball)
			end
		end
		if has("scarf") then attach(torso, model, Vector3.new(1.3, 0.35, 0.9), CFrame.new(0, 0.85, 0), look.accent, M.Fabric, nil, true) end
		if look.terrorist then
			-- אפוד טקטי עם פאוצ'ים
			attach(torso, model, Vector3.new(2.15, 1.7, 1.25), CFrame.new(0, -0.05, 0), rgb(51, 54, 43), M.Fabric)
			for i = -1, 1 do attach(torso, model, Vector3.new(0.45, 0.6, 0.3), CFrame.new(i * 0.55, -0.4, -0.7), rgb(59, 62, 49), M.Fabric) end
		end
	end
	if has("bracelet") then
		local la = model:FindFirstChild("LeftLowerArm")
		if la then
			attach(la, model, Vector3.new(0.12, la.Size.X + 0.12, la.Size.Z + 0.12), CFrame.new(0, -la.Size.Y * 0.4, 0) * CFrame.Angles(0, 0, math.rad(90)), rgb(232, 192, 122), M.Metal, Enum.PartType.Cylinder).Name = "Bracelet"
			local beads = { rgb(255, 107, 139), rgb(74, 199, 255), rgb(255, 210, 90), rgb(255, 255, 255) }
			for i = 0, 7 do
				local a = i / 8 * math.pi * 2
				attach(la, model, Vector3.new(0.14, 0.14, 0.14), CFrame.new(math.cos(a) * (la.Size.X / 2 + 0.07), -la.Size.Y * 0.4, math.sin(a) * (la.Size.Z / 2 + 0.07)), beads[i % 4 + 1], M.SmoothPlastic, Enum.PartType.Ball)
			end
		end
	end
end

--- רובה (ויזואלי בלבד, בלי פירוט טכני)
function NPC.Rifle(model)
	local hand = model:FindFirstChild("RightHand")
	if not hand then return end
	local g = Instance.new("Model")
	g.Name = "Rifle"
	local dark, wood = rgb(28, 29, 31), rgb(74, 58, 40)
	local base = hand.CFrame * CFrame.new(0, -0.25, -0.6)
	local function rp(size, off, col, shape)
		local p = Instance.new("Part")
		p.Size = size; p.Color = col; p.Material = col == wood and M.Wood or M.Metal; p.CanCollide = false; p.Massless = true
		if shape then p.Shape = shape end
		p.CFrame = base * off; p.Parent = g; weld(hand, p)
		return p
	end
	rp(Vector3.new(0.3, 0.35, 2.0), CFrame.new(0, 0, 0), dark)
	rp(Vector3.new(1.9, 0.14, 0.14), CFrame.new(0, 0.05, -1.8) * CFrame.Angles(0, math.rad(90), 0), dark, Enum.PartType.Cylinder).Name = "Muzzle"
	rp(Vector3.new(0.28, 0.32, 1.1), CFrame.new(0, 0, -1.2), wood)
	rp(Vector3.new(0.26, 0.5, 1.2), CFrame.new(0, -0.15, 1.4) * CFrame.Angles(math.rad(-10), 0, 0), wood)
	rp(Vector3.new(0.2, 0.8, 0.35), CFrame.new(0, -0.5, -0.3) * CFrame.Angles(math.rad(-18), 0, 0), dark)
	g.Parent = model
	return g
end

--- יוצר NPC. look = טבלת מראה. opts: { name, anchored, pose, anim }
function NPC.Create(parent, look, cf, opts)
	opts = opts or {}
	local desc = Instance.new("HumanoidDescription")
	desc.HeightScale = look.height or 1
	desc.WidthScale = look.gender == "f" and 0.92 or 1
	desc.DepthScale = look.gender == "f" and 0.92 or 1
	desc.BodyTypeScale = 0.3
	desc.ProportionScale = look.gender == "f" and 0.8 or 0.4
	local ok, model = pcall(function() return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15) end)
	if not ok or not model then warn("NPC create failed", model) return nil end
	model.Name = opts.name or "NPC"
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	for _, st in ipairs({ Enum.HumanoidStateType.Climbing, Enum.HumanoidStateType.Swimming, Enum.HumanoidStateType.Ragdoll, Enum.HumanoidStateType.FallingDown, Enum.HumanoidStateType.Dead }) do hum:SetStateEnabled(st, false) end
	local animScript = model:FindFirstChild("Animate")
	if animScript then animScript:Destroy() end
	if look.terrorist then
		look.top = look.top or rgb(42, 44, 37); look.bottom = look.bottom or rgb(38, 40, 31); look.shoes = rgb(26, 25, 22); look.gloves = rgb(30, 30, 27); look.longSleeve = true; look.shortSleeve = false
	end
	paint(model, look)
	model:PivotTo(cf)
	face(model, look)
	hair(model, look)
	accessories(model, look)
	if look.terrorist and opts.rifle ~= false then NPC.Rifle(model) end
	model:SetAttribute("NPC", true)
	if opts.id then model:SetAttribute("Id", opts.id) end
	model.Parent = parent
	local hrp = model:FindFirstChild("HumanoidRootPart")
	if opts.anchored ~= false then hrp.Anchored = true end
	-- אנימציות
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	local function load(n)
		if tracks[n] then return tracks[n] end
		local a = Instance.new("Animation")
		a.AnimationId = Config.Anim[n]
		local ok2, t = pcall(function() return animator:LoadAnimation(a) end)
		if ok2 then tracks[n] = t end
		return tracks[n]
	end
	local self = { Model = model, Humanoid = hum, Root = hrp, Look = look, Tracks = tracks, Current = nil }
	function self:Play(n, fade, speed)
		if self.Current == n then return end
		for k, t in pairs(tracks) do if k ~= n then t:Stop(fade or 0.25) end end
		self.Current = n
		model:SetAttribute("Pose", "")
		if n then
			local t = load(n)
			if t then t.Looped = true; t:Play(fade or 0.25, 1, speed or 1) end
		end
	end
	function self:Pose(p)
		-- תנוחה ידנית (הלקוח מחיל על Motor6D): cower / crouch / sitGround / handsUp / lying / hug / drum / holdPhoto / aim / sit
		for _, t in pairs(tracks) do t:Stop(0.2) end
		self.Current = "pose:" .. p
		model:SetAttribute("Pose", p)
	end
	function self:MoveTo(pos, run)
		hrp.Anchored = false
		hum.WalkSpeed = run and 20 or 8
		self:Play(run and "Run" or "Walk", 0.2, run and 1.1 or 1)
		hum:MoveTo(pos)
		local done = false
		local conn
		conn = hum.MoveToFinished:Connect(function()
			done = true
			conn:Disconnect()
		end)
		return function() return done end
	end
	function self:WalkPath(points, run, onDone)
		task.spawn(function()
			for _, p in ipairs(points) do
				local isDone = self:MoveTo(p, run)
				local t0 = os.clock()
				while not isDone() and os.clock() - t0 < 25 and model.Parent do task.wait(0.1) end
				if not model.Parent then return end
			end
			self:Play(self.IdleAnim or "Idle")
			if onDone then onDone() end
		end)
	end
	function self:Face(pos)
		local p = hrp.Position
		model:PivotTo(CFrame.lookAt(p, Vector3.new(pos.X, p.Y, pos.Z)))
	end
	function self:Destroy() model:Destroy() end
	if opts.pose then self:Pose(opts.pose) else self:Play(opts.anim or "Idle") end
	self.IdleAnim = opts.anim or "Idle"
	return self
end

--- מחבל
function NPC.Terrorist(parent, cf, opts)
	opts = opts or {}
	local look = { terrorist = true, skin = SKIN[4], hair = 5, hairColor = HAIR[1], gender = "m", acc = {}, height = 1.02 }
	local n = NPC.Create(parent, look, cf, { name = "Terrorist", anchored = opts.anchored, rifle = opts.rifle, anim = "Idle" })
	if n then n.Model:SetAttribute("Terrorist", true) end
	return n
end

-- דמויות קבועות
NPC.Looks = {
	shachar = { skin = SKIN[2], hair = 3, hairColor = HAIR[2], top = rgb(246, 230, 200), bottom = rgb(58, 74, 106), shortSleeve = true, shoes = rgb(233, 228, 218), gender = "f", acc = { "bracelet", "flower" }, accent = rgb(255, 107, 139), height = 0.97 },
	yoni = { skin = SKIN[3], hair = 2, hairColor = HAIR[1], top = rgb(47, 163, 107), bottom = rgb(58, 63, 69), shortSleeve = true, shorts = true, shoes = rgb(40, 40, 40), gender = "m", acc = { "headband" }, accent = rgb(255, 210, 90), height = 1.06 },
	maya = { skin = SKIN[1], hair = 4, hairColor = HAIR[4], top = rgb(255, 79, 139), bottom = rgb(35, 38, 41), shortSleeve = true, shoes = rgb(207, 202, 192), gender = "f", acc = { "glasses", "scarf" }, accent = rgb(57, 224, 255), height = 0.96 },
	esther = { skin = SKIN[2], hair = 4, hairColor = HAIR[7], top = rgb(107, 91, 122), bottom = rgb(58, 58, 58), longSleeve = true, shoes = rgb(40, 40, 40), gender = "f", acc = { "glasses" }, accent = rgb(201, 162, 74), height = 0.95 },
	ido = { skin = SKIN[3], hair = 2, hairColor = HAIR[1], top = rgb(61, 74, 92), bottom = rgb(35, 38, 41), longSleeve = true, shoes = rgb(207, 202, 192), gender = "m", acc = {}, accent = rgb(255, 179, 71), height = 0.93 },
	meir = { skin = SKIN[4], hair = 1, hairColor = HAIR[2], top = rgb(122, 106, 90), bottom = rgb(58, 63, 69), longSleeve = true, shoes = rgb(40, 40, 40), gender = "m", acc = { "beard" }, accent = rgb(255, 255, 255), height = 1.02 },
	zvika = { skin = SKIN[2], hair = 5, hairColor = HAIR[7], top = rgb(232, 85, 31), bottom = rgb(74, 74, 74), longSleeve = true, shoes = rgb(40, 40, 40), gender = "m", acc = { "backpack", "packLogo", "glasses" }, packColor = rgb(232, 85, 31), accent = rgb(255, 255, 255), height = 1.0 },
}

--- מראה לשחקן (לפי בחירה בלובי)
function NPC.PlayerLook(plr)
	local skin = SKIN[plr:GetAttribute("Skin") or 3] or SKIN[3]
	local out = OUT[plr:GetAttribute("Outfit") or 1] or OUT[1]
	return {
		skin = skin, hair = plr:GetAttribute("Hair") or 1, hairColor = HAIR[plr:GetAttribute("HairColor") or 2] or HAIR[2],
		top = out[1], bottom = out[2], shortSleeve = out[3], shoes = rgb(60, 60, 60), gender = plr:GetAttribute("Gender") or "m",
		acc = plr:GetAttribute("Bracelet") and { "bracelet" } or {}, accent = rgb(255, 179, 92),
	}
end

--- מחיל את המראה על הדמות של השחקן (אם לא בחר להשתמש באוואטר שלו)
function NPC.ApplyToPlayer(plr)
	local char = plr.Character
	if not char then return end
	local look = NPC.PlayerLook(plr)
	if plr:GetAttribute("UseAvatar") then
		if plr:GetAttribute("Bracelet") then accessories(char, { acc = { "bracelet" } }) end
		return
	end
	for _, d in ipairs(char:GetChildren()) do
		if d:IsA("Accessory") or d:IsA("Shirt") or d:IsA("Pants") or d:IsA("ShirtGraphic") or d:IsA("CharacterMesh") then d:Destroy() end
		if d:IsA("BasePart") and d.Name:match("^Cosmetic") then d:Destroy() end
	end
	paint(char, look)
	for _, p in ipairs(char:GetChildren()) do if p:IsA("BasePart") and p:GetAttribute("Cosmetic") then p:Destroy() end end
	local before = {}
	for _, p in ipairs(char:GetChildren()) do before[p] = true end
	face(char, look)
	hair(char, look)
	accessories(char, look)
	for _, p in ipairs(char:GetChildren()) do if not before[p] and p:IsA("BasePart") then p:SetAttribute("Cosmetic", true) end end
end

return NPC
