trn.Building = trn.Building or {}
trn.Building.Classes = {"glass", "metal", "plastic", "stone", "wood"}
trn.Building.Props = {}

for k, v in pairs(trn.Building.Classes) do
    local fl = util.JSONToTable(file.Read("spawnlist/" .. v .. ".txt") or "[]")
    trn.Building.Props[v] = fl
end

function trn.Building:GetCategory(index)
    local i = 0
    for k,v in pairs(self.Classes) do
        if (index == i) then
            return trn.Building.Props[v]
        end
        i = i + 1
    end
    return nil
end

local PLAYER = FindMetaTable("Player")

function PLAYER:GetCredits()
    return self:GetNW2Int("Credits",0)
end

function PLAYER:CanAfford(am)
    return self:GetCredits() >= am
end
