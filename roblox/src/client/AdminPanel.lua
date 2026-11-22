-- ═══════════════════════════════════════════════════════════════════
--  AdminPanel – פאנל אדמין בסגנון "בלוקי" צבעוני: כותרת כחולה עם דוגמת בליטות, X אדום,
--  כרטיסים כהים, כפתורים תלת־ממדיים, אזורים מתקפלים ולשונית "עוד…" ירוקה.
--  מופיע רק למשתמש 9214350185 (גם השרת בודק בכל פקודה). כל הטקסטים בעברית.
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Config = require(RS.Shared.Config)
local UI = require(script.Parent.UI)
local new = UI.new

local A = {}
local plr = Players.LocalPlayer
local R
local rgb = Color3.fromRGB
local Bk = require(script.Parent.Blocky)
local FONT = Bk.FONT
local txt, studs, button, input, card = Bk.txt, Bk.studs, Bk.button, Bk.input, Bk.card

local function send(...) if R then R.Admin:FireServer(...) end end

function A.Init(remotes)
	R = remotes
	if plr.UserId ~= Config.AdminUserId then return end
	-- כפתור קטן לפתיחה
	local open = new("TextButton", { Text = "🔨", TextSize = 20, BackgroundColor3 = rgb(36, 132, 220), Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -14, 1, -14), ZIndex = 89, Parent = UI.Gui }, { UI.corner(8), new("UIStroke", { Color = rgb(10, 40, 80), Thickness = 2 }) })
	local win = A.Build()
	win.Visible = false
	open.MouseButton1Click:Connect(function()
		win.Visible = not win.Visible
		if win.Visible then UI.PushCursor() else UI.PopCursor() end
		A.Open = win.Visible
	end)
	A.Win = win
	R.AdminLog.OnClientEvent:Connect(function(s) UI.Toast(s, 2) end)
end

