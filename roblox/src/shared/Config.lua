-- ═══════════════════════════════════════════════════════════════════
--  הגדרות טכניות: אדמין, אודיו (מזהים אמיתיים ומאומתים מספריית Roblox), אנימציות, Color Grading, מיקומי מפות
-- ═══════════════════════════════════════════════════════════════════
local C = {}

-- אדמין: רק המשתמש הזה. אין מקש נסתר – כפתור "אדמין" מופיע רק לו.
C.AdminUserId = 9214350185

C.ServerSizes = { 2, 4, 6, 8 }
C.RespawnDelay = 4
C.SessionStartWait = 25 -- שניות המתנה לחברים בשרת פרטי

-- מיקומי המפות בעולם (כל פרק נבנה במקום משלו ונהרס במעבר)
C.Origins = {
	Lobby = Vector3.new(0, 0, -3000),
	Festival = Vector3.new(0, 0, 0),
	Tunnel = Vector3.new(4000, -60, 0),
	Outside = Vector3.new(-4000, 0, 0),
	Plane = Vector3.new(0, 400, 4000),
	Sky = Vector3.new(3000, 0, 3000),
	Home = Vector3.new(3000, 0, 3000),
	Memorial = Vector3.new(-3000, 0, 3000),
}

local function id(n) return "rbxassetid://" .. tostring(n) end
-- מוזיקה: APM Music (מורשה לשימוש בכל חוויה ב-Roblox). אפקטים: Pro Sound Effects + קריאייטורים מאומתים.
C.Music = {
	Party = id(1846151759),      -- Psychotrance
	Party2 = id(1846151699),     -- Megatrance
	Lobby = id(1842181512),      -- Lakeside Reflection
	Tension = id(1843821342),    -- Tension Repeat Drones 22
	Danger = id(1842923627),     -- Stealth Raid
	Ominous = id(92305230618831),-- Ominous Presence (Ambient)
	Tunnel = id(1843797989),     -- Moving Drone 94
	Drone = id(9043359885),      -- Dark Drone 13
	Theme = id(1836417022),      -- Rose (השיר הראשון ברשימה של שחר)
	Hope = id(84002131639340),   -- Cinematic Hopeful Gravitas
	Piano = id(1838635121),      -- Sad End (Solo Piano)
	Memorial = id(1846508910),   -- Memorial A
	Djembe = id(1838875080),     -- Fast Solo Djembe
}
C.Sfx = {
	Siren = id(9113073796), Rifle = { id(97312793139079), id(123769276894569), id(128799811976358) },
	GunFar = { id(96851433851138), id(105717470125759), id(137321622895305), id(84901063664788) },
	Battle = id(9116353775), Ricochet = { id(7842386350), id(7842385403), id(7842389592) },
	Impact = { id(72423161893546), id(74179101862675) }, BoomFar = id(1843024924), Boom = id(9114224354),
	Heart = id(9043365842), Breath = id(6814463121), Breath2 = id(101395573137763), Ring = id(9069161602),
	Punch = id(9117969687), BodyFall = id(9113480915), Glass = id(9114592245), CarDoor = id(9120371080),
	DoorSlam = id(9114153270), Engine = id(80317022777602), Skid = id(9120397746), Wind = id(116565742544806),
	Crickets = id(9112764573), CrowdPanic = { id(9114012460), id(9114012583) }, CrowdParty = id(9112779173),
	Birds = id(9116969962), Drip = { id(9126190246), id(9126190343), id(9126190341) }, Pipe = id(9113100200),
	Knock = id(9120918417), Zip = id(9113260699), Cloth = id(9113837941), Rustle = id(6644702473),
	Shutter = id(9113678227), Cabin = id(9112773830), Ding = id(75498113218029), Latch = id(9114142431),
	Pistol = id(92011177452282), Whistle = id(9120675895), Chute = id(9117235033), Flap = id(9113716663),
	FallWind = id(9119462099), Beep = id(9118777437), Heli = id(9113417082), Dog = id(8678449977),
	Stinger = id(9047014318), Stinger2 = id(9047014546), Skid2 = id(9119186275),
	Step = {
		Dirt = { id(83191980763392), id(135486775506797), id(82405282985167) },
		Gravel = { id(104596932601069), id(132387836053582), id(74732964293646) },
		Concrete = { id(120195545352847), id(108290664490396), id(106961831442199) },
		Water = { id(131880769929031), id(127535679679925), id(96891952448950) },
		Carpet = { id(131412978408311), id(123224557798023), id(91882016473062) },
		Metal = { id(9125818616), id(9125818607) },
	},
}

-- אנימציות ברירת מחדל של Roblox (R15, היוצר: Roblox – מאומת)
C.Anim = {
	Idle = id(507766388), Look = id(507766666), Walk = id(507777826), Run = id(507767714), Jump = id(507765000),
	Dance1 = id(507771019), Dance2 = id(507776043), Dance3 = id(507777268), Wave = id(507770239),
	Point = id(507770453), Cheer = id(507770677), Laugh = id(507770818), Sit = id(2506281703),
}

