-- ═══════════════════════════════════════════════════════════════════
--  UI – ממשק עברי (RTL) מעוצב: כתוביות, דיאלוגים ובחירות, הנחיות (ProximityPrompt מותאם),
--  מטרה, כרטיס פרק, פייד, Letterbox, עפעפיים, ויניטה, קצה אדום, הערה, טוסט, מיני־מפה, קרדיטים
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local PPS = game:GetService("ProximityPromptService")
local RS = game:GetService("ReplicatedStorage")
local T = require(RS:WaitForChild("Shared"):WaitForChild("Texts"))
local plr = Players.LocalPlayer

local UI = {}
UI.Settings = { ReduceScare = false, ReduceFlash = false, BigSubs = false, Music = 0.7, Sfx = 0.9 }
UI.Ctx = { gender = "m", name = "" }
UI.Cursor = 0
function UI.PushCursor() UI.Cursor += 1 end
function UI.PopCursor() UI.Cursor = math.max(0, UI.Cursor - 1) end

local INK = Color3.fromRGB(244, 239, 230)
local MUTED = Color3.fromRGB(165, 159, 150)
local ACCENT = Color3.fromRGB(255, 179, 92)
local GLASS = Color3.fromRGB(14, 12, 20)
UI.Colors = { Ink = INK, Muted = MUTED, Accent = ACCENT, Glass = GLASS }

local FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Regular)
local FONT_B = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Bold)
local FONT_T = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Light)
UI.Font, UI.FontBold, UI.FontTitle = FONT, FONT_B, FONT_T

local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quint, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end
UI.tween = tween

function UI.F(s) return T.F(s, UI.Ctx.gender, UI.Ctx.name) end

local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do if k ~= "Parent" then o[k] = v end end
	for _, c in ipairs(children or {}) do c.Parent = o end
	if props and props.Parent then o.Parent = props.Parent end
	return o
end
UI.new = new
function UI.corner(r) return new("UICorner", { CornerRadius = UDim.new(0, r or 12) }) end
function UI.stroke(c, t, tr) return new("UIStroke", { Color = c or Color3.fromRGB(255, 240, 220), Thickness = t or 1, Transparency = tr or 0.85 }) end
function UI.label(props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1, TextColor3 = INK, FontFace = FONT, TextSize = 18, TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Right, TextDirection = Enum.TextDirection.RightToLeft, RichText = true,
	})
	for k, v in pairs(props) do l[k] = v end
	return l
end
function UI.button(props, primary)
	local b = new("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = primary and Color3.fromRGB(255, 160, 100) or Color3.fromRGB(40, 34, 52),
		TextColor3 = primary and Color3.fromRGB(27, 16, 6) or INK, FontFace = FONT_B, TextSize = 17,
		TextDirection = Enum.TextDirection.RightToLeft, Size = UDim2.fromOffset(240, 46),
	}, { UI.corner(12), UI.stroke(nil, 1, primary and 1 or 0.85) })
	if primary then new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(255, 191, 112), Color3.fromRGB(255, 138, 92)), Rotation = 30, Parent = b }) end
	for k, v in pairs(props) do b[k] = v end
	b.MouseEnter:Connect(function() tween(b, 0.18, { Size = b.Size + UDim2.fromOffset(4, 2) }) if UI.Hover then UI.Hover() end end)
	b.MouseLeave:Connect(function() tween(b, 0.18, { Size = b.Size - UDim2.fromOffset(4, 2) }) end)
	return b
end
function UI.panel(props)
	local f = new("Frame", { BackgroundColor3 = GLASS, BackgroundTransparency = 0.2 }, { UI.corner(20), UI.stroke(nil, 1, 0.86) })
	for k, v in pairs(props) do f[k] = v end
	return f
end

