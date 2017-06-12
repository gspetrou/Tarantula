trn.Roles = trn.Roles or {}

-------------------------------------
-- ConVar:		trn_always_spectator
-------------------------------------
-- Desc:		Puts the player into spectator mode. Won't ever spawn in, just spectates.
-- Arg One:		Number boolean, 0 or 1 to toggle the convar.
local always_spec = CreateClientConVar("trn_always_spectator", "0", true, false, "Setting this to true will always make you a spectator.")
cvars.AddChangeCallback("trn_always_spectator", function(_, _, newval)
	newval = newval == "1" and true or false
	
	net.Start("trn.Roles.ChangedSpectatorMode")
		net.WriteBool(newval)
	net.SendToServer()
end)

---------------------------------
-- trn.Roles.InitializeSpectator
---------------------------------
-- Desc:		Tell's the server what this player's spectator state is.
function trn.Roles.InitializeSpectator()
	local isspec = always_spec:GetString() == "1" and true or false
	net.Start("trn.Roles.ChangedSpectatorMode")
		net.WriteBool(isspec)
	net.SendToServer()
end

net.Receive("trn.Roles.Clear", function()
	local numplys = net.ReadUInt(7)
	local activeplayers = {}
	for i = 1, numplys do
		activeplayers[net.ReadPlayer()] = true
	end

	for i, v in ipairs(player.GetAll()) do
		if activeplayers[v] then
			v:SetRole(ROLE_WAITING)
		else
			v:SetRole(ROLE_SPECTATOR)
		end
	end
end)

net.Receive("trn.Roles.Sync", function()
	local numReds = net.ReadUInt(7)
	for i = 1, numReds do
		net.numReds():SetRole(ROLE_RED)
	end

	local numBlues = net.ReadUInt(7)
		for i = 1, numBlues do
		net.ReadPlayer():SetRole(ROLE_BLUE)
	end

	local numSpectators = net.ReadUInt(7)
	for i = 1, numSpectators do
		net.ReadPlayer():SetRole(ROLE_SPECTATOR)
	end

	-- Any player without a role, set to waiting.
	for i, v in ipairs(player.GetAll()) do
		if v:IsWaiting() then
			v:SetRole(ROLE_WAITING)
		end
	end
end)

net.Receive("trn.Roles.PlayerSwitchedRole", function()
	local role = net.ReadUInt(3)
	local ply = net.ReadPlayer()
	ply:SetRole(role)
end)