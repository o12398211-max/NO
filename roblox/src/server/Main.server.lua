-- שרת: אירועי רשת, לובי/פורטלים, ReservedServer, בניית העולם, פרקים, אדמין
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")
local Shared = RS:WaitForChild("Shared")
local Config = require(Shared.Config)
local World = require(script.Parent.World)

local remotes = Instance.new("Folder"); remotes.Name = "Remotes"; remotes.Parent = RS
local function remote(n) local r = Instance.new("RemoteEvent"); r.Name = n; r.Parent = remotes; return r end
local StartReq, Story, AdminCmd, Portal = remote("StartReq"), remote("Story"), remote("AdminCmd"), remote("Portal")

local function isAdmin(plr)
	if plr.UserId == game.CreatorId then return true end
	for _, id in ipairs(Config.AdminUserIds) do if id == plr.UserId then return true end end
	return game:GetService("RunService"):IsStudio()
end

World.BuildLobby()
World.BuildFestival()

-- פורטלים: נגיעה בעיגול פותחת UI
for _, p in ipairs(workspace.Lobby.Portals:GetChildren()) do
	p.Touched:Connect(function(hit)
		local plr = Players:GetPlayerFromCharacter(hit.Parent)
		if plr then Portal:FireClient(plr, p.Name) end
	end)
end

local chapter = 0
StartReq.OnServerEvent:Connect(function(plr, size, friendsOnly)
	if typeof(size) ~= "number" then return end
	if friendsOnly and Config.GamePlaceId ~= 0 then
		local ok, code = pcall(function() return TeleportService:ReserveServer(Config.GamePlaceId) end)
		if ok then TeleportService:TeleportToPrivateServer(Config.GamePlaceId, code, { plr }) return end
	end
	chapter = 1
	for _, p in ipairs(Players:GetPlayers()) do
		if p.Character then p.Character:PivotTo(workspace.Festival.Spawn.CFrame + Vector3.new(math.random(-4, 4), 3, 0)) end
	end
	Story:FireAllClients("chapter", 1)
end)

AdminCmd.OnServerEvent:Connect(function(plr, cmd, arg)
	if not isAdmin(plr) then return end
	if cmd == "chapter" then chapter = arg; Story:FireAllClients("chapter", arg)
	elseif cmd == "kick" then local t = Players:FindFirstChild(tostring(arg)); if t then t:Kick("הוצאת מהחדר") end
	elseif cmd == "time" then game.Lighting.ClockTime = arg
	elseif cmd == "speed" and plr.Character then plr.Character.Humanoid.WalkSpeed = arg
	elseif cmd == "tp" and plr.Character then plr.Character:PivotTo(CFrame.new(arg)) end
end)

Players.PlayerAdded:Connect(function(plr)
	plr:SetAttribute("IsAdmin", isAdmin(plr))
end)
