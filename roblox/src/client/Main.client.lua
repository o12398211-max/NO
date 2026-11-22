-- לקוח: אזהרת טריגר, הגדרות, UI לובי (פורטלים), אפקטים קולנועיים, גוף ראשון, אדמין (F9), פרקים 1–2
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local T = require(RS:WaitForChild("Shared"):WaitForChild("Texts"))
local Config = require(RS.Shared.Config)
local Remotes = RS:WaitForChild("Remotes")
local plr = Players.LocalPlayer
local cam = workspace.CurrentCamera
local settings = { ReduceScare = false, ReduceFlash = false, BigSubs = false }

-- ─ תאורה ופוסט ─
local function fx(cls, props) local e = Lighting:FindFirstChildOfClass(cls) or Instance.new(cls); for k, v in pairs(props) do e[k] = v end; e.Parent = Lighting; return e end
local atm = fx("Atmosphere", { Density = 0.35, Haze = 2, Color = Color3.fromRGB(60, 40, 90), Decay = Color3.fromRGB(30, 20, 50) })
local cc = fx("ColorCorrectionEffect", { Saturation = 0.15, Contrast = 0.1, TintColor = Config.Grades.Party.Tint })
local bloom = fx("BloomEffect", { Intensity = 0.8, Size = 32, Threshold = 0.9 })
local dof = fx("DepthOfFieldEffect", { Enabled = false, FarIntensity = 0.3, FocusDistance = 10, InFocusRadius = 15 })
local rays = fx("SunRaysEffect", { Intensity = 0.05, Spread = 0.6 })
local blur = fx("BlurEffect", { Size = 0 })

-- ─ GUI ─
local gui = Instance.new("ScreenGui"); gui.Name = "Hazricha"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.Parent = plr:WaitForChild("PlayerGui")
local function label(parent, text, size, pos, ts)
	local l = Instance.new("TextLabel"); l.BackgroundTransparency = 1; l.Text = text; l.Size = size; l.Position = pos; l.TextColor3 = Color3.fromRGB(244, 239, 230)
	l.Font = Enum.Font.GothamMedium; l.TextSize = ts or 18; l.TextWrapped = true; l.TextXAlignment = Enum.TextXAlignment.Right; l.Parent = parent; return l
end
local function button(parent, text, pos, primary)
	local b = Instance.new("TextButton"); b.Size = UDim2.fromOffset(260, 46); b.Position = pos; b.Text = text; b.Font = Enum.Font.GothamBold; b.TextSize = 17
	b.BackgroundColor3 = primary and Color3.fromRGB(255, 160, 100) or Color3.fromRGB(40, 34, 50); b.TextColor3 = primary and Color3.fromRGB(27, 16, 6) or Color3.new(1, 1, 1)
	local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, 12); c.Parent = b; b.Parent = parent; return b
end
local fade = Instance.new("Frame"); fade.Size = UDim2.fromScale(1, 1); fade.BackgroundColor3 = Color3.new(0, 0, 0); fade.BorderSizePixel = 0; fade.ZIndex = 50; fade.Parent = gui
local subs = label(gui, "", UDim2.new(0.7, 0, 0, 60), UDim2.new(0.15, 0, 0.82, 0), 22); subs.TextXAlignment = Enum.TextXAlignment.Center
local objective = label(gui, "", UDim2.fromOffset(360, 40), UDim2.new(1, -390, 0, 30), 18)
local function sub(text, dur) subs.TextSize = settings.BigSubs and 30 or 22; subs.Text = text; task.delay(dur or 3, function() if subs.Text == text then subs.Text = "" end end) end
local function fadeTo(a, t) TweenService:Create(fade, TweenInfo.new(t or 1), { BackgroundTransparency = 1 - a }):Play() end

-- ─ אזהרת טריגר (חובה לפני הכול) ─
local function toggleRow(parent, key, y)
	local b = button(parent, "", UDim2.new(0.5, -130, 0, y), false)
	local function upd() b.Text = T.Settings[key] .. ": " .. (settings[key] and "מופעל" or "כבוי") end
	upd(); b.MouseButton1Click:Connect(function() settings[key] = not settings[key]; upd() end)
