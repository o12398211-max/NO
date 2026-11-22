-- ═══════════════════════════════════════════════════════════════════
--  Props – אביזרים מפורטים מבוססי חלקים: במה, רמקולים, קרני אור, אוהלים, צלונים, בר, רכבים,
--  עצים, שיחים, כיסאות, צידניות, שירותים, מגדלי תאורה, דגלים, נורות, כתמים, רכבים שרופים
-- ═══════════════════════════════════════════════════════════════════
local B = require(script.Parent.Build)
local P = {}
local M = Enum.Material
local rgb = Color3.fromRGB
local A = CFrame.Angles
local rad = math.rad

-- ─────────────── במה ───────────────
function P.Stage(parent, cf)
	local m = B.model(parent, "Stage")
	local wood = rgb(120, 98, 80)
	B.part(m, Vector3.new(40, 3, 22), cf * CFrame.new(0, 1.5, 0), wood, M.WoodPlanks)
	B.part(m, Vector3.new(40.4, 2.6, 0.4), cf * CFrame.new(0, 1.3, 11.1), rgb(14, 13, 18), M.Fabric)
	for i = 0, 3 do B.part(m, Vector3.new(4, 0.75, 1.1), cf * CFrame.new(-17, 0.38 + i * 0.75, 14.5 - i * 1.1), wood, M.WoodPlanks) end
	-- טראס משולש
	local trussC = rgb(190, 192, 198)
	local function trussV(pos, h)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			B.vcyl(m, h, 0.22, pos + Vector3.new(math.cos(a) * 0.55, h / 2, math.sin(a) * 0.55), trussC, M.Metal)
		end
		for y = 1, h - 1, 1.2 do
			for k = 0, 2 do
				local a1, a2 = k / 3 * math.pi * 2, (k + 1) / 3 * math.pi * 2
				local p1 = pos + Vector3.new(math.cos(a1) * 0.55, y, math.sin(a1) * 0.55)
				local p2 = pos + Vector3.new(math.cos(a2) * 0.55, y + 0.6, math.sin(a2) * 0.55)
				B.part(m, Vector3.new(0.08, 0.08, (p2 - p1).Magnitude), CFrame.lookAt((p1 + p2) / 2, p2), trussC, M.Metal, { CastShadow = false })
			end
		end
	end
	local function trussH(p1, p2)
		local len = (p2 - p1).Magnitude
		local base = CFrame.lookAt((p1 + p2) / 2, p2)
		for k = 0, 2 do
			local a = k / 3 * math.pi * 2
			B.part(m, Vector3.new(0.22, 0.22, len), base * CFrame.new(math.cos(a) * 0.55, math.sin(a) * 0.55, 0), trussC, M.Metal)
		end
		for z = -len / 2 + 0.6, len / 2 - 0.6, 1.2 do
			B.part(m, Vector3.new(0.08, 1.1, 0.08), base * CFrame.new(0, 0, z) * A(rad(35), 0, 0), trussC, M.Metal, { CastShadow = false })
		end
	end
	local H = 20
	for _, x in ipairs({ -19, 19 }) do
		for _, z in ipairs({ -9, 8 }) do trussV((cf * CFrame.new(x, 3, z)).Position, H) end
	end
	for _, z in ipairs({ -9, 8 }) do trussH((cf * CFrame.new(-19, 3 + H, z)).Position, (cf * CFrame.new(19, 3 + H, z)).Position) end
	for _, x in ipairs({ -19, 19 }) do trussH((cf * CFrame.new(x, 3 + H, -9)).Position, (cf * CFrame.new(x, 3 + H, 8)).Position) end
	-- קיר LED: פיקסלים ניאון (הלקוח מנפיש אותם)
	local led = B.model(m, "LED")
	B.part(m, Vector3.new(31, 15, 0.8), cf * CFrame.new(0, 12, -8.8), rgb(10, 10, 12), M.Metal)
	for ix = 0, 23 do
		for iy = 0, 10 do
			B.part(led, Vector3.new(1.18, 1.18, 0.2), cf * CFrame.new(-14.4 + ix * 1.25, 5.6 + iy * 1.25, -8.3), rgb(40, 0, 60), M.Neon, { CastShadow = false, Name = ix .. "_" .. iy })
		end
	end
	-- דק די־ג'יי
	local booth = B.model(m, "Booth")
	B.part(booth, Vector3.new(7, 2.3, 2.4), cf * CFrame.new(0, 4.15, -1), rgb(20, 20, 26), M.Metal)
	B.part(booth, Vector3.new(6.8, 1.9, 0.1), cf * CFrame.new(0, 4.15, 0.25), rgb(122, 44, 255), M.Neon, { Name = "Front" })
	for i = -1, 1 do
		B.part(booth, Vector3.new(1.5, 0.15, 1.3), cf * CFrame.new(i * 2, 5.37, -1), rgb(40, 40, 46), M.Metal)
		B.cyl(booth, 0.06, 1, cf * CFrame.new(i * 2, 5.48, -1) * A(0, 0, rad(90)), rgb(12, 12, 12), M.SmoothPlastic, { Name = "Platter" })
	end
	-- רמקולים
	local function speaker(c)
		local s = B.model(m, "Speaker")
		B.part(s, Vector3.new(2.8, 3.4, 2.2), c, rgb(16, 16, 20), M.Fabric)
		for _, o in ipairs({ { 0.8, 0.75 }, { -0.7, 0.55 } }) do
			B.cyl(s, 0.2, o[2] * 2, c * CFrame.new(0, o[1], -1.12) * A(0, rad(90), 0), rgb(28, 28, 30), M.Rubber)
			B.cyl(s, 0.22, o[2] * 0.7, c * CFrame.new(0, o[1], -1.15) * A(0, rad(90), 0), rgb(60, 60, 64), M.Metal)
		end
	end
	for _, x in ipairs({ -24, 24 }) do
		for k = 0, 2 do speaker(cf * CFrame.new(x, 1.7 + k * 3.45, 6) * A(0, x > 0 and rad(195) or rad(165), 0)) end
	end
	-- ראשים נעים עם קרני אור נפחיות (Beams)
	local heads = B.folder(m, "Heads")
	local cols = { rgb(255, 46, 136), rgb(25, 227, 255), rgb(155, 91, 255), rgb(255, 179, 71), rgb(25, 227, 255), rgb(255, 46, 136) }
	for i, c in ipairs(cols) do
		local h = B.part(heads, Vector3.new(0.9, 1.1, 0.9), cf * CFrame.new(-15 + (i - 1) * 6, 3 + H - 1, 8), rgb(20, 20, 24), M.Metal, { Name = "Head" .. i })
		local a0 = B.att(h, Vector3.new(0, -0.6, 0))
		local tgt = B.part(heads, Vector3.new(0.2, 0.2, 0.2), cf * CFrame.new(-10 + (i - 1) * 4, 0.2, 30), c, M.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "Target" .. i })
		local a1 = B.att(tgt)
		B.beam(a0, a1, c, 0.4, 9)
		B.light(h, "SpotLight", { Color = c, Range = 60, Angle = 25, Brightness = 4, Face = Enum.NormalId.Bottom, Shadows = false })
		h:SetAttribute("Phase", i * 1.3)
	end
	-- לייזרים
	local lasers = B.folder(m, "Lasers")
	for i = 1, 8 do
		local src = B.part(lasers, Vector3.new(0.3, 0.3, 0.3), cf * CFrame.new(0, 3 + H - 2, -7), rgb(30, 30, 30), M.Metal, { Name = "L" .. i })
		local a0 = B.att(src)
		local t = B.part(lasers, Vector3.new(0.1, 0.1, 0.1), cf * CFrame.new(-60 + i * 15, 25, 120), rgb(0, 0, 0), M.SmoothPlastic, { Transparency = 1, CanCollide = false, Name = "T" .. i })
		local a1 = B.att(t)
		B.beam(a0, a1, i % 2 == 0 and rgb(34, 255, 136) or rgb(255, 34, 102), 0.08, 0.15, { Transparency = NumberSequence.new(0.2) })
	end
	return m