-- ─────────────── שכבות ───────────────
function UI.Init()
	local gui = new("ScreenGui", { Name = "Hazricha", ResetOnSpawn = false, IgnoreGuiInset = true, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 10, Parent = plr:WaitForChild("PlayerGui") })
	UI.Gui = gui
	-- ויניטה (ארבעה קצוות עם גרדיאנט)
	local vig = new("Frame", { Name = "Vignette", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 2, Parent = gui })
	UI.VigParts = {}
	for i, rot in ipairs({ 0, 90, 180, 270 }) do
		local f = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, ZIndex = 2, Parent = vig })
		if rot == 0 or rot == 180 then f.Size = UDim2.new(1, 0, 0.32, 0); f.Position = rot == 0 and UDim2.new(0, 0, 0, 0) or UDim2.new(0, 0, 0.68, 0)
		else f.Size = UDim2.new(0.26, 0, 1, 0); f.Position = rot == 270 and UDim2.new(0, 0, 0, 0) or UDim2.new(0.74, 0, 0, 0) end
		local grad = new("UIGradient", { Rotation = ({ 90, 180, 270, 0 })[i], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 1) }), Parent = f })
		table.insert(UI.VigParts, { f = f, g = grad })
	end
	UI.Vignette = vig
	UI.SetVignette(0.45)
	-- קצה אדום (פגיעה)
	local hit = new("Frame", { Name = "Hit", Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 3, Parent = gui })
	for i = 1, 4 do
		local f = new("Frame", { BackgroundColor3 = Color3.fromRGB(120, 5, 5), BorderSizePixel = 0, ZIndex = 3, BackgroundTransparency = 1, Parent = hit })
		f.Size = (i <= 2) and UDim2.new(1, 0, 0.3, 0) or UDim2.new(0.25, 0, 1, 0)
		f.Position = ({ UDim2.new(0, 0, 0, 0), UDim2.new(0, 0, 0.7, 0), UDim2.new(0, 0, 0, 0), UDim2.new(0.75, 0, 0, 0) })[i]
		new("UIGradient", { Rotation = ({ 90, 270, 0, 180 })[i], Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1) }), Parent = f })
	end
	UI.HitFrame = hit
	-- Letterbox
	UI.BarTop = new("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), ZIndex = 40, Parent = gui })
	UI.BarBot = new("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(1, 0, 0, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.fromScale(0, 1), ZIndex = 40, Parent = gui })
	-- עפעפיים
	UI.LidTop = new("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(1.4, 0, 0, 0), Position = UDim2.new(-0.2, 0, 0, 0), ZIndex = 45, Parent = gui }, { UI.corner(9999) })
	UI.LidBot = new("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.new(1.4, 0, 0, 0), AnchorPoint = Vector2.new(0, 1), Position = UDim2.new(-0.2, 0, 1, 0), ZIndex = 45, Parent = gui }, { UI.corner(9999) })
	-- פייד
	UI.Fade = new("Frame", { BackgroundColor3 = Color3.new(), BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 0, ZIndex = 50, Parent = gui })
	-- כתוביות
	UI.Subs = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.9, 0), Size = UDim2.new(0.7, 0, 0.3, 0), ZIndex = 30, Parent = gui }, {
		new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	-- בחירות
	UI.Choices = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0.72, 0), Size = UDim2.new(0, 560, 0, 220), ZIndex = 31, Visible = false, Parent = gui }, {
		new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }),
	})
	-- מטרה
	UI.Obj = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -30, 0, 28), Size = UDim2.fromOffset(380, 60), ZIndex = 20, Parent = gui })
	UI.ObjLbl = UI.label({ Text = T.Hud.Objective, TextColor3 = ACCENT, TextSize = 12, FontFace = FONT_B, Size = UDim2.new(1, 0, 0, 16), TextTransparency = 1, Parent = UI.Obj })
	UI.ObjTxt = UI.label({ Text = "", TextSize = 19, FontFace = FONT_B, Position = UDim2.fromOffset(0, 18), Size = UDim2.new(1, 0, 0, 40), TextTransparency = 1, TextStrokeTransparency = 0.6, Parent = UI.Obj })
	-- כרטיס פרק
	UI.Card = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 35, Visible = false, Parent = gui })
	UI.CardNum = UI.label({ TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = ACCENT, TextSize = 14, FontFace = FONT_B, Position = UDim2.new(0, 0, 0.38, 0), Size = UDim2.new(1, 0, 0, 20), Parent = UI.Card })
	UI.CardName = UI.label({ TextXAlignment = Enum.TextXAlignment.Center, TextSize = 96, FontFace = FONT_T, Position = UDim2.new(0, 0, 0.42, 0), Size = UDim2.new(1, 0, 0, 110), TextStrokeTransparency = 0.7, Parent = UI.Card })
	UI.CardSub = UI.label({ TextXAlignment = Enum.TextXAlignment.Center, TextColor3 = MUTED, TextSize = 20, Position = UDim2.new(0, 0, 0.42, 116), Size = UDim2.new(1, 0, 0, 26), Parent = UI.Card })
	-- הערה קטנה + טוסט
	UI.NoteL = UI.label({ TextXAlignment = Enum.TextXAlignment.Center, TextSize = 16, TextColor3 = Color3.fromRGB(230, 230, 230), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.76, 0), Size = UDim2.fromOffset(500, 24), TextTransparency = 1, TextStrokeTransparency = 0.5, ZIndex = 20, Parent = gui })
	UI.ToastF = UI.panel({ AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -60), Size = UDim2.fromOffset(420, 44), ZIndex = 60, Parent = gui })
	UI.ToastL = UI.label({ TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1), ZIndex = 61, Parent = UI.ToastF })
	-- הנחיית אינטראקציה מותאמת
	UI.PromptF = UI.panel({ AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.6, 0), Size = UDim2.fromOffset(220, 42), BackgroundTransparency = 0.25, Visible = false, ZIndex = 25, Parent = gui })
	UI.PromptKey = new("TextLabel", { BackgroundColor3 = Color3.new(1, 1, 1), TextColor3 = Color3.fromRGB(17, 17, 17), FontFace = FONT_B, TextSize = 15, Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -36, 0.5, -14), ZIndex = 26, Parent = UI.PromptF }, { UI.corner(7) })
	UI.PromptTxt = UI.label({ Size = UDim2.new(1, -52, 1, 0), Position = UDim2.fromOffset(8, 0), TextSize = 16, ZIndex = 26, Parent = UI.PromptF })
	UI.PromptBar = new("Frame", { BackgroundColor3 = ACCENT, BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 3), Position = UDim2.new(0, 0, 1, -3), ZIndex = 27, Parent = UI.PromptF })
	-- מיני־מפה
	UI.Mini = new("Frame", { BackgroundColor3 = Color3.fromRGB(20, 24, 28), BackgroundTransparency = 0.15, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -24), Size = UDim2.fromOffset(220, 220), ClipsDescendants = true, Visible = false, ZIndex = 22, Parent = gui }, { UI.corner(110), UI.stroke(Color3.new(1, 1, 1), 2, 0.8) })
	UI.MiniWorld = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromScale(1, 1), ZIndex = 22, Parent = UI.Mini })
	new("TextLabel", { Text = "▲", BackgroundTransparency = 1, TextColor3 = Color3.new(1, 1, 1), TextSize = 18, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(20, 20), ZIndex = 24, Parent = UI.Mini })
	-- FPS
	UI.Fps = new("TextLabel", { BackgroundTransparency = 1, TextColor3 = Color3.fromRGB(150, 255, 150), FontFace = FONT, TextSize = 13, Position = UDim2.fromOffset(12, 10), Size = UDim2.fromOffset(100, 16), TextXAlignment = Enum.TextXAlignment.Left, Visible = false, ZIndex = 70, Parent = gui })
	-- הנחיות בהתאמה אישית
	PPS.PromptShown:Connect(function(pp) UI.ShowPrompt(pp) end)
	PPS.PromptHidden:Connect(function(pp) if UI.CurrentPrompt == pp then UI.HidePrompt() end end)
	PPS.PromptButtonHoldBegan:Connect(function(pp) if UI.CurrentPrompt == pp then UI.PromptBar.Size = UDim2.new(0, 0, 0, 3); tween(UI.PromptBar, pp.HoldDuration, { Size = UDim2.new(1, 0, 0, 3) }, Enum.EasingStyle.Linear) end end)
	PPS.PromptButtonHoldEnded:Connect(function() UI.PromptBar.Size = UDim2.new(0, 0, 0, 3) end)
