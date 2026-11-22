-- ═══════════════════════════════════════════════════════════════════
--  מיני־משחקים: קצב (די־ג'יי), מעגל תופים (זיכרון), סלפי (מסגרת טלפון + פולארויד),
--  פענוח קוד טפיחות (פרק 3), מנגינת הצינורות של עידו (פרק 3)
-- ═══════════════════════════════════════════════════════════════════
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS.Shared.Texts)
local Config = require(RS.Shared.Config)
local UI = require(script.Parent.UI)
local Audio = require(script.Parent.Audio)
local Effects = require(script.Parent.Effects)
local new = UI.new

local M = {}
local function overlay()
	local f = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 55, Parent = UI.Gui })
	return f
end
local function freeMouse(on)
	if on then UI.PushCursor() else UI.PopCursor() end
end

--- קצב: 4 מסלולים (D F J K), תווים נופלים בקצב 142BPM. מחזיר 0..1
function M.Rhythm()
	local root = overlay()
	local panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(380, 520), ZIndex = 56, Parent = root })
	UI.label({ Text = T.CH1.Rhythm.Title, FontFace = UI.FontTitle, TextSize = 32, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 8), ZIndex = 57, Parent = panel })
	UI.label({ Text = T.CH1.Rhythm.Hint, TextColor3 = UI.Colors.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 50), ZIndex = 57, Parent = panel })
	local lane = new("Frame", { BackgroundTransparency = 1, Position = UDim2.fromOffset(10, 76), Size = UDim2.new(1, -20, 1, -120), ClipsDescendants = true, ZIndex = 57, Parent = panel })
	local fb = UI.label({ Text = "", FontFace = UI.FontBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, -40), ZIndex = 57, Parent = panel })
	local keys = { Enum.KeyCode.D, Enum.KeyCode.F, Enum.KeyCode.J, Enum.KeyCode.K }
	local cols = { Color3.fromRGB(255, 46, 136), Color3.fromRGB(25, 227, 255), Color3.fromRGB(155, 91, 255), Color3.fromRGB(255, 179, 71) }
	local W = 360 / 4
	local hitY = 360
	local rings = {}
	for i = 1, 4 do
		rings[i] = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset((i - 1) * W + W / 2 - 26 - 5, hitY - 26), ZIndex = 58, Parent = lane }, { UI.corner(26), new("UIStroke", { Color = cols[i], Thickness = 3, Transparency = 0.4 }) })
		UI.label({ Text = keys[i].Name, FontFace = UI.FontBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromOffset(W, 20), Position = UDim2.fromOffset((i - 1) * W - 5, hitY + 32), ZIndex = 58, Parent = lane })
	end
	local beat = 60 / 142
	local notes = {}
	local tt = 0
	local b = 4
	while tt < 22 do
		tt = b * beat
		if math.random() < 0.7 then table.insert(notes, { t = tt, lane = math.random(1, 4) }) end
		b += 1
	end
	local score, total, combo = 0, #notes, 0
	local t0 = os.clock()
	local conn = UIS.InputBegan:Connect(function(inp)
		local now = os.clock() - t0
		for l = 1, 4 do
			if inp.KeyCode == keys[l] then
				local best, bd = nil, 1e9
				for _, n in ipairs(notes) do if not n.hit and n.lane == l then local d = math.abs(n.t - now); if d < bd then bd, best = d, n end end end
				if best and bd < 0.16 then
					best.hit = true; combo += 1
					local perfect = bd < 0.06
					score += perfect and 1 or 0.6
					fb.Text = (perfect and T.CH1.Rhythm.Perfect or T.CH1.Rhythm.Good) .. (combo > 3 and ("  ×" .. combo) or "")
					fb.TextColor3 = cols[l]
					if best.ui then best.ui:Destroy() end
					UI.tween(rings[l], 0.08, { Size = UDim2.fromOffset(62, 62) }).Completed:Connect(function() UI.tween(rings[l], 0.15, { Size = UDim2.fromOffset(52, 52) }) end)
				else combo = 0; fb.Text = "·"; fb.TextColor3 = UI.Colors.Muted end
			end
		end
	end)
	while os.clock() - t0 < 23.5 do
		local now = os.clock() - t0
		for _, n in ipairs(notes) do
			if not n.hit then
				local y = hitY - (n.t - now) * 300
				if y > -40 and y < 460 then
					n.ui = n.ui or new("Frame", { BackgroundColor3 = cols[n.lane], Size = UDim2.fromOffset(40, 40), ZIndex = 59, Parent = lane }, { UI.corner(20), new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 1, Transparency = 0.6 }) })
					n.ui.Position = UDim2.fromOffset((n.lane - 1) * W + W / 2 - 20 - 5, y - 20)
				end
				if y > 460 then n.hit = "miss"; combo = 0; if n.ui then n.ui:Destroy() end end
			end
		end
		RunService.RenderStepped:Wait()
	end
	conn:Disconnect()
	root:Destroy()
	return score / math.max(1, total)
