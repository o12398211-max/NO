-- ═══════════════════════════════════════════════════════════════════
--  עד הזריחה – לקוח ראשי: אזהרת טריגר → לובי (דמות, הגדרות, פורטלים) → פרקים.
--  הכרזות, הודעת שרת, סקרים, אירועי אדמין, ג'אמפסקייר, VIP, טבלת ניקוד, כישלון/חזרה
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local StarterGui = game:GetService("StarterGui")
local plr = Players.LocalPlayer

local Shared = RS:WaitForChild("Shared")
local T = require(Shared:WaitForChild("Texts"))
local Config = require(Shared:WaitForChild("Config"))
local R = {}
for _, n in ipairs({ "Chapter", "Story", "Progress", "State", "Fx", "Look", "Portal", "PortalStart", "Admin", "AdminLog", "Score", "Shoot", "Lobby" }) do R[n] = RS:WaitForChild("Remotes"):WaitForChild(n) end

local UI = require(script.Parent.UI)
local Effects = require(script.Parent.Effects)
local Audio = require(script.Parent.Audio)
local Cinematic = require(script.Parent.Cinematic)
local FP = require(script.Parent.FirstPerson)
local Poser = require(script.Parent.Poser)
local Show = require(script.Parent.Show)
local Admin = require(script.Parent.AdminPanel)
local Bk = require(script.Parent.Blocky)
local Chapters = {}
for i = 1, 6 do Chapters[i] = require(script.Parent.Chapters["Ch" .. i]) end

pcall(function() StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false); StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false) end)
UI.Init()
Effects.Settings = UI.Settings
UI.Click = function() Audio.Play(Config.Sfx.Latch, { vol = 0.15, speed = 2.2, life = 2 }) end
UI.Hover = function() end
Poser.Init()
FP.Init(R)
local new = UI.new
local current = nil

-- ═════════════ הגדרות ═════════════
local function toggleRow(parent, key, label, desc, y, onChange)
	local row = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundTransparency = 1, Size = UDim2.new(1, -40, 0, 56), Position = UDim2.fromOffset(20, y), ZIndex = parent.ZIndex + 1, Parent = parent })
	UI.label({ Text = label, TextSize = 17, FontFace = UI.FontBold, Size = UDim2.new(1, -70, 0, 24), Position = UDim2.fromOffset(60, 4), ZIndex = row.ZIndex, Parent = row })
	if desc then UI.label({ Text = desc, TextSize = 13, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -70, 0, 22), Position = UDim2.fromOffset(60, 28), ZIndex = row.ZIndex, Parent = row }) end
	local sw = new("Frame", { BackgroundColor3 = Color3.fromRGB(43, 38, 51), Size = UDim2.fromOffset(46, 26), Position = UDim2.fromOffset(0, 14), ZIndex = row.ZIndex, Parent = row }, { UI.corner(13) })
	local knob = new("Frame", { BackgroundColor3 = Color3.fromRGB(207, 200, 191), Size = UDim2.fromOffset(20, 20), Position = UDim2.fromOffset(3, 3), ZIndex = row.ZIndex + 1, Parent = sw }, { UI.corner(10) })
	local function paint()
		local on = UI.Settings[key]
		UI.tween(sw, 0.2, { BackgroundColor3 = on and Color3.fromRGB(255, 150, 96) or Color3.fromRGB(43, 38, 51) })
		UI.tween(knob, 0.2, { Position = on and UDim2.fromOffset(23, 3) or UDim2.fromOffset(3, 3) })
	end
	paint()
	row.MouseButton1Click:Connect(function() UI.Settings[key] = not UI.Settings[key]; paint(); if UI.Click then UI.Click() end; if onChange then onChange() end end)
