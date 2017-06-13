
trn.Weapons = trn.Weapons or {}

function trn.Weapons.GiveStarterWeapons(ply)
    ply:Give("weapon_build")
end

function trn.Weapons.StripCompletely(ply)
    ply:StripWeapons()
end
