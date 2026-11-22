-- ═══════════════════════════════════════════════════════════════════
--  Poser – תנוחות ידניות על Motor6D של R15 (לכל מודל עם Attribute "Pose"), בצד הלקוח:
--  ישיבה, ישיבה על הקרקע, כפיפה, התכווצות בפחד, ידיים למעלה, שכיבה, חיבוק, תיפוף, תמונה,
--  כיוון, נפילה, וארבעה סגנונות ריקוד פרוצדורליים. גם: דיבור (פה) ומצמוץ (עיניים)
-- ═══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Poser = {}
local rad = math.rad
local A = CFrame.Angles

local function J(model)
	local function m(part, name) local p = model:FindFirstChild(part); return p and p:FindFirstChild(name) end
	return {
		root = m("LowerTorso", "Root"), waist = m("UpperTorso", "Waist"), neck = m("Head", "Neck"),
		rs = m("RightUpperArm", "RightShoulder"), re = m("RightLowerArm", "RightElbow"), ls = m("LeftUpperArm", "LeftShoulder"), le = m("LeftLowerArm", "LeftElbow"),
		rh = m("RightUpperLeg", "RightHip"), rk = m("RightLowerLeg", "RightKnee"), lh = m("LeftUpperLeg", "LeftHip"), lk = m("LeftLowerLeg", "LeftKnee"),
	}
end

local POSES = {}
POSES.sit = function(j)
	return { rh = A(rad(90), 0, 0), lh = A(rad(90), 0, 0), rk = A(rad(-90), 0, 0), lk = A(rad(-90), 0, 0), rs = A(rad(25), 0, 0), ls = A(rad(25), 0, 0), re = A(rad(40), 0, 0), le = A(rad(40), 0, 0) }
end
POSES.sitGround = function(j, t)
	return { root = CFrame.new(0, -2.0, 0), rh = A(rad(85), 0, rad(-20)), lh = A(rad(85), 0, rad(20)), rk = A(rad(-120), 0, 0), lk = A(rad(-120), 0, 0), waist = A(rad(-12 + math.sin(t * 0.8) * 2), 0, 0), rs = A(rad(35), 0, 0), ls = A(rad(35), 0, 0), re = A(rad(50), 0, 0), le = A(rad(50), 0, 0) }
end
POSES.crouch = function(j)
	return { root = CFrame.new(0, -1.5, 0), rh = A(rad(100), 0, 0), lh = A(rad(100), 0, 0), rk = A(rad(-120), 0, 0), lk = A(rad(-120), 0, 0), waist = A(rad(-25), 0, 0) }
end
POSES.cower = function(j, t)
	return { root = CFrame.new(0, -1.6, 0), rh = A(rad(105), 0, 0), lh = A(rad(105), 0, 0), rk = A(rad(-125), 0, 0), lk = A(rad(-125), 0, 0), waist = A(rad(-35), 0, rad(math.sin(t * 22) * 1)), neck = A(rad(-30), 0, 0), rs = A(rad(150), 0, rad(15)), ls = A(rad(150), 0, rad(-15)), re = A(rad(70), 0, 0), le = A(rad(70), 0, 0) }
end
POSES.handsUp = function(j)
	return { rs = A(0, 0, rad(170)), ls = A(0, 0, rad(-170)), re = A(0, 0, rad(-20)), le = A(0, 0, rad(20)) }
end
POSES.lying = function(j, t)
	return { root = CFrame.new(0, -2.6, 0) * A(rad(-90), 0, 0) * CFrame.new(0, 0, math.sin(t * 1.4) * 0.03), rs = A(0, 0, rad(15)), ls = A(0, 0, rad(-15)) }
end
POSES.down = function(j)
	return { root = CFrame.new(0, -2.7, 0.6) * A(rad(-88), 0, rad(10)), rs = A(rad(20), 0, rad(30)), ls = A(rad(-10), 0, rad(-25)), rh = A(rad(10), 0, 0), lk = A(rad(-30), 0, 0) }
end
POSES.hug = function(j)
	return { rs = A(rad(80), rad(-30), rad(30)), ls = A(rad(80), rad(30), rad(-30)), re = A(rad(70), 0, 0), le = A(rad(70), 0, 0), neck = A(rad(-10), 0, 0) }
end
POSES.drum = function(j, t)
	local b = t * 4.5
	local s = POSES.sitGround(j, t)
	s.rs = A(rad(55 + math.max(0, math.sin(b)) * 30), 0, 0); s.ls = A(rad(55 + math.max(0, math.sin(b + math.pi)) * 30), 0, 0)
	s.re = A(rad(40), 0, 0); s.le = A(rad(40), 0, 0); s.waist = A(rad(-18), 0, 0); s.neck = A(rad(math.sin(b) * 6), 0, 0)
	return s
end
POSES.holdPhoto = function(j, t)
	local s = POSES.sitGround(j, t)
	s.ls = A(rad(55), 0, rad(-10)); s.le = A(rad(80), 0, 0); s.neck = A(rad(-25), 0, 0)
	return s
end
POSES.aim = function(j)
	return { rs = A(rad(85), 0, rad(-10)), ls = A(rad(80), rad(30), rad(25)), le = A(rad(40), 0, 0), neck = A(0, rad(10), 0) }