end
local function settingsPanel()
	local o = new("Frame", { BackgroundColor3 = Color3.new(), BackgroundTransparency = 0.45, Size = UDim2.fromScale(1, 1), ZIndex = 70, Parent = UI.Gui })
	UI.PushCursor()
	o.Destroying:Connect(function() UI.PopCursor() end)
	local p = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 420), ZIndex = 71, Parent = o })
	UI.label({ Text = T.Settings.Title, FontFace = UI.FontTitle, TextSize = 34, Size = UDim2.new(1, -40, 0, 50), Position = UDim2.fromOffset(20, 12), ZIndex = 72, Parent = p })
	toggleRow(p, "ReduceScare", T.Settings.ReduceScare, T.Settings.ReduceScareDesc, 70)
	toggleRow(p, "ReduceFlash", T.Settings.ReduceFlash, T.Settings.ReduceFlashDesc, 130, function() Effects.Grade(Effects.Current or "Lobby", 0.3) end)
	toggleRow(p, "BigSubs", T.Settings.BigSubs, T.Settings.BigSubsDesc, 190)
	for i, k in ipairs({ "Music", "Sfx" }) do
		local y = 250 + (i - 1) * 46
		UI.label({ Text = T.Settings[k], TextSize = 16, Size = UDim2.new(1, -200, 0, 30), Position = UDim2.fromOffset(180, y), ZIndex = 72, Parent = p })
		local val = UI.label({ Text = math.floor(UI.Settings[k] * 100) .. "%", TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(60, 30), Position = UDim2.fromOffset(70, y), ZIndex = 72, Parent = p })
		local function set(d) UI.Settings[k] = math.clamp(UI.Settings[k] + d, 0, 1); val.Text = math.floor(UI.Settings[k] * 100 + 0.5) .. "%"; Audio.SetVolumes(UI.Settings.Music, UI.Settings.Sfx) end
		UI.button({ Text = "−", Size = UDim2.fromOffset(40, 30), Position = UDim2.fromOffset(20, y), ZIndex = 72, Parent = p }).MouseButton1Click:Connect(function() set(-0.1) end)
		UI.button({ Text = "+", Size = UDim2.fromOffset(40, 30), Position = UDim2.fromOffset(136, y), ZIndex = 72, Parent = p }).MouseButton1Click:Connect(function() set(0.1) end)
	end
	local close = UI.button({ Text = T.Settings.Close, Size = UDim2.fromOffset(200, 44), Position = UDim2.new(0.5, -100, 1, -60), ZIndex = 72, Parent = p }, true)
	close.MouseButton1Click:Connect(function() o:Destroy() end)
end

