AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "shared.lua" )

include( "shared.lua" )

function GM:PlayerInitialSpawn(ply)
	trn.Roles.SetupSpectator(ply)
end

function GM:PlayerSpawn(ply)
	-- If something needs to spawn a player mid-game and doesn't want to deal with this function it can enable ply.trn_OverrideSpawn.
	if ply.trn_OverrideSpawn ~= true then
		print(ply:IsSpectator())
		if ply:IsSpectator() or trn.Rounds.IsActive() or trn.Rounds.IsPost() then
			self:PlayerSpawnAsSpectator(ply)
		else
			trn.Roles.SpawnAsPlayer(ply, true)
		end
	end
	
	self:PlayerSetModel(ply)
	ply:SetupHands()					-- Get c_ hands working.
end

function GM:PlayerSpawnAsSpectator(ply)	-- For backwards compatability.
	trn.Roles.SpawnInFlyMode(ply)
end

function GM:PostPlayerDeath(ply)
	trn.Rounds.CheckForRoundEnd()
end

function GM:PlayerDisconnected(ply)
	timer.Create("trn.WaitForFullPlayerDisconnect", .5, 0, function()
		if not IsValid(ply) then
			trn.Rounds.CheckForRoundEnd()
			timer.Remove("trn.WaitForFullPlayerDisconnect")
		end
	end)
end

function GM:PlayerSetHandsModels(ply, ent)
	-- Get c_ hands working.
	local simplemodel = player_manager.TranslateToPlayerModelName(ply:GetModel())
	local info = player_manager.TranslatePlayerHands(simplemodel)
	if info then
		ent:SetModel(info.model)
		ent:SetSkin(info.skin)
		ent:SetBodyGroups(info.body)
	end
end

hook.Add("trn.Rounds.Initialize", "trn", function()
	if trn.Rounds.ShouldStart() then
		trn.Rounds.EnterPrep()
	else
		trn.Rounds.WaitForStart()
	end
end)

hook.Add("trn.Rounds.ShouldStart", "trn", function()
	if GetConVar("trn_dev_preventstart"):GetBool() or #trn.Roles.GetActivePlayers() < GetConVar("trn_minimum_players"):GetInt() then
		return false
	end
	
	return true
end)

hook.Add("trn.Rounds.ShouldEnd", "trn", function()
	if not trn.Rounds.IsActive() or GetConVar("trn_dev_preventwin"):GetBool() then
		return false
	end

	if trn.Rounds.GetRemainingTime() <= 0 then
		return WIN_TIME
	end

	local numAlive, numaliveReds, numaliveBlues = 0, 0, 0
	for i, v in ipairs(trn.Roles.GetAlivePlayers()) do
		numAlive = numAlive + 1

		if v:IsBlue() then
			numaliveBlues = numaliveBlues + 1
		elseif v:IsRed() then
			numaliveReds = numaliveReds + 1
		end
	end

	if numAlive == 0 then
		return WIN_TIME -- TODO: Change this
	end

	local numplys = #trn.Roles.GetAlivePlayers()
	if numplys == numaliveReds then
		return WIN_RED
	elseif numplys == numaliveBlues then
		return WIN_BLUE
	end

	return false
end)

hook.Add("trn.Rounds.RoundStarted", "trn", function()
	for i, v in ipairs(trn.Roles.GetDeadPlayers()) do
		trn.Roles.ForceSpawn(v) -- Technically the round already started.
	end
	trn.Roles.PickRoles()
	trn.Roles.Sync()

	timer.Simple(1, function()
		trn.Rounds.CheckForRoundEnd()	-- Could happen if trn_dev_preventwin is 0 and trn_minimum_players is <= 1.
	end)
end)

hook.Add("trn.Rounds.EnteredPrep", "trn", function()
	--trn.Player.SetDefaultModelColor(trn.Player.GetRandomPlayerColor())
	--trn.MapHandler.ResetMap()
	trn.Roles.Clear()
end)

--------------
-- Role Hooks
--------------
hook.Add("trn.Roles.PlayerBecameSpectator", "trn", function(ply)
	trn.Rounds.CheckForRoundEnd()
end)

hook.Add("trn.Roles.PlayerExittedSpectator", "trn", function(ply)
	if not trn.Rounds.IsActive() or not trn.Rounds.IsPost() then
		trn.Roles.SpawnAsPlayer(ply)
	--	trn.Player.SetModel(ply)
	end
end)

hook.Add("trn.Roles.PlayerSpawned", "trn", function(ply, resetSpawn, wasForced)
	if resetSpawn then
	--	trn.MapHandler.PutPlayerAtRandomSpawnPoint(ply)
	end
	
	--trn.Weapons.StripCompletely(ply)
	--trn.Weapons.GiveStarterWeapons(ply)
end)

hook.Add("trn.Roles.PlayerSpawnedInFlyMode", "trn", function(ply)
	--trn.Weapons.StripCompletely(ply)
end)