end

--- מעגל תופים: המתופף מנגן רצף, השחקן חוזר ב-Q W E R. 3 סיבובים
function M.Drums()
	local root = overlay()
	local panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(460, 260), ZIndex = 56, Parent = root })
	UI.label({ Text = T.CH1.Drums.Title, FontFace = UI.FontTitle, TextSize = 30, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), ZIndex = 57, Parent = panel })
	UI.label({ Text = T.CH1.Drums.Hint, TextColor3 = UI.Colors.Muted, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 18), Position = UDim2.fromOffset(0, 50), ZIndex = 57, Parent = panel })
	local st = UI.label({ Text = "", TextSize = 20, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.new(0, 0, 1, -36), ZIndex = 57, Parent = panel })
	local keys = { Enum.KeyCode.Q, Enum.KeyCode.W, Enum.KeyCode.E, Enum.KeyCode.R }
	local pads = {}
	for i = 1, 4 do
		pads[i] = new("TextLabel", { Text = keys[i].Name, FontFace = UI.FontBold, TextSize = 22, TextColor3 = Color3.fromRGB(42, 26, 10), BackgroundColor3 = Color3.fromRGB(201, 160, 112), Size = UDim2.fromOffset(84, 84), Position = UDim2.fromOffset(28 + (i - 1) * 104, 86), ZIndex = 58, Parent = panel }, { UI.corner(42), new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(230, 190, 140), Color3.fromRGB(122, 85, 52)), Rotation = 60 }) })
	end
	local speeds = { 0.9, 1.1, 1.4, 1.7 }
	local function flash(i)
		Audio.Play(Config.Sfx.Knock, { vol = 0.8, speed = speeds[i] })
		UI.tween(pads[i], 0.07, { Size = UDim2.fromOffset(94, 94) }).Completed:Connect(function() UI.tween(pads[i], 0.12, { Size = UDim2.fromOffset(84, 84) }) end)
	end
	Audio.Music("Djembe", 0.4, 1)
	local seq, ok = {}, 0
	for _ = 1, 3 do
		table.insert(seq, math.random(1, 4)); table.insert(seq, math.random(1, 4))
		st.Text = "♪"; task.wait(0.7)
		for _, i in ipairs(seq) do flash(i); task.wait(0.42) end
		st.Text = "…"
		local idx, fail = 1, false
		local c = UIS.InputBegan:Connect(function(inp)
			for k = 1, 4 do if inp.KeyCode == keys[k] then flash(k); if seq[idx] ~= k then fail = true end; idx += 1 end end
		end)
		while not fail and idx <= #seq do task.wait() end
		c:Disconnect()
		st.Text = fail and "~" or "✓"
		if not fail then ok += 1 end
		task.wait(0.6)
	end
	Audio.Music("Party", 0.6, 1)
	root:Destroy()
	return ok / 3
end