-- ═════════════ אזהרת טריגר (חובה, לפני הכול) ═════════════
local function warning()
	UI.Fade.BackgroundTransparency = 0
	local w = new("Frame", { BackgroundColor3 = Color3.new(), Size = UDim2.fromScale(1, 1), ZIndex = 75, Parent = UI.Gui })
	local sc = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(0, 800, 1, -40), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 20), CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 4, ZIndex = 76, Parent = w }, {
		new("UIListLayout", { Padding = UDim.new(0, 16), SortOrder = Enum.SortOrder.LayoutOrder }), new("UIPadding", { PaddingTop = UDim.new(0, 40), PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16) }),
	})
	local o = 0
	local function add(inst) o += 1; inst.LayoutOrder = o; inst.Parent = sc; return inst end
	add(UI.label({ Text = '<font color="#FF6B5A">●</font>  ' .. T.Warning.Heading, FontFace = UI.FontTitle, TextSize = 42, Size = UDim2.new(1, 0, 0, 56), ZIndex = 77 }))
	for _, para in ipairs(T.Warning.Body) do add(UI.label({ Text = para, TextSize = 19, TextColor3 = Color3.fromRGB(221, 214, 204), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, LineHeight = 1.4, ZIndex = 77 })) end
	local q = add(UI.panel({ Size = UDim2.new(1, 0, 0, 236), BackgroundTransparency = 0.6, ZIndex = 77 }))
	UI.label({ Text = T.Warning.Quick, TextSize = 14, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -40, 0, 24), Position = UDim2.fromOffset(20, 10), ZIndex = 78, Parent = q })
	toggleRow(q, "ReduceScare", T.Settings.ReduceScare, T.Settings.ReduceScareDesc, 40)
	toggleRow(q, "ReduceFlash", T.Settings.ReduceFlash, T.Settings.ReduceFlashDesc, 100)
	toggleRow(q, "BigSubs", T.Settings.BigSubs, T.Settings.BigSubsDesc, 160)
	local row = add(new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), ZIndex = 77 }))
	local ok = UI.button({ Text = T.Warning.Accept, Size = UDim2.fromOffset(300, 50), Position = UDim2.new(1, -300, 0, 0), ZIndex = 78, Parent = row }, true)
	local ex = UI.button({ Text = T.Warning.Exit, Size = UDim2.fromOffset(140, 50), Position = UDim2.new(1, -460, 0, 0), ZIndex = 78, Parent = row })
	UIS.MouseIconEnabled = true
	local accepted = false
	ok.MouseButton1Click:Connect(function() accepted = true end)
	ex.MouseButton1Click:Connect(function() plr:Kick(T.Warning.ExitMsg) end)
	while not accepted do task.wait() end
	UI.tween(w, 0.8, { BackgroundTransparency = 1 })
	for _, d in ipairs(w:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then UI.tween(d, 0.6, { TextTransparency = 1 }) end
		if d:IsA("Frame") or d:IsA("TextButton") then UI.tween(d, 0.6, { BackgroundTransparency = 1 }) end
	end
	task.wait(0.8)
	w:Destroy()
end

-- ═════════════ לובי ═════════════
local lobbyGui
local function lobbyUI()
	if lobbyGui then lobbyGui.Visible = true return end
	lobbyGui = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 60, Parent = UI.Gui })
	local brand = new("Frame", { BackgroundTransparency = 1, Position = UDim2.new(1, -520, 0, 24), Size = UDim2.fromOffset(500, 120), ZIndex = 61, Parent = lobbyGui })
	UI.label({ Text = T.Title, FontFace = UI.FontTitle, TextSize = 64, TextColor3 = Color3.fromRGB(255, 214, 160), Size = UDim2.new(1, 0, 0, 72), ZIndex = 62, Parent = brand })
	UI.label({ Text = T.Subtitle, TextSize = 16, TextColor3 = UI.Colors.Muted, Position = UDim2.fromOffset(0, 72), Size = UDim2.new(1, 0, 0, 22), ZIndex = 62, Parent = brand })
	UI.label({ Text = T.Lobby.PortalHint, TextSize = 15, TextColor3 = UI.Colors.Accent, Position = UDim2.fromOffset(0, 96), Size = UDim2.new(1, 0, 0, 22), ZIndex = 62, Parent = brand })
	-- פאנל דמות
	local p = UI.panel({ Position = UDim2.new(0, 24, 0.5, -230), Size = UDim2.fromOffset(380, 460), ZIndex = 61, Parent = lobbyGui })
	UI.label({ Text = T.Lobby.Character, FontFace = UI.FontBold, TextSize = 13, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -40, 0, 20), Position = UDim2.fromOffset(20, 14), ZIndex = 62, Parent = p })
	local nameBox = new("TextBox", { Text = "", PlaceholderText = T.Lobby.NamePh, TextColor3 = UI.Colors.Ink, FontFace = UI.Font, TextSize = 16, BackgroundColor3 = Color3.fromRGB(21, 18, 27), Size = UDim2.new(1, -40, 0, 38), Position = UDim2.fromOffset(20, 40), TextDirection = Enum.TextDirection.RightToLeft, ZIndex = 62, Parent = p }, { UI.corner(10), UI.stroke() })
	local look = { gender = "m", skin = 3, hair = 1, hairColor = 2, outfit = 1, useAvatar = false }
	local y = 90
	local function seg(title, items, key, cols)
		UI.label({ Text = title, TextSize = 13, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -40, 0, 18), Position = UDim2.fromOffset(20, y), ZIndex = 62, Parent = p })
		y += 22
		local btns = {}
		local w = (340 - (cols - 1) * 6) / cols
		for i, it in ipairs(items) do
			local col = (i - 1) % cols
			local row = math.floor((i - 1) / cols)
			local b = new("TextButton", { AutoButtonColor = false, Text = typeof(it) == "string" and it or "", BackgroundColor3 = typeof(it) == "Color3" and it or Color3.fromRGB(46, 40, 56), TextColor3 = UI.Colors.Ink, FontFace = UI.Font, TextSize = 13, TextDirection = Enum.TextDirection.RightToLeft, Size = UDim2.fromOffset(typeof(it) == "Color3" and 30 or w, 30), Position = UDim2.new(1, -20 - (col + 1) * (typeof(it) == "Color3" and 36 or w + 6) + 6, 0, y + row * 36), ZIndex = 62, Parent = p }, { UI.corner(typeof(it) == "Color3" and 15 or 8) })
			local st = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Transparency = 1, Parent = b })
			btns[i] = st
			b.MouseButton1Click:Connect(function() look[key] = i; for j, s in ipairs(btns) do s.Transparency = j == i and 0 or 1 end; if UI.Click then UI.Click() end end)
		end
		btns[look[key]].Transparency = 0
		y += math.ceil(#items / cols) * 36 + 6
	end
	seg(T.Lobby.Address, { T.Lobby.Male, T.Lobby.Female }, "genderI", 2)
	look.genderI = 1
	seg(T.Lobby.Skin, Config.Skin, "skin", 6)
	seg(T.Lobby.Hair, T.Lobby.HairStyles, "hair", 5)
	seg("", Config.HairColors, "hairColor", 7)
	seg(T.Lobby.Outfit, T.Lobby.Outfits, "outfit", 3)
	local av = new("TextButton", { AutoButtonColor = false, Text = "☐  " .. T.Lobby.UseAvatar, TextColor3 = UI.Colors.Ink, FontFace = UI.Font, TextSize = 14, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right, TextDirection = Enum.TextDirection.RightToLeft, Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, y), ZIndex = 62, Parent = p })
	av.MouseButton1Click:Connect(function() look.useAvatar = not look.useAvatar; av.Text = (look.useAvatar and "☑  " or "☐  ") .. T.Lobby.UseAvatar end)
	y += 34
	local save = UI.button({ Text = T.Lobby.Save, Size = UDim2.fromOffset(160, 42), Position = UDim2.new(1, -180, 0, y), ZIndex = 62, Parent = p }, true)
	local sett = UI.button({ Text = T.Lobby.Settings, Size = UDim2.fromOffset(150, 42), Position = UDim2.fromOffset(20, y), ZIndex = 62, Parent = p })
	p.Size = UDim2.fromOffset(380, y + 60)
	p.Position = UDim2.new(0, 24, 0.5, -(y + 60) / 2)
	save.MouseButton1Click:Connect(function()
		look.gender = look.genderI == 2 and "f" or "m"
		UI.Ctx.gender = look.gender
		UI.Ctx.name = nameBox.Text ~= "" and nameBox.Text or plr.DisplayName
		R.Look:FireServer({ name = UI.Ctx.name, gender = look.gender, skin = look.skin, hair = look.hair, hairColor = look.hairColor, outfit = look.outfit, useAvatar = look.useAvatar })
		UI.Toast("✓", 1.2)
	end)
	sett.MouseButton1Click:Connect(settingsPanel)
	UI.Ctx.name = plr.DisplayName