end
do
	local w = Instance.new("Frame"); w.Size = UDim2.fromScale(1, 1); w.BackgroundColor3 = Color3.new(0, 0, 0); w.ZIndex = 60; w.Parent = gui
	local h = label(w, T.Warning.Heading, UDim2.new(0.7, 0, 0, 50), UDim2.new(0.15, 0, 0.06, 0), 34); h.ZIndex = 61
	local b = label(w, T.Warning.Body, UDim2.new(0.7, 0, 0.45, 0), UDim2.new(0.15, 0, 0.14, 0), 17); b.ZIndex = 61; b.TextYAlignment = Enum.TextYAlignment.Top
	toggleRow(w, "ReduceScare", 470); toggleRow(w, "ReduceFlash", 522); toggleRow(w, "BigSubs", 574)
	local ok = button(w, T.Warning.Accept, UDim2.new(0.5, 10, 0, 640), true)
	local ex = button(w, T.Warning.Exit, UDim2.new(0.5, -270, 0, 640), false)
	for _, x in ipairs(w:GetDescendants()) do if x:IsA("GuiObject") then x.ZIndex = 61 end end
	local done = Instance.new("BindableEvent")
	ok.MouseButton1Click:Connect(function() w:Destroy(); done:Fire() end)
	ex.MouseButton1Click:Connect(function() plr:Kick("תודה. שמרו על עצמכם.") end)
	done.Event:Wait()
	fadeTo(0, 1.5)
end

