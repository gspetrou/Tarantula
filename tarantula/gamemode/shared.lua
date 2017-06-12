GM.Name = "Tarantula"
GM.Author = "Gonzo, King David, Stalker"
GM.Email = "gonzalolog@gmail.com"
GM.Website = "https://github.com/gspetrou/Tarantula"
DeriveGamemode( "sandbox" )

trn = trn or {}

-- Small library of functions for use within the modules.
if SERVER then
	AddCSLuaFile( "prelib.lua" )
end
include( "prelib.lua" )

-- Load the modules
GM:LoadModules()

function GM:Initialize()
	trn.Rounds.Initialize()
end

hook.Add("trn.Rounds.StateChanged", "trn", function(state)
	if state == ROUND_WAITING then
		for i, v in ipairs(player.GetAll()) do
			if not v:IsSpectator() then
				v:SetRole(ROLE_WAITING)
			end
		end
	end
end)

function GM:InitPostEntity()
	if CLIENT then
		trn.Roles.InitializeSpectator()
	end
end