end
local function toLobby()
	if current then pcall(current.Stop) current = nil end
	Audio.StopAll(1)
	Cinematic.Release()
	FP.SetEnabled(false)
	FP.Fear = 0
	UI.Objective(nil); UI.Note(nil)
	UI.MiniOn = false; UI.Mini.Visible = false
	Effects.Grade("Lobby", 1)
	Audio.Space("small")
	Audio.Music("Lobby", 0.45, 2)
	UIS.MouseBehavior = Enum.MouseBehavior.Default
	UIS.MouseIconEnabled = true
	lobbyUI()
	UI.FadeTo(0, 1.2)
end

-- ═════════════ פורטל: גודל שרת, חברים בלבד, התחל ═════════════
local portalPanel
R.Portal.OnClientEvent:Connect(function(size, count, running)
	if portalPanel or plr:GetAttribute("InStory") then return end
	portalPanel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(420, 330), ZIndex = 80, Parent = UI.Gui })
	UI.PushCursor()
	portalPanel.Destroying:Connect(function() UI.PopCursor() end)
	UI.label({ Text = T.Lobby.ServerSize, FontFace = UI.FontTitle, TextSize = 30, Size = UDim2.new(1, -40, 0, 44), Position = UDim2.fromOffset(20, 14), ZIndex = 81, Parent = portalPanel })
	local sel = size
	local btns = {}
	for i, n in ipairs(Config.ServerSizes) do
		local b = UI.button({ Text = tostring(n), Size = UDim2.fromOffset(80, 44), Position = UDim2.new(1, -20 - i * 92 + 12, 0, 70), ZIndex = 81, Parent = portalPanel }, n == sel)
		btns[n] = b
		b.MouseButton1Click:Connect(function() sel = n; for k, bb in pairs(btns) do bb.BackgroundColor3 = k == n and Color3.fromRGB(255, 160, 100) or Color3.fromRGB(40, 34, 52) end end)
	end
	UI.label({ Text = T.Lobby.InCircle .. ": " .. tostring(count) .. "  " .. T.Lobby.Players, TextSize = 15, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -40, 0, 22), Position = UDim2.fromOffset(20, 124), ZIndex = 81, Parent = portalPanel })
	local fo = { v = running }
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 60), Position = UDim2.fromOffset(0, 150), ZIndex = 81, Parent = portalPanel })
	UI.Settings._fo = running
	toggleRow(holder, "_fo", T.Lobby.FriendsOnly, running and T.Lobby.Busy or T.Lobby.FriendsOnlyDesc, 0)
	local start = UI.button({ Text = T.Lobby.Start, Size = UDim2.fromOffset(200, 48), Position = UDim2.new(1, -220, 1, -68), ZIndex = 81, Parent = portalPanel }, true)
	local cancel = UI.button({ Text = T.Lobby.Cancel, Size = UDim2.fromOffset(150, 48), Position = UDim2.fromOffset(20, 262), ZIndex = 81, Parent = portalPanel })
	start.MouseButton1Click:Connect(function() R.PortalStart:FireServer(sel, UI.Settings._fo == true); portalPanel:Destroy(); portalPanel = nil end)
	cancel.MouseButton1Click:Connect(function() portalPanel:Destroy(); portalPanel = nil end)
