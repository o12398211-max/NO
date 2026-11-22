-- ═══════════════════════════════════════════════════════════════════
--  Vehicles – הופך מודל רכב (חלקים מעוגנים) לרכב נהיג: ריתוך לשלדה, LinearVelocity במישור
--  (בלי החלקה צידית), AngularVelocity להיגוי, בעלות רשת לנהג, פנסים (SpotLight)
-- ═══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local V = {}
V.Active = {}

function V.MakeDrivable(model)
	local chassis = model.PrimaryPart
	local seat = model:FindFirstChild("DriveSeat")
	if not chassis or not seat then return end
	seat.Disabled = false
	for _, p in ipairs(model:GetDescendants()) do
		if p:IsA("BasePart") and p ~= chassis then
			local w = Instance.new("WeldConstraint"); w.Part0 = chassis; w.Part1 = p; w.Parent = chassis
			p.Massless = true
			if p.Name ~= "Chassis" then p.CanCollide = false end
		end
	end
	chassis.CustomPhysicalProperties = PhysicalProperties.new(1.2, 0.05, 0, 1, 1)
	local a = Instance.new("Attachment"); a.Name = "DriveAtt"; a.Parent = chassis
	local lv = Instance.new("LinearVelocity")
	lv.Attachment0 = a; lv.RelativeTo = Enum.ActuatorRelativeTo.Attachment0
	lv.VelocityConstraintMode = Enum.VelocityConstraintMode.Plane
	lv.PrimaryTangentAxis = Vector3.new(0, 0, -1); lv.SecondaryTangentAxis = Vector3.new(1, 0, 0)
	lv.PlaneVelocity = Vector2.zero; lv.MaxForce = 0; lv.Parent = chassis
	local av = Instance.new("AngularVelocity")
	av.Attachment0 = a; av.RelativeTo = Enum.ActuatorRelativeTo.World; av.AngularVelocity = Vector3.zero; av.MaxTorque = 0; av.Parent = chassis
	local lights = {}
	for _, h in ipairs(model:GetChildren()) do
		if h.Name == "Headlight" then
			local s = Instance.new("SpotLight"); s.Face = Enum.NormalId.Front; s.Range = 70; s.Angle = 55; s.Brightness = 0; s.Color = Color3.fromRGB(255, 242, 216); s.Shadows = true; s.Parent = h
			table.insert(lights, s)
			h.Material = Enum.Material.Glass
		end
	end
	for _, p in ipairs(model:GetDescendants()) do if p:IsA("BasePart") then p.Anchored = false end end
	local car = { Model = model, Chassis = chassis, Seat = seat, LV = lv, AV = av, Lights = lights, Speed = 0, LightsOn = false }
	model:SetAttribute("Drivable", true)
	seat:GetPropertyChangedSignal("Occupant"):Connect(function()
		local occ = seat.Occupant
		if occ then
			local plr = Players:GetPlayerFromCharacter(occ.Parent)
			if plr then pcall(function() chassis:SetNetworkOwner(plr) end) end
			lv.MaxForce = 60000; av.MaxTorque = 400000
		else
			lv.PlaneVelocity = Vector2.zero
			task.delay(1.5, function() if not seat.Occupant then lv.MaxForce = 4000; av.MaxTorque = 40000 end end)
		end
		model:SetAttribute("Driver", occ and occ.Parent.Name or "")
	end)
	function car:SetLights(on)
		self.LightsOn = on
		for _, l in ipairs(self.Lights) do l.Brightness = on and 4 or 0 end
		for _, h in ipairs(model:GetChildren()) do if h.Name == "Headlight" then h.Material = on and Enum.Material.Neon or Enum.Material.Glass end end
		model:SetAttribute("LightsOn", on)
	end
	table.insert(V.Active, car)
	return car
end

function V.Clear()
	V.Active = {}
end

RunService.Heartbeat:Connect(function(dt)
	for _, car in ipairs(V.Active) do
		if car.Model.Parent and car.Seat.Occupant and not car.Model:GetAttribute("Disabled") then
			local target = car.Seat.ThrottleFloat * car.Seat.MaxSpeed * (car.Seat.ThrottleFloat < 0 and 0.4 or 1)
			car.Speed += math.clamp(target - car.Speed, -60 * dt, 30 * dt)
			car.LV.PlaneVelocity = Vector2.new(car.Speed, 0)
			local yaw = -car.Seat.SteerFloat * math.clamp(math.abs(car.Speed) / 25, 0, 1) * 1.6 * math.sign(car.Speed + 0.001)
			car.AV.AngularVelocity = Vector3.new(0, yaw, 0)
		elseif car.Model.Parent then
			car.Speed *= 0.9
			car.LV.PlaneVelocity = Vector2.new(car.Speed, 0)
			car.AV.AngularVelocity = Vector3.zero
		end
	end
end)

return V
