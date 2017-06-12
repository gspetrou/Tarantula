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


function GM:InitPostEntity()
	if CLIENT then
		trn.Roles.InitializeSpectator()
	end
end