end

function UI.SetVignette(a)
	for _, v in ipairs(UI.VigParts or {}) do
		v.g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, math.clamp(1 - a, 0, 1)), NumberSequenceKeypoint.new(1, 1) })
	end
end
function UI.Hit(a) for _, f in ipairs(UI.HitFrame:GetChildren()) do f.BackgroundTransparency = 1 - a * 0.85 end end
function UI.FadeTo(a, t) return tween(UI.Fade, t or 1, { BackgroundTransparency = 1 - a }, Enum.EasingStyle.Sine) end
function UI.Letterbox(on, t)
	local h = on and UDim2.new(1, 0, 0.12, 0) or UDim2.new(1, 0, 0, 0)
	tween(UI.BarTop, t or 1.4, { Size = h }); tween(UI.BarBot, t or 1.4, { Size = h })
end
--- עפעפיים: 0 פתוח, 1 סגור
function UI.Eyelid(a, t)
	local h = UDim2.new(1.4, 0, 0.62 * a, 0)
	tween(UI.LidTop, t or 0.6, { Size = h }, Enum.EasingStyle.Sine); return tween(UI.LidBot, t or 0.6, { Size = h }, Enum.EasingStyle.Sine)
end

function UI.ShowPrompt(pp)
	if UI.Hidden or UI.BlockPrompts then return end
	UI.CurrentPrompt = pp
	UI.PromptTxt.Text = pp.ActionText
	UI.PromptKey.Text = pp.KeyboardKeyCode.Name:gsub("^Button", "")
	UI.PromptBar.Size = UDim2.new(0, 0, 0, 3)
	local w = math.max(180, 70 + #pp.ActionText * 8)
	UI.PromptF.Size = UDim2.fromOffset(w, 42)
	UI.PromptF.Visible = true
	UI.PromptF.BackgroundTransparency = 1
	tween(UI.PromptF, 0.2, { BackgroundTransparency = 0.25 })
end
function UI.HidePrompt() UI.CurrentPrompt = nil; UI.PromptF.Visible = false end

function UI.Objective(text)
	if not text then tween(UI.ObjLbl, 0.5, { TextTransparency = 1 }); tween(UI.ObjTxt, 0.5, { TextTransparency = 1 }) return end
	UI.ObjTxt.Text = UI.F(text)
	UI.Obj.Position = UDim2.new(1, -10, 0, 28)
	tween(UI.Obj, 0.7, { Position = UDim2.new(1, -30, 0, 28) })
	tween(UI.ObjLbl, 0.5, { TextTransparency = 0 }); tween(UI.ObjTxt, 0.5, { TextTransparency = 0 })
	local tok = {}
	UI._objTok = tok
	task.delay(8, function() if UI._objTok == tok then tween(UI.ObjTxt, 1, { TextTransparency = 0.6 }); tween(UI.ObjLbl, 1, { TextTransparency = 0.6 }) end end)
end
function UI.Note(text)
	if not text then tween(UI.NoteL, 0.4, { TextTransparency = 1 }) return end
	UI.NoteL.Text = UI.F(text); tween(UI.NoteL, 0.4, { TextTransparency = 0 })
end
function UI.Toast(text, dur)
	UI.ToastL.Text = UI.F(text)
	tween(UI.ToastF, 0.35, { Position = UDim2.new(0.5, 0, 0, 24) })
	local tok = {}
	UI._toastTok = tok
	task.delay(dur or 2.6, function() if UI._toastTok == tok then tween(UI.ToastF, 0.35, { Position = UDim2.new(0.5, 0, 0, -60) }) end end)
end

local function subLine(who, text, big)
	local name = who and who ~= "" and (T.Names[who] or who) or nil
	local str = UI.F(text)
	local size = UI.Settings.BigSubs and 28 or 20
	local f = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), ZIndex = 30 }, {
		UI.corner(10), new("UIPadding", { PaddingLeft = UDim.new(0, 16), PaddingRight = UDim.new(0, 16), PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8) }),
	})
	local l = UI.label({ Text = (name and ('<font color="#FFB35C"><b>' .. name .. '</b></font>  ') or "") .. str .. (big and '  <font color="#6C665F" size="12">E ›</font>' or ""), TextSize = size, AutomaticSize = Enum.AutomaticSize.XY, Size = UDim2.fromOffset(0, 0), TextXAlignment = Enum.TextXAlignment.Center, TextTransparency = 1, TextStrokeTransparency = 0.7, ZIndex = 31, Parent = f })
	new("UISizeConstraint", { MaxSize = Vector2.new(900, 400), Parent = l })
	f.Parent = UI.Subs
	tween(f, 0.3, { BackgroundTransparency = UI.Settings.BigSubs and 0.18 or 0.45 }); tween(l, 0.3, { TextTransparency = 0 })
	return f, l, str
