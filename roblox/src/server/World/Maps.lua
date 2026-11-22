-- ═══════════════════════════════════════════════════════════════════
--  Maps – לובי, מנהרה, אזור הרוס (פרק 4), מטוס (5–6), שדה נחיתה ואיחוד, כיכר הזיכרון
-- ═══════════════════════════════════════════════════════════════════
local B = require(script.Parent.Build)
local P = require(script.Parent.Props)
local Maps = {}
local rgb = Color3.fromRGB
local M = Enum.Material
local A = CFrame.Angles
local rad = math.rad

-- ─────────────── לובי: אולם מכובד ───────────────
function Maps.Lobby(parent, o)
	local m = B.model(parent, "Lobby")
	local marble, dark, gold = rgb(222, 216, 206), rgb(34, 30, 40), rgb(201, 162, 74)
	B.part(m, Vector3.new(160, 2, 160), CFrame.new(o + Vector3.new(0, -1, 0)), rgb(40, 36, 46), M.Marble)
	B.part(m, Vector3.new(120, 0.2, 120), CFrame.new(o + Vector3.new(0, 0.05, 0)), rgb(56, 50, 62), M.Marble)
	-- קירות ועמודים
	for _, s in ipairs({ -1, 1 }) do
		B.part(m, Vector3.new(2, 40, 160), CFrame.new(o + Vector3.new(s * 80, 20, 0)), dark, M.Concrete)
		B.part(m, Vector3.new(160, 40, 2), CFrame.new(o + Vector3.new(0, 20, s * 80)), dark, M.Concrete)
		for z = -60, 60, 20 do
			B.vcyl(m, 38, 3.6, o + Vector3.new(s * 70, 19, z), marble, M.Marble)
			local l = B.part(m, Vector3.new(1, 1.6, 1), CFrame.new(o + Vector3.new(s * 76, 14, z)), rgb(255, 210, 150), M.Neon)
			B.light(l, "PointLight", { Color = rgb(255, 196, 140), Range = 22, Brightness = 1.4 })
		end
	end
	B.part(m, Vector3.new(160, 2, 160), CFrame.new(o + Vector3.new(0, 41, 0)), dark, M.Concrete)
	-- כותרת
	local title = B.part(m, Vector3.new(60, 12, 1), CFrame.new(o + Vector3.new(0, 28, -78.4)), dark, M.SmoothPlastic)
	B.sign(title, Enum.NormalId.Back, "עד הזריחה", rgb(255, 214, 160))
	-- קיר הזיכרון עם נרות
	local wall = B.part(m, Vector3.new(50, 14, 1), CFrame.new(o + Vector3.new(0, 7, 78.4)), rgb(30, 28, 34), M.Slate)
	B.sign(wall, Enum.NormalId.Front, "לזכר הנרצחים, לרפואת הפצועים, ולחיזוק החטופים ששבו הביתה ומשפחותיהם", rgb(240, 225, 200))
	for i = -12, 12 do
		local c = B.vcyl(m, 1.4, 0.5, o + Vector3.new(i * 1.9, 0.7, 74 + (i % 2) * 1.2), rgb(245, 235, 210), M.SmoothPlastic)
		local flame = B.part(m, Vector3.new(0.18, 0.4, 0.18), CFrame.new(o + Vector3.new(i * 1.9, 1.65, 74 + (i % 2) * 1.2)), rgb(255, 176, 80), M.Neon, { CanCollide = false })
		if i % 3 == 0 then B.light(flame, "PointLight", { Color = rgb(255, 160, 70), Range = 9, Brightness = 1.2 }) end
		flame:SetAttribute("Flicker", true)
	end
	-- פורטלים: עיגולים על הרצפה
	local portals = B.folder(m, "Portals")
	local sizes = { 2, 4, 6, 8 }
	for i, n in ipairs(sizes) do
		local pos = o + Vector3.new(-45 + (i - 1) * 30, 0.15, -25)
		local ring = B.cyl(portals, 0.2, 16, CFrame.new(pos) * A(0, 0, rad(90)), rgb(255, 179, 92), M.Neon, { Name = "Portal" .. n, CanCollide = false })
		B.cyl(portals, 0.22, 14.6, CFrame.new(pos + Vector3.new(0, 0.02, 0)) * A(0, 0, rad(90)), rgb(28, 24, 34), M.Marble, { CanCollide = false })
		ring:SetAttribute("Size", n)
		B.light(ring, "PointLight", { Color = rgb(255, 179, 92), Range = 16, Brightness = 1.6 })
		local signP = B.part(portals, Vector3.new(8, 3, 0.4), CFrame.new(pos + Vector3.new(0, 7, 0)), dark, M.SmoothPlastic, { CanCollide = false })
		B.sign(signP, Enum.NormalId.Back, n .. " שחקנים", rgb(255, 230, 200))
		B.sign(signP, Enum.NormalId.Front, n .. " שחקנים", rgb(255, 230, 200))
		local zone = B.part(portals, Vector3.new(14, 8, 14), CFrame.new(pos + Vector3.new(0, 4, 0)), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "Zone" .. n })
		zone:SetAttribute("Size", n)
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Size = Vector3.new(12, 0.4, 12); spawn.Anchored = true; spawn.Transparency = 1; spawn.CanCollide = false; spawn.Neutral = true
	spawn.CFrame = CFrame.new(o + Vector3.new(0, 0.3, 30)); spawn.Duration = 0; spawn.Parent = m
	return m
