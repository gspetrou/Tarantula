trn.Colors = {
	Dead		= Color(90, 90, 90, 230),
	Blue		= Color(41, 128, 185, 230),
	Red			= Color(192, 57, 43, 230)
}

------------------
-- GM:LoadModules
------------------
-- Desc:		Loads every module.
function GM:LoadModules()
	local _, folder = file.Find(GM.FolderName .. "/gamemode/modules/*", "LUA")
	for _, dir in ipairs(folder) do
		for cs, fl in ipairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/cl_*.lua", "LUA")) do
			if SERVER then
				AddCSLuaFile(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
			else
				include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
			end
		end

		for sh, fl in ipairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/sh_*.lua", "LUA")) do
			AddCSLuaFile(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
			include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
		end

		if SERVER then
			for sv, fl in ipairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/sv_*.lua", "LUA")) do
				include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
			end
		end
	end

	hook.Call("tra.PostModulesLoaded")
end

-------------------
-- net.WritePlayer
-------------------
-- Desc:		A more optimized version of net.WriteEntity specifically for players.
-- Arg One:		Player entity to be networked.
if not net.WritePlayer then
	function net.WritePlayer(ply)
		if IsValid(ply) then
			net.WriteUInt(ply:EntIndex(), 7)
		else
			net.WriteUInt(0, 7)
		end
	end
end

------------------
-- net.ReadPlayer
------------------
-- Desc:		Optimized version of net.ReadEntity specifically for players.
-- Returns:		Player entity thats been written.
if not net.ReadPlayer then
	function net.ReadPlayer()
		local i = net.ReadUInt(7)
		if not i then
			return
		end
		return Entity(i)
	end
end

----------------
-- table.Filter
----------------
-- CREDITS:		Copied from the dash library by SuperiorServers (https://github.com/SuperiorServers/dash)
-- Desc:		Will use the given function to filter out certain members from the given table. Edits the given table.
-- Arg One:		Table, to be filtered.
-- Arg Two:		Function, decides what should be filters.
-- Returns:		Table, same table as arg one but filtered.
function table.Filter(tab, func)
	local c = 1
	for i = 1, #tab do
		if func(tab[i]) then
			tab[c] = tab[i]
			c = c + 1
		end
	end
	for i = c, #tab do
		tab[i] = nil
	end
	return tab
end