end

-- ─────────────── שרשרת נורות ───────────────
function P.StringLights(parent, a, b, n, sag, withLight)
	local f = B.model(parent, "StringLights")
	local pts = B.catenary(a, b, 14, sag or 1.5)
	B.wire(f, pts, rgb(15, 15, 15), 0.05)
	local cols = { rgb(255, 196, 122), rgb(255, 122, 176), rgb(122, 215, 255), rgb(255, 241, 160) }
	for i = 1, n do
		local t = (i - 0.5) / n
		local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * (sag or 1.5) + 0.12, 0)
		local bulb = B.ball(f, 0.22, p, cols[(i % 4) + 1], M.Neon, { CanCollide = false, CastShadow = false })
		if withLight and i % 4 == 0 then B.light(bulb, "PointLight", { Color = bulb.Color, Range = 9, Brightness = 0.8, Shadows = false }) end
	end
	return f
end

-- ─────────────── אוהל כיפה ───────────────
function P.DomeTent(parent, cf, color, scale)
	scale = scale or 1
	local m = B.model(parent, "Tent")
	local d = 7 * scale
	B.ellipsoid(m, Vector3.new(d * 1.1, d * 0.85, d), cf, color, M.Fabric)
	-- מוטות קשת
	for _, r in ipairs({ 40, -40 }) do
		for k = 0, 10 do
			local a = k / 10 * math.pi
			local p = cf * A(0, rad(r), 0) * CFrame.new(math.cos(a) * d * 0.53, math.sin(a) * d * 0.425, 0)
			B.part(m, Vector3.new(0.1, 0.1, 0.9), p * A(0, 0, a), rgb(30, 30, 30), M.Metal, { CastShadow = false, CanCollide = false })
		end
	end
	-- פתח
	B.ellipsoid(m, Vector3.new(2.4 * scale, 3.2 * scale, 0.2), cf * CFrame.new(0, 0.2, -d / 2 + 0.05), rgb(10, 10, 10), M.Fabric, { CanCollide = false })
	B.wedge(m, Vector3.new(0.1, 2.6 * scale, 1.6 * scale), cf * CFrame.new(1.2 * scale, 1.2 * scale, -d / 2 - 0.6) * A(0, rad(-90), 0), color:Lerp(Color3.new(), 0.2), M.Fabric, { CanCollide = false })
	-- חבלים ויתדות
	for k = 0, 3 do
		local a = k / 4 * math.pi * 2 + math.pi / 4
		local top = (cf * CFrame.new(math.cos(a) * d * 0.45, d * 0.25, math.sin(a) * d * 0.4)).Position
		local bot = (cf * CFrame.new(math.cos(a) * d * 0.85, 0, math.sin(a) * d * 0.8)).Position
		B.wire(m, { top, bot }, rgb(220, 215, 200), 0.04)
	end
	return m
