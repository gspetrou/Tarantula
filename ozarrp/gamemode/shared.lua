GM.Name = "Tarantula"
GM.Author = "People"
GM.Email = "gonzalolog@gmail.com"
GM.Website = "https://bitbucket.org/gonzalolog/2017-gamemode-coding-competition"

local _, folder = file.Find(GM.FolderName .. "/gamemode/modules/*", "LUA")

for _, dir in pairs(folder) do
    for cs, fl in pairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/cl_*.lua", "LUA")) do
        if SERVER then
            AddCSLuaFile(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
        else
            include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
        end
    end

    for sh, fl in pairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/sh_*.lua", "LUA")) do
        AddCSLuaFile(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
        include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
    end

    if SERVER then
        for sv, fl in pairs(file.Find(GM.FolderName .. "/gamemode/modules/" .. dir .. "/sv_*.lua", "LUA")) do
            include(GM.FolderName .. "/gamemode/modules/" .. dir .. "/" .. fl)
        end
    end
end
