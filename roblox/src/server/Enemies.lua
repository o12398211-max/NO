-- ═══════════════════════════════════════════════════════════════════
--  Enemies – מחבלים: התקדמות, סיור עם פנס, קו ראייה, מטחים, "סכנה" נסתרת לכל שחקן
--  הירי ויזואלי וקולי בלבד. אין פירוט טכני. פגיעה = כישלון → חזרה לצ'קפוינט (בלי טקסט).
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local RS = game:GetService("ReplicatedStorage")
local NPC = require(script.Parent.NPC)
local E = {}
E.List = {}
E.Disabled = false
E.OnFail = nil -- function(player)
E.Mode = "off" -- off / escape / tunnel / outside

local params = RaycastParams.new()
params.FilterType = Enum.RaycastFilterType.Exclude
params.IgnoreWater = true

local function fx(...)
	local r = RS:FindFirstChild("Remotes")
	if r then r.Fx:FireAllClients(...) end
end
E.fx = fx

function E.Clear()
	for _, e in ipairs(E.List) do if e.N and e.N.Model then e.N.Model:Destroy() end end
	E.List = {}
end

--- yields: { mode="advance"|"patrol"|"post", path={Vector3}, flashlight=bool, range, fov }
function E.Spawn(parent, cf, opts)
	local n = NPC.Terrorist(parent, cf, { anchored = false })
	if not n then return end
	local e = { N = n, Opts = opts or {}, PathI = 1, FireT = math.random() * 3 + 1, Active = true, Seen = {} }
	if e.Opts.flashlight then
		local head = n.Model:FindFirstChild("Head")
		local sp = Instance.new("SpotLight"); sp.Face = Enum.NormalId.Front; sp.Range = e.Opts.range or 40; sp.Angle = 32; sp.Brightness = 5; sp.Color = Color3.fromRGB(255, 240, 200); sp.Shadows = true; sp.Parent = head
		local hand = n.Model:FindFirstChild("LeftHand")
		if hand then NPC.attach(hand, n.Model, Vector3.new(0.25, 0.25, 0.9), CFrame.new(0, -0.2, -0.3), Color3.fromRGB(30, 30, 30), Enum.Material.Metal) end
	end
	n.Humanoid.WalkSpeed = e.Opts.speed or 6
	table.insert(E.List, e)
	return e
end

local function visible(e, char)
	local head = e.N.Model:FindFirstChild("Head")
	local th = char:FindFirstChild("Head")
	if not head or not th then return false, math.huge end
	local plr = Players:GetPlayerFromCharacter(char)
	if plr and plr:GetAttribute("Hidden") then return false, math.huge end
	local from, to = head.Position, th.Position - Vector3.new(0, plr and plr:GetAttribute("Crouch") and 1.2 or 0, 0)
	local d = (to - from).Magnitude
	if d > (e.Opts.range or 160) then return false, d end
	if e.Opts.fov then
		local look = head.CFrame.LookVector
		if look:Dot((to - from).Unit) < math.cos(math.rad(e.Opts.fov)) then return false, d end
	end
	local ex = { e.N.Model, char }
	for _, o in ipairs(E.List) do table.insert(ex, o.N.Model) end
	local crowd = workspace:FindFirstChild("Crowd")
	if crowd then table.insert(ex, crowd) end
	params.FilterDescendantsInstances = ex
	local r = workspace:Raycast(from, to - from, params)
	if r and r.Instance and not r.Instance:IsDescendantOf(char) then
		-- שיחים חוסמים רק כשמתכופפים
		local inBush = r.Instance.Parent and r.Instance.Parent:GetAttribute("Bush")
		if not inBush or (plr and plr:GetAttribute("Crouch")) then return false, d end
	end
	return true, d
end

local function burst(e, targetPos, n)
	local m = e.N.Model
	local muzzle = m:FindFirstChild("Rifle") and m.Rifle:FindFirstChild("Muzzle")
	local from = muzzle and muzzle.Position or (m.Head.Position)
	fx("burst", from, targetPos, n or math.random(3, 7))
end