end

-- ─────────────── צלון בד מתוח ───────────────
function P.ShadeSail(parent, cf, w, d, color)
	local m = B.model(parent, "Sail")
	local h = 7
	B.part(m, Vector3.new(w, 0.15, d), cf * CFrame.new(0, h, 0) * A(rad(3), 0, rad(4)), color, M.Fabric, { CanCollide = false })
	for _, c in ipairs({ { -1, -1 }, { 1, -1 }, { -1, 1 }, { 1, 1 } }) do
		B.vcyl(m, h + 0.4, 0.3, (cf * CFrame.new(c[1] * w / 2, (h + 0.4) / 2, c[2] * d / 2)).Position, rgb(90, 70, 50), M.Wood)
	end
	return m
end

function P.Rug(parent, cf, w, d, hue)
	local m = B.model(parent, "Rug")
	B.part(m, Vector3.new(w, 0.08, d), cf, Color3.fromHSV(hue, 0.55, 0.32), M.Fabric, { CanCollide = false })
	B.part(m, Vector3.new(w * 0.8, 0.09, d * 0.7), cf, Color3.fromHSV((hue + 0.08) % 1, 0.6, 0.55), M.Fabric, { CanCollide = false })
	B.part(m, Vector3.new(w * 0.4, 0.1, d * 0.35), cf * A(0, rad(45), 0), Color3.fromHSV((hue + 0.15) % 1, 0.6, 0.7), M.Fabric, { CanCollide = false })
	return m
end

function P.Beanbag(parent, pos, color)
	return B.ellipsoid(parent, Vector3.new(2.2, 1.2, 2.4), CFrame.new(pos + Vector3.new(0, 0.55, 0)), color, M.Fabric)
end

function P.SleepingBag(parent, cf, color)
	local m = B.model(parent, "Bag")
	B.ellipsoid(m, Vector3.new(1.5, 0.55, 4.4), cf * CFrame.new(0, 0.25, 0), color, M.Fabric, { CanCollide = false })
	B.ellipsoid(m, Vector3.new(1.3, 0.4, 0.8), cf * CFrame.new(0, 0.4, -2.0), rgb(220, 214, 200), M.Fabric, { CanCollide = false })
	return m
