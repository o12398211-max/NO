-- ═══════════════════════════════════════════════════════════════════
--  Crowd – המון נמלט בצד הלקוח: מאות אנשים, כל אחד לכיוון אחר, עם התנהגויות:
--  בורח, מסתתר, עוצר ומחפש מישהו, נופל וקם, מושך חבר ביד. נשאר בצפיפות סביב השחקן.
-- ═══════════════════════════════════════════════════════════════════
local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))

local C = {}
local people = {}
local folder
local conn
local rayP = RaycastParams.new()
rayP.FilterType = Enum.RaycastFilterType.Include
rayP.FilterDescendantsInstances = { workspace.Terrain }

local function groundY(x, z, fallback)
	local r = workspace:Raycast(Vector3.new(x, 300, z), Vector3.new(0, -600, 0), rayP)
	return r and r.Position.Y or fallback
end

local function playAnim(model, id, speed)
	local hum = model:FindFirstChildOfClass("Humanoid")
	if not hum then return end
	local an = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	for _, t in ipairs(an:GetPlayingAnimationTracks()) do t:Stop(0.2) end
	local a = Instance.new("Animation"); a.AnimationId = id
	local ok, tr = pcall(function() return an:LoadAnimation(a) end)
	if ok and tr then tr.Looped = true; tr:Play(0.2, 1, speed or 1); return tr end
end