function A.Build()
	local root = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(860, 560), ZIndex = 90, Parent = UI.Gui })
	new("UIScale", { Scale = 1, Parent = root })
	-- גוף
	local body = new("Frame", { BackgroundColor3 = rgb(20, 30, 26), BackgroundTransparency = 0.12, Size = UDim2.new(1, -40, 1, -70), Position = UDim2.fromOffset(20, 66), ZIndex = 90, Parent = root }, { UI.corner(4), new("UIStroke", { Color = rgb(8, 12, 16), Thickness = 4 }) })
	-- כותרת
	local head = new("Frame", { BackgroundColor3 = rgb(64, 170, 245), Size = UDim2.new(1, 0, 0, 74), ZIndex = 91, Parent = root }, {
		UI.corner(4), new("UIStroke", { Color = rgb(8, 30, 60), Thickness = 4 }), new("UIGradient", { Color = ColorSequence.new(rgb(96, 196, 255), rgb(40, 140, 225)), Rotation = 90 }),
	})
	studs(head, rgb(255, 255, 255))
	txt(head, "🔨", UDim2.fromOffset(50, 50), UDim2.new(1, -70, 0, 12), 34, Enum.TextXAlignment.Center)
	txt(head, "פאנל אדמין", UDim2.new(1, -170, 1, 0), UDim2.fromOffset(80, 0), 40)
	button(head, "X", "red", UDim2.fromOffset(52, 52), UDim2.fromOffset(12, 11), function() if root.Visible then UI.PopCursor() end; root.Visible = false; A.Open = false end)
	-- לשונית "עוד…"
	local more = button(root, "", "green", UDim2.fromOffset(60, 230), UDim2.new(1, 6, 0, 130), function() A.ToggleMore() end)
	local ml = txt(more, "עוד…", UDim2.fromOffset(200, 50), UDim2.new(0.5, -100, 0.5, -25), 30, Enum.TextXAlignment.Center); ml.Rotation = 90; ml.ZIndex = 95
	-- ─ עמוד ראשי ─
	local page = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 91, Parent = body })
	A.Page = page
	local colR = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -20, 1, -20), Position = UDim2.new(0.5, 10, 0, 10), ZIndex = 91, Parent = page })
	local colL = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.5, -20, 1, -20), Position = UDim2.fromOffset(10, 10), ZIndex = 91, Parent = page })
	new("Frame", { BackgroundColor3 = rgb(40, 60, 50), Size = UDim2.new(0, 4, 1, -24), Position = UDim2.new(0.5, -2, 0, 12), ZIndex = 91, Parent = page }, { UI.corner(2) })
	-- הכרזה גלובלית
	local c1 = card(colR, "הכרזה גלובלית", UDim2.new(1, 0, 0, 80), UDim2.new())
	local ann = input(c1, "הקלידו הודעה…", UDim2.new(1, -120, 0, 32), UDim2.fromOffset(104, 40))
	button(c1, "שלח", "green", UDim2.fromOffset(84, 32), UDim2.fromOffset(12, 40), function() send("announce", ann.Text); ann.Text = "" end)
	-- הודעת שרת
	local c2 = card(colR, "הודעת שרת", UDim2.new(1, 0, 0, 80), UDim2.fromOffset(0, 90))
	local hint = input(c2, "טקסט קבוע בראש המסך…", UDim2.new(1, -120, 0, 32), UDim2.fromOffset(104, 40))
	button(c2, "שלח", "green", UDim2.fromOffset(84, 32), UDim2.fromOffset(12, 40), function() send("servermsg", hint.Text); hint.Text = "" end)
	-- סקר
	local c3 = card(colR, "סקר", UDim2.new(1, 0, 0, 200), UDim2.fromOffset(0, 180))
	button(c3, "גלובלי", "blue", UDim2.fromOffset(70, 22), UDim2.fromOffset(12, 8), function() end)
	local q = input(c3, "הקלידו שאלה…", UDim2.new(1, -24, 0, 28), UDim2.fromOffset(12, 38))
	local opts = {}
	for i = 1, 4 do
		local col = (i - 1) % 2
		local row = math.floor((i - 1) / 2)
		opts[i] = input(c3, "אפשרות " .. i, UDim2.new(0.5, -18, 0, 26), UDim2.new(col == 0 and 0.5 or 0, col == 0 and 6 or 12, 0, 72 + row * 30))
	end
	local dur = input(c3, "דקות", UDim2.fromOffset(110, 26), UDim2.new(1, -170, 0, 134))
	dur.Text = "2"
	txt(c3, "זמן:", UDim2.fromOffset(50, 26), UDim2.new(1, -60, 0, 134), 18)
	button(c3, "תבנית", "purple", UDim2.fromOffset(90, 26), UDim2.fromOffset(12, 134), function()
		q.Text = "איזה פרק הכי ריגש אתכם?"; opts[1].Text = "המסיבה"; opts[2].Text = "המנהרה"; opts[3].Text = "המטוס"; opts[4].Text = "הבית"
	end)
	button(c3, "שליחה", "green", UDim2.fromOffset(150, 30), UDim2.new(0.5, -75, 0, 164), function()
		send("poll", q.Text, { opts[1].Text, opts[2].Text, opts[3].Text, opts[4].Text }, (tonumber(dur.Text) or 2) * 60)
	end)
	-- משך אירוע
	local c4 = card(colL, "אירוע לזמן מוגבל", UDim2.new(1, 0, 0, 84), UDim2.new())
	button(c4, "עצור", "pink", UDim2.fromOffset(70, 22), UDim2.fromOffset(12, 8), function() send("stopEvents") end)
	local evIn = input(c4, "שחקן / שניות (למשל all/30)", UDim2.new(1, -150, 0, 30), UDim2.fromOffset(134, 44))
	evIn.TextSize = 13
	button(c4, "שלח דיסקו", "green", UDim2.fromOffset(112, 30), UDim2.fromOffset(12, 44), function()
		local target, secs = evIn.Text:match("([^/]+)/?(%d*)")
		send("event", "disco", target or "all", tonumber(secs) or 30)
	end)
	-- פקודות שחקן
	local c5 = card(colL, "פקודות שחקן", UDim2.new(1, 0, 0, 120), UDim2.fromOffset(0, 94))
	local tgt = input(c5, "שחקן / שם תצוגה / me / others / all", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 34))
	tgt.TextSize = 13
	local reason = input(c5, "סיבה / כמות (דקות)", UDim2.new(1, -24, 0, 26), UDim2.fromOffset(12, 88))
	reason.TextSize = 13
	local w = 0.25
	button(c5, "קיק", "red", UDim2.new(w, -10, 0, 22), UDim2.new(0.75, 4, 0, 63), function() send("kick", tgt.Text, reason.Text) end)
	button(c5, "באן", "red", UDim2.new(w, -10, 0, 22), UDim2.new(0.5, 4, 0, 63), function() send("ban", tgt.Text, reason.Text) end)
	button(c5, "אזהרה", "orange", UDim2.new(w, -10, 0, 22), UDim2.new(0.25, 4, 0, 63), function() send("warn", tgt.Text, reason.Text) end)
	button(c5, "השתקה", "gray", UDim2.new(w, -10, 0, 22), UDim2.new(0, 4, 0, 63), function() send("mute", tgt.Text, reason.Text) end)
	A.Target = tgt
	-- אזורים מתקפלים
	local c6 = card(colL, nil, UDim2.new(1, 0, 1, -224), UDim2.fromOffset(0, 224))
	local scroll = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 92, Parent = c6 }, { new("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder }) })
	local order = 0
	local function section(name, items)
		order += 1
		local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 30), AutomaticSize = Enum.AutomaticSize.Y, LayoutOrder = order, ZIndex = 92, Parent = scroll })
		local hdr = new("TextButton", { BackgroundTransparency = 1, Text = "", Size = UDim2.new(1, 0, 0, 28), ZIndex = 93, Parent = holder })
		local arrow = txt(hdr, "◀", UDim2.fromOffset(20, 28), UDim2.new(1, -24, 0, 0), 16, Enum.TextXAlignment.Center)
		txt(hdr, name, UDim2.new(1, -40, 1, 0), UDim2.fromOffset(0, 0), 19)
		new("Frame", { BackgroundColor3 = rgb(230, 230, 230), Size = UDim2.new(0.62, 0, 0, 2), Position = UDim2.new(0.28, 0, 1, -2), ZIndex = 93, Parent = hdr })
		local list = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0), Position = UDim2.fromOffset(0, 32), AutomaticSize = Enum.AutomaticSize.Y, Visible = false, ZIndex = 92, Parent = holder }, {
			new("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 28), CellPadding = UDim2.fromOffset(6, 6), HorizontalAlignment = Enum.HorizontalAlignment.Right }),
		})
		for _, it in ipairs(items) do button(list, it[1], it[2], UDim2.fromOffset(160, 28), UDim2.new(), it[3]) end
		hdr.MouseButton1Click:Connect(function() list.Visible = not list.Visible; arrow.Text = list.Visible and "▼" or "◀" end)
	end
	local function T() return A.Target.Text ~= "" and A.Target.Text or "all" end
	section("אירועים", {
		{ "ג'אמפסקייר", "red", function() send("jumpscare", T()) end },
		{ "זיקוקים", "purple", function() send("event", "fireworks", "all", 10) end },
		{ "דרופ במה", "pink", function() send("event", "drop", "all", 1) end },
		{ "קונפטי", "yellow", function() send("event", "confetti", "all", 1) end },
		{ "החשכה", "gray", function() send("event", "blackout", "all", 8) end },
		{ "דיסקו 30 שנ'", "green", function() send("event", "disco", "all", 30) end },
	})
	section("מתנות", {
		{ "VIP לשחקן", "yellow", function() send("vip", T(), true) end },
		{ "הסרת VIP", "gray", function() send("vip", T(), false) end },
		{ "רובה אדמין", "red", function() send("rifle", true) end },
		{ "בלי רובה", "gray", function() send("rifle", false) end },
		{ "מהירות ×3", "blue", function() send("speed", 33) end },
		{ "מהירות רגילה", "gray", function() send("speed", 11) end },
		{ "קפיצה גבוהה", "green", function() send("jump", true) end },
		{ "צמיד לשחקן", "pink", function() send("bracelet", T()) end },
	})
	section("אחר", {
		{ "בלי אויבים", "orange", function() send("enemies", true) end },
		{ "עם אויבים", "gray", function() send("enemies", false) end },
		{ "ללא פגיעה", "green", function() send("god", true) end },
		{ "פגיעה רגילה", "gray", function() send("god", false) end },
		{ "FPS", "blue", function() UI.Fps.Visible = not UI.Fps.Visible end },
		{ "הסתרת UI", "purple", function() UI.SetHidden(not UI.Hidden) end },
		{ "טיסה", "blue", function() A.Fly(not A.Flying) end },
		{ "חזרה ללובי", "red", function() send("lobby") end },
	})
	section("טלפורט", {
		{ "אליי השחקן", "blue", function() send("bring", T()) end },
		{ "אל השחקן", "blue", function() send("tpPlayer", T()) end },
		{ "לבמה", "purple", function() send("tpPlace", "stage") end },
		{ "מאחורי הקלעים", "yellow", function() send("tpPlace", "backstage") end },
		{ "לאוהל", "green", function() send("tpPlace", "tent") end },
		{ "ללובי", "gray", function() send("tpPlace", "lobby") end },
	})
	-- ─ עמוד "עוד…": פרקים, צ'קפוינטים, שעה ─
	local pg2 = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 91, Parent = body })
	A.Page2 = pg2
	local k1 = card(pg2, "דילוג לפרק", UDim2.new(1, -20, 0, 90), UDim2.fromOffset(10, 10))
	local names = { "המסיבה", "הבוקר", "המנהרה", "בחוץ", "המטוס", "הבית" }
	for i = 1, 6 do button(k1, i .. ". " .. names[i], ({ "pink", "orange", "gray", "blue", "purple", "green" })[i], UDim2.fromOffset(120, 34), UDim2.new(1, -12 - i * 128, 0, 44), function() send("chapter", i) end) end
	local k2 = card(pg2, "צ'קפוינטים", UDim2.new(1, -20, 0, 90), UDim2.fromOffset(10, 110))
	local cps = { { "1:tent", "אוהל" }, { "2:escape", "בריחה" }, { "3:sneak", "סטלת'" }, { "4:route", "מסלול" }, { "6:home", "הבית" } }
	for i, c in ipairs(cps) do button(k2, c[2], "yellow", UDim2.fromOffset(120, 34), UDim2.new(1, -12 - i * 128, 0, 44), function() send("checkpoint", c[1]) end) end
	local k3 = card(pg2, "שעה ביום", UDim2.new(1, -20, 0, 90), UDim2.fromOffset(10, 210))
	for i, h in ipairs({ 0, 5, 6.5, 9, 12, 17, 20 }) do button(k3, string.format("%02d:%02d", math.floor(h), (h % 1) * 60), "blue", UDim2.fromOffset(92, 34), UDim2.new(1, -12 - i * 100, 0, 44), function() send("time", h) end) end
	return root
