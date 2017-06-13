
net.Receive("trn.Building.AskProp",function()
    local can = net.ReadBool()
    if (IsValid(LocalPlayer().BuildModel)) then
        LocalPlayer().BuildModel:Remove()
    end
    if (can) then
        local mdl = net.ReadString()
        util.PrecacheModel(mdl)
        LocalPlayer().BuildModel = ents.CreateClientProp()
        LocalPlayer().BuildModel:SetModel(mdl)
        LocalPlayer().BuildModel:Spawn()
        LocalPlayer().BuildModel:SetMaterial("effects/tarantula/glow_texture")
    end
end)