end

-- ─────────────── מנהרה ───────────────
function Maps.Tunnel(parent, o)
	local m = B.model(parent, "Tunnel")
	local conc, wet = rgb(110, 114, 116), rgb(70, 76, 78)
	local data = { Lights = {}, Pipes = {} }
	local function seg(cf, len, w, h)
		B.part(m, Vector3.new(w, 1, len), cf * CFrame.new(0, -0.5, 0), wet, M.Concrete)
		B.part(m, Vector3.new(1, h, len), cf * CFrame.new(-w / 2 - 0.5, h / 2, 0), conc, M.Concrete)
		B.part(m, Vector3.new(1, h, len), cf * CFrame.new(w / 2 + 0.5, h / 2, 0), conc, M.Concrete)
		-- קשת תקרה: שני לוחות משופעים + תקרה
		for _, sx in ipairs({ -1, 1 }) do
			B.part(m, Vector3.new(w * 0.42, 0.9, len), cf * CFrame.new(sx * w * 0.36, h + w * 0.14, 0) * A(0, 0, sx * rad(-35)), conc, M.Concrete)
		end
		B.part(m, Vector3.new(w * 0.45, 0.9, len), cf * CFrame.new(0, h + w * 0.28, 0), conc, M.Concrete)
	end
	-- תא (חדר החטופים)
	local cell = CFrame.new(o)
	seg(cell, 24, 18, 8)
	B.part(m, Vector3.new(20, 12, 1), cell * CFrame.new(0, 6, 12.5), conc, M.Concrete)
	-- לוח האותיות החרוט (הרמז של אסתר)
	local board = B.part(m, Vector3.new(0.2, 4, 6), cell * CFrame.new(-9.4, 4, 2), conc:Lerp(Color3.new(), 0.15), M.Concrete, { Name = "LetterBoard" })
	B.sign(board, Enum.NormalId.Right, "1 א ב ג ד ה\n2 ו ז ח ט י\n3 כ ל מ נ ס\n4 ע פ צ ק ר\n5 ש ת", rgb(200, 195, 180))
	data.Knock = (cell * CFrame.new(9.2, 3, -4)).Position
	data.Mattress = (cell * CFrame.new(-2, 0.4, 7)).Position
	for i = 0, 3 do P.SleepingBag(m, cell * CFrame.new(-6 + i * 4, 0, 8) * A(0, rad(90), 0), ({ rgb(58, 58, 58), rgb(74, 58, 42), rgb(42, 58, 74), rgb(58, 42, 42) })[i + 1]) end
	local bulb = B.ball(m, 0.6, (cell * CFrame.new(0, 7.2, 0)).Position, rgb(168, 196, 154), M.Neon, { Name = "Bulb" })
	B.light(bulb, "PointLight", { Color = rgb(168, 196, 154), Range = 22, Brightness = 1.4, Shadows = true })
	bulb:SetAttribute("Flicker", true)
	data.Spawn = (cell * CFrame.new(0, 3, 3)).Position
	data.Cell = cell
	-- מסדרון ארוך עם פיצול לצינורות (הסחה)
	local corr = cell * CFrame.new(0, 0, -12 - 60)
	seg(corr, 120, 8, 7)
	for z = -50, 50, 25 do
		local l = B.part(m, Vector3.new(0.6, 0.3, 2.2), corr * CFrame.new(0, 7.6, z), rgb(200, 220, 190), M.Neon)
		B.light(l, "PointLight", { Color = rgb(190, 210, 180), Range = 16, Brightness = 0.6, Shadows = true })
		table.insert(data.Lights, l)
	end
	-- צינורות לאורך הקיר: שני צינורות ניגון (שיתוף פעולה)
	for _, z in ipairs({ 40, 30 }) do
		local pipe = B.cyl(m, 6, 0.8, corr * CFrame.new(-3.6, 2.5 + (z == 40 and 0 or 1.5), z) * A(0, rad(90), 0), rgb(120, 110, 95), M.CorrodedMetal, { Name = "Pipe" })
		table.insert(data.Pipes, pipe)
	end
	B.cyl(m, 120, 0.5, corr * CFrame.new(3.7, 6, 0) * A(0, rad(90), 0), rgb(80, 80, 80), M.Metal)
	-- סיום: תעלת מים וסורג, ואז פיר עולה
	local endCF = corr * CFrame.new(0, 0, -60)
	data.Grate = (endCF * CFrame.new(0, 0.2, 2)).Position
	B.part(m, Vector3.new(6, 0.2, 4), endCF * CFrame.new(0, 0.1, 2), rgb(60, 60, 60), M.DiamondPlate, { Name = "Grate" })
	workspace.Terrain:FillBlock(endCF * CFrame.new(0, -0.6, 10), Vector3.new(7, 1, 18), M.Water)
	B.part(m, Vector3.new(8, 7, 1), endCF * CFrame.new(0, 3.5, -0.5), conc, M.Concrete)
	local shaft = endCF * CFrame.new(0, 0, 2)
	for _, s in ipairs({ -1, 1 }) do B.part(m, Vector3.new(1, 60, 6), shaft * CFrame.new(s * 3.5, 30, 0), conc, M.Concrete) end
	for y = 1, 58, 2 do B.part(m, Vector3.new(4, 0.25, 0.25), shaft * CFrame.new(0, y, -2.6), rgb(100, 100, 100), M.Metal) end
	data.Exit = (shaft * CFrame.new(0, 2, 0)).Position
	data.GuardPath1 = { (corr * CFrame.new(0, 1, 30)).Position, (corr * CFrame.new(0, 1, -10)).Position }
	data.GuardPath2 = { (corr * CFrame.new(0, 1, -20)).Position, (corr * CFrame.new(0, 1, -50)).Position }
	data.Lure = (corr * CFrame.new(0, 1, 52)).Position
	data.Corridor = corr
	return m, data
