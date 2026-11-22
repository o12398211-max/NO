-- ═══════════════════════════════════════════════════════════════════
--  Story – מכונת המצבים של העלילה בצד השרת (סמכותית): בניית מפות, NPC, דגלים משותפים,
--  צ'קפוינטים, כישלון/חזרה, תפיסה, ומעברי פרקים מסונכרנים לכל השחקנים
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local NPC = require(script.Parent.NPC)
local Enemies = require(script.Parent.Enemies)
local Vehicles = require(script.Parent.Vehicles)
local Festival = require(script.Parent.World.Festival)
local Maps = require(script.Parent.World.Maps)
local B = require(script.Parent.World.Build)

local S = {}
S.Chapter = 0
S.Checkpoint = nil
S.Flags = {}
S.Running = false
S.Gen = 0 -- מונה דורות: כל טעינה מבטלת תהליכים ישנים
S.NPCs = {}
S.Data = {}
S.Score = {}
local Remotes

local function alive(gen) return S.Gen == gen end
local function storyPlayers()
	local t = {}
	for _, p in ipairs(Players:GetPlayers()) do if p:GetAttribute("InStory") then table.insert(t, p) end end
	return t
end
S.storyPlayers = storyPlayers
local function allFlag(flag)
	for _, p in ipairs(storyPlayers()) do if not p:GetAttribute(flag) then return false end end
	return true
end
local function anyFlag(flag)
	for _, p in ipairs(storyPlayers()) do if p:GetAttribute(flag) then return true end end
	return false
end
local function waitUntil(gen, fn, timeout)
	local t0 = os.clock()
	while alive(gen) and not fn() and os.clock() - t0 < (timeout or 1e9) do task.wait(0.2) end
	return alive(gen)
end
local function teleport(plr, pos, look)
	local char = plr.Character
	if not char or not char:FindFirstChild("HumanoidRootPart") then return end
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum and hum.SeatPart then hum.Sit = false; task.wait() end
	local cf = look and CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z)) or CFrame.new(pos)
	char:PivotTo(cf + Vector3.new(0, 3, 0))
end
S.teleport = teleport
local function ev(name, ...) Remotes.Story:FireAllClients(name, ...) end
local function evTo(plr, name, ...) Remotes.Story:FireClient(plr, name, ...) end
S.ev = ev

-- ─────────────── ניקוי וטעינה ───────────────
function S.Clear()
	S.Gen += 1
	Enemies.Mode = "off"
	Enemies.Clear()
	Vehicles.Clear()
	for _, n in pairs(S.NPCs) do if type(n) == "table" and n.Destroy then pcall(function() n:Destroy() end) end end
	S.NPCs = {}
	local map = workspace:FindFirstChild("Map")
	if map then map:Destroy() end
	workspace.Terrain:Clear()
	S.Flags = {}
	S.Pipes = nil
	for _, p in ipairs(Players:GetPlayers()) do
		for _, a in ipairs({ "Danger", "Capturing", "Captured", "Hidden", "Asleep", "Done", "Kills", "HasGun", "Protected", "Exited", "Caught", "Awake" }) do p:SetAttribute(a, nil) end
	end
end

function S.Load(n, cp)
	ev("transition", n)
	S.Clear()
	local gen = S.Gen
	S.Chapter = n
	S.Checkpoint = cp
	S.Running = true
	local map = Instance.new("Folder"); map.Name = "Map"; map.Parent = workspace
	S.Map = map
	for _, p in ipairs(Players:GetPlayers()) do
		if p:GetAttribute("InStory") then
			p:SetAttribute("Chapter", n)
			S.Score[p.UserId] = S.Score[p.UserId] or { time = 0, puzzles = 0, chapter = n }
			S.Score[p.UserId].chapter = n
		end
	end
	S.ChapterStart = os.clock()
	local fn = S["Ch" .. n]
	task.spawn(function()
		local ok, err = pcall(fn, gen, cp)
		if not ok then warn("[Story] chapter " .. n .. " error: " .. tostring(err)) end
	end)
	S.PushScore()
end

function S.Next(n, cp)
	local dt = os.clock() - (S.ChapterStart or os.clock())
	for _, p in ipairs(storyPlayers()) do
		local sc = S.Score[p.UserId]; if sc then sc.time += dt end
	end
	task.wait(0.2)
	if n > 6 then S.End() return end
	S.Load(n, cp)
end

function S.End()
	S.Clear()
	S.Running = false
	S.Chapter = 0
	for _, p in ipairs(Players:GetPlayers()) do
		p:SetAttribute("InStory", nil)
		p:SetAttribute("Chapter", 0)
	end
	ev("lobby")
	if S.OnEnd then S.OnEnd() end
end

function S.PushScore()
	local rows = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local sc = S.Score[p.UserId]
		if sc then table.insert(rows, { name = p:GetAttribute("CharName") or p.DisplayName, time = sc.time, puzzles = sc.puzzles, chapter = sc.chapter }) end
	end
	Remotes.Score:FireAllClients(rows)
end
function S.AddPuzzle(p)
	local sc = S.Score[p.UserId]
	if sc then sc.puzzles += 1; S.PushScore() end
end