--- סלפי: מסגרת טלפון, קליק לצילום, הבזק ופולארויד
function M.Selfie()
	local root = overlay()
	local phone = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(0.28, 0.86), ZIndex = 56, Parent = root }, {
		UI.corner(34), new("UIStroke", { Color = Color3.fromRGB(17, 17, 17), Thickness = 12 }), new("UIAspectRatioConstraint", { AspectRatio = 9 / 16 }),
	})
	new("Frame", { BackgroundColor3 = Color3.fromRGB(17, 17, 17), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(80, 20), ZIndex = 57, Parent = phone }, { UI.corner(10) })
	local shutter = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -18), Size = UDim2.fromOffset(58, 58), ZIndex = 57, Parent = phone }, { UI.corner(29), new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 4 }) })
	UI.label({ Text = T.CH1.SelfieHint, TextColor3 = UI.Colors.Muted, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -20), Size = UDim2.fromOffset(300, 20), ZIndex = 57, Parent = root })
	freeMouse(true)
	local clicked = false
	local c = UIS.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.KeyCode == Enum.KeyCode.E then clicked = true end end)
	while not clicked do task.wait() end
	c:Disconnect()
	Audio.Play(Config.Sfx.Shutter, { vol = 0.8 })
	Effects.Flash(0.9, 0.5)
	freeMouse(false)
	phone:Destroy()
	-- פולארויד
	local pol = new("Frame", { BackgroundColor3 = Color3.fromRGB(244, 239, 230), AnchorPoint = Vector2.new(0, 0), Position = UDim2.new(0.06, 0, 0.12, -20), Size = UDim2.fromOffset(220, 250), Rotation = -6, BackgroundTransparency = 1, ZIndex = 57, Parent = root }, { new("UIPadding", { PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 40) }) })
	local view = new("ViewportFrame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(20, 12, 40), ZIndex = 58, Ambient = Color3.fromRGB(200, 170, 255), LightColor = Color3.fromRGB(255, 220, 255), Parent = pol })
	local vc = Instance.new("Camera"); vc.CFrame = workspace.CurrentCamera.CFrame; vc.FieldOfView = 60; vc.Parent = view; view.CurrentCamera = vc
	for _, m in ipairs(workspace:GetPartBoundsInRadius(workspace.CurrentCamera.CFrame.Position, 9)) do
		if m.Parent and m.Parent:FindFirstChildOfClass("Humanoid") and (m.Transparency < 1) then m:Clone().Parent = view end
	end
	UI.tween(pol, 0.6, { BackgroundTransparency = 0, Position = UDim2.new(0.06, 0, 0.12, 0) })
	task.wait(4)
	UI.tween(pol, 0.6, { BackgroundTransparency = 1 })
	view.Visible = false
	task.wait(0.6)
	root:Destroy()
end

--- פענוח קוד טפיחות: מנגן את הדפיקות ומציג לוח. מחזיר כשמוקלדת המילה הנכונה
function M.Decode(word, grid, knockPos)
	local code = {}
	for _, ch in utf8.codes(word) do
		local c = utf8.char(ch)
		for r, row in ipairs(grid) do
			local col = 0
			for _, g in utf8.codes(row) do col += 1; if utf8.char(g) == c then table.insert(code, { r, col }) end end
		end
	end
	task.spawn(function()
		local d = 0
		for _, rc in ipairs(code) do
			for _ = 1, rc[1] do task.delay(d, function() Audio.Play(Config.Sfx.Knock, { pos = knockPos, vol = 0.9 }) end); d += 0.32 end
			d += 0.6
			for _ = 1, rc[2] do task.delay(d, function() Audio.Play(Config.Sfx.Knock, { pos = knockPos, vol = 0.9 }) end); d += 0.32 end
			d += 1.2
		end
	end)
	local root = overlay()
	local panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(520, 470), ZIndex = 56, Parent = root })
	UI.label({ Text = T.CH3.DecodeTitle, FontFace = UI.FontTitle, TextSize = 28, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 40), Position = UDim2.fromOffset(0, 10), ZIndex = 57, Parent = panel })
	UI.label({ Text = T.CH3.DecodeHint, TextColor3 = UI.Colors.Muted, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, -40, 0, 36), Position = UDim2.fromOffset(20, 50), ZIndex = 57, Parent = panel })
	for r, row in ipairs(grid) do
		local col, letters = 0, {}
		for _, g in utf8.codes(row) do col += 1; table.insert(letters, utf8.char(g) .. '<font size="12" color="#6C665F">' .. col .. "</font>") end
		UI.label({ Text = '<font color="#FFB35C"><b>' .. r .. "</b></font>    " .. table.concat(letters, "    "), TextSize = 24, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 34), Position = UDim2.fromOffset(0, 90 + r * 36), ZIndex = 57, Parent = panel })
	end
	local codeStr = {}
	for _, rc in ipairs(code) do table.insert(codeStr, rc[1] .. "·" .. rc[2]) end
	local codeL = UI.label({ Text = table.concat(codeStr, "     "), TextColor3 = UI.Colors.Accent, TextSize = 22, TextDirection = Enum.TextDirection.LeftToRight, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.fromOffset(0, 320), ZIndex = 57, TextTransparency = 1, Parent = panel })
	task.delay(6, function() UI.tween(codeL, 1, { TextTransparency = 0 }) end)
	local box = new("TextBox", { Text = "", PlaceholderText = "…", FontFace = UI.FontBold, TextSize = 26, TextColor3 = UI.Colors.Ink, BackgroundColor3 = Color3.fromRGB(21, 18, 27), Size = UDim2.fromOffset(260, 48), Position = UDim2.new(0.5, -130, 0, 362), TextDirection = Enum.TextDirection.RightToLeft, ClearTextOnFocus = false, ZIndex = 57, Parent = panel }, { UI.corner(10), UI.stroke() })
	freeMouse(true)
	local solved = false
	box.FocusLost:Connect(function()
		if box.Text:gsub("%s", "") == word then solved = true else box.Text = ""; UI.tween(box, 0.05, { Position = UDim2.new(0.5, -120, 0, 362) }).Completed:Connect(function() UI.tween(box, 0.1, { Position = UDim2.new(0.5, -130, 0, 362) }) end) end
	end)
	box:CaptureFocus()
	while not solved do task.wait(0.1) end
	freeMouse(false)
	root:Destroy()