end)
R.Lobby.OnClientEvent:Connect(function(kind)
	if kind == "teleporting" then UI.Toast(T.Lobby.Teleporting, 4) elseif kind == "teleportFail" then UI.Toast(T.Lobby.TeleportFail, 4) elseif kind == "busy" then UI.Toast(T.Lobby.Busy, 4) end
end)

-- ═════════════ פרקים ═════════════
R.Chapter.OnClientEvent:Connect(function(n, cp, payload)
	if UI.LoadingL then UI.LoadingL:Destroy(); UI.LoadingL = nil end
	if current then pcall(current.Stop) end
	if lobbyGui then lobbyGui.Visible = false end
	if portalPanel then portalPanel:Destroy(); portalPanel = nil end
	UI.HidePrompt()
	current = Chapters[n]
	task.spawn(function()
		local ok, err = pcall(current.Start, R, payload or {}, cp)
		if not ok then warn("[Chapter " .. n .. "] " .. tostring(err)) end
	end)
end)

-- ═════════════ כישלון וחזרה (בלי טקסט) ═════════════
local function fail()
	Audio.Play(Config.Sfx.Punch, { vol = 0.8 })
	UI.Hit(1); Effects.Shake(0.7); Effects.Desat(0.8, 2)
	Audio.Muffle(0.7, 0.2); Audio.Ring(0.8)
	FP.BreathOverride = 1; FP.LockMove(true)
	task.wait(0.45)
	UI.FadeTo(1, 1.6)
	task.wait(1)
	FP.Fear = 1
end
local function respawn()
	UI.Hit(0); Effects.Desat(0, 0.5); FP.BreathOverride = nil; Audio.Muffle(0, 1); FP.LockMove(false); FP.Fear = 0.4
	UI.FadeTo(0, 0.8)
end

-- ═════════════ הכרזות, הודעות, סקרים ═════════════
local serverMsg
local function announce(sender, text)
	Audio.Play(Config.Sfx.Ding, { vol = 0.6 })
	Bk.announce(UI.Gui, sender, text, 7)
end
local pollF
local function showPoll(q, opts, secs)
	if pollF then pollF:Destroy() end
	local root, body = Bk.window(UI.Gui, "סקר", "🗳️", UDim2.fromOffset(380, 360), UDim2.new(1, -210, 0.5, 0), "blue", function() if pollF then pollF:Destroy(); pollF = nil end end, 84)
	pollF = root
	Bk.txt(body, q, UDim2.new(1, -24, 0, 52), UDim2.fromOffset(12, 8), 20, nil, 86)
	local bars = {}
	local voted = false
	local colors = { "green", "blue", "orange", "purple" }
	for i, o in ipairs(opts) do
		if o ~= "" then
			local b = Bk.button(body, "", colors[i], UDim2.new(1, -24, 0, 46), UDim2.fromOffset(12, 66 + (i - 1) * 54), nil, 86)
			local fill = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 0.7, Size = UDim2.new(0, 0, 1, 0), AnchorPoint = Vector2.new(1, 0), Position = UDim2.fromScale(1, 0), ZIndex = 87, Parent = b }, { UI.corner(4) })
			Bk.txt(b, o, UDim2.new(1, -70, 1, 0), UDim2.fromOffset(56, 0), 18, nil, 88)
			local c = Bk.txt(b, "0", UDim2.fromOffset(46, 46), UDim2.fromOffset(6, 0), 18, Enum.TextXAlignment.Center, 88)
			bars[i] = { fill = fill, c = c }
			b.MouseButton1Click:Connect(function() if not voted then voted = true; if UI.Click then UI.Click() end; R.Progress:FireServer("vote", i) end end)
		end
	end
	local timeL = Bk.txt(body, "", UDim2.new(1, -24, 0, 24), UDim2.new(0, 12, 1, -30), 15, Enum.TextXAlignment.Center, 86)
	task.spawn(function()
		local t0 = os.clock()
		while pollF == root and os.clock() - t0 < secs do
			local left = secs - (os.clock() - t0)
			timeL.Text = string.format("⏱  %d:%02d", math.floor(left / 60), math.floor(left % 60))
			task.wait(1)
		end
	end)
	UI.PollBars = bars
	UI.PushCursor()
	local popped = false
	local function pop() if not popped then popped = true; UI.PopCursor() end end
	root.Destroying:Connect(pop)
	for _, bb in pairs(bars) do bb.fill.Parent.MouseButton1Click:Connect(pop) end