-- ─────────────── כישלון וחזרה לצ'קפוינט (בלי טקסט) ───────────────
function S.Fail(plr)
	if plr:GetAttribute("Failing") or plr:GetAttribute("God") then return end
	plr:SetAttribute("Failing", true)
	evTo(plr, "fail")
	task.delay(Config.RespawnDelay, function()
		plr:SetAttribute("Failing", nil)
		plr:SetAttribute("Danger", 0)
		local spot = S.Data.Respawn and S.Data.Respawn(plr)
		if spot then teleport(plr, spot.pos, spot.look) end
		evTo(plr, "respawn", S.Checkpoint)
	end)
end
Enemies.OnFail = function(plr) S.Fail(plr) end

-- ─────────────── NPC עם הנחיה (ProximityPrompt) ───────────────
local function prompt(part, action, id, opts)
	opts = opts or {}
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = action
	pp.ObjectText = opts.object or ""
	pp.KeyboardKeyCode = opts.key or Enum.KeyCode.E
	pp.HoldDuration = opts.hold or 0
	pp.MaxActivationDistance = opts.dist or 9
	pp.RequiresLineOfSight = false
	pp.Style = Enum.ProximityPromptStyle.Custom
	pp.Enabled = opts.enabled ~= false
	pp:SetAttribute("Id", id)
	pp.Parent = part
	return pp
end
S.prompt = prompt
local function npc(key, look, cf, opts)
	local n = NPC.Create(S.Map, look, cf, opts)
	if n then S.NPCs[key] = n end
	return n
end
local function talkPrompt(n, id, action, opts)
	if not n then return end
	return prompt(n.Model:FindFirstChild("Head") or n.Root, action or "לדבר", id, opts)
end