end

function P.CampChair(parent, cf, color)
	local m = B.model(parent, "Chair")
	B.part(m, Vector3.new(1.4, 0.1, 1.3), cf * CFrame.new(0, 1.2, 0) * A(rad(-6), 0, 0), color, M.Fabric)
	B.part(m, Vector3.new(1.4, 1.5, 0.1), cf * CFrame.new(0, 2.0, 0.65) * A(rad(-12), 0, 0), color, M.Fabric)
	for _, x in ipairs({ -0.65, 0.65 }) do
		B.part(m, Vector3.new(0.07, 1.7, 0.07), cf * CFrame.new(x, 0.65, 0) * A(rad(25), 0, 0), rgb(150, 150, 155), M.Metal)
		B.part(m, Vector3.new(0.07, 1.7, 0.07), cf * CFrame.new(x, 0.65, 0) * A(rad(-25), 0, 0), rgb(150, 150, 155), M.Metal)
	end
	return m
end

function P.Cooler(parent, cf, color)
	local m = B.model(parent, "Cooler")
	B.part(m, Vector3.new(1.8, 1.1, 1.1), cf * CFrame.new(0, 0.55, 0), color, M.SmoothPlastic)
	B.part(m, Vector3.new(1.85, 0.22, 1.15), cf * CFrame.new(0, 1.2, 0), rgb(240, 240, 240), M.SmoothPlastic)
	return m
end

-- ─────────────── בר / דוכן ───────────────
function P.Stall(parent, cf, roofColor, isFood)
	local m = B.model(parent, isFood and "FoodStall" or "Bar")
	local wood = rgb(176, 138, 98)
	B.part(m, Vector3.new(12, 3.3, 2.4), cf * CFrame.new(0, 1.65, 0), wood, M.WoodPlanks)
	B.part(m, Vector3.new(12.6, 0.25, 3), cf * CFrame.new(0, 3.42, 0.15), rgb(90, 59, 34), M.Wood)
	for _, x in ipairs({ -6, 6 }) do
		for _, z in ipairs({ -4.2, 0.9 }) do B.vcyl(m, 8.4, 0.3, (cf * CFrame.new(x, 4.2, z)).Position, rgb(90, 70, 50), M.Wood) end
	end
	B.part(m, Vector3.new(14, 0.15, 7.6), cf * CFrame.new(0, 8.5, -1.6) * A(rad(8), 0, 0), roofColor, M.Fabric)
	for i = 0, 11 do
		B.wedge(m, Vector3.new(0.1, 0.7, 1.15), cf * CFrame.new(-6.4 + i * 1.18, 7.85, 2.2) * A(0, rad(90), rad(180)), i % 2 == 0 and roofColor or rgb(244, 231, 201), M.Fabric, { CanCollide = false })
	end
	B.part(m, Vector3.new(11, 0.15, 1), cf * CFrame.new(0, 5.2, -3.9), wood, M.WoodPlanks)
	if not isFood then
		local juice = { rgb(182, 224, 74), rgb(255, 90, 110), rgb(159, 216, 255), rgb(255, 179, 71) }
		for i = 1, 4 do
			local x = -4 + (i - 1) * 2.6
			B.vcyl(m, 1.4, 1.0, (cf * CFrame.new(x, 4.25, 0)).Position, rgb(230, 240, 245), M.Glass, { Transparency = 0.5 })
			B.vcyl(m, 1.0, 0.9, (cf * CFrame.new(x, 4.1, 0)).Position, juice[i], M.Glass, { Transparency = 0.15 })
		end
		for i = 0, 9 do B.vcyl(m, 0.3, 0.22, (cf * CFrame.new(3.6 + (i % 5) * 0.3, 3.7 + math.floor(i / 5) * 0.3, 0.8)).Position, rgb(240, 240, 240), M.SmoothPlastic) end
	else
		B.part(m, Vector3.new(3, 0.25, 1.6), cf * CFrame.new(-2, 3.65, 0), rgb(60, 60, 60), M.Metal)
		for i = 0, 5 do B.ellipsoid(m, Vector3.new(0.8, 0.12, 0.8), cf * CFrame.new(-3 + i * 0.4, 3.85, 0.1), rgb(220, 180, 120), M.SmoothPlastic) end
	end
	for _, x in ipairs({ -4, 0, 4 }) do
		local l = B.ball(m, 0.45, (cf * CFrame.new(x, 7.3, 0.6)).Position, rgb(255, 179, 71), M.Neon, { CanCollide = false })
		B.light(l, "PointLight", { Color = rgb(255, 179, 106), Range = 14, Brightness = 1.2, Shadows = true })
	end
	return m