end

-- ─────────────── פרק 4: אזור הרוס ───────────────
function Maps.Outside(parent, o)
	local m = B.model(parent, "Outside")
	local T = workspace.Terrain
	T:SetMaterialColor(M.Ground, rgb(150, 138, 115))
	T:SetMaterialColor(M.Concrete, rgb(170, 160, 140))
	T:FillBlock(CFrame.new(o + Vector3.new(0, -8, -250)), Vector3.new(900, 16, 900), M.Ground)
	for _ = 1, 120 do T:FillBall(o + Vector3.new(math.random(-420, 420), -3, math.random(-650, 150)), math.random(4, 14), math.random() < 0.5 and M.Mud or M.Sand) end
	local data = { Patrols = {}, Cars = {}, Bushes = {} }
	local plaster = rgb(181, 165, 138)
	math.randomseed(5)
	for _ = 1, 70 do
		local p = o + Vector3.new(math.random(-400, 400), 0, math.random(-620, 120))
		if (p - o).Magnitude > 30 then
			local w, d, h = math.random(14, 30), math.random(14, 30), math.random(6, 22)
			local b = B.model(m, "Ruin")
			B.part(b, Vector3.new(w, h, 1.2), CFrame.new(p + Vector3.new(0, h / 2, -d / 2)) * A(0, 0, rad(math.random(-3, 3))), plaster, M.Concrete)
			B.part(b, Vector3.new(1.2, h * 0.7, d), CFrame.new(p + Vector3.new(-w / 2, h * 0.35, 0)), plaster, M.Concrete)
			if math.random() < 0.6 then B.part(b, Vector3.new(1.2, h * 0.5, d * 0.6), CFrame.new(p + Vector3.new(w / 2, h * 0.25, -d * 0.2)), plaster:Lerp(Color3.new(), 0.1), M.Concrete) end
			for _ = 1, 6 do B.part(b, Vector3.new(math.random(2, 5), math.random(1, 3), math.random(2, 5)), CFrame.new(p + Vector3.new(math.random(-w, w) / 2, 0.8, math.random(-d, d) / 2)) * A(math.random(), math.random(), math.random()), plaster:Lerp(Color3.new(), 0.2), M.Concrete) end
			for _ = 1, 3 do B.part(b, Vector3.new(0.2, 0.2, math.random(4, 9)), CFrame.new(p + Vector3.new(math.random(-w, w) / 2, h * 0.8, 0)) * A(math.random(), 0, 0), rgb(110, 70, 50), M.CorrodedMetal) end
		end
	end
	for _ = 1, 60 do
		local p = o + Vector3.new(math.random(-400, 400), 0, math.random(-620, 120))
		table.insert(data.Bushes, P.Bush(m, p, B.rand(3, 5.5), rgb(107, 106, 69)))
	end
	-- שולחן עם המפה ליד יציאת המנהרה
	local table1 = B.part(m, Vector3.new(5, 0.3, 3), CFrame.new(o + Vector3.new(6, 3, -8)), rgb(120, 92, 64), M.WoodPlanks)
	for _, x in ipairs({ -2.2, 2.2 }) do for _, z in ipairs({ -1.2, 1.2 }) do B.part(m, Vector3.new(0.3, 3, 0.3), CFrame.new(o + Vector3.new(6 + x, 1.5, -8 + z)), rgb(100, 76, 54), M.Wood) end end
	local map = B.part(m, Vector3.new(2.4, 0.05, 1.7), CFrame.new(o + Vector3.new(6, 3.2, -8)) * A(0, rad(10), 0), rgb(216, 204, 174), M.SmoothPlastic, { Name = "Map" })
	local g = B.sign(map, Enum.NormalId.Top, "", rgb(0, 0, 0))
	g.Text = "✕"; g.TextColor3 = rgb(192, 57, 43); g.TextXAlignment = Enum.TextXAlignment.Right; g.TextYAlignment = Enum.TextYAlignment.Top
	data.Map = map
	-- יציאת המנהרה (פתח צר)
	B.part(m, Vector3.new(6, 1, 6), CFrame.new(o + Vector3.new(0, 0.2, 0)), rgb(60, 60, 60), M.DiamondPlate)
	data.Spawn = o + Vector3.new(0, 3, 4)
	-- רכבים
	local cars = { { "sedan", rgb(138, 138, 122), Vector3.new(-12, 0, -22) }, { "pickup", rgb(200, 200, 190), Vector3.new(18, 0, -28) } }
	for _, c in ipairs(cars) do table.insert(data.Cars, P.Car(m, CFrame.new(o + c[3]) * A(0, rad(math.random(0, 360)), 0), c[2], c[1], { drivable = true })) end
	table.insert(data.Cars, P.Motorbike(m, CFrame.new(o + Vector3.new(4, 0, -32)) * A(0, rad(30), 0), rgb(138, 29, 29)))
	-- מחסום עם זרקורים
	local cp = o + Vector3.new(120, 0, -300)
	for i = -2, 2 do B.part(m, Vector3.new(4, 2.6, 1.6), CFrame.new(cp + Vector3.new(i * 5, 1.3, 0)), rgb(170, 160, 150), M.Concrete) end
	local tower = B.part(m, Vector3.new(1, 14, 1), CFrame.new(cp + Vector3.new(14, 7, 0)), rgb(60, 60, 60), M.Metal)
	local flood = B.part(m, Vector3.new(2, 1.4, 1), CFrame.new(cp + Vector3.new(14, 14, 0)) * A(rad(-20), rad(180), 0), rgb(255, 240, 210), M.Neon)
	B.light(flood, "SpotLight", { Face = Enum.NormalId.Front, Range = 80, Angle = 45, Brightness = 5, Shadows = true })
	data.Checkpoint = cp
	-- מסלולי סיור
	data.PatrolPaths = {
		{ o + Vector3.new(-60, 2, -80), o + Vector3.new(60, 2, -100), o + Vector3.new(40, 2, -160), o + Vector3.new(-50, 2, -140) },
		{ cp + Vector3.new(-40, 2, 30), cp + Vector3.new(40, 2, 30) },
		{ o + Vector3.new(160, 2, -420), o + Vector3.new(260, 2, -380), o + Vector3.new(220, 2, -480) },
		{ o + Vector3.new(-120, 2, -250), o + Vector3.new(-40, 2, -320) },
		{ o + Vector3.new(300, 2, -540), o + Vector3.new(380, 2, -560) },
	}
	data.Goal = o + Vector3.new(330, 0, -580)
	-- נקודת היעד: פרדס קטן וגדר רחוקה
	for i = 0, 10 do P.Tree(m, data.Goal + Vector3.new(-30 + i * 6, 0, -20 + (i % 3) * 8), "olive", 1) end
	return m, data