-- Color grading לכל פרק (מתוך docs/ART_DIRECTION.md)
C.Grades = {
	Lobby = { Clock = 20.2, Tint = Color3.fromRGB(255, 236, 220), Sat = -0.05, Contrast = 0.08, Bright = 0, Bloom = 0.6, AtmoColor = Color3.fromRGB(70, 60, 90), AtmoDecay = Color3.fromRGB(40, 30, 60), Density = 0.3, Haze = 1.5, Ambient = Color3.fromRGB(40, 36, 52), Brightness = 1 },
	Party = { Clock = 0.4, Tint = Color3.fromRGB(235, 225, 255), Sat = 0.18, Contrast = 0.12, Bright = 0.02, Bloom = 1.0, AtmoColor = Color3.fromRGB(60, 40, 95), AtmoDecay = Color3.fromRGB(30, 20, 55), Density = 0.38, Haze = 2.2, Ambient = Color3.fromRGB(28, 24, 48), Brightness = 1.2 },
	Dawn = { Clock = 6.35, Tint = Color3.fromRGB(255, 226, 204), Sat = -0.3, Contrast = 0.22, Bright = 0, Bloom = 0.5, AtmoColor = Color3.fromRGB(205, 165, 135), AtmoDecay = Color3.fromRGB(120, 90, 80), Density = 0.42, Haze = 2.6, Ambient = Color3.fromRGB(90, 76, 70), Brightness = 2.2 },
	Tunnel = { Clock = 0, Tint = Color3.fromRGB(220, 230, 215), Sat = -0.3, Contrast = 0.28, Bright = -0.02, Bloom = 0.55, AtmoColor = Color3.fromRGB(10, 12, 14), AtmoDecay = Color3.fromRGB(5, 6, 7), Density = 0.6, Haze = 0, Ambient = Color3.fromRGB(8, 9, 10), Brightness = 0 },
	Outside = { Clock = 6.0, Tint = Color3.fromRGB(225, 232, 245), Sat = -0.22, Contrast = 0.12, Bright = 0, Bloom = 0.45, AtmoColor = Color3.fromRGB(143, 163, 179), AtmoDecay = Color3.fromRGB(100, 110, 125), Density = 0.45, Haze = 2.5, Ambient = Color3.fromRGB(70, 76, 86), Brightness = 1.4 },
	Plane = { Clock = 13, Tint = Color3.fromRGB(240, 245, 255), Sat = -0.18, Contrast = 0.12, Bright = 0, Bloom = 0.4, AtmoColor = Color3.fromRGB(200, 215, 230), AtmoDecay = Color3.fromRGB(150, 170, 190), Density = 0.2, Haze = 0.5, Ambient = Color3.fromRGB(120, 125, 135), Brightness = 2 },
	Home = { Clock = 16.5, Tint = Color3.fromRGB(255, 240, 215), Sat = 0.05, Contrast = 0.06, Bright = 0.02, Bloom = 0.65, AtmoColor = Color3.fromRGB(200, 220, 240), AtmoDecay = Color3.fromRGB(255, 220, 170), Density = 0.25, Haze = 1, Ambient = Color3.fromRGB(110, 110, 100), Brightness = 2.6 },
	Memorial = { Clock = 21, Tint = Color3.fromRGB(255, 225, 190), Sat = -0.15, Contrast = 0.1, Bright = 0, Bloom = 0.9, AtmoColor = Color3.fromRGB(20, 24, 50), AtmoDecay = Color3.fromRGB(10, 12, 30), Density = 0.45, Haze = 1, Ambient = Color3.fromRGB(20, 22, 40), Brightness = 0.5 },
}

C.Skin = { Color3.fromRGB(241, 209, 181), Color3.fromRGB(226, 180, 143), Color3.fromRGB(201, 145, 105), Color3.fromRGB(164, 112, 74), Color3.fromRGB(122, 78, 51), Color3.fromRGB(91, 56, 38) }
C.HairColors = { Color3.fromRGB(29, 20, 16), Color3.fromRGB(59, 37, 23), Color3.fromRGB(107, 68, 38), Color3.fromRGB(168, 116, 61), Color3.fromRGB(217, 180, 122), Color3.fromRGB(90, 90, 90), Color3.fromRGB(216, 216, 216) }
-- [חולצה, מכנס, שרוול קצר?]
C.Outfits = {
	{ Color3.fromRGB(242, 239, 233), Color3.fromRGB(45, 62, 87), true },
	{ Color3.fromRGB(255, 79, 139), Color3.fromRGB(58, 63, 69), true },
	{ Color3.fromRGB(255, 207, 74), Color3.fromRGB(107, 91, 69), true },
	{ Color3.fromRGB(61, 74, 92), Color3.fromRGB(35, 38, 41), false },
	{ Color3.fromRGB(91, 107, 62), Color3.fromRGB(75, 64, 51), true },
}

return C