end
local function pollCounts(counts, final)
	if not UI.PollBars then return end
	local total = 0
	for _, c in ipairs(counts) do total += c end
	for i, b in pairs(UI.PollBars) do
		b.c.Text = tostring(counts[i] or 0)
		UI.tween(b.fill, 0.4, { Size = UDim2.new(total > 0 and (counts[i] / total) or 0, 0, 1, 0) })
	end
	if final then task.delay(6, function() if pollF then pollF:Destroy(); pollF = nil; UI.PollBars = nil end end) end
end

-- ═════════════ ג'אמפסקייר (אדמין) ═════════════
local function jumpscare()
	local tmpl = RS:FindFirstChild("Templates") and RS.Templates:FindFirstChild("Terrorist")
	if not tmpl then return end
	local cam = workspace.CurrentCamera
	local m = tmpl:Clone()
	m:SetAttribute("Local", true); m:SetAttribute("NPC", true)
	m.HumanoidRootPart.Anchored = true
	local calm = UI.Settings.ReduceScare
	local cf = cam.CFrame
	local dist = calm and 9 or 2.3
	m:PivotTo(CFrame.lookAt(cf.Position + cf.LookVector * dist - Vector3.new(0, 1.6, 0), cf.Position - Vector3.new(0, 1.6, 0)))
	m.Parent = workspace
	if calm then
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 end end
		for k = 1, 20 do for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.LocalTransparencyModifier = 1 - k / 20 end end task.wait(0.05) end
		task.wait(1.2)
	else
		Audio.Play(Config.Sfx.Stinger, { vol = 1 })
		Audio.Play(Config.Sfx.Punch, { vol = 0.8 })
		Effects.Flash(0.5, 0.4)
		Effects.Shake(1)
		task.wait(1.1)
	end
	m:Destroy()
end

-- ═════════════ אירועי אדמין ═════════════
local events = {}
local function runEvent(kind, secs)
	if kind == "stop" then for k in pairs(events) do events[k] = 0 end; Show.Disco = 0; Effects.Grade(Effects.Current or "Lobby", 1) return end
	local hrp = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	local base = hrp and hrp.Position or Vector3.zero
	if kind == "disco" then
		Show.Disco = secs * 30
		events.disco = os.clock() + secs
		task.spawn(function()
			while os.clock() < (events.disco or 0) do
				Effects.Tint(Color3.fromHSV(math.random(), 0.5, 1), 0.25)
				if math.random() < 0.3 then Show.Burst(base + Vector3.new(math.random(-30, 30), 30, math.random(-30, 30)), "confetti") end
				task.wait(UI.Settings.ReduceFlash and 1.2 or 0.35)
			end
			Effects.Tint(Color3.new(1, 1, 1), 1)
		end)
	elseif kind == "fireworks" then
		task.spawn(function() for _ = 1, math.max(6, secs * 2) do Show.Firework(base + Vector3.new(math.random(-120, 120), 90 + math.random(0, 60), math.random(-120, 120))); task.wait(0.45) end end)
	elseif kind == "confetti" then
		for _ = 1, 5 do Show.Burst(base + Vector3.new(math.random(-20, 20), 25, math.random(-20, 20)), "confetti") end
	elseif kind == "drop" then
		Show.Drop(base + Vector3.new(0, 0, -60))
	elseif kind == "blackout" then
		local b0 = Lighting.Brightness
		Effects.tw(Lighting, 0.5, { Brightness = 0, ExposureCompensation = -3 })
		task.delay(secs, function() Effects.Grade(Effects.Current or "Lobby", 1.5) end)
	end
end