end

function A.ToggleMore()
	A.Page.Visible = not A.Page.Visible
	A.Page2.Visible = not A.Page.Visible
end

-- טיסה (לאדמין בלבד, צד לקוח)
local flyConn
function A.Fly(on)
	A.Flying = on
	local char = plr.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if flyConn then flyConn:Disconnect(); flyConn = nil end
	if hrp then local old = hrp:FindFirstChild("AdminFly"); if old then old:Destroy() end end
	if not on or not hrp then return end
	local att = hrp:FindFirstChild("RootAttachment") or Instance.new("Attachment", hrp)
	local lv = Instance.new("LinearVelocity"); lv.Name = "AdminFly"; lv.Attachment0 = att; lv.MaxForce = 1e6; lv.RelativeTo = Enum.ActuatorRelativeTo.World; lv.Parent = hrp
	flyConn = game:GetService("RunService").RenderStepped:Connect(function()
		local cam = workspace.CurrentCamera
		local v = Vector3.zero
		if UIS:IsKeyDown(Enum.KeyCode.W) then v += cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.S) then v -= cam.CFrame.LookVector end
		if UIS:IsKeyDown(Enum.KeyCode.D) then v += cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.A) then v -= cam.CFrame.RightVector end
		if UIS:IsKeyDown(Enum.KeyCode.Space) then v += Vector3.yAxis end
		lv.VectorVelocity = v * 70
	end)
end

return A