end

-- ─────────────── מטוס נוסעים ───────────────
function Maps.Plane(parent, o)
	local m = B.model(parent, "Plane")
	local wall, seatC = rgb(216, 221, 224), rgb(31, 42, 68)
	local L = 120
	B.part(m, Vector3.new(16, 1, L), CFrame.new(o + Vector3.new(0, -0.5, 0)), rgb(90, 96, 110), M.Fabric)
	for _, s in ipairs({ -1, 1 }) do
		B.part(m, Vector3.new(1, 10, L), CFrame.new(o + Vector3.new(s * 8.5, 5, 0)), wall, M.SmoothPlastic)
		B.part(m, Vector3.new(3, 1, L), CFrame.new(o + Vector3.new(s * 7, 10.2, 0)) * A(0, 0, s * rad(-30)), wall, M.SmoothPlastic)
		B.part(m, Vector3.new(3.5, 2.2, L), CFrame.new(o + Vector3.new(s * 6.2, 8.6, 0)), rgb(235, 238, 240), M.SmoothPlastic) -- תאי מטען
		for z = -L / 2 + 6, L / 2 - 6, 5 do
			B.part(m, Vector3.new(0.1, 1.6, 1.1), CFrame.new(o + Vector3.new(s * 7.95, 5.6, z)), rgb(150, 200, 240), M.Neon, { Name = "Window" })
		end
	end
	B.part(m, Vector3.new(10, 1, L), CFrame.new(o + Vector3.new(0, 11, 0)), wall, M.SmoothPlastic)
	for z = -L / 2 + 6, L / 2 - 6, 8 do
		local l = B.part(m, Vector3.new(3, 0.2, 1.2), CFrame.new(o + Vector3.new(0, 10.4, z)), rgb(235, 242, 255), M.Neon)
		B.light(l, "PointLight", { Color = rgb(232, 240, 255), Range = 14, Brightness = 0.8, Shadows = true })
	end
	local seats = {}
	for r = 0, 13 do
		for _, x in ipairs({ -5.6, -3.4, 3.4, 5.6 }) do
			local z = 40 - r * 5.6
			local s = Instance.new("Seat"); s.Anchored = true; s.Size = Vector3.new(2, 0.6, 2); s.CFrame = CFrame.new(o + Vector3.new(x, 1.5, z)); s.Color = seatC; s.Material = M.Fabric; s.Parent = m
			B.part(m, Vector3.new(2, 3.2, 0.5), CFrame.new(o + Vector3.new(x, 3.2, z + 1.1)) * A(rad(-8), 0, 0), seatC, M.Fabric)
			B.part(m, Vector3.new(1.4, 0.6, 0.4), CFrame.new(o + Vector3.new(x, 4.6, z + 1.25)), rgb(235, 235, 235), M.Fabric)
			table.insert(seats, { Seat = s, Row = r, X = x })
		end
	end
	-- וילון וגלריה קדמית, דלת ראשית
	local cur = B.part(m, Vector3.new(14, 10, 0.2), CFrame.new(o + Vector3.new(0, 5, -44)), rgb(42, 51, 80), M.Fabric, { CanCollide = false, Name = "Curtain" })
	B.part(m, Vector3.new(6, 4, 3), CFrame.new(o + Vector3.new(-4, 2, -50)), rgb(200, 205, 210), M.Metal)
	local door = B.part(m, Vector3.new(0.4, 8, 4), CFrame.new(o + Vector3.new(-8.3, 4, -40)), rgb(200, 206, 210), M.Metal, { Name = "MainDoor" })
	B.part(m, Vector3.new(0.3, 0.8, 0.6), CFrame.new(o + Vector3.new(-8.0, 4, -39)), rgb(200, 30, 30), M.SmoothPlastic, { Name = "DoorHandle" })
	local exitS = B.part(m, Vector3.new(0.1, 0.5, 1.5), CFrame.new(o + Vector3.new(-7.9, 8.6, -40)), rgb(255, 59, 48), M.Neon)
	-- שירותים בירכתיים
	local lav = o + Vector3.new(0, 0, 54)
	B.part(m, Vector3.new(16, 10, 1), CFrame.new(lav + Vector3.new(0, 5, -4)), wall, M.SmoothPlastic)
	B.part(m, Vector3.new(3.6, 8, 0.3), CFrame.new(lav + Vector3.new(0, 4, -4.6)), rgb(200, 204, 208), M.SmoothPlastic, { Name = "LavDoor", CanCollide = false })
	B.part(m, Vector3.new(2.4, 2.2, 2), CFrame.new(lav + Vector3.new(2, 1.1, 0)), rgb(240, 240, 240), M.SmoothPlastic, { Name = "Sink" })
	B.part(m, Vector3.new(2, 1.6, 2), CFrame.new(lav + Vector3.new(-2, 0.8, 1)), rgb(245, 245, 245), M.SmoothPlastic)
	B.cyl(m, 0.1, 1.0, CFrame.new(lav + Vector3.new(-3.6, 6, 1)) * A(0, rad(90), 0), rgb(150, 200, 240), M.Neon, { Name = "LavWindow" })
	return m, { Seats = seats, Door = door, Lav = lav, Origin = o }