end

-- ─────────────── רכב (דקורטיבי/בסיס לנהיגה) ───────────────
-- type: sedan / hatch / pickup / van. מחזיר Model עם PrimaryPart="Chassis"
function P.Car(parent, cf, color, kind, opts)
	opts = opts or {}
	local m = B.model(parent, "Car")
	local burned = opts.burned
	local paint = burned and rgb(30, 26, 23) or color
	local paintMat = burned and M.CorrodedMetal or M.SmoothPlastic
	local glassC = burned and rgb(5, 5, 5) or rgb(20, 28, 36)
	local L = (kind == "pickup" and 15) or (kind == "van" and 14) or (kind == "hatch" and 11.5) or 13.5
	local W = 5.6
	local chassis = B.part(m, Vector3.new(W, 1.9, L), cf * CFrame.new(0, 1.9, 0), paint, paintMat, { Name = "Chassis" })
	m.PrimaryPart = chassis
	-- מכסה מנוע ותא נוסעים
	B.wedge(m, Vector3.new(W - 0.2, 0.6, 3.2), cf * CFrame.new(0, 3.15, -L / 2 + 1.6) * A(0, rad(180), 0), paint, paintMat)
	if kind == "van" then
		B.part(m, Vector3.new(W, 3.6, L - 3.2), cf * CFrame.new(0, 4.6, 1.4), paint, paintMat)
		B.wedge(m, Vector3.new(W - 0.1, 3.4, 2.4), cf * CFrame.new(0, 4.5, -L / 2 + 3.2) * A(0, 0, 0), glassC, M.Glass, { Transparency = burned and 0 or 0.2 })
		for _, s in ipairs({ -1, 1 }) do B.part(m, Vector3.new(0.1, 1.5, L - 6), cf * CFrame.new(s * (W / 2 + 0.01), 5.3, 1.6), glassC, M.Glass, { Transparency = burned and 0 or 0.25 }) end
	else
		local cabL = kind == "pickup" and 5.2 or (kind == "hatch" and 6.4 or 5.8)
		local cabZ = kind == "pickup" and -0.6 or (kind == "hatch" and 1.4 or 0.6)
		B.part(m, Vector3.new(W - 0.5, 2.0, cabL), cf * CFrame.new(0, 3.85, cabZ), glassC, M.Glass, { Transparency = burned and 0 or 0.25 })
		B.part(m, Vector3.new(W - 0.4, 0.2, cabL + 0.1), cf * CFrame.new(0, 4.95, cabZ), paint, paintMat)
		for _, s in ipairs({ -1, 1 }) do
			B.part(m, Vector3.new(0.3, 2.0, 0.35), cf * CFrame.new(s * (W / 2 - 0.35), 3.85, cabZ - cabL / 2), paint, paintMat)
			B.part(m, Vector3.new(0.3, 2.0, 0.35), cf * CFrame.new(s * (W / 2 - 0.35), 3.85, cabZ + cabL / 2), paint, paintMat)
		end
		B.wedge(m, Vector3.new(W - 0.5, 2.0, 1.4), cf * CFrame.new(0, 3.85, cabZ - cabL / 2 - 0.7) * A(0, rad(180), 0), glassC, M.Glass, { Transparency = burned and 0 or 0.2, Name = "Windshield" })
		if kind ~= "hatch" and kind ~= "pickup" then B.wedge(m, Vector3.new(W - 0.5, 2.0, 1.4), cf * CFrame.new(0, 3.85, cabZ + cabL / 2 + 0.7), glassC, M.Glass, { Transparency = burned and 0 or 0.2 }) end
		if kind == "pickup" then
			for _, s in ipairs({ -1, 1 }) do B.part(m, Vector3.new(0.3, 1.1, 6), cf * CFrame.new(s * (W / 2 - 0.15), 3.4, L / 2 - 3.2), paint, paintMat) end
			B.part(m, Vector3.new(W, 1.1, 0.3), cf * CFrame.new(0, 3.4, L / 2 - 0.15), paint, paintMat)
		end
	end
	-- גלגלים
	local wz = L / 2 - 2.3
	for _, z in ipairs({ -wz, wz }) do
		for _, s in ipairs({ -1, 1 }) do
			local w = B.cyl(m, 0.9, 2.3, cf * CFrame.new(s * (W / 2 - 0.25), 1.15, z), burned and rgb(10, 10, 10) or rgb(22, 22, 22), M.Rubber, { Name = "Wheel" })
			if not burned then B.cyl(m, 0.92, 1.3, cf * CFrame.new(s * (W / 2 - 0.25), 1.15, z), rgb(170, 172, 178), M.Metal, { CanCollide = false, Name = "Rim" }) end
			w:SetAttribute("Front", z < 0)
		end
	end
	-- פנסים, פגושים, מראות, לוחית
	for _, s in ipairs({ -1, 1 }) do
		B.part(m, Vector3.new(1.1, 0.5, 0.15), cf * CFrame.new(s * (W / 2 - 0.9), 2.4, -L / 2 - 0.05), burned and rgb(15, 15, 15) or rgb(255, 245, 220), burned and M.Slate or M.Neon, { Name = "Headlight", CanCollide = false })
		B.part(m, Vector3.new(1.0, 0.45, 0.15), cf * CFrame.new(s * (W / 2 - 0.9), 2.4, L / 2 + 0.05), burned and rgb(15, 15, 15) or rgb(180, 20, 15), burned and M.Slate or M.Neon, { Name = "Taillight", CanCollide = false })
		B.part(m, Vector3.new(0.5, 0.35, 0.25), cf * CFrame.new(s * (W / 2 + 0.2), 3.5, -L / 2 + 4.3), paint, paintMat, { CanCollide = false })
	end
	B.part(m, Vector3.new(W + 0.1, 0.6, 0.4), cf * CFrame.new(0, 1.3, -L / 2 - 0.15), rgb(25, 25, 25), M.SmoothPlastic)
	B.part(m, Vector3.new(W + 0.1, 0.6, 0.4), cf * CFrame.new(0, 1.3, L / 2 + 0.15), rgb(25, 25, 25), M.SmoothPlastic)
	B.part(m, Vector3.new(1.6, 0.4, 0.05), cf * CFrame.new(0, 1.9, L / 2 + 0.38), rgb(242, 210, 46), M.SmoothPlastic, { CanCollide = false })
	-- מושב נהג (VehicleSeat) – בשימוש רק ברכבים ניתנים לנהיגה
	local seat = Instance.new("VehicleSeat")
	seat.Name = "DriveSeat"; seat.Size = Vector3.new(2, 0.4, 2); seat.Anchored = true; seat.Transparency = 1; seat.CanCollide = false
	seat.CFrame = cf * CFrame.new(-1.2, 3.0, (kind == "pickup" and -0.6 or 0.6) - 0.3)
	seat.MaxSpeed = kind == "van" and 55 or 70; seat.Torque = 25; seat.TurnSpeed = 1
	seat.Disabled = not opts.drivable
	seat.Parent = m
	B.part(m, Vector3.new(1.3, 1.3, 0.12), cf * CFrame.new(-1.2, 3.6, (kind == "pickup" and -0.6 or 0.6) - 2.2) * A(rad(-25), 0, 0), rgb(15, 15, 15), M.SmoothPlastic, { Name = "Wheel_Steer", CanCollide = false, Shape = Enum.PartType.Cylinder })
	if burned then
		local fire = Instance.new("Fire"); fire.Size = 8; fire.Heat = 12; fire.Color = rgb(255, 120, 40); fire.SecondaryColor = rgb(255, 60, 10); fire.Parent = chassis
		local smoke = Instance.new("Smoke"); smoke.Size = 10; smoke.RiseVelocity = 8; smoke.Opacity = 0.35; smoke.Color = rgb(30, 28, 26); smoke.Parent = chassis
		B.light(chassis, "PointLight", { Color = rgb(255, 120, 40), Range = 22, Brightness = 3, Shadows = true })
	end
	if opts.bulletHoles then
		for i = 1, opts.bulletHoles do
			local s = math.random() < 0.5 and 1 or -1
			B.cyl(m, 0.06, 0.18, cf * CFrame.new(s * (W / 2 + 0.01), B.rand(1.5, 2.6), B.rand(-L / 3, L / 3)), rgb(8, 6, 6), M.SmoothPlastic, { CanCollide = false })
		end
	end
	if opts.doorOpen then
		B.part(m, Vector3.new(0.25, 1.8, 3.2), cf * CFrame.new(-W / 2 - 1.3, 2.6, -0.2) * A(0, rad(-60), 0), paint, paintMat, { Name = "DoorOpen" })
	end
	m:SetAttribute("Kind", kind)
	return m