end
local function removeLine(f, l)
	tween(f, 0.3, { BackgroundTransparency = 1 }); tween(l, 0.3, { TextTransparency = 1 })
	task.delay(0.35, function() f:Destroy() end)
end

--- כתובית לא חוסמת
function UI.Bark(who, text, dur)
	local f, l, str = subLine(who, text, false)
	task.delay(dur or math.max(1.8, 0.9 + #str * 0.05), function() removeLine(f, l) end)
end
--- כתובית חוסמת עם משך
function UI.Sub(who, text, dur)
	local f, l, str = subLine(who, text, false)
	task.wait(dur or math.max(1.8, 0.9 + #str * 0.05))
	removeLine(f, l)
end

local function waitSkip(sec)
	local t0 = os.clock()
	local skipped = false
	local c = UIS.InputBegan:Connect(function(i, gp)
		if os.clock() - t0 > 0.35 and (i.KeyCode == Enum.KeyCode.E or i.KeyCode == Enum.KeyCode.Space or i.UserInputType == Enum.UserInputType.MouseButton1) then skipped = true end
	end)
	while os.clock() - t0 < sec and not skipped do task.wait() end
	c:Disconnect()
end

--- שורות דיאלוג ברצף, עם דילוג (E/רווח/קליק). speakers[who] = Model (להנפשת פה)
function UI.Lines(lines, speakers)
	for _, ln in ipairs(lines) do
		local who, text = ln[1], ln[2]
		local model = speakers and speakers[who]
		if model then model:SetAttribute("Talking", true) end
		if UI.Click then UI.Click() end
		local f, l, str = subLine(who, text, true)
		waitSkip(math.max(2.2, 1.0 + #str * 0.06))
		if model then model:SetAttribute("Talking", false) end
		removeLine(f, l)
		task.wait(0.12)
	end
end

--- בחירה מתוך אפשרויות – מחזיר אינדקס
function UI.Choose(choices)
	UI.Choices:ClearAllChildren()
	new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8), Parent = UI.Choices })
	UI.Choices.Visible = true
	UI.PushCursor()
	local picked
	local conns = {}
	for i, c in ipairs(choices) do
		local b = UI.button({ Size = UDim2.fromOffset(540, 48), Text = "", ZIndex = 32, Parent = UI.Choices })
		b.BackgroundTransparency = 0.15
		UI.label({ Text = UI.F(c.text), Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(10, 0), TextSize = UI.Settings.BigSubs and 22 or 17, ZIndex = 33, Parent = b })
		new("TextLabel", { Text = tostring(i), BackgroundColor3 = Color3.fromRGB(255, 255, 255), BackgroundTransparency = 0.88, TextColor3 = INK, FontFace = FONT_B, TextSize = 14, Size = UDim2.fromOffset(26, 26), Position = UDim2.new(1, -38, 0.5, -13), ZIndex = 33, Parent = b }, { UI.corner(6) })
		table.insert(conns, b.MouseButton1Click:Connect(function() picked = i end))
	end
	table.insert(conns, UIS.InputBegan:Connect(function(inp)
		local n = ({ [Enum.KeyCode.One] = 1, [Enum.KeyCode.Two] = 2, [Enum.KeyCode.Three] = 3 })[inp.KeyCode]
		if n and n <= #choices then picked = n end
	end))
	while not picked do task.wait() end
	for _, c in ipairs(conns) do c:Disconnect() end
	if UI.Click then UI.Click() end
	UI.Choices.Visible = false
	UI.Choices:ClearAllChildren()
	UI.PopCursor()
	return picked
end

--- עץ שיחה. onAct(act) לאירועים, onTrust(who)
function UI.Dialog(tree, startId, speakers, onAct, onTrust)
	local id = startId
	while id do
		local node = tree[id]
		if not node then break end
		UI.Lines(node.lines, speakers)
		if node.choices then
			local i = UI.Choose(node.choices)
			local c = node.choices[i]
			if c.trust and onTrust then onTrust(c.trust) end
			if c.act and onAct then onAct(c.act) end
			id = c.next
		else
			id = node.next
		end
	end
end

function UI.ChapterCard(n)
	local c = T.Chapters[n]
	if not c then return end
	UI.CardNum.Text = T.Hud.Chapter .. " " .. T.Hud.ChapterNum[n]
	UI.CardName.Text = c.Name
	UI.CardSub.Text = c.Sub
	for _, l in ipairs({ UI.CardNum, UI.CardName, UI.CardSub }) do l.TextTransparency = 1 end
	UI.Card.Visible = true
	for _, l in ipairs({ UI.CardNum, UI.CardName, UI.CardSub }) do tween(l, 1.2, { TextTransparency = 0 }, Enum.EasingStyle.Sine) end
	task.wait(4)
	for _, l in ipairs({ UI.CardNum, UI.CardName, UI.CardSub }) do tween(l, 1.0, { TextTransparency = 1 }, Enum.EasingStyle.Sine) end
	task.wait(1.1)
	UI.Card.Visible = false
end

function UI.SetHidden(h)
	UI.Hidden = h
	for _, f in ipairs({ UI.Subs, UI.Obj, UI.NoteL, UI.PromptF, UI.Mini }) do f.Visible = not h and (f ~= UI.PromptF or UI.CurrentPrompt ~= nil) and (f ~= UI.Mini or UI.MiniOn == true) end
end

--- מסך הקדשה וקרדיטים
function UI.Credits()
	local f = new("Frame", { BackgroundColor3 = Color3.new(), Size = UDim2.fromScale(1, 1), ZIndex = 80, Parent = UI.Gui })
	local candle = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 190, 110), Size = UDim2.fromOffset(10, 28), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.36, 0), ZIndex = 81, Parent = f }, { UI.corner(5) })
	local glow = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 160, 60), BackgroundTransparency = 0.6, Size = UDim2.fromOffset(140, 140), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, 0, 0.36, 0), ZIndex = 80, Parent = f }, {
		UI.corner(70), new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }) }),
	})
	local ded = UI.label({ Text = T.Dedication, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FONT_T, TextSize = 40, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0.46, 0), Size = UDim2.new(0.8, 0, 0, 140), TextTransparency = 1, ZIndex = 81, Parent = f })
	tween(ded, 3, { TextTransparency = 0 }, Enum.EasingStyle.Sine)
	task.wait(9)
	tween(ded, 2, { TextTransparency = 1 }, Enum.EasingStyle.Sine); tween(candle, 2, { BackgroundTransparency = 1 }); tween(glow, 2, { BackgroundTransparency = 1 })
	task.wait(2.2)
	local roll = new("Frame", { BackgroundTransparency = 1, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 0), Size = UDim2.new(0, 700, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, ZIndex = 81, Parent = f }, {
		new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 28) }),
	})
	UI.label({ Text = T.Title, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FONT_T, TextSize = 52, Size = UDim2.new(1, 0, 0, 70), ZIndex = 82, Parent = roll })
	for _, c in ipairs(T.Credits) do
		UI.label({ Text = '<font color="#A59F96" size="14">' .. c[1] .. '</font>\n' .. c[2], TextXAlignment = Enum.TextXAlignment.Center, TextSize = 20, Size = UDim2.new(1, 0, 0, 60), ZIndex = 82, Parent = roll })
	end
	UI.label({ Text = T.Dedication, TextXAlignment = Enum.TextXAlignment.Center, FontFace = FONT_T, TextSize = 26, Size = UDim2.new(1, 0, 0, 120), ZIndex = 82, Parent = roll })
	task.wait()
	local h = roll.AbsoluteSize.Y
	local tw = tween(roll, 45, { Position = UDim2.new(0.5, 0, 0, -h - 40) }, Enum.EasingStyle.Linear)
	tw.Completed:Wait()
	tween(f, 1.5, { BackgroundTransparency = 1 })
	task.wait(1.6)
	f:Destroy()
end

return UI
