-- ═══════════════════════════════════════════════════════════════════
--  Blocky – שפת העיצוב של פאנל האדמין והחלונות הקופצים: כותרת כחולה עם בליטות, X אדום,
--  כרטיסים כהים, כפתורים תלת־ממדיים עם טקסט מוקף, ופס הכרזה בסגנון "עץ" (שם אדום + וי כחול)
-- ═══════════════════════════════════════════════════════════════════
local UI = require(script.Parent.UI)
local new = UI.new
local rgb = Color3.fromRGB

local Bk = {}
Bk.FONT = Font.new("rbxasset://fonts/families/Arimo.json", Enum.FontWeight.Heavy)
Bk.COLORS = {
	green = { rgb(160, 232, 64), rgb(92, 186, 30) }, red = { rgb(240, 96, 96), rgb(196, 52, 52) }, orange = { rgb(246, 186, 80), rgb(214, 136, 36) },
	gray = { rgb(170, 170, 170), rgb(118, 118, 118) }, pink = { rgb(255, 120, 180), rgb(232, 62, 140) }, purple = { rgb(176, 120, 255), rgb(132, 72, 230) },
	blue = { rgb(96, 190, 255), rgb(36, 132, 220) }, yellow = { rgb(255, 222, 90), rgb(232, 180, 30) },
}

function Bk.stroked(lbl, t)
	new("UIStroke", { Color = rgb(10, 10, 10), Thickness = t or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = lbl })
	return lbl
end
function Bk.txt(parent, text, size, pos, ts, align, z)
	local l = new("TextLabel", { BackgroundTransparency = 1, Text = text, FontFace = Bk.FONT, TextSize = ts or 18, TextColor3 = rgb(255, 255, 255), Size = size, Position = pos, TextXAlignment = align or Enum.TextXAlignment.Right, TextDirection = Enum.TextDirection.RightToLeft, TextWrapped = true, ZIndex = z or 92, Parent = parent })
	return Bk.stroked(l, ts and ts > 20 and 3 or 2)
end
function Bk.studs(parent, color, cell, z)
	local g = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ClipsDescendants = true, ZIndex = z or 91, Parent = parent })
	new("UIGridLayout", { CellSize = cell or UDim2.fromOffset(26, 22), CellPadding = UDim2.fromOffset(6, 6), Parent = g })
	for _ = 1, 160 do new("Frame", { BackgroundColor3 = color, BackgroundTransparency = 0.82, ZIndex = z or 91, Parent = g }, { UI.corner(6) }) end
	return g
end
function Bk.button(parent, text, color, size, pos, onClick, z)
	z = z or 93
	local c = Bk.COLORS[color] or Bk.COLORS.green
	local b = new("TextButton", { AutoButtonColor = false, Text = "", BackgroundColor3 = c[1], Size = size, Position = pos, ZIndex = z, Parent = parent }, {
		UI.corner(4), new("UIStroke", { Color = c[2]:Lerp(rgb(0, 0, 0), 0.35), Thickness = 2 }),
		new("UIGradient", { Color = ColorSequence.new(c[1], c[2]), Rotation = 90 }),
	})
	local s = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -6, 0.55, 0), Position = UDim2.fromOffset(3, 2), ClipsDescendants = true, ZIndex = z, Parent = b })
	new("UIGridLayout", { CellSize = UDim2.fromOffset(10, 6), CellPadding = UDim2.fromOffset(4, 3), Parent = s })
	for _ = 1, 30 do new("Frame", { BackgroundColor3 = rgb(255, 255, 255), BackgroundTransparency = 0.8, ZIndex = z, Parent = s }, { UI.corner(2) }) end
	local ts = size.Y.Offset > 0 and math.min(16, size.Y.Offset * 0.45) or 15
	local l = Bk.txt(b, text, UDim2.fromScale(1, 1), UDim2.new(), ts, Enum.TextXAlignment.Center, z + 1)
	b:SetAttribute("Label", true)
	b.MouseEnter:Connect(function() UI.tween(b, 0.1, { Size = size + UDim2.fromOffset(3, 2) }) end)
	b.MouseLeave:Connect(function() UI.tween(b, 0.1, { Size = size }) end)
	b.MouseButton1Down:Connect(function() UI.tween(b, 0.05, { Size = size - UDim2.fromOffset(3, 2) }) end)
	if onClick then b.MouseButton1Click:Connect(function() if UI.Click then UI.Click() end; onClick() end) end
	return b, l
end
function Bk.input(parent, ph, size, pos, z)
	return new("TextBox", { Text = "", PlaceholderText = ph, PlaceholderColor3 = rgb(110, 120, 112), TextColor3 = rgb(240, 240, 240), FontFace = Bk.FONT, TextSize = 16, BackgroundColor3 = rgb(12, 22, 17), BackgroundTransparency = 0.1, Size = size, Position = pos, ClearTextOnFocus = false, TextDirection = Enum.TextDirection.RightToLeft, ZIndex = z or 93, Parent = parent }, { UI.corner(4), new("UIStroke", { Color = rgb(40, 64, 50), Thickness = 1 }) })