end

function P.Motorbike(parent, cf, color)
	local m = B.model(parent, "Motorbike")
	local chassis = B.part(m, Vector3.new(0.9, 1.2, 4.0), cf * CFrame.new(0, 2.0, 0), rgb(30, 30, 34), M.Metal, { Name = "Chassis" })
	m.PrimaryPart = chassis
	for _, z in ipairs({ -1.9, 1.9 }) do B.cyl(m, 0.5, 2.2, cf * CFrame.new(0, 1.1, z), rgb(20, 20, 20), M.Rubber, { Name = "Wheel" }) end
	B.ellipsoid(m, Vector3.new(1.2, 1.0, 2.0), cf * CFrame.new(0, 2.9, -0.6), color, M.SmoothPlastic)
	B.part(m, Vector3.new(0.9, 0.35, 1.8), cf * CFrame.new(0, 2.9, 1.0), rgb(15, 15, 15), M.Fabric)
	B.part(m, Vector3.new(2.2, 0.15, 0.15), cf * CFrame.new(0, 3.6, -1.8), rgb(40, 40, 40), M.Metal)
	B.part(m, Vector3.new(0.5, 0.5, 0.2), cf * CFrame.new(0, 3.1, -2.2), rgb(255, 245, 220), M.Neon, { Name = "Headlight" })
	local seat = Instance.new("VehicleSeat"); seat.Name = "DriveSeat"; seat.Size = Vector3.new(1, 0.4, 1.4); seat.Anchored = true; seat.Transparency = 1; seat.CanCollide = false
	seat.CFrame = cf * CFrame.new(0, 3.1, 0.8); seat.MaxSpeed = 80; seat.Disabled = true; seat.Parent = m
	m:SetAttribute("Kind", "bike")
	return m