-- ═══════════════════════ פרק 1 – המסיבה ═══════════════════════
function S.Ch1(gen, cp)
	local o = Config.Origins.Festival
	local m, d = Festival.Build(S.Map, o, false)
	local L = Festival.L
	local g = function(v) return Vector3.new(o.X + v.X, Festival.ground(Vector3.zero, o + v) + 3, o.Z + v.Z) end
	S.Data = d
	local dance = o + L.Dance
	-- חברים
	local yoni = npc("yoni", NPC.Looks.yoni, CFrame.new(g(L.Dance + Vector3.new(-16, 0, 12))) * CFrame.Angles(0, math.pi, 0), { anim = "Dance2" })
	local maya = npc("maya", NPC.Looks.maya, CFrame.new(g(L.Dance + Vector3.new(-12, 0, 14))) * CFrame.Angles(0, math.pi + 0.5, 0), { anim = "Dance3" })
	local shachar = npc("shachar", NPC.Looks.shachar, CFrame.new(g(L.Rocks + Vector3.new(-3, 0, 4))) * CFrame.Angles(0, math.rad(-90), 0), { pose = "sitGround" })
	local dj = npc("dj", { skin = Config.Skin[3], hair = 5, hairColor = Config.HairColors[1], top = Color3.fromRGB(17, 17, 17), bottom = Color3.fromRGB(34, 34, 34), shoes = Color3.fromRGB(17, 17, 17), gender = "m", acc = { "cap" }, capColor = Color3.fromRGB(17, 17, 17), accent = Color3.fromRGB(255, 46, 136) }, CFrame.new(o + L.Stage + Vector3.new(0, 6.2, 1.5)), { anim = "Dance1" })
	if d.Backstage then
		local bouncer = npc("bouncer", { skin = Config.Skin[5], hair = 5, hairColor = Config.HairColors[1], top = Color3.fromRGB(15, 15, 15), bottom = Color3.fromRGB(20, 20, 20), longSleeve = true, shoes = Color3.fromRGB(15, 15, 15), gender = "m", acc = { "glasses" }, accent = Color3.new(1, 1, 1), height = 1.12 }, CFrame.new(d.Backstage + Vector3.new(8, 3, 19)) * CFrame.Angles(0, math.pi, 0), { anim = "Idle" })
	end
	local bartender = npc("bartender", NPC.RandomLook(11), CFrame.new(g(L.Bar + Vector3.new(-3, 0, 0))) * CFrame.Angles(0, math.rad(-90), 0), { anim = "Idle" })
	local drummer = npc("drummer", NPC.RandomLook(13), CFrame.new(g(L.Drums + Vector3.new(9, -1.2, 0))) * CFrame.Angles(0, math.rad(90), 0), { pose = "drum" })
	for i = 1, 5 do
		local a = i / 6 * math.pi * 2 + 0.6
		local p = g(L.Drums + Vector3.new(math.cos(a) * 9, 0, math.sin(a) * 9)) - Vector3.new(0, 1.2, 0)
		npc("drum" .. i, NPC.RandomLook(40 + i), CFrame.lookAt(p, o + L.Drums + Vector3.new(0, p.Y - o.Y, 0)), { pose = "drum" })
	end
	local medic = npc("medic", NPC.RandomLook(17), CFrame.new(g(L.Medic + Vector3.new(3, 0, 4))) * CFrame.Angles(0, math.pi, 0), { anim = "Idle" })
	local strangers = {}
	for i, s in ipairs({ { L.Chill + Vector3.new(-6, -1.2, 3), "sitGround" }, { L.Chill + Vector3.new(6, -1.2, -3), "sitGround" }, { L.Dance + Vector3.new(38, 0, 22), nil }, { L.Dance + Vector3.new(-40, 0, -6), nil } }) do
		strangers[i] = npc("stranger" .. i, NPC.RandomLook(60 + i), CFrame.new(g(s[1])) * CFrame.Angles(0, math.random() * 6, 0), { pose = s[2], anim = "Dance" .. ((i % 3) + 1) })
	end
	-- רוקדים: כל אחד ריקוד אחר (שלוש אנימציות × מהירות × היסט + סגנונות פרוצדורליים)
	local dancers = {}
	for i = 1, 64 do
		local x, z = math.random(-60, 60), math.random(-30, 34)
		if (Vector3.new(x, 0, z) - Vector3.new(-14, 0, 13)).Magnitude > 7 then
			local n = NPC.Create(S.Map, NPC.RandomLook(100 + i), CFrame.new(g(L.Dance + Vector3.new(x, 0, z))) * CFrame.Angles(0, math.pi + math.random(-40, 40) / 100, 0), { anim = "Idle" })
			if n then
				local style = math.random(1, 7)
				if style <= 3 then
					n:Play("Dance" .. style, 0.4, 0.8 + math.random() * 0.45)
					local tr = n.Tracks["Dance" .. style]
					if tr then task.delay(0.1, function() pcall(function() tr.TimePosition = math.random() * 3 end) end) end
				else
					n:Pose(({ "danceArms", "danceSway", "danceJump", "danceStomp" })[style - 3])
				end
				n.Model:SetAttribute("DancePhase", math.random() * 10)
				n.Model:SetAttribute("DanceSpeed", 0.85 + math.random() * 0.35)
				table.insert(dancers, n)
				-- מדי פעם: צהלה / נפנוף
				if math.random() < 0.35 then
					task.spawn(function()
						while alive(gen) and n.Model.Parent do
							task.wait(8 + math.random() * 14)
							if not alive(gen) or S.Flags.disperse then break end
							local prev = n.Current
							n:Play(math.random() < 0.6 and "Cheer" or "Wave", 0.3)
							task.wait(2.5)
							if S.Flags.disperse then break end
							if prev and prev:sub(1, 5) == "pose:" then n:Pose(prev:sub(6)) elseif prev then n:Play(prev, 0.4) end
						end
					end)
				end
			end
		end
	end
	S.NPCs.dancers = dancers
	for i = 1, 6 do npc("chill" .. i, NPC.RandomLook(220 + i), CFrame.new(g(L.Chill + Vector3.new(-12 + i * 4, -1.2, (i % 2) * 8 - 2))) * CFrame.Angles(0, math.random() * 6, 0), { pose = "sitGround" }) end
	-- משוטטים
	for i = 1, 8 do
		local w = npc("wander" .. i, NPC.RandomLook(300 + i), CFrame.new(g(Vector3.new(math.random(-150, 150), 0, math.random(-60, 120)))), { anim = "Idle", anchored = false })
		if w then task.spawn(function()
			while alive(gen) and w.Model.Parent do
				w:MoveTo(g(Vector3.new(math.random(-150, 150), 0, math.random(-60, 120))))
				task.wait(10 + math.random() * 10)
			end
		end) end
	end
	-- הנחיות שיחה
	talkPrompt(yoni, "yoni_hello"); talkPrompt(maya, "maya_talk"); talkPrompt(bartender, "bartender"); talkPrompt(drummer, "drummer")
	talkPrompt(dj, "dj", "לדבר", { dist = 14 }); talkPrompt(medic, "medic"); talkPrompt(shachar, "shachar_main", "לדבר", { enabled = true })
	for i, s in ipairs(strangers) do talkPrompt(s, "stranger" .. i) end
	prompt(maya.Model.Head, "סלפי", "selfie", { key = Enum.KeyCode.F, object = "מאיה" })
	local sleepPart = B.part(S.Map, Vector3.new(4, 1, 4), CFrame.new(d.SleepSpot), Color3.new(), Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "SleepSpot" })
	prompt(sleepPart, "לישון", "sleep", { enabled = false, dist = 10 })
	-- נקודות ייחוס ללקוח
	S.Data.Respawn = function() return { pos = g(L.Spawn), look = dance } end
	local payload = { origin = o, dance = dance, stage = o + L.Stage, rocks = o + L.Rocks, tent = o + L.OurTent, sleep = d.SleepSpot, spawn = g(L.Spawn), led = d.Stage.LED, heads = d.Stage.Heads, lasers = d.Stage.Lasers, cp = cp }
	for _, p in ipairs(storyPlayers()) do teleport(p, g(L.Spawn + Vector3.new(math.random(-6, 6), 0, math.random(-3, 3))), dance) end
	Remotes.Chapter:FireAllClients(1, cp, payload)
	-- ─ ציר זמן: פתיחה → ~45 שניות חופשי (שחר מגיעה אם לא נמצאה) → פיזור → אוהל → שינה
	if cp ~= "tent" then
		waitUntil(gen, function() return allFlag("Awake") end, cp and 3 or 40)
		local tFree = os.clock()
		waitUntil(gen, function() return os.clock() - tFree > 20 or allFlag("Bracelet") end)
		if not alive(gen) then return end
		if not allFlag("Bracelet") then
			-- שחר מגיעה בעצמה אל מי שעוד לא קיבל צמיד
			local target
			for _, p in ipairs(storyPlayers()) do if not p:GetAttribute("Bracelet") and p.Character then target = p break end end
			if target then
				shachar:Play("Idle")
				local tp = target.Character.HumanoidRootPart.Position
				shachar:WalkPath({ tp + (shachar.Root.Position - tp).Unit * 5 }, false, function() shachar:Face(tp) end)
				ev("shacharComes", target.UserId)
			end
		end
		waitUntil(gen, function() return (os.clock() - tFree > 45 and allFlag("Bracelet")) or os.clock() - tFree > 70 end)
		if not alive(gen) then return end
	end
	-- ─ פיזור ─
	S.Flags.disperse = true
	ev("disperse")
	for i, n in ipairs(dancers) do
		task.delay(i * 0.15, function()
			if not alive(gen) or not n.Model.Parent then return end
			local tgt = i % 3 == 0 and g(L.Parking + Vector3.new(math.random(-90, 90), 0, math.random(-100, 100))) or g(L.Camp + Vector3.new(math.random(-80, 80), 0, math.random(-40, 40)))
			n:WalkPath({ tgt }, false, function() if math.random() < 0.5 then n:Pose("sitGround") end end)
		end)
	end
	task.wait(1)
	local gather = storyPlayers()[1] and storyPlayers()[1].Character and storyPlayers()[1].Character.HumanoidRootPart.Position or dance
	for i, n in ipairs({ yoni, maya, shachar }) do n:Play("Idle"); n:WalkPath({ gather + Vector3.new((i - 2) * 4, 0, -7) }) end
	task.wait(6)
	if not alive(gen) then return end
	ev("tentTime")
	task.wait(10)
	shachar:WalkPath({ g(L.Parking + Vector3.new(60, 0, -40)) })
	local door = o + L.OurTent + Vector3.new(0, 0, -10)
	yoni:WalkPath({ g(L.OurTent + Vector3.new(-3, 0, -10)), g(L.OurTent + Vector3.new(-3, 0, 0)) }, false, function() yoni:Pose("lying") end)
	maya:WalkPath({ g(L.OurTent + Vector3.new(3, 0, -10)), g(L.OurTent + Vector3.new(0, 0, 1)) }, false, function() maya:Pose("sitGround") end)
	sleepPart:FindFirstChildOfClass("ProximityPrompt").Enabled = true
	S.Data.Respawn = function() return { pos = door + Vector3.new(0, 3, -8), look = o + L.OurTent } end
	-- ─ שינה: כשכולם ישנים (או 40 שניות אחרי הראשון) → פרק 2
	waitUntil(gen, function() return anyFlag("Asleep") end)
	waitUntil(gen, function() return allFlag("Asleep") end, 40)
	if alive(gen) then task.wait(5); S.Next(2) end