R.Story.OnClientEvent:Connect(function(name, ...)
	if name == "transition" then
		local n = ...
		UI.FadeTo(1, 0.8)
		if UI.LoadingL then UI.LoadingL:Destroy() end
		local ch = T.Chapters[n]
		UI.LoadingL = Bk.txt(UI.Gui, "טוען" .. (ch and (" · " .. ch.Name) or "") .. "…", UDim2.fromOffset(400, 40), UDim2.new(0.5, -200, 0.86, 0), 22, Enum.TextXAlignment.Center, 60)
		return
	end
	if name == "lobby" then toLobby() return end
	if name == "fail" then task.spawn(fail) return end
	if name == "respawn" then task.spawn(respawn) return end
	if name == "announce" then task.spawn(announce, ...) return end
	if name == "servermsg" then
		local t = ...
		if serverMsg then serverMsg:Destroy(); serverMsg = nil end
		if t and t ~= "" then
			serverMsg = new("Frame", { BackgroundColor3 = Color3.fromRGB(64, 170, 245), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 6), Size = UDim2.fromOffset(0, 36), AutomaticSize = Enum.AutomaticSize.X, ZIndex = 84, Parent = UI.Gui }, {
				UI.corner(4), new("UIStroke", { Color = Color3.fromRGB(8, 30, 60), Thickness = 3 }), new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(96, 196, 255), Color3.fromRGB(40, 140, 225)), Rotation = 90 }),
				new("UIPadding", { PaddingLeft = UDim.new(0, 24), PaddingRight = UDim.new(0, 24) }),
			})
			Bk.studs(serverMsg, Color3.new(1, 1, 1), UDim2.fromOffset(16, 12), 84)
			local l = Bk.txt(serverMsg, "ℹ️  " .. t, UDim2.fromOffset(0, 36), UDim2.new(), 18, Enum.TextXAlignment.Center, 85)
			l.AutomaticSize = Enum.AutomaticSize.X
			l.TextWrapped = false
		end
		return
	end
	if name == "poll" then showPoll(...) return end
	if name == "pollUpdate" then pollCounts(...) return end
	if name == "pollEnd" then pollCounts(..., true) return end
	if name == "warn" then
		local t = ...
		local root, body = Bk.window(UI.Gui, "אזהרה", "⚠️", UDim2.fromOffset(460, 220), UDim2.fromScale(0.5, 0.42), "orange", nil, 88)
		Bk.txt(body, t ~= "" and t or "שימו לב להתנהגות.", UDim2.new(1, -30, 0, 80), UDim2.fromOffset(15, 16), 20, Enum.TextXAlignment.Center, 90)
		Audio.Play(Config.Sfx.Ding, { vol = 0.5, speed = 0.8 })
		Bk.button(body, "הבנתי", "green", UDim2.fromOffset(140, 40), UDim2.new(0.5, -70, 1, -54), function() root:Destroy() end, 90)
		UI.PushCursor()
		root.Destroying:Connect(function() UI.PopCursor() end)
		task.delay(12, function() if root.Parent then root:Destroy() end end)
		return
	end
	if name == "vip" then
		local on = ...
		local root, body = Bk.window(UI.Gui, on and "VIP" or "VIP הוסר", "✨", UDim2.fromOffset(420, 190), UDim2.fromScale(0.5, 0.4), on and "yellow" or "gray", nil, 88)
		Bk.txt(body, on and "קיבלת גישה לאחורי הקלעים במסיבה!" or "גישת ה-VIP לאחורי הקלעים הוסרה.", UDim2.new(1, -30, 0, 70), UDim2.fromOffset(15, 14), 20, Enum.TextXAlignment.Center, 90)
		Audio.Play(Config.Sfx.Ding, { vol = 0.6, speed = 1.2 })
		task.delay(4, function() if root.Parent then root:Destroy() end end)
		return
	end
	if name == "event" then task.spawn(runEvent, ...) return end
	if name == "jumpscare" then task.spawn(jumpscare) return end
	if current and current.OnStory then task.spawn(current.OnStory, name, ...) end
end)

R.Fx.OnClientEvent:Connect(function(kind, a, b, c)
	if kind == "pshot" or kind == "down" then
		if kind == "pshot" then Audio.Play(Config.Sfx.Pistol, { pos = a, vol = 1, minDist = 20 }); if c == plr.UserId then Effects.Shake(0.15) end end
		if kind == "down" and a and a:FindFirstChild("HumanoidRootPart") then Audio.Play(Config.Sfx.BodyFall, { pos = a.HumanoidRootPart.Position, vol = 0.8 }) end
		return
	end
	if current and current.OnFx then current.OnFx(kind, a, b, c) end
end)