end

-- ─────────────── צמחייה ───────────────
function P.Tree(parent, pos, kind, scale)
	scale = scale or 1
	local m = B.model(parent, "Tree")
	local trunkC = kind == "olive" and rgb(92, 76, 60) or rgb(185, 173, 152)
	local leafC = kind == "olive" and rgb(125, 138, 95) or rgb(93, 115, 80)
	local H = (kind == "olive" and 8 or 26) * scale
	local function branch(from, dir, len, thick, depth)
		local to = from + dir * len
		B.part(m, Vector3.new(thick, thick, len), CFrame.lookAt((from + to) / 2, to), trunkC, M.Wood)
		if depth >= 2 then
			local s = (kind == "olive" and 5 or 7) * scale * B.rand(0.8, 1.2)
			B.ellipsoid(m, Vector3.new(s * 1.3, s * 0.8, s * 1.2), CFrame.new(to + Vector3.new(0, s * 0.2, 0)) * A(0, math.random() * 6, 0), leafC:Lerp(rgb(70, 90, 60), math.random() * 0.3), M.LeafyGrass, { CanCollide = false })
			return
		end
		for _ = 1, 2 + (math.random() < 0.4 and 1 or 0) do
			local d = (dir + Vector3.new(B.rand(-0.9, 0.9), B.rand(0.3, 0.7), B.rand(-0.9, 0.9))).Unit
			branch(to, d, len * 0.62, thick * 0.6, depth + 1)
		end
	end
	branch(pos, Vector3.new(0, 1, 0), H * 0.45, (kind == "olive" and 1.0 or 1.5) * scale, 0)
	return m
end

function P.Bush(parent, pos, size, color)
	local m = B.model(parent, "Bush")
	for i = 1, 4 do
		local a = i * 2.1
		local s = size * B.rand(0.7, 1.0)
		B.ellipsoid(m, Vector3.new(s * 1.3, s * 0.9, s * 1.2), CFrame.new(pos + Vector3.new(math.cos(a) * size * 0.35, s * 0.35, math.sin(a) * size * 0.35)), (color or rgb(107, 106, 69)):Lerp(rgb(80, 90, 55), math.random() * 0.4), M.Grass, { CanCollide = false })
	end
	m:SetAttribute("Bush", true)
	return m
end

