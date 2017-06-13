trn.Building = trn.Building or {}

util.AddNetworkString("trn.Building.AskProp")
util.AddNetworkString("trn.Building.SpawnProp")

local PLAYER = FindMetaTable("Player")

function PLAYER:SetCredits(am)
    hook.Run("onCreditsChange", self, self:GetCredits(), am)
    self:SetNW2Int("Credits", am)
end

net.Receive("trn.Building.AskProp", function(l, ply)
    local category = net.ReadString()
    local id = net.ReadInt(16)
    if (trn.Building.Props[category]) then
        local item = trn.Building.Props[category][id]
        net.Start("trn.Building.AskProp")
        net.WriteBool(ply:CanAfford(item.price))
        if (ply:CanAfford(item.price)) then
            net.WriteString(item.path)
            ply.ItemToSpawn = item
        else
            ply.ItemToSpawn = nil
        end
        net.Send(ply)
    end
end)

net.Receive("trn.Building.SpawnProp",function(l, ply)
    if (ply.ItemToSpawn and ply:CanAfford(ply.ItemToSpawn.price)) then
        ply:SetCredits(ply:GetCredits() - ply.ItemToSpawn.price)
        local ent = ents.Create("prop_physics")
        ent:SetModel(ply.ItemToSpawn.path)
        ent:SetPos(net.ReadVector())
        ent:SetAngles(net.ReadAngle())
        ent:Spawn()
        ply.ItemToSpawn = nil
    end
end)
