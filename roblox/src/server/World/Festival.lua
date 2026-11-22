-- ═══════════════════════════════════════════════════════════════════
--  מתחם מסיבת הטבע – פרק 1 (לילה) ופרק 2 (בוקר, אחרי ההתקפה)
--  מזרח = +X (הזריחה). במה בצפון (-Z), אוהלים בדרום, רכבים מפוזרים בשדה במערב, פרדס במזרח.
-- ═══════════════════════════════════════════════════════════════════
local B = require(script.Parent.Build)
local P = require(script.Parent.Props)
local F = {}
local rgb = Color3.fromRGB
local M = Enum.Material

-- מיקומים יחסיים (סטאדים)
F.L = {
	Stage = Vector3.new(0, 0, -95), Dance = Vector3.new(0, 0, -45), Bar = Vector3.new(-72, 0, -22),
	Food = Vector3.new(-72, 0, -56), Drums = Vector3.new(76, 0, 6), Chill = Vector3.new(-84, 0, 50),
	Rocks = Vector3.new(112, 0, -72), Medic = Vector3.new(-34, 0, 78), Toilets = Vector3.new(60, 0, 90),
	Camp = Vector3.new(16, 0, 160), OurTent = Vector3.new(28, 0, 168), Parking = Vector3.new(-170, 0, 140),
	Orchard = Vector3.new(270, 0, 80), Ditch = Vector3.new(170, 0, 200), Shelter = Vector3.new(-60, 0, 235),
	Spawn = Vector3.new(-6, 0, -20),
}

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { workspace.Terrain }
local function ground(o, pos)
	-- גובה קרקע: Raycast על ה-Terrain בלבד
	local r = workspace:Raycast(o + pos + Vector3.new(0, 200, 0), Vector3.new(0, -400, 0), rayParams)
	return r and r.Position.Y or o.Y
end
F.ground = ground

function F.Terrain(o, dawn)
	local T = workspace.Terrain
	T:SetMaterialColor(M.Sand, dawn and rgb(196, 170, 130) or rgb(150, 128, 100))
	T:SetMaterialColor(M.Ground, rgb(120, 98, 72))
	T:SetMaterialColor(M.Grass, rgb(128, 120, 78))
	T:SetMaterialColor(M.Mud, rgb(96, 80, 62))
	T:SetMaterialColor(M.Rock, rgb(170, 152, 124))
	T.Decoration = true
	-- בסיס: חול, בעובי 16
	T:FillBlock(CFrame.new(o + Vector3.new(60, -8, 60)), Vector3.new(1100, 16, 1100), M.Sand)
	-- גבעות רכות ומשטחי אדמה/עשב יבש
	math.randomseed(7)
	for _ = 1, 90 do
		local p = o + Vector3.new(math.random(-480, 560), -5, math.random(-460, 560))
		local d = (p - (o + F.L.Dance)).Magnitude
		if d > 120 and (p - (o + F.L.Camp)).Magnitude > 90 then T:FillBall(p, math.random(14, 40), M.Sand) end
	end
	for _ = 1, 160 do
		local p = o + Vector3.new(math.random(-480, 560), -0.5, math.random(-460, 560))
		T:FillCylinder(CFrame.new(p), 1.5, math.random(8, 22), math.random() < 0.55 and M.Grass or M.Ground)
	end
	-- רחבת הריקודים: אדמה דחוסה
	T:FillCylinder(CFrame.new(o + F.L.Dance + Vector3.new(0, -0.4, 0)), 1.6, 70, M.Ground)
	-- גבעת הסלעים של שחר + סלעים
	T:FillBall(o + F.L.Rocks + Vector3.new(0, -14, 0), 30, M.Sand)
	for i = 1, 9 do
		local a = i / 9 * math.pi * 2
		T:FillBall(o + F.L.Rocks + Vector3.new(math.cos(a) * 12, 13 + math.random() * 2, math.sin(a) * 10), math.random(3, 6), M.Rock)
	end
	-- ואדי (תעלה) במזרח-דרום
	for i = 0, 18 do
		T:FillBall(o + F.L.Ditch + Vector3.new(-60 + i * 7, -7, -18 + i * 2), 7, M.Air)
		T:FillCylinder(CFrame.new(o + F.L.Ditch + Vector3.new(-60 + i * 7, -12, -18 + i * 2)), 2, 6, M.Mud)
	end
	-- דרך עפר מהמערב למזרח
	local road = { Vector3.new(-600, 0, 40), Vector3.new(-260, 0, 60), Vector3.new(-200, 0, 80), Vector3.new(-120, 0, 105), Vector3.new(-60, 0, 125), Vector3.new(30, 0, 125), Vector3.new(120, 0, 135), Vector3.new(260, 0, 160), Vector3.new(600, 0, 180) }
	for i = 1, #road - 1 do
		local a, b = o + road[i], o + road[i + 1]
		local n = math.ceil((b - a).Magnitude / 8)
		for k = 0, n do
			local p = a:Lerp(b, k / n)
			T:FillCylinder(CFrame.new(p + Vector3.new(0, -0.9, 0)), 1.8, 11, M.Ground)
		end
	end
	F.Road = road
	-- סלעים מפוזרים
	for _ = 1, 50 do
		local p = o + Vector3.new(math.random(-450, 520), 0, math.random(-430, 520))
		if (p - (o + F.L.Dance)).Magnitude > 90 then T:FillBall(p, math.random(2, 5), M.Rock) end
	end
