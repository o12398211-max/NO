-- ═══════════════════════════════════════════════════════════════════
--  FirstPerson – גוף ראשון: ידיים נראות, head bob שמתגבר בריצה, FOV בספרינט, כפיפה,
--  "סטמינה" נסתרת (רק נשימה/האטה/טשטוש – בלי מד), פחד → דופק/ויניטה/מנהרה, צעדים לפי משטח, רעידות
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local RS = game:GetService("ReplicatedStorage")
local Audio = require(script.Parent.Audio)
local Effects = require(script.Parent.Effects)
local UI = require(script.Parent.UI)
local Cinematic = require(script.Parent.Cinematic)
local Config = require(RS:WaitForChild("Shared"):WaitForChild("Config"))

local FP = {}
local plr = Players.LocalPlayer
FP.Enabled = false
FP.Fear = 0
FP.Stamina = 1
FP.Exhaust = 0
FP.Crouch = false
FP.Running = false
FP.MoveLocked = false
FP.BreathOverride = nil
FP.WalkSpeed = 11
FP.RunSpeed = 22
local bob, bobAmt, stepAcc = 0, 0, 0
local lastState = {}
local remotes

local VISIBLE = { LeftUpperArm = true, LeftLowerArm = true, LeftHand = true, RightUpperArm = true, RightLowerArm = true, RightHand = true, Bracelet = true }

local function hum()
	local c = plr.Character
	return c and c:FindFirstChildOfClass("Humanoid"), c
end

function FP.Init(r)
	remotes = r
	UIS.InputBegan:Connect(function(i, gp)
		if gp or not FP.Enabled then return end
		if i.KeyCode == Enum.KeyCode.C or i.KeyCode == Enum.KeyCode.LeftControl then FP.Crouch = not FP.Crouch end
	end)
	-- השתקת הצעדים המובנים
	plr.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 5)
		task.wait(0.5)
		if hrp then for _, s in ipairs(hrp:GetChildren()) do if s:IsA("Sound") and (s.Name == "Running" or s.Name == "Jumping" or s.Name == "Landing") then s.Volume = 0 end end end
	end)
	RunService:BindToRenderStep("HazrichaFP", Enum.RenderPriority.Camera.Value + 1, FP.Update)
end

function FP.SetEnabled(on)
	FP.Enabled = on
	plr.CameraMode = on and Enum.CameraMode.LockFirstPerson or Enum.CameraMode.Classic
	plr.CameraMaxZoomDistance = on and 0.5 or 12
	if not on then
		local h = hum()
		if h then h.CameraOffset = Vector3.zero end
	end
end
function FP.LockMove(on)
	FP.MoveLocked = on
	local h = hum()
	if h then h.WalkSpeed = on and 0 or FP.WalkSpeed; h.JumpHeight = on and 0 or 5 end
end

