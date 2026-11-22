-- ═══════════════════════════════════════════════════════════════════
--  עד הזריחה – שרת ראשי: Remotes, לובי ופורטלים (שרת פרטי דרך ReservedServer),
--  מראה הדמות, התקדמות העלילה, ירי השחקן, אדמין (רק UserId 9214350185)
-- ═══════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Lighting = game:GetService("Lighting")
local Config = require(RS.Shared.Config)
local Story = require(script.Parent.Story)
local NPC = require(script.Parent.NPC)
local Enemies = require(script.Parent.Enemies)
local Maps = require(script.Parent.World.Maps)

Players.CharacterAutoLoads = true

-- ─ Remotes ─
local folder = Instance.new("Folder"); folder.Name = "Remotes"; folder.Parent = RS
local R = {}
for _, n in ipairs({ "Chapter", "Story", "Progress", "State", "Fx", "Look", "Portal", "PortalStart", "Admin", "AdminLog", "Score", "Shoot", "Lobby" }) do
	local e = Instance.new("RemoteEvent"); e.Name = n; e.Parent = folder; R[n] = e
end
Story.Init(R)

-- ─ תבניות לדמויות מקומיות בלקוח (המון נמלט, דמויות בקאטסינס) ─
local templates = Instance.new("Folder"); templates.Name = "Templates"; templates.Parent = RS
task.spawn(function()
	for i = 1, 16 do
		local n = NPC.Create(workspace, NPC.RandomLook(900 + i), CFrame.new(0, -500, 0), { name = "Crowd" .. i, anim = "Idle" })
		if n then n.Model.Parent = templates end
	end
	local t = NPC.Terrorist(workspace, CFrame.new(0, -500, 0), {})
	if t then t.Model.Name = "Terrorist"; t.Model.Parent = templates end
	local sh = NPC.Create(workspace, NPC.Looks.shachar, CFrame.new(0, -500, 0), { name = "Shachar", anim = "Idle" })
	if sh then sh.Model.Parent = templates end
end)

-- ─ לובי ─
local lobby = Instance.new("Folder"); lobby.Name = "LobbyMap"; lobby.Parent = workspace
local lobbyModel = Maps.Lobby(lobby, Config.Origins.Lobby)
local lobbySpawn = Config.Origins.Lobby + Vector3.new(0, 3, 30)
local function toLobby(plr)
	local char = plr.Character
	if char then char:PivotTo(CFrame.new(lobbySpawn + Vector3.new(math.random(-8, 8), 0, math.random(-4, 4)))) end
end

local isAdmin = function(plr) return plr.UserId == Config.AdminUserId end

Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("IsAdmin", isAdmin(plr))
	plr:SetAttribute("CharName", plr.DisplayName)
	plr:SetAttribute("Gender", "m")
	plr:SetAttribute("Skin", 3); plr:SetAttribute("Hair", 1); plr:SetAttribute("HairColor", 2); plr:SetAttribute("Outfit", 1)
	plr:SetAttribute("UseAvatar", false)
	plr.CharacterAdded:Connect(function(char)
		local hum = char:WaitForChild("Humanoid")
		hum.BreakJointsOnDeath = false
		hum.WalkSpeed = 11
		hum.JumpHeight = 5
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.Viewer
		hum.NameDisplayDistance = 40
		hum.DisplayName = plr:GetAttribute("CharName") or plr.DisplayName
		task.wait(0.2)
		if plr:GetAttribute("Styled") then NPC.ApplyToPlayer(plr) end
		if not plr:GetAttribute("InStory") then toLobby(plr) end
	end)
	-- שרת פרטי: מצטרפים ישר לסיפור
	local data = plr:GetJoinData() and plr:GetJoinData().TeleportData
	if data and data.party then plr:SetAttribute("Party", true) end
end)
Players.PlayerRemoving:Connect(function(plr)
	if Story.Running and #Story.storyPlayers() == 0 then Story.End() end
end)