end

function F.Build(parent, o, dawn)
	local m = B.model(parent, dawn and "FestivalDawn" or "Festival")
	local L = F.L
	local data = { Cars = {}, Tents = {}, Bushes = {}, Covers = {}, Zones = {} }
	F.Terrain(o, dawn)
	local function at(v, y) return o + v + Vector3.new(0, y or 0, 0) end
	-- ─ במה ─
	data.Stage = P.Stage(m, CFrame.new(at(L.Stage)))
	-- גדר מחסום מול הבמה
	for i = -5, 5 do B.part(m, Vector3.new(4.6, 2.6, 1.2), CFrame.new(at(L.Stage, 1.3) + Vector3.new(i * 4.8, 0, 22)), rgb(42, 44, 48), M.Metal) end
	-- ─ אחורי הקלעים – אזור VIP (רק מי שקיבל גישה מהאדמין) ─
	do
		local bs = B.model(m, "Backstage")
		local c = at(L.Stage) + Vector3.new(0, 0, -42)
		local dark, neonP, neonC = rgb(20, 18, 26), rgb(255, 46, 136), rgb(25, 227, 255)
		B.part(bs, Vector3.new(54, 0.6, 34), CFrame.new(c + Vector3.new(0, 0.3, 0)), rgb(36, 32, 44), M.Marble)
		for _, sx in ipairs({ -1, 1 }) do B.part(bs, Vector3.new(1, 10, 34), CFrame.new(c + Vector3.new(sx * 27, 5, 0)), dark, M.Fabric) end
		B.part(bs, Vector3.new(54, 10, 1), CFrame.new(c + Vector3.new(0, 5, -17)), dark, M.Fabric)
		-- שלט ניאון
		local signP = B.part(bs, Vector3.new(16, 3.2, 0.4), CFrame.new(c + Vector3.new(0, 8, -16.4)), rgb(10, 10, 12), M.SmoothPlastic)
		B.sign(signP, Enum.NormalId.Front, "אחורי הקלעים · VIP", neonP)
		B.light(signP, "PointLight", { Color = neonP, Range = 30, Brightness = 2 })
		-- ספות לאונג', שולחנות, בר קטן, פסי ניאון
		for i = -1, 1 do
			local sp = c + Vector3.new(i * 14, 0, -8)
			B.part(bs, Vector3.new(9, 1.4, 3.4), CFrame.new(sp + Vector3.new(0, 1.3, 0)), rgb(120, 20, 60), M.Fabric)
			B.part(bs, Vector3.new(9, 2.6, 1), CFrame.new(sp + Vector3.new(0, 2.6, -1.6)), rgb(120, 20, 60), M.Fabric)
			B.vcyl(bs, 0.2, 3.4, sp + Vector3.new(0, 1.6, 4), rgb(240, 240, 245), M.Glass)
			B.vcyl(bs, 1.6, 0.4, sp + Vector3.new(0, 0.8, 4), rgb(200, 200, 205), M.Metal)
		end
		B.part(bs, Vector3.new(10, 3.4, 2.4), CFrame.new(c + Vector3.new(18, 1.7, 8)), rgb(30, 26, 36), M.Marble)
		B.part(bs, Vector3.new(10, 0.15, 2.4), CFrame.new(c + Vector3.new(18, 3.45, 8)), neonC, M.Neon)
		for _, z in ipairs({ -16.4, 16.4 }) do B.part(bs, Vector3.new(52, 0.25, 0.25), CFrame.new(c + Vector3.new(0, 9.4, z)), neonC, M.Neon) end
		for _, sx in ipairs({ -1, 1 }) do B.part(bs, Vector3.new(0.25, 0.25, 32), CFrame.new(c + Vector3.new(sx * 26.4, 9.4, 0)), neonP, M.Neon) end
		local disco = B.ball(bs, 2.2, c + Vector3.new(0, 8.5, 0), rgb(220, 220, 230), M.Glass, { Name = "DiscoBall", Reflectance = 0.6 })
		B.light(disco, "PointLight", { Color = rgb(255, 120, 220), Range = 40, Brightness = 1.6 })
		-- שער: סוגר לכולם, הלקוח פותח מקומית רק ל-VIP
		local gate = B.part(bs, Vector3.new(12, 9, 0.6), CFrame.new(c + Vector3.new(0, 4.5, 17)), rgb(255, 46, 136), M.ForceField, { Name = "VIPGate", Transparency = 0.6 })
		gate:SetAttribute("VIPGate", true)
		for _, sx in ipairs({ -1, 1 }) do B.part(bs, Vector3.new(21, 10, 1), CFrame.new(c + Vector3.new(sx * 16.5, 5, 17)), dark, M.Fabric) end
		data.Backstage = c
	end
	-- עמדת סאונד
	P.ShadeSail(m, CFrame.new(at(L.Dance) + Vector3.new(0, 0, 40)), 14, 11, rgb(29, 29, 36))
	B.part(m, Vector3.new(8, 3, 3), CFrame.new(at(L.Dance, 1.5) + Vector3.new(0, 0, 40)), rgb(18, 18, 22), M.Metal)
	B.part(m, Vector3.new(4, 1.4, 0.1), CFrame.new(at(L.Dance, 3.7) + Vector3.new(0, 0, 39)) * CFrame.Angles(math.rad(-30), 0, 0), rgb(42, 140, 255), M.Neon)
	-- ─ דגלים סביב הרחבה ─
	local flagC = { rgb(255, 107, 74), rgb(255, 210, 90), rgb(57, 224, 255), rgb(255, 79, 139), rgb(138, 91, 255), rgb(47, 214, 138) }
	for i = 0, 13 do
		local a = -math.pi * 0.95 + i / 13 * math.pi * 0.9
		P.FlagPole(m, at(L.Dance) + Vector3.new(math.cos(a) * 85, 0, -20 - math.sin(a) * 55), flagC[i % 6 + 1], 18 + (i % 3) * 2)
	end
	-- ─ שרשראות נורות מעל הרחבה ─
	for i = 0, 4 do
		local z = -85 + i * 18
		for _, x in ipairs({ -75, 75 }) do B.vcyl(m, 18, 0.4, at(Vector3.new(x, 9, z)), rgb(90, 70, 50), M.Wood) end
		P.StringLights(m, at(Vector3.new(-75, 17.5, z)), at(Vector3.new(75, 17.5, z + 10)), 28, 3, not dawn and i % 2 == 0)
	end
	-- ─ מגדלי תאורה ─
	for _, t in ipairs({ { -100, -5, 40 }, { 100, -5, -40 }, { -55, 105, 150 }, { 80, 120, -150 }, { -150, 100, 90 } }) do
		P.LightTower(m, CFrame.new(at(Vector3.new(t[1], 0, t[2]))) * CFrame.Angles(0, math.rad(t[3]), 0), not dawn)
	end
	-- ─ בר + דוכן אוכל ─
	data.Bar = P.Stall(m, CFrame.new(at(L.Bar)) * CFrame.Angles(0, math.rad(-90), 0), rgb(201, 79, 58), false)
	P.Stall(m, CFrame.new(at(L.Food)) * CFrame.Angles(0, math.rad(-90), 0), rgb(46, 110, 160), true)
	-- ─ מתחם צ'יל ─
	P.ShadeSail(m, CFrame.new(at(L.Chill)), 32, 26, rgb(232, 217, 184))
	for i = 0, 3 do P.Rug(m, CFrame.new(at(L.Chill, 0.05) + Vector3.new(-8 + (i % 2) * 14, 0, -6 + math.floor(i / 2) * 11)) * CFrame.Angles(0, i * 0.3, 0), 9, 6, i * 0.17) end
	for i = 0, 5 do P.Beanbag(m, at(L.Chill) + Vector3.new(-11 + i * 4.5, 0, (i % 2) * 8 - 2), Color3.fromHSV(i / 6, 0.65, 0.75)) end
	-- ─ מעגל תופים ─
	for i = 0, 7 do
		local a = i / 8 * math.pi * 2
		B.cyl(m, 5, 1.4, CFrame.new(at(L.Drums, 0.7) + Vector3.new(math.cos(a) * 11, 0, math.sin(a) * 11)) * CFrame.Angles(0, a, 0), rgb(138, 106, 72), M.Wood)
	end
	local lantern = B.ball(m, 0.9, at(L.Drums, 3), rgb(255, 162, 74), M.Neon, { Name = "Lantern" })
	if not dawn then B.light(lantern, "PointLight", { Color = rgb(255, 154, 74), Range = 30, Brightness = 2.2, Shadows = true }) end
	-- ─ עזרה ראשונה ─
	P.ShadeSail(m, CFrame.new(at(L.Medic)), 14, 11, rgb(242, 242, 242))
	P.FlagPole(m, at(L.Medic) + Vector3.new(9, 0, 0), rgb(255, 122, 26), 15)
	B.part(m, Vector3.new(2.4, 1.3, 5.6), CFrame.new(at(L.Medic, 0.7)), rgb(61, 90, 122), M.Fabric)
	-- ─ שירותים ─
	for i = 0, 5 do P.PortaToilet(m, CFrame.new(at(L.Toilets) + Vector3.new(i * 4, 0, 0)), i % 2 == 0 and rgb(43, 123, 214) or rgb(47, 163, 107)) end
	-- ─ מתחם אוהלים ─
	local tentC = { rgb(61, 111, 138), rgb(138, 61, 61), rgb(79, 122, 58), rgb(217, 160, 50), rgb(90, 79, 138), rgb(46, 107, 107), rgb(181, 85, 46), rgb(122, 122, 122) }
	math.randomseed(11)
	for ix = -4, 4 do
		for iz = -2, 2 do
			local p = at(L.Camp) + Vector3.new(ix * 17 + B.rand(-3, 3), 0, iz * 17 + B.rand(-3, 3))
			if (p - at(L.OurTent)).Magnitude > 12 and math.random() > 0.18 then
				local t = P.DomeTent(m, CFrame.new(p) * CFrame.Angles(0, math.random() * 6, 0), tentC[(ix * 5 + iz + 20) % 8 + 1], B.rand(0.85, 1.2))
				table.insert(data.Tents, t)
				if math.random() < 0.4 then P.CampChair(m, CFrame.new(p + Vector3.new(6, 0, 3)) * CFrame.Angles(0, math.random() * 6, 0), Color3.fromHSV(math.random(), 0.5, 0.45)) end
				if math.random() < 0.3 then P.Cooler(m, CFrame.new(p + Vector3.new(-5, 0, 2)), Color3.fromHSV(math.random(), 0.7, 0.75)) end
			end
		end
	end
	-- האוהל שלנו – גדול, נורות, שקי שינה
	local our = B.model(m, "OurTent")
	P.DomeTent(our, CFrame.new(at(L.OurTent)), rgb(46, 107, 138), 1.8)
	for i = 0, 3 do P.SleepingBag(our, CFrame.new(at(L.OurTent) + Vector3.new(-3.6 + i * 2.4, 0.05, 0.6)), ({ rgb(47, 93, 138), rgb(138, 47, 79), rgb(58, 122, 58), rgb(217, 160, 50) })[i + 1]) end
	local lamp = B.ball(our, 0.35, at(L.OurTent, 4.6), rgb(255, 201, 138), M.Neon, { Name = "TentLamp", CanCollide = false })
	B.light(lamp, "PointLight", { Color = rgb(255, 201, 138), Range = 14, Brightness = dawn and 0.4 or 1.4, Shadows = true })
	for i = 0, 2 do P.CampChair(our, CFrame.new(at(L.OurTent) + Vector3.new(-4 + i * 4, 0, -12)) * CFrame.Angles(0, math.rad(180), 0), ({ rgb(42, 107, 79), rgb(138, 45, 45), rgb(45, 74, 138) })[i + 1]) end
	P.Rug(our, CFrame.new(at(L.OurTent, 0.1) + Vector3.new(0, 0, -9)), 8, 6, 0.55)
	P.StringLights(our, at(L.OurTent) + Vector3.new(-7, 7, -7), at(L.OurTent) + Vector3.new(7, 7, -7), 10, 0.8, false)
	data.OurTent = our
	data.SleepSpot = at(L.OurTent, 0.6) + Vector3.new(1.2, 0, 0.6)
	-- ─ רכבים מפוזרים בשדה – כל אחד בזווית אחרת ─
	local kinds = { "sedan", "hatch", "pickup", "van", "sedan", "hatch" }
	local carC = { rgb(154, 163, 173), rgb(232, 232, 232), rgb(31, 42, 68), rgb(138, 29, 29), rgb(43, 43, 43), rgb(201, 162, 74), rgb(61, 107, 79), rgb(90, 107, 122) }
	local spots = {}
	math.randomseed(23)
	local made, tries = 0, 0
	while made < 44 and tries < 900 do
		tries += 1
		local zone = tries % 5
		local p
		if zone < 3 then p = at(L.Parking) + Vector3.new(B.rand(-110, 110), 0, B.rand(-120, 120))
		elseif zone == 3 then p = at(L.Camp) + Vector3.new(B.rand(-100, 100), 0, B.rand(40, 90))
		else local r = F.Road[math.random(3, 7)]; p = o + r + Vector3.new((math.random() < 0.5 and -1 or 1) * B.rand(10, 16), 0, B.rand(-12, 12)) end
		local ok = true
		for _, s in ipairs(spots) do if (s - p).Magnitude < 16 then ok = false break end end
		for _, t in ipairs(data.Tents) do if (t:GetPivot().Position - p).Magnitude < 13 then ok = false break end end
		if ok and not (math.abs(p.X - o.X) < 110 and p.Z - o.Z < 30) then
			local kind = kinds[made % #kinds + 1]
			local car = P.Car(m, CFrame.new(Vector3.new(p.X, ground(Vector3.zero, p) , p.Z)) * CFrame.Angles(0, math.random() * math.pi * 2, 0), carC[(made * 7 + 3) % #carC + 1], kind, {
				drivable = dawn and made % 4 == 0, doorOpen = dawn and math.random() < 0.35, bulletHoles = dawn and math.random() < 0.25 and 8 or nil,
			})
			table.insert(spots, p); table.insert(data.Cars, car); made += 1
		end
	end
	-- ─ צמחייה ─
	math.randomseed(31)
	for _ = 1, 150 do
		local p = at(Vector3.new(math.random(-460, 520), 0, math.random(-430, 520)))
		local far = (p - at(L.Dance)).Magnitude > 100 and (p - at(L.Camp)).Magnitude > 95 and (p - at(L.Parking)).Magnitude > 120
		if far then
			local b = P.Bush(m, Vector3.new(p.X, ground(Vector3.zero, p) - 0.3, p.Z), B.rand(2.4, 5), nil)
			table.insert(data.Bushes, b)
		end
	end
	for i = 1, 26 do
		local r = F.Road[3 + (i % 6)]
		local p = o + r + Vector3.new((math.random() < 0.5 and -1 or 1) * B.rand(22, 34), 0, B.rand(-15, 15))
		P.Tree(m, Vector3.new(p.X, ground(Vector3.zero, p) - 0.5, p.Z), "eucalyptus", B.rand(0.8, 1.3))
	end
	for ix = 0, 8 do
		for iz = 0, 6 do
			local p = at(L.Orchard) + Vector3.new(ix * 20 + B.rand(-2, 2), 0, -60 + iz * 20 + B.rand(-2, 2))
			P.Tree(m, Vector3.new(p.X, ground(Vector3.zero, p) - 0.3, p.Z), "olive", B.rand(0.9, 1.2))
		end
	end
	-- ─ מבנה בטון קטן (מסתור) ─
	local sh = B.model(m, "Shelter")
	local conc = rgb(184, 176, 160)
	local sp = at(L.Shelter)
	B.part(sh, Vector3.new(18, 8, 1), CFrame.new(sp + Vector3.new(0, 4, -6)), conc, M.Concrete)
	B.part(sh, Vector3.new(1, 8, 13), CFrame.new(sp + Vector3.new(-8.5, 4, 0)), conc, M.Concrete)
	B.part(sh, Vector3.new(1, 8, 13), CFrame.new(sp + Vector3.new(8.5, 4, 0)), conc, M.Concrete)
	B.part(sh, Vector3.new(6, 8, 1), CFrame.new(sp + Vector3.new(-6, 4, 6)), conc, M.Concrete)
	B.part(sh, Vector3.new(6, 8, 1), CFrame.new(sp + Vector3.new(6, 4, 6)), conc, M.Concrete)
	B.part(sh, Vector3.new(19, 1, 14), CFrame.new(sp + Vector3.new(0, 8.5, 0)), conc, M.Concrete)
	data.ShelterZone = { Center = sp + Vector3.new(0, 3, 0), Size = Vector3.new(16, 8, 11) }
	data.Origin = o
	-- ─ גרסת הבוקר: שרידי הלילה, רכבים בוערים, כתמים, עשן ─
	if dawn then
		math.randomseed(41)
		for _ = 1, 80 do local p = at(Vector3.new(math.random(-90, 90), 0, math.random(-90, 200))); P.Debris(m, Vector3.new(p.X, ground(Vector3.zero, p), p.Z)) end
		data.Burning = {}
		for _, c in ipairs({ { -240, 52, 0.4 }, { -262, 66, 2.1 }, { -215, 84, 1.2 } }) do
			local p = at(Vector3.new(c[1], 0, c[2]))
			table.insert(data.Burning, P.Car(m, CFrame.new(Vector3.new(p.X, ground(Vector3.zero, p), p.Z)) * CFrame.Angles(0, c[3], 0), rgb(40, 40, 40), ({ "sedan", "pickup", "hatch" })[#data.Burning + 1], { burned = true }))
		end
		for _, s in ipairs({ { -165, 72, 4 }, { -130, 100, 3 }, { -195, 120, 5 }, { -85, 165, 3 }, { -245, 80, 4.5 } }) do
			local p = at(Vector3.new(s[1], 0, s[2])); P.Stain(m, Vector3.new(p.X, ground(Vector3.zero, p), p.Z), s[3], "blood")
		end
		for _, s in ipairs({ { -230, 60 }, { -250, 90 } }) do local p = at(Vector3.new(s[1], 0, s[2])); P.Stain(m, Vector3.new(p.X, ground(Vector3.zero, p), p.Z), 9, "soot") end
		-- עמודי עשן רחוקים במערב
		for _, s in ipairs({ { -560, -160 }, { -480, 120 }, { -340, -420 }, { -620, 330 } }) do
			local e = B.part(m, Vector3.new(2, 2, 2), CFrame.new(at(Vector3.new(s[1], 2, s[2]))), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false })
			local sm = Instance.new("Smoke"); sm.Size = 60; sm.RiseVelocity = 22; sm.Opacity = 0.4; sm.Color = rgb(40, 36, 34); sm.Parent = e
			local f = Instance.new("Fire"); f.Size = 18; f.Heat = 20; f.Parent = e
		end
		-- שלט "יציאה" נפול – רמז ויזואלי למזרח
		local post = B.vcyl(m, 7, 0.25, at(Vector3.new(85, 3.5, 128)), rgb(120, 120, 120), M.Metal)
		post.CFrame = post.CFrame * CFrame.Angles(math.rad(20), 0, 0)
		local board = B.part(m, Vector3.new(5, 1.8, 0.2), CFrame.new(at(Vector3.new(85, 6.5, 129))) * CFrame.Angles(math.rad(20), math.rad(-90), 0), rgb(31, 107, 58), M.SmoothPlastic)
		B.sign(board, Enum.NormalId.Front, "יציאה ⟵", rgb(255, 255, 255))
		B.sign(board, Enum.NormalId.Back, "יציאה ⟵", rgb(255, 255, 255))
	end
	-- אזורי טריגר לתפיסה
	data.Zones.Orchard = { Center = at(L.Orchard) + Vector3.new(60, 5, 0), Size = Vector3.new(200, 40, 160) }
	data.Zones.Ditch = { Center = at(L.Ditch) + Vector3.new(0, 0, 0), Size = Vector3.new(140, 30, 70) }
	return m, data
end

return F
