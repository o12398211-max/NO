-- ═══════════════════════════════════════════════════════════════════
--  Cinematic – קאטסינס: שוטים עם דולי/פאן/קריין/קלוז־אפ, מצלמת יד, Letterbox, DOF, אירועים מתוזמנים
--  shot = { dur, from = {pos, look, fov}, to = {...}, ease, hand, dof = {focus, radius}, at = {{t, fn}}, track = fn }
-- ═══════════════════════════════════════════════════════════════════
local RunService = game:GetService("RunService")
local UI = require(script.Parent.UI)
local Effects = require(script.Parent.Effects)
local C = {}
C.Active = false
local cam = workspace.CurrentCamera

local EASE = {
	linear = function(t) return t end,
	inOut = function(t) return t * t * (3 - 2 * t) end,
	out = function(t) return 1 - (1 - t) ^ 3 end,
	inn = function(t) return t * t * t end,
}
local function val(v) if typeof(v) == "function" then return v() end return v end

--- מנגן רשימת שוטים (חוסם). opts: letterbox, skippable
function C.Play(shots, opts)
	opts = opts or {}
	C.Active = true
	cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	if opts.letterbox ~= false then UI.Letterbox(true) end
	UI.BlockPrompts = true
	UI.HidePrompt()
	local skip = false
	local conn
	if opts.skippable then
		conn = game:GetService("UserInputService").InputBegan:Connect(function(i) if i.KeyCode == Enum.KeyCode.Space then skip = true end end)
	end
	for _, s in ipairs(shots) do
		if skip then for _, a in ipairs(s.at or {}) do if a.always then a.fn() end end continue end
		local t = 0
		local fired = {}
		if s.dof then Effects.SetDOF(true, s.dof.focus, s.dof.radius or 2, 0.6, 0.75) else Effects.SetDOF(false) end
		if s.onStart then s.onStart() end
		local fromPos, fromLook = val(s.from.pos), val(s.from.look)
		local to = s.to or s.from
		local toPos, toLook = val(to.pos), val(to.look)
		local f0, f1 = s.from.fov or 50, to.fov or s.from.fov or 50
		while t < s.dur and not skip do
			local dt = RunService.RenderStepped:Wait()
			t += dt
			local k = math.min(1, t / s.dur)
			local e = (EASE[s.ease or "inOut"])(k)
			for i, a in ipairs(s.at or {}) do if not fired[i] and t >= a.t then fired[i] = true; task.spawn(a.fn) end end
			local p = (s.from.follow and s.from.follow() or fromPos):Lerp(to.follow and to.follow() or toPos, e)
			local l = (s.from.track and s.from.track() or fromLook):Lerp(to.track and to.track() or toLook, e)
			local h = s.hand or 0.15
			local tm = os.clock()
			p += Vector3.new(math.sin(tm * 1.3) * 0.03 * h, math.sin(tm * 1.7 + 1) * 0.025 * h, 0)
			cam.CFrame = CFrame.lookAt(p, l) * CFrame.Angles(0, 0, s.roll or 0) * Effects.ShakeOffset(dt)
			cam.FieldOfView = f0 + (f1 - f0) * e
		end
	end
	if conn then conn:Disconnect() end
	Effects.SetDOF(false)
	if opts.letterbox ~= false then UI.Letterbox(false) end
	if not opts.keep then C.Release() end
	UI.BlockPrompts = false
end

--- מצלמה ידנית (קאטסין בגוף ראשון בשליטת הקוד)
function C.Take()
	C.Active = true
	cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	UI.BlockPrompts = true
	UI.HidePrompt()
end
function C.Release()
	C.Active = false
	cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Custom
	cam.FieldOfView = 72
	UI.BlockPrompts = false
end
--- תנועה חלקה של המצלמה ל-CFrame (חוסם)
function C.MoveTo(cf, dur, ease, fov)
	cam = workspace.CurrentCamera
	local c0, f0 = cam.CFrame, cam.FieldOfView
	local t = 0
	while t < dur do
		local dt = RunService.RenderStepped:Wait()
		t += dt
		local e = (EASE[ease or "inOut"])(math.min(1, t / dur))
		cam.CFrame = c0:Lerp(cf, e) * Effects.ShakeOffset(dt)
		if fov then cam.FieldOfView = f0 + (fov - f0) * e end
	end
end
function C.Hold(dur, fn)
	local t = 0
	while t < dur do
		local dt = RunService.RenderStepped:Wait()
		t += dt
		if fn then fn(t, dt) end
	end
end

return C