-- ═════════════ טבלת ניקוד (Tab) ═════════════
local scoreRows = {}
R.Score.OnClientEvent:Connect(function(rows) scoreRows = rows end)
local board
UIS.InputBegan:Connect(function(i, gp)
	if i.KeyCode == Enum.KeyCode.Tab then
		if board then board:Destroy() end
		board = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.45), Size = UDim2.fromOffset(560, 80 + #scoreRows * 36), ZIndex = 83, Parent = UI.Gui })
		UI.label({ Text = T.Hud.Scoreboard, FontFace = UI.FontBold, TextSize = 14, TextColor3 = UI.Colors.Muted, Size = UDim2.new(1, -40, 0, 24), Position = UDim2.fromOffset(20, 12), ZIndex = 84, Parent = board })
		local cols = T.Hud.ScoreCols
		for k, c in ipairs(cols) do UI.label({ Text = c, TextSize = 13, TextColor3 = UI.Colors.Muted, Size = UDim2.fromOffset(120, 20), Position = UDim2.new(1, -20 - k * 130, 0, 40), ZIndex = 84, Parent = board }) end
		for r, row in ipairs(scoreRows) do
			local vals = { row.name, string.format("%d:%02d", math.floor(row.time / 60), math.floor(row.time % 60)), tostring(row.puzzles), tostring(row.chapter) }
			for k, v in ipairs(vals) do UI.label({ Text = v, TextSize = 16, Size = UDim2.fromOffset(120, 30), Position = UDim2.new(1, -20 - k * 130, 0, 60 + (r - 1) * 36), ZIndex = 84, Parent = board }) end
		end
	elseif i.UserInputType == Enum.UserInputType.MouseButton1 and not gp and plr:GetAttribute("AdminRifle") and not Admin.Open then
		local cam = workspace.CurrentCamera
		R.Admin:FireServer("rshoot", cam.CFrame.Position, cam.CFrame.LookVector)
	end
end)
UIS.InputEnded:Connect(function(i) if i.KeyCode == Enum.KeyCode.Tab and board then board:Destroy(); board = nil end end)

-- ═════════════ אפקטים מקומיים: שער VIP, הבהוב נורות, דגלים, FPS (רשימה במטמון) ═════════════
local tagged = { gates = {}, flick = {}, wave = {} }
local function scan(root)
	for _, d in ipairs(root:GetDescendants()) do
		if d:IsA("BasePart") then
			if d:GetAttribute("VIPGate") then table.insert(tagged.gates, d)
			elseif d:GetAttribute("Flicker") then local l = d:FindFirstChildOfClass("PointLight"); if l then table.insert(tagged.flick, { l = l, base = l.Brightness }) end
			elseif d:GetAttribute("Wave") then table.insert(tagged.wave, { p = d, base = d.CFrame }) end
		end
	end
end
local function rescan()
	tagged = { gates = {}, flick = {}, wave = {} }
	for _, n in ipairs({ "Map", "LobbyMap" }) do local f = workspace:FindFirstChild(n); if f then scan(f) end end
end
workspace.ChildAdded:Connect(function(c) if c.Name == "Map" then task.delay(8, rescan); task.delay(25, rescan) end end)
task.delay(3, rescan)
R.Chapter.OnClientEvent:Connect(function() task.delay(1, rescan) end)
local acc, fpsAcc, frames = 0, 0, 0
RunService.RenderStepped:Connect(function(dt)
	frames += 1
	fpsAcc += dt
	if fpsAcc > 0.5 then UI.Fps.Text = math.floor(frames / fpsAcc) .. " FPS"; frames = 0; fpsAcc = 0 end
	acc += dt
	if acc < 0.1 then return end
	acc = 0
	local vip = plr:GetAttribute("VIP") == true or plr.UserId == Config.AdminUserId
	for _, g in ipairs(tagged.gates) do if g.Parent then g.CanCollide = not vip; g.LocalTransparencyModifier = vip and 0.6 or 0 end end
	local gentle = UI.Settings.ReduceFlash
	for _, f in ipairs(tagged.flick) do
		if f.l.Parent then
			local k = gentle and (0.85 + math.random() * 0.15) or ((math.random() < 0.04) and 0.1 or (0.8 + math.random() * 0.25))
			f.l.Brightness = f.base * k
		end
	end
	local t = os.clock()
	for _, w in ipairs(tagged.wave) do if w.p.Parent then w.p.CFrame = w.base * CFrame.Angles(0, math.sin(t * 3 + w.base.Position.X) * 0.12, 0) end end
	Audio.SetVolumes(UI.Settings.Music, UI.Settings.Sfx)
end)

-- ═════════════ התחלה ═════════════
FP.SetEnabled(false)
UI.PushCursor()
warning()
UI.PopCursor()
Admin.Init(R)
toLobby()