end
function Bk.card(parent, title, size, pos, z)
	local f = new("Frame", { BackgroundColor3 = rgb(14, 34, 25), BackgroundTransparency = 0.15, Size = size, Position = pos, ZIndex = z or 92, Parent = parent }, { UI.corner(4), new("UIStroke", { Color = rgb(6, 14, 10), Thickness = 2 }) })
	if title then Bk.txt(f, title, UDim2.new(1, -24, 0, 30), UDim2.fromOffset(12, 6), 21, nil, (z or 92) + 1) end
	return f
end

--- חלון בסגנון הפאנל: כותרת צבעונית עם בליטות + X. מחזיר (root, body)
function Bk.window(parent, title, icon, size, pos, headColor, onClose, z)
	z = z or 90
	local hc = Bk.COLORS[headColor or "blue"]
	local root = new("Frame", { BackgroundTransparency = 1, Size = size, Position = pos or UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Parent = parent })
	local body = new("Frame", { BackgroundColor3 = rgb(20, 30, 26), BackgroundTransparency = 0.12, Size = UDim2.new(1, -24, 1, -50), Position = UDim2.fromOffset(12, 46), ZIndex = z, Parent = root }, { UI.corner(4), new("UIStroke", { Color = rgb(8, 12, 16), Thickness = 4 }) })
	local head = new("Frame", { BackgroundColor3 = hc[1], Size = UDim2.new(1, 0, 0, 54), ZIndex = z + 1, Parent = root }, {
		UI.corner(4), new("UIStroke", { Color = hc[2]:Lerp(rgb(0, 0, 0), 0.55), Thickness = 4 }), new("UIGradient", { Color = ColorSequence.new(hc[1], hc[2]), Rotation = 90 }),
	})
	Bk.studs(head, rgb(255, 255, 255), UDim2.fromOffset(20, 16), z + 1)
	if icon then Bk.txt(head, icon, UDim2.fromOffset(40, 40), UDim2.new(1, -50, 0, 7), 26, Enum.TextXAlignment.Center, z + 2) end
	Bk.txt(head, title, UDim2.new(1, icon and -110 or -70, 1, 0), UDim2.fromOffset(56, 0), 28, nil, z + 2)
	if onClose then Bk.button(head, "X", "red", UDim2.fromOffset(40, 40), UDim2.fromOffset(8, 7), onClose, z + 3) end
	-- כניסה קופצנית
	local uis = new("UIScale", { Scale = 0.6, Parent = root })
	UI.tween(uis, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
	return root, body
end

--- פס הכרזה בסגנון "עץ": שם השולח באדום, וי כחול מאומת, נקודתיים, ההודעה בלבן – כולם מוקפים בשחור
function Bk.announce(parent, sender, text, dur)
	local bar = new("Frame", { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -80), Size = UDim2.fromOffset(0, 58), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = rgb(150, 112, 60), BackgroundTransparency = 0.18, ZIndex = 95, Parent = parent }, {
		UI.corner(6),
		new("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, rgb(120, 86, 44)), ColorSequenceKeypoint.new(0.5, rgb(168, 128, 72)), ColorSequenceKeypoint.new(1, rgb(120, 86, 44)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(0.12, 0.1), NumberSequenceKeypoint.new(0.88, 0.1), NumberSequenceKeypoint.new(1, 0.55) }) }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 40), PaddingRight = UDim.new(0, 40) }),
		new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
	})
	local function part(order, txt, color, size)
		local l = new("TextLabel", { BackgroundTransparency = 1, Text = txt, FontFace = Bk.FONT, TextSize = size or 30, TextColor3 = color, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 50), TextDirection = Enum.TextDirection.RightToLeft, LayoutOrder = order, ZIndex = 96, Parent = bar })
		new("UIStroke", { Color = rgb(0, 0, 0), Thickness = 3, Parent = l })
		return l
	end
	-- סדר משמאל לימין כך שבעברית השם בצד ימין
	part(1, text, rgb(255, 255, 255))
	part(2, ":", rgb(255, 255, 255))
	local badge = new("Frame", { BackgroundColor3 = rgb(34, 120, 255), Size = UDim2.fromOffset(32, 32), Rotation = 8, LayoutOrder = 3, ZIndex = 96, Parent = bar }, { UI.corner(6), new("UIStroke", { Color = rgb(255, 255, 255), Thickness = 2 }) })
	new("TextLabel", { BackgroundTransparency = 1, Text = "✔", FontFace = Bk.FONT, TextSize = 22, TextColor3 = rgb(255, 255, 255), Size = UDim2.fromScale(1, 1), Rotation = -8, ZIndex = 97, Parent = badge })
	part(4, sender, rgb(255, 64, 64))
	UI.tween(bar, 0.45, { Position = UDim2.new(0.5, 0, 0, 22) }, Enum.EasingStyle.Back)
	task.delay(dur or 7, function()
		UI.tween(bar, 0.4, { Position = UDim2.new(0.5, 0, 0, -80) })
		task.wait(0.45)
		bar:Destroy()
	end)
	return bar
end

return Bk
