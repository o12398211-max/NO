-- ═══════════════════════════════════════════════════════════════════
--  Build – מפעל חלקים: Part/Wedge/Cylinder/Ellipsoid עם חומרים, אורות, Beams ומודלים
-- ═══════════════════════════════════════════════════════════════════
local B = {}

local function apply(inst, props)
	if props then
		for k, v in pairs(props) do
			if k ~= "Parent" then inst[k] = v end
		end
		if props.Parent then inst.Parent = props.Parent end
	end
	return inst
end
B.apply = apply

function B.part(parent, size, cf, color, material, props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.new(1, 1, 1)
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	apply(p, props)
	p.Parent = parent
	return p
end

function B.wedge(parent, size, cf, color, material, props)
	local p = Instance.new("WedgePart")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color or Color3.new(1, 1, 1)
	p.Material = material or Enum.Material.SmoothPlastic
	apply(p, props)
	p.Parent = parent
	return p
end

--- גליל לאורך ציר X (כמו ב-Roblox). length = Size.X
function B.cyl(parent, length, diameter, cf, color, material, props)
	local p = B.part(parent, Vector3.new(length, diameter, diameter), cf, color, material, props)
	p.Shape = Enum.PartType.Cylinder
	return p
end

--- גליל אנכי
function B.vcyl(parent, height, diameter, pos, color, material, props)
	return B.cyl(parent, height, diameter, CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, material, props)
end

--- אליפסואיד (SpecialMesh Sphere) – מאפשר צורות מעוגלות לא אחידות
function B.ellipsoid(parent, size, cf, color, material, props)
	local p = B.part(parent, size, cf, color, material, props)
	local m = Instance.new("SpecialMesh")
	m.MeshType = Enum.MeshType.Sphere
	m.Parent = p
	return p
end

function B.ball(parent, d, pos, color, material, props)
	local p = B.part(parent, Vector3.new(d, d, d), CFrame.new(pos), color, material, props)
	p.Shape = Enum.PartType.Ball
	return p
end

function B.model(parent, name)
	local m = Instance.new("Model")
	m.Name = name or "Model"
	m.Parent = parent
	return m
end

function B.folder(parent, name)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	return f
end

function B.light(parent, kind, props)
	local l = Instance.new(kind or "PointLight")
	apply(l, props)
	l.Parent = parent
	return l
end

function B.att(parent, pos)
	local a = Instance.new("Attachment")
	a.Position = pos or Vector3.zero
	a.Parent = parent
	return a
end

--- קרן אור נפחית בין שתי נקודות (Beam עם גרדיאנט שקיפות)
function B.beam(a0, a1, color, w0, w1, props)
	local b = Instance.new("Beam")
	b.Attachment0 = a0
	b.Attachment1 = a1
	b.Color = ColorSequence.new(color)
	b.Width0 = w0 or 0.3
	b.Width1 = w1 or 6
	b.LightEmission = 1
	b.LightInfluence = 0
	b.FaceCamera = true
	b.Segments = 1
	b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55), NumberSequenceKeypoint.new(1, 1) })
	apply(b, props)
	b.Parent = a0.Parent
	return b
end

--- שלט טקסט עברי על משטח
function B.sign(part, face, text, color, bg, textScale)
	local g = Instance.new("SurfaceGui")
	g.Face = face or Enum.NormalId.Front
	g.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	g.PixelsPerStud = 40
	g.LightInfluence = 0.3
	g.Parent = part
	local l = Instance.new("TextLabel")
	l.Size = UDim2.fromScale(1, 1)
	l.BackgroundTransparency = bg and 0 or 1
	l.BackgroundColor3 = bg or Color3.new()
	l.TextColor3 = color or Color3.new(1, 1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.Arimo
	l.Text = text
	l.TextDirection = Enum.TextDirection.RightToLeft
	l.Parent = g
	local c = Instance.new("UITextSizeConstraint")
	c.MaxTextSize = textScale or 200
	c.Parent = l
	return l
end

--- נקודות על עקומת שרשרת (catenary) בין שתי נקודות
function B.catenary(a, b, n, sag)
	local pts = {}
	for i = 0, n do
		local t = i / n
		local p = a:Lerp(b, t) - Vector3.new(0, math.sin(t * math.pi) * sag, 0)
		table.insert(pts, p)
	end
	return pts
end

--- חוט דק בין נקודות
function B.wire(parent, pts, color, thick)
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local len = (b - a).Magnitude
		B.part(parent, Vector3.new(thick or 0.06, thick or 0.06, len), CFrame.lookAt((a + b) / 2, b), color or Color3.fromRGB(20, 20, 20), Enum.Material.SmoothPlastic, { CanCollide = false, CastShadow = false })
	end
end

function B.noCollide(model)
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then d.CanCollide = false end
	end
end

function B.rand(a, b)
	return a + math.random() * (b - a)
end

return B
