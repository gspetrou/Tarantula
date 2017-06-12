-- Setup network strings.
util.AddNetworkString("trn.Roles.Sync")
util.AddNetworkString("trn.Roles.Clear")
util.AddNetworkString("trn.Roles.ChangedSpectatorMode")
util.AddNetworkString("trn.Roles.PlayerSwitchedRole")

-- Setup the convars.
local PLAYER = FindMetaTable("Player")

-- We say flying mode here to not confused being a spectator and spectating with being dead and spectating.
------------------------------
-- trn.Roles.SpawnInFlyMode
------------------------------
-- Desc:		Spawns the player in a flying mode.
-- Arg One:		Player, to be set as a spectator.
function trn.Roles.SpawnInFlyMode(ply)
	if not ply.trn_InFlyMode then
		ply:Spectate(OBS_MODE_ROAMING)
		ply.trn_InFlyMode = true
	end

	hook.Call("trn.Roles.PlayerSpawnedInFlyMode", nil, ply)
end

function PLAYER:IsInFlyMode()
	return self.trn_InFlyMode or false
end

---------------------------
-- trn.Roles.SpawnAsPlayer
---------------------------
-- Desc:		Spawns the player as an active player.
-- Arg One:		Player, to spawn as an active player.
-- Arg Two:		Boolean, if true places them at a spawn point.
function trn.Roles.SpawnAsPlayer(ply, resetSpawn)
	if ply:IsInFlyMode() then
		ply:UnSpectate()
		ply.trn_InFlyMode = false
	end
	ply:SetNoDraw(false)
	hook.Call("trn.Roles.PlayerSpawned", nil, ply, false)
end

------------------------
-- trn.Roles.ForceSpawn
------------------------
-- Desc:		Spawns a player mid round.
-- Arg One:		Player, to be spawned.
-- Arg Two:		Boolean, if true places them at a spawn point.
function trn.Roles.ForceSpawn(ply, resetSpawn)
	if not ply:Alive() then
		ply.trn_OverrideSpawn = true
		ply:Spawn()
		ply.trn_OverrideSpawn = false
	end
	ply:UnSpectate()
	ply.trn_InFlyMode = false
	
	hook.Call("trn.Roles.PlayerSpawned", nil, ply, resetSpawn, true)
	ply:SetNoDraw(false) -- For some reason players spawn with no-draw set. This will undo that.
end

----------------------------
-- trn.Roles.SetupSpectator
----------------------------
-- Desc:		Sees if this player should be a spectator and sets them if they should.
function trn.Roles.SetupSpectator(ply)
	if ply:IsSpectator() then
		ply:SetRole(ROLE_SPECTATOR)
	end
end

-----------------------------
-- trn.Roles.GetAlivePlayers
-----------------------------
-- Desc:		Gets all the alive players.
-- Returns:		Table, containning alive players.
function trn.Roles.GetAlivePlayers()
	return table.Filter(player.GetAll(), function(ply)
		if ply:IsInFlyMode() or ply:IsSpectator() then
			return false
		end
		return ply:Alive()
	end)
end

----------------------------
-- trn.Roles.GetDeadPlayers
----------------------------
-- Desc:		Gets a table containning all dead players, does not include spectators.
-- Returns:		Table, all dead players that are not spectators.
function trn.Roles.GetDeadPlayers()
	return table.Filter(player.GetAll(), function(ply)
		if not ply:Alive() or ply:IsInFlyMode() then
			return true
		end
		return false
	end)
end

------------------------------
-- trn.Roles.GetActivePlayers
------------------------------
-- Desc:		Gets all active players. Active means they are not idle or in always spectate mode.
-- Returns:		Table, containning active players.
function trn.Roles.GetActivePlayers()
	return table.Filter(player.GetAll(), function(ply)
		return ply:IsActive()
	end)
end

-------------------
-- PLAYER:IsActive
-------------------
-- Desc:		Is the player not a spectator.
-- Return:		Boolean, are they active.
function PLAYER:IsActive()
	return not self:IsSpectator()
end

----------------------
-- PLAYER:IsSpectator
----------------------
-- Desc:		Checks if the player is a spectator.
-- Returns:		Boolean, are they a spectator.
function PLAYER:IsSpectator()
	if self.trn_IsSpectator ~= nil then
		return self.trn_IsSpectator
	end
	return true
end

net.Receive("trn.Roles.ChangedSpectatorMode", function(_, ply)
	local wants_spec = net.ReadBool()
	if wants_spec then
		ply:ForceSpectator()
		ply.trn_IsSpectator = true
		hook.Call("trn.Roles.PlayerBecameSpectator", nil, ply)
	else
		ply:ForceWaiting()
		ply.trn_IsSpectator = false
		hook.Call("trn.Roles.PlayerExittedSpectator", nil, ply)
	end
end)

------------------------------
-- trn.Roles.GetPlayersOfRole
------------------------------
-- Desc:		Gets all players of a specified role.
-- Arg One:		ROLE_ enum of players to get.
-- Returns:		Table, players of this role.
function trn.Roles.GetPlayersOfRole(role)
	return table.Filter(player.GetAll(), function(ply)
		return ply:GetRole() == role
	end)
end