-- ─ UI פורטל: גודל שרת, חברים בלבד, התחל ─
local portalUI
Remotes.Portal.OnClientEvent:Connect(function(name)
	if portalUI then return end
	portalUI = Instance.new("Frame"); portalUI.Size = UDim2.fromOffset(340, 300); portalUI.Position = UDim2.new(0.5, -170, 0.5, -150); portalUI.BackgroundColor3 = Color3.fromRGB(14, 12, 20); portalUI.BackgroundTransparency = 0.15; portalUI.Parent = gui
	Instance.new("UICorner", portalUI).CornerRadius = UDim.new(0, 18)
	label(portalUI, T.Lobby.ServerSize, UDim2.new(1, -30, 0, 30), UDim2.fromOffset(15, 14), 18)
	local size = tonumber(name:match("%d+")) or 4; local friends = false
	local sizeB = button(portalUI, tostring(size), UDim2.fromOffset(40, 54), false)
	sizeB.MouseButton1Click:Connect(function() local i = table.find(Config.ServerSizes, size) or 1; size = Config.ServerSizes[i % #Config.ServerSizes + 1]; sizeB.Text = tostring(size) end)
	local fb = button(portalUI, T.Lobby.FriendsOnly .. ": כבוי", UDim2.fromOffset(40, 112), false)
	fb.MouseButton1Click:Connect(function() friends = not friends; fb.Text = T.Lobby.FriendsOnly .. (friends and ": מופעל" or ": כבוי") end)
	local st = button(portalUI, T.Lobby.Start, UDim2.fromOffset(40, 200), true)
	st.MouseButton1Click:Connect(function() Remotes.StartReq:FireServer(size, friends); portalUI:Destroy(); portalUI = nil end)
end)

-- ─ גוף ראשון: head bob, FOV בספרינט, נשימה ─
local bobT = 0
RunService.RenderStepped:Connect(function(dt)
	local char = plr.Character; if not char then return end
	local hum = char:FindFirstChildOfClass("Humanoid"); if not hum then return end
	local speed = (char.PrimaryPart and char.PrimaryPart.AssemblyLinearVelocity.Magnitude) or 0
	bobT += dt * (speed > 14 and 13 or 8)
	local amt = math.clamp(speed / 16, 0, 1)
	hum.CameraOffset = Vector3.new(math.sin(bobT) * 0.08 * amt, math.abs(math.cos(bobT)) * 0.12 * amt, 0)
	cam.FieldOfView += ((speed > 14 and 80 or 72) - cam.FieldOfView) * math.min(1, dt * 4)
end)
UIS.InputBegan:Connect(function(i, gp)
	if gp then return end
	local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
	if i.KeyCode == Enum.KeyCode.LeftShift and hum then hum.WalkSpeed = 24 end
end)
UIS.InputEnded:Connect(function(i) local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid"); if i.KeyCode == Enum.KeyCode.LeftShift and hum then hum.WalkSpeed = 12 end end)

-- ─ פרקים ─
local function chapter1()
	plr.CameraMode = Enum.CameraMode.LockFirstPerson
	Lighting.ClockTime = 0.5; cc.TintColor = Config.Grades.Party.Tint; cc.Saturation = 0.15; atm.Color = Color3.fromRGB(60, 40, 90)
	-- קאטסין פתיחה קצר
	cam.CameraType = Enum.CameraType.Scriptable
	cam.CFrame = CFrame.new(120, 80, 120, 0, 5, -60)
	fadeTo(0, 1)
	TweenService:Create(cam, TweenInfo.new(7, Enum.EasingStyle.Sine), { CFrame = CFrame.lookAt(Vector3.new(30, 10, 10), Vector3.new(0, 6, -60)) }):Play()
	sub("פרק ראשון – " .. T.Chapters[1], 4); task.wait(7.5)
	cam.CameraType = Enum.CameraType.Custom
	objective.Text = T.CH1.FindFriends
	task.wait(40)
	objective.Text = T.CH1.Shachar
	for _, l in ipairs(T.CH1.ShacharLines) do sub("שחר: " .. l, 4.5); task.wait(4.8) end
	objective.Text = T.CH1.Tent; task.wait(30)
	objective.Text = ""
	blur.Size = 10; fadeTo(1, 3); task.wait(3.5)
end
local function chapter2()
	Lighting.ClockTime = 6.4; cc.TintColor = Config.Grades.Dawn.Tint; cc.Saturation = -0.3; cc.Contrast = 0.22; atm.Color = Color3.fromRGB(200, 160, 130); rays.Intensity = 0.15
	fadeTo(0, 2); blur.Size = 24
	TweenService:Create(blur, TweenInfo.new(4), { Size = 0 }):Play()
	sub(T.CH2.Alarm, 3); task.wait(3); sub(T.CH2.Wake, 2); task.wait(2.5); sub(T.CH2.Shachar, 3)
end
local STORY = {
	{ "פרק שלישי – המנהרה", "אסתר: שקט. את/ה איתנו. אני אסתר. זה עידו, וזה מאיר.", "אסתר: \"מים\". הפתח במים. התעלה שמתחת לרצפה.", "עידו מנגן על הצינור – ההד מושך את השומרים", "אסתר: אני נשארת. מישהו צריך לשמור על כולם. לך/י." },
	{ "פרק רביעי – בחוץ", "המפה: נקודה מסומנת רחוק", "להסתתר מהסיורים ולהגיע לנקודה", "פנסים נדלקים בבת אחת…" },
	{ "פרק חמישי – המטוס", "שחר… הצמיד התאום", "צריך לשירותים", "במגירה מתחת לכיור…" },
	{ "פרק שישי – הבית", "צביקה: קח/י. היא כבר ארוזה. והמשואה בכיס הקדמי.", "הקפיצה", "המשואה הובילה את חיל האוויר למטוס, והוא נחת בבטחה עם כל נוסעיו.", "שחר: אמרתי לך. בזריחה. ביחד.", T.Dedication },
}
local function storyChapters()
	for _, ch in ipairs(STORY) do
		fadeTo(1, 1); task.wait(1.2); fadeTo(0, 1)
		for _, line in ipairs(ch) do sub(line, 4.5); task.wait(4.8) end
	end
end
Remotes.Story.OnClientEvent:Connect(function(kind, n)
	if kind == "chapter" then
		fadeTo(1, 0.6); task.wait(0.7)
		if n == 1 then chapter1(); chapter2() elseif n == 2 then chapter2() end
		if n <= 2 then task.wait(20) end
		storyChapters()
	end
end)

-- ─ אדמין (F9) – רק לבעלים/אדמינים ─
local adminF
UIS.InputBegan:Connect(function(i)
	if i.KeyCode ~= Enum.KeyCode.F9 or not plr:GetAttribute("IsAdmin") then return end
	if adminF then adminF:Destroy(); adminF = nil return end
	adminF = Instance.new("Frame"); adminF.Size = UDim2.fromOffset(300, 360); adminF.Position = UDim2.fromOffset(16, 60); adminF.BackgroundColor3 = Color3.fromRGB(10, 14, 10); adminF.Parent = gui
	label(adminF, T.Admin.Title, UDim2.new(1, -20, 0, 30), UDim2.fromOffset(10, 6), 14)
	local y = 44
	local function cmd(text, fn) local b = button(adminF, text, UDim2.fromOffset(20, y), false); b.Size = UDim2.fromOffset(260, 34); b.MouseButton1Click:Connect(fn); y += 40 end
	for n = 1, 2 do cmd(T.Admin.Chapter .. " " .. n, function() Remotes.AdminCmd:FireServer("chapter", n) end) end
	cmd(T.Admin.Speed .. " ×3", function() Remotes.AdminCmd:FireServer("speed", 48) end)
	cmd(T.Admin.Time .. " 12:00", function() Remotes.AdminCmd:FireServer("time", 12) end)
	cmd(T.Admin.Fly, function() local h = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid"); if h then h.JumpPower = 150 end end)
end)
