local PANEL = {}
local itemlist = {"Wood", "Stone", "Plastic", "Metal", "Glass"}

function PANEL:Init()
    local w = ScrW() * 0.8
    local h = ScrH() * 0.8
    self:SetSize(w, h)
    self:Center()
    self:MakePopup()
    self:SetSizable(true)
    self.List = vgui.Create("DListView", self)
    self.List:SetSize(w - 32, h / 4)
    self.List:Dock(TOP)
    self.List:DockMargin(8, 8, 8, h / 4 + 8)
    self.List:AddColumn("Category")

    for k, v in pairs(itemlist) do
        self.List:AddLine(v)
    end

    self.List.OnRowSelected = function(s, rowindex, row)
        self:PerformReload(row:GetColumnText(1))
    end

    self.Container = vgui.Create("DPanel", self)
    self.Container:SetSize(w - 32, h - h / 4 - 48 - 16)
    self.Container:DockMargin(8, 8, 8, 8)
    self.Container:Dock(BOTTOM)

    self.Container.Paint = function(s, we, he)
        surface.SetDrawColor(75, 75, 75, 255)
        surface.DrawRect(0, 0, we, he)
    end

    self.Props = vgui.Create("DIconLayout", self.Container)
    self.Props:Dock(FILL)

    self.Props.Paint = function(s, we, he)
        surface.SetDrawColor(75, 75, 75, 255)
        surface.DrawRect(0, 0, we, he)
    end

    self:SetTitle("Prop whitelister")
    file.CreateDir("spawnlist")
end

function PANEL:PerformReload(row)
    for k, v in pairs(self.Props:GetChildren()) do
        v:Remove()
    end

    local add = vgui.Create("gPropItem", self.Props)
    add:SetModel("Add model")
    add.Category = row

    if (file.Exists("spawnlist/" .. row .. ".txt", "DATA")) then
        local data = util.JSONToTable(file.Read("spawnlist/" .. row .. ".txt"))

        for k, v in pairs(data) do
            local mdl = vgui.Create("gPropItem", self.Props)
            mdl:SetModel(v.path, v.price or 0)
            mdl.Category = row
        end
    end
end

function PANEL:Delete(path, row)
    local data = util.JSONToTable(file.Read("spawnlist/" .. row .. ".txt"))

    for k, v in pairs(data or {}) do
        if (string.lower(path) == string.lower(v.path)) then
            table.RemoveByValue(data, v)
            break
        end
    end

    file.Write("spawnlist/" .. row .. ".txt", util.TableToJSON(data))
    file.Write("spawnlist/version.txt", tonumber(file.Read("spawnlist/version.txt", "DATA")) + 1)
    self:PerformReload(row)
end

function PANEL:SetPrice(path, price, row)
    local data = util.JSONToTable(file.Read("spawnlist/" .. row .. ".txt"))

    for k, v in pairs(data or {}) do
        if (path == v.path) then
            v.price = price
            break
        end
    end

    file.Write("spawnlist/" .. row .. ".txt", util.TableToJSON(data))
    file.Write("spawnlist/version.txt", tonumber(file.Read("spawnlist/version.txt", "DATA")) + 1)
    self:PerformReload(row)
end

function PANEL:AddItem(path, price, row)
    MsgN(row == nil)
    if (row == nil) then return end
    local data = util.JSONToTable(file.Read("spawnlist/" .. row .. ".txt") or "[]")
    local newItem = {}
    newItem.path = path
    newItem.price = tonumber(price)
    table.insert(data, newItem)
    file.Write("spawnlist/" .. row .. ".txt", util.TableToJSON(data))
    file.Write("spawnlist/version.txt", tonumber(file.Read("crafting/version.txt", "DATA")) + 1)
    self:PerformReload(row)
end

derma.DefineControl("gPropWhitelist", "GPROP", PANEL, "DFrame")
local PROP = {}
PROP.Category = ""
PROP.MDLPaint = nil

function PROP:Init()
    self:SetText("")
    self:SetSize(96, 96)
    self.MDL = vgui.Create("DModelPanel", self)
    self.MDL:SetSize(96, 96)
end

function PROP:SetModel(mdl, price)
    self.IsModel = mdl ~= "Add model"
    self.MDL.Price = price
    self.MDL:SetTooltip(mdl)

    if (mdl ~= "Add model") then
        local w, h = self:GetSize()
        self.MDL:SetPos(4, 4)
        self.MDL:SetSize(w - 8, h - 8)
        self.MDL:SetModel(mdl)
        local mn, mx = self.MDL.Entity:GetRenderBounds()
        local size = 0
        size = math.max(size, math.abs(mn.x) + math.abs(mx.x))
        size = math.max(size, math.abs(mn.y) + math.abs(mx.y))
        size = math.max(size, math.abs(mn.z) + math.abs(mx.z))
        self.MDL:SetFOV(45)
        self.MDL:SetCamPos(Vector(size, size, size))
        self.MDL:SetLookAt((mn + mx) * 0.5)
    end

    self.MDL.DoClick = self.DoClick

    self.MDL.PaintOver = function(s, w, h)
        if s.Price and tonumber(s.Price) > 0 then
            draw.SimpleText(tostring(s.Price or 1), "default", 3, 3, Color(255, 255, 255))
        end
    end
end

function PROP:DoClick()
    if (self:GetModel() ~= nil) then
        local menu = DermaMenu()
        local set = menu:AddOption("Set price")
        set:SetIcon("icon16/coins.png")

        set.DoClick = function()
            local target = self:GetParent():GetParent():GetParent():GetParent()

            Derma_StringRequest("New price", "How much of " .. self:GetParent().Category .. " should it cost?", "2", function(price)
                target:SetPrice(self:GetParent().MDL:GetModel(), tonumber(price), self:GetParent().Category)
            end)
        end

        local delete = menu:AddOption("Delete")
        delete:SetIcon("icon16/fire.png")

        delete.DoClick = function()
            local target = self:GetParent():GetParent():GetParent():GetParent()
            target:Delete(self:GetParent().MDL:GetModel(), self:GetParent().Category)
        end

        local cancel = menu:AddOption("Cancel")
        cancel:SetIcon("icon16/arrow_left.png")
        cancel.DoClick = function() end
        menu:Open()
        local mx, my = input.GetCursorPos()
        menu:SetPos(mx, my)
    else
        Derma_StringRequest("New item", "Insert a model path", "models/Gibs/HGIBS.mdl", function(mdl)
            Derma_StringRequest("New item", "Insert amount of item required for this", "16", function(weight)
                local target = self:GetParent():GetParent():GetParent():GetParent()
                target:AddItem(mdl, weight, self:GetParent().Category)
            end)
        end)
    end
end

local hover = surface.GetTextureID("vgui/spawnmenu/hover")

function PROP:Paint(w, h)
    draw.RoundedBox(8, 2, 2, w - 4, h - 4, Color(90, 90, 90))

    if (self.MDL:IsHovered()) then
        surface.SetTexture(hover)
        surface.DrawTexturedRect(0, 0, w, h)
    end

    if (not self.IsModel) then
        surface.SetDrawColor(125, 255, 90)
        surface.DrawRect(16, h / 2 - 8, w - 32, 16)
        surface.DrawRect(w / 2 - 8, 16, 16, h - 32)
    end
end

derma.DefineControl("gPropItem", "gPropItem", PROP, "DButton")
PW = PW or nil

concommand.Add("prop_manager", function(l, ply)
    if (PW) then
        PW:Remove()
        PW = nil
    end

    PW = vgui.Create("gPropWhitelist")
end)