local acc = 0
RunService.Heartbeat:Connect(function(dt)
	if E.Mode == "off" then return end
	acc += dt
	if acc < 0.1 then return end
	local step = acc
	acc = 0
	local exposure = {}
	for _, e in ipairs(E.List) do
		local n = e.N
		if e.Active and n.Model.Parent and not E.Disabled then
			local root = n.Root
			-- תנועה
			if e.Opts.mode == "advance" or e.Opts.mode == "patrol" then
				local path = e.Opts.path
				if path and #path > 0 then
					local tgt = path[e.PathI]
					if (Vector3.new(tgt.X, 0, tgt.Z) - Vector3.new(root.Position.X, 0, root.Position.Z)).Magnitude < 4 then
						if e.Opts.mode == "patrol" then e.PathI = e.PathI % #path + 1 else e.PathI = math.min(e.PathI + 1, #path) end
						tgt = path[e.PathI]
					end
					root.Anchored = false
					n.Humanoid:MoveTo(tgt)
					if n.Current ~= "Walk" then n:Play("Walk", 0.3, 0.8) end
				end
			end
			-- ראייה וירי
			local best, bestD = nil, math.huge
			for _, plr in ipairs(Players:GetPlayers()) do
				local char = plr.Character
				if char and char:FindFirstChild("Head") and plr:GetAttribute("InStory") and not plr:GetAttribute("Capturing") then
					local vis, d = visible(e, char)
					if vis then
						if d < bestD then best, bestD = plr, d end
						local k = math.clamp(1 - d / (e.Opts.range or 160), 0, 1)
						if plr:GetAttribute("Running") then k *= 0.7 end
						if plr:GetAttribute("Crouch") then k *= 0.55 end
						if plr:GetAttribute("Driving") then k *= plr:GetAttribute("Fast") and 0.35 or 0.8 end
						exposure[plr] = (exposure[plr] or 0) + k
					end
				end
			end
			e.FireT -= step
			if best then
				n:Face(best.Character.Head.Position)
				if e.Opts.mode == "patrol" and E.Mode ~= "escape" then
					-- סיור: אזהרה ואז כישלון
					if not e.Seen[best] then
						e.Seen[best] = os.clock()
						burst(e, best.Character.Head.Position + Vector3.new(math.random(-12, 12), 18, math.random(-12, 12)), 2)
						fx("spotted", best.UserId)
					elseif os.clock() - e.Seen[best] > 1.2 then
						e.Seen[best] = nil
						if E.OnFail then E.OnFail(best) end
					end
				elseif e.FireT <= 0 then
					e.FireT = 1.6 + math.random() * 3
					local miss = (1 - (best:GetAttribute("Danger") or 0)) * 14 + 2
					burst(e, best.Character.Head.Position + Vector3.new(math.random(-100, 100) / 100 * miss, -3, math.random(-100, 100) / 100 * miss))
				end
			elseif e.FireT <= 0 and E.Mode == "escape" then
				e.FireT = 2.5 + math.random() * 4
				-- ירי כללי לכיוון ההמון / האוויר
				burst(e, root.Position + root.CFrame.LookVector * 60 + Vector3.new(math.random(-30, 30), math.random(0, 8), math.random(-30, 30)))
			end
		end
	end
	-- סכנה נסתרת – בלי מד, הלקוח מתרגם לנשימה/דופק/מנהרה
	if E.Mode == "escape" or E.Mode == "outside" then
		for _, plr in ipairs(Players:GetPlayers()) do
			if plr:GetAttribute("InStory") and not plr:GetAttribute("Capturing") then
				local d = plr:GetAttribute("Danger") or 0
				local ex = exposure[plr]
				d = ex and d + ex * step * 0.16 or d - step * 0.07
				if plr:GetAttribute("Hidden") then d -= step * 0.15 end
				d = math.clamp(d, 0, 1)
				plr:SetAttribute("Danger", d)
				if d >= 1 and not plr:GetAttribute("God") then
					plr:SetAttribute("Danger", 0)
					if E.OnFail then E.OnFail(plr) end
				end
			end
		end
	end
end)

return E