end

--- מנגינת עידו: חוזרים על רצף של 5 צלילים בצינורות (מקשים 1–4)
function M.PipeMelody(onNote)
	local root = overlay()
	local panel = UI.panel({ AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -40), Size = UDim2.fromOffset(420, 150), ZIndex = 56, Parent = root })
	UI.label({ Text = T.CH3.PipeHint, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(0, 10), ZIndex = 57, Parent = panel })
	local keys = { Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four }
	local pads = {}
	for i = 1, 4 do pads[i] = new("TextLabel", { Text = tostring(i), FontFace = UI.FontBold, TextSize = 20, TextColor3 = UI.Colors.Ink, BackgroundColor3 = Color3.fromRGB(120, 110, 95), Size = UDim2.fromOffset(80, 70), Position = UDim2.fromOffset(20 + (i - 1) * 98, 52), ZIndex = 57, Parent = panel }, { UI.corner(10) }) end
	local speeds = { 0.8, 0.95, 1.1, 1.3 }
	local melody = { 1, 3, 4, 3, 2 }
	local function play(i) Audio.Play(Config.Sfx.Pipe, { vol = 0.9, speed = speeds[i] }); UI.tween(pads[i], 0.06, { BackgroundColor3 = UI.Colors.Accent }).Completed:Connect(function() UI.tween(pads[i], 0.3, { BackgroundColor3 = Color3.fromRGB(120, 110, 95) }) end); if onNote then onNote(i) end end
	local success = false
	while not success do
		task.wait(0.6)
		for _, i in ipairs(melody) do play(i); task.wait(0.55) end
		local idx, fail = 1, false
		local c = UIS.InputBegan:Connect(function(inp) for k = 1, 4 do if inp.KeyCode == keys[k] then play(k); if melody[idx] ~= k then fail = true end; idx += 1 end end end)
		while not fail and idx <= #melody do task.wait() end
		c:Disconnect()
		success = not fail
	end
	root:Destroy()
end

return M