end

-- ─────────────── שדה נחיתה, איחוד, אפילוג ───────────────
function Maps.Home(parent, o)
	local m = B.model(parent, "Home")
	local T = workspace.Terrain
	T:SetMaterialColor(M.Grass, rgb(106, 154, 74))
	T:FillBlock(CFrame.new(o + Vector3.new(0, -8, 0)), Vector3.new(1600, 16, 1600), M.Grass)
	for i = 0, 30 do
		T:FillBlock(CFrame.new(o + Vector3.new(math.random(-700, 700), -0.3, math.random(-700, 700))) * A(0, math.random() * 6, 0), Vector3.new(math.random(60, 160), 1, math.random(60, 160)), ({ M.Grass, M.Ground, M.LeafyGrass, M.Sand })[i % 4 + 1])
	end
	-- מגדל מים של קיבוץ ברקע, עצים, דגל ישראל
	local wt = o + Vector3.new(-120, 0, -200)
	for _, x in ipairs({ -3, 3 }) do for _, z in ipairs({ -3, 3 }) do B.part(m, Vector3.new(0.8, 30, 0.8), CFrame.new(wt + Vector3.new(x, 15, z)), rgb(180, 180, 175), M.Concrete) end end
	B.vcyl(m, 10, 14, wt + Vector3.new(0, 34, 0), rgb(220, 220, 215), M.Concrete)
	for i = 1, 30 do P.Tree(m, o + Vector3.new(math.random(-300, 300), 0, -260 + math.random(-40, 40)), "eucalyptus", B.rand(0.8, 1.2)) end
	local pole = B.vcyl(m, 22, 0.3, o + Vector3.new(14, 11, -14), rgb(220, 220, 220), M.Metal)
	local flag = B.part(m, Vector3.new(0.05, 4.4, 6.4), CFrame.new(o + Vector3.new(14, 19.8, -10.8)), rgb(255, 255, 255), M.Fabric, { Name = "IsraelFlag", CanCollide = false })
	for _, y in ipairs({ 1.6, -1.6 }) do B.part(m, Vector3.new(0.06, 0.5, 6.4), CFrame.new(o + Vector3.new(14, 19.8 + y, -10.8)), rgb(0, 56, 184), M.Fabric, { CanCollide = false }) end
	local star = B.part(m, Vector3.new(0.06, 1.6, 1.6), CFrame.new(o + Vector3.new(14, 19.8, -10.8)), rgb(255, 255, 255), M.Fabric, { CanCollide = false })
	B.sign(star, Enum.NormalId.Right, "✡", rgb(0, 56, 184))
	B.sign(star, Enum.NormalId.Left, "✡", rgb(0, 56, 184))
	-- ג'יפ צבאי
	P.Car(m, CFrame.new(o + Vector3.new(24, 0, 10)) * A(0, rad(-120), 0), rgb(95, 105, 70), "pickup", {})
	return m, { Spot = o, Origin = o }
