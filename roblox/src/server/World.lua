-- בניית עולם פרוצדורלית: לובי מכובד עם פורטלים, מתחם המסיבה (Terrain + במה + אוהלים + רכבים מפוזרים)
local W = {}
local function part(props)
	local p = Instance.new("Part"); p.Anchored = true; p.TopSurface = Enum.SurfaceType.Smooth; p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do p[k] = v end; return p
end

function W.BuildLobby()
	local m = Instance.new("Model"); m.Name = "Lobby"; m.Parent = workspace
	part({ Name = "Floor", Size = Vector3.new(120, 2, 120), Position = Vector3.new(0, 500, 0), Material = Enum.Material.Marble, Color = Color3.fromRGB(28, 26, 34), Parent = m })
	local portals = Instance.new("Folder"); portals.Name = "Portals"; portals.Parent = m
	for i, n in ipairs({ 2, 4, 6, 8 }) do
		local c = part({ Name = "Portal" .. n, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12, 12), CFrame = CFrame.new(-36 + i * 15, 501.2, -20) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Neon, Color = Color3.fromRGB(255, 179, 92), CanCollide = false, Parent = portals })
		local l = Instance.new("PointLight"); l.Color = c.Color; l.Range = 18; l.Brightness = 2; l.Parent = c
	end
	local sp = Instance.new("SpawnLocation"); sp.Anchored = true; sp.Size = Vector3.new(8, 1, 8); sp.Position = Vector3.new(0, 501.5, 20); sp.Transparency = 1; sp.Parent = m
	-- קיר זיכרון עם נרות
	for i = -5, 5 do
		local c = part({ Size = Vector3.new(0.4, 1.2, 0.4), Position = Vector3.new(i * 3, 501.6, 45), Material = Enum.Material.SmoothPlastic, Color = Color3.fromRGB(245, 235, 210), Parent = m })
		local f = Instance.new("PointLight"); f.Color = Color3.fromRGB(255, 170, 80); f.Range = 8; f.Parent = c
		local fl = Instance.new("Fire"); fl.Size = 1; fl.Heat = 2; fl.Parent = c
	end
end

function W.BuildFestival()
	local m = Instance.new("Model"); m.Name = "Festival"; m.Parent = workspace
	local T = workspace.Terrain
	T:FillBlock(CFrame.new(0, -6, 0), Vector3.new(700, 12, 700), Enum.Material.Sand)
	for i = 1, 140 do T:FillBall(Vector3.new(math.random(-300, 300), -2, math.random(-300, 300)), math.random(4, 12), Enum.Material.Ground) end
	local sp = part({ Name = "Spawn", Size = Vector3.new(4, 1, 4), Position = Vector3.new(0, 1, 10), Transparency = 1, CanCollide = false, Parent = m })
	-- במה + טראס + LED + אורות
	part({ Name = "Deck", Size = Vector3.new(36, 3, 20), Position = Vector3.new(0, 1.5, -68), Material = Enum.Material.WoodPlanks, Color = Color3.fromRGB(120, 100, 85), Parent = m })
	local led = part({ Name = "LED", Size = Vector3.new(28, 13, 0.5), Position = Vector3.new(0, 11, -77), Material = Enum.Material.Neon, Color = Color3.fromRGB(120, 40, 255), Parent = m })
	for _, x in ipairs({ -17, 17 }) do for _, z in ipairs({ -77, -61 }) do part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(20, 0.8, 0.8), CFrame = CFrame.new(x, 13, z) * CFrame.Angles(0, 0, math.rad(90)), Material = Enum.Material.Metal, Color = Color3.fromRGB(190, 190, 195), Parent = m }) end end
	for i, c in ipairs({ Color3.fromRGB(255, 46, 136), Color3.fromRGB(25, 227, 255), Color3.fromRGB(155, 91, 255) }) do
		local h = part({ Size = Vector3.new(1, 1, 1), Position = Vector3.new(-12 + i * 6, 22, -61), Color = Color3.new(0, 0, 0), Parent = m })
		local s = Instance.new("SpotLight"); s.Color = c; s.Range = 60; s.Angle = 50; s.Brightness = 6; s.Face = Enum.NormalId.Bottom; s.Parent = h
	end
	-- אוהלים (כיפות)
	for i = 1, 40 do
		local t = part({ Shape = Enum.PartType.Ball, Size = Vector3.new(7, 7, 7), Position = Vector3.new(math.random(-60, 70), 0.5, math.random(90, 140)), Material = Enum.Material.Fabric, Color = Color3.fromHSV(math.random(), 0.5, 0.6), Parent = m })
	end
	-- רכבים מפוזרים בשדה, כל אחד בזווית אחרת
	for i = 1, 40 do
		local car = Instance.new("Model"); car.Name = "Car"; car.Parent = m
		local cf = CFrame.new(math.random(-160, -60), 1.6, math.random(20, 180)) * CFrame.Angles(0, math.rad(math.random(0, 359)), 0)
		local col = Color3.fromHSV(math.random(), 0.3, 0.4 + math.random() * 0.5)
		local body = part({ Size = Vector3.new(9, 2.4, 4), CFrame = cf, Material = Enum.Material.SmoothPlastic, Color = col, Parent = car })
		local cab = part({ Size = Vector3.new(5, 2, 3.8), CFrame = cf * CFrame.new(-0.5, 2.1, 0), Material = Enum.Material.Glass, Color = Color3.fromRGB(20, 25, 30), Transparency = 0.2, Parent = car })
		for _, o in ipairs({ { 3, 2 }, { 3, -2 }, { -3, 2 }, { -3, -2 } }) do
			part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.8, 2, 2), CFrame = cf * CFrame.new(o[1], -1, o[2]) * CFrame.Angles(0, math.rad(90), 0), Material = Enum.Material.Rubber, Color = Color3.fromRGB(20, 20, 20), Parent = car })
		end
		local seat = Instance.new("VehicleSeat"); seat.Anchored = false; seat.Size = Vector3.new(2, 1, 2); seat.CFrame = cf * CFrame.new(-0.5, 1.4, 0.8); seat.Transparency = 1; seat.Parent = car
		car.PrimaryPart = body
	end
	-- סלעים של שחר
	for i = 1, 8 do part({ Shape = Enum.PartType.Ball, Size = Vector3.new(6, 4, 6), Position = Vector3.new(80 + math.random(-8, 8), 0, -52 + math.random(-8, 8)), Material = Enum.Material.Rock, Color = Color3.fromRGB(170, 150, 120), Parent = m }) end
end
return W