function C.Start(center, count, goals, threats)
	C.Stop()
	local templates = RS:WaitForChild("Templates", 20)
	if not templates then return end
	folder = Instance.new("Folder"); folder.Name = "Crowd"; folder.Parent = workspace
	local list = {}
	for _, t in ipairs(templates:GetChildren()) do if t.Name:match("^Crowd") then table.insert(list, t) end end
	if #list == 0 then return end
	local rng = Random.new(42)
	for i = 1, count do
		local m = list[(i - 1) % #list + 1]:Clone()
		m:SetAttribute("Local", true)
		m:SetAttribute("NPC", true)
		for _, d in ipairs(m:GetDescendants()) do if d:IsA("BasePart") then d.CanCollide = false; d.CastShadow = i < 30 end end
		m.HumanoidRootPart.Anchored = true
		local p = { m = m, pos = center + Vector3.new(rng:NextNumber(-140, 140), 0, rng:NextNumber(-140, 140)), dir = Vector3.new(0, 0, -1), speed = 0, mode = "flee", t = 0, wait = 0, phase = rng:NextNumber() * 10 }
		local r = rng:NextNumber()
		if r < 0.62 and #goals > 0 then local g = goals[rng:NextInteger(1, #goals)]; p.goal = g + Vector3.new(rng:NextNumber(-90, 90), 0, rng:NextNumber(-90, 90))
		elseif r < 0.75 then p.mode = "hide"; p.goal = p.pos + Vector3.new(rng:NextNumber(-40, 40), 0, rng:NextNumber(-40, 40))
		elseif r < 0.86 then p.mode = "search"; p.wait = rng:NextNumber(2, 6); p.goal = p.pos + Vector3.new(rng:NextNumber(-50, 50), 0, rng:NextNumber(-50, 50))
		else local a = rng:NextNumber() * math.pi * 2; p.goal = p.pos + Vector3.new(math.cos(a) * 300, 0, math.sin(a) * 300) end
		p.speed = p.mode == "search" and 9 or rng:NextNumber(17, 26)
		m.Parent = folder
		p.track = playAnim(m, p.mode == "search" and Config.Anim.Walk or Config.Anim.Run, p.speed / 20)
		people[i] = p
	end
	-- זוגות: אחד מושך את השני ביד
	for i = 1, 20, 2 do people[i + 1].buddy = people[i] end
	local acc = 0
	conn = RunService.Heartbeat:Connect(function(dt)
		local char = Players.LocalPlayer.Character
		local pl = char and char:FindFirstChild("HumanoidRootPart") and char.HumanoidRootPart.Position or center
		acc += dt
		local doGround = acc > 0.25
		if doGround then acc = 0 end
		for _, p in ipairs(people) do
			p.t += dt
			local dpl = (Vector3.new(p.pos.X, 0, p.pos.Z) - Vector3.new(pl.X, 0, pl.Z)).Magnitude
			if dpl > 230 then
				local a = math.random() * math.pi * 2
				p.pos = pl + Vector3.new(math.cos(a), 0, math.sin(a)) * math.random(110, 180)
				p.goal = p.pos + Vector3.new(math.random(-200, 200), 0, math.random(-200, 200))
				p.mode = "flee"
			end
			local m = p.m
			if p.fallen and p.fallen > 0 then
				p.fallen -= dt
				m:SetAttribute("Pose", p.fallen > 0.8 and "lying" or "crouch")
				if p.fallen <= 0 then m:SetAttribute("Pose", ""); p.track = playAnim(m, Config.Anim.Run, p.speed / 20) end
			elseif p.buddy then
				local d = p.buddy.pos - p.pos
				d = Vector3.new(d.X, 0, d.Z)
				if d.Magnitude > 3 then p.pos += d.Unit * math.min(d.Magnitude - 2.6, (p.buddy.speed + 2) * dt) end
				p.dir = d.Magnitude > 0.01 and d.Unit or p.dir
			elseif p.mode == "hide" and (p.goal - p.pos).Magnitude < 4 then
				if m:GetAttribute("Pose") ~= "cower" then m:SetAttribute("Pose", "cower"); if p.track then p.track:Stop(0.2) end end
				if p.t > 10 + math.random() * 8 then p.mode = "flee"; p.t = 0; p.goal = p.pos + Vector3.new(math.random(-300, 300), 0, math.random(-300, 300)); m:SetAttribute("Pose", ""); p.track = playAnim(m, Config.Anim.Run, p.speed / 20) end
			elseif p.mode == "search" and p.wait > 0 then
				p.wait -= dt
				if p.track then p.track:AdjustSpeed(0.1) end
				if p.wait <= 0 then p.mode = "flee"; p.track = playAnim(m, Config.Anim.Run, 1) ; p.speed = 20 end
			else
				local v = p.goal - p.pos
				v = Vector3.new(v.X, 0, v.Z)
				if v.Magnitude < 4 then
					p.goal = p.pos + Vector3.new(math.random(-260, 260), 0, math.random(-260, 260))
				else
					local dir = v.Unit
					for _, th in ipairs(threats or {}) do
						if th.Parent and th:FindFirstChild("HumanoidRootPart") then
							local tv = p.pos - th.HumanoidRootPart.Position
							tv = Vector3.new(tv.X, 0, tv.Z)
							local td = tv.Magnitude
							if td < 120 and td > 0.1 then dir += tv.Unit * (120 - td) / 70 end
						end
					end
					dir += Vector3.new(math.sin(p.t * 1.3 + p.phase), 0, math.cos(p.t * 1.1 + p.phase)) * 0.2
					p.dir = p.dir:Lerp(dir.Unit, math.min(1, dt * 4))
					p.pos += p.dir * p.speed * dt
					if dpl < 120 and math.random() < dt * 0.012 then p.fallen = 1.6 + math.random() end
				end
			end
			if doGround or not p.y then p.y = groundY(p.pos.X, p.pos.Z, p.y or pl.Y) end
			local visible = dpl < 220
			if visible then
				local look = p.dir.Magnitude > 0.01 and p.dir or Vector3.new(0, 0, -1)
				m:PivotTo(CFrame.lookAt(Vector3.new(p.pos.X, p.y + 3, p.pos.Z), Vector3.new(p.pos.X, p.y + 3, p.pos.Z) + look))
			end
			if m.Parent ~= (visible and folder or nil) then m.Parent = visible and folder or nil end
		end
	end)
end

function C.SetVisible(on) if folder then folder.Parent = on and workspace or nil end end
function C.Stop()
	if conn then conn:Disconnect(); conn = nil end
	for _, p in ipairs(people) do if p.m then p.m:Destroy() end end
	people = {}
	if folder then folder:Destroy(); folder = nil end
end

return C