function FP.Update(dt)
	if UI.Cursor > 0 then UIS.MouseBehavior = Enum.MouseBehavior.Default; UIS.MouseIconEnabled = true
	elseif FP.Enabled and not Cinematic.Active then UIS.MouseIconEnabled = false end
	local h, char = hum()
	if not h or not char then return end
	local cam = workspace.CurrentCamera
	-- רעידות מצלמה על כל מצב
	if not Cinematic.Active then cam.CFrame = cam.CFrame * Effects.ShakeOffset(dt) end
	if not FP.Enabled or Cinematic.Active then
		Audio.Body(dt, FP.BreathOverride or FP.Fear * 0.5, FP.Fear, UI.Settings.ReduceScare)
		return
	end
	-- ידיים נראות בגוף ראשון
	for _, p in ipairs(char:GetDescendants()) do
		if p:IsA("BasePart") and (VISIBLE[p.Name] or (p.Parent and p.Parent:IsA("Model") and p:FindFirstChildOfClass("WeldConstraint") and p:FindFirstChildOfClass("WeldConstraint").Part0 and VISIBLE[p:FindFirstChildOfClass("WeldConstraint").Part0.Name])) then
			p.LocalTransparencyModifier = 0
		end
	end
	local vel = char.HumanoidRootPart.AssemblyLinearVelocity
	local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
	local wantRun = UIS:IsKeyDown(Enum.KeyCode.LeftShift) and h.MoveDirection.Magnitude > 0.1 and not FP.Crouch and not FP.MoveLocked
	local seated = h.SeatPart ~= nil
	FP.Running = wantRun and FP.Stamina > 0.02 and not seated
	FP.Stamina = math.clamp(FP.Stamina + (FP.Running and -dt / 9 or dt / (FP.Crouch and 4 or 6)), 0, 1)
	FP.Exhaust += (((FP.Running and FP.Stamina < 0.25) and 1 or (FP.Running and 0.4 or 0)) - FP.Exhaust) * math.min(1, dt * 1.5)
	if not FP.MoveLocked and not seated then
		h.WalkSpeed = FP.Crouch and 5 or (FP.Running and FP.RunSpeed * (0.7 + 0.3 * math.min(1, FP.Stamina * 3)) or FP.WalkSpeed) * (plr:GetAttribute("SpeedMul") or 1)
	end
	-- head bob דינמי
	local grounded = h.FloorMaterial ~= Enum.Material.Air
	bobAmt += (((grounded and not seated) and math.min(1.3, speed / 18) or 0) - bobAmt) * math.min(1, dt * 6)
	bob += dt * (FP.Running and 13 or 8.5) * math.max(0.3, bobAmt)
	local bx = math.sin(bob) * 0.12 * bobAmt * (FP.Running and 1.5 or 1)
	local by = math.abs(math.cos(bob)) * 0.18 * bobAmt * (FP.Running and 1.6 or 1)
	local crouchY = FP.Crouch and -1.7 or 0
	h.CameraOffset = h.CameraOffset:Lerp(Vector3.new(bx, -by + crouchY, 0), math.min(1, dt * 12))
	-- FOV: ספרינט מרחיב, פחד מצמצם
	local danger = plr:GetAttribute("Danger") or 0
	local fear = math.max(FP.Fear, danger)
	local targetFov = 72 + (FP.Running and 8 or 0) - fear * 7
	cam.FieldOfView += (targetFov - cam.FieldOfView) * math.min(1, dt * 4)
	-- ויניטה / טשטוש / מנהרת פחד
	UI.SetVignette(0.42 + FP.Exhaust * 0.3 + math.max(0, fear - 0.5) * 0.7)
	Effects.Blur.Size = math.max(Effects.Blur.Size * 0.9, FP.Exhaust > 0.7 and (FP.Exhaust - 0.7) * 20 or 0)
	-- גוף
	local breath = FP.BreathOverride or math.min(1, FP.Exhaust * 0.9 + fear * 0.5 + (FP.Running and 0.35 or 0))
	Audio.Body(dt, breath, math.max(fear, FP.Exhaust * 0.6), UI.Settings.ReduceScare)
	-- צעדים
	if grounded and speed > 1 and not seated then
		stepAcc += speed * dt
		local stride = FP.Running and 7 or (FP.Crouch and 3.2 or 4.6)
		if stepAcc > stride then stepAcc = 0; Audio.Footstep(h.FloorMaterial, FP.Running and 1 or (FP.Crouch and 0.2 or 0.5)) end
	end
	-- דיווח מצב לשרת (רק בשינוי)
	if remotes and (lastState.crouch ~= FP.Crouch or lastState.running ~= FP.Running) then
		lastState = { crouch = FP.Crouch, running = FP.Running }
		remotes.State:FireServer(lastState)
	end
end

--- מעידה/נחיתה: רעידה + צליל
function FP.Stumble(a)
	Effects.Shake(a or 0.5)
	Audio.Play(Config.Sfx.BodyFall, { vol = 0.6 })
end

return FP