-- ─────────────── שונות ───────────────
function P.PortaToilet(parent, cf, color)
	local m = B.model(parent, "Toilet")
	B.part(m, Vector3.new(3.4, 7, 3.4), cf * CFrame.new(0, 3.5, 0), color, M.SmoothPlastic)
	B.ellipsoid(m, Vector3.new(4, 1.2, 4), cf * CFrame.new(0, 7.1, 0), rgb(240, 240, 240), M.SmoothPlastic)
	B.part(m, Vector3.new(2.4, 5.8, 0.12), cf * CFrame.new(0, 3.2, -1.76), color:Lerp(Color3.new(), 0.15), M.SmoothPlastic)
	return m
end

function P.LightTower(parent, cf, on)
	local m = B.model(parent, "LightTower")
	B.part(m, Vector3.new(5, 2.6, 3.4), cf * CFrame.new(0, 2.2, 0), rgb(224, 176, 32), M.Metal)
	B.vcyl(m, 18, 0.35, (cf * CFrame.new(0, 12, 0)).Position, rgb(150, 150, 155), M.Metal)
	for _, x in ipairs({ -1, 1 }) do
		for _, y in ipairs({ 0, 1 }) do
			local h = B.part(m, Vector3.new(1.5, 1.1, 0.5), cf * CFrame.new(x * 1, 21 + y * 1.2, 0) * A(rad(-25), 0, 0), rgb(30, 30, 34), M.Metal)
			B.part(m, Vector3.new(1.3, 0.9, 0.1), cf * CFrame.new(x * 1, 21 + y * 1.2, -0.3) * A(rad(-25), 0, 0), rgb(255, 241, 214), on and M.Neon or M.Glass, { CanCollide = false })
			if on and x == 1 and y == 0 then B.light(h, "SpotLight", { Face = Enum.NormalId.Front, Color = rgb(255, 241, 214), Range = 60, Angle = 70, Brightness = 2.5, Shadows = true }) end
		end
	end
	return m
end

function P.FlagPole(parent, pos, color, h)
	local m = B.model(parent, "Flag")
	B.vcyl(m, h, 0.2, pos + Vector3.new(0, h / 2, 0), rgb(220, 220, 220), M.Metal)
	local f = B.part(m, Vector3.new(0.05, 7, 2.2), CFrame.new(pos + Vector3.new(0, h - 4, 1.1)), color, M.Fabric, { CanCollide = false, Name = "Cloth" })
	f:SetAttribute("Wave", true)
	return m
end

--- כתם (דם כהה וקרוש / פיח) – לא גרפי: אשכול עיגולים שטוחים חצי־שקופים
function P.Stain(parent, pos, size, kind)
	local m = B.model(parent, "Stain")
	local c = kind == "soot" and rgb(18, 15, 12) or rgb(70, 14, 12)
	for _ = 1, 7 do
		local d = size * B.rand(0.3, 0.8)
		B.cyl(m, 0.04, d, CFrame.new(pos + Vector3.new(B.rand(-size, size) * 0.4, 0.03, B.rand(-size, size) * 0.4)) * A(0, 0, rad(90)), c, M.SmoothPlastic, { Transparency = B.rand(0.25, 0.5), CanCollide = false, CastShadow = false })
	end
	return m
end

--- חפצים נטושים: נעליים, תיקים, כוסות
function P.Debris(parent, pos)
	local k = math.random(1, 4)
	if k == 1 then return B.vcyl(parent, 0.35, 0.25, pos + Vector3.new(0, 0.17, 0), rgb(240, 240, 240), M.SmoothPlastic, { CanCollide = false }) end
	if k == 2 then return B.part(parent, Vector3.new(1.1, 0.7, 0.6), CFrame.new(pos + Vector3.new(0, 0.35, 0)) * A(0, math.random() * 6, rad(80)), Color3.fromHSV(math.random(), 0.6, 0.6), M.Fabric, { CanCollide = false }) end
	if k == 3 then return B.part(parent, Vector3.new(0.4, 0.3, 0.95), CFrame.new(pos + Vector3.new(0, 0.15, 0)) * A(0, math.random() * 6, 0), rgb(230, 225, 215), M.Fabric, { CanCollide = false }) end
	return B.part(parent, Vector3.new(1.4, 0.08, 1.4), CFrame.new(pos + Vector3.new(0, 0.05, 0)) * A(0, math.random() * 6, 0), Color3.fromHSV(math.random(), 0.4, 0.5), M.Fabric, { CanCollide = false })
end

return P