end
-- סגנונות ריקוד פרוצדורליים (כל רוקד עם פאזה ומהירות משלו)
POSES.danceArms = function(j, t)
	local b = t * 4.7
	local bounce = math.abs(math.sin(b / 2))
	return { root = CFrame.new(0, -bounce * 0.35, 0), rh = A(rad(bounce * 18), 0, 0), lh = A(rad(bounce * 18), 0, 0), rk = A(rad(-bounce * 30), 0, 0), lk = A(rad(-bounce * 30), 0, 0), rs = A(0, 0, rad(160 + math.sin(b) * 12)), ls = A(0, 0, rad(-160 - math.sin(b) * 12)), re = A(rad(20), 0, 0), le = A(rad(20), 0, 0), neck = A(rad(math.sin(b) * 10), 0, 0) }
end
POSES.danceSway = function(j, t)
	local b = t * 2.4
	return { root = CFrame.new(math.sin(b) * 0.2, -0.1, 0) * A(0, 0, rad(math.sin(b) * 6)), waist = A(0, 0, rad(-math.sin(b) * 9)), rs = A(rad(30), 0, rad(70 + math.sin(b + 1) * 30)), ls = A(rad(30), 0, rad(-70 + math.sin(b) * 30)), re = A(rad(30 + math.sin(b) * 30), 0, 0), le = A(rad(30 + math.sin(b + 2) * 30), 0, 0), neck = A(0, 0, rad(math.sin(b) * 8)) }
end
POSES.danceJump = function(j, t)
	local b = t * 4.7
	local up = math.max(0, math.sin(b))
	return { root = CFrame.new(0, up * 0.6, 0), rk = A(rad(-up * 25), 0, 0), lk = A(rad(-up * 25), 0, 0), rs = A(0, 0, rad(175)), ls = A(rad(40), 0, rad(-20)), le = A(rad(90), 0, 0), re = A(rad(math.sin(b) * 20), 0, 0) }
end
POSES.danceStomp = function(j, t)
	local b = t * 2.35
	local s = math.sin(b)
	return { root = CFrame.new(0, -math.abs(s) * 0.25, 0) * A(0, rad(s * 18), 0), lh = A(rad(math.max(0, s) * 45), 0, 0), lk = A(rad(-math.max(0, s) * 60), 0, 0), rh = A(rad(math.max(0, -s) * 45), 0, 0), rk = A(rad(-math.max(0, -s) * 60), 0, 0), rs = A(rad(60 + s * 30), 0, 0), ls = A(rad(60 - s * 30), 0, 0), re = A(rad(90), 0, 0), le = A(rad(90), 0, 0), waist = A(rad(-10), rad(-s * 12), 0) }
end
Poser.POSES = POSES

local tracked = {}
local function consider(m)
	if m:IsA("Model") and m:FindFirstChildOfClass("Humanoid") then tracked[m] = tracked[m] or { j = nil } end
end
function Poser.Track(m) consider(m) end

function Poser.Init()
	for _, d in ipairs(workspace:GetDescendants()) do if d:IsA("Model") and d:GetAttribute("NPC") then consider(d) end end
	workspace.DescendantAdded:Connect(function(d)
		if d:IsA("Model") then task.defer(function() if d:GetAttribute("NPC") or d:GetAttribute("Local") then consider(d) end end) end
	end)
	for _, p in ipairs(Players:GetPlayers()) do p.CharacterAdded:Connect(consider); if p.Character then consider(p.Character) end end
	Players.PlayerAdded:Connect(function(p) p.CharacterAdded:Connect(consider) end)
	local t0 = os.clock()
	RunService.Stepped:Connect(function()
		local now = os.clock() - t0
		local camPos = workspace.CurrentCamera.CFrame.Position
		for m, st in pairs(tracked) do
			if not m.Parent then tracked[m] = nil continue end
			local pose = m:GetAttribute("Pose")
			local plr = Players:GetPlayerFromCharacter(m)
			if plr then pose = plr:GetAttribute("Crouch") and "crouch" or m:GetAttribute("Pose") end
			local hrp = m:FindFirstChild("HumanoidRootPart")
			if hrp and (hrp.Position - camPos).Magnitude > 260 then continue end
			-- פה מדבר + מצמוץ
			local mouth = m:FindFirstChild("Mouth")
			if mouth then
				local talking = m:GetAttribute("Talking")
				local h = talking and (0.05 + math.abs(math.sin(now * 13) * math.sin(now * 5.3)) * 0.14) or 0.05
				if math.abs(mouth.Size.Y - h) > 0.01 then mouth.Size = Vector3.new(mouth.Size.X, h, mouth.Size.Z) end
			end
			if pose and pose ~= "" and POSES[pose] then
				st.j = st.j or J(m)
				local phase = m:GetAttribute("DancePhase") or 0
				local spd = m:GetAttribute("DanceSpeed") or 1
				local target = POSES[pose](st.j, now * spd + phase)
				for name, motor in pairs(st.j) do
					if motor then motor.Transform = target[name] or CFrame.new() end
				end
				st.posed = true
			elseif st.posed then
				st.posed = false
			end
		end
	end)
end

return Poser