end

-- ═══════════════════════ פרק 2 – הבוקר, הבריחה והתפיסה ═══════════════════════
function S.Ch2(gen, cp)
	local o = Config.Origins.Festival
	local m, d = Festival.Build(S.Map, o, true)
	local L = Festival.L
	local g = function(v) return Vector3.new(o.X + v.X, Festival.ground(Vector3.zero, o + v) + 3, o.Z + v.Z) end
	S.Data = d
	for _, car in ipairs(d.Cars) do
		if car:FindFirstChild("DriveSeat") and not car.DriveSeat.Disabled then Vehicles.MakeDrivable(car) end
	end
	local yoni = npc("yoni", NPC.Looks.yoni, CFrame.new(g(L.OurTent + Vector3.new(-3, -1.5, 1))), { pose = "crouch" })
	local maya = npc("maya", NPC.Looks.maya, CFrame.new(g(L.OurTent + Vector3.new(3, -1.5, 2))), { pose = "cower" })
	-- מחבלים: מתקדמים מהמערב ומהצפון, יורים במטחים
	local paths = {
		{ g(Vector3.new(-280, 0, 50)), g(Vector3.new(-160, 0, 90)), g(Vector3.new(-60, 0, 120)) },
		{ g(Vector3.new(-270, 0, 75)), g(Vector3.new(-150, 0, 130)), g(Vector3.new(-40, 0, 160)) },
		{ g(Vector3.new(-250, 0, 30)), g(Vector3.new(-120, 0, 60)), g(Vector3.new(-30, 0, 90)) },
		{ g(Vector3.new(-120, 0, -130)), g(Vector3.new(-50, 0, -60)), g(Vector3.new(0, 0, 20)) },
		{ g(Vector3.new(-90, 0, -150)), g(Vector3.new(-20, 0, -80)), g(Vector3.new(40, 0, 10)) },
		{ g(Vector3.new(-300, 0, 150)), g(Vector3.new(-180, 0, 200)), g(Vector3.new(-80, 0, 230)) },
	}
	local function spawnWave()
		for _, path in ipairs(paths) do Enemies.Spawn(S.Map, CFrame.new(path[1]), { mode = "advance", path = path, range = 170, speed = 5 }) end
	end
	local escapeStart = g(L.OurTent + Vector3.new(0, 0, -14))
	S.Data.Respawn = function(plr)
		if plr:GetAttribute("HasGun") and plr:GetAttribute("GunSpot") then return { pos = plr:GetAttribute("GunSpot"), look = o } end
		return { pos = escapeStart, look = o + Vector3.new(200, 0, 160) }
	end
	local payload = { origin = o, tent = o + L.OurTent, sleep = d.SleepSpot, escape = escapeStart, orchard = d.Zones.Orchard, ditch = d.Zones.Ditch, shelter = d.ShelterZone, parking = o + L.Parking, cp = cp }
	for _, p in ipairs(storyPlayers()) do
		if cp then teleport(p, escapeStart + Vector3.new(math.random(-4, 4), 0, 0), o) else teleport(p, d.SleepSpot + Vector3.new(math.random(-2, 2), 0, 0), o + L.OurTent + Vector3.new(0, 0, -10)) end
	end
	Remotes.Chapter:FireAllClients(2, cp, payload)
	-- ─ התעוררות (קאטסין בלקוח) ─
	if not cp then waitUntil(gen, function() return allFlag("Awake") end, 30) end
	if not alive(gen) then return end
	S.Checkpoint = "escape"
	yoni:WalkPath({ g(L.Parking + Vector3.new(60, 0, 0)) }, true, function() yoni.Model:Destroy() end)
	maya:WalkPath({ g(L.Parking + Vector3.new(66, 0, 10)) }, true, function() maya.Model:Destroy() end)
	Enemies.Mode = "escape"
	spawnWave()
	ev("escape")
	-- ─ לכל שחקן: חפירה → אקדח → 3 מחבלים → האקדח עף → חלון מוגן → תפיסה ─
	S.Kills = {}
	S.Targets = {}
	task.spawn(function()
		while alive(gen) do
			for _, p in ipairs(storyPlayers()) do
				local char = p.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if hrp and not p:GetAttribute("Capturing") and not p:GetAttribute("Captured") then
					local pos = hrp.Position
					local protectedUntil = p:GetAttribute("Protected") or 0
					local free = p:GetAttribute("GunLost") and os.clock() > protectedUntil
					if p:GetAttribute("Protected") and os.clock() < protectedUntil then p:SetAttribute("Danger", math.min(p:GetAttribute("Danger") or 0, 0.85)) end
					-- מסתור
					local hidden = false
					if p:GetAttribute("Crouch") then
						for _, b in ipairs(d.Bushes) do if (b:GetPivot().Position - pos).Magnitude < 5 then hidden = true break end end
					end
					local sz = d.ShelterZone
					local inShelter = math.abs(pos.X - sz.Center.X) < sz.Size.X / 2 and math.abs(pos.Z - sz.Center.Z) < sz.Size.Z / 2
					p:SetAttribute("Hidden", hidden or inShelter)
					if hidden or inShelter then p:SetAttribute("HideT", (p:GetAttribute("HideT") or 0) + 0.5) else p:SetAttribute("HideT", math.max(0, (p:GetAttribute("HideT") or 0) - 1)) end
					local hum = char:FindFirstChildOfClass("Humanoid")
					local driving = hum and hum.SeatPart and hum.SeatPart:IsA("VehicleSeat")
					p:SetAttribute("Driving", driving or nil)
					p:SetAttribute("Fast", driving and hrp.AssemblyLinearVelocity.Magnitude > 30 or nil)
					if free then
						local function inZone(z) return math.abs(pos.X - z.Center.X) < z.Size.X / 2 and math.abs(pos.Z - z.Center.Z) < z.Size.Z / 2 end
						local route
						if driving and ((pos - escapeStart).Magnitude > 260 or pos.X - o.X > 200) then route = "car"
						elseif (p:GetAttribute("HideT") or 0) > 18 then route = "hide"
						elseif inZone(d.Zones.Orchard) or inZone(d.Zones.Ditch) or (pos - escapeStart).Magnitude > 380 then route = "foot"
						elseif os.clock() - protectedUntil > 100 then route = driving and "car" or (hidden and "hide" or "foot") end
						if route then
							p:SetAttribute("Capturing", true)
							if driving then
								local car = hum.SeatPart.Parent
								car:SetAttribute("Disabled", true)
							end
							evTo(p, "capture", route)
						end
					end
				end
			end
			task.wait(0.5)
		end
	end)
	-- כשכולם נתפסו → פרק 3
	waitUntil(gen, function() return #storyPlayers() > 0 and allFlag("Captured") end)
	if alive(gen) then S.Next(3) end
end

--- האקדח מהחול: שלושה מחבלים שמתקרבים לשחקן הזה
function S.SpawnTargets(plr)
	if S.Chapter ~= 2 or plr:GetAttribute("HasGun") then return end
	plr:SetAttribute("HasGun", true)
	plr:SetAttribute("Kills", 0)
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	plr:SetAttribute("GunSpot", hrp.Position)
	local base = hrp.CFrame
	S.Targets[plr] = {}
	for i = 1, 3 do
		local off = base * CFrame.new((i - 2) * 22, 0, -45 - i * 8)
		local p = Vector3.new(off.X, Festival.ground(Vector3.zero, off.Position) + 3, off.Z)
		local e = Enemies.Spawn(S.Map, CFrame.lookAt(p, hrp.Position), { mode = "advance", path = { hrp.Position + Vector3.new((i - 2) * 10, 0, 0) }, range = 120, speed = 3.5 })
		if e then e.N.Model:SetAttribute("TargetOf", plr.UserId); table.insert(S.Targets[plr], e) end
	end
	evTo(plr, "targets", #S.Targets[plr])
end

--- ירי של השחקן (פרק 2 – אקדח מהחול). השרת מאמת ופוגע במחבל (לא גרפי: נופל וזהו)
function S.Shoot(plr, origin, dir)
	if S.Chapter ~= 2 or not plr:GetAttribute("HasGun") or plr:GetAttribute("GunLost") then return end
	local char = plr.Character
	local head = char and char:FindFirstChild("Head")
	if not head or typeof(origin) ~= "Vector3" or typeof(dir) ~= "Vector3" then return end
	if (origin - head.Position).Magnitude > 8 then return end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local r = workspace:Raycast(origin, dir.Unit * 400, params)
	Remotes.Fx:FireAllClients("pshot", origin, r and r.Position or origin + dir.Unit * 400, plr.UserId)
	if not r then return end
	local model = r.Instance:FindFirstAncestorOfClass("Model")
	while model and not model:GetAttribute("Terrorist") and model.Parent ~= workspace do model = model.Parent:FindFirstAncestorOfClass("Model") end
	if model and model:GetAttribute("Terrorist") and not model:GetAttribute("Down") then
		model:SetAttribute("Down", true)
		for _, e in ipairs(Enemies.List) do if e.N.Model == model then e.Active = false; e.N.Humanoid:MoveTo(e.N.Root.Position); e.N.Root.Anchored = true; e.N:Pose("down") end end
		local k = (plr:GetAttribute("Kills") or 0) + 1
		plr:SetAttribute("Kills", k)
		Remotes.Fx:FireAllClients("down", model)
		task.delay(6, function() if model.Parent then model:Destroy() end end)
		local need = 3
		if k >= need then
			plr:SetAttribute("GunLost", true)
			task.delay(0.8, function()
				evTo(plr, "gunLost")
				plr:SetAttribute("Protected", os.clock() + 70)
				S.AddPuzzle(plr)
			end)
		end
	end
end

-- ═══════════════════════ פרק 3 – המנהרה ═══════════════════════
function S.Ch3(gen, cp)
	local o = Config.Origins.Tunnel
	local m, d = Maps.Tunnel(S.Map, o)
	S.Data = d
	local esther = npc("esther", NPC.Looks.esther, d.Cell * CFrame.new(-5, 2.2, 3) * CFrame.Angles(0, math.pi, 0), { pose = "sitGround" })
	local ido = npc("ido", NPC.Looks.ido, d.Cell * CFrame.new(5, 2.2, 3) * CFrame.Angles(0, math.pi, 0), { pose = "sitGround" })
	local meir = npc("meir", NPC.Looks.meir, d.Cell * CFrame.new(0, 2.2, 7) * CFrame.Angles(0, math.pi, 0), { pose = "holdPhoto" })
	local knock = B.part(S.Map, Vector3.new(1, 3, 3), CFrame.new(d.Knock), Color3.new(), Enum.Material.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "KnockSpot" })
	prompt(knock, "להקשיב לקיר", "knock", { dist = 10 })
	talkPrompt(meir, "meir", "לדבר עם מאיר", { enabled = false })
	talkPrompt(ido, "ido", "לתכנן עם עידו", { enabled = false })
	for i, pipe in ipairs(d.Pipes) do prompt(pipe, "לנגן על הצינור", "pipe" .. i, { enabled = false, dist = 8 }) end
	local grate = S.Map:FindFirstChild("Tunnel"):FindFirstChild("Grate")
	prompt(grate, "לפתוח את הסורג", "grate", { enabled = false, hold = 2, dist = 8 })
	S.Data.Respawn = function()
		if S.Flags.sneak then return { pos = (d.Corridor * CFrame.new(0, 3, 55)).Position, look = d.Grate } end
		return { pos = d.Spawn, look = d.Knock }
	end
	for _, p in ipairs(storyPlayers()) do teleport(p, d.Spawn + Vector3.new(math.random(-4, 4), 0, math.random(-2, 2)), d.Knock) end
	local payload = { spawn = d.Spawn, knock = d.Knock, pipes = { d.Pipes[1].Position, d.Pipes[2].Position }, grate = d.Grate, exit = d.Exit, lure = d.Lure, cell = d.Cell.Position, cp = cp }
	Remotes.Chapter:FireAllClients(3, cp, payload)
	S.Flags3 = { decoded = cp ~= nil, tool = cp ~= nil, pipes = cp == "sneak" }
	local function setFlag(k)
		S.Flags[k] = true
		ev("flag3", k)
	end
	S.SetFlag3 = setFlag
	if cp == "sneak" then S.Flags.decoded = true; S.Flags.tool = true; S.Flags.sneak = true end
	waitUntil(gen, function() return S.Flags.decoded end)
	if not alive(gen) then return end
	meir.Model.Head:FindFirstChildOfClass("ProximityPrompt").Enabled = true
	waitUntil(gen, function() return S.Flags.tool end)
	if not alive(gen) then return end
	ido.Model.Head:FindFirstChildOfClass("ProximityPrompt").Enabled = true
	waitUntil(gen, function() return S.Flags.plan end, cp and 1 or nil)
	for _, pipe in ipairs(d.Pipes) do pipe:FindFirstChildOfClass("ProximityPrompt").Enabled = true end
	-- שומרים עם פנסים
	local g1 = Enemies.Spawn(S.Map, CFrame.new(d.GuardPath1[1]), { mode = "patrol", path = d.GuardPath1, flashlight = true, range = 38, fov = 30, speed = 5 })
	local g2 = Enemies.Spawn(S.Map, CFrame.new(d.GuardPath2[1]), { mode = "patrol", path = d.GuardPath2, flashlight = true, range = 38, fov = 30, speed = 5 })
	Enemies.Mode = "tunnel"
	-- הסחה בשיתוף פעולה: שני צינורות. שחקן יחיד – עידו מנגן על השני.
	waitUntil(gen, function() return S.Flags.pipes end)
	if not alive(gen) then return end
	-- השומרים הולכים אחרי ההד
	for _, e in ipairs({ g1, g2 }) do if e then e.Opts.path = { d.Lure, d.Lure + Vector3.new(0, 0, 4) } e.Opts.fov = 18 end end
	ido:Pose("drum")
	setFlag("sneak")
	S.Checkpoint = "sneak"
	grate:FindFirstChildOfClass("ProximityPrompt").Enabled = true
	-- אחרי 50 שניות השומרים חוזרים לסיור
	task.delay(50, function() if alive(gen) then for _, e in ipairs({ g1, g2 }) do if e then e.Opts.path = d.GuardPath2; e.Opts.fov = 30 end end end end)
	waitUntil(gen, function() return anyFlag("Exited") end)
	waitUntil(gen, function() return allFlag("Exited") end, 60)
	if alive(gen) then task.wait(2); S.Next(4) end
end

-- ═══════════════════════ פרק 4 – בחוץ ═══════════════════════
function S.Ch4(gen, cp)
	local o = Config.Origins.Outside
	local m, d = Maps.Outside(S.Map, o)
	S.Data = d
	for _, c in ipairs(d.Cars) do Vehicles.MakeDrivable(c) end
	prompt(d.Map, "להסתכל על המפה", "map", { dist = 9 })
	for _, path in ipairs(d.PatrolPaths) do Enemies.Spawn(S.Map, CFrame.new(path[1]), { mode = "patrol", path = path, flashlight = true, range = 70, fov = 38, speed = 6 }) end
	Enemies.Mode = "outside"
	S.Data.Respawn = function() return { pos = d.Spawn, look = d.Goal } end
	for _, p in ipairs(storyPlayers()) do teleport(p, d.Spawn + Vector3.new(math.random(-3, 3), 0, 0), d.Map.Position) end
	Remotes.Chapter:FireAllClients(4, cp, { spawn = d.Spawn, map = d.Map.Position, goal = d.Goal, origin = o, cp = cp })
	-- פנסי רכב דולקים = מסגירים
	task.spawn(function()
		while alive(gen) do
			for _, car in ipairs(Vehicles.Active) do
				if car.LightsOn then
					for _, e in ipairs(Enemies.List) do
						if (e.N.Root.Position - car.Chassis.Position).Magnitude < 140 and car.Seat.Occupant then
							local plr = Players:GetPlayerFromCharacter(car.Seat.Occupant.Parent)
							if plr then S.Fail(plr) end
						end
					end
				end
			end
			-- הגעה ליעד → תפיסה מפתיעה
			for _, p in ipairs(storyPlayers()) do
				local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if hrp and not p:GetAttribute("Capturing") and (Vector3.new(hrp.Position.X, 0, hrp.Position.Z) - Vector3.new(d.Goal.X, 0, d.Goal.Z)).Magnitude < 45 then
					p:SetAttribute("Capturing", true)
					local hum = p.Character:FindFirstChildOfClass("Humanoid")
					if hum and hum.SeatPart then hum.SeatPart.Parent:SetAttribute("Disabled", true) end
					evTo(p, "surprise")
				end
			end
			task.wait(0.5)
		end
	end)
	waitUntil(gen, function() return #storyPlayers() > 0 and allFlag("Captured") end)
	if alive(gen) then S.Next(5) end
end

-- ═══════════════════════ פרק 5 – המטוס ═══════════════════════
local function buildCabin(gen, chapter)
	local o = Config.Origins.Plane
	local m, d = Maps.Plane(S.Map, o)
	S.Data = d
	-- נוסעים (מגוונים), שחר בשורה 3, צביקה בשורה 8
	local players = storyPlayers()
	local seatsFor = {}
	local used = {}
	for i, p in ipairs(players) do
		local idx = (3 + i) * 4 + 3 -- מושב מעבר ימני בשורות 4–11
		local s = d.Seats[idx]
		seatsFor[p] = s; used[s] = true; used[d.Seats[idx + 1]] = true -- המושב הסמוך שמור למחבל
	end
	for i, s in ipairs(d.Seats) do
		if not used[s] then
			local look
			if s.Row == 3 and s.X == -3.4 then look = NPC.Looks.shachar
			elseif s.Row == 12 and s.X == -5.6 and chapter == 6 then look = NPC.Looks.zvika end
			local n = NPC.Create(S.Map, look or NPC.RandomLook(500 + i), s.Seat.CFrame * CFrame.new(0, 1.6, 0), { pose = "sit" })
			if n then
				if look == NPC.Looks.shachar then S.NPCs.shachar = n end
				if look == NPC.Looks.zvika then S.NPCs.zvika = n; talkPrompt(n, "zvika", "לקחת את התיק", { enabled = false }) end
			end
		end
	end
	-- מחבל ליד כל שחקן
	for p, s in pairs(seatsFor) do
		local guardSeat = s.Seat.CFrame * CFrame.new(2.2, 0, 0)
		local gn = NPC.Terrorist(S.Map, guardSeat * CFrame.new(0, 1.6, 0), { anchored = true })
		if gn then
			gn:Pose("sit")
			gn.Model:SetAttribute("GuardOf", p.UserId)
			talkPrompt(gn, "guard", "לבקש אישור", { enabled = chapter == 5 })
		end
		teleport(p, s.Seat.Position, s.Seat.Position - Vector3.new(0, 0, 10))
		task.delay(0.5, function()
			local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
			if hum then s.Seat:Sit(hum) end
		end)
	end
	-- מחבלים בקדמת המטוס (מאחורי הווילון)
	for _, x in ipairs({ -2, 2 }) do NPC.Terrorist(S.Map, CFrame.new(d.Origin + Vector3.new(x, 3, -50)), { anchored = true }) end
	S.Data.Respawn = function(plr) local s = seatsFor[plr]; return s and { pos = s.Seat.Position, look = s.Seat.Position - Vector3.new(0, 0, 10) } end
	local lavDoor = S.Map.Plane:FindFirstChild("LavDoor")
	if chapter == 5 then prompt(lavDoor, "לסגור את הדלת", "lav", { enabled = false, dist = 8 }) end
	if chapter == 6 then prompt(d.Door, "לפתוח את הדלת", "door", { enabled = false, hold = 1.6, dist = 10 }) end
	local mySeats = {}
	for p, s in pairs(seatsFor) do mySeats[p.UserId] = s.Seat.Position end
	return d, mySeats
end

function S.Ch5(gen, cp)
	local d, seats = buildCabin(gen, 5)
	for _, p in ipairs(storyPlayers()) do
		Remotes.Chapter:FireClient(p, 5, cp, { seat = seats[p.UserId], lav = d.Lav, origin = d.Origin, shachar = S.NPCs.shachar and S.NPCs.shachar.Model })
	end
	waitUntil(gen, function() return #storyPlayers() > 0 and allFlag("Done") end)
	if alive(gen) then task.wait(1); S.Next(6) end
end

-- ═══════════════════════ פרק 6 – הקפיצה והבית ═══════════════════════
function S.Ch6(gen, cp)
	local d, seats = buildCabin(gen, 6)
	local hm, hd = Maps.Home(S.Map, Config.Origins.Home)
	local mm, md = Maps.Memorial(S.Map, Config.Origins.Memorial)
	local hs = Config.Origins.Home
	-- האיחוד: שחר, הורים, לוחם, משפחה
	local reunion = {}
	reunion.shachar = NPC.Create(S.Map, NPC.Looks.shachar, CFrame.new(hs + Vector3.new(0, 3, 2)) * CFrame.Angles(0, math.pi, 0), { anim = "Idle" })
	reunion.mom = NPC.Create(S.Map, { skin = Config.Skin[2], hair = 3, hairColor = Config.HairColors[3], top = Color3.fromRGB(70, 110, 160), bottom = Color3.fromRGB(50, 50, 60), longSleeve = true, gender = "f", acc = {}, accent = Color3.new(1, 1, 1) }, CFrame.new(hs + Vector3.new(-4, 3, 4)) * CFrame.Angles(0, math.pi, 0), { anim = "Idle" })
	reunion.dad = NPC.Create(S.Map, { skin = Config.Skin[3], hair = 1, hairColor = Config.HairColors[6], top = Color3.fromRGB(230, 230, 225), bottom = Color3.fromRGB(45, 62, 87), longSleeve = true, gender = "m", acc = { "glasses" }, accent = Color3.new(1, 1, 1) }, CFrame.new(hs + Vector3.new(4, 3, 4)) * CFrame.Angles(0, math.pi, 0), { anim = "Idle" })
	reunion.soldier = NPC.Create(S.Map, { skin = Config.Skin[4], hair = 1, hairColor = Config.HairColors[1], top = Color3.fromRGB(95, 105, 70), bottom = Color3.fromRGB(95, 105, 70), longSleeve = true, shoes = Color3.fromRGB(60, 50, 40), gender = "m", acc = { "cap" }, capColor = Color3.fromRGB(95, 105, 70), accent = Color3.new(1, 1, 1) }, CFrame.new(hs + Vector3.new(14, 3, 6)) * CFrame.Angles(0, math.rad(200), 0), { anim = "Idle" })
	for i = 1, 6 do reunion["fam" .. i] = NPC.Create(S.Map, NPC.RandomLook(800 + i), CFrame.new(hs + Vector3.new(-10 + i * 3.4, 3, 9 + (i % 2) * 2)) * CFrame.Angles(0, math.pi, 0), { anim = i % 2 == 0 and "Wave" or "Cheer" }) end
	for k, n in pairs(reunion) do S.NPCs["r_" .. k] = n end
	for _, p in ipairs(storyPlayers()) do
		Remotes.Chapter:FireClient(p, 6, cp, { seat = seats[p.UserId], door = d.Door.Position, origin = d.Origin, home = hs, memorial = Config.Origins.Memorial, zvika = S.NPCs.zvika and S.NPCs.zvika.Model, reunion = reunion.shachar and reunion.shachar.Model, mom = reunion.mom and reunion.mom.Model })
	end
	waitUntil(gen, function() return #storyPlayers() > 0 and allFlag("Done") end)
	if alive(gen) then task.wait(2); S.End() end
end

function S.Init(remotes) Remotes = remotes end

return S