end

function Maps.Memorial(parent, o)
	local m = B.model(parent, "Memorial")
	B.part(m, Vector3.new(200, 2, 200), CFrame.new(o + Vector3.new(0, -1, 0)), rgb(106, 106, 112), M.Concrete)
	math.randomseed(77)
	for i = 1, 160 do
		local a, r = math.random() * math.pi * 2, 4 + math.random() * 14
		local p = o + Vector3.new(math.cos(a) * r, 0, math.sin(a) * r)
		B.vcyl(m, 0.6, 0.3, p + Vector3.new(0, 0.3, 0), rgb(245, 235, 210), M.SmoothPlastic)
		local f = B.part(m, Vector3.new(0.1, 0.22, 0.1), CFrame.new(p + Vector3.new(0, 0.75, 0)), rgb(255, 176, 96), M.Neon, { CanCollide = false })
		f:SetAttribute("Flicker", true)
		if i % 10 == 0 then B.light(f, "PointLight", { Color = rgb(255, 170, 90), Range = 12, Brightness = 1.2 }) end
	end
	for i = 0, 15 do
		local a = i / 16 * math.pi * 2
		P.CampChair(m, CFrame.new(o + Vector3.new(math.cos(a) * 26, 0, math.sin(a) * 26)) * A(0, -a - rad(90), 0), rgb(30, 30, 30))
	end
	-- לוחות זיכרון עם צלליות (בלי שמות)
	for i = -4, 4 do
		local b = B.part(m, Vector3.new(4, 6, 0.3), CFrame.new(o + Vector3.new(i * 5, 3, -40)), rgb(40, 38, 44), M.Slate)
		B.ellipsoid(m, Vector3.new(1.6, 2, 0.1), CFrame.new(o + Vector3.new(i * 5, 3.6, -39.8)), rgb(200, 190, 175), M.SmoothPlastic)
		B.ellipsoid(m, Vector3.new(2.6, 1.6, 0.1), CFrame.new(o + Vector3.new(i * 5, 1.6, -39.8)), rgb(200, 190, 175), M.SmoothPlastic)
	end
	return m, { Origin = o }
end

return Maps