-- מראה הדמות מהלובי
R.Look.OnServerEvent:Connect(function(plr, t)
	if typeof(t) ~= "table" then return end
	local name = typeof(t.name) == "string" and t.name:sub(1, 32) or plr.DisplayName
	pcall(function() name = game:GetService("TextService"):FilterStringAsync(name, plr.UserId):GetNonChatStringForBroadcastAsync() end)
	plr:SetAttribute("CharName", name ~= "" and name or plr.DisplayName)
	plr:SetAttribute("Gender", t.gender == "f" and "f" or "m")
	local function clampI(v, max) v = tonumber(v) or 1; return math.clamp(math.floor(v), 1, max) end
	plr:SetAttribute("Skin", clampI(t.skin, #Config.Skin))
	plr:SetAttribute("Hair", clampI(t.hair, 5))
	plr:SetAttribute("HairColor", clampI(t.hairColor, #Config.HairColors))
	plr:SetAttribute("Outfit", clampI(t.outfit, #Config.Outfits))
	plr:SetAttribute("UseAvatar", t.useAvatar == true)
	plr:SetAttribute("Styled", true)
	if not plr:GetAttribute("UseAvatar") then
		local desc = Instance.new("HumanoidDescription")
		desc.HeightScale = 1; desc.WidthScale = plr:GetAttribute("Gender") == "f" and 0.92 or 1; desc.ProportionScale = 0.5
		pcall(function() plr:LoadCharacterWithHumanoidDescription(desc) end)
	else
		plr:LoadCharacter()
	end
end)

-- ─ פורטלים ─
local session = nil -- { host, size, members }
local function membersIn(size)
	local zone = lobbyModel.Portals:FindFirstChild("Zone" .. size)
	local list = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
		if hrp and zone then
			local rel = zone.CFrame:PointToObjectSpace(hrp.Position)
			if math.abs(rel.X) < zone.Size.X / 2 and math.abs(rel.Z) < zone.Size.Z / 2 and math.abs(rel.Y) < 6 then table.insert(list, p) end
		end
	end
	return list
end
local lastPortal = {}
for _, z in ipairs(lobbyModel.Portals:GetChildren()) do
	if z.Name:match("^Zone") then
		z.Touched:Connect(function(hit)
			local plr = Players:GetPlayerFromCharacter(hit.Parent)
			if not plr or plr:GetAttribute("InStory") then return end
			if lastPortal[plr] and os.clock() - lastPortal[plr] < 4 then return end
			lastPortal[plr] = os.clock()
			R.Portal:FireClient(plr, z:GetAttribute("Size"), #membersIn(z:GetAttribute("Size")), Story.Running)
		end)
	end
end

local function startStory(members, chapter)
	for _, p in ipairs(members) do p:SetAttribute("InStory", true) end
	Story.Score = {}
	Story.Load(chapter or 1)
end
Story.OnEnd = function()
	for _, p in ipairs(Players:GetPlayers()) do toLobby(p) end
	Lighting.ClockTime = Config.Grades.Lobby.Clock
end

R.PortalStart.OnServerEvent:Connect(function(plr, size, friendsOnly)
	size = tonumber(size) or 4
	if not table.find(Config.ServerSizes, size) then return end
	local members = membersIn(size)
	if not table.find(members, plr) then table.insert(members, 1, plr) end
	while #members > size do table.remove(members) end
	if friendsOnly or Story.Running then
		-- שרת פרטי חדש לחברים שבעיגול
		R.Lobby:FireClient(plr, "teleporting")
		local ok, err = pcall(function()
			local code = TeleportService:ReserveServer(game.PlaceId)
			local opts = Instance.new("TeleportOptions")
			opts.ReservedServerAccessCode = code
			opts:SetTeleportData({ party = true, size = size, count = #members })
			TeleportService:TeleportAsync(game.PlaceId, members, opts)
		end)
		if ok then return end
		warn("Teleport failed: " .. tostring(err))
		if Story.Running then R.Lobby:FireClient(plr, "busy") return end
		R.Lobby:FireClient(plr, "teleportFail")
	end
	startStory(members, 1)
end)

-- שרת פרטי: מתחילים אוטומטית כשכולם הגיעו
task.spawn(function()
	if game.PrivateServerId == "" or game.PrivateServerOwnerId ~= 0 then return end
	local t0 = os.clock()
	local expected = 1
	while os.clock() - t0 < Config.SessionStartWait do
		for _, p in ipairs(Players:GetPlayers()) do
			local jd = p:GetJoinData(); local td = jd and jd.TeleportData
			if td and td.count then expected = td.count end
		end
		if #Players:GetPlayers() >= expected and #Players:GetPlayers() > 0 then break end
		task.wait(1)
	end
	task.wait(4)
	if not Story.Running and #Players:GetPlayers() > 0 then startStory(Players:GetPlayers(), 1) end
end)

-- ─ מצב שחקן (כפיפה/ריצה) ─
R.State.OnServerEvent:Connect(function(plr, t)
	if typeof(t) ~= "table" then return end
	plr:SetAttribute("Crouch", t.crouch == true or nil)
	plr:SetAttribute("Running", t.running == true or nil)
	if t.lights ~= nil then
		local hum = plr.Character and plr.Character:FindFirstChildOfClass("Humanoid")
		local seat = hum and hum.SeatPart
		if seat and seat:IsA("VehicleSeat") then
			for _, car in ipairs(require(script.Parent.Vehicles).Active) do if car.Seat == seat then car:SetLights(t.lights == true) end end
		end
	end
end)

-- ─ התקדמות עלילה מהלקוח ─
local allowedFlags = { Awake = true, Bracelet = true, Asleep = true, Captured = true, Exited = true, Done = true }
R.Progress.OnServerEvent:Connect(function(plr, key, val)
	if not plr:GetAttribute("InStory") or typeof(key) ~= "string" then return end
	if allowedFlags[key] then
		plr:SetAttribute(key, true)
		if key == "Bracelet" then
			if plr.Character then NPC.ApplyToPlayer(plr) end
			Story.AddPuzzle(plr)
		end
		if key == "Captured" then plr:SetAttribute("Capturing", nil) end
		return
	end
	if key == "puzzle" then Story.AddPuzzle(plr) return end
	if key == "gun" then Story.SpawnTargets(plr) return end
	if Story.Chapter == 3 and Story.SetFlag3 then
		if key == "decoded" or key == "tool" or key == "plan" then Story.SetFlag3(key); Story.AddPuzzle(plr) end
		if key == "pipesDone" then
			Story.Pipes = Story.Pipes or {}
			Story.Pipes[tonumber(val) or 1] = plr.UserId
			local p1, p2 = Story.Pipes[1], Story.Pipes[2]
			local solo = #Story.storyPlayers() <= 1
			-- שיתוף פעולה: עם כמה שחקנים צריך שני שחקנים שונים על שני הצינורות. לבד – עידו מנגן על השני.
			if solo or (p1 and p2 and p1 ~= p2) then Story.SetFlag3("pipes"); Story.AddPuzzle(plr) end
		end
		if key == "pipeNote" then R.Story:FireAllClients("pipeNote", plr.UserId, val) end
	end
	if key == "guardDown" and Story.Chapter == 6 then
		for _, m in ipairs(Story.Map:GetDescendants()) do
			if m:IsA("Model") and m:GetAttribute("GuardOf") == plr.UserId then m:SetAttribute("Down", true) end
		end
	end
end)
R.Shoot.OnServerEvent:Connect(function(plr, origin, dir) Story.Shoot(plr, origin, dir) end)

-- ─ אדמין: רק UserId 9214350185 ─
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local TextChatService = game:GetService("TextChatService")
local vipStore
pcall(function() vipStore = DataStoreService:GetDataStore("HazrichaVIP_v1") end)
local function filter(text, from)
	text = tostring(text or ""):sub(1, 200)
	local ok, res = pcall(function() return TextService:FilterStringAsync(text, from.UserId):GetNonChatStringForBroadcastAsync() end)
	return ok and res or ""
end
local function findTargets(admin, q)
	q = tostring(q or ""):lower()
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		if q == "all" or q == "" then table.insert(out, p)
		elseif q == "me" then if p == admin then table.insert(out, p) end
		elseif q == "others" then if p ~= admin then table.insert(out, p) end
		elseif p.Name:lower():sub(1, #q) == q or p.DisplayName:lower():sub(1, #q) == q or (p:GetAttribute("CharName") or ""):lower():sub(1, #q) == q then table.insert(out, p) end
	end
	return out
end
local function setVIP(userId, on)
	local p = Players:GetPlayerByUserId(userId)
	if p then p:SetAttribute("VIP", on or nil) end
	if vipStore then pcall(function() vipStore:SetAsync(tostring(userId), on and true or nil) end) end
end
Players.PlayerAdded:Connect(function(p)
	if vipStore then task.spawn(function() local ok, v = pcall(function() return vipStore:GetAsync(tostring(p.UserId)) end); if ok and v then p:SetAttribute("VIP", true) end end) end
end)
local poll = nil
R.Progress.OnServerEvent:Connect(function(p, key, val)
	if key == "vote" and poll and typeof(val) == "number" and val >= 1 and val <= 4 and not poll.voted[p.UserId] then
		poll.voted[p.UserId] = true
		poll.counts[val] += 1
		R.Story:FireAllClients("pollUpdate", poll.counts)
	end
end)
local function log(plr, s) R.AdminLog:FireClient(plr, s) end
local function places()
	local o = Config.Origins.Festival
	local F = require(script.Parent.World.Festival)
	return { stage = o + F.L.Stage + Vector3.new(0, 8, 0), backstage = o + F.L.Stage + Vector3.new(0, 4, -40), tent = o + F.L.OurTent + Vector3.new(0, 4, -12), lobby = lobbySpawn }
end
R.Admin.OnServerEvent:Connect(function(plr, cmd, a, b, c)
	if not isAdmin(plr) then return end
	local char = plr.Character
	if cmd == "announce" then local t = filter(a, plr); if t ~= "" then R.Story:FireAllClients("announce", plr:GetAttribute("CharName") or plr.DisplayName, t) end; log(plr, "הכרזה נשלחה")
	elseif cmd == "servermsg" then R.Story:FireAllClients("servermsg", filter(a, plr)); log(plr, "הודעת שרת")
	elseif cmd == "poll" then
		local opts = {}
		for i = 1, 4 do opts[i] = filter(typeof(b) == "table" and b[i] or "", plr) end
		poll = { q = filter(a, plr), opts = opts, counts = { 0, 0, 0, 0 }, voted = {} }
		local secs = math.clamp(tonumber(c) or 120, 15, 7200)
		R.Story:FireAllClients("poll", poll.q, poll.opts, secs)
		local my = poll
		task.delay(secs, function() if poll == my then R.Story:FireAllClients("pollEnd", poll.counts); poll = nil end end)
		log(plr, "סקר נפתח")
	elseif cmd == "event" then
		for _, t in ipairs(findTargets(plr, b)) do R.Story:FireClient(t, "event", a, math.clamp(tonumber(c) or 10, 1, 600)) end
		log(plr, "אירוע: " .. tostring(a))
	elseif cmd == "stopEvents" then R.Story:FireAllClients("event", "stop", 0)
	elseif cmd == "jumpscare" then for _, t in ipairs(findTargets(plr, a)) do R.Story:FireClient(t, "jumpscare") end; log(plr, "בוווו")
	elseif cmd == "kick" then for _, t in ipairs(findTargets(plr, a)) do if t ~= plr then t:Kick(tostring(b ~= "" and b or "הוצאת מהשרת")) end end
	elseif cmd == "ban" then
		for _, t in ipairs(findTargets(plr, a)) do
			if t ~= plr then
				local mins = tonumber(b) or 60
				local ok = pcall(function() Players:BanAsync({ UserIds = { t.UserId }, ApplyToUniverse = true, Duration = mins * 60, DisplayReason = "הורחקת מהמשחק", PrivateReason = "admin panel" }) end)
				if not ok then t:Kick("הורחקת מהמשחק") end
			end
		end
		log(plr, "באן")
	elseif cmd == "warn" then for _, t in ipairs(findTargets(plr, a)) do R.Story:FireClient(t, "warn", filter(b, plr)) end; log(plr, "אזהרה נשלחה")
	elseif cmd == "mute" then
		local mins = tonumber(b) or 5
		for _, t in ipairs(findTargets(plr, a)) do
			if t ~= plr then
				for _, ch in ipairs(TextChatService:GetDescendants()) do if ch:IsA("TextSource") and ch.UserId == t.UserId then ch.CanSend = false end end
				task.delay(mins * 60, function() for _, ch in ipairs(TextChatService:GetDescendants()) do if ch:IsA("TextSource") and ch.UserId == t.UserId then ch.CanSend = true end end end)
			end
		end
		log(plr, "השתקה")
	elseif cmd == "vip" then
		local found = findTargets(plr, a)
		if #found == 0 and tostring(a) ~= "" then
			local ok, uid = pcall(function() return Players:GetUserIdFromNameAsync(tostring(a)) end)
			if ok and uid then setVIP(uid, b == true); log(plr, "VIP נשמר ל-" .. tostring(a)) end
		end
		for _, t in ipairs(found) do setVIP(t.UserId, b == true); R.Story:FireClient(t, "vip", b == true) end
		log(plr, b and "VIP ניתן" or "VIP הוסר")
	elseif cmd == "rifle" and char then
		local old = char:FindFirstChild("Rifle"); if old then old:Destroy() end
		plr:SetAttribute("AdminRifle", a == true or nil)
		if a then NPC.Rifle(char) end
		log(plr, a and "רובה אדמין" or "בלי רובה")
	elseif cmd == "rshoot" and plr:GetAttribute("AdminRifle") and char and typeof(a) == "Vector3" and typeof(b) == "Vector3" then
		local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude; params.FilterDescendantsInstances = { char }
		local r = workspace:Raycast(a, b.Unit * 600, params)
		R.Fx:FireAllClients("pshot", a, r and r.Position or a + b.Unit * 600, plr.UserId)
		local m = r and r.Instance:FindFirstAncestorOfClass("Model")
		while m and not m:GetAttribute("Terrorist") and m.Parent and m.Parent ~= workspace do m = m.Parent:FindFirstAncestorOfClass("Model") end
		if m and m:GetAttribute("Terrorist") and not m:GetAttribute("Down") then
			m:SetAttribute("Down", true); m:SetAttribute("Pose", "down")
			for _, e in ipairs(Enemies.List) do if e.N.Model == m then e.Active = false; e.N.Root.Anchored = true end end
			R.Fx:FireAllClients("down", m)
			task.delay(6, function() if m.Parent then m:Destroy() end end)
		end
	elseif cmd == "bracelet" then for _, t in ipairs(findTargets(plr, a)) do t:SetAttribute("Bracelet", true); NPC.ApplyToPlayer(t) end
	elseif cmd == "bring" and char then for _, t in ipairs(findTargets(plr, a)) do if t ~= plr and t.Character then t.Character:PivotTo(char:GetPivot() * CFrame.new(math.random(-4, 4), 0, -4)) end end
	elseif cmd == "tpPlayer" and char then local t = findTargets(plr, a)[1]; if t and t ~= plr and t.Character then char:PivotTo(t.Character:GetPivot() * CFrame.new(3, 0, 0)) end
	elseif cmd == "tpPlace" and char then local p = places()[a]; if p then char:PivotTo(CFrame.new(p)) end
	elseif cmd == "chapter" then
		local n = math.clamp(tonumber(a) or 1, 1, 6)
		if not Story.Running then for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("InStory", true) end end
		Story.Load(n); log(plr, "פרק " .. n)
	elseif cmd == "checkpoint" then
		if not Story.Running then for _, p in ipairs(Players:GetPlayers()) do p:SetAttribute("InStory", true) end end
		local n, cp = tostring(a):match("(%d)%:(%w+)")
		Story.Load(tonumber(n) or 1, cp); log(plr, "צ'קפוינט " .. tostring(a))
	elseif cmd == "speed" then plr:SetAttribute("SpeedMul", (tonumber(a) or 11) / 11); log(plr, "מהירות")
	elseif cmd == "jump" and char then char.Humanoid.JumpHeight = a and 30 or 5
	elseif cmd == "enemies" then Enemies.Disabled = a == true; log(plr, a and "אויבים כבויים" or "אויבים פעילים")
	elseif cmd == "god" then plr:SetAttribute("God", a == true or nil); log(plr, "ללא פגיעה: " .. tostring(a))
	elseif cmd == "time" then Lighting.ClockTime = tonumber(a) or 12
	elseif cmd == "lobby" then Story.End(); log(plr, "חזרה ללובי")
	end
end)

Lighting.ClockTime = Config.Grades.Lobby.Clock
print("[עד הזריחה] השרת מוכן")