-- Role getter functions.
function trn.Roles.GetWaiting() return trn.Roles.GetPlayersOfRole(ROLE_WAITING) end
function trn.Roles.GetBlues() return trn.Roles.GetPlayersOfRole(ROLE_BLUE) end
function trn.Roles.GetReds() return trn.Roles.GetPlayersOfRole(ROLE_RED) end
function trn.Roles.GetSpectators()
	return table.Filter(player.GetAll(), function(ply)
		return ply:IsSpectator()
	end)
end

---------------------------------
-- trn.Roles.GetPlayersNotOfRole
---------------------------------
-- Desc:		Gets all players not of the specified role.
-- Arg One:		ROLE_ enum to get players not of this role.
-- Returns:		Table, players not of the role supplied in arg one.
function trn.Roles.GetPlayersNotOfRole(role)
	return table.Filter(player.GetAll(), function(ply)
		return ply:GetRole() ~= role
	end)
end

-- Role getter functions.
function trn.Roles.GetNotWaiting() return trn.Roles.GetPlayersNotOfRole(ROLE_WAITING) end
function trn.Roles.GetNotBlues() return trn.Roles.GetPlayersNotOfRole(ROLE_BLUE) end
function trn.Roles.GetNotReds() return trn.Roles.GetPlayersNotOfRole(ROLE_RED) end
function trn.Roles.GetNotSpectators()
	return table.Filter(player.GetAll(), function(ply)
		return not ply:IsSpectator()
	end)
end

----------------------------
-- PLAYER:SetRoleClientside
----------------------------
-- Desc:		Sets the role of a player but only for the given recipients.
-- Arg One:		ROLE_ enum, what role this player should have.
-- Arg Two:		Table, player, or true. Table if more than one player should know. Player for a single person. True for everyone to know this person's role changed.
function PLAYER:SetRoleClientside(role, recipients)
	net.Start("trn.Roles.PlayerSwitchedRole")
		net.WriteUInt(role, 3)
		net.WritePlayer(self)

	if recipients == true then
		net.Broadcast()
	else
		net.Send(recipients)
	end
end

--------------------
-- PLAYER:ForceRole
--------------------
-- Desc:		Sets the player's role and networks it to the given recipients.
-- Arg One:		ROLE_ enum, to set the player to.
-- Arg Two:		Table, player, or true. Table if more than one player should know. Player for a single person. True for everyone to know this person's role changed.
function PLAYER:ForceRole(role, recipients)
	self:SetRole(role)
	self:SetRoleClientside(role, recipients)
end

-- Helper functions for setting a player's role after round start.
function PLAYER:ForceSpectator()
	if self:Alive() then
		self:Kill()
	end
	self:ForceRole(ROLE_SPECTATOR, true)
end
function PLAYER:ForceBlue()
	self:ForceRole(ROLE_BLUE, true)
end
function PLAYER:ForceRed()
	self:ForceRole(ROLE_RED, true)
end
function PLAYER:ForceWaiting()
	self:ForceRole(ROLE_WAITING, true)
end

-------------------
-- trn.Roles.Clear
-------------------
-- Desc:		Clears everyone's role, sets them to ROLE_WAITING if they are active. ROLE_SPECTATOR if they are not.
function trn.Roles.Clear()
	local activeplayers = trn.Roles.GetActivePlayers()

	for i, v in ipairs(activeplayers) do
		v:SetRole(ROLE_WAITING)
	end
	net.Start("trn.Roles.Clear")
		net.WriteUInt(#activeplayers, 7)
		for i, v in ipairs(activeplayers) do
			net.WritePlayer(v)
		end
	net.Broadcast()
end

-----------------------
-- trn.Roles.PickRoles
-----------------------
-- Desc:		Will set the roles of each player accordingly. Does not network these role changes.
function trn.Roles.PickRoles()
	local reds = {}
	local blue = {}

	-- Pick Reds.
	do
		local players = trn.Roles.GetWaiting()
		local percent_red = 0.5
		local needed_players = math.max(1, math.floor(#players * percent_red))
		math.randomseed(os.time())

		for i = 1, needed_players do
			local ply_index = math.random(1, #players)
			local ply = players[ply_index]

			table.insert(reds, ply)
			table.remove(players, ply_index)
		end

		-- Now that we randomly picked some reds allow others to edit this list.
		reds = hook.Call("trn.Roles.PickReds", nil, reds) or reds

		for i, v in ipairs(reds) do
			v:SetRole(ROLE_REDS)
		end
	end


	-- Pick blues.
	do
		local blues = trn.Roles.GetWaiting()

		-- Whether or not we hit the threshold still see if they want to add blues.
		blues = hook.Call("trn.Roles.PickBlues", nil, blues) or blues

		if #blues > 0 then
			for i, v in ipairs(blues) do
				v:SetRole(ROLE_BLUE)
			end
		end
	end
end

------------------
-- trn.Roles.Sync
------------------
-- Desc:		Informs everyone of the current player roles.
function trn.Roles.Sync()
	local reds = trn.Roles.GetReds()
	local blues = trn.Roles.GetBlues()
	local spectators = trn.Roles.GetSpectators()
	net.Start("trn.Roles.Sync")
		-- Send order: reds, blue, spectators.
		net.WriteUInt(#reds, 7)
		for i, v in ipairs(reds) do
			net.WritePlayer(v)
		end

		net.WriteUInt(#blues, 7)
		for i, v in ipairs(blues) do
			net.WritePlayer(v)
		end

		net.WriteUInt(#spectators, 7)
		for i, v in ipairs(spectators) do
			net.WritePlayer(v)
		end
	net.Broadcast